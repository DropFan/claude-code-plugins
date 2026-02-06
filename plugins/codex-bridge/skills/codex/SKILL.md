---
name: Codex Bridge
description: >
  This skill should be used when the user asks to "use codex", "ask codex",
  "let codex review", "get a second opinion", "compare with codex",
  "delegate to codex", "codex review my code", "have codex check this",
  or when cross-model verification, code review, or collaborative generation
  with OpenAI Codex CLI is needed. Also triggers on /codex and /codex-review commands.
version: 0.1.0
---

# Codex Bridge

Bridge OpenAI Codex CLI into Claude Code as an external sub-agent.
All interactions use non-interactive mode (`codex exec` / `codex review`),
output is captured via `-o` flag and integrated back into the current session.

## Prerequisites

- Codex CLI installed (verify: `codex --version`)
- OpenAI API key configured (fix: `codex login`)
- Git repository context (Codex requires a repo root)

## Two Core Commands

### `codex exec` — General Execution

```bash
codex exec --sandbox read-only -o "$(mktemp /tmp/codex-bridge-XXXXXXXX.md)" "<prompt>"
```

| Flag | Purpose |
|------|---------|
| `--sandbox read-only` | Default. No file writes. |
| `--sandbox workspace-write` | Allow file writes. Only when user explicitly requests. |
| `-o <file>` | Capture final response to file. Always use this. |
| `-C <dir>` | Set working directory. |
| `-m <model>` | Override model. Omit to use `~/.codex/config.toml` default. |

### `codex review` — Code Review

```bash
codex review --uncommitted                        # All uncommitted changes
codex review --base <branch>                      # Diff against branch
codex review --commit <sha>                       # Specific commit
codex review --uncommitted "<focus instructions>" # Custom focus
```

## Usage Patterns

### A. Code Review

1. Determine scope: uncommitted / branch diff / specific commit
2. Run `codex review` with matching flag
3. Present Codex findings to user
4. If requested, compare with Claude's own analysis

### B. Second Opinion / Verification

1. Gather context: what was done, what needs verification
2. Compose a focused prompt describing the specific question
3. Run `codex exec --sandbox read-only -o "$(mktemp /tmp/codex-bridge-XXXXXXXX.md)" "<prompt>"`
4. Read output, highlight agreements and disagreements with Claude's analysis

### C. Task Delegation

1. Compose a self-contained prompt (Codex has no access to conversation history)
2. Include: target files, constraints, expected output format
3. Choose sandbox mode: `read-only` for analysis, `workspace-write` for code generation
4. Run, capture, integrate result

> Note: `workspace-write` is not auto-approved by `/codex` command. User will be prompted to confirm.

### D. Collaborative Generation

1. Claude designs approach / writes spec
2. Delegate specific implementation to Codex via `codex exec --sandbox workspace-write`
3. Claude reads Codex output, reviews and integrates
4. Iterate: refine prompt or adjust approach based on results

> Note: Same as Pattern C — write operations require manual user approval.

### E. Document / Spec Review

Same as Pattern B, but prompt explicitly points to document paths:
```bash
codex exec --sandbox read-only -o "$(mktemp /tmp/codex-bridge-XXXXXXXX.md)" \
  "Review docs/designs/xxx.md for technical accuracy, completeness, and feasibility."
```

## Model Configuration

Codex model is configured in `~/.codex/config.toml`. Read this file to determine the default model before suggesting overrides.

Override only when needed:
```bash
codex exec -m <model-name> --sandbox read-only -o "$(mktemp /tmp/codex-bridge-XXXXXXXX.md)" "<prompt>"
```

## Output Handling

1. Always use `-o "$(mktemp /tmp/codex-bridge-XXXXXXXX.md)"` to capture output (unique path per invocation)
2. Read the output file with the Read tool
3. Present results clearly labeled as **Codex output**
4. Add Claude's own analysis when comparison is requested

## Safety Rules

1. **Default `--sandbox read-only`** — use `workspace-write` only on explicit user request
2. **Forbidden flags** — never append these to any codex command:
   - `--dangerously-bypass-approvals-and-sandbox` (disables all sandboxing)
   - `--full-auto` (escalates to workspace-write + auto-approve)
   - `--sandbox danger-full-access` (unrestricted filesystem access)
3. **Never pass secrets** (API keys, tokens, passwords) in Codex prompts
4. **Always use `-C`** to set working directory when it matters
5. **`/codex` command is read-only only** — `workspace-write` operations must go through direct Bash calls, which require manual user approval

## Error Handling

| Symptom | Action |
|---------|--------|
| `codex: command not found` | Suggest `npm install -g @openai/codex` |
| Authentication error | Suggest `codex login` |
| Timeout (no response >3min) | Simplify prompt, narrow scope, retry |
| Non-zero exit code | Show stderr, suggest adjustment |

## Additional Resources

- **`references/usage-patterns.md`** — Detailed prompt templates for each pattern
- **`scripts/codex-exec.sh`** — Standalone wrapper script for terminal use (not called by `/codex` or `/codex-review` commands). Provides timeout, parameter validation, and error handling. Useful for manual invocation or CI integration.
