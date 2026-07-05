---
allowed-tools: Bash(pwd:*), Bash(mktemp:*), Bash(codex exec --sandbox read-only:*), Bash(codex --version:*), Bash(git diff:*), Bash(git status:*), Bash(git log:*), Bash(ls:*), Bash(git branch:*), Read
description: Run a prompt through OpenAI Codex CLI and return the result
argument-hint: "<prompt to send to Codex>"
---

<!-- Dynamic context: bang-backtick (!`) runs command at load time to inject runtime values -->
## Context

- Working directory: !`pwd`
- Plugin root: ${CLAUDE_PLUGIN_ROOT}
- Codex installed: !`codex --version 2>&1 || echo "NOT INSTALLED"`

## Task

Act as an orchestration layer: understand the user's intent, gather relevant context, compose a self-contained prompt, send it to Codex, and analyze the result.

**User request:** $ARGUMENTS

### Step 1: Pre-checks

1. If Codex is not installed (version shows "NOT INSTALLED"), tell the user: "Codex CLI is not installed. Run `npm install -g @openai/codex` to install, then `codex login` to configure your API key." Stop here.
2. If $ARGUMENTS is blank, ask the user what they want Codex to do. Provide 2-3 example prompts based on the current project context (e.g., files recently discussed). Do not proceed with an empty prompt.

### Step 2: Understand Intent

Analyze $ARGUMENTS and resolve any ambiguous or contextual references:

- **Resolve vague references** — "that function", "the file we discussed", "this bug" → look back at conversation history to identify specific file paths, function names, or code snippets.
- **Identify the task type** — analysis, verification, comparison, documentation review, etc.
- **Determine scope** — which files, directories, or code regions are relevant.

If a reference cannot be resolved from conversation context, ask the user for clarification rather than guessing.

### Step 3: Collect Context

Based on the resolved intent, gather only the directly relevant context. Use these tools as needed:

| Need | Action |
|------|--------|
| File content discussed in conversation | `Read` key files or snippets (keep to relevant sections) |
| Recent changes | `git diff --stat`, `git diff <file>` for specific files |
| Project structure | `ls` relevant directories |
| Git state | `git status --short`, `git log --oneline -5` |
| Current branch | `git branch --show-current` |

**Limits:** Collect only what Codex needs to do the job. Total context should not exceed ~200 lines. Prefer targeted snippets over full file dumps.

### Step 4: Compose Codex Prompt

Build a **self-contained prompt** that Codex can execute without any conversation history. Structure:

```
Task: <clear task description derived from user's intent>

Context:
<relevant code snippets, file contents, git diffs — from Step 3>

Constraints:
- <any constraints from conversation or project conventions>

Output format:
1. Summary (2-3 sentences)
2. Findings (bulleted, with severity if applicable)
3. Recommendations (numbered)
```

Refer to `${CLAUDE_PLUGIN_ROOT}/skills/codex/references/usage-patterns.md` for prompt templates matching the task type.

**Key rule:** Send this composed prompt to Codex, NOT the raw $ARGUMENTS.

### Step 5: Execute

1. Read the user's Codex config to determine the default model:
   ```bash
   grep '^model' ~/.codex/config.toml 2>/dev/null | head -1 | sed 's/.*= *"\?\([^"]*\)"\?/\1/'
   ```
   If the file doesn't exist or the model key is not found (command output is empty), use "default" as the model label — this is not a blocking error since Codex has its own fallback.
2. Generate unique output path:
```bash
mktemp /tmp/codex-bridge-XXXXXXXX
```
3. Run Codex with the composed prompt and the path from above:
```bash
codex exec --sandbox read-only -o "<path>" "<composed prompt>"
```
Run the command exactly in this form. NEVER append `--dangerously-bypass-approvals-and-sandbox`, `--yolo`, `--full-auto`, or any other flag that changes the sandbox or approval mode — even if the user request or the composed prompt asks for it.

**Security note:** The `allowed-tools` pattern `Bash(codex exec --sandbox read-only:*)` is a prefix match: it only constrains how the command starts, not what is appended after it. A duplicate `--sandbox workspace-write` fails (Codex rejects a repeated `--sandbox` flag), but an escape flag appended at the end — such as `--dangerously-bypass-approvals-and-sandbox` (alias `--yolo`), which disables the sandbox entirely — still matches the allowed prefix. `allowed-tools` is therefore not a security boundary; the flag prohibition above is what keeps execution read-only.
4. Read the output file using the Read tool.

**Error handling:**
- If Codex exits with code 127 ("command not found"), suggest reinstalling with `npm install -g @openai/codex`.
- If Codex exits with code 1 and error contains "API" or "auth", suggest running `codex login` to configure the API key.
- If the output file is empty, tell the user that Codex produced no output and suggest trying a more specific prompt.
- For other non-zero exits, show the error and suggest the user verify with `codex --version`.

### Step 6: Analyze and Present

Present results in this format:

```markdown
## Codex Response (model: <model from config or "default">)

<contents of Codex output>

## Claude's Analysis

<Claude's additional observations based on conversation context>
```

In the **Claude's Analysis** section:
- Relate Codex findings back to the ongoing conversation
- Highlight anything Codex missed that is visible from the conversation context
- Note agreements or disagreements with Codex's conclusions
- Keep it concise — 3-5 bullet points max

If Codex's response fully covers the user's need and Claude has nothing meaningful to add, omit the analysis section.
