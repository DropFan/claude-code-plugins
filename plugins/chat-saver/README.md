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
| `raw-export` | Export raw data from JSONL session files | `/raw-export --format html --list` |
| `search` | Search saved conversations | `/search auth --from 2024-01-01` |
| `list` | List all saved files | `/list --sort date` |
| `clean` | Remove old files | `/clean --before 2024-01-01 --dry-run` |
| `stats` | Show statistics for saved files | `/stats` |
| `export` | Export to Notion/Feishu | `/export notion full` |
| `setup` | Initialize or update configuration | `/setup` |

> Tip: 本地开发时用 `--plugin-dir` 加载，也可以直接用 `/save-chat`。

## Usage

### Save Conversation

```
/chat-saver:save-chat                       # Save as Markdown (full)
/chat-saver:save-chat md summary            # Save Markdown summary
/chat-saver:save-chat html full             # Save full conversation as HTML
/chat-saver:save-chat txt                   # Save as plain text
/chat-saver:save-chat md full --append      # Append to existing file
/chat-saver:save-chat md full --raw         # Use raw JSONL data (100% complete)
```

### Raw Export

```
/chat-saver:raw-export                      # Export current session as Markdown
/chat-saver:raw-export --format html        # Export as styled HTML
/chat-saver:raw-export --list               # Browse and pick a session
/chat-saver:raw-export --format jsonl --full # Export all records as JSONL
```

### Search

```
/chat-saver:search auth                     # Search for "auth" in all files
/chat-saver:search "login bug" --date 2024-01-15    # Search on specific date
/chat-saver:search api --from 2024-01-01 --to 2024-01-31  # Date range
/chat-saver:search --tag debug              # List all files tagged "debug"
/chat-saver:search auth --tag backend       # Search "auth" in backend-tagged files
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

### Stats

```
/chat-saver:stats                           # Show statistics for saved files
```

### Export

```
/chat-saver:export notion                   # Export to Notion (full)
/chat-saver:export feishu summary           # Export summary to Feishu
```

### Setup

```
/chat-saver:setup                           # Interactive configuration wizard
                                            # Includes optional MCP export setup
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

Run `/chat-saver:setup` to interactively initialize configuration, or manually create `.claude/chat-saver.local.md` in your project root:

```markdown
---
default_format: md
default_scope: full
save_dir: ./chats
stop_hook: true
stop_hook_threshold: 50
---

<!-- Advanced options (edit manually if needed):
custom_header: ""
custom_footer: ""
-->
```

| Setting | Default | Description |
|---------|---------|-------------|
| `default_format` | `md` | Default output format |
| `default_scope` | `full` | Default content scope |
| `save_dir` | `./chats` | Directory for saved files |
| `stop_hook` | `true` | Enable session-end save suggestions (only takes effect when the Stop hook is enabled — see [Optional: Auto-save Prompt](#optional-auto-save-prompt)) |
| `stop_hook_threshold` | `50` | Score threshold for save suggestions (higher = less frequent); same prerequisite as `stop_hook` |
| `custom_header` | `""` | Text prepended to exports (manual edit only) |
| `custom_footer` | `""` | Text replacing default footer (manual edit only) |

Priority: command arguments > settings file > built-in defaults.

## MCP Export Setup

This plugin **does not ship pre-configured MCP servers**. There are two ways to set up MCP export:

### Option A: Use `/setup` (Recommended for new users)

Run `/chat-saver:setup` and select the MCP export option. The wizard will guide you through entering your token/URL and generate the MCP configuration automatically.

### Option B: Use existing MCP servers

If you already have Notion or Feishu MCP servers configured in your environment (project `.mcp.json` or `~/.claude/.mcp.json`), chat-saver will **auto-detect** them — no additional setup needed.

### Manual Configuration

#### Notion

1. Create a [Notion integration](https://www.notion.so/my-integrations) and get the token
2. Add `@notionhq/notion-mcp-server` to your `.mcp.json` with `NOTION_TOKEN`
3. Share target pages with the integration

#### Feishu (飞书)

1. Add a Feishu/Lark MCP server to your `.mcp.json`
2. Ensure the server is running

See `skills/conversation-export/references/mcp-export-guide.md` for detailed setup.

## Installation

Install from the marketplace. In Claude Code, add the marketplace first:

```
/plugin marketplace add DropFan/claude-code-plugins
```

Then install the plugin:

```
/plugin install chat-saver@tiger-plugins
```

For local development, load the plugin directly:

```bash
claude --plugin-dir /path/to/chat-saver
```

## Optional: Auto-save Prompt

The plugin ships with an optional `Stop` hook that scores the session activity (user turns, file edits, tasks, commands) and suggests saving valuable conversations before exiting. The hook is **disabled by default** — it is distributed as `hooks/hooks.json.disabled`.

To enable:
- Rename `hooks/hooks.json.disabled` to `hooks/hooks.json`

To disable again:
- Rename it back to `hooks/hooks.json.disabled`

Once enabled, the hook runs `hooks/stop-hook.sh`, which respects the `stop_hook` and `stop_hook_threshold` settings in `.claude/chat-saver.local.md`. While the hook is disabled, those two settings have no effect.

## File Structure

```
chat-saver/
├── .claude-plugin/
│   └── plugin.json                    # Plugin manifest
├── commands/
│   ├── save-chat.md                   # /save-chat — save conversation
│   ├── raw-export.md                  # /raw-export — export raw JSONL data
│   ├── export.md                      # /export — export to Notion/Feishu
│   ├── setup.md                       # /setup — initialize configuration
│   ├── search.md                      # /search — search conversations
│   ├── list.md                        # /list — list saved files
│   ├── clean.md                       # /clean — clean old files
│   └── stats.md                       # /stats — show statistics
├── scripts/
│   └── raw-export.sh                  # Raw JSONL export script (bash/jq)
├── skills/
│   └── conversation-export/
│       ├── SKILL.md                   # Export knowledge base
│       └── references/
│           ├── format-templates.md    # Format templates + append separators
│           ├── settings-loading.md    # Shared settings loading procedure
│           ├── settings-schema.md     # Settings configuration schema
│           └── mcp-export-guide.md    # MCP export setup guide
├── hooks/
│   ├── hooks.json.disabled            # Optional Stop hook (rename to hooks.json to enable)
│   └── stop-hook.sh                   # Stop hook script (session scoring + save suggestion)
└── README.md
```
