#!/usr/bin/env bash
#
# run-tests.sh — Automated tests for the maintenance scripts in scripts/
#
# Usage: bash tests/run-tests.sh
#
# Copies the maintenance scripts into throwaway fixture repos (the real repo
# files are never touched) and checks:
#   1. sync-plugins.sh is idempotent on a healthy fixture
#   2. sync-plugins.sh rejects a plugin.json with a missing required field,
#      without writing partial output or literal "null"
#   3. sync-plugins.sh leaves marketplace.json/README.md untouched when a
#      plugin.json in the middle of the loop is invalid JSON
#   4. verify-sync.sh detects version drift between plugin.json and marketplace.json
#   5. keywords/license are synced into marketplace.json and removed when absent
#   6. verify-sync.sh --run-sync surfaces sync failures and restores files
#
# Requires: bash, jq. Exit 0 if all tests pass, exit 1 otherwise.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPTS_DIR="$REPO_ROOT/scripts"

if ! command -v jq &>/dev/null; then
  echo "Error: jq is required but not installed." >&2
  exit 1
fi

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

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

# --- Fixture helpers ---

make_fixture() {
  local fx="$1"
  mkdir -p "$fx/scripts" "$fx/.claude-plugin" "$fx/plugins"
  cp "$SCRIPTS_DIR/sync-plugins.sh" \
     "$SCRIPTS_DIR/verify-sync.sh" \
     "$SCRIPTS_DIR/validate-plugins.sh" \
     "$fx/scripts/"
  cat > "$fx/.claude-plugin/marketplace.json" <<'EOF'
{
  "name": "test-marketplace",
  "owner": {
    "name": "Tester"
  },
  "plugins": []
}
EOF
  cat > "$fx/README.md" <<'EOF'
# Test Fixture

<!-- PLUGINS_TABLE_START -->
<!-- PLUGINS_TABLE_END -->

Footer line.
EOF
}

make_plugin() {
  local fx="$1" name="$2" version="$3"
  mkdir -p "$fx/plugins/$name/.claude-plugin"
  cat > "$fx/plugins/$name/.claude-plugin/plugin.json" <<EOF
{
  "name": "$name",
  "description": "Test plugin $name",
  "version": "$version",
  "author": {
    "name": "Tester",
    "url": "https://example.com/tester"
  }
}
EOF
}

# Edit a plugin.json in place with a jq filter
edit_plugin_json() {
  local file="$1" filter="$2" tmp
  tmp="$(mktemp)"
  jq "$filter" "$file" > "$tmp"
  mv "$tmp" "$file"
}

# --- Test 1: sync is idempotent on a healthy fixture ---

echo ""
echo "Test 1: sync-plugins.sh is idempotent on a healthy fixture"

fx="$WORK_DIR/t1"
make_fixture "$fx"
make_plugin "$fx" alpha 1.0.0
make_plugin "$fx" beta 0.2.0

rc=0
bash "$fx/scripts/sync-plugins.sh" >/dev/null 2>&1 || rc=$?
if [[ $rc -eq 0 ]]; then
  pass "first sync run exits 0"
else
  fail "first sync run exited $rc"
fi

if [[ "$(jq -r '.plugins | length' "$fx/.claude-plugin/marketplace.json")" == "2" ]] \
   && [[ "$(jq -r '.plugins[] | select(.name == "alpha") | .version' "$fx/.claude-plugin/marketplace.json")" == "1.0.0" ]]; then
  pass "both plugins written to marketplace.json with correct version"
else
  fail "marketplace.json entries missing or wrong after sync"
fi

cp "$fx/.claude-plugin/marketplace.json" "$WORK_DIR/t1-marketplace.after1"
cp "$fx/README.md" "$WORK_DIR/t1-readme.after1"

rc=0
bash "$fx/scripts/sync-plugins.sh" >/dev/null 2>&1 || rc=$?
if [[ $rc -eq 0 ]]; then
  pass "second sync run exits 0"
else
  fail "second sync run exited $rc"
fi

if diff -q "$WORK_DIR/t1-marketplace.after1" "$fx/.claude-plugin/marketplace.json" >/dev/null; then
  pass "marketplace.json unchanged by second run (idempotent)"
else
  fail "marketplace.json changed on second run (not idempotent)"
fi

if diff -q "$WORK_DIR/t1-readme.after1" "$fx/README.md" >/dev/null; then
  pass "README.md unchanged by second run (idempotent)"
else
  fail "README.md changed on second run (not idempotent)"
fi

# --- Test 2: missing required field aborts sync without partial writes ---

echo ""
echo "Test 2: missing required field aborts sync without partial writes"

fx="$WORK_DIR/t2"
make_fixture "$fx"
make_plugin "$fx" alpha 1.0.0
# 'broken' sorts after 'alpha', so a per-plugin write strategy would already
# have written alpha before hitting the bad plugin
make_plugin "$fx" broken 0.1.0
edit_plugin_json "$fx/plugins/broken/.claude-plugin/plugin.json" 'del(.description)'

cp "$fx/.claude-plugin/marketplace.json" "$WORK_DIR/t2-marketplace.before"
cp "$fx/README.md" "$WORK_DIR/t2-readme.before"

rc=0
sync_out="$(bash "$fx/scripts/sync-plugins.sh" 2>&1)" || rc=$?

if [[ $rc -ne 0 ]]; then
  pass "sync exits non-zero on missing description"
else
  fail "sync exited 0 despite missing description"
fi

if echo "$sync_out" | grep -q "plugins/broken" && echo "$sync_out" | grep -q "description"; then
  pass "error message names the offending file and field"
else
  fail "error message does not name the offending file/field"
fi

if diff -q "$WORK_DIR/t2-marketplace.before" "$fx/.claude-plugin/marketplace.json" >/dev/null; then
  pass "marketplace.json untouched (no partial write)"
else
  fail "marketplace.json was modified despite the error"
fi

if diff -q "$WORK_DIR/t2-readme.before" "$fx/README.md" >/dev/null; then
  pass "README.md untouched (no partial write)"
else
  fail "README.md was modified despite the error"
fi

if ! grep -q "null" "$fx/.claude-plugin/marketplace.json" && ! grep -q "null" "$fx/README.md"; then
  pass "no literal \"null\" in marketplace.json or README.md"
else
  fail "literal \"null\" found in marketplace.json or README.md"
fi

# --- Test 3: invalid JSON mid-loop leaves outputs exactly as before ---

echo ""
echo "Test 3: invalid JSON mid-loop leaves outputs exactly as before"

fx="$WORK_DIR/t3"
make_fixture "$fx"
make_plugin "$fx" alpha 1.0.0
make_plugin "$fx" zeta 3.0.0

# Populate marketplace/README with a healthy sync first
if ! bash "$fx/scripts/sync-plugins.sh" >/dev/null 2>&1; then
  fail "fixture setup sync failed"
fi

# Bump alpha (so a rerun has something to write) and corrupt zeta's JSON
edit_plugin_json "$fx/plugins/alpha/.claude-plugin/plugin.json" '.version = "1.1.0"'
echo '{ this is not json' > "$fx/plugins/zeta/.claude-plugin/plugin.json"

cp "$fx/.claude-plugin/marketplace.json" "$WORK_DIR/t3-marketplace.before"
cp "$fx/README.md" "$WORK_DIR/t3-readme.before"

rc=0
bash "$fx/scripts/sync-plugins.sh" >/dev/null 2>&1 || rc=$?

if [[ $rc -ne 0 ]]; then
  pass "sync exits non-zero on invalid JSON"
else
  fail "sync exited 0 despite invalid JSON"
fi

if diff -q "$WORK_DIR/t3-marketplace.before" "$fx/.claude-plugin/marketplace.json" >/dev/null; then
  pass "marketplace.json identical to pre-run state"
else
  fail "marketplace.json was partially written"
fi

if diff -q "$WORK_DIR/t3-readme.before" "$fx/README.md" >/dev/null; then
  pass "README.md identical to pre-run state"
else
  fail "README.md was partially written"
fi

# --- Test 4: verify-sync detects version drift ---

echo ""
echo "Test 4: verify-sync.sh detects version drift"

fx="$WORK_DIR/t4"
make_fixture "$fx"
make_plugin "$fx" alpha 1.0.0
if ! bash "$fx/scripts/sync-plugins.sh" >/dev/null 2>&1; then
  fail "fixture setup sync failed"
fi

rc=0
bash "$fx/scripts/verify-sync.sh" >/dev/null 2>&1 || rc=$?
if [[ $rc -eq 0 ]]; then
  pass "verify-sync passes on a freshly synced fixture"
else
  fail "verify-sync exited $rc on a freshly synced fixture"
fi

# Introduce drift: bump plugin.json without re-running sync
edit_plugin_json "$fx/plugins/alpha/.claude-plugin/plugin.json" '.version = "2.0.0"'

rc=0
verify_out="$(bash "$fx/scripts/verify-sync.sh" 2>&1)" || rc=$?

if [[ $rc -ne 0 ]]; then
  pass "verify-sync exits non-zero on version drift"
else
  fail "verify-sync exited 0 despite version drift"
fi

if echo "$verify_out" | grep -q "\[DRIFT\] version"; then
  pass "version drift is reported"
else
  fail "version drift not reported in output"
fi

# --- Test 5: keywords/license sync roundtrip ---

echo ""
echo "Test 5: keywords/license are synced and removed when absent"

fx="$WORK_DIR/t5"
make_fixture "$fx"
make_plugin "$fx" alpha 1.0.0
edit_plugin_json "$fx/plugins/alpha/.claude-plugin/plugin.json" \
  '. + {keywords: ["kw-one", "kw-two"], license: "MIT"}'

if ! bash "$fx/scripts/sync-plugins.sh" >/dev/null 2>&1; then
  fail "sync failed with keywords/license present"
fi

if [[ "$(jq -c '.plugins[0].keywords' "$fx/.claude-plugin/marketplace.json")" == '["kw-one","kw-two"]' ]] \
   && [[ "$(jq -r '.plugins[0].license' "$fx/.claude-plugin/marketplace.json")" == "MIT" ]]; then
  pass "keywords and license synced into marketplace.json"
else
  fail "keywords/license not synced into marketplace.json"
fi

rc=0
bash "$fx/scripts/verify-sync.sh" >/dev/null 2>&1 || rc=$?
if [[ $rc -eq 0 ]]; then
  pass "verify-sync passes with keywords/license present"
else
  fail "verify-sync reports drift after keywords/license sync"
fi

# Remove the optional fields; sync should drop them from the marketplace entry
edit_plugin_json "$fx/plugins/alpha/.claude-plugin/plugin.json" 'del(.keywords, .license)'
if ! bash "$fx/scripts/sync-plugins.sh" >/dev/null 2>&1; then
  fail "sync failed after removing keywords/license"
fi

if [[ "$(jq '.plugins[0] | has("keywords") or has("license")' "$fx/.claude-plugin/marketplace.json")" == "false" ]]; then
  pass "keywords and license removed from marketplace.json when absent"
else
  fail "stale keywords/license left in marketplace.json"
fi

# --- Test 6: verify-sync --run-sync surfaces sync failures and restores files ---

echo ""
echo "Test 6: verify-sync.sh --run-sync surfaces sync failures and restores files"

fx="$WORK_DIR/t6"
make_fixture "$fx"
make_plugin "$fx" alpha 1.0.0
if ! bash "$fx/scripts/sync-plugins.sh" >/dev/null 2>&1; then
  fail "fixture setup sync failed"
fi

# Break the plugin so the inner sync run fails (missing description)
edit_plugin_json "$fx/plugins/alpha/.claude-plugin/plugin.json" 'del(.description)'

cp "$fx/.claude-plugin/marketplace.json" "$WORK_DIR/t6-marketplace.before"
cp "$fx/README.md" "$WORK_DIR/t6-readme.before"

rc=0
verify_out="$(bash "$fx/scripts/verify-sync.sh" --run-sync 2>&1)" || rc=$?

if [[ $rc -ne 0 ]]; then
  pass "verify-sync --run-sync exits non-zero when sync fails"
else
  fail "verify-sync --run-sync exited 0 despite failing sync"
fi

if echo "$verify_out" | grep -q "required field"; then
  pass "sync failure output is surfaced (not swallowed)"
else
  fail "sync failure output was swallowed"
fi

if diff -q "$WORK_DIR/t6-marketplace.before" "$fx/.claude-plugin/marketplace.json" >/dev/null \
   && diff -q "$WORK_DIR/t6-readme.before" "$fx/README.md" >/dev/null; then
  pass "marketplace.json and README.md restored after failed sync"
else
  fail "files left modified after failed --run-sync"
fi

# --- Summary ---

echo ""
echo "Summary: $PASS_COUNT passed, $FAIL_COUNT failed"
if [[ $FAIL_COUNT -gt 0 ]]; then
  exit 1
fi
exit 0
