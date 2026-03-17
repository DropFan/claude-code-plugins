# Settings Loading

## Procedure

1. Use the Read tool to check if `.claude/chat-saver.local.md` exists in the project root
2. If it exists, parse the YAML frontmatter between the opening `---` and closing `---` markers to extract settings
3. If the file does not exist, silently use built-in defaults (no error, no warning)
4. Priority: command arguments > settings file > built-in defaults

## Available Fields

| Field | Type | Default | Used By |
|-------|------|---------|---------|
| `default_format` | `md` \| `txt` \| `html` | `md` | save-chat, raw-export |
| `default_scope` | `full` \| `summary` | `full` | save-chat, export |
| `save_dir` | string (path) | `./chats` | all commands |
| `stop_hook` | `true` \| `false` | `true` | stop hook |
| `stop_hook_threshold` | integer | `50` | stop hook |
| `custom_header` | string | `""` | save-chat |
| `custom_footer` | string | `""` | save-chat, raw-export, export |

Commands only need to extract the fields listed in their "Used By" column. Unknown keys are silently ignored.
