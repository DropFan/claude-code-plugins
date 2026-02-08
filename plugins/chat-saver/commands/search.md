---
allowed-tools: Bash(pwd:*), Bash(date:*), Read, Grep, Glob, AskUserQuestion
description: Search saved conversations by keyword or date
argument-hint: "<keyword> [--date YYYY-MM-DD] [--from YYYY-MM-DD --to YYYY-MM-DD]"
---

## Context

- Working directory: !`pwd`
- Current date: !`date '+%Y-%m-%d %H:%M'`

## Task

Search through saved conversation files for specific keywords, optionally filtered by date range.

**User arguments:** $ARGUMENTS

### Step 0: Load Settings

1. Use the Read tool to check if `.claude/chat-saver.local.md` exists
2. Extract `save_dir` (default: `./chats`)
3. If the file does not exist, use defaults silently

### Step 1: Parse Arguments

Parse arguments from $ARGUMENTS:

- **keyword** (required) — The search term or phrase to find
- **--date YYYY-MM-DD** — Search only in files from a specific date
- **--from YYYY-MM-DD --to YYYY-MM-DD** — Search within a date range

If no keyword is provided, use AskUserQuestion to ask for one.

### Step 2: Find Target Files

1. Use Glob to scan `<save_dir>` for all conversation files (`*.md`, `*.txt`, `*.html`)
2. If no files exist, inform the user and exit
3. Apply date filters if specified:
   - **--date**: Only include files whose filename starts with the exact date
   - **--from/--to**: Include files whose filename date falls within the range (inclusive)
   - Date comparison is based on the `YYYY-MM-DD` prefix in filenames

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
