---
allowed-tools: Bash(pwd:*), Bash(codex exec --sandbox read-only:*), Bash(codex --version:*), Bash(wc:*), Bash(ls:*), Bash(tree:*), Bash(file:*), Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git show:*), Bash(git branch:*), Read
description: Run a prompt through OpenAI Codex CLI and return the result
argument-hint: "<prompt to send to Codex>"
---

## Context

- Working directory: !`pwd`
- Codex installed: !`codex --version 2>&1 || echo "NOT INSTALLED"`

## Task

Send the user's prompt to Codex CLI in non-interactive mode and return the result.

**User prompt:** $ARGUMENTS

### Execution Steps

1. **Pre-check**: If Codex is not installed (version shows "NOT INSTALLED"), tell the user to install it with `npm install -g @openai/codex` and stop.

2. **Empty prompt check**: If $ARGUMENTS is blank, ask the user what they want Codex to do. Do not run Codex with an empty prompt.

3. **Read default model**: Use the Read tool to read `~/.codex/config.toml` and extract the model name.

4. **Run Codex** (inline `mktemp` to generate unique output path):
```bash
codex exec --sandbox read-only -o "$(mktemp /tmp/codex-bridge-XXXXXXXX.md)" "$ARGUMENTS"
```

5. **Read output**: Use the Read tool to read the output file printed in the previous step.

6. **Present results** in this format:
```
### Codex Response (model: <model from config>)

<contents of output file>
```

Keep Claude's own commentary to a minimum. The user is asking for Codex's perspective, not Claude's interpretation.
