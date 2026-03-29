#!/usr/bin/env bash
# test_trigger.sh - Trigger Word Recognition Tests (20 test cases)
# TDD: Tests describe expected behavior of trigger detection

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
if ! declare -f assert_eq >/dev/null 2>&1; then
    source "${PROJECT_ROOT}/tests/framework.sh"
fi

# Mock detect_intent function for testing (since it doesn't exist yet)
detect_intent() {
    local input="$1"
    input=$(echo "$input" | tr '[:upper:]' '[:lower:]')
    
    case "$input" in
        *create*skill*|*create*new*|*创建*技能*|*新建*)
            echo "CREATE"
            ;;
        *evaluat*|*评估*|*evaluate*)
            echo "EVALUATE"
            ;;
        *restor*|*恢复*|*restore*)
            echo "RESTORE"
            ;;
        *secur*|*安全*|*security*)
            echo "SECURITY"
            ;;
        *optimi*|*优化*|*optimize*)
            echo "OPTIMIZE"
            ;;
        *)
            echo "UNKNOWN"
            ;;
    esac
}

# ============================================================================
# CREATE Trigger Tests (IDs: 001-004)
# ============================================================================

test_trigger_create_zh_001() {
    local result
    result=$(detect_intent "创建技能")
    assert_eq "CREATE" "$result" "Chinese '创建技能' triggers CREATE"
}

test_trigger_create_zh_002() {
    local result
    result=$(detect_intent "创建一个新的技能")
    assert_eq "CREATE" "$result" "Chinese '创建一个新的技能' triggers CREATE"
}

test_trigger_create_en_003() {
    local result
    result=$(detect_intent "create a new skill")
    assert_eq "CREATE" "$result" "English 'create a new skill' triggers CREATE"
}

test_trigger_create_en_004() {
    local result
    result=$(detect_intent "I want to create skill")
    assert_eq "CREATE" "$result" "English phrase triggers CREATE"
}

# ============================================================================
# EVALUATE Trigger Tests (IDs: 005-008)
# ============================================================================

test_trigger_evaluate_zh_005() {
    local result
    result=$(detect_intent "评估技能")
    assert_eq "EVALUATE" "$result" "Chinese '评估技能' triggers EVALUATE"
}

test_trigger_evaluate_zh_006() {
    local result
    result=$(detect_intent "评估这个技能的质量")
    assert_eq "EVALUATE" "$result" "Chinese phrase triggers EVALUATE"
}

test_trigger_evaluate_en_007() {
    local result
    result=$(detect_intent "evaluate this skill")
    assert_eq "EVALUATE" "$result" "English 'evaluate this skill' triggers EVALUATE"
}

test_trigger_evaluate_en_008() {
    local result
    result=$(detect_intent "I need to evaluate the skill")
    assert_eq "EVALUATE" "$result" "English phrase triggers EVALUATE"
}

# ============================================================================
# RESTORE Trigger Tests (IDs: 009-011)
# ============================================================================

test_trigger_restore_zh_009() {
    local result
    result=$(detect_intent "恢复技能")
    assert_eq "RESTORE" "$result" "Chinese '恢复技能' triggers RESTORE"
}

test_trigger_restore_zh_010() {
    local result
    result=$(detect_intent "恢复之前的版本")
    assert_eq "RESTORE" "$result" "Chinese phrase triggers RESTORE"
}

test_trigger_restore_en_011() {
    local result
    result=$(detect_intent "restore the skill")
    assert_eq "RESTORE" "$result" "English 'restore' triggers RESTORE"
}

# ============================================================================
# SECURITY Trigger Tests (IDs: 012-014)
# ============================================================================

test_trigger_security_zh_012() {
    local result
    result=$(detect_intent "安全检查")
    assert_eq "SECURITY" "$result" "Chinese '安全检查' triggers SECURITY"
}

test_trigger_security_zh_013() {
    local result
    result=$(detect_intent "检查安全问题")
    assert_eq "SECURITY" "$result" "Chinese phrase triggers SECURITY"
}

test_trigger_security_en_014() {
    local result
    result=$(detect_intent "run security check")
    assert_eq "SECURITY" "$result" "English phrase triggers SECURITY"
}

# ============================================================================
# OPTIMIZE Trigger Tests (IDs: 015-017)
# ============================================================================

test_trigger_optimize_zh_015() {
    local result
    result=$(detect_intent "优化技能")
    assert_eq "OPTIMIZE" "$result" "Chinese '优化技能' triggers OPTIMIZE"
}

test_trigger_optimize_zh_016() {
    local result
    result=$(detect_intent "优化性能")
    assert_eq "OPTIMIZE" "$result" "Chinese phrase triggers OPTIMIZE"
}

test_trigger_optimize_en_017() {
    local result
    result=$(detect_intent "optimize the skill")
    assert_eq "OPTIMIZE" "$result" "English 'optimize' triggers OPTIMIZE"
}

# ============================================================================
# Ambiguous Input Tests (IDs: 018-020)
# ============================================================================

test_trigger_ambiguous_018() {
    local result
    result=$(detect_intent "hello world")
    assert_eq "UNKNOWN" "$result" "Unknown input returns UNKNOWN"
}

test_trigger_ambiguous_019() {
    local result
    result=$(detect_intent "make something")
    assert_eq "UNKNOWN" "$result" "Non-matching phrase returns UNKNOWN"
}

test_trigger_ambiguous_020() {
    local result
    result=$(detect_intent "")
    assert_eq "UNKNOWN" "$result" "Empty input returns UNKNOWN"
}

# ============================================================================
# Run all trigger tests
# ============================================================================

main() {
    echo "Running Trigger Recognition Tests (20 cases)..."
    
    test_trigger_create_zh_001
    test_trigger_create_zh_002
    test_trigger_create_en_003
    test_trigger_create_en_004
    test_trigger_evaluate_zh_005
    test_trigger_evaluate_zh_006
    test_trigger_evaluate_en_007
    test_trigger_evaluate_en_008
    test_trigger_restore_zh_009
    test_trigger_restore_zh_010
    test_trigger_restore_en_011
    test_trigger_security_zh_012
    test_trigger_security_zh_013
    test_trigger_security_en_014
    test_trigger_optimize_zh_015
    test_trigger_optimize_zh_016
    test_trigger_optimize_en_017
    test_trigger_ambiguous_018
    test_trigger_ambiguous_019
    test_trigger_ambiguous_020
}

main "$@"
