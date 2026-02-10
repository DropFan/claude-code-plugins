#!/bin/bash
# Skill-extractor stop hook: suggest extracting patterns from methodology-rich conversations
# Parses transcript JSONL for structural signals and generates contextual messages
# Respects stop_hook setting in .claude/skill-extractor.local.md

INPUT=$(cat)

# Prevent infinite loop
if [ "$(echo "$INPUT" | jq -r '.stop_hook_active // false')" = "true" ]; then
  exit 0
fi

# Check user config: stop_hook enabled?
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
if [ -n "$CWD" ] && [ -f "$CWD/.claude/skill-extractor.local.md" ]; then
  HOOK_ENABLED=$(sed -n '/^---$/,/^---$/p' "$CWD/.claude/skill-extractor.local.md" | grep '^stop_hook:' | awk '{print $2}')
  if [ "$HOOK_ENABLED" = "false" ]; then
    exit 0
  fi
fi

TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // ""')
if [ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ]; then
  exit 0
fi

# Quick bail: tiny files never have extractable patterns
FILE_SIZE=$(wc -c < "$TRANSCRIPT" 2>/dev/null | tr -d ' ')
if [ "${FILE_SIZE:-0}" -lt 10240 ]; then
  exit 0
fi

# Single-pass extraction: user turns + tool names + created files
TOOL_DATA=$(jq -r '
  if .type == "user" then "USER"
  elif .type == "assistant" then
    .message.content[]? |
    if .type == "tool_use" then
      if (.name == "Write") then
        "CREATED:" + (.input.file_path // "" | split("/") | last)
      elif (.name == "Edit" or .name == "NotebookEdit") then
        "EDITED:" + (.input.file_path // "" | split("/") | last)
      else .name
      end
    else empty end
  else empty end
' "$TRANSCRIPT" 2>/dev/null)

UT=$(echo "$TOOL_DATA" | grep -c '^USER$')
WE=$(echo "$TOOL_DATA" | grep -cE '^(CREATED|EDITED):')
TC=$(echo "$TOOL_DATA" | grep -c '^Task$')

# Extractable patterns need code output + complexity
SCORE=$(( UT * 1 + WE * 5 + TC * 4 ))

if [ "$SCORE" -le 60 ]; then
  exit 0
fi

# Build contextual message describing what was built
CREATED=$(echo "$TOOL_DATA" | grep '^CREATED:' | sed 's/^CREATED://' | sort -u)
CREATED_COUNT=$(echo "$CREATED" | grep -c '.' || echo 0)
EDITED=$(echo "$TOOL_DATA" | grep '^EDITED:' | sed 's/^EDITED://' | sort -u)
EDITED_COUNT=$(echo "$EDITED" | grep -c '.' || echo 0)

if [ "$CREATED_COUNT" -gt 0 ]; then
  SHOWN=$(echo "$CREATED" | head -2 | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g')
  if [ "$CREATED_COUNT" -gt 2 ]; then
    MSG="Created ${SHOWN} and $((CREATED_COUNT - 2)) other files"
  else
    MSG="Created ${SHOWN}"
  fi
elif [ "$EDITED_COUNT" -gt 0 ]; then
  SHOWN=$(echo "$EDITED" | head -2 | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g')
  MSG="Developed workflow across ${SHOWN}"
elif [ "$TC" -gt 0 ]; then
  MSG="Multi-step investigation with ${TC} deep analyses"
else
  MSG="Methodology-rich session"
fi

echo "${MSG} — consider \`/skill-extractor:extract\`" >&2
exit 2
