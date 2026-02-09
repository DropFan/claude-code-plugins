---
allowed-tools: Bash(pwd:*), Bash(date:*), Bash(mkdir:*), Bash(ls:*), Write, Read, Glob, AskUserQuestion
description: Save the current conversation to a document file
argument-hint: "[format: md|txt|html] [scope: full|summary] [--append] [--last N] [--from \"keyword\"]"
---

## Context

- Working directory: !`pwd`
- Current date: !`date '+%Y-%m-%d %H:%M'`

## Task

Save the current conversation to a document file. Parse user arguments and guide the export process.

**User arguments:** $ARGUMENTS

### Step 0: Load Settings

1. Use the Read tool to check if `.claude/chat-saver.local.md` exists in the project root
2. If it exists, parse the YAML frontmatter between `---` markers to extract:
   - `default_format` — fallback format if not specified in arguments
   - `default_scope` — fallback scope if not specified in arguments
   - `save_dir` — output directory (default: `./chats`)
   - `custom_header` — text to prepend to exported content
   - `custom_footer` — text to replace the default footer
3. If the file does not exist, silently use built-in defaults (no error)
4. Settings are overridden by explicit command arguments

### Step 1: Parse Arguments

Parse the optional arguments from $ARGUMENTS:

- **format** — `md` (default), `txt`, or `html`
- **scope** — `full` (default) or `summary`
- **--append** — Append to an existing file instead of creating a new one
- **--last N** — Only save the last N conversation turns (each User + Assistant pair = 1 turn)
- **--from "keyword"** — Save from the first turn containing the keyword to the end

If $ARGUMENTS is empty, use defaults (md, full, no append).

If arguments are ambiguous or invalid, use AskUserQuestion to let the user choose:

For format:
- `md` — Markdown format, preserves code blocks and formatting
- `txt` — Plain text, clean and portable
- `html` — HTML with styled layout, viewable in browser

For scope:
- `full` — Complete conversation history
- `summary` — Key decisions, code changes, and insights

### Step 1.5: Filter Conversation Range

If `--last` or `--from` is specified, filter the conversation before processing:

**`--last N`:**
- Count conversation turns (each User + Assistant pair = 1 turn)
- Keep only the last N turns
- If N exceeds total turns, keep the entire conversation (no error)

**`--from "keyword"`:**
- Scan conversation turns from the beginning
- Find the first turn where either the user message or assistant response contains the keyword (case-insensitive)
- Keep that turn and all subsequent turns
- If no turn matches, inform the user and ask whether to save the full conversation instead

**Combining filters:**
- `--last` and `--from` cannot be used together. If both are specified, inform the user and ask which one to use.

The filtered conversation is used for all subsequent steps (topic extraction, content generation, etc.).

### Step 2: Determine Topic

Analyze the conversation history to extract the main topic:

1. Identify the primary task or subject discussed
2. Generate 2-4 keywords in kebab-case
3. Prefer specific terms over generic ones (e.g., `fix-login-timeout` over `bug-fix`)

### Step 2.5: Check Existing Files (Append Mode)

If `--append` is set:

1. Use Glob to search `<save_dir>/*-<topic>.*` for files matching the current topic
2. If exactly one file is found, use it as the target file
3. If multiple files match, use AskUserQuestion to let the user choose which file to append to
4. If no matching file is found, inform the user and fall back to creating a new file (proceed to Step 3 as normal)
5. Store the target file path for use in Step 5

### Step 3: Prepare Output

1. Get the current date for the filename:
```bash
date '+%Y-%m-%d'
```

2. Construct the filename: `<date>-<topic>.<ext>`
   - Extension based on format: `.md`, `.txt`, or `.html`

3. Ensure the output directory exists (use `save_dir` from settings, default `./chats`):
```bash
mkdir -p <save_dir>
```

4. Check for filename collision using `ls`. If the file already exists, append `-2`, `-3`, etc.

### Step 4: Generate Content

Based on the chosen scope, generate the document content. **You MUST read `references/format-templates.md` from the `conversation-export` skill and strictly follow the templates** — including header metadata, content structure, and the footer.

**For `full` scope:**
- Export the entire conversation in the selected format
- Include all user messages and assistant responses
- Preserve code blocks with language tags
- Omit internal tool call metadata (tool names, parameters)
- Include meaningful tool output (file contents, command results)

**For `summary` scope:**
- Generate a structured summary containing:
  - **Topic** — One-line description
  - **Key Decisions** — Bullet list of decisions made
  - **Code Changes** — Files modified/created with descriptions
  - **Insights** — Important findings or patterns
  - **Action Items** — Unfinished follow-up tasks
  - **Key Code Snippets** — Important code worth preserving

**For append mode:**
- Generate content **without** the document header (title, metadata section)
- Prepend the format-appropriate continuation separator (see `references/format-templates.md`)
- The separator includes the current date/time to mark the continuation point

### Step 5: Save File

1. Write the generated content to `<save_dir>/<filename>` using the Write tool
   - If `custom_header` is set, prepend it before the main content
   - **Footer is MANDATORY** — every exported file must end with the plugin attribution footer:
     - If `custom_footer` is set in settings, use `custom_footer` as the footer
     - Otherwise, use the **exact** default footer from the template:
       - Markdown: `> Generated by [chat-saver](https://github.com/DropFan/claude-code-plugins/tree/master/plugins/chat-saver) plugin for Claude Code`
       - Plain text: `Generated by chat-saver plugin for Claude Code` + newline + `https://github.com/DropFan/claude-code-plugins/tree/master/plugins/chat-saver`
       - HTML: `<div class="footer">Generated by <a href="https://github.com/DropFan/claude-code-plugins/tree/master/plugins/chat-saver">chat-saver</a> plugin for <a href="https://claude.ai/download">Claude Code</a></div>`
   - **Do NOT omit the footer under any circumstances**
2. **Append mode:** Read the existing target file, concatenate existing content + separator + new content, then write the combined result using the Write tool. The footer must appear only once at the very end of the combined document.
3. Report to the user:
   - Saved file path (absolute)
   - Format and scope used
   - File size approximation (number of lines)
   - Whether it was a new file or an append

### Example Output

**New file:**
```
Conversation saved!

  File: ./chats/2024-01-15-auth-implementation.md
  Format: Markdown (full)
  Lines: 156
```

**Append:**
```
Conversation appended!

  File: ./chats/2024-01-15-auth-implementation.md
  Format: Markdown (full)
  Lines: 89 added (total: 245)
```
