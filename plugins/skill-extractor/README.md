# Skill Extractor

Analyze Claude Code conversation history and extract reusable patterns into component files — Skills, Commands, or Agents.

## Installation

```
/plugin marketplace add DropFan/claude-code-plugins
/plugin install skill-extractor@tiger-plugins
```

## Commands

### `/skill-extractor:extract [type] [--name <component-name>]`

Scan the current conversation for extractable patterns (methodologies, operation sequences, decision workflows), then interactively confirm the type, name, and save location before generating the component file.

- `type` — `skill`, `command`, `agent`, or `auto` (default: `auto`, analyzes and recommends a type)
- `--name <component-name>` — kebab-case name for the generated component

```
/skill-extractor:extract                              # Auto-detect candidates
/skill-extractor:extract skill                        # Extract as a Skill
/skill-extractor:extract command --name deploy-flow   # Extract as a Command with a given name
```

Generated files can be saved to `~/.claude/skills/`, `~/.claude/commands/`, the project's `.claude/` directory, or a plugin directory. The content is previewed for approval before writing, and sensitive data (API keys, tokens, personal paths, credentials) is filtered out during extraction.

## Skill

The **extract-component** skill triggers on phrases like "extract skill", "save as command", "turn this into a skill", "提取技能", "保存为技能", and routes to the `/skill-extractor:extract` command with the user's intent.

## Configuration

Optionally create `.claude/skill-extractor.local.md` in your project root:

```markdown
---
default_output_dir: ~/.claude/skills/
default_type: auto
stop_hook: true
---
```

| Setting | Default | Description |
|---------|---------|-------------|
| `default_output_dir` | `~/.claude/skills/` | Default save directory |
| `default_type` | `auto` | Default component type (`auto` / `skill` / `command` / `agent`) |
| `stop_hook` | `true` | Whether the Stop hook (if enabled, see below) makes suggestions in this project |

Priority: command arguments > settings file > built-in defaults.

## Hooks (disabled by default)

The plugin ships an optional `Stop` hook (`hooks/stop-hook.sh`) that scores the session transcript when a session ends — based on user turns, files created/edited, and subagent tasks — and suggests running `/skill-extractor:extract` for methodology-rich sessions.

The hook is **disabled by default**: the configuration ships as `hooks/hooks.json.disabled`. To enable it, rename `hooks/hooks.json.disabled` to `hooks/hooks.json` in the installed plugin directory and restart the session. To silence it for a single project while enabled, set `stop_hook: false` in `.claude/skill-extractor.local.md`.

## License

MIT
