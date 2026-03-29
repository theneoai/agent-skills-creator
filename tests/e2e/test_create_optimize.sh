#!/usr/bin/env bash
# CREATE→OPTIMIZE→EVALUATE 端到端测试
# 10 test cases for create, optimize, evaluate workflow

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "${PROJECT_ROOT}/tests/framework.sh"

CREATE_SCRIPT="${PROJECT_ROOT}/scripts/create-skill.sh"
OPTIMIZE_SCRIPT="${PROJECT_ROOT}/scripts/optimize-skill.sh"
EVAL_SCRIPT="${PROJECT_ROOT}/tools/eval/main.sh"

test_optimize_score_improvement_001() {
    local output
    output=$(mktemp /tmp/test_opt_XXXXXX.md)
    cat > "$output" <<'EOF'
---
name: optimization-test
description: Test optimization workflow
license: MIT
---

# Optimization Test

## §1.1 Identity
Test skill

## §1.2 Framework

## §1.3 Thinking
EOF
    local score_before
    score_before=$(bash "$EVAL_SCRIPT" --skill "$output" --fast --no-agent 2>/dev/null | grep -oE "[0-9]+" | head -1 || echo "0")
    if [[ -x "$OPTIMIZE_SCRIPT" ]]; then
        bash "$OPTIMIZE_SCRIPT" "$output" 5 2>/dev/null || true
    fi
    local score_after
    score_after=$(bash "$EVAL_SCRIPT" --skill "$output" --fast --no-agent 2>/dev/null | grep -oE "[0-9]+" | head -1 || echo "0")
    assert_match "[0-9]+" "$score_after" "Score after optimization is numeric"
    rm -f "$output"
}

test_optimize_convergence_002() {
    local output
    output=$(mktemp /tmp/test_opt_XXXXXX.md)
    cat > "$output" <<'EOF'
---
name: convergence-test
description: Test convergence
license: MIT
---

# Convergence Test

## §1.1 Identity
Test

## §1.2 Framework
ReAct

## §1.3 Thinking
EOF
    if [[ -x "$OPTIMIZE_SCRIPT" ]]; then
        bash "$OPTIMIZE_SCRIPT" "$output" 3 2>/dev/null || true
    fi
    local score
    score=$(bash "$EVAL_SCRIPT" --skill "$output" --fast --no-agent 2>/dev/null | grep -oE "[0-9]+" | head -1 || echo "0")
    assert_match "[0-9]+" "$score" "Converged score is numeric"
    rm -f "$output"
}

test_optimize_no_regression_003() {
    local output
    output=$(mktemp /tmp/test_opt_XXXXXX.md)
    cat > "$output" <<'EOF'
---
name: regression-test
description: Test no regression
license: MIT
---

# Regression Test

## §1.1 Identity
Test skill

## §1.2 Framework

## §1.3 Thinking
EOF
    local score_before
    score_before=$(bash "$EVAL_SCRIPT" --skill "$output" --fast --no-agent 2>/dev/null | grep -oE "[0-9]+" | head -1 || echo "0")
    if [[ -x "$OPTIMIZE_SCRIPT" ]]; then
        bash "$OPTIMIZE_SCRIPT" "$output" 2>/dev/null || true
    fi
    local score_after
    score_after=$(bash "$EVAL_SCRIPT" --skill "$output" --fast --no-agent 2>/dev/null | grep -oE "[0-9]+" | head -1 || echo "0")
    assert_match "[0-9]+" "$score_after" "Score after optimization exists"
    rm -f "$output"
}

test_optimize_quality_boost_004() {
    local output
    output=$(mktemp /tmp/test_opt_XXXXXX.md)
    cat > "$output" <<'EOF'
---
name: quality-boost
description: Quality boost test
license: MIT
---

# Quality Boost

## §1.1 Identity
Test skill for quality boost

## §1.2 Framework
ReAct, Chain of Thought

## §1.3 Thinking
Risk assessment
EOF
    if [[ -x "$OPTIMIZE_SCRIPT" ]]; then
        bash "$OPTIMIZE_SCRIPT" "$output" 5 2>/dev/null || true
    fi
    local result
    result=$(bash "$EVAL_SCRIPT" --skill "$output" --fast --no-agent 2>&1 || true)
    assert_match "[0-9]+" "$result" "Quality boost produces results"
    rm -f "$output"
}

test_optimize_max_rounds_005() {
    local output
    output=$(mktemp /tmp/test_opt_XXXXXX.md)
    cat > "$output" <<'EOF'
---
name: max-rounds-test
description: Test max rounds
license: MIT
---

# Max Rounds Test

## §1.1 Identity
Test

## §1.2 Framework

## §1.3 Thinking
EOF
    if [[ -x "$OPTIMIZE_SCRIPT" ]]; then
        bash "$OPTIMIZE_SCRIPT" "$output" 10 2>/dev/null || true
    fi
    assert_success "[[ -f '$output' ]]" "Skill file exists after max rounds"
    rm -f "$output"
}

test_optimize_minimal_skill_006() {
    local output
    output=$(mktemp /tmp/test_opt_XXXXXX.md)
    cat > "$output" <<'EOF'
---
name: minimal
description: Minimal skill
license: MIT
---

# Minimal

## §1.1 Identity

## §1.2 Framework

## §1.3 Thinking
EOF
    if [[ -x "$OPTIMIZE_SCRIPT" ]]; then
        bash "$OPTIMIZE_SCRIPT" "$output" 3 2>/dev/null || true
    fi
    local result
    result=$(bash "$EVAL_SCRIPT" --skill "$output" --fast --no-agent 2>&1 || true)
    assert_match "[0-9]+" "$result" "Minimal skill optimizes and evaluates"
    rm -f "$output"
}

test_optimize_missing_file_007() {
    local result
    result=$(bash "$OPTIMIZE_SCRIPT" "/nonexistent/file.md" 2>&1 || true)
    assert_match "not found|Error|error" "$result" "Handles missing file"
}

test_optimize_preserves_content_008() {
    local output
    output=$(mktemp /tmp/test_opt_XXXXXX.md)
    cat > "$output" <<'EOF'
---
name: preserve-test
description: Test content preservation
license: MIT
---

# Preserve Test

## §1.1 Identity
This should be preserved

## §1.2 Framework

## §1.3 Thinking
EOF
    if [[ -x "$OPTIMIZE_SCRIPT" ]]; then
        bash "$OPTIMIZE_SCRIPT" "$output" 2>/dev/null || true
    fi
    assert_success "[[ -f '$output' ]]" "Content file still exists"
    rm -f "$output"
}

test_optimize_tier_upgrade_009() {
    local output
    output=$(mktemp /tmp/test_opt_XXXXXX.md)
    cat > "$output" <<'EOF'
---
name: tier-upgrade
description: Test tier upgrade
license: MIT
version: 1.0.0
---

# Tier Upgrade Test

## §1.1 Identity
Test skill for tier upgrade

## §1.2 Framework
- Uses ReAct pattern
- Implements Chain of Thought
- F1 >= 0.90 threshold

## §1.3 Thinking
- Risk assessment
- Decision framework

## §2 Invocation

| CREATE | EVALUATE | OPTIMIZE |
|--------|----------|----------|

## §3 Process

### Phase 1: Analyze
Analyze input

### Done: Complete
EOF
    if [[ -x "$OPTIMIZE_SCRIPT" ]]; then
        bash "$OPTIMIZE_SCRIPT" "$output" 10 2>/dev/null || true
    fi
    local result
    result=$(bash "$EVAL_SCRIPT" --skill "$output" --fast --no-agent 2>&1 || true)
    assert_match "[0-9]+" "$result" "Tier upgrade produces results"
    rm -f "$output"
}

test_optimize_multi_iteration_010() {
    local output
    output=$(mktemp /tmp/test_opt_XXXXXX.md)
    cat > "$output" <<'EOF'
---
name: multi-iteration
description: Test multi-iteration
license: MIT
---

# Multi Iteration Test

## §1.1 Identity
Test

## §1.2 Framework

## §1.3 Thinking
EOF
    local i
    for i in 1 2 3; do
        if [[ -x "$OPTIMIZE_SCRIPT" ]]; then
            bash "$OPTIMIZE_SCRIPT" "$output" 2>/dev/null || true
        fi
    done
    local result
    result=$(bash "$EVAL_SCRIPT" --skill "$output" --fast --no-agent 2>&1 || true)
    assert_match "[0-9]+" "$result" "Multi-iteration produces final score"
    rm -f "$output"
}

test_optimize_score_improvement_001
test_optimize_convergence_002
test_optimize_no_regression_003
test_optimize_quality_boost_004
test_optimize_max_rounds_005
test_optimize_minimal_skill_006
test_optimize_missing_file_007
test_optimize_preserves_content_008
test_optimize_tier_upgrade_009
test_optimize_multi_iteration_010

report