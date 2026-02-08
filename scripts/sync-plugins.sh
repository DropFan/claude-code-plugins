#!/usr/bin/env bash
#
# sync-plugins.sh — Sync plugin metadata from plugin.json to marketplace.json and README.md
#
# Usage: bash scripts/sync-plugins.sh
#
# Data flow:
#   plugin.json (source of truth for self-developed plugins)
#     -> marketplace.json  (sync description, version, author)
#     -> README.md         (regenerate plugins table)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MARKETPLACE="$REPO_ROOT/.claude-plugin/marketplace.json"
README="$REPO_ROOT/README.md"
PLUGINS_DIR="$REPO_ROOT/plugins"

# --- Preflight checks ---

if ! command -v jq &>/dev/null; then
  echo "Error: jq is required but not installed." >&2
  exit 1
fi

if [[ ! -f "$MARKETPLACE" ]]; then
  echo "Error: marketplace.json not found at $MARKETPLACE" >&2
  exit 1
fi

if [[ ! -f "$README" ]]; then
  echo "Error: README.md not found at $README" >&2
  exit 1
fi

# --- Step 1: Collect self-developed plugin metadata ---

declare -a SELF_PLUGINS=()

for plugin_json in "$PLUGINS_DIR"/*/.claude-plugin/plugin.json; do
  [[ -f "$plugin_json" ]] || continue
  plugin_dir="$(dirname "$(dirname "$plugin_json")")"
  plugin_name="$(basename "$plugin_dir")"
  SELF_PLUGINS+=("$plugin_name")

  name="$(jq -r '.name' "$plugin_json")"
  desc="$(jq -r '.description' "$plugin_json")"
  version="$(jq -r '.version' "$plugin_json")"
  author_name="$(jq -r '.author.name' "$plugin_json")"
  author_url="$(jq -r '.author.url // empty' "$plugin_json")"

  # --- Step 2: Update marketplace.json ---
  # Find the matching entry by name and update its fields
  MARKETPLACE_TMP="$(mktemp)"
  jq --arg pname "$name" \
     --arg desc "$desc" \
     --arg ver "$version" \
     --arg aname "$author_name" \
     --arg aurl "$author_url" \
    '(.plugins[] | select(.name == $pname)) |=
      (.description = $desc | .version = $ver |
       .author = (if $aurl != "" then {name: $aname, url: $aurl} else {name: $aname} end))' \
    "$MARKETPLACE" > "$MARKETPLACE_TMP"
  mv "$MARKETPLACE_TMP" "$MARKETPLACE"

  echo "Synced plugin '$name' to marketplace.json"
done

# --- Step 3: Generate README plugins table ---

TABLE_HEADER="| Plugin | Description | Author | Install | Version |
|--------|-------------|--------|---------|---------|"

TABLE_ROWS=""

# Self-developed plugins (from plugin.json)
for plugin_json in "$PLUGINS_DIR"/*/.claude-plugin/plugin.json; do
  [[ -f "$plugin_json" ]] || continue

  name="$(jq -r '.name' "$plugin_json")"
  desc="$(jq -r '.description' "$plugin_json")"
  version="$(jq -r '.version' "$plugin_json")"
  author_name="$(jq -r '.author.name' "$plugin_json")"
  author_url="$(jq -r '.author.url // empty' "$plugin_json")"

  if [[ -n "$author_url" ]]; then
    author_col="[${author_name}](${author_url})"
  else
    author_col="$author_name"
  fi

  TABLE_ROWS+="| [${name}](./plugins/${name}) | ${desc} | ${author_col} | \`/plugin install ${name}@tiger-plugins\` | ${version} |
"
done

# Curated plugins (from marketplace.json, source is an object with "source": "github")
curated_count="$(jq '[.plugins[] | select(.source | type == "object")] | length' "$MARKETPLACE")"
if [[ "$curated_count" -gt 0 ]]; then
  while IFS=$'\t' read -r name desc repo author_name author_url version; do
    if [[ -n "$author_url" ]]; then
      author_col="[${author_name}](${author_url})"
    else
      author_col="$author_name"
    fi
    version_col="${version:-—}"
    TABLE_ROWS+="| [${name}](https://github.com/${repo}) | ${desc} | ${author_col} | \`/plugin install ${name}@tiger-plugins\` | ${version_col} |
"
  done < <(jq -r '.plugins[] | select(.source | type == "object") |
    [.name, .description,
     .source.repo,
     (.author.name // "—"),
     (.author.url // ""),
     (.version // "—")] | @tsv' "$MARKETPLACE")
fi

# --- Step 4: Replace README table between markers ---

START_MARKER="<!-- PLUGINS_TABLE_START -->"
END_MARKER="<!-- PLUGINS_TABLE_END -->"

if ! grep -q "$START_MARKER" "$README" || ! grep -q "$END_MARKER" "$README"; then
  echo "Error: README.md is missing table markers ($START_MARKER / $END_MARKER)" >&2
  exit 1
fi

# Write replacement block to a temp file (awk -v can't handle multiline strings)
REPLACE_TMP="$(mktemp)"
{
  echo "$START_MARKER"
  echo "$TABLE_HEADER"
  printf "%s" "$TABLE_ROWS"
  echo "$END_MARKER"
} > "$REPLACE_TMP"

# Use awk to replace content between markers
README_TMP="$(mktemp)"
awk -v start="$START_MARKER" -v end="$END_MARKER" -v rfile="$REPLACE_TMP" '
  $0 == start {
    while ((getline line < rfile) > 0) print line
    close(rfile)
    skip=1; next
  }
  $0 == end   { skip=0; next }
  !skip       { print }
' "$README" > "$README_TMP"
mv "$README_TMP" "$README"
rm -f "$REPLACE_TMP"

echo "Updated README.md plugins table"
echo "Done."
