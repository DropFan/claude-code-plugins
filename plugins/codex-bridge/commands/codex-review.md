---
allowed-tools: Bash(pwd:*), Bash(codex review:*), Bash(codex --version:*), Bash(wc:*), Bash(ls:*), Bash(tree:*), Bash(file:*), Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git show:*), Bash(git blame:*), Bash(git branch:*), Bash(git rev-parse:*), Read
description: Run OpenAI Codex code review on current changes or a specific branch/commit
argument-hint: "[branch | commit-sha | review instructions]"
---

## Context

- Working directory: !`pwd`
- Current branch: !`git branch --show-current 2>/dev/null || echo "not a git repo"`
- Uncommitted changes: !`git status --short 2>/dev/null | head -20`

## Task

Run Codex CLI code review and present findings.

**User arguments:** $ARGUMENTS

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
| Contains natural language instructions | `codex review --uncommitted "$ARGUMENTS"` |

### Step 2: Gather Context

Before running Codex, briefly review the changes to understand scope:
- For uncommitted: run `git diff --stat` to see affected files
- For branch: run `git diff --stat $ARGUMENTS...HEAD` to see the delta
- For commit: run `git show --stat $ARGUMENTS` to see the commit scope

This context helps compare Codex's findings with the actual changes later.

### Step 3: Run Codex Review

Execute the determined command. Codex review writes output directly to stdout.

### Step 4: Present Results

1. Show Codex's review findings as-is, labeled as **Codex Review**
2. After Codex output, add a brief **Claude's Notes** section:
   - Highlight any findings where Claude agrees or disagrees
   - Flag anything Codex may have missed based on the diff context from Step 2
   - Keep this concise — 2-3 bullet points max
