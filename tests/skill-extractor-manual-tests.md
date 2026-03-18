# skill-extractor Manual Test Checklist

Last updated: 2026-03-18
Plugin version: 0.1.1

## Prerequisites

- Claude Code installed and working
- skill-extractor plugin installed (verify: plugin directory exists at `plugins/skill-extractor/`)
- A conversation with enough history to contain extractable patterns (for normal flow tests)
- Terminal access for verifying hook script behavior
- `jq` installed (for hook tests; also test without jq for robustness verification)

## Test Cases

### TC-SE-001: Extract a skill from conversation

**Category:** Normal flow
**Prerequisites:** An active conversation where you have demonstrated a repeatable methodology (e.g., a debugging approach with multiple analysis steps)
**Steps:**
1. Have a conversation with Claude Code involving a multi-step problem-solving methodology (e.g., debug a performance issue by profiling, analyzing bottlenecks, and applying fixes)
2. Invoke `/skill-extractor:extract skill --name test-debug-skill`
3. Observe Claude's behavior through all steps (analyze, confirm, generate, preview, save)
4. Approve the generated file when prompted

**Expected Result:**
- Claude scans conversation history and identifies the debugging methodology as an extractable skill
- Claude presents a candidate with name, type, summary, and key content
- Generated `SKILL.md` has correct frontmatter: `name` and `description` fields (NO `version` field)
- The `description` field follows CSO principles (lists trigger phrases, not workflow summary)
- File is saved to the chosen location (e.g., `~/.claude/skills/test-debug-skill/SKILL.md`)
- Claude reports the result with type, name, file path, and usage instructions

**Pass criteria:** SKILL.md is created with correct frontmatter format; description contains trigger phrases; no version field present
**Status:** [ ] Not tested

---

### TC-SE-002: Extract a command from conversation

**Category:** Normal flow
**Prerequisites:** An active conversation where you have performed a repeatable sequence of tool calls or shell commands
**Steps:**
1. Have a conversation where you performed a specific workflow (e.g., build, test, deploy sequence)
2. Invoke `/skill-extractor:extract command --name test-deploy-cmd`
3. Review the generated command file
4. Approve when prompted

**Expected Result:**
- Claude identifies the operation sequence as a command pattern
- Generated command `.md` file has correct frontmatter: `allowed-tools`, `description`, and `argument-hint` fields
- The `allowed-tools` field only includes tools actually needed by the command
- File content has proper structure: Context section, Task section, numbered Steps
- File is saved to the chosen location

**Pass criteria:** Command .md file created with `allowed-tools` and `description` in frontmatter; proper step structure
**Status:** [ ] Not tested

---

### TC-SE-003: Extract an agent from conversation

**Category:** Normal flow
**Prerequisites:** An active conversation involving complex analysis with branching decisions and autonomous judgment
**Steps:**
1. Have a conversation involving a multi-file investigation or complex analysis workflow
2. Invoke `/skill-extractor:extract agent --name test-review-agent`
3. Review the generated agent file
4. Approve when prompted

**Expected Result:**
- Claude identifies the workflow as an agent pattern
- Generated agent `.md` file has correct frontmatter: `name`, `description`, `model`, `color`, `tools`
- File content includes Role, Process (with Steps), and Output sections
- File is saved to the chosen location

**Pass criteria:** Agent .md file created with proper frontmatter (name, description, model, color, tools); structured sections present
**Status:** [ ] Not tested

---

### TC-SE-004: Auto-detect extraction type

**Category:** Normal flow
**Prerequisites:** An active conversation with extractable patterns
**Steps:**
1. Have a conversation with a clear extractable pattern
2. Invoke `/skill-extractor:extract auto` (or `/skill-extractor:extract` without specifying type)
3. Observe Claude's type classification

**Expected Result:**
- Claude analyzes the conversation and suggests a component type (Skill, Command, or Agent)
- Claude uses AskUserQuestion to let the user confirm or override the suggested type
- The classification rationale is reasonable (methodology -> skill, operation sequence -> command, autonomous workflow -> agent)

**Pass criteria:** Auto-detection provides a reasonable type suggestion with rationale; user can confirm or override
**Status:** [ ] Not tested

---

### TC-SE-005: Skill auto-trigger via extract-component SKILL.md

**Category:** Normal flow
**Prerequisites:** skill-extractor plugin active; conversation with extractable patterns
**Steps:**
1. In a conversation with Claude Code, say "extract this as a skill" or "save this as a command"
2. Observe whether the SKILL.md triggers and routes to `/skill-extractor:extract`
3. Verify the correct type argument is passed based on the trigger phrase

**Expected Result:**
- SKILL.md recognizes trigger phrases like "extract skill", "save as command", "turn this into a skill"
- Claude routes to `/skill-extractor:extract` with the appropriate type argument
- The extraction workflow proceeds normally

**Pass criteria:** Skill triggers on recognized phrases and routes to extract command with correct type
**Status:** [ ] Not tested

---

### TC-SE-006: Extract from empty/minimal conversation

**Category:** Error handling
**Prerequisites:** Start a fresh conversation with almost no content (e.g., just a greeting)
**Steps:**
1. Start a new Claude Code conversation
2. Say only "hello" or a brief non-technical message
3. Invoke `/skill-extractor:extract skill --name test-empty`
4. Observe the response

**Expected Result:**
- Claude scans the conversation and finds no extractable patterns
- Claude informs the user gracefully: explains that no extractable patterns were found
- Claude does NOT generate an empty or meaningless component file
- No crash or unhandled error

**Pass criteria:** Graceful message about no patterns found; no file created; no crash
**Status:** [ ] Not tested

---

### TC-SE-007: Invalid output path (path traversal attempt)

**Category:** Error handling
**Phase 2 Fix:** SE-003 (path validation)
**Prerequisites:** skill-extractor plugin active; conversation with extractable patterns
**Steps:**
1. Have a conversation with an extractable pattern
2. Invoke `/skill-extractor:extract skill --name ../../../etc/evil`
3. Alternatively, when prompted for save location, provide a path containing `..` segments like `../../outside-project/test`
4. Observe the response

**Expected Result:**
- Claude detects `..` segments in the resolved path during path validation
- Claude rejects the path with a clear message explaining why (path traversal prevention)
- Claude asks for a corrected path
- No file is written to the traversal target

**Pass criteria:** Path traversal is blocked; clear rejection message; user prompted for corrected path
**Status:** [ ] Not tested

---

### TC-SE-008: Non-writable directory

**Category:** Error handling
**Phase 2 Fix:** SE-002, SE-003 related (directory error handling)
**Prerequisites:** Access to a read-only directory (e.g., create one with `chmod 444`)
**Steps:**
1. Create a read-only test directory:
   ```bash
   mkdir /tmp/readonly-test && chmod 444 /tmp/readonly-test
   ```
2. Have a conversation with an extractable pattern
3. Invoke extract and when prompted for save location, specify the read-only directory
4. Observe the response
5. Clean up: `chmod 755 /tmp/readonly-test && rmdir /tmp/readonly-test`

**Expected Result:**
- Claude attempts `mkdir -p` which fails due to permissions
- Claude detects the failure and informs the user with a specific error (e.g., "Permission denied")
- Claude asks for an alternative save path
- Or, if directory exists but is not writable, the `[ -w <dir> ]` check fails and Claude reports "NOT WRITABLE"

**Pass criteria:** Clear error message about permissions; user prompted for alternative path; no crash
**Status:** [ ] Not tested

---

### TC-SE-009: Sensitive data filtering

**Category:** Security (Phase 2 Fix Verification)
**Phase 2 Fix:** SE-005 (sensitive data filtering guidance)
**Prerequisites:** Active conversation that includes sensitive data patterns
**Steps:**
1. Have a conversation where you mention or use sensitive data:
   - An API key like `sk-test-12345abcdef`
   - A database URL like `postgres://user:password@internal-host:5432/db`
   - A personal file path like `/Users/yourname/secret-project/config.json`
   - A Bearer token like `Bearer ghp_abc123def456`
2. Develop a useful pattern in the conversation (e.g., an API integration workflow)
3. Invoke `/skill-extractor:extract skill --name test-api-integration`
4. Review the generated component carefully

**Expected Result:**
- Claude actively filters sensitive data during extraction
- API keys are replaced with placeholders like `<your-api-key>`
- Database URLs are replaced with `<your-database-url>`
- Personal paths have usernames replaced with `<username>` or `$HOME`
- Bearer tokens are replaced with `<your-token>`
- The generated component file does NOT contain any of the original sensitive values

**Pass criteria:** No sensitive data in generated output; all sensitive values replaced with descriptive placeholders
**Status:** [ ] Not tested

---

### TC-SE-010: Path validation instructions present in extract.md

**Category:** Security (Phase 2 Fix Verification)
**Phase 2 Fix:** SE-003 (path validation)
**Prerequisites:** Access to the extract.md source file
**Steps:**
1. Read `plugins/skill-extractor/commands/extract.md`
2. Locate Step 2d (save location selection)
3. Verify the path validation section exists and contains:
   - Check for `..` segments (path traversal prevention)
   - Verification that path is under home directory, working directory, or `~/.claude/`
   - Rejection of system directories (`/etc`, `/usr`, `/var`, `/bin`, `/sbin`, `/System`, `/Library`)
   - Instructions to inform user and ask for corrected path on validation failure

**Expected Result:**
- A "Path validation" section exists in Step 2d
- All three validation rules are documented (no `..`, allowed base paths, no system dirs)
- Failure handling instructs the LLM to inform user and request corrected path

**Pass criteria:** All path validation rules documented in extract.md; failure handling instructions present
**Status:** [ ] Not tested

---

### TC-SE-011: Very long conversation extraction

**Category:** Edge case
**Phase 2 Fix:** SE-011 (long conversation handling)
**Prerequisites:** A very long conversation (or simulate by having extensive back-and-forth with Claude)
**Steps:**
1. Build up a long conversation with many exchanges (>50 turns or extensive content)
2. Invoke `/skill-extractor:extract skill --name test-long-session`
3. Observe Claude's behavior

**Expected Result:**
- Claude focuses on the most recent exchanges first (as documented in the "For long conversations" guidance)
- If early parts were truncated or not analyzed, Claude informs the user: "Note: Only the most recent portion of the conversation was analyzed..."
- Extraction completes without crash or timeout
- Generated component contains meaningful content from the analyzed portion

**Pass criteria:** Long conversation handled without crash; user informed if partial analysis; meaningful output generated
**Status:** [ ] Not tested

---

### TC-SE-012: Special characters in component name

**Category:** Edge case
**Prerequisites:** Active conversation with extractable patterns
**Steps:**
1. Invoke `/skill-extractor:extract skill --name "my skill with spaces"`
2. Observe how the name is handled
3. Try again with unicode: `/skill-extractor:extract skill --name "test-"`
4. Try with shell metacharacters: `/skill-extractor:extract skill --name "test;rm -rf /"`

**Expected Result:**
- Spaces in names: either handled by converting to kebab-case or rejected with guidance
- Unicode characters: handled gracefully (accepted or rejected with clear message)
- Shell metacharacters: do NOT cause command injection; name is treated as data, not shell commands
- In all cases, the generated file path is safe and valid

**Pass criteria:** No shell injection from special characters; names handled safely (converted or rejected with guidance)
**Status:** [ ] Not tested

---

### TC-SE-013: Duplicate component name

**Category:** Edge case
**Prerequisites:** An existing component file at the target save location
**Steps:**
1. Extract a component with name "test-duplicate" and save it
2. Invoke `/skill-extractor:extract skill --name test-duplicate` again with the same name and same save location
3. Observe the response at Step 4c

**Expected Result:**
- Claude detects that the file already exists at the target path (Step 4c check)
- Claude warns the user about the existing file
- Claude asks whether to overwrite
- If user says no, Claude asks for an alternative name or cancels

**Pass criteria:** Existing file detected; user warned and prompted for overwrite decision
**Status:** [ ] Not tested

---

### TC-SE-014: stop-hook.sh robustness

**Category:** Hook verification
**Phase 2 Fix:** SE-004 (jq failure detection), SE-009 (variable defaults, fail-safe pattern)
**Prerequisites:** Terminal access; `jq` installed (test both with and without jq)
**Steps:**
1. **Test with valid input:** Create a mock JSONL transcript file with enough content (>10KB):
   ```bash
   # Create a mock transcript with enough data
   python3 -c "
   import json
   for i in range(200):
       if i % 3 == 0:
           print(json.dumps({'type': 'user', 'message': {'content': [{'type': 'text', 'text': f'message {i}'}]}}))
       elif i % 3 == 1:
           print(json.dumps({'type': 'assistant', 'message': {'content': [{'type': 'tool_use', 'name': 'Write', 'input': {'file_path': f'/tmp/test{i}.ts'}}]}}))
       else:
           print(json.dumps({'type': 'assistant', 'message': {'content': [{'type': 'tool_use', 'name': 'Task', 'input': {}}]}}))
   " > /tmp/test-transcript.jsonl
   ```
2. Run the hook with mock input:
   ```bash
   echo '{"cwd": "/tmp", "transcript_path": "/tmp/test-transcript.jsonl"}' | bash plugins/skill-extractor/hooks/stop-hook.sh
   ```
3. Check exit code: `echo $?` (should be 2 if score > 60, 0 otherwise)
4. **Test with missing jq:** Temporarily rename jq and run the hook:
   ```bash
   # Skip if you cannot temporarily remove jq from PATH
   PATH_BACKUP="$PATH"
   export PATH=$(echo "$PATH" | tr ':' '\n' | grep -v "$(dirname $(which jq))" | tr '\n' ':')
   echo '{"cwd": "/tmp", "transcript_path": "/tmp/test-transcript.jsonl"}' | bash plugins/skill-extractor/hooks/stop-hook.sh
   echo "Exit: $?"
   export PATH="$PATH_BACKUP"
   ```
5. **Test with malformed JSONL:** Create an invalid transcript and run:
   ```bash
   echo "not valid json" > /tmp/bad-transcript.jsonl
   dd if=/dev/urandom bs=1024 count=20 >> /tmp/bad-transcript.jsonl 2>/dev/null
   echo '{"cwd": "/tmp", "transcript_path": "/tmp/bad-transcript.jsonl"}' | bash plugins/skill-extractor/hooks/stop-hook.sh
   echo "Exit: $?"
   ```
6. Verify the script has the fail-safe comment (no `set -e`) and variable defaults

**Expected Result:**
- Valid input: hook calculates score and either exits 0 (low score) or exits 2 with suggestion message (high score)
- Missing jq: hook exits cleanly (exit 0) without crash
- Malformed JSONL: jq fails, `JQ_EXIT` is non-zero, hook detects the failure and exits 0 silently (Phase 2 fix: jq failure detection)
- Script header contains comment explaining why `set -e` is not used
- Variables like `FILE_SIZE` use default values (e.g., `${FILE_SIZE:-0}`)
- stderr output for jq errors is redirected to `/tmp/skill-extractor-jq-err`

**Pass criteria:** Hook never crashes; jq failure detected and handled silently; fail-safe patterns confirmed in source
**Status:** [ ] Not tested

---

## Test Summary

| ID | Name | Category | Phase 2 Fix | Status |
|----|------|----------|-------------|--------|
| TC-SE-001 | Extract a skill | Normal flow | - | [ ] |
| TC-SE-002 | Extract a command | Normal flow | - | [ ] |
| TC-SE-003 | Extract an agent | Normal flow | - | [ ] |
| TC-SE-004 | Auto-detect type | Normal flow | - | [ ] |
| TC-SE-005 | Skill auto-trigger | Normal flow | - | [ ] |
| TC-SE-006 | Empty conversation | Error handling | - | [ ] |
| TC-SE-007 | Path traversal | Error handling | SE-003 | [ ] |
| TC-SE-008 | Non-writable directory | Error handling | SE-002/SE-003 | [ ] |
| TC-SE-009 | Sensitive data filtering | Security | SE-005 | [ ] |
| TC-SE-010 | Path validation in source | Security | SE-003 | [ ] |
| TC-SE-011 | Long conversation | Edge case | SE-011 | [ ] |
| TC-SE-012 | Special characters | Edge case | - | [ ] |
| TC-SE-013 | Duplicate component name | Edge case | - | [ ] |
| TC-SE-014 | stop-hook.sh robustness | Hook verification | SE-004/SE-009 | [ ] |

**Total test cases:** 14
**Normal flow:** 5 | **Error handling:** 3 | **Security:** 2 | **Edge case:** 3 | **Hook verification:** 1
