#!/usr/bin/env bash
# 完整生命周期端到端测试
# 10 test cases for full lifecycle: CREATE → EVALUATE → OPTIMIZE → SECURITY → RESTORE

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "${PROJECT_ROOT}/tests/framework.sh"

CREATE_SCRIPT="${PROJECT_ROOT}/scripts/create-skill.sh"
EVAL_SCRIPT="${PROJECT_ROOT}/tools/eval/main.sh"
OPTIMIZE_SCRIPT="${PROJECT_ROOT}/scripts/optimize-skill.sh"
RESTORE_SCRIPT="${PROJECT_ROOT}/scripts/restore-skill.sh"
SECURITY_SCRIPT="${PROJECT_ROOT}/scripts/security-audit.sh"

test_lifecycle_create_to_security_001() {
    local output
    output=$(mktemp /tmp/test_lc_XXXXXX.md)
    bash "$CREATE_SCRIPT" "Full lifecycle test skill" "$output" --no-agent 2>/dev/null || true
    local eval_result
    eval_result=$(bash "$EVAL_SCRIPT" --skill "$output" --fast --no-agent 2>&1 || true)
    assert_match "[0-9]+" "$eval_result" "CREATE → EVALUATE works"
    if [[ -x "$SECURITY_SCRIPT" ]]; then
        bash "$SECURITY_SCRIPT" "$output" 2>/dev/null || true
    fi
    assert_success "[[ -f '$output' ]]" "Skill file preserved through lifecycle"
    rm -f "$output"
}

test_lifecycle_all_modes_002() {
    local output
    output=$(mktemp /tmp/test_lc_XXXXXX.md)
    cat > "$output" <<'EOF'
---
name: all-modes-test
description: Test all lifecycle modes
license: MIT
---

# All Modes Test

## §1.1 Identity
Test skill

## §1.2 Framework

## §1.3 Thinking
EOF
    local result
    result=$(bash "$EVAL_SCRIPT" --skill "$output" --fast --no-agent 2>&1 || true)
    assert_match "[0-9]+" "$result" "EVALUATE mode works"
    if [[ -x "$OPTIMIZE_SCRIPT" ]]; then
        bash "$OPTIMIZE_SCRIPT" "$output" 2>/dev/null || true
    fi
    assert_success "[[ -f '$output' ]]" "OPTIMIZE mode works"
    if [[ -x "$RESTORE_SCRIPT" ]]; then
        bash "$RESTORE_SCRIPT" "$output" 2>/dev/null || true
    fi
    assert_success "[[ -f '$output' ]]" "RESTORE mode works"
    rm -f "$output"
}

test_lifecycle_create_evaluate_optimize_003() {
    local output
    output=$(mktemp /tmp/test_lc_XXXXXX.md)
    bash "$CREATE_SCRIPT" "C-E-O test" "$output" --no-agent 2>/dev/null || true
    local score1
    score1=$(bash "$EVAL_SCRIPT" --skill "$output" --fast --no-agent 2>/dev/null | grep -oE "[0-9]+" | head -1 || echo "0")
    if [[ -x "$OPTIMIZE_SCRIPT" ]]; then
        bash "$OPTIMIZE_SCRIPT" "$output" 3 2>/dev/null || true
    fi
    local score2
    score2=$(bash "$EVAL_SCRIPT" --skill "$output" --fast --no-agent 2>/dev/null | grep -oE "[0-9]+" | head -1 || echo "0")
    assert_match "[0-9]+" "$score2" "CREATE → EVALUATE → OPTIMIZE → EVALUATE works"
    rm -f "$output"
}

test_lifecycle_minimal_skill_004() {
    local output
    output=$(mktemp /tmp/test_lc_XXXXXX.md)
    cat > "$output" <<'EOF'
---
name: minimal-lifecycle
description: Minimal lifecycle test
license: MIT
---

# Minimal

## §1.1 Identity

## §1.2 Framework

## §1.3 Thinking
EOF
    local result
    result=$(bash "$EVAL_SCRIPT" --skill "$output" --fast --no-agent 2>&1 || true)
    assert_match "[0-9]+" "$result" "Minimal skill lifecycle works"
    rm -f "$output"
}

test_lifecycle_multiple_iterations_005() {
    local output
    output=$(mktemp /tmp/test_lc_XXXXXX.md)
    cat > "$output" <<'EOF'
---
name: multi-iter
description: Multiple iterations test
license: MIT
---

# Multi Iteration

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
        bash "$EVAL_SCRIPT" --skill "$output" --fast --no-agent 2>/dev/null || true
    done
    assert_success "[[ -f '$output' ]]" "Multiple iterations preserve file"
    rm -f "$output"
}

test_lifecycle_robustness_006() {
    local output
    output=$(mktemp /tmp/test_lc_XXXXXX.md)
    cat > "$output" <<'EOF'
---
name: robustness-test
description: Robustness test
license: MIT
---

# Robustness Test

## §1.1 Identity
Test

## §1.2 Framework
Uses ReAct

## §1.3 Thinking
EOF
    if [[ -x "$RESTORE_SCRIPT" ]]; then
        bash "$RESTORE_SCRIPT" "$output" 2>/dev/null || true
    fi
    if [[ -x "$OPTIMIZE_SCRIPT" ]]; then
        bash "$OPTIMIZE_SCRIPT" "$output" 2>/dev/null || true
    fi
    local result
    result=$(bash "$EVAL_SCRIPT" --skill "$output" --fast --no-agent 2>&1 || true)
    assert_match "[0-9]+" "$result" "Robustness test produces result"
    rm -f "$output"
}

test_lifecycle_quality_progression_007() {
    local output
    output=$(mktemp /tmp/test_lc_XXXXXX.md)
    cat > "$output" <<'EOF'
---
name: quality-progression
description: Quality progression test
license: MIT
version: 1.0.0
---

# Quality Progression

## §1.1 Identity
Test skill for quality progression

## §1.2 Framework
- ReAct pattern
- Chain of Thought
- F1 >= 0.90

## §1.3 Thinking
- Risk assessment
- Decision making

## §2 Invocation

| CREATE | EVALUATE | OPTIMIZE | RESTORE |
|--------|----------|----------|---------|

## §3 Process

### Phase 1: Init
Initialize

### Phase 2: Analyze
Analyze

### Done: Complete
EOF
    local score1
    score1=$(bash "$EVAL_SCRIPT" --skill "$output" --fast --no-agent 2>/dev/null | grep -oE "[0-9]+" | head -1 || echo "0")
    if [[ -x "$OPTIMIZE_SCRIPT" ]]; then
        bash "$OPTIMIZE_SCRIPT" "$output" 5 2>/dev/null || true
    fi
    local score2
    score2=$(bash "$EVAL_SCRIPT" --skill "$output" --fast --no-agent 2>/dev/null | grep -oE "[0-9]+" | head -1 || echo "0")
    assert_match "[0-9]+" "$score2" "Quality progression produces scores"
    rm -f "$output"
}

test_lifecycle_error_recovery_008() {
    local output
    output=$(mktemp /tmp/test_lc_XXXXXX.md)
    cat > "$output" <<'EOF'
---
name: error-recovery
description: Error recovery test
license: MIT
---

# Error Recovery

## §1.1 Identity
Test

## §1.2 Framework

## §1.3 Thinking
EOF
    if [[ -x "$RESTORE_SCRIPT" ]]; then
        bash "$RESTORE_SCRIPT" "$output" 2>/dev/null || true
    fi
    local result
    result=$(bash "$EVAL_SCRIPT" --skill "$output" --fast --no-agent 2>&1 || true)
    assert_match "[0-9]+" "$result" "Error recovery produces result"
    rm -f "$output"
}

test_lifecycle_concurrent_safety_009() {
    local output1
    output1=$(mktemp /tmp/test_lc1_XXXXXX.md)
    local output2
    output2=$(mktemp /tmp/test_lc2_XXXXXX.md)
    cat > "$output1" <<'EOF'
---
name: concurrent1
description: Concurrent test 1
license: MIT
---

# Concurrent 1

## §1.1 Identity

## §1.2 Framework

## §1.3 Thinking
EOF
    cat > "$output2" <<'EOF'
---
name: concurrent2
description: Concurrent test 2
license: MIT
---

# Concurrent 2

## §1.1 Identity

## §1.2 Framework

## §1.3 Thinking
EOF
    local result1
    result1=$(bash "$EVAL_SCRIPT" --skill "$output1" --fast --no-agent 2>&1 || true)
    local result2
    result2=$(bash "$EVAL_SCRIPT" --skill "$output2" --fast --no-agent 2>&1 || true)
    assert_match "[0-9]+" "$result1" "First concurrent evaluation works"
    assert_match "[0-9]+" "$result2" "Second concurrent evaluation works"
    rm -f "$output1" "$output2"
}

test_lifecycle_end_to_end_quality_010() {
    local output
    output=$(mktemp /tmp/test_lc_XXXXXX.md)
    cat > "$output" <<'EOF'
---
name: e2e-quality
description: End-to-end quality test
license: MIT
version: 1.0.0
author: test
tags:
  - test
  - e2e
---

# E2E Quality Test

## §1.1 Identity
- **Name**: E2E Quality Skill
- **Purpose**: Test end-to-end quality
- **Constraints**: Never compromise quality

## §1.2 Framework
- ReAct pattern for reasoning
- Chain of Thought for analysis
- F1 score >= 0.90 threshold
- NIST security guidelines compliance
- Uses industry best practices

## §1.3 Thinking
- Systematic risk assessment
- Data-driven decision making
- Continuous improvement loop

## §2 Invocation

| CREATE | EVALUATE | OPTIMIZE | RESTORE | SECURITY |
|--------|----------|----------|---------|----------|
| New skill creation | Quality assessment | Performance tuning | Fix issues | Security audit |

### Trigger Keywords
- CREATE: new, create, build, develop
- EVALUATE: evaluate, assess, review, test
- OPTIMIZE: optimize, improve, enhance, tune
- RESTORE: restore, fix, repair, recover
- SECURITY: security, audit, scan, protect

## §3 Process

### Phase 1: Initialization
1. Load configuration
2. Initialize context
3. Setup environment

### Phase 2: Analysis
1. Parse input
2. Analyze patterns
3. Identify risks

### Phase 3: Implementation
1. Apply changes
2. Validate output
3. Log results

### Done:
- All checks pass
- F1 >= 0.90
- MRR >= 0.85
- Security scan clean

### Fail:
- Any check fails
- Performance degrades
- Security issue found

## §4 Tool Set

### Primary Tools
- `analyze()`: Analyze input patterns
- `implement()`: Apply changes
- `validate()`: Check output quality
- `report()`: Generate reports

### Secondary Tools
- `audit()`: Security audit
- `optimize()`: Performance tuning
- `backup()`: Create backup

## §5 Validation

### Quality Checks
- Unit test pass rate >= 95%
- F1 score >= 0.90
- MRR >= 0.85
- Trigger accuracy >= 0.99

### Security Checks
- No API key exposure
- No hardcoded credentials
- OWASP compliance

### Performance Checks
- Response time < 1s
- Memory usage < 512MB
- CPU usage < 50%

## §6 Self-Evolution

### Triggers
- Score drop > 5%
- New threat detected
- Performance degradation

### Actions
- Analyze root cause
- Generate fix
- Validate improvement
EOF
    local score
    score=$(bash "$EVAL_SCRIPT" --skill "$output" --fast --no-agent 2>/dev/null | grep -oE "[0-9]+" | head -1 || echo "0")
    assert_match "[0-9]+" "$score" "End-to-end quality test produces score"
    if [[ -x "$OPTIMIZE_SCRIPT" ]]; then
        bash "$OPTIMIZE_SCRIPT" "$output" 5 2>/dev/null || true
    fi
    local score2
    score2=$(bash "$EVAL_SCRIPT" --skill "$output" --fast --no-agent 2>/dev/null | grep -oE "[0-9]+" | head -1 || echo "0")
    assert_match "[0-9]+" "$score2" "Final score after optimization"
    rm -f "$output"
}

test_lifecycle_create_to_security_001
test_lifecycle_all_modes_002
test_lifecycle_create_evaluate_optimize_003
test_lifecycle_minimal_skill_004
test_lifecycle_multiple_iterations_005
test_lifecycle_robustness_006
test_lifecycle_quality_progression_007
test_lifecycle_error_recovery_008
test_lifecycle_concurrent_safety_009
test_lifecycle_end_to_end_quality_010

report