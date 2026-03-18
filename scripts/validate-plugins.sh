#!/usr/bin/env bash
#
# validate-plugins.sh — Validate structure and metadata of all self-developed plugins
#
# Usage: bash scripts/validate-plugins.sh
#
# Validates:
#   1. plugin.json schema (required fields, semver, name consistency)
#   2. Required file existence (commands or skills)
#   3. Command file validation (frontmatter with description + allowed-tools)
#   4. Skill file validation (frontmatter with name + description)
#   5. Naming conventions (kebab-case directories)
#
# Exit 0 if all checks pass, exit 1 if any fail.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLUGINS_DIR="$REPO_ROOT/plugins"

# --- Preflight ---

if ! command -v jq &>/dev/null; then
  echo "Error: jq is required but not installed." >&2
  exit 1
fi

# --- Counters ---

PASS_COUNT=0
FAIL_COUNT=0

pass() {
  echo "  [PASS] $1"
  PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
  echo "  [FAIL] $1"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

# --- Helper: check kebab-case ---
# kebab-case: lowercase letters, digits, hyphens only
is_kebab_case() {
  [[ "$1" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]]
}

# --- Helper: extract frontmatter field value ---
# Reads YAML frontmatter from a file and extracts a field value.
# Returns empty string if field not found.
get_frontmatter_field() {
  local file="$1"
  local field="$2"
  # Read between first --- and second ---, then grep for field
  awk '/^---$/{n++; next} n==1{print} n>=2{exit}' "$file" \
    | grep -E "^${field}:" \
    | sed "s/^${field}:[[:space:]]*//" \
    | sed 's/^"\(.*\)"$/\1/' \
    | sed "s/^'\(.*\)'$/\1/" \
    || true
}

# --- Main validation ---

found_plugins=0

for plugin_dir in "$PLUGINS_DIR"/*/; do
  [[ -d "$plugin_dir" ]] || continue

  plugin_name="$(basename "$plugin_dir")"
  plugin_json="$plugin_dir/.claude-plugin/plugin.json"

  # Skip if no plugin.json (not a self-developed plugin with metadata)
  [[ -f "$plugin_json" ]] || continue

  found_plugins=$((found_plugins + 1))
  echo ""
  echo "Validating plugin: $plugin_name"

  # === 1. plugin.json schema validation ===

  pass "plugin.json exists"

  # Required string fields: name, description, version
  for field in name description version; do
    val="$(jq -r ".$field // empty" "$plugin_json")"
    if [[ -n "$val" ]]; then
      pass "plugin.json has required field: $field"
    else
      fail "plugin.json missing or empty field: $field"
    fi
  done

  # author must be an object with non-empty .name
  author_name="$(jq -r '.author.name // empty' "$plugin_json")"
  if [[ -n "$author_name" ]]; then
    pass "plugin.json has required field: author.name"
  else
    fail "plugin.json missing or empty field: author.name"
  fi

  # version must match semver pattern X.Y.Z
  version="$(jq -r '.version // empty' "$plugin_json")"
  if [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    pass "version matches semver format ($version)"
  else
    fail "version does not match semver format: '$version' (expected X.Y.Z)"
  fi

  # name must match directory name
  json_name="$(jq -r '.name // empty' "$plugin_json")"
  if [[ "$json_name" == "$plugin_name" ]]; then
    pass "plugin.json name matches directory name ($plugin_name)"
  else
    fail "plugin.json name '$json_name' does not match directory name '$plugin_name'"
  fi

  # === 2. Required file existence ===

  has_commands=false
  has_skills=false

  if [[ -d "$plugin_dir/commands" ]]; then
    cmd_files=("$plugin_dir"/commands/*.md)
    if [[ -f "${cmd_files[0]}" ]]; then
      has_commands=true
    fi
  fi

  if [[ -d "$plugin_dir/skills" ]]; then
    for skill_dir in "$plugin_dir"/skills/*/; do
      if [[ -f "${skill_dir}SKILL.md" ]]; then
        has_skills=true
        break
      fi
    done
  fi

  if $has_commands || $has_skills; then
    pass "has at least one command or skill"
  else
    fail "no commands/*.md or skills/*/SKILL.md found"
  fi

  # === 3. Command file validation ===

  if [[ -d "$plugin_dir/commands" ]]; then
    for cmd_file in "$plugin_dir"/commands/*.md; do
      [[ -f "$cmd_file" ]] || continue
      cmd_basename="$(basename "$cmd_file" .md)"

      # Check kebab-case filename
      if is_kebab_case "$cmd_basename"; then
        pass "commands/$cmd_basename.md filename is kebab-case"
      else
        fail "commands/$cmd_basename.md filename is not kebab-case"
      fi

      # Check frontmatter exists
      first_line="$(head -1 "$cmd_file")"
      if [[ "$first_line" == "---" ]]; then
        pass "commands/$cmd_basename.md has frontmatter"
      else
        fail "commands/$cmd_basename.md missing frontmatter (no opening ---)"
        continue
      fi

      # Check description field in frontmatter
      desc_val="$(get_frontmatter_field "$cmd_file" "description")"
      if [[ -n "$desc_val" ]]; then
        pass "commands/$cmd_basename.md has description"
      else
        fail "commands/$cmd_basename.md missing description in frontmatter"
      fi

      # Check allowed-tools field in frontmatter
      tools_val="$(get_frontmatter_field "$cmd_file" "allowed-tools")"
      if [[ -n "$tools_val" ]]; then
        pass "commands/$cmd_basename.md has allowed-tools"
      else
        fail "commands/$cmd_basename.md missing allowed-tools in frontmatter"
      fi
    done
  fi

  # === 4. Skill file validation ===

  if [[ -d "$plugin_dir/skills" ]]; then
    for skill_subdir in "$plugin_dir"/skills/*/; do
      [[ -d "$skill_subdir" ]] || continue
      skill_name="$(basename "$skill_subdir")"
      skill_file="$skill_subdir/SKILL.md"

      # Check skill directory name is kebab-case
      if is_kebab_case "$skill_name"; then
        pass "skills/$skill_name/ directory name is kebab-case"
      else
        fail "skills/$skill_name/ directory name is not kebab-case"
      fi

      if [[ ! -f "$skill_file" ]]; then
        fail "skills/$skill_name/SKILL.md does not exist"
        continue
      fi

      # Check frontmatter exists
      first_line="$(head -1 "$skill_file")"
      if [[ "$first_line" == "---" ]]; then
        pass "skills/$skill_name/SKILL.md has frontmatter"
      else
        fail "skills/$skill_name/SKILL.md missing frontmatter (no opening ---)"
        continue
      fi

      # Check name field
      name_val="$(get_frontmatter_field "$skill_file" "name")"
      if [[ -n "$name_val" ]]; then
        pass "skills/$skill_name/SKILL.md has name"
      else
        fail "skills/$skill_name/SKILL.md missing name in frontmatter"
      fi

      # Check description field
      desc_val="$(get_frontmatter_field "$skill_file" "description")"
      if [[ -n "$desc_val" ]]; then
        pass "skills/$skill_name/SKILL.md has description"
      else
        fail "skills/$skill_name/SKILL.md missing description in frontmatter"
      fi
    done
  fi

  # === 5. Naming convention checks ===

  if is_kebab_case "$plugin_name"; then
    pass "plugin directory name is kebab-case ($plugin_name)"
  else
    fail "plugin directory name is not kebab-case: $plugin_name"
  fi

done

# --- Summary ---

echo ""
if [[ $found_plugins -eq 0 ]]; then
  echo "No self-developed plugins found under $PLUGINS_DIR"
  exit 1
fi

total=$((PASS_COUNT + FAIL_COUNT))
echo "Summary: $PASS_COUNT checks passed, $FAIL_COUNT failed"

if [[ $FAIL_COUNT -gt 0 ]]; then
  exit 1
fi

exit 0
