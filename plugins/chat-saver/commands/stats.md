---
allowed-tools: Bash(pwd:*), Bash(date:*), Bash(ls:*), Bash(wc:*), Bash(du:*), Read, Glob
description: Show statistics for saved conversation files
argument-hint: ""
---

## Context

- Working directory: !`pwd`
- Current date: !`date '+%Y-%m-%d %H:%M'`

## Task

Display statistics about saved conversation files in the save directory.

**User arguments:** $ARGUMENTS

### Step 0: Load Settings

1. Use the Read tool to check if `.claude/chat-saver.local.md` exists
2. Extract `save_dir` (default: `./chats`)
3. If the file does not exist, use defaults silently

### Step 1: Scan Directory

1. Use Glob to find all conversation files in `<save_dir>`:
   ```
   <save_dir>/*.md
   <save_dir>/*.txt
   <save_dir>/*.html
   ```
2. If no files are found, inform the user that no saved conversations exist and exit

### Step 2: Collect Statistics

For each file found:

1. Determine the format from the file extension (`.md` → Markdown, `.txt` → Plain Text, `.html` → HTML)
2. Get the file size using `du -h` or `ls -lh`
3. Extract the month from the filename date prefix (`YYYY-MM`)

Aggregate:

- **Total files** — Count of all files
- **Total size** — Combined size of all files (use `du -sh <save_dir>` or sum individual sizes)
- **By format** — Count and combined size per format (Markdown, HTML, Plain Text)
- **By month** — Count per month based on filename date prefix
- **Latest file** — Most recently dated file (by filename)
- **Oldest file** — Earliest dated file (by filename)

### Step 3: Display Statistics

Present the statistics in a clean, readable format:

```
Chat-Saver Statistics (<save_dir>)

  Total files:     12
  Total size:      148K

  By format:
    Markdown:      8 files  (102K)
    HTML:          3 files  (42K)
    Plain Text:    1 file   (4K)

  By month:
    2024-01:       5 files
    2024-02:       7 files

  Latest:          2024-02-08-chat-saver-iteration.md
  Oldest:          2024-01-03-project-setup.md
```

Notes:
- Use singular "file" when count is 1, plural "files" otherwise
- Sort months chronologically (oldest first)
- Omit "By format" rows for formats with 0 files
- If all files are the same format, still show the "By format" section for consistency
