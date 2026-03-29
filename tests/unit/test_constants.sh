#!/usr/bin/env bash
# test_constants.sh - 常量模块测试 (20用例)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TOOLS_LIB="${PROJECT_ROOT}/tools/lib"

source "${TOOLS_LIB}/bootstrap.sh"
source "${TOOLS_LIB}/constants.sh"

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

assert_neq() {
    local not_expected="$1"
    local actual="$2"
    local msg="${3:-}"
    ((TEST_COUNT++))
    if [[ "$not_expected" != "$actual" ]]; then
        ((TEST_PASSED++))
        echo "  ✓ $msg"
        return 0
    else
        ((TEST_FAILED++))
        echo "  ✗ $msg"
        echo "    Expected not: $not_expected"
        echo "    Actual: $actual"
        return 1
    fi
}

get_tier() {
    local score="$1"
    if [[ $score -ge $PLATINUM_MIN ]]; then
        echo "PLATINUM"
    elif [[ $score -ge $GOLD_MIN ]]; then
        echo "GOLD"
    elif [[ $score -ge $SILVER_MIN ]]; then
        echo "SILVER"
    elif [[ $score -ge $BRONZE_MIN ]]; then
        echo "BRONZE"
    else
        echo "NONE"
    fi
}

test_constants_tier_gold_001() {
    echo "  Testing GOLD tier boundary (>=900)"
    assert_eq "GOLD" "$(get_tier 900)" "Score 900 is GOLD"
}

test_constants_tier_gold_002() {
    assert_eq "PLATINUM" "$(get_tier 950)" "Score 950 is PLATINUM"
}

test_constants_tier_gold_003() {
    assert_eq "PLATINUM" "$(get_tier 999)" "Score 999 is PLATINUM"
}

test_constants_tier_silver_001() {
    echo "  Testing SILVER tier boundary (800-899)"
    assert_eq "SILVER" "$(get_tier 800)" "Score 800 is SILVER"
}

test_constants_tier_silver_002() {
    assert_eq "SILVER" "$(get_tier 850)" "Score 850 is SILVER"
}

test_constants_tier_silver_003() {
    assert_eq "SILVER" "$(get_tier 899)" "Score 899 is SILVER"
}

test_constants_tier_bronze_001() {
    echo "  Testing BRONZE tier boundary (700-799)"
    assert_eq "BRONZE" "$(get_tier 700)" "Score 700 is BRONZE"
}

test_constants_tier_bronze_002() {
    assert_eq "BRONZE" "$(get_tier 750)" "Score 750 is BRONZE"
}

test_constants_tier_bronze_003() {
    assert_eq "BRONZE" "$(get_tier 799)" "Score 799 is BRONZE"
}

test_constants_tier_none_001() {
    echo "  Testing NONE tier (<700)"
    assert_eq "NONE" "$(get_tier 699)" "Score 699 is NONE"
}

test_constants_tier_none_002() {
    assert_eq "NONE" "$(get_tier 0)" "Score 0 is NONE"
}

test_constants_tier_platinum_001() {
    echo "  Testing PLATINUM tier boundary (>=950)"
    assert_eq "PLATINUM" "$(get_tier 950)" "Score 950 is PLATINUM"
}

test_constants_tier_platinum_002() {
    assert_eq "PLATINUM" "$(get_tier 1000)" "Score 1000 is PLATINUM"
}

test_constants_thresholds_001() {
    echo "  Testing score thresholds"
    assert_eq "280" "$TEXT_SCORE_MIN" "TEXT_SCORE_MIN is 280"
}

test_constants_thresholds_002() {
    assert_eq "360" "$RUNTIME_SCORE_MIN" "RUNTIME_SCORE_MIN is 360"
}

test_constants_thresholds_003() {
    assert_eq "20" "$VARIANCE_MAX" "VARIANCE_MAX is 20"
}

test_constants_f1_threshold_001() {
    echo "  Testing F1 and MRR thresholds"
    assert_eq "0.90" "$F1_THRESHOLD" "F1_THRESHOLD is 0.90"
}

test_constants_f1_threshold_002() {
    assert_eq "0.85" "$MRR_THRESHOLD" "MRR_THRESHOLD is 0.85"
}

test_constants_cwe_patterns_001() {
    echo "  Testing CWE patterns are defined"
    assert_success "[[ -n '$CWE_798_PATTERN' ]]" "CWE_798_PATTERN is defined"
}

test_constants_cwe_patterns_002() {
    assert_neq "" "$CWE_89_PATTERN" "CWE_89_PATTERN is defined"
}

test_constants_cwe_patterns_003() {
    assert_success "[[ -n '$CWE_78_PATTERN' ]]" "CWE_78_PATTERN is defined"
}

test_constants_timeouts_001() {
    echo "  Testing timeout constants"
    assert_eq "180" "$FAST_TIMEOUT" "FAST_TIMEOUT is 180"
}

test_constants_timeouts_002() {
    assert_eq "600" "$FULL_TIMEOUT" "FULL_TIMEOUT is 600"
}

run_test_constants_tests() {
    echo ""
    echo "=== Constants Module Tests ==="
    test_constants_tier_gold_001
    test_constants_tier_gold_002
    test_constants_tier_gold_003
    test_constants_tier_silver_001
    test_constants_tier_silver_002
    test_constants_tier_silver_003
    test_constants_tier_bronze_001
    test_constants_tier_bronze_002
    test_constants_tier_bronze_003
    test_constants_tier_none_001
    test_constants_tier_none_002
    test_constants_tier_platinum_001
    test_constants_tier_platinum_002
    test_constants_thresholds_001
    test_constants_thresholds_002
    test_constants_thresholds_003
    test_constants_f1_threshold_001
    test_constants_f1_threshold_002
    test_constants_cwe_patterns_001
    test_constants_cwe_patterns_002
    test_constants_cwe_patterns_003
    test_constants_timeouts_001
    test_constants_timeouts_002
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_test_constants_tests
    echo ""
    echo "Results: $TEST_PASSED/$TEST_COUNT passed"
    [[ $TEST_FAILED -gt 0 ]] && exit 1 || exit 0
fi
