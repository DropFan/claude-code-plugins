# Codex Bridge

Bridge [OpenAI Codex CLI](https://github.com/openai/codex) into Claude Code for cross-model review, verification, task delegation and collaborative generation.

## Prerequisites

- [Codex CLI](https://github.com/openai/codex) installed: `npm install -g @openai/codex`
- OpenAI API key configured: `codex login`
- Working inside a git repository

## Commands

### `/codex-bridge:codex <prompt>`

Send a prompt to Codex CLI in read-only sandbox mode and return the result.

```
/codex-bridge:codex "Analyze the error handling in src/api/handler.go"
```

### `/codex-bridge:codex-review [branch | commit-sha | instructions]`

Run Codex code review on current changes or a specific branch/commit.

```
/codex-bridge:codex-review                          # Review uncommitted changes
/codex-bridge:codex-review main                     # Diff against main branch
/codex-bridge:codex-review abc1234                  # Review specific commit
/codex-bridge:codex-review "Focus on security"      # Review with custom focus
```

## Skill

The **Codex Bridge** skill triggers when the user explicitly mentions "codex" — e.g., "ask codex", "let codex review", "用 codex 分析", etc. The skill routes to the appropriate command, which automatically collects conversation context and project state to compose a self-contained prompt for Codex — so vague references like "that function" or "the file we discussed" are resolved before reaching Codex.

## Usage Patterns

| Pattern | Description | Sandbox |
|---------|-------------|---------|
| Code Review | Run `codex review` on changes | read-only |
| Second Opinion | Get Codex's take on a design decision | read-only |
| Task Delegation | Delegate implementation to Codex | workspace-write (requires approval) |
| Collaborative Generation | Claude designs, Codex implements | workspace-write (requires approval) |
| Document Review | Have Codex review specs/docs | read-only |

See [usage-patterns.md](./skills/codex/references/usage-patterns.md) for detailed prompt templates.

## Safety

- Default sandbox mode is `read-only` — no file writes
- `workspace-write` requires manual user approval
- Dangerous flags (`--dangerously-bypass-approvals-and-sandbox`, `--full-auto`, `--sandbox danger-full-access`) are explicitly forbidden
- Users should avoid passing secrets (API keys, tokens, passwords) in Codex prompts

## License

MIT
