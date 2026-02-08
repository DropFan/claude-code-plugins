# chat-saver

Save Claude Code conversations to documents in multiple formats.

## Features

- **Multiple formats**: Markdown, plain text, HTML
- **Content scope**: Full conversation or intelligent summary
- **Smart naming**: Auto-extracts topic from conversation for filenames
- **Optional auto-prompt**: Hook reminds you to save valuable conversations (opt-in)

## Usage

### Command

```
/chat-saver:save-chat                    # Save as Markdown (full)
/chat-saver:save-chat md summary         # Save Markdown summary
/chat-saver:save-chat html full          # Save full conversation as HTML
/chat-saver:save-chat txt                # Save as plain text
```

> Tip: 本地开发时用 `--plugin-dir` 加载，也可以直接用 `/save-chat`。

Files are saved to `./chats/` in your project directory.

### Output Formats

| Format | Extension | Best For |
|--------|-----------|----------|
| `md`   | .md       | Reading in editors, version control |
| `txt`  | .txt      | Maximum portability |
| `html` | .html     | Viewing in browser with styling |

### Content Scope

| Scope | Description |
|-------|-------------|
| `full` | Complete conversation history |
| `summary` | Key decisions, code changes, insights, action items |

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
│   └── plugin.json              # Plugin manifest
├── commands/
│   └── save-chat.md             # /chat-saver:save-chat command
├── skills/
│   └── conversation-export/
│       ├── SKILL.md             # Export knowledge
│       └── references/
│           └── format-templates.md  # Detailed format templates
├── hooks/
│   └── hooks.json               # Optional Stop hook
└── README.md
```
