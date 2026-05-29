#!/usr/bin/env python3
"""Rebuild the `lark` plugin content inside this marketplace repo.

Re-copies the upstream Lark skills from ~/.agents/skills/lark-* into this
plugin's skills/ directory, injects the Cowork execution note into each
SKILL.md, and ensures the plugin is registered in the marketplace manifest.

Run after updating upstream skills:  npx skills add larksuite/cli -g -y
Then:  python3 plugins/lark/rebuild.py  &&  git commit ...  &&  git push
Finally update the plugin inside Cowork (plugin manager / update-plugins).

Path-agnostic: derives the repo root from this script's own location, so it
works on any machine/clone. Skill source defaults to ~/.agents/skills and can
be overridden with LARK_SKILLS_SRC.
"""
import os, json, shutil, sys

PLUGIN_DIR = os.path.dirname(os.path.abspath(__file__))          # .../plugins/lark
REPO_ROOT  = os.path.abspath(os.path.join(PLUGIN_DIR, "..", ".."))
SKILLS_DST = os.path.join(PLUGIN_DIR, "skills")
SKILLS_SRC = os.environ.get("LARK_SKILLS_SRC", os.path.expanduser("~/.agents/skills"))
MARKETPLACE = os.path.join(REPO_ROOT, ".claude-plugin", "marketplace.json")
PLUGIN_JSON = os.path.join(PLUGIN_DIR, ".claude-plugin", "plugin.json")

BANNER_MARK = "<!-- cowork-exec-note -->"
BANNER = f"""{BANNER_MARK}
> **⚙️ Cowork / Claude Desktop 执行环境说明（自动注入）**
>
> 本技能依赖本地 `lark-cli`（`@larksuite/cli`，位于 `/opt/homebrew/bin/lark-cli`）及其 `~/.lark-cli` 登录态（应用密钥存于 macOS keychain）。
>
> 在 Cowork 中运行任何 `lark-cli` 命令时，**必须在本地 macOS 上执行**（使用 Desktop Commander 的 `start_process` / `interact_with_process`，或其它本地 shell 工具），**不要用隔离的 Linux 沙箱** `mcp__workspace__bash`——沙箱里没有 lark-cli、也读不到 keychain。
> 执行前确保 PATH 含 Homebrew：`export PATH="/opt/homebrew/bin:$PATH"`。
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

def main():
    if not os.path.isdir(SKILLS_SRC):
        sys.exit(f"skills source not found: {SKILLS_SRC} (run: npx skills add larksuite/cli -g -y)")
    lark = sorted(d for d in os.listdir(SKILLS_SRC)
                  if d.startswith("lark-") and os.path.isdir(os.path.join(SKILLS_SRC, d)))
    if not lark:
        sys.exit("no lark-* skills found in " + SKILLS_SRC)

    if os.path.isdir(SKILLS_DST):
        shutil.rmtree(SKILLS_DST)
    os.makedirs(SKILLS_DST)

    injected = 0
    for d in lark:
        shutil.copytree(os.path.join(SKILLS_SRC, d), os.path.join(SKILLS_DST, d), symlinks=False)
    # drop junk
    for root, dirs, files in os.walk(SKILLS_DST):
        for fn in files:
            if fn == ".DS_Store":
                os.remove(os.path.join(root, fn))
    for d in lark:
        smd = os.path.join(SKILLS_DST, d, "SKILL.md")
        if os.path.isfile(smd) and inject(smd):
            injected += 1

    # ensure marketplace registration
    version = json.load(open(PLUGIN_JSON, encoding="utf-8")).get("version", "1.0.0")
    desc = json.load(open(PLUGIN_JSON, encoding="utf-8")).get("description", "Feishu/Lark skills")
    m = json.load(open(MARKETPLACE, encoding="utf-8"))
    m["plugins"] = [p for p in m["plugins"] if p.get("name") != "lark"]
    m["plugins"].append({
        "name": "lark", "source": "./plugins/lark", "description": desc,
        "version": version, "author": {"name": "Tiger", "url": "https://github.com/DropFan"}
    })
    json.dump(m, open(MARKETPLACE, "w", encoding="utf-8"), ensure_ascii=False, indent=2)

    print(f"skills: {len(lark)}  banners injected: {injected}  version: {version}")
    print("marketplace plugins:", [p["name"] for p in m["plugins"]])
    print("done. next: git add -A && git commit && git push, then update the plugin in Cowork.")

if __name__ == "__main__":
    main()
