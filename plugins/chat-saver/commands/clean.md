---
allowed-tools: Bash(pwd:*), Bash(ls:*), Bash(wc:*), Bash(rm:*), Bash(date:*), Read, Glob, AskUserQuestion
description: Clean up old saved conversation files
argument-hint: "[--before YYYY-MM-DD] [--keep N] [--dry-run]"
---

## Context

- Working directory: !`pwd`
- Current date: !`date '+%Y-%m-%d %H:%M'`

## Task

Clean up old or unwanted saved conversation files with user confirmation.

**User arguments:** $ARGUMENTS

### Step 0: Load Settings

1. Use the Read tool to check if `.claude/chat-saver.local.md` exists
2. Extract `save_dir` (default: `./chats`)
3. If the file does not exist, use defaults silently

### Step 1: Parse Arguments

Parse optional arguments from $ARGUMENTS:

- **--before YYYY-MM-DD** — Delete files with a date prefix before the specified date
- **--keep N** — Keep the N most recent files, delete the rest
- **--dry-run** — Preview which files would be deleted without actually deleting them

If no arguments are provided, use AskUserQuestion to let the user choose a mode:
- **By date** — Delete files older than a specific date
- **Keep recent** — Keep the N most recent files
- **Select manually** — Show all files and let the user pick which to delete

### Step 2: Scan and Filter

1. Use Glob to find all files in `<save_dir>` (`*.md`, `*.txt`, `*.html`)
2. Extract the date prefix from each filename
3. Apply the selected filter:
   - **--before**: Compare filename date prefix against the cutoff date
   - **--keep**: Sort by date (newest first), mark all beyond the Nth file for deletion
   - **Manual**: Display all files and use AskUserQuestion for selection

### Step 3: Preview

Display the files that will be deleted:

```
Files to delete:

  1. 2024-01-10-old-topic.md (45 lines, 3K)
  2. 2024-01-08-another-topic.txt (89 lines, 6K)

Total: 2 files, ~9K
```

If `--dry-run` is set, display the preview and stop here without deleting.

### Step 4: Confirm

**This step is mandatory — never skip confirmation.**

Use AskUserQuestion to confirm:
- **Delete** — Proceed with deletion
- **Cancel** — Abort without deleting

### Step 5: Delete

Delete each file individually using `rm` (one file per command, no wildcards):

```bash
rm <save_dir>/2024-01-10-old-topic.md
```

Report the result:
```
Cleaned up!

  Deleted: 2 files
  Freed: ~9K
  Remaining: 5 files in ./chats
```
