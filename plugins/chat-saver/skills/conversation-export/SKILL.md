---
name: Conversation Export
description: This skill should be used when the user asks to "save the conversation", "export chat", "save chat history", "save our discussion", "export this conversation", "save dialogue", "save this session", "export as markdown", "export as HTML", "summarize and save", "保存对话", "导出对话", "保存聊天记录", "导出聊天", "保存会话", or wants to preserve the current Claude Code conversation as a structured document in Markdown, plain text, or HTML format.
version: 0.1.0
---

# Conversation Export

## Overview

Provide the ability to export Claude Code conversation content to structured documents. Support multiple output formats (Markdown, plain text, HTML) and content scopes (full conversation, summary).

## Output Formats

Three output formats are supported. For complete templates with full markup, see `references/format-templates.md`.

### Markdown (default)

Use heading-based structure with `## User` / `## Assistant` sections separated by `---`. Preserve code blocks with original language tags and inline code formatting. Include metadata header with topic, date, and project name.

### Plain Text

Use `[User]` / `[Assistant]` labels with `========` separators. Strip all Markdown formatting. Indent code blocks with 4 spaces. Clean and portable format.

### HTML

Generate self-contained HTML with embedded CSS. Use `.user` (blue tint) and `.assistant` (gray tint) styled containers. Wrap code in `<pre><code>` tags with dark theme. Escape HTML entities in code content.

## Content Scope

### Full Export

Export the entire conversation history as-is. Include all user messages and assistant responses. Preserve tool call results when they contain meaningful output. Omit internal tool call metadata (tool names, parameters) unless relevant to understanding.

### Summary Export

Generate a structured summary that captures the essential value:

1. **Topic** — One-line description of the conversation subject
2. **Key Decisions** — Bullet list of decisions made during the conversation
3. **Code Changes** — List of files modified/created with brief descriptions
4. **Insights** — Important findings, patterns discovered, or lessons learned
5. **Action Items** — Any follow-up tasks identified but not completed
6. **Key Code Snippets** — Important code blocks worth preserving (with file paths)

Target length: 20-30% of the original conversation.

## Topic Extraction

To determine the conversation topic for the filename:

1. Identify the primary task or subject discussed
2. Extract 2-4 keywords in kebab-case
3. Prefer specific terms over generic ones

Examples:
- Auth implementation discussion → `auth-implementation`
- Bug fix for login timeout → `fix-login-timeout`
- Database schema design → `db-schema-design`
- Code review of payment module → `review-payment-module`

## File Naming

Generate filenames in the format: `YYYY-MM-DD-<topic>.<ext>`

- Date: Use current date from system
- Topic: Extracted from conversation (see above)
- Extension: `.md`, `.txt`, or `.html` based on format
- On filename collision: Append `-2`, `-3`, etc. (e.g., `2024-01-15-auth-implementation-2.md`)

## Save Location

Default save directory: `./chats/` relative to the current working directory.

1. Check if `./chats/` exists; if not, create it
2. Check for filename collision; if exists, append counter suffix
3. Write the file to `./chats/<filename>`
4. Report the full path to the user

Edge cases:
- Empty conversation: Inform the user there is nothing to save
- Directory creation failure: Report the error and suggest an alternative path

## Additional Resources

### Reference Files

For detailed format templates, content processing rules, and message filtering guidelines:
- **`references/format-templates.md`** — Complete templates for each output format with CSS, content processing rules, and message filtering guidelines
