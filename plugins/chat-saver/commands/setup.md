---
allowed-tools: Bash(pwd:*), Bash(mkdir:*), Read, Write, AskUserQuestion
description: Initialize or update chat-saver configuration for the current project
---

## Context

- Working directory: !`pwd`
- Plugin root: ${CLAUDE_PLUGIN_ROOT}

## Task

Initialize or update the chat-saver settings file (`.claude/chat-saver.local.md`) for the current project, and optionally configure MCP export integration. Guide the user through each step interactively.

### Step 1: Check Existing Configuration

1. Use the Read tool to check if `.claude/chat-saver.local.md` exists in the project root
2. **If it exists:**
   - Parse and display the current settings in a readable table format
   - Use AskUserQuestion to ask:
     - **Update** — Modify the existing configuration (pre-fill current values as defaults)
     - **Reset** — Start fresh with all defaults
     - **Cancel** — Keep current configuration unchanged and exit
   - If user chooses Cancel, stop here
3. **If it does not exist:**
   - Inform the user that no configuration file was found, proceeding with setup

### Step 2: Configure Parameters

Guide the user through each parameter using AskUserQuestion. Ask all 4 questions in a **single** AskUserQuestion call.

**Question 1 — Default Format:**
- `md` — Markdown, preserves code blocks and formatting (Recommended)
- `txt` — Plain text, clean and portable
- `html` — HTML with styled layout, viewable in browser

**Question 2 — Default Scope:**
- `full` — Complete conversation history (Recommended)
- `summary` — Key decisions, code changes, and insights only

**Question 3 — Save Directory:**
- `./chats` — Default directory (Recommended)
- `./docs/conversations` — Under docs directory
- Custom — Let user specify a custom path

**Question 4 — Stop Hook:**
- `true` — Enable session-end suggestions (Recommended)
- `false` — Disable — never suggest saving at session end

**Question 5 — MCP Export:**
- **Skip** — I already have MCP configured, or don't need export (Recommended)
- **Notion** — Configure Notion export (requires API token)
- **Feishu** — Configure Feishu/飞书 export (requires server URL)
- **Both** — Configure both platforms

When in **Update** mode, show the current value for each parameter and include it as the recommended option. For Question 5, if the plugin's `.mcp.json` already exists at `${CLAUDE_PLUGIN_ROOT}/.mcp.json`, show the currently configured platforms.

### Step 3: Confirm Custom Values

If the user chose "Custom" for save directory, use AskUserQuestion to ask them to input the directory path.

### Step 4: Configure MCP Export

**If user chose Skip in Question 5, skip this entire step.**

1. **If Notion or Both:**
   - Use AskUserQuestion to ask the user for their Notion Integration Token
   - Validate: token should start with `ntn_` or `secret_` (inform user if format looks wrong, but don't block)

2. **If Feishu or Both:**
   - Use AskUserQuestion to ask the user for the Feishu MCP server URL
   - Provide default: `http://localhost:8090/sse`

3. **Write `.mcp.json`** to `${CLAUDE_PLUGIN_ROOT}/.mcp.json` with the configured servers:

**Notion only:**
```json
{
  "mcpServers": {
    "notion-mcp": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@notionhq/notion-mcp-server"],
      "env": {
        "NOTION_TOKEN": "<user_token>"
      }
    }
  }
}
```

**Feishu only:**
```json
{
  "mcpServers": {
    "feishu-mcp": {
      "type": "sse",
      "url": "<user_url>"
    }
  }
}
```

**Both:** merge both entries into the `mcpServers` object.

**If `.mcp.json` already exists:** read it first, merge new entries into the existing `mcpServers` object (do not overwrite unrelated servers), then write back.

### Step 5: Write Settings File

1. Ensure the `.claude/` directory exists:
```bash
mkdir -p .claude
```

2. Write the configuration file `.claude/chat-saver.local.md` with the selected values using the Write tool:

```markdown
---
default_format: <selected_format>
default_scope: <selected_scope>
save_dir: <selected_dir>
stop_hook: <true_or_false>
custom_header: ""
custom_footer: ""
---
```

**Rules:**
- **Always write ALL fields** into the YAML frontmatter, even if they match defaults — this makes the configuration explicit and self-documenting
- `custom_header` and `custom_footer` are always written as `""` — users can edit them manually later

### Step 6: Report

Display the final configuration summary:

```
chat-saver configured!

  Config: .claude/chat-saver.local.md
  Format: md
  Scope: full
  Save to: ./chats
  Stop hook: enabled

  MCP Export: Notion ✓ (configured in plugin .mcp.json)

  Tips:
  - Edit custom_header / custom_footer in the settings file to customize export branding
  - MCP tokens are stored in the plugin's .mcp.json — do not commit to version control
```

If MCP was skipped:
```
  MCP Export: skipped (auto-detects from your environment)
```

If this was an update, briefly note what changed compared to the previous configuration.
