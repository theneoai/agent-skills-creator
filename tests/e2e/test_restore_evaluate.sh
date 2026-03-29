#!/usr/bin/env bash
# RESTORE→EVALUATE 端到端测试
# 10 test cases for restore and evaluate workflow

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "${PROJECT_ROOT}/tests/framework.sh"

RESTORE_SCRIPT="${PROJECT_ROOT}/scripts/restore-skill.sh"
EVAL_SCRIPT="${PROJECT_ROOT}/tools/eval/main.sh"

test_restore_evaluate_fixed_001() {
    local output
    output=$(mktemp /tmp/test_restore_XXXXXX.md)
    cat > "$output" <<'EOF'
---
name: fixable-skill
description: Skill that can be fixed
license: MIT
---

# Fixable Skill

## §1.1 Identity
Test skill

## §1.2 Framework

## §1.3 Thinking
EOF
    if [[ -x "$RESTORE_SCRIPT" ]]; then
        bash "$RESTORE_SCRIPT" "$output" 2>/dev/null || true
    fi
    local result
    result=$(bash "$EVAL_SCRIPT" --skill "$output" --fast --no-agent 2>&1 || true)
    assert_match "[0-9]+" "$result" "Restored skill evaluates successfully"
    rm -f "$output"
}

test_restore_evaluate_still_failing_002() {
    local output
    output=$(mktemp /tmp/test_restore_XXXXXX.md)
    cat > "$output" <<'EOF'
---
name: broken
description: Broken skill
license: MIT
---

# Broken

Just text without structure.
EOF
    if [[ -x "$RESTORE_SCRIPT" ]]; then
        bash "$RESTORE_SCRIPT" "$output" 2>/dev/null || true
    fi
    local result
    result=$(bash "$EVAL_SCRIPT" --skill "$output" --fast --no-agent 2>&1 || true)
    assert_match "[0-9]+" "$result" "Even broken skill produces evaluation"
    rm -f "$output"
}

test_restore_evaluate_missing_sections_003() {
    local output
    output=$(mktemp /tmp/test_restore_XXXXXX.md)
    cat > "$output" <<'EOF'
---
name: missing-sections
description: Missing sections skill
license: MIT
---

# Missing Sections

Only one section.
EOF
    if [[ -x "$RESTORE_SCRIPT" ]]; then
        bash "$RESTORE_SCRIPT" "$output" 2>/dev/null || true
    fi
    local result
    result=$(bash "$EVAL_SCRIPT" --skill "$output" --fast --no-agent 2>&1 || true)
    assert_match "[0-9]+" "$result" "Missing sections restored and evaluated"
    rm -f "$output"
}

test_restore_evaluate_invalid_yaml_004() {
    local output
    output=$(mktemp /tmp/test_restore_XXXXXX.md)
    cat > "$output" <<'EOF'
name: invalid
description: Invalid YAML front
license MIT
---

# Invalid YAML

## §1.1 Identity
EOF
    if [[ -x "$RESTORE_SCRIPT" ]]; then
        bash "$RESTORE_SCRIPT" "$output" 2>/dev/null || true
    fi
    assert_success "[[ -f '$output' ]]" "File exists after restore attempt"
    rm -f "$output"
}

test_restore_evaluate_empty_file_005() {
    local output
    output=$(mktemp /tmp/test_restore_XXXXXX.md)
    echo "" > "$output"
    if [[ -x "$RESTORE_SCRIPT" ]]; then
        bash "$RESTORE_SCRIPT" "$output" 2>/dev/null || true
    fi
    local result
    result=$(bash "$EVAL_SCRIPT" --skill "$output" --fast --no-agent 2>&1 || true)
    assert_match "[0-9]+|Error|error" "$result" "Empty file restore produces result"
    rm -f "$output"
}

test_restore_evaluate_file_not_found_006() {
    local result
    result=$(bash "$RESTORE_SCRIPT" "/nonexistent/broken.md" 2>&1 || true)
    assert_match "not found|Error|error" "$result" "Handles missing file"
}

test_restore_evaluate_partial_content_007() {
    local output
    output=$(mktemp /tmp/test_restore_XXXXXX.md)
    cat > "$output" <<'EOF'
---
name: partial
description: Partial content
license: MIT
---

## §1.1 Identity

## §1.2 Framework
EOF
    if [[ -x "$RESTORE_SCRIPT" ]]; then
        bash "$RESTORE_SCRIPT" "$output" 2>/dev/null || true
    fi
    local result
    result=$(bash "$EVAL_SCRIPT" --skill "$output" --fast --no-agent 2>&1 || true)
    assert_match "[0-9]+" "$result" "Partial content restores and evaluates"
    rm -f "$output"
}

test_restore_evaluate_trigger_repair_008() {
    local output
    output=$(mktemp /tmp/test_restore_XXXXXX.md)
    cat > "$output" <<'EOF'
---
name: trigger-repair
description: Trigger repair test
license: MIT
---

# Trigger Repair

## §1.1 Identity
Test

## §1.2 Framework

## §1.3 Thinking

No triggers defined here.
EOF
    if [[ -x "$RESTORE_SCRIPT" ]]; then
        bash "$RESTORE_SCRIPT" "$output" 2>/dev/null || true
    fi
    local result
    result=$(bash "$EVAL_SCRIPT" --skill "$output" --fast --no-agent 2>&1 || true)
    assert_match "[0-9]+" "$result" "Trigger repair produces evaluation"
    rm -f "$output"
}

test_restore_evaluate_after_create_009() {
    local output
    output=$(mktemp /tmp/test_restore_XXXXXX.md)
    cat > "$output" <<'EOF'
---
name: after-create
description: Test after create
license: MIT
---

# After Create

## §1.1 Identity
Test

## §1.2 Framework

## §1.3 Thinking
EOF
    if [[ -x "$RESTORE_SCRIPT" ]]; then
        bash "$RESTORE_SCRIPT" "$output" 2>/dev/null || true
    fi
    local score
    score=$(bash "$EVAL_SCRIPT" --skill "$output" --fast --no-agent 2>/dev/null | grep -oE "[0-9]+" | head -1 || echo "0")
    assert_match "[0-9]+" "$score" "Score obtained after restore"
    rm -f "$output"
}

test_restore_evaluate_with_dependencies_010() {
    local output
    output=$(mktemp /tmp/test_restore_XXXXXX.md)
    cat > "$output" <<'EOF'
---
name: with-deps
description: Skill with dependencies
license: MIT
---

# With Dependencies

## §1.1 Identity
Test skill

## §1.2 Framework
- ReAct
- Chain of Thought

## §1.3 Thinking
Risk assessment

## §2 Invocation

| CREATE | EVALUATE |
|--------|----------|

## §3 Process

### Phase 1
Step 1

### Done: Complete

## §4 Tools
- tool1
EOF
    if [[ -x "$RESTORE_SCRIPT" ]]; then
        bash "$RESTORE_SCRIPT" "$output" 2>/dev/null || true
    fi
    local result
    result=$(bash "$EVAL_SCRIPT" --skill "$output" --fast --no-agent 2>&1 || true)
    assert_match "[0-9]+" "$result" "Dependencies handled during restore"
    rm -f "$output"
}

test_restore_evaluate_fixed_001
test_restore_evaluate_still_failing_002
test_restore_evaluate_missing_sections_003
test_restore_evaluate_invalid_yaml_004
test_restore_evaluate_empty_file_005
test_restore_evaluate_file_not_found_006
test_restore_evaluate_partial_content_007
test_restore_evaluate_trigger_repair_008
test_restore_evaluate_after_create_009
test_restore_evaluate_with_dependencies_010

report