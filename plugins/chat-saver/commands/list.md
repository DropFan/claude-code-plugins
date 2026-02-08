---
allowed-tools: Bash(pwd:*), Bash(ls:*), Bash(wc:*), Bash(date:*), Read, Glob, AskUserQuestion
description: List all saved conversation files
argument-hint: "[--sort date|size|name] [--format md|txt|html]"
---

## Context

- Working directory: !`pwd`
- Current date: !`date '+%Y-%m-%d %H:%M'`

## Task

List all saved conversation files in the save directory. Display them in a formatted table with metadata.

**User arguments:** $ARGUMENTS

### Step 0: Load Settings

1. Use the Read tool to check if `.claude/chat-saver.local.md` exists
2. Extract `save_dir` (default: `./chats`)
3. If the file does not exist, use defaults silently

### Step 1: Parse Arguments

Parse optional arguments from $ARGUMENTS:

- **--sort** — Sort order: `date` (default, newest first), `size` (largest first), or `name` (alphabetical)
- **--format** — Filter by format: `md`, `txt`, or `html`. If omitted, show all formats

### Step 2: Scan Directory

1. Use Glob to find all files in `<save_dir>`:
   ```
   <save_dir>/*.md
   <save_dir>/*.txt
   <save_dir>/*.html
   ```
2. If no files are found, inform the user that no saved conversations exist and exit
3. If `--format` filter is set, only include files with the matching extension

### Step 3: Extract Metadata

For each file found:

1. Extract the date from the filename prefix (`YYYY-MM-DD`)
2. Extract the topic from the filename (between date and extension)
3. Determine the format from the extension
4. Get the line count using `wc -l`
5. Get the file size using `ls -lh`

### Step 4: Display Table

Present the results as a formatted table:

```
Saved Conversations (<save_dir>)
Showing N files, sorted by <sort_order>

  #  │ Date       │ Topic                │ Format │ Lines │ Size
 ────┼────────────┼──────────────────────┼────────┼───────┼──────
  1  │ 2024-01-15 │ auth-implementation  │ md     │  156  │ 12K
  2  │ 2024-01-14 │ fix-login-timeout    │ md     │   89  │  7K
  3  │ 2024-01-13 │ db-schema-design     │ html   │  234  │ 18K
```

### Step 5: Follow-up

After displaying the table, ask the user what they'd like to do next:

Use AskUserQuestion with options:
- **Read** — Open and display a specific file
- **Search** — Search within saved conversations
- **Clean** — Remove old or unwanted files
- **Done** — No further action

If the user chooses Read, ask which file number to open, then use the Read tool to display its content.
