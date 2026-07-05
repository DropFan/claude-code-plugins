#!/usr/bin/env bash
#
# sync-plugins.sh — Sync plugin metadata from plugin.json to marketplace.json and README.md
#
# Usage: bash scripts/sync-plugins.sh
#
# Data flow:
#   plugin.json (source of truth for self-developed plugins)
#     -> marketplace.json  (sync description, version, author, keywords, license)
#     -> README.md         (regenerate plugins table)
#
# Synced fields: description, version, author.name, author.url, keywords,
# license. Optional fields (author.url, keywords, license) are removed from
# the marketplace entry when absent from plugin.json.
#
# Writes are two-phase: every plugin.json is parsed and validated while the
# changes accumulate in temp files; marketplace.json and README.md are only
# replaced once all plugins have been processed successfully. If any
# plugin.json is invalid, both files are left untouched.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MARKETPLACE="$REPO_ROOT/.claude-plugin/marketplace.json"
README="$REPO_ROOT/README.md"
PLUGINS_DIR="$REPO_ROOT/plugins"

MARKETPLACE_TMP=""
JQ_TMP=""
REPLACE_TMP=""
README_TMP=""

cleanup() {
  rm -f "${MARKETPLACE_TMP:-}" "${JQ_TMP:-}" "${REPLACE_TMP:-}" "${README_TMP:-}" 2>/dev/null || true
}
trap cleanup EXIT

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

START_MARKER="<!-- PLUGINS_TABLE_START -->"
END_MARKER="<!-- PLUGINS_TABLE_END -->"

if ! grep -q "$START_MARKER" "$README" || ! grep -q "$END_MARKER" "$README"; then
  echo "Error: README.md is missing table markers ($START_MARKER / $END_MARKER)" >&2
  exit 1
fi

# --- Step 1: Stage marketplace.json updates and collect README table rows ---

MARKETPLACE_TMP="$(mktemp)"
cp "$MARKETPLACE" "$MARKETPLACE_TMP"

TABLE_ROWS=""

for plugin_json in "$PLUGINS_DIR"/*/.claude-plugin/plugin.json; do
  [[ -f "$plugin_json" ]] || continue
  plugin_dir="$(dirname "$(dirname "$plugin_json")")"
  plugin_name="$(basename "$plugin_dir")"

  name="$(jq -r '.name // empty' "$plugin_json")"
  desc="$(jq -r '.description // empty' "$plugin_json")"
  version="$(jq -r '.version // empty' "$plugin_json")"
  author_name="$(jq -r '.author.name // empty' "$plugin_json")"
  author_url="$(jq -r '.author.url // empty' "$plugin_json")"
  keywords="$(jq -c '.keywords // empty' "$plugin_json")"
  license="$(jq -r '.license // empty' "$plugin_json")"

  # Required fields must be present and non-empty before anything is written
  missing=""
  [[ -n "$name" ]] || missing="$missing name"
  [[ -n "$desc" ]] || missing="$missing description"
  [[ -n "$version" ]] || missing="$missing version"
  [[ -n "$author_name" ]] || missing="$missing author.name"
  if [[ -n "$missing" ]]; then
    echo "Error: $plugin_json is missing or has empty required field(s):$missing" >&2
    exit 1
  fi

  # Stage the marketplace entry (append if new, update in place otherwise)
  source_path="./plugins/$plugin_name"
  JQ_TMP="$(mktemp)"

  exists="$(jq --arg pname "$name" '[.plugins[] | select(.name == $pname)] | length' "$MARKETPLACE_TMP")"
  if [[ "$exists" -eq 0 ]]; then
    # Append new entry
    jq --arg pname "$name" \
       --arg src "$source_path" \
       --arg desc "$desc" \
       --arg ver "$version" \
       --arg aname "$author_name" \
       --arg aurl "$author_url" \
       --arg kw "$keywords" \
       --arg lic "$license" \
      '.plugins += [{
        name: $pname, source: $src, description: $desc, version: $ver,
        author: (if $aurl != "" then {name: $aname, url: $aurl} else {name: $aname} end)
      }
      + (if $kw != "" then {keywords: ($kw | fromjson)} else {} end)
      + (if $lic != "" then {license: $lic} else {} end)]' \
      "$MARKETPLACE_TMP" > "$JQ_TMP"
  else
    # Update existing entry
    jq --arg pname "$name" \
       --arg desc "$desc" \
       --arg ver "$version" \
       --arg aname "$author_name" \
       --arg aurl "$author_url" \
       --arg kw "$keywords" \
       --arg lic "$license" \
      '(.plugins[] | select(.name == $pname)) |=
        (.description = $desc | .version = $ver |
         .author = (if $aurl != "" then {name: $aname, url: $aurl} else {name: $aname} end) |
         (if $kw != "" then .keywords = ($kw | fromjson) else del(.keywords) end) |
         (if $lic != "" then .license = $lic else del(.license) end))' \
      "$MARKETPLACE_TMP" > "$JQ_TMP"
  fi
  mv "$JQ_TMP" "$MARKETPLACE_TMP"

  # Collect the README table row for this plugin
  if [[ -n "$author_url" ]]; then
    author_col="[${author_name}](${author_url})"
  else
    author_col="$author_name"
  fi
  TABLE_ROWS+="| [${name}](./plugins/${name}) | ${desc} | ${author_col} | \`/plugin install ${name}@tiger-plugins\` | ${version} |
"

  echo "Staged plugin '$name'"
done

# --- Step 2: Generate README plugins table ---

TABLE_HEADER="| Plugin | Description | Author | Install | Version |
|--------|-------------|--------|---------|---------|"

# Curated plugins (from marketplace.json, source is an object with "source": "github")
curated_count="$(jq '[.plugins[] | select(.source | type == "object")] | length' "$MARKETPLACE_TMP")"
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
     (.version // "—")] | @tsv' "$MARKETPLACE_TMP")
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

# --- Step 3: Commit staged changes (all plugins parsed successfully) ---

mv "$MARKETPLACE_TMP" "$MARKETPLACE"
echo "Updated marketplace.json"

mv "$README_TMP" "$README"
rm -f "$REPLACE_TMP"
echo "Updated README.md plugins table"
echo "Done."
