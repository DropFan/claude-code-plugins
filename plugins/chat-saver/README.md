# chat-saver

Save, search, manage, and export Claude Code conversations.

## Features

- **Multiple formats**: Markdown, plain text, HTML
- **Content scope**: Full conversation or intelligent summary
- **Append mode**: Continue saving to an existing file across sessions
- **Search**: Find keywords in saved conversations with date filtering
- **List & Clean**: Browse and manage saved files with batch operations
- **MCP Export**: Export to Notion or Feishu (飞书) via MCP integration
- **Settings**: Customize defaults via local configuration file
- **Smart naming**: Auto-extracts topic from conversation for filenames
- **Optional auto-prompt**: Hook reminds you to save valuable conversations (opt-in)

## Commands

| Command | Description | Example |
|---------|-------------|---------|
| `save-chat` | Save conversation to a file | `/save-chat md summary --append` |
| `search` | Search saved conversations | `/search auth --from 2024-01-01` |
| `list` | List all saved files | `/list --sort date` |
| `clean` | Remove old files | `/clean --before 2024-01-01 --dry-run` |
| `export` | Export to Notion/Feishu | `/export notion full` |

> Tip: 本地开发时用 `--plugin-dir` 加载，也可以直接用 `/save-chat`。

## Usage

### Save Conversation

```
/chat-saver:save-chat                       # Save as Markdown (full)
/chat-saver:save-chat md summary            # Save Markdown summary
/chat-saver:save-chat html full             # Save full conversation as HTML
/chat-saver:save-chat txt                   # Save as plain text
/chat-saver:save-chat md full --append      # Append to existing file
```

### Search

```
/chat-saver:search auth                     # Search for "auth" in all files
/chat-saver:search "login bug" --date 2024-01-15    # Search on specific date
/chat-saver:search api --from 2024-01-01 --to 2024-01-31  # Date range
```

### List

```
/chat-saver:list                            # List all saved conversations
/chat-saver:list --sort size                # Sort by file size
/chat-saver:list --format md                # Show only Markdown files
```

### Clean

```
/chat-saver:clean                           # Interactive mode
/chat-saver:clean --before 2024-01-01       # Delete files older than date
/chat-saver:clean --keep 10                 # Keep only 10 most recent
/chat-saver:clean --dry-run                 # Preview without deleting
```

### Export

```
/chat-saver:export notion                   # Export to Notion (full)
/chat-saver:export feishu summary           # Export summary to Feishu
```

## Output Formats

| Format | Extension | Best For |
|--------|-----------|----------|
| `md`   | .md       | Reading in editors, version control |
| `txt`  | .txt      | Maximum portability |
| `html` | .html     | Viewing in browser with styling |

## Content Scope

| Scope | Description |
|-------|-------------|
| `full` | Complete conversation history |
| `summary` | Key decisions, code changes, insights, action items |

## Settings

Create `.claude/chat-saver.local.md` in your project root to customize defaults:

```markdown
---
default_format: md
default_scope: full
save_dir: ./chats
custom_header: ""
custom_footer: ""
---
```

| Setting | Default | Description |
|---------|---------|-------------|
| `default_format` | `md` | Default output format |
| `default_scope` | `full` | Default content scope |
| `save_dir` | `./chats` | Directory for saved files |
| `custom_header` | `""` | Text prepended to exports |
| `custom_footer` | `""` | Text replacing default footer |

Priority: command arguments > settings file > built-in defaults.

## MCP Export Setup

The plugin supports exporting to external platforms via MCP servers. Configure in `.mcp.json`:

### Notion

1. Create a [Notion integration](https://www.notion.so/my-integrations) and get the token
2. Set `NOTION_TOKEN` in `.mcp.json`
3. Share target pages with the integration

### Feishu (飞书)

1. Start the Feishu MCP SSE server locally
2. The default URL is `http://localhost:8090/sse`

See `skills/conversation-export/references/mcp-export-guide.md` for detailed setup.

## Installation

Add to your Claude Code plugins:

```bash
claude plugin add /path/to/chat-saver
```

Or use with `--plugin-dir`:

```bash
claude --plugin-dir /path/to/chat-saver
```

## Optional: Auto-save Prompt

The plugin includes an optional `Stop` hook that intelligently detects valuable conversations and suggests saving before exiting. This hook is **included but can be disabled**.

To disable:
- Rename `hooks/hooks.json` to `hooks/hooks.json.disabled`

To re-enable:
- Rename back to `hooks/hooks.json`

## File Structure

```
chat-saver/
├── .claude-plugin/
│   └── plugin.json                    # Plugin manifest
├── .mcp.json                          # Notion + Feishu MCP config
├── commands/
│   ├── save-chat.md                   # /save-chat — save conversation
│   ├── search.md                      # /search — search conversations
│   ├── list.md                        # /list — list saved files
│   ├── clean.md                       # /clean — clean old files
│   └── export.md                      # /export — export to Notion/Feishu
├── skills/
│   └── conversation-export/
│       ├── SKILL.md                   # Export knowledge base
│       └── references/
│           ├── format-templates.md    # Format templates + append separators
│           ├── settings-schema.md     # Settings configuration schema
│           └── mcp-export-guide.md    # MCP export setup guide
├── hooks/
│   └── hooks.json                     # Optional Stop hook
└── README.md
```
