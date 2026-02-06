#!/usr/bin/env bash
# codex-exec.sh — Wrapper for non-interactive Codex CLI execution
# Usage: codex-exec.sh [--mode review|exec] [--sandbox read-only|workspace-write] [--model MODEL] [--dir DIR] [--timeout SECS] "<prompt>"
#
# Examples:
#   codex-exec.sh --mode exec --sandbox read-only "Analyze this codebase"
#   codex-exec.sh --mode review --uncommitted
#   codex-exec.sh --mode exec --model <model-name> "Quick analysis"

set -eo pipefail

# Defaults
MODE="exec"
SANDBOX="read-only"
MODEL=""
WORKDIR=""
TIMEOUT=300
OUTPUT_FILE=""
EXTRA_ARGS=()
PROMPT=""

usage() {
    cat <<'USAGE'
Usage: codex-exec.sh [OPTIONS] "<prompt>"

Options:
  --mode exec|review     Execution mode (default: exec)
  --sandbox MODE         Sandbox policy: read-only, workspace-write (default: read-only)
  --model MODEL          Override model (default: use config.toml setting)
  --dir DIR              Working directory for Codex
  --timeout SECS         Timeout in seconds (default: 300)
  --output FILE          Write last message to file
  --uncommitted          (review mode) Review uncommitted changes
  --base BRANCH          (review mode) Review against branch
  --commit SHA           (review mode) Review specific commit
  --title TITLE          (review mode) Commit/PR title for context
  -h, --help             Show this help
USAGE
    exit 0
}

require_arg() {
    # $1 = remaining arg count from caller's $#, $2 = option name
    if [[ $1 -lt 2 ]]; then
        echo "ERROR: $2 requires a value" >&2; exit 1
    fi
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --mode)         require_arg $# "$1"; MODE="$2"; shift 2 ;;
        --sandbox)      require_arg $# "$1"; SANDBOX="$2"; shift 2 ;;
        --model)        require_arg $# "$1"; MODEL="$2"; shift 2 ;;
        --dir)          require_arg $# "$1"; WORKDIR="$2"; shift 2 ;;
        --timeout)      require_arg $# "$1"; TIMEOUT="$2"; shift 2 ;;
        --output)       require_arg $# "$1"; OUTPUT_FILE="$2"; shift 2 ;;
        --uncommitted)  EXTRA_ARGS+=("$1"); shift ;;
        --base|--commit|--title)
            require_arg $# "$1"; EXTRA_ARGS+=("$1" "$2"); shift 2 ;;
        -h|--help)      usage ;;
        --)             shift; PROMPT="$*"; break ;;
        -*)             echo "Unknown option: $1" >&2; exit 1 ;;
        *)
            if [[ -z "$PROMPT" ]]; then
                PROMPT="$1"
            else
                PROMPT="$PROMPT $1"
            fi
            shift ;;
    esac
done

# Validate --mode
if [[ "$MODE" != "exec" && "$MODE" != "review" ]]; then
    echo "ERROR: --mode must be 'exec' or 'review', got '$MODE'" >&2
    exit 1
fi

# Validate --sandbox (only allow safe values)
if [[ "$SANDBOX" != "read-only" && "$SANDBOX" != "workspace-write" ]]; then
    echo "ERROR: --sandbox must be 'read-only' or 'workspace-write', got '$SANDBOX'" >&2
    exit 1
fi

# Validate --timeout is a positive integer
if ! [[ "$TIMEOUT" =~ ^[0-9]+$ ]] || [[ "$TIMEOUT" -le 0 ]]; then
    echo "ERROR: --timeout must be a positive integer, got '$TIMEOUT'" >&2
    exit 1
fi

# Validate --output path (must resolve to /tmp/ or /private/tmp/ after canonicalization)
if [[ -n "$OUTPUT_FILE" ]]; then
    RESOLVED_OUTPUT="$(cd "$(dirname "$OUTPUT_FILE")" 2>/dev/null && pwd -P)/$(basename "$OUTPUT_FILE")" || true
    if [[ "$RESOLVED_OUTPUT" != /tmp/* && "$RESOLVED_OUTPUT" != /private/tmp/* ]]; then
        echo "ERROR: --output path must resolve to /tmp/, got '$OUTPUT_FILE' (resolved: '$RESOLVED_OUTPUT')" >&2
        exit 1
    fi
fi

# Verify codex is installed
if ! command -v codex &>/dev/null; then
    echo "ERROR: Codex CLI not found. Install with: npm install -g @openai/codex" >&2
    exit 127
fi

# Validate review mode: check mutually exclusive scope flags
if [[ "$MODE" == "review" ]]; then
    SCOPE_COUNT=0
    for arg in "${EXTRA_ARGS[@]}"; do
        case "$arg" in --uncommitted|--base|--commit) SCOPE_COUNT=$((SCOPE_COUNT + 1)) ;; esac
    done
    if [[ $SCOPE_COUNT -gt 1 ]]; then
        echo "ERROR: --uncommitted, --base, and --commit are mutually exclusive" >&2
        exit 1
    fi
fi

# Build command
CMD=(codex)

if [[ "$MODE" == "review" ]]; then
    CMD+=(review)
    [[ ${#EXTRA_ARGS[@]} -gt 0 ]] && CMD+=("${EXTRA_ARGS[@]}")
    [[ -n "$PROMPT" ]] && CMD+=("$PROMPT")
else
    CMD+=(exec)
    CMD+=(--sandbox "$SANDBOX")
    [[ -n "$MODEL" ]] && CMD+=(-m "$MODEL")
    [[ -n "$WORKDIR" ]] && CMD+=(-C "$WORKDIR")

    # Auto-generate output file if not specified (use mktemp to avoid predictable paths)
    if [[ -z "$OUTPUT_FILE" ]]; then
        OUTPUT_FILE="$(mktemp /tmp/codex-bridge-XXXXXXXX)"
    fi
    CMD+=(-o "$OUTPUT_FILE")

    [[ ${#EXTRA_ARGS[@]} -gt 0 ]] && CMD+=("${EXTRA_ARGS[@]}")
    [[ -n "$PROMPT" ]] && CMD+=("$PROMPT")
fi

# Execute with timeout (compatible with macOS and Linux)
echo "--- Codex Bridge ---"
echo "Mode: $MODE | Sandbox: $SANDBOX | Timeout: ${TIMEOUT}s"
[[ -n "$MODEL" ]] && echo "Model: $MODEL" || echo "Model: (config.toml default)"
echo "---"

EXIT_CODE=0
if command -v timeout &>/dev/null; then
    timeout "$TIMEOUT" "${CMD[@]}" || EXIT_CODE=$?
elif command -v gtimeout &>/dev/null; then
    gtimeout "$TIMEOUT" "${CMD[@]}" || EXIT_CODE=$?
else
    # Bash-based timeout fallback (macOS without coreutils)
    "${CMD[@]}" &
    CMD_PID=$!
    ( sleep "$TIMEOUT" && kill "$CMD_PID" 2>/dev/null ) &
    WATCHER_PID=$!
    wait "$CMD_PID" || EXIT_CODE=$?
    kill "$WATCHER_PID" 2>/dev/null
    wait "$WATCHER_PID" 2>/dev/null
fi

if [[ $EXIT_CODE -eq 124 || $EXIT_CODE -eq 143 ]]; then
    echo "ERROR: Codex timed out after ${TIMEOUT}s" >&2
fi

# If output file was used, print its path
if [[ -n "$OUTPUT_FILE" && -f "$OUTPUT_FILE" ]]; then
    echo ""
    echo "--- Output written to: $OUTPUT_FILE ---"
fi

exit $EXIT_CODE
