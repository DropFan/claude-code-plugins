# Tiger's Claude Code Plugins

A [Claude Code](https://docs.anthropic.com/en/docs/claude-code) plugin marketplace — custom plugins and curated favorites.

## Usage

Add this marketplace to Claude Code:

```bash
/plugin marketplace add DropFan/claude-code-plugins
```

Then browse and install plugins:

```bash
/plugin install <plugin-name>@tiger-plugins
```

## Plugins

<!-- PLUGINS_TABLE_START -->
| Plugin | Description | Author | Install | Version |
|--------|-------------|--------|---------|---------|
| [chat-saver](./plugins/chat-saver) | Save, search, manage, and export Claude Code conversations to documents or external platforms | [Tiger](https://github.com/DropFan) | `/plugin install chat-saver@tiger-plugins` | 0.3.0 |
| [codex-bridge](./plugins/codex-bridge) | Bridge OpenAI Codex CLI into Claude Code for cross-model review, verification, task delegation and collaborative generation | [Tiger](https://github.com/DropFan) | `/plugin install codex-bridge@tiger-plugins` | 0.2.0 |
<!-- PLUGINS_TABLE_END -->

## Repository Structure

```
.claude-plugin/
  marketplace.json          # Marketplace manifest
plugins/
  <plugin-name>/            # Self-developed plugins
    .claude-plugin/
      plugin.json
    commands/               # Slash commands (/command-name)
    agents/                 # Subagent definitions
    skills/                 # Skill modules
    hooks/                  # Hook configurations
```

**Self-developed plugins** live under `plugins/` as source directories.

**Curated plugins** are referenced in `marketplace.json` via GitHub source — no code duplication.

## License

MIT
