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
| [chat-saver](./plugins/chat-saver) | Save, search, manage, and export Claude Code conversations to documents or external platforms | [Tiger](https://github.com/DropFan) | `/plugin install chat-saver@tiger-plugins` | 0.6.1 |
| [codex-bridge](./plugins/codex-bridge) | Bridge OpenAI Codex CLI into Claude Code for cross-model review, verification, task delegation and collaborative generation | [Tiger](https://github.com/DropFan) | `/plugin install codex-bridge@tiger-plugins` | 0.3.2 |
| [lark](./plugins/lark) | Operate Feishu/Lark (IM, Docs, Base, Sheets, Calendar, Drive, Wiki, Task, OKR, VC, etc.) via the local lark-cli. Mirrors the Claude Code lark skill set for Cowork. 飞书/Lark 全套技能。 | [Tiger](https://github.com/DropFan) | `/plugin install lark@tiger-plugins` | 1.0.61 |
| [skill-extractor](./plugins/skill-extractor) | Extract reusable skills, commands, and agents from conversation history | [Tiger](https://github.com/DropFan) | `/plugin install skill-extractor@tiger-plugins` | 0.1.3 |
| [update-plugins](./plugins/update-plugins) | Batch update all installed Claude Code plugins with a single command | [Tiger](https://github.com/DropFan) | `/plugin install update-plugins@tiger-plugins` | 0.1.1 |
<!-- PLUGINS_TABLE_END -->

## Repository Structure

```
.claude-plugin/
  marketplace.json          # Marketplace manifest
plugins/
  <plugin-name>/            # Self-developed plugins
    .claude-plugin/
      plugin.json           # Plugin metadata (source of truth)
    commands/               # Slash commands (/command-name)
    agents/                 # Subagent definitions
    skills/                 # Skill modules
    hooks/                  # Hook configurations
scripts/                    # Maintenance scripts (sync, validate, verify)
tests/                      # Test runner and manual test checklists
.github/workflows/          # CI configuration
```

**Self-developed plugins** live under `plugins/` as source directories.

**Curated plugins** are referenced in `marketplace.json` via GitHub source — no code duplication.

## Development

For self-developed plugins, `plugins/<name>/.claude-plugin/plugin.json` is the single source of truth for metadata. Do not hand-edit their entries in `marketplace.json` or the plugin table above — the sync script regenerates both, and manual edits will be overwritten.

- `bash scripts/sync-plugins.sh` — sync `plugin.json` metadata (description, version, author, keywords, license) to `marketplace.json` and the README plugin table
- `bash scripts/validate-plugins.sh` — validate plugin structure and metadata
- `bash scripts/verify-sync.sh` — detect drift between `plugin.json` and `marketplace.json` (`--run-sync` to fix)
- `bash tests/run-tests.sh` — run the automated tests; manual checklists live in `tests/*-manual-tests.md`

CI (`.github/workflows/ci.yml`) runs validation, sync verification, and the tests.

## License

MIT
