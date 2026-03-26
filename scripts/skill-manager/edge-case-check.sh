#!/usr/bin/env bash
# edge-case-check.sh — Test edge cases for validate.sh
# Usage: ./edge-case-check.sh

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VALIDATE="$SCRIPT_DIR/validate.sh"
TESTS_PASSED=0
TESTS_FAILED=0

pass()  { echo -e "${GREEN}  ✓ $1${NC}"; TESTS_PASSED=$((TESTS_PASSED+1)); }
fail()  { echo -e "${RED}  ✗ $1${NC}"; TESTS_FAILED=$((TESTS_FAILED+1)); }

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  EDGE CASE TESTS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── Create temp test directory ───────────────────────────────────────────────
TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

# Helper: create valid SKILL.md
create_valid_skill() {
  local dir="$1"
  local skill_name
  skill_name=$(basename "$dir")
  mkdir -p "$dir"
  cat > "$dir/SKILL.md" <<EOF
---
name: $skill_name
description: A test skill for edge case validation testing purposes
---
# System Prompt

## § 1.1 Identity
Test identity

## § 1.2 Decision Framework
Test framework

## § 1.3 Thinking Patterns
Test patterns
EOF
}

# Helper: run validate.sh and capture result
run_validate() {
  local file="$1"
  if "$VALIDATE" "$file" > /dev/null 2>&1; then
    echo "pass"
  else
    echo "fail"
  fi
}

# ── Test 1: Empty file ───────────────────────────────────────────────────────
echo "[ Test 1: Empty file ]"
EMPTY_DIR="$TEST_DIR/empty-file"
mkdir -p "$EMPTY_DIR"
touch "$EMPTY_DIR/SKILL.md"
RESULT=$(run_validate "$EMPTY_DIR/SKILL.md")
if [[ "$RESULT" == "fail" ]]; then
  pass "Empty file rejected"
else
  fail "Empty file should be rejected"
fi
echo ""

# ── Test 2: Circular reference (self-reference in location) ─────────────────
echo "[ Test 2: Circular reference ]"
CIRC_DIR="$TEST_DIR/circular-ref"
create_valid_skill "$CIRC_DIR"
# Inject circular reference
cat > "$CIRC_DIR/SKILL.md" <<'EOF'
---
name: circular-ref
description: A skill that references itself
location: file:///Users/lucas/.agents/skills/skill-manager/scripts/circular-ref/SKILL.md
---
# System Prompt

## § 1.1 Identity
Test identity
EOF
RESULT=$(run_validate "$CIRC_DIR/SKILL.md")
if [[ "$RESULT" == "fail" ]]; then
  pass "Circular reference detected"
else
  fail "Circular reference should be detected"
fi
echo ""

# ── Test 3: Path traversal ────────────────────────────────────────────────────
echo "[ Test 3: Path traversal ]"
TRAV_DIR="$TEST_DIR/normal-skill"
create_valid_skill "$TRAV_DIR"
MALICIOUS_PATH="$TRAV_DIR/../traversal-attempt/SKILL.md"
OUTPUT=$("$VALIDATE" "$MALICIOUS_PATH" 2>&1 || true)
if echo "$OUTPUT" | grep -q "Path traversal"; then
  pass "Path traversal blocked"
else
  fail "Path traversal should be blocked"
fi
echo ""

# ── Test 4: Malformed YAML (missing closing ---) ─────────────────────────────
echo "[ Test 4: Malformed YAML ]"
MALFORMED_DIR="$TEST_DIR/malformed"
mkdir -p "$MALFORMED_DIR"
cat > "$MALFORMED_DIR/SKILL.md" <<'EOF'
---
name: malformed
description: Missing closing delimiter
# System Prompt
EOF
RESULT=$(run_validate "$MALFORMED_DIR/SKILL.md")
if [[ "$RESULT" == "fail" ]]; then
  pass "Malformed YAML (missing closing ---) rejected"
else
  fail "Malformed YAML should be rejected"
fi
echo ""

# ── Test 5: Circular reference by directory name ─────────────────────────────
echo "[ Test 5: Circular reference by directory name in location ]"
CIRC_DIR2="$TEST_DIR/self-ref-by-name"
create_valid_skill "$CIRC_DIR2"
cat > "$CIRC_DIR2/SKILL.md" <<'EOF'
---
name: self-ref-by-name
description: References itself by directory name
location: ./self-ref-by-name/related.md
---
# System Prompt

## § 1.1 Identity
Test
EOF
RESULT=$(run_validate "$CIRC_DIR2/SKILL.md")
if [[ "$RESULT" == "fail" ]]; then
  pass "Circular reference by directory name detected"
else
  fail "Circular reference by directory name should be detected"
fi
echo ""

# ── Test 6: Valid skill still passes ────────────────────────────────────────
echo "[ Test 6: Valid skill still passes ]"
VALID_DIR="$TEST_DIR/valid-skill"
create_valid_skill "$VALID_DIR"
RESULT=$(run_validate "$VALID_DIR/SKILL.md")
if [[ "$RESULT" == "pass" ]]; then
  pass "Valid skill passes validation"
else
  fail "Valid skill should pass"
fi
echo ""

# ── Summary ───────────────────────────────────────────────────────────────────
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "  Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
  echo -e "${GREEN}All edge case tests passed${NC}"
  exit 0
else
  echo -e "${RED}Some tests failed${NC}"
  exit 1
fi
