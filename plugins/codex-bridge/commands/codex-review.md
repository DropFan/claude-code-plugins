---
allowed-tools: Bash(pwd:*), Bash(codex review:*), Bash(codex --version:*), Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git show:*), Bash(git branch:*), Bash(git rev-parse:*), Read
description: Run OpenAI Codex code review on current changes or a specific branch/commit
argument-hint: "[branch | commit-sha | review instructions]"
---

## Context

- Working directory: !`pwd`
- Codex installed: !`codex --version 2>&1 || echo "NOT INSTALLED"`
- Current branch: !`git branch --show-current 2>/dev/null || echo "NOT A GIT REPO"`
- Uncommitted changes: !`git status --short 2>/dev/null | head -20`

## Task

Run Codex CLI code review with conversation-aware context enrichment.

**User arguments:** $ARGUMENTS

### Pre-checks

1. If Codex is not installed (version shows "NOT INSTALLED"), tell the user to install it with `npm install -g @openai/codex` and stop.
2. If not in a git repo (branch shows "NOT A GIT REPO"), tell the user this command requires a git repository and stop.

### Step 1: Determine Review Scope

Parse $ARGUMENTS to decide the review mode. When ambiguous, **verify with git** before deciding:

```bash
git branch --list "$ARGUMENTS"                        # non-empty output → branch
git rev-parse --verify "$ARGUMENTS^{commit}" 2>/dev/null  # success → valid commit
```

| $ARGUMENTS | Command |
|-----------|---------|
| Empty or `uncommitted` | `codex review --uncommitted` |
| Verified as a branch name | `codex review --base $ARGUMENTS` |
| Verified as a commit SHA | `codex review --commit $ARGUMENTS` |
| Contains natural language instructions | Compose enriched prompt (see Step 2), then `codex review "<enriched prompt>"` |

> **Note:** Codex CLI does not allow `--uncommitted` and `[PROMPT]` together. When custom instructions are provided, pass them as the positional argument without `--uncommitted` — Codex defaults to reviewing uncommitted changes.

### Step 2: Enrich with Conversation Context

Before running Codex, gather context from two sources:

**A. Git context** (always collect):
- For uncommitted: run `git diff --stat` to see affected files
- For branch: run `git diff --stat $ARGUMENTS...HEAD` to see the delta
- For commit: run `git show --stat $ARGUMENTS` to see the commit scope

**B. Conversation context** (collect when available):
- If the user discussed specific files or features in this conversation, note them as **review focus areas**
- If the user mentioned specific concerns (performance, security, error handling), include them as review priorities
- If the user recently worked on specific code with Claude, identify those files in the diff

**Compose enriched prompt** (when $ARGUMENTS contains natural language OR conversation context adds value):

Combine the user's instructions with conversation focus areas into a single review prompt:
```
<user's review instructions or "Review all changes">

Focus areas from conversation context:
- <file or concern discussed in conversation>
- <specific aspect the user cares about>

Files in scope: <list from git diff --stat>
```

Only enrich when context is genuinely relevant. Do not pad the prompt with generic instructions.

### Step 3: Run Codex Review

Execute the determined command from Step 1. Codex review writes output directly to stdout.

### Step 4: Present Results

1. Show Codex's review findings as-is, labeled as **Codex Review**
2. After Codex output, add a **Claude's Notes** section:
   - Relate Codex findings to the ongoing conversation — e.g., "Codex flagged X, which aligns with the concern you raised earlier about Y"
   - Highlight any findings where Claude agrees or disagrees based on deeper context
   - Flag anything Codex may have missed that Claude knows from the conversation (e.g., a design decision that explains seemingly odd code)
   - Keep this concise — 3-5 bullet points max
