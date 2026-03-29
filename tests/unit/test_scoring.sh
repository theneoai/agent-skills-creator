#!/usr/bin/env bash
# test_scoring.sh - 评分模块测试 (30用例)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TOOLS_LIB="${PROJECT_ROOT}/tools/lib"

source "${TOOLS_LIB}/bootstrap.sh"
source "${TOOLS_LIB}/scoring.sh"

TEST_COUNT=0
TEST_PASSED=0
TEST_FAILED=0

assert_eq() {
    local expected="$1"
    local actual="$2"
    local msg="${3:-}"
    ((TEST_COUNT++))
    if [[ "$expected" == "$actual" ]]; then
        ((TEST_PASSED++))
        echo "  ✓ $msg"
        return 0
    else
        ((TEST_FAILED++))
        echo "  ✗ $msg"
        echo "    Expected: $expected"
        echo "    Actual: $actual"
        return 1
    fi
}

assert_success() {
    local cmd="$1"
    local msg="${2:-}"
    ((TEST_COUNT++))
    if eval "$cmd" >/dev/null 2>&1; then
        ((TEST_PASSED++))
        echo "  ✓ $msg"
        return 0
    else
        ((TEST_FAILED++))
        echo "  ✗ $msg"
        return 1
    fi
}

assert_match() {
    local pattern="$1"
    local text="$2"
    local msg="${3:-}"
    ((TEST_COUNT++))
    if [[ "$text" =~ $pattern ]]; then
        ((TEST_PASSED++))
        echo "  ✓ $msg"
        return 0
    else
        ((TEST_FAILED++))
        echo "  ✗ $msg"
        echo "    Pattern: $pattern"
        echo "    Text: $text"
        return 1
    fi
}

get_tier_from_score() {
    local score="$1"
    if [[ $score -ge $TIER_PLATINUM ]]; then
        echo "PLATINUM"
    elif [[ $score -ge $TIER_GOLD ]]; then
        echo "GOLD"
    elif [[ $score -ge $TIER_SILVER ]]; then
        echo "SILVER"
    elif [[ $score -ge $TIER_BRONZE ]]; then
        echo "BRONZE"
    else
        echo "NONE"
    fi
}

is_gold() {
    local score="$1"
    [[ $score -ge $TIER_GOLD ]] && echo "1" || echo "0"
}

is_silver() {
    local score="$1"
    [[ $score -ge $TIER_SILVER ]] && [[ $score -lt $TIER_GOLD ]] && echo "1" || echo "0"
}

is_bronze() {
    local score="$1"
    [[ $score -ge $TIER_BRONZE ]] && [[ $score -lt $TIER_SILVER ]] && echo "1" || echo "0"
}

test_scoring_phase_max_001() {
    echo "  Testing phase max scores"
    assert_eq "100" "$PARSE_MAX" "PARSE_MAX is 100"
}

test_scoring_phase_max_002() {
    assert_eq "505" "$TEXT_MAX" "TEXT_MAX is 505"
}

test_scoring_phase_max_003() {
    assert_eq "450" "$RUNTIME_MAX" "RUNTIME_MAX is 450"
}

test_scoring_phase_max_004() {
    assert_eq "100" "$CERTIFY_MAX" "CERTIFY_MAX is 100"
}

test_scoring_total_max_001() {
    echo "  Testing total max scores"
    assert_eq "1155" "$TOTAL_ACTUAL_MAX" "TOTAL_ACTUAL_MAX is 1155"
}

test_scoring_total_max_002() {
    assert_eq "1000" "$TOTAL_DISPLAY_MAX" "TOTAL_DISPLAY_MAX is 1000"
}

test_scoring_tier_thresholds_001() {
    echo "  Testing tier thresholds"
    assert_eq "950" "$TIER_PLATINUM" "TIER_PLATINUM is 950"
}

test_scoring_tier_thresholds_002() {
    assert_eq "900" "$TIER_GOLD" "TIER_GOLD is 900"
}

test_scoring_tier_thresholds_003() {
    assert_eq "800" "$TIER_SILVER" "TIER_SILVER is 800"
}

test_scoring_tier_thresholds_004() {
    assert_eq "700" "$TIER_BRONZE" "TIER_BRONZE is 700"
}

test_scoring_lean_conversion_001() {
    echo "  Testing lean to standard conversion"
    local converted
    converted=$(echo "600 * $LEAN_TO_STANDARD" | bc -l)
    assert_match "^99[89]\." "$converted" "600 * 1.667 ≈ 1000"
}

test_scoring_lean_conversion_002() {
    assert_eq "1.667" "$LEAN_TO_STANDARD" "LEAN_TO_STANDARD is 1.667"
}

test_scoring_lean_thresholds_001() {
    echo "  Testing lean tier thresholds"
    assert_eq "570" "$LEAN_TIER_GOLD" "LEAN_TIER_GOLD is 570"
}

test_scoring_lean_thresholds_002() {
    assert_eq "510" "$LEAN_TIER_SILVER" "LEAN_TIER_SILVER is 510"
}

test_scoring_lean_thresholds_003() {
    assert_eq "420" "$LEAN_TIER_BRONZE" "LEAN_TIER_BRONZE is 420"
}

test_scoring_lean_norm_001() {
    echo "  Testing lean normalized thresholds"
    assert_eq "950" "$LEAN_TIER_PLATINUM" "LEAN_TIER_PLATINUM is 950"
}

test_scoring_lean_norm_002() {
    assert_eq "950" "$LEAN_TIER_GOLD_NORM" "LEAN_TIER_GOLD_NORM is 950"
}

test_scoring_lean_norm_003() {
    assert_eq "850" "$LEAN_TIER_SILVER_NORM" "LEAN_TIER_SILVER_NORM is 850"
}

test_scoring_lean_norm_004() {
    assert_eq "700" "$LEAN_TIER_BRONZE_NORM" "LEAN_TIER_BRONZE_NORM is 700"
}

test_scoring_threshold_gold_001() {
    echo "  Testing threshold detection"
    assert_eq "1" "$(is_gold 950)" "950 is GOLD threshold"
}

test_scoring_threshold_gold_002() {
    assert_eq "1" "$(is_gold 900)" "900 is GOLD threshold"
}

test_scoring_threshold_gold_003() {
    assert_eq "0" "$(is_gold 899)" "899 is not GOLD"
}

test_scoring_threshold_silver_001() {
    assert_eq "1" "$(is_silver 850)" "850 is SILVER"
}

test_scoring_threshold_silver_002() {
    assert_eq "1" "$(is_silver 800)" "800 is SILVER threshold"
}

test_scoring_threshold_silver_003() {
    assert_eq "0" "$(is_silver 799)" "799 is not SILVER"
}

test_scoring_threshold_bronze_001() {
    assert_eq "1" "$(is_bronze 750)" "750 is BRONZE"
}

test_scoring_threshold_bronze_002() {
    assert_eq "1" "$(is_bronze 700)" "700 is BRONZE threshold"
}

test_scoring_threshold_bronze_003() {
    assert_eq "0" "$(is_bronze 699)" "699 is not BRONZE"
}

test_scoring_tier_assignment_001() {
    echo "  Testing tier assignment function"
    assert_eq "PLATINUM" "$(get_tier_from_score 1000)" "Score 1000 is PLATINUM"
}

test_scoring_tier_assignment_002() {
    assert_eq "GOLD" "$(get_tier_from_score 900)" "Score 900 is GOLD"
}

test_scoring_tier_assignment_003() {
    assert_eq "SILVER" "$(get_tier_from_score 800)" "Score 800 is SILVER"
}

test_scoring_tier_assignment_004() {
    assert_eq "BRONZE" "$(get_tier_from_score 700)" "Score 700 is BRONZE"
}

test_scoring_tier_assignment_005() {
    assert_eq "NONE" "$(get_tier_from_score 500)" "Score 500 is NONE"
}

run_test_scoring_tests() {
    echo ""
    echo "=== Scoring Module Tests ==="
    test_scoring_phase_max_001
    test_scoring_phase_max_002
    test_scoring_phase_max_003
    test_scoring_phase_max_004
    test_scoring_total_max_001
    test_scoring_total_max_002
    test_scoring_tier_thresholds_001
    test_scoring_tier_thresholds_002
    test_scoring_tier_thresholds_003
    test_scoring_tier_thresholds_004
    test_scoring_lean_conversion_001
    test_scoring_lean_conversion_002
    test_scoring_lean_thresholds_001
    test_scoring_lean_thresholds_002
    test_scoring_lean_thresholds_003
    test_scoring_lean_norm_001
    test_scoring_lean_norm_002
    test_scoring_lean_norm_003
    test_scoring_lean_norm_004
    test_scoring_threshold_gold_001
    test_scoring_threshold_gold_002
    test_scoring_threshold_gold_003
    test_scoring_threshold_silver_001
    test_scoring_threshold_silver_002
    test_scoring_threshold_silver_003
    test_scoring_threshold_bronze_001
    test_scoring_threshold_bronze_002
    test_scoring_threshold_bronze_003
    test_scoring_tier_assignment_001
    test_scoring_tier_assignment_002
    test_scoring_tier_assignment_003
    test_scoring_tier_assignment_004
    test_scoring_tier_assignment_005
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_test_scoring_tests
    echo ""
    echo "Results: $TEST_PASSED/$TEST_COUNT passed"
    [[ $TEST_FAILED -gt 0 ]] && exit 1 || exit 0
fi
