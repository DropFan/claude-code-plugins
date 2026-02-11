---
allowed-tools: Bash(pwd:*), Bash(date:*), Bash(mkdir:*), Bash(ls:*), Bash(bash:*), Bash(wc:*), Bash(du:*), Write, Read, Glob, AskUserQuestion
description: Export raw conversation data directly from JSONL session files
argument-hint: "[--format jsonl|json|md|html] [--full] [--list] [--session <id>]"
---

## Context

- Working directory: !`pwd`
- Current date: !`date '+%Y-%m-%d %H:%M'`
- Plugin root: ${CLAUDE_PLUGIN_ROOT}

## Task

Export raw conversation data directly from Claude Code's JSONL session files. Unlike `/save-chat` which reconstructs content from memory, this command reads the original data files, ensuring complete and faithful export.

**User arguments:** $ARGUMENTS

### Step 0: Load Settings

1. Use the Read tool to check if `.claude/chat-saver.local.md` exists in the project root
2. If it exists, parse the YAML frontmatter between `---` markers to extract:
   - `save_dir` — output directory (default: `./chats`)
   - `default_format` — fallback format if not specified in arguments (default: `md`)
   - `custom_footer` — custom footer text (replaces default)
3. If the file does not exist, silently use built-in defaults (no error)
4. Settings are overridden by explicit command arguments

### Step 1: Parse Arguments

Parse the optional arguments from $ARGUMENTS:

- **--format** — `md` (default), `jsonl`, `json`, or `html`
- **--full** — Include all record types (progress, file-history-snapshot, etc.), not just user/assistant messages
- **--list** — List available sessions and let user pick one
- **--session <id>** — Specify a session ID (supports UUID prefix match)

If $ARGUMENTS is empty, use defaults (format from settings or `md`, latest session).

If arguments are ambiguous or invalid, use AskUserQuestion to let the user choose:

For format:
- `md` — Markdown with YAML frontmatter, `## User`/`## Assistant` structure
- `html` — Styled HTML, viewable in browser
- `jsonl` — Filtered JSONL, machine-readable
- `json` — JSON array, machine-readable

### Step 2: Locate Project Data Directory

1. Get the current working directory:
```bash
pwd
```

2. Encode the path to match Claude Code's directory naming:
```bash
echo "$CWD" | sed 's|^/||' | sed 's|/|-|g'
```
The encoding removes the leading `/` then replaces all `/` with `-`.

3. Construct the project data path:
```
~/.claude/projects/-<encoded-path>/
```

4. Verify the directory exists:
```bash
ls ~/.claude/projects/<encoded-path>/*.jsonl 2>/dev/null | head -1
```

If the directory doesn't exist or contains no JSONL files, inform the user and stop.

### Step 3: Session Selection

**If `--list` is specified:**

1. Run the script in list mode:
```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/raw-export.sh" --list --project-dir "<project-data-dir>"
```
2. Display the table to the user
3. Use AskUserQuestion to let the user pick a session (show up to 4 options from the list, using session ID prefix + first message as labels)
4. Map the selection to the JSONL file path

**If `--session <id>` is specified:**

1. Search for matching files:
```bash
ls ~/.claude/projects/<encoded-path>/<id>*.jsonl 2>/dev/null
```
2. If exactly one match, use it
3. If multiple matches, use AskUserQuestion to disambiguate
4. If no match, inform the user

**Default (no selection arguments):**

Use the most recently modified JSONL file:
```bash
ls -t ~/.claude/projects/<encoded-path>/*.jsonl | head -1
```

### Step 4: Export

1. Ensure the output directory exists:
```bash
mkdir -p <save_dir>
```

2. Generate the output filename: `<date>-raw-<session-prefix-8>.<ext>`
   - Date: from `date '+%Y-%m-%d'`
   - Session prefix: first 8 characters of the session UUID
   - Extension: `.md`, `.html`, `.jsonl`, or `.json` based on format

3. Check for filename collision:
```bash
ls <save_dir>/<filename> 2>/dev/null
```
If exists, append `-2`, `-3`, etc.

4. Build and run the export command:
```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/raw-export.sh" \
  --format <fmt> \
  [--full] \
  --output "<save_dir>/<filename>" \
  [--footer "<custom_footer>"] \
  [--no-footer]  # for jsonl/json formats when no custom footer
  "<jsonl-file>"
```

Note: For `jsonl` and `json` formats, use `--no-footer` unless user has a `custom_footer` configured.

5. Parse the JSON summary from stdout

### Step 5: Report Result

Display a concise summary:

```
Raw export complete!

  File: ./<save_dir>/<filename>
  Format: <format name>
  Session: <full-session-uuid>
  Records: <user_count> user + <assistant_count> assistant (of <total> total)
  Size: <file_size>
```

If the user used `--list` mode, also mention that they can re-run with `--session <id>` for faster access next time.
