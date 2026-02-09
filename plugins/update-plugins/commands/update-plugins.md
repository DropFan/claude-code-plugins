---
allowed-tools: Bash
description: Batch update all installed Claude Code plugins to latest versions
---

# Update All Plugins

Run the following steps to update all installed plugins:

1. Run `claude plugin list` to get the list of installed plugins
2. Parse the output to extract all plugin identifiers (format: `name@marketplace`)
3. For each plugin, run `claude plugin update <plugin-identifier>` and collect the results
4. After all updates complete, display a summary table showing each plugin and its update result (updated / already up-to-date / failed)
5. Remind the user to restart the session to apply updates
