---
allowed-tools: Bash(pwd:*), Bash(date:*), Read, Grep, Glob, AskUserQuestion
description: Search saved conversations by keyword or date
argument-hint: "<keyword> [--date YYYY-MM-DD] [--from YYYY-MM-DD --to YYYY-MM-DD] [--tag <tag>]"
---

## Context

- Working directory: !`pwd`
- Current date: !`date '+%Y-%m-%d %H:%M'`
- Plugin root: ${CLAUDE_PLUGIN_ROOT}

## Task

Search through saved conversation files for specific keywords, optionally filtered by date range.

**User arguments:** $ARGUMENTS

### Step 0: Load Settings

Load settings from `.claude/chat-saver.local.md` following `${CLAUDE_PLUGIN_ROOT}/skills/conversation-export/references/settings-loading.md`. Extract: `save_dir`.

### Step 1: Parse Arguments

Parse arguments from $ARGUMENTS:

- **keyword** (required, unless `--tag` is used) — The search term or phrase to find
- **--date YYYY-MM-DD** — Search only in files from a specific date
- **--from YYYY-MM-DD --to YYYY-MM-DD** — Search within a date range
- **--tag <tag>** — Filter results to files containing the specified tag in their metadata (YAML frontmatter `tags:` field, HTML `<meta name="keywords">`, or plain text `Tags:` header line)

If no keyword and no `--tag` is provided, use AskUserQuestion to ask for a keyword.

When `--tag` is used without a keyword, list all files matching the tag (no content search needed — just check metadata). When used with a keyword, first filter by tag, then search within matching files.

### Step 2: Find Target Files

1. Use Glob to scan `<save_dir>` for all conversation files (`*.md`, `*.txt`, `*.html`)
2. If no files exist, inform the user and exit
3. Apply filters if specified:
   - **--date**: Only include files whose filename starts with the exact date
   - **--from/--to**: Include files whose filename date falls within the range (inclusive)
   - Date comparison is based on the `YYYY-MM-DD` prefix in filenames
   - **--tag**: Use Grep to search for the tag in file metadata. For `.md` files, search for the tag in the YAML frontmatter `tags:` line. For `.html` files, search in the `<meta name="keywords">` tag. For `.txt` files, search in the `Tags:` header line. Only keep files that contain the specified tag.

### Step 3: Search Content

1. Use Grep to search for the keyword in the filtered files:
   - Use case-insensitive matching
   - Include 2 lines of context before and after each match (`-C 2`)
   - Use `output_mode: "content"` to show matching lines
2. Collect all matches grouped by file

### Step 4: Display Results

Present results grouped by file:

```
Search results for "auth" (3 matches in 2 files)

── 2024-01-15-auth-implementation.md ──────────
  Line 23: ...implementing the **auth** middleware...
  Line 45: ...the **auth** token should be stored in...

── 2024-01-12-api-design.md ───────────────────
  Line 78: ...endpoint requires **auth**entication...
```

If no matches are found, inform the user.

### Step 5: Follow-up

Use AskUserQuestion to ask the user:
- **Read file** — Open one of the matching files in full
- **Refine search** — Search again with different terms
- **Done** — No further action

If the user chooses to read a file, use the Read tool to display the full content.
