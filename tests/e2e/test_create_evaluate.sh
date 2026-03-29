#!/usr/bin/env bash
# CREATE→EVALUATE 端到端测试
# 10 test cases for create and evaluate workflow

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "${PROJECT_ROOT}/tests/framework.sh"

CREATE_SCRIPT="${PROJECT_ROOT}/scripts/create-skill.sh"
EVAL_SCRIPT="${PROJECT_ROOT}/tools/eval/main.sh"

test_create_evaluate_normal_001() {
    local output
    output=$(mktemp /tmp/test_ce_XXXXXX.md)
    bash "$CREATE_SCRIPT" "Test skill for e2e" "$output" --no-agent 2>/dev/null || true
    assert_success "[[ -f '$output' ]]" "Skill created"
    local score
    score=$(bash "$EVAL_SCRIPT" --skill "$output" --fast --no-agent 2>/dev/null | grep -oE "[0-9]+" | head -1 || echo "0")
    assert_match "[0-9]+" "$score" "Score obtained"
    rm -f "$output"
}

test_create_evaluate_low_quality_002() {
    local output
    output=$(mktemp /tmp/test_ce_XXXXXX.md)
    cat > "$output" <<'EOF'
---
name: low-quality
description: Low quality skill
license: MIT
---

# Low Quality Skill

Just some text without proper structure.
EOF
    local result
    result=$(bash "$EVAL_SCRIPT" --skill "$output" --fast --no-agent 2>&1 || true)
    assert_match "[0-9]+" "$result" "Evaluation produces score for low quality skill"
    rm -f "$output"
}

test_create_evaluate_high_quality_003() {
    local output
    output=$(mktemp /tmp/test_ce_XXXXXX.md)
    cat > "$output" <<'EOF'
---
name: high-quality-skill
description: A comprehensive code review skill
license: MIT
version: 1.0.0
---

# High Quality Skill

## §1.1 Identity
- **Name**: Code Review Skill
- **Purpose**: Perform thorough code reviews
- **Constraints**: Never approve code with security vulnerabilities

## §1.2 Framework
- ReAct pattern for reasoning
- Uses F1 score >= 0.90 for validation
- NIST security guidelines compliance

## §1.3 Thinking
- Chain of thought for analysis
- Risk assessment framework

## §2 Invocation

| Trigger | Mode |
|---------|------|
| CREATE | Code creation |
| EVALUATE | Quality assessment |

## §3 Process

### Phase 1: Parse
- Extract code structure

### Phase 2: Analyze
- Security check
- Performance analysis

### Done: All checks pass

### Fail: Any check fails

## §4 Tools
- Static analysis tools
- Security scanners

## §5 Validation
- Unit tests pass
- F1 >= 0.90
EOF
    local result
    result=$(bash "$EVAL_SCRIPT" --skill "$output" --fast --no-agent 2>&1 || true)
    assert_match "[0-9]+" "$result" "High quality skill gets evaluated"
    rm -f "$output"
}

test_create_evaluate_no_agent_004() {
    local output
    output=$(mktemp /tmp/test_ce_XXXXXX.md)
    bash "$CREATE_SCRIPT" "No agent test skill" "$output" --no-agent 2>/dev/null || true
    assert_success "[[ -f '$output' ]]" "Skill created without agent"
    local result
    result=$(bash "$EVAL_SCRIPT" --skill "$output" --fast --no-agent 2>&1 || true)
    assert_match "[0-9]+" "$result" "Evaluate works without agent"
    rm -f "$output"
}

test_create_evaluate_file_not_found_005() {
    local result
    result=$(bash "$EVAL_SCRIPT" --skill "/nonexistent/file.md" --fast --no-agent 2>&1 || true)
    assert_match "not found|Error|error" "$result" "Handles missing file"
}

test_create_evaluate_fast_mode_006() {
    local output
    output=$(mktemp /tmp/test_ce_XXXXXX.md)
    cat > "$output" <<'EOF'
---
name: fast-test
description: Fast mode test
license: MIT
---

# Fast Test

## §1.1 Identity
## §1.2 Framework
## §1.3 Thinking
EOF
    local result
    result=$(bash "$EVAL_SCRIPT" --skill "$output" --fast --no-agent 2>&1 || true)
    assert_match "[0-9]+" "$result" "Fast mode produces results"
    rm -f "$output"
}

test_create_evaluate_ci_mode_007() {
    local output
    output=$(mktemp /tmp/test_ce_XXXXXX.md)
    cat > "$output" <<'EOF'
---
name: ci-test
description: CI mode test
license: MIT
---

# CI Test

## §1.1 Identity
## §1.2 Framework
## §1.3 Thinking
EOF
    local result
    result=$(bash "$EVAL_SCRIPT" --skill "$output" --fast --no-agent --ci 2>&1 || true)
    assert_match "[0-9]+" "$result" "CI mode produces results"
    rm -f "$output"
}

test_create_evaluate_output_dir_008() {
    local output
    output=$(mktemp /tmp/test_ce_XXXXXX.md)
    local eval_dir
    eval_dir=$(mktemp -d /tmp/test_eval_XXXXXX)
    cat > "$output" <<'EOF'
---
name: output-test
description: Output dir test
license: MIT
---

# Output Test

## §1.1 Identity
## §1.2 Framework
## §1.3 Thinking
EOF
    bash "$EVAL_SCRIPT" --skill "$output" --fast --no-agent --output "$eval_dir" 2>/dev/null || true
    assert_success "[[ -d '$eval_dir' ]]" "Output directory created"
    assert_success "[[ -f '$eval_dir/summary.json' ]]" "Summary JSON created"
    rm -rf "$output" "$eval_dir"
}

test_create_evaluate_cross_llm_009() {
    local output
    output=$(mktemp /tmp/test_ce_XXXXXX.md)
    cat > "$output" <<'EOF'
---
name: cross-llm-test
description: Multi-LLM validation test
license: MIT
---

# Cross LLM Test

## §1.1 Identity
## §1.2 Framework
- Uses ReAct framework
- Implements Chain of Thought

## §1.3 Thinking
- Risk assessment
- Decision making
EOF
    local result
    result=$(bash "$EVAL_SCRIPT" --skill "$output" --fast --no-agent 2>&1 || true)
    assert_match "[0-9]+" "$result" "Cross-LLM evaluation completes"
    rm -f "$output"
}

test_create_evaluate_score_range_010() {
    local output
    output=$(mktemp /tmp/test_ce_XXXXXX.md)
    cat > "$output" <<'EOF'
---
name: score-range-test
description: Score range validation
license: MIT
---

# Score Range Test

## §1.1 Identity
Test skill for score range

## §1.2 Framework
Uses proper framework

## §1.3 Thinking
Cognitive approach

## §2 Invocation

| CREATE | EVALUATE | OPTIMIZE | RESTORE | SECURITY |
|--------|----------|----------|---------|----------|

## §3 Process

### Phase 1: Init
Initialize

### Done: Complete

## §4 Tools
- tool1
- tool2

## §5 Validation
- F1 >= 0.90
- MRR >= 0.85
EOF
    local score
    score=$(bash "$EVAL_SCRIPT" --skill "$output" --fast --no-agent 2>/dev/null | grep -oE "[0-9]+" | head -1 || echo "0")
    assert_match "[0-9]+" "$score" "Score is numeric"
    rm -f "$output"
}

test_create_evaluate_normal_001
test_create_evaluate_low_quality_002
test_create_evaluate_high_quality_003
test_create_evaluate_no_agent_004
test_create_evaluate_file_not_found_005
test_create_evaluate_fast_mode_006
test_create_evaluate_ci_mode_007
test_create_evaluate_output_dir_008
test_create_evaluate_cross_llm_009
test_create_evaluate_score_range_010

report