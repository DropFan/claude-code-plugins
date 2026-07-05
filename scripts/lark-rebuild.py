#!/usr/bin/env python3
"""Rebuild the `lark` plugin content inside this marketplace repo.

Re-copies the upstream Lark skills from ~/.agents/skills/lark-* into
plugins/lark/skills/, injects the Cowork execution note into each SKILL.md,
regenerates the skills table in plugins/lark/README.md, updates the plugin
version in plugins/lark/.claude-plugin/plugin.json, and runs
scripts/sync-plugins.sh to propagate the metadata to marketplace.json and
the root README.

Full workflow:
  1. npx skills add larksuite/cli -g -y     # refresh upstream skills locally
  2. python3 scripts/lark-rebuild.py [--version X.Y.Z]
     (--version sets the plugin version explicitly, e.g. to match the
      lark-cli release; without it the patch version is bumped by one)
  3. git add plugins/lark .claude-plugin/marketplace.json README.md
     then git commit && git push
  4. Update the plugin inside Cowork (plugin manager / update-plugins).

Path-agnostic: derives the repo root from this script's own location, so it
works on any machine/clone. Skill source defaults to ~/.agents/skills and can
be overridden with LARK_SKILLS_SRC.

Note: files under plugins/lark/skills/ are overwritten wholesale on every
run. Local fixes to skill content (e.g. repaired links) do not survive a
rebuild -- apply fixes that must persist in the upstream larksuite/cli repo.
"""
import argparse
import json
import os
import re
import shutil
import subprocess
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))           # .../scripts
REPO_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, ".."))
PLUGIN_DIR = os.path.join(REPO_ROOT, "plugins", "lark")
SKILLS_DST = os.path.join(PLUGIN_DIR, "skills")
SKILLS_SRC = os.environ.get("LARK_SKILLS_SRC", os.path.expanduser("~/.agents/skills"))
PLUGIN_JSON = os.path.join(PLUGIN_DIR, ".claude-plugin", "plugin.json")
PLUGIN_README = os.path.join(PLUGIN_DIR, "README.md")
SYNC_SCRIPT = os.path.join(REPO_ROOT, "scripts", "sync-plugins.sh")

SKILLS_LIST_START = "<!-- SKILLS_LIST_START -->"
SKILLS_LIST_END = "<!-- SKILLS_LIST_END -->"

BANNER_MARK = "<!-- cowork-exec-note -->"
BANNER = f"""{BANNER_MARK}
> **⚙️ Cowork / Claude Desktop 执行环境说明（自动注入）**
>
> 本技能依赖本地 `lark-cli`（`@larksuite/cli`，可用 `command -v lark-cli` 定位）及其 `~/.lark-cli` 登录态（应用密钥存于 macOS keychain）。
>
> 在 Cowork 中运行任何 `lark-cli` 命令时，**必须在本地 macOS 上执行**（使用 Desktop Commander 的 `start_process` / `interact_with_process`，或其它本地 shell 工具），**不要用隔离的 Linux 沙箱** `mcp__workspace__bash`——沙箱里没有 lark-cli、也读不到 keychain。
> 执行前确保 npm 全局 bin 目录（`npm prefix -g` 输出目录下的 `bin`）在 PATH 中。
>
> （在 Claude Code 中可忽略本说明，lark-cli 在本机 shell 直接可用。）

"""

def inject(skill_md):
    with open(skill_md, encoding="utf-8") as f:
        txt = f.read()
    if BANNER_MARK in txt:
        return False
    lines = txt.split("\n")
    if lines and lines[0].strip() == "---":
        end = next((i for i in range(1, len(lines)) if lines[i].strip() == "---"), None)
        if end is not None:
            txt = "\n".join(lines[:end+1]) + "\n\n" + BANNER + "\n".join(lines[end+1:])
        else:
            txt = BANNER + txt
    else:
        txt = BANNER + txt
    with open(skill_md, "w", encoding="utf-8") as f:
        f.write(txt)
    return True

def read_frontmatter(skill_md):
    """Extract top-level key: value pairs (incl. block scalars) from YAML frontmatter."""
    meta = {}
    with open(skill_md, encoding="utf-8") as f:
        lines = f.read().split("\n")
    if not lines or lines[0].strip() != "---":
        return meta
    i = 1
    while i < len(lines):
        line = lines[i]
        if line.strip() == "---":
            break
        if not line or line[0].isspace() or ":" not in line:
            i += 1
            continue
        key, _, val = line.partition(":")
        val = val.strip()
        if val in (">", ">-", ">+", "|", "|-", "|+"):
            block = []
            while i + 1 < len(lines) and (lines[i + 1].startswith(" ") or not lines[i + 1].strip()):
                block.append(lines[i + 1].strip())
                i += 1
            val = " ".join(b for b in block if b)
        else:
            val = val.strip('"').strip("'")
        meta[key.strip()] = val
        i += 1
    return meta

def first_sentence(desc):
    if "。" in desc:
        return desc.split("。", 1)[0] + "。"
    m = re.search(r"\.\s", desc)
    if m:
        return desc[:m.start() + 1]
    return desc

def update_readme(skill_dirs):
    rows = ["| Skill | Description |", "| --- | --- |"]
    for d in skill_dirs:
        smd = os.path.join(SKILLS_DST, d, "SKILL.md")
        meta = read_frontmatter(smd) if os.path.isfile(smd) else {}
        name = meta.get("name", d)
        desc = first_sentence(meta.get("description", "")).replace("|", "\\|")
        rows.append(f"| [{name}](skills/{d}/SKILL.md) | {desc} |")
    table = "\n".join(rows)
    with open(PLUGIN_README, encoding="utf-8") as f:
        txt = f.read()
    if SKILLS_LIST_START not in txt or SKILLS_LIST_END not in txt:
        sys.exit(f"README markers not found in {PLUGIN_README}: "
                 f"{SKILLS_LIST_START} / {SKILLS_LIST_END}")
    pattern = re.compile(re.escape(SKILLS_LIST_START) + r".*?" + re.escape(SKILLS_LIST_END),
                         re.DOTALL)
    replacement = f"{SKILLS_LIST_START}\n{table}\n{SKILLS_LIST_END}"
    txt = pattern.sub(lambda _: replacement, txt, count=1)
    with open(PLUGIN_README, "w", encoding="utf-8") as f:
        f.write(txt)

def bumped_patch(version):
    parts = version.split(".")
    if len(parts) != 3 or not all(p.isdigit() for p in parts):
        sys.exit(f"cannot auto-bump version {version!r}; pass --version X.Y.Z explicitly")
    parts[2] = str(int(parts[2]) + 1)
    return ".".join(parts)

def main():
    parser = argparse.ArgumentParser(
        description="Rebuild the lark plugin from upstream skills and sync metadata.")
    parser.add_argument("--version", metavar="X.Y.Z",
                        help="set the plugin version explicitly (e.g. the lark-cli "
                             "release); default: bump the current patch version")
    args = parser.parse_args()
    if args.version and not re.fullmatch(r"\d+\.\d+\.\d+", args.version):
        parser.error(f"--version must look like X.Y.Z, got {args.version!r}")

    if not os.path.isdir(SKILLS_SRC):
        sys.exit(f"skills source not found: {SKILLS_SRC} (run: npx skills add larksuite/cli -g -y)")
    lark = sorted(d for d in os.listdir(SKILLS_SRC)
                  if d.startswith("lark-") and os.path.isdir(os.path.join(SKILLS_SRC, d)))
    if not lark:
        sys.exit("no lark-* skills found in " + SKILLS_SRC)
    if not os.path.isfile(SYNC_SCRIPT):
        sys.exit(f"sync script not found: {SYNC_SCRIPT}")

    if os.path.isdir(SKILLS_DST):
        shutil.rmtree(SKILLS_DST)
    os.makedirs(SKILLS_DST)

    for d in lark:
        shutil.copytree(os.path.join(SKILLS_SRC, d), os.path.join(SKILLS_DST, d), symlinks=False)
    # drop junk
    for root, dirs, files in os.walk(SKILLS_DST):
        for fn in files:
            if fn == ".DS_Store":
                os.remove(os.path.join(root, fn))
    injected = 0
    for d in lark:
        smd = os.path.join(SKILLS_DST, d, "SKILL.md")
        if os.path.isfile(smd) and inject(smd):
            injected += 1

    update_readme(lark)

    with open(PLUGIN_JSON, encoding="utf-8") as f:
        plugin_meta = json.load(f)
    old_version = plugin_meta.get("version", "1.0.0")
    new_version = args.version or bumped_patch(old_version)
    plugin_meta["version"] = new_version
    with open(PLUGIN_JSON, "w", encoding="utf-8") as f:
        json.dump(plugin_meta, f, ensure_ascii=False, indent=2)
        f.write("\n")

    # propagate plugin.json -> marketplace.json + root README via the single sync entry point
    subprocess.run(["bash", SYNC_SCRIPT], check=True, cwd=REPO_ROOT)

    print(f"skills: {len(lark)}  banners injected: {injected}  "
          f"version: {old_version} -> {new_version}")
    print("done. next: git add plugins/lark .claude-plugin/marketplace.json README.md "
          "&& git commit && git push, then update the plugin in Cowork.")

if __name__ == "__main__":
    main()
