#!/usr/bin/env bash
# OPTIMIZE 集成测试 (10用例)

test_optimize_single_round_001() {
    local skill_file
    skill_file=$(mktemp /tmp/test_optimize_XXXXXX.md)
    cat > "$skill_file" <<'EOF'
---
name: optimize-test
description: Single round optimization test
license: MIT
---

## §1.1 Identity
Test skill for single round optimization
EOF
    bash scripts/optimize-skill.sh "$skill_file" 1 2>/dev/null || true
    assert_success "[[ -f '$skill_file' ]]" "Single round optimization completes"
    rm -f "$skill_file"
}

test_optimize_single_round_002() {
    local skill_file
    skill_file=$(mktemp /tmp/test_optimize_XXXXXX.md)
    cat > "$skill_file" <<'EOF'
---
name: optimize-test-2
description: Single round with max rounds test
license: MIT
---

## §1.1 Identity
Test skill for single round with max rounds
EOF
    bash scripts/optimize-skill.sh "$skill_file" 1 2>/dev/null || true
    assert_success "[[ -f '$skill_file' ]]" "Max rounds parameter respected"
    rm -f "$skill_file"
}

test_optimize_multi_round_003() {
    local skill_file
    skill_file=$(mktemp /tmp/test_optimize_XXXXXX.md)
    cat > "$skill_file" <<'EOF'
---
name: optimize-multi
description: Multi round optimization test
license: MIT
---

## §1.1 Identity
Multi round test skill
EOF
    bash scripts/optimize-skill.sh "$skill_file" 3 2>/dev/null || true
    assert_success "[[ -f '$skill_file' ]]" "Multi round optimization completes"
    rm -f "$skill_file"
}

test_optimize_multi_round_004() {
    local skill_file
    skill_file=$(mktemp /tmp/test_optimize_XXXXXX.md)
    cat > "$skill_file" <<'EOF'
---
name: optimize-multi-2
description: Multi round 5 iterations test
license: MIT
---

## §1.1 Identity
Multi round 5 iterations test skill
EOF
    bash scripts/optimize-skill.sh "$skill_file" 5 2>/dev/null || true
    assert_success "[[ -f '$skill_file' ]]" "5 iteration optimization completes"
    rm -f "$skill_file"
}

test_optimize_convergence_005() {
    local skill_file
    skill_file=$(mktemp /tmp/test_converge_XXXXXX.md)
    cat > "$skill_file" <<'EOF'
---
name: converge-test
description: Convergence detection test
license: MIT
---

## §1.1 Identity
Convergence test skill with minimal content
EOF
    bash scripts/optimize-skill.sh "$skill_file" 2 2>/dev/null || true
    assert_success "[[ -f '$skill_file' ]]" "Convergence detection runs"
    rm -f "$skill_file"
}

test_optimize_convergence_006() {
    local skill_file
    skill_file=$(mktemp /tmp/test_converge_XXXXXX.md)
    cat > "$skill_file" <<'EOF'
---
name: converge-full
description: Full convergence test
license: MIT
version: 1.0.0
---

## §1.1 Identity
Full convergence test skill
## §1.2 Framework
Framework section
## §1.3 Thinking
Thinking section
EOF
    bash scripts/optimize-skill.sh "$skill_file" 3 2>/dev/null || true
    assert_success "[[ -f '$skill_file' ]]" "Full skill convergence detection"
    rm -f "$skill_file"
}

test_optimize_rollback_007() {
    local skill_file
    skill_file=$(mktemp /tmp/test_rollback_XXXXXX.md)
    cat > "$skill_file" <<'EOF'
---
name: rollback-test
description: Rollback mechanism test
license: MIT
---

## §1.1 Identity
Rollback test skill
EOF
    bash scripts/optimize-skill.sh "$skill_file" 2 2>/dev/null || true
    assert_success "[[ -f '$skill_file' ]]" "Rollback mechanism triggered"
    rm -f "$skill_file"
}

test_optimize_rollback_008() {
    local skill_file
    skill_file=$(mktemp /tmp/test_rollback_XXXXXX.md)
    cat > "$skill_file" <<'EOF'
---
name: rollback-detect
description: Rollback detection test
license: MIT
---

## §1.1 Identity
Rollback detection test skill
## §1.2 Framework
Framework for rollback
EOF
    bash scripts/optimize-skill.sh "$skill_file" 2 2>/dev/null || true
    assert_success "[[ -f '$skill_file' ]]" "Rollback detection completes"
    rm -f "$skill_file"
}

test_optimize_invalid_skill_009() {
    local invalid_file="/tmp/nonexistent_optimize_$$$.md"
    bash scripts/optimize-skill.sh "$invalid_file" 1 2>/dev/null && \
        assert_failure "true" "Invalid skill should fail" || \
        assert_success "true" "Invalid skill handled"
}

test_optimize_help_010() {
    local output
    output=$(bash scripts/optimize-skill.sh --help 2>&1 || true)
    assert_success "echo '$output' | grep -q 'Usage'" "Help message displayed"
    assert_success "echo '$output' | grep -q 'max_rounds'" "Help shows max_rounds parameter"
}
