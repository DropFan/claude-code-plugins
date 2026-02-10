#!/bin/bash
# Chat-saver stop hook: suggest saving for substantial conversations
# Parses transcript JSONL for structural signals and generates contextual messages
# Respects stop_hook setting in .claude/chat-saver.local.md

INPUT=$(cat)

# Prevent infinite loop
if [ "$(echo "$INPUT" | jq -r '.stop_hook_active // false')" = "true" ]; then
  exit 0
fi

# Check user config: stop_hook enabled?
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
if [ -n "$CWD" ] && [ -f "$CWD/.claude/chat-saver.local.md" ]; then
  HOOK_ENABLED=$(sed -n '/^---$/,/^---$/p' "$CWD/.claude/chat-saver.local.md" | grep '^stop_hook:' | awk '{print $2}')
  if [ "$HOOK_ENABLED" = "false" ]; then
    exit 0
  fi
fi

TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // ""')
if [ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ]; then
  exit 0
fi

# Quick bail: tiny files are never worth saving
FILE_SIZE=$(wc -c < "$TRANSCRIPT" 2>/dev/null | tr -d ' ')
if [ "${FILE_SIZE:-0}" -lt 10240 ]; then
  exit 0
fi

# Single-pass extraction: user turns + tool names + modified files
TOOL_DATA=$(jq -r '
  if .type == "user" then "USER"
  elif .type == "assistant" then
    .message.content[]? |
    if .type == "tool_use" then
      if (.name == "Write" or .name == "Edit" or .name == "NotebookEdit") then
        "FILE:" + (.input.file_path // "" | split("/") | last)
      else .name
      end
    else empty end
  else empty end
' "$TRANSCRIPT" 2>/dev/null)

UT=$(echo "$TOOL_DATA" | grep -c '^USER$')
WE=$(echo "$TOOL_DATA" | grep -c '^FILE:')
TC=$(echo "$TOOL_DATA" | grep -c '^Task$')
BC=$(echo "$TOOL_DATA" | grep -c '^Bash$')

SCORE=$(( UT * 2 + WE * 5 + TC * 3 + BC * 1 ))

if [ "$SCORE" -le 50 ]; then
  exit 0
fi

# Build contextual message from actual session activity
FILE_NAMES=$(echo "$TOOL_DATA" | grep '^FILE:' | sed 's/^FILE://' | sort -u)
FILE_COUNT=$(echo "$FILE_NAMES" | grep -c '.')

if [ "$FILE_COUNT" -gt 0 ]; then
  # Show up to 2 unique filenames
  FIRST_TWO=$(echo "$FILE_NAMES" | head -2 | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g')
  if [ "$FILE_COUNT" -gt 2 ]; then
    MSG="Modified ${FIRST_TWO} and $((FILE_COUNT - 2)) other files"
  else
    MSG="Modified ${FIRST_TWO}"
  fi
elif [ "$TC" -gt 0 ]; then
  MSG="Research session with ${UT} exchanges and ${TC} deep investigations"
else
  MSG="Session with ${UT} exchanges"
fi

echo "${MSG} — consider \`/chat-saver:save-chat\`" >&2
exit 2
