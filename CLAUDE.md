# Claude Code Plugins Collection

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
```

## Plugin Management

- **Self-developed plugins** — Source code lives directly under `plugins/<name>/`
- **Curated plugins** — Referenced in `marketplace.json` via GitHub source pointing to external repos

## Development Guidelines

### Adding a Self-developed Plugin

1. Create a plugin directory under `plugins/`
2. Create `.claude-plugin/plugin.json` with metadata
3. Add an entry to the `plugins` array in `marketplace.json` with a relative path as source
4. **Update the Plugins table in the root `README.md`** (name, description, version)

> **Important:** When adding or modifying a plugin, always sync `marketplace.json` and the root `README.md` Plugins table to keep descriptions and versions consistent.

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
  "author": { "name": "Tiger" }
}
```
