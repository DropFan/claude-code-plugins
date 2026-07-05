# Claude Code Plugins Collection

<!-- This file mirrors CLAUDE.md. Keep the two in sync when editing either. -->

This is a Claude Code plugin marketplace repository.

## Repository Structure

```
.claude-plugin/
  marketplace.json      # Marketplace manifest, declares all available plugins
plugins/
  <plugin-name>/        # Self-developed plugin directory
    .claude-plugin/
      plugin.json       # Plugin metadata
    commands/            # User-invokable slash commands
    agents/              # Subagent definitions
    skills/              # Skill modules
    hooks/               # Hook configurations
scripts/
  sync-plugins.sh       # Sync plugin.json metadata to marketplace.json and README.md
  validate-plugins.sh   # Validate plugin structure and metadata (plugin.json, frontmatter, naming)
  verify-sync.sh        # Detect drift between plugin.json and marketplace.json (--run-sync to fix)
  lark-rebuild.py       # Rebuild the lark plugin from lark-cli skill sources
tests/
  run-tests.sh          # Automated test runner
  *-manual-tests.md     # Manual test checklists per plugin
.github/workflows/
  ci.yml                # CI: validate-plugins + verify-sync + tests
```

## Plugin Management

- **Self-developed plugins** — Source code lives directly under `plugins/<name>/`
- **Curated plugins** — Referenced in `marketplace.json` via GitHub source pointing to external repos

## Development Guidelines

### Adding a Self-developed Plugin

1. Create a plugin directory under `plugins/`
2. Create `.claude-plugin/plugin.json` with metadata (this is the single source of truth)
3. Add an entry to the `plugins` array in `marketplace.json` with a relative path as source
4. Run `bash scripts/sync-plugins.sh` to auto-sync metadata to `marketplace.json` and `README.md`

> **Note:** `plugin.json` is the single source of truth for self-developed plugins. Do NOT manually edit plugin metadata in `marketplace.json` or `README.md` — run the sync script instead. The sync covers the `description`, `version`, `author`, `keywords`, and `license` fields; other fields are not propagated.

### Maintenance Scripts

- `bash scripts/sync-plugins.sh` — run after changing any `plugin.json` to propagate metadata to `marketplace.json` and the README plugin table
- `bash scripts/validate-plugins.sh` — run before committing to validate plugin structure and metadata
- `bash scripts/verify-sync.sh` — run before committing to detect metadata drift (add `--run-sync` to fix it)
- `bash tests/run-tests.sh` — run the automated tests; manual checklists live in `tests/*-manual-tests.md`

CI (`.github/workflows/ci.yml`) runs validate-plugins, verify-sync, and the tests.

### Adding a Curated Plugin

Add an entry to the `plugins` array in `marketplace.json` using the GitHub source format:
```json
{
  "name": "plugin-name",
  "source": { "source": "github", "repo": "owner/repo" },
  "description": "Description"
}
```

### Component Naming Conventions

- Commands: `commands/<command-name>.md`
- Agents: `agents/<agent-name>.md`
- Skills: `skills/<skill-name>/SKILL.md`
- Hooks: `hooks/hooks.json`

### plugin.json Template

```json
{
  "name": "plugin-name",
  "description": "Plugin description",
  "version": "0.1.0",
  "author": {
    "name": "Tiger",
    "url": "https://github.com/DropFan"
  },
  "license": "MIT"
}
```
