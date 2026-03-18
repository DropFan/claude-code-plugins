#!/usr/bin/env bash
#
# verify-sync.sh — Verify marketplace.json is in sync with plugin.json sources of truth
#
# Usage: bash scripts/verify-sync.sh [--run-sync]
#
# Checks:
#   1. Field-level comparison (description, version, author) per plugin
#   2. Orphan entries in marketplace.json (no plugin.json on disk)
#   3. Missing entries (plugin.json on disk but not in marketplace.json)
#   4. Optionally runs sync-plugins.sh and checks idempotency (--run-sync)
#
# Exit 0 if all in sync, exit 1 if any drift detected.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MARKETPLACE="$REPO_ROOT/.claude-plugin/marketplace.json"
PLUGINS_DIR="$REPO_ROOT/plugins"
SYNC_SCRIPT="$REPO_ROOT/scripts/sync-plugins.sh"

RUN_SYNC=false
if [[ "${1:-}" == "--run-sync" ]]; then
  RUN_SYNC=true
fi

# --- Preflight ---

if ! command -v jq &>/dev/null; then
  echo "Error: jq is required but not installed." >&2
  exit 1
fi

if [[ ! -f "$MARKETPLACE" ]]; then
  echo "Error: marketplace.json not found at $MARKETPLACE" >&2
  exit 1
fi

# --- Counters ---

MATCH_COUNT=0
DRIFT_COUNT=0

match() {
  echo "  [MATCH] $1"
  MATCH_COUNT=$((MATCH_COUNT + 1))
}

drift() {
  echo "  [DRIFT] $1"
  DRIFT_COUNT=$((DRIFT_COUNT + 1))
}

# --- Step 1: Field-level comparison for each self-developed plugin ---

declare -a DISK_PLUGINS=()

for plugin_json in "$PLUGINS_DIR"/*/.claude-plugin/plugin.json; do
  [[ -f "$plugin_json" ]] || continue

  plugin_dir="$(dirname "$(dirname "$plugin_json")")"
  plugin_name="$(basename "$plugin_dir")"
  DISK_PLUGINS+=("$plugin_name")

  echo ""
  echo "Checking sync: $plugin_name"

  # Read from plugin.json (source of truth)
  p_name="$(jq -r '.name' "$plugin_json")"
  p_desc="$(jq -r '.description' "$plugin_json")"
  p_version="$(jq -r '.version' "$plugin_json")"
  p_author_name="$(jq -r '.author.name' "$plugin_json")"
  p_author_url="$(jq -r '.author.url // empty' "$plugin_json")"

  # Check if plugin exists in marketplace.json
  m_exists="$(jq --arg pname "$p_name" '[.plugins[] | select(.name == $pname)] | length' "$MARKETPLACE")"
  if [[ "$m_exists" -eq 0 ]]; then
    drift "plugin '$p_name' not found in marketplace.json"
    continue
  fi

  # Read from marketplace.json
  m_desc="$(jq -r --arg pname "$p_name" '.plugins[] | select(.name == $pname) | .description' "$MARKETPLACE")"
  m_version="$(jq -r --arg pname "$p_name" '.plugins[] | select(.name == $pname) | .version' "$MARKETPLACE")"
  m_author_name="$(jq -r --arg pname "$p_name" '.plugins[] | select(.name == $pname) | .author.name' "$MARKETPLACE")"
  m_author_url="$(jq -r --arg pname "$p_name" '.plugins[] | select(.name == $pname) | (.author.url // empty)' "$MARKETPLACE")"
  m_source="$(jq -r --arg pname "$p_name" '.plugins[] | select(.name == $pname) | .source' "$MARKETPLACE")"

  # Compare description
  if [[ "$m_desc" == "$p_desc" ]]; then
    match "description"
  else
    drift "description: marketplace='$m_desc' vs plugin.json='$p_desc'"
  fi

  # Compare version
  if [[ "$m_version" == "$p_version" ]]; then
    match "version"
  else
    drift "version: marketplace='$m_version' vs plugin.json='$p_version'"
  fi

  # Compare author.name
  if [[ "$m_author_name" == "$p_author_name" ]]; then
    match "author.name"
  else
    drift "author.name: marketplace='$m_author_name' vs plugin.json='$p_author_name'"
  fi

  # Compare author.url (only if present in plugin.json)
  if [[ -n "$p_author_url" ]]; then
    if [[ "$m_author_url" == "$p_author_url" ]]; then
      match "author.url"
    else
      drift "author.url: marketplace='$m_author_url' vs plugin.json='$p_author_url'"
    fi
  else
    match "author.url (not required)"
  fi

  # Check source is local
  if [[ "$m_source" == "./plugins/"* ]]; then
    match "source is local path"
  else
    drift "source is not a local path: '$m_source'"
  fi

done

# --- Step 2: Detect orphan entries ---
# Marketplace entries with local source that have no plugin.json on disk

echo ""

orphan_found=false
while IFS= read -r entry_name; do
  entry_source="$(jq -r --arg pname "$entry_name" '.plugins[] | select(.name == $pname) | .source' "$MARKETPLACE")"

  # Only check local-source plugins
  if [[ "$entry_source" != "./plugins/"* ]]; then
    continue
  fi

  # Check if this plugin exists on disk
  found=false
  for dp in "${DISK_PLUGINS[@]}"; do
    if [[ "$dp" == "$entry_name" ]]; then
      found=true
      break
    fi
  done

  if ! $found; then
    drift "orphan entry in marketplace.json: '$entry_name' (no plugin.json on disk)"
    orphan_found=true
  fi
done < <(jq -r '.plugins[].name' "$MARKETPLACE")

if ! $orphan_found; then
  echo "No orphan entries in marketplace.json"
fi

# --- Step 3: Detect missing entries ---
# plugin.json on disk but not in marketplace.json

missing_found=false
for dp in "${DISK_PLUGINS[@]}"; do
  m_count="$(jq --arg pname "$dp" '[.plugins[] | select(.name == $pname)] | length' "$MARKETPLACE")"
  if [[ "$m_count" -eq 0 ]]; then
    drift "missing from marketplace.json: '$dp' (has plugin.json on disk)"
    missing_found=true
  fi
done

if ! $missing_found; then
  echo "No missing plugins from marketplace.json"
fi

# --- Step 4: Optional sync idempotency check ---

if $RUN_SYNC; then
  echo ""
  echo "Running sync idempotency check..."

  if [[ ! -f "$SYNC_SCRIPT" ]]; then
    echo "Error: sync-plugins.sh not found at $SYNC_SCRIPT" >&2
    exit 1
  fi

  # Save copies
  MARKETPLACE_BAK="$(mktemp)"
  README_BAK="$(mktemp)"
  cp "$MARKETPLACE" "$MARKETPLACE_BAK"
  cp "$REPO_ROOT/README.md" "$README_BAK"

  # Run sync
  bash "$SYNC_SCRIPT" >/dev/null 2>&1

  # Compare
  if diff -q "$MARKETPLACE_BAK" "$MARKETPLACE" >/dev/null 2>&1; then
    match "marketplace.json unchanged after sync (idempotent)"
  else
    drift "marketplace.json changed after running sync-plugins.sh"
    # Restore original
    cp "$MARKETPLACE_BAK" "$MARKETPLACE"
  fi

  if diff -q "$README_BAK" "$REPO_ROOT/README.md" >/dev/null 2>&1; then
    match "README.md unchanged after sync (idempotent)"
  else
    drift "README.md changed after running sync-plugins.sh"
    # Restore original
    cp "$README_BAK" "$REPO_ROOT/README.md"
  fi

  rm -f "$MARKETPLACE_BAK" "$README_BAK"
fi

# --- Summary ---

echo ""
total=$((MATCH_COUNT + DRIFT_COUNT))
if [[ $DRIFT_COUNT -eq 0 ]]; then
  echo "Summary: All plugins in sync ($MATCH_COUNT checks passed)"
  exit 0
else
  echo "Summary: $MATCH_COUNT matched, $DRIFT_COUNT drifted"
  exit 1
fi
