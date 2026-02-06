# Codex Bridge — Prompt Templates & Usage Patterns

Detailed prompt templates for each usage pattern. All examples use `--sandbox read-only` unless explicitly noted.

> **Output paths:** Examples below use `/tmp/codex-bridge-XXXXXXXX` as a placeholder. In practice, always generate a unique path via `mktemp /tmp/codex-bridge-XXXXXXXX` to avoid conflicts between concurrent runs.

## Pattern A: Code Review

### Uncommitted Changes

```bash
codex review --uncommitted
```

With focused review criteria (note: `--uncommitted` and `[PROMPT]` are mutually exclusive in Codex CLI):

```bash
codex review "Focus on: 1) error handling completeness 2) potential race conditions 3) missing edge cases. Ignore formatting issues."
```

### Branch Diff

```bash
codex review --base main
codex review --base develop "Check for breaking API changes and backward compatibility"
```

### Specific Commit

```bash
codex review --commit abc1234
codex review --commit HEAD "Evaluate for security implications"
```

### With PR Title Context

```bash
codex review --uncommitted --title "feat: add user authentication middleware"
```

## Pattern B: Second Opinion / Verification

### Verify an Implementation Approach

```bash
codex exec --sandbox read-only -o /tmp/codex-bridge-XXXXXXXX \
  "Review the implementation in <file-path>. We chose <approach> because <reason>.
   Identify:
   1. Design issues or anti-patterns
   2. Unhandled edge cases
   3. Performance concerns
   4. Better alternatives (if any)"
```

### Cross-validate a Design Decision

```bash
codex exec --sandbox read-only -o /tmp/codex-bridge-XXXXXXXX \
  "We are deciding between:
   - Option A: <description>
   - Option B: <description>
   Goal: <what we're trying to achieve>
   Constraints: <relevant constraints>
   Analyze trade-offs and recommend the better option for this codebase."
```

### Verify Documentation Accuracy

```bash
codex exec --sandbox read-only -o /tmp/codex-bridge-XXXXXXXX \
  "Compare <doc-path> against the actual codebase.
   Flag: outdated information, missing sections, incorrect descriptions."
```

## Pattern C: Task Delegation

> **Safety:** `workspace-write` is NOT auto-approved by `/codex-bridge:codex` command. These examples require direct Bash calls, which will prompt for manual user approval. Never use `danger-full-access` or `--dangerously-bypass-approvals-and-sandbox`.

### Analyze Then Implement (Two-Step)

```bash
# Step 1: Read-only analysis
codex exec --sandbox read-only -o /tmp/codex-bridge-XXXXXXXX \
  "Analyze the codebase and propose how to implement <feature>.
   Output: file locations, function signatures, key design decisions."

# Step 2: Implement (only after reviewing proposal)
codex exec --sandbox workspace-write -C <project-dir> \
  "Implement <feature> following this plan: <paste from step 1 or summarize>"
```

### Delegate Test Writing

```bash
codex exec --sandbox workspace-write -C <project-dir> \
  "Write unit tests for <file-path>.
   Requirements:
   - Follow existing test patterns in <test-file-path>
   - Use table-driven tests
   - Cover: normal path, error paths, edge cases
   - Do not use third-party test frameworks"
```

### Delegate Refactoring

```bash
codex exec --sandbox workspace-write -C <project-dir> \
  "Refactor <file-path>: extract <logic> into a separate function.
   Constraints: preserve all existing behavior, all tests must still pass."
```

## Pattern D: Collaborative Generation

> **Safety:** Same as Pattern C — all `workspace-write` operations require manual user approval. Never use `danger-full-access` or `--dangerously-bypass-approvals-and-sandbox`.

### Workflow: Claude Designs, Codex Implements

1. Claude writes design spec or implementation plan
2. Delegate implementation of a specific section:

```bash
codex exec --sandbox workspace-write -C <project-dir> \
  "Based on the design at <doc-path>, implement the section titled '<section>'.
   Follow existing code patterns in the repo. Do not modify files outside <scope>."
```

3. Claude reviews Codex output with `git diff`, integrates or adjusts

### Workflow: Parallel Review

Run Codex review as a background check while Claude continues working:

```bash
codex review --uncommitted "Review all changes for correctness and style"
```

Claude reads the result afterward, addresses any issues found.

## Pattern E: Document / Spec Review

### Review Design Document

```bash
codex exec --sandbox read-only -o /tmp/codex-bridge-XXXXXXXX \
  "Review <doc-path>. Evaluate:
   1. Technical accuracy against the codebase
   2. Completeness — any missing scenarios?
   3. Feasibility — can the codebase support this design?
   4. Risks and concerns"
```

### Review API Specification

```bash
codex exec --sandbox read-only -o /tmp/codex-bridge-XXXXXXXX \
  "Review the OpenAPI spec at <spec-path>. Check:
   1. Naming consistency (snake_case for fields, plural resources)
   2. Missing error responses
   3. Schema completeness
   4. REST best practices"
```

## Prompt Composition Guidelines

### Scope: Be Specific

| Weak | Strong |
|------|--------|
| "Review the code" | "Review `internal/handler/session.go` focusing on error handling and HTTP status codes" |
| "Write tests" | "Write tests for `CreateSession` in `handler.go`. Table-driven, stdlib only, follow patterns in `session_test.go`" |

### Context: Codex Has No Conversation History

Codex runs as a fresh subprocess — it cannot see Claude's conversation context.
Always include in the prompt:
- Which files to look at
- What constraints apply
- What output format is expected

### Output Format: Set Expectations

```bash
codex exec --sandbox read-only -o /tmp/codex-bridge-XXXXXXXX \
  "Analyze <target>. Provide:
   1. Summary (2-3 sentences)
   2. Issues (bulleted, with severity: high/medium/low)
   3. Recommended actions (numbered)"
```

## Configuration Reference

### `~/.codex/config.toml`

```toml
model = "<your-model>"              # Default model (check `codex --help` for available models)
personality = "pragmatic"           # Response style
model_reasoning_effort = "high"     # low / medium / high
```

### CLI Overrides

```bash
# Override model
codex exec -m <other-model> --sandbox read-only -o /tmp/codex-bridge-XXXXXXXX "<prompt>"

# Override reasoning effort
codex exec -c 'model_reasoning_effort="medium"' --sandbox read-only -o /tmp/codex-bridge-XXXXXXXX "<prompt>"
```
