# Update Plugins

Batch update all installed Claude Code plugins to their latest versions with a single command.

## Installation

```
/plugin marketplace add DropFan/claude-code-plugins
/plugin install update-plugins@tiger-plugins
```

## Commands

### `/update-plugins:update-plugins`

Update every installed plugin in one pass:

1. Runs `claude plugin list` to enumerate installed plugins
2. Runs `claude plugin update <name@marketplace>` for each one
3. Displays a summary table with each plugin's result (updated / already up-to-date / failed)
4. Reminds you to restart the session to apply updates

```
/update-plugins:update-plugins
```

## License

MIT
