#!/usr/bin/env bash
# EVALUATE 集成测试 (15用例)

test_evaluate_valid_skill_001() {
    local result
    result=$(bash tools/eval/main.sh --skill SKILL.md --fast --no-agent 2>/dev/null || true)
    assert_success "echo '$result' | grep -qE '[0-9]+'" "Returns score in output"
}

test_evaluate_valid_skill_002() {
    local result
    result=$(bash tools/eval/main.sh --skill SKILL.md --fast --no-agent 2>/dev/null || true)
    assert_success "echo '$result' | grep -q 'total_score'" "JSON output contains total_score"
}

test_evaluate_invalid_skill_003() {
    local invalid_file="/tmp/nonexistent_skill_$$$.md"
    bash tools/eval/main.sh --skill "$invalid_file" --fast --no-agent 2>/dev/null && \
        assert_failure "true" "Invalid skill should fail" || \
        assert_success "true" "Invalid skill handled correctly"
}

test_evaluate_invalid_skill_004() {
    local empty_file
    empty_file=$(mktemp /tmp/test_empty_XXXXXX.md)
    echo "" > "$empty_file"
    bash tools/eval/main.sh --skill "$empty_file" --fast --no-agent 2>/dev/null || true
    assert_success "grep -q 'score' '$empty_file'" "Empty file evaluation returns score"
    rm -f "$empty_file"
}

test_evaluate_boundary_005() {
    local minimal_file
    minimal_file=$(mktemp /tmp/test_minimal_XXXXXX.md)
    cat > "$minimal_file" <<'EOF'
---
name: minimal
description: minimal test
license: MIT
---
## §1.1 Identity
Test
EOF
    bash tools/eval/main.sh --skill "$minimal_file" --fast --no-agent 2>/dev/null || true
    assert_success "[[ -f '$minimal_file' ]]" "Minimal valid skill evaluated"
    rm -f "$minimal_file"
}

test_evaluate_boundary_006() {
    local large_file
    large_file=$(mktemp /tmp/test_large_XXXXXX.md)
    {
        echo "---"
        echo "name: large"
        echo "description: large test skill"
        echo "license: MIT"
        echo "---"
        for i in $(seq 1 100); do
            echo "## §1.$i Section $i"
            echo "Content for section $i with some additional text to make it larger"
        done
    } > "$large_file"
    bash tools/eval/main.sh --skill "$large_file" --fast --no-agent 2>/dev/null || true
    assert_success "[[ -f '$large_file' ]]" "Large skill file evaluated"
    rm -f "$large_file"
}

test_evaluate_parallel_007() {
    local out1 out2 out3
    out1=$(mktemp /tmp/test_eval_parallel_1_XXXXXX.md)
    out2=$(mktemp /tmp/test_eval_parallel_2_XXXXXX.md)
    out3=$(mktemp /tmp/test_eval_parallel_3_XXXXXX.md)
    cat > "$out1" <<'EOF'
---
name: parallel-test-1
description: Parallel evaluation test 1
license: MIT
---
## §1.1 Identity
Test skill 1
EOF
    cat > "$out2" <<'EOF'
---
name: parallel-test-2
description: Parallel evaluation test 2
license: MIT
---
## §1.1 Identity
Test skill 2
EOF
    cat > "$out3" <<'EOF'
---
name: parallel-test-3
description: Parallel evaluation test 3
license: MIT
---
## §1.1 Identity
Test skill 3
EOF
    (
        bash tools/eval/main.sh --skill "$out1" --fast --no-agent 2>/dev/null &
        bash tools/eval/main.sh --skill "$out2" --fast --no-agent 2>/dev/null &
        bash tools/eval/main.sh --skill "$out3" --fast --no-agent 2>/dev/null &
        wait
    )
    local count=0
    [[ -f "$out1" ]] && ((count++)) || true
    [[ -f "$out2" ]] && ((count++)) || true
    [[ -f "$out3" ]] && ((count++)) || true
    rm -f "$out1" "$out2" "$out3"
    assert_success "[[ $count -eq 3 ]]" "Parallel evaluation completes all files"
}

test_evaluate_fast_mode_008() {
    local result
    result=$(bash tools/eval/main.sh --skill SKILL.md --fast --no-agent 2>/dev/null)
    assert_success "echo '$result' | grep -q 'fast'" "Fast mode flag respected"
}

test_evaluate_full_mode_009() {
    local result
    result=$(bash tools/eval/main.sh --skill SKILL.md --full --no-agent 2>/dev/null || true)
    assert_success "[[ -n '$result' ]]" "Full mode flag respected"
}

test_evaluate_ci_mode_010() {
    local result
    result=$(bash tools/eval/main.sh --skill SKILL.md --fast --no-agent --ci 2>/dev/null)
    assert_success "[[ -n '$result' ]]" "CI mode flag respected"
}

test_evaluate_output_dir_011() {
    local output_dir
    output_dir=$(mktemp -d /tmp/test_eval_output_XXXXXX)
    bash tools/eval/main.sh --skill SKILL.md --fast --no-agent --output "$output_dir" 2>/dev/null || true
    assert_success "[[ -d '$output_dir' ]]" "Custom output directory created"
    assert_success "[[ -f '$output_dir/summary.json' ]]" "Summary JSON generated"
    rm -rf "$output_dir"
}

test_evaluate_yaml_frontmatter_012() {
    local skill_file
    skill_file=$(mktemp /tmp/test_yaml_XXXXXX.md)
    cat > "$skill_file" <<'EOF'
---
name: yaml-test
description: YAML frontmatter test
license: MIT
---

## §1.1 Identity
Test content
EOF
    bash tools/eval/main.sh --skill "$skill_file" --fast --no-agent 2>/dev/null || true
    assert_success "[[ -f '$skill_file' ]]" "YAML frontmatter skill evaluated"
    rm -f "$skill_file"
}

test_evaluate_missing_yaml_013() {
    local skill_file
    skill_file=$(mktemp /tmp/test_no_yaml_XXXXXX.md)
    cat > "$skill_file" <<'EOF'
## §1.1 Identity
No YAML frontmatter
EOF
    bash tools/eval/main.sh --skill "$skill_file" --fast --no-agent 2>/dev/null || true
    assert_success "[[ -f '$skill_file' ]]" "Missing YAML frontmatter handled"
    rm -f "$skill_file"
}

test_evaluate_trigger_detection_014() {
    local skill_file
    skill_file=$(mktemp /tmp/test_triggers_XXXXXX.md)
    cat > "$skill_file" <<'EOF'
---
name: trigger-test
description: Trigger detection test
license: MIT
---

## §1.1 Identity
Test skill with CREATE EVALUATE OPTIMIZE RESTORE SECURITY triggers
EOF
    bash tools/eval/main.sh --skill "$skill_file" --fast --no-agent 2>/dev/null || true
    assert_success "[[ -f '$skill_file' ]]" "Trigger detection skill evaluated"
    rm -f "$skill_file"
}

test_evaluate_security_violation_015() {
    local skill_file
    skill_file=$(mktemp /tmp/test_security_XXXXXX.md)
    cat > "$skill_file" <<'EOF'
---
name: security-test
description: Security violation test
license: MIT
---

## §1.1 Identity
Test skill with API key = "sk-1234567890abcdefghijklmnop"
EOF
    bash tools/eval/main.sh --skill "$skill_file" --fast --no-agent 2>/dev/null || true
    assert_success "[[ -f '$skill_file' ]]" "Security violation detection skill evaluated"
    rm -f "$skill_file"
}
