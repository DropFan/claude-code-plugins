---
allowed-tools: Bash(pwd:*), Bash(date:*), Bash(mkdir:*), Bash(ls:*), Write, Read, AskUserQuestion
description: Save the current conversation to a document file
argument-hint: "[format: md|txt|html] [scope: full|summary]"
---

## Context

- Working directory: !`pwd`
- Current date: !`date '+%Y-%m-%d %H:%M'`

## Task

Save the current conversation to a document file. Parse user arguments and guide the export process.

**User arguments:** $ARGUMENTS

### Step 1: Parse Arguments

Parse the optional arguments from $ARGUMENTS:

- **format** — `md` (default), `txt`, or `html`
- **scope** — `full` (default) or `summary`

If $ARGUMENTS is empty, use defaults (md, full).

If arguments are ambiguous or invalid, use AskUserQuestion to let the user choose:

For format:
- `md` — Markdown format, preserves code blocks and formatting
- `txt` — Plain text, clean and portable
- `html` — HTML with styled layout, viewable in browser

For scope:
- `full` — Complete conversation history
- `summary` — Key decisions, code changes, and insights

### Step 2: Determine Topic

Analyze the conversation history to extract the main topic:

1. Identify the primary task or subject discussed
2. Generate 2-4 keywords in kebab-case
3. Prefer specific terms over generic ones (e.g., `fix-login-timeout` over `bug-fix`)

### Step 3: Prepare Output

1. Get the current date for the filename:
```bash
date '+%Y-%m-%d'
```

2. Construct the filename: `<date>-<topic>.<ext>`
   - Extension based on format: `.md`, `.txt`, or `.html`

3. Ensure the output directory exists:
```bash
mkdir -p ./chats
```

4. Check for filename collision using `ls`. If the file already exists, append `-2`, `-3`, etc.

### Step 4: Generate Content

Based on the chosen scope, generate the document content:

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

Follow the format templates from the `conversation-export` skill.

### Step 5: Save File

1. Write the generated content to `./chats/<filename>` using the Write tool
2. Report to the user:
   - Saved file path (absolute)
   - Format and scope used
   - File size approximation (number of lines)

### Example Output

```
Conversation saved!

  File: ./chats/2024-01-15-auth-implementation.md
  Format: Markdown (full)
  Lines: 156
```
