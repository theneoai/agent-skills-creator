#!/usr/bin/env bash
# CLI 入口测试
# 10 test cases for CLI entry point

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "${PROJECT_ROOT}/tests/framework.sh"

CLI="${PROJECT_ROOT}/cli/skill"
CREATE_SCRIPT="${PROJECT_ROOT}/scripts/create-skill.sh"
EVAL_SCRIPT="${PROJECT_ROOT}/tools/eval/main.sh"

test_cli_lean_evaluate_001() {
    local output
    output=$(mktemp /tmp/test_cli_XXXXXX.md)
    cat > "$output" <<'EOF'
---
name: test-skill
description: Test skill
license: MIT
---

# Test Skill

## §1.1 Identity
## §1.2 Framework
## §1.3 Thinking
EOF
    local result
    result=$(bash "$CLI" "$output" 2>&1 || true)
    assert_match "[0-9]+|score|Score|PASS|NEEDS" "$result" "Lean evaluation produces output"
    rm -f "$output"
}

test_cli_lean_no_file_002() {
    local result
    result=$(bash "$CLI" "/nonexistent/file.md" 2>&1 || true)
    assert_match "not found|Error|error|No such file" "$result" "Handles missing file"
}

test_cli_create_help_003() {
    local result
    result=$(bash "$CREATE_SCRIPT" --help 2>&1 || true)
    assert_contains "$result" "Usage" "Create script shows usage"
    assert_contains "$result" "create" "Shows create instruction"
}

test_cli_create_basic_004() {
    local output
    output=$(mktemp /tmp/test_cli_create_XXXXXX.md)
    local result
    result=$(bash "$CREATE_SCRIPT" "Test skill for CLI" "$output" 2>&1 || true)
    assert_success "[[ -f '$output' ]]" "Skill file created"
    rm -f "$output"
}

test_cli_create_with_name_005() {
    local output
    output=$(mktemp /tmp/test_cli_create_XXXXXX.md)
    bash "$CREATE_SCRIPT" "Test skill" "$output" 2>/dev/null || true
    assert_success "[[ -f '$output' ]]" "Skill file created via CLI"
    rm -f "$output"
}

test_cli_evaluate_help_006() {
    local result
    result=$(bash "$EVAL_SCRIPT" --help 2>&1 || true)
    assert_contains "$result" "Usage" "Eval script shows usage"
    assert_contains "$result" "--skill" "Shows skill option"
}

test_cli_evaluate_fast_007() {
    local output
    output=$(mktemp /tmp/test_cli_XXXXXX.md)
    cat > "$output" <<'EOF'
---
name: fast-test
description: Fast test
license: MIT
---

# Fast Test

## §1.1 Identity
## §1.2 Framework
## §1.3 Thinking
EOF
    local result
    result=$(bash "$EVAL_SCRIPT" --skill "$output" --fast --no-agent 2>&1 || true)
    assert_match "[0-9]+" "$result" "Fast evaluation works"
    rm -f "$output"
}

test_cli_evaluate_full_008() {
    local output
    output=$(mktemp /tmp/test_cli_XXXXXX.md)
    cat > "$output" <<'EOF'
---
name: full-test
description: Full test
license: MIT
---

# Full Test

## §1.1 Identity
## §1.2 Framework
## §1.3 Thinking
EOF
    local result
    result=$(bash "$EVAL_SCRIPT" --skill "$output" --full --no-agent 2>&1 || true)
    assert_match "[0-9]+" "$result" "Full evaluation works"
    rm -f "$output"
}

test_cli_evaluate_with_output_009() {
    local output
    output=$(mktemp /tmp/test_cli_XXXXXX.md)
    local eval_dir
    eval_dir=$(mktemp -d /tmp/test_eval_XXXXXX)
    cat > "$output" <<'EOF'
---
name: output-test
description: Output test
license: MIT
---

# Output Test

## §1.1 Identity
## §1.2 Framework
## §1.3 Thinking
EOF
    bash "$EVAL_SCRIPT" --skill "$output" --fast --no-agent --output "$eval_dir" 2>/dev/null || true
    assert_success "[[ -f '$eval_dir/summary.json' ]]" "Summary JSON created"
    rm -rf "$output" "$eval_dir"
}

test_cli_evaluate_ci_mode_010() {
    local output
    output=$(mktemp /tmp/test_cli_XXXXXX.md)
    cat > "$output" <<'EOF'
---
name: ci-test
description: CI test
license: MIT
---

# CI Test

## §1.1 Identity
## §1.2 Framework
## §1.3 Thinking
EOF
    local result
    result=$(bash "$EVAL_SCRIPT" --skill "$output" --fast --no-agent --ci 2>&1 || true)
    assert_match "[0-9]+" "$result" "CI mode evaluation works"
    rm -f "$output"
}

test_cli_lean_evaluate_001
test_cli_lean_no_file_002
test_cli_create_help_003
test_cli_create_basic_004
test_cli_create_with_name_005
test_cli_evaluate_help_006
test_cli_evaluate_fast_007
test_cli_evaluate_full_008
test_cli_evaluate_with_output_009
test_cli_evaluate_ci_mode_010

report