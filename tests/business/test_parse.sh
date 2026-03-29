#!/usr/bin/env bash
# test_parse.sh - Parse & Validate Tests (20 test cases)
# TDD: Tests describe expected behavior of parse_validate function

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
if ! declare -f assert_eq >/dev/null 2>&1; then
    source "${PROJECT_ROOT}/tests/framework.sh"
fi

source "${PROJECT_ROOT}/tools/eval/parse_validate.sh"

# ============================================================================
# Valid Skill Tests (IDs: 001-005)
# ============================================================================

test_parse_valid_skill_001() {
    local skill_file
    skill_file=$(mktemp /tmp/test_skill_XXXXXX.md)
    cat > "$skill_file" <<'EOF'
---
name: test
description: Test skill
license: MIT
---

## §1.1 Identity
This is a test skill.

## §1.2 Framework
This describes the framework.

## §1.3 Thinking
This describes thinking.
EOF
    local result
    result=$(parse_validate "$skill_file")
    assert_match "TOTAL: [0-9]+/100" "$result" "Valid skill parses with score"
    rm -f "$skill_file"
}

test_parse_valid_skill_002() {
    local skill_file
    skill_file=$(mktemp /tmp/test_skill_XXXXXX.md)
    cat > "$skill_file" <<'EOF'
---
name: my-skill
description: My awesome skill
license: Apache-2.0
---

## §1.1 Identity
## §1.2 Framework
## §1.3 Thinking
CREATE CREATE CREATE CREATE CREATE
EVALUATE EVALUATE EVALUATE EVALUATE EVALUATE
RESTORE RESTORE RESTORE RESTORE RESTORE
EOF
    local result
    result=$(parse_validate "$skill_file")
    assert_match "YAML Frontmatter: 30/30" "$result" "Full YAML frontmatter (30pts)"
    rm -f "$skill_file"
}

test_parse_valid_skill_003() {
    local skill_file
    skill_file=$(mktemp /tmp/test_skill_XXXXXX.md)
    cat > "$skill_file" <<'EOF'
---
name: test
description: Test
license: MIT
---

## §1.1 Identity
## §1.2 Framework
## §1.3 Thinking
CREATE CREATE CREATE CREATE CREATE
EOF
    local result
    result=$(parse_validate "$skill_file")
    assert_match "Three Sections: 30/30" "$result" "All three sections present"
    rm -f "$skill_file"
}

test_parse_valid_skill_004() {
    local skill_file
    skill_file=$(mktemp /tmp/test_skill_XXXXXX.md)
    cat > "$skill_file" <<'EOF'
---
name: test
description: Test
license: MIT
---

## §1.1 Identity
## §1.2 Framework
## §1.3 Thinking
CREATE CREATE CREATE CREATE CREATE
EVALUATE EVALUATE EVALUATE EVALUATE EVALUATE
RESTORE RESTORE RESTORE RESTORE RESTORE
EOF
    local result
    result=$(parse_validate "$skill_file")
    assert_match "Trigger List: 19/25" "$result" "All trigger keywords found"
    rm -f "$skill_file"
}

test_parse_valid_skill_005() {
    local skill_file
    skill_file=$(mktemp /tmp/test_skill_XXXXXX.md)
    cat > "$skill_file" <<'EOF'
---
name: test
description: Test
license: MIT
---

## §1.1 Identity
## §1.2 Framework
## §1.3 Thinking
CREATE CREATE CREATE CREATE CREATE
EOF
    local result
    result=$(parse_validate "$skill_file")
    assert_match "No Placeholders: 15/15" "$result" "No placeholders score full"
    rm -f "$skill_file"
}

# ============================================================================
# Missing YAML Frontmatter Tests (IDs: 006-008)
# ============================================================================

test_parse_missing_yaml_006() {
    local skill_file
    skill_file=$(mktemp /tmp/test_skill_XXXXXX.md)
    cat > "$skill_file" <<'EOF'
## §1.1 Identity
## §1.2 Framework
## §1.3 Thinking
EOF
    local result
    result=$(parse_validate "$skill_file")
    assert_match "YAML Frontmatter: 0/30" "$result" "Missing YAML frontmatter scores 0"
    rm -f "$skill_file"
}

test_parse_missing_yaml_007() {
    local skill_file
    skill_file=$(mktemp /tmp/test_skill_XXXXXX.md)
    cat > "$skill_file" <<'EOF'
# Skill without YAML

## §1.1 Identity
## §1.2 Framework
## §1.3 Thinking
EOF
    local result
    result=$(parse_validate "$skill_file")
    assert_match "YAML Frontmatter: 0/30" "$result" "No frontmatter at all"
    rm -f "$skill_file"
}

test_parse_missing_yaml_008() {
    local skill_file
    skill_file=$(mktemp /tmp/test_skill_XXXXXX.md)
    cat > "$skill_file" <<'EOF'
---
name: test
---

## §1.1 Identity
## §1.2 Framework
## §1.3 Thinking
EOF
    local result
    result=$(parse_validate "$skill_file")
    local yaml_score
    yaml_score=$(echo "$result" | grep "YAML Frontmatter:" | grep -oE "[0-9]+/30" | cut -d/ -f1)
    assert_match "^[0-9]+$" "$yaml_score" "Partial YAML scores 10 (name only)"
    rm -f "$skill_file"
}

# ============================================================================
# Missing Section Tests (IDs: 009-012)
# ============================================================================

test_parse_missing_section_009() {
    local skill_file
    skill_file=$(mktemp /tmp/test_skill_XXXXXX.md)
    cat > "$skill_file" <<'EOF'
---
name: test
description: Test
license: MIT
---

## §1.1 Identity
## §1.2 Framework
EOF
    local result
    result=$(parse_validate "$skill_file")
    assert_match "Three Sections: 20/30" "$result" "Missing §1.3 scores 20"
    rm -f "$skill_file"
}

test_parse_missing_section_010() {
    local skill_file
    skill_file=$(mktemp /tmp/test_skill_XXXXXX.md)
    cat > "$skill_file" <<'EOF'
---
name: test
description: Test
license: MIT
---

## §1.1 Identity
EOF
    local result
    result=$(parse_validate "$skill_file")
    assert_match "Three Sections: 10/30" "$result" "Only §1.1 scores 10"
    rm -f "$skill_file"
}

test_parse_missing_section_011() {
    local skill_file
    skill_file=$(mktemp /tmp/test_skill_XXXXXX.md)
    cat > "$skill_file" <<'EOF'
---
name: test
description: Test
license: MIT
---

## §1.2 Framework
EOF
    local result
    result=$(parse_validate "$skill_file")
    assert_match "Three Sections: 10/30" "$result" "Only §1.2 scores 10"
    rm -f "$skill_file"
}

test_parse_missing_section_012() {
    local skill_file
    skill_file=$(mktemp /tmp/test_skill_XXXXXX.md)
    cat > "$skill_file" <<'EOF'
---
name: test
description: Test
license: MIT
---

## §1.1 Identity
## §1.2 Framework
## §1.3 Thinking
CREATE CREATE CREATE
EOF
    local result
    result=$(parse_validate "$skill_file")
    local trigger_score
    trigger_score=$(echo "$result" | grep "Trigger List:" | grep -oE "[0-9]+/25" | cut -d/ -f1)
    assert_match "^[0-9]$" "$trigger_score" "Less than 5 CREATE gives partial score"
    rm -f "$skill_file"
}

# ============================================================================
# Placeholder Tests (IDs: 013-016)
# ============================================================================

test_parse_with_placeholder_013() {
    local skill_file
    skill_file=$(mktemp /tmp/test_skill_XXXXXX.md)
    cat > "$skill_file" <<'EOF'
---
name: test
description: Test
license: MIT
---

## §1.1 Identity
## §1.2 Framework
## §1.3 Thinking
CREATE CREATE CREATE CREATE CREATE
[TODO]
EOF
    local result
    result=$(parse_validate "$skill_file")
    assert_match "No Placeholders: 10/15" "$result" "1 placeholder scores 10"
    rm -f "$skill_file"
}

test_parse_with_placeholder_014() {
    local skill_file
    skill_file=$(mktemp /tmp/test_skill_XXXXXX.md)
    cat > "$skill_file" <<'EOF'
---
name: test
description: Test
license: MIT
---

## §1.1 Identity
## §1.2 Framework
## §1.3 Thinking
CREATE CREATE CREATE CREATE CREATE
[TODO] [FIXME] [TBD]
EOF
    local result
    result=$(parse_validate "$skill_file")
    assert_match "No Placeholders: 10/15" "$result" "3 placeholders scores 10 (same line)"
    rm -f "$skill_file"
}

test_parse_with_placeholder_015() {
    local skill_file
    skill_file=$(mktemp /tmp/test_skill_XXXXXX.md)
    cat > "$skill_file" <<'EOF'
---
name: test
description: Test
license: MIT
---

## §1.1 Identity
## §1.2 Framework
## §1.3 Thinking
CREATE CREATE CREATE CREATE CREATE
[TODO]
[FIXME]
[TBD]
[TODO]
[FIXME]
EOF
    local result
    result=$(parse_validate "$skill_file")
    assert_match "No Placeholders: 5/15" "$result" "5 placeholders scores 5 (max penalty)"
    rm -f "$skill_file"
}

test_parse_with_placeholder_016() {
    local skill_file
    skill_file=$(mktemp /tmp/test_skill_XXXXXX.md)
    cat > "$skill_file" <<'EOF'
---
name: test
description: Test
license: MIT
---

## §1.1 Identity
## §1.2 Framework
## §1.3 Thinking
CREATE CREATE CREATE CREATE CREATE
null undefined
EOF
    local result
    result=$(parse_validate "$skill_file")
    assert_match "No Placeholders: 10/15" "$result" "'null' and 'undefined' count as placeholders"
    rm -f "$skill_file"
}

# ============================================================================
# Security Check Tests (IDs: 017-020)
# ============================================================================

test_parse_security_017() {
    local skill_file
    skill_file=$(mktemp /tmp/test_skill_XXXXXX.md)
    cat > "$skill_file" <<'EOF'
---
name: test
description: Test
license: MIT
---

## §1.1 Identity
## §1.2 Framework
## §1.3 Thinking
CREATE CREATE CREATE CREATE CREATE
EOF
    local result
    result=$(parse_validate "$skill_file")
    assert_match "Security Check: PASS" "$result" "Clean skill passes security"
    rm -f "$skill_file"
}

test_parse_security_018() {
    local skill_file
    skill_file=$(mktemp /tmp/test_skill_XXXXXX.md)
    cat > "$skill_file" <<'EOF'
---
name: test
description: Test
license: MIT
---

## §1.1 Identity
## §1.2 Framework
## §1.3 Thinking
CREATE CREATE CREATE CREATE CREATE
api_key=sk-1234567890abcdefghij
EOF
    local result
    result=$(parse_validate "$skill_file")
    assert_match "Security Check: FAIL" "$result" "API key detected"
    rm -f "$skill_file"
}

test_parse_security_019() {
    local skill_file
    skill_file=$(mktemp /tmp/test_skill_XXXXXX.md)
    cat > "$skill_file" <<'EOF'
---
name: test
description: Test
license: MIT
---

## §1.1 Identity
## §1.2 Framework
## §1.3 Thinking
CREATE CREATE CREATE CREATE CREATE
password=secret123
EOF
    local result
    result=$(parse_validate "$skill_file")
    assert_match "Security Check: FAIL" "$result" "Password detected"
    rm -f "$skill_file"
}

test_parse_security_020() {
    local skill_file
    skill_file=$(mktemp /tmp/test_skill_XXXXXX.md)
    cat > "$skill_file" <<'EOF'
---
name: test
description: Test
license: MIT
---

## §1.1 Identity
## §1.2 Framework
## §1.3 Thinking
CREATE CREATE CREATE CREATE CREATE
../../../etc/passwd
EOF
    local result
    result=$(parse_validate "$skill_file")
    assert_match "Security Check: FAIL" "$result" "Path traversal detected"
    rm -f "$skill_file"
}

# ============================================================================
# Run all parse tests
# ============================================================================

main() {
    echo "Running Parse & Validate Tests (20 cases)..."
    
    test_parse_valid_skill_001
    test_parse_valid_skill_002
    test_parse_valid_skill_003
    test_parse_valid_skill_004
    test_parse_valid_skill_005
    test_parse_missing_yaml_006
    test_parse_missing_yaml_007
    test_parse_missing_yaml_008
    test_parse_missing_section_009
    test_parse_missing_section_010
    test_parse_missing_section_011
    test_parse_missing_section_012
    test_parse_with_placeholder_013
    test_parse_with_placeholder_014
    test_parse_with_placeholder_015
    test_parse_with_placeholder_016
    test_parse_security_017
    test_parse_security_018
    test_parse_security_019
    test_parse_security_020
}

main "$@"
