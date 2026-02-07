---
name: Codex Bridge
description: >
  This skill should be used ONLY when the user explicitly mentions "codex" by name.
  Trigger phrases: "use codex", "ask codex", "let codex review", "compare with codex",
  "delegate to codex", "codex review my code", "have codex check this",
  "用 codex", "让 codex 看看", "codex 审查", "codex 帮我看", "用 codex 分析",
  "让 codex 帮忙", "交给 codex", "codex 看一下", "换 codex 看看".
  Do NOT trigger on generic phrases like "get a second opinion", "review my code",
  or "cross-model verification" unless the user explicitly mentions "codex".
version: 0.2.0
---

# Codex Bridge

Route user requests to the appropriate Codex command. Commands handle context collection, prompt composition, and result analysis autonomously.

## Safety

- Default sandbox: `read-only`. Only use `workspace-write` on explicit user request.
- Forbidden flags: `--dangerously-bypass-approvals-and-sandbox`, `--full-auto`, `--sandbox danger-full-access`
- Never pass secrets (API keys, tokens, passwords) in Codex prompts.

## Intent Classification & Routing

Classify the user's request and invoke the matching command:

### Review Intent → `/codex-bridge:codex-review`

Trigger when the request is about reviewing code changes, diffs, or commits.

Keywords: review, 审查, check changes, 看看改动, code review, PR review, diff review

Examples:
- "让 codex review 我的改动" → `/codex-bridge:codex-review`
- "codex 审查一下这个 PR" → `/codex-bridge:codex-review`
- "ask codex to review changes against main" → `/codex-bridge:codex-review main`

Pass any branch name, commit SHA, or review instructions as arguments.

### General Task → `/codex-bridge:codex`

Trigger for all other requests: analysis, verification, second opinion, document review, task delegation.

Keywords: analyze, verify, explain, compare, delegate, check, 分析, 验证, 看看, 帮忙看

Examples:
- "让 codex 分析这个函数的错误处理" → `/codex-bridge:codex "分析...的错误处理"`
- "ask codex about the auth implementation" → `/codex-bridge:codex "analyze the auth implementation"`
- "codex 帮我看看这个插件的安全性" → `/codex-bridge:codex "review the security of this plugin"`

Pass the user's full request as the argument. The command will resolve context and compose the prompt.

## Additional Resources

- **`references/usage-patterns.md`** — Detailed prompt templates for each usage pattern
- **`scripts/codex-exec.sh`** — Standalone wrapper script for terminal use
