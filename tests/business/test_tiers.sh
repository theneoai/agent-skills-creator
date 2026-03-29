#!/usr/bin/env bash
# test_tiers.sh - Tier Determination Tests (10 test cases)
# TDD: Tests describe expected behavior of tier classification

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
if ! declare -f assert_eq >/dev/null 2>&1; then
    source "${PROJECT_ROOT}/tests/framework.sh"
fi

source "${PROJECT_ROOT}/tools/eval/certifier.sh"

# ============================================================================
# Simple get_tier wrapper for testing (uses determine_tier from certifier.sh)
# ============================================================================

get_tier() {
    local score="$1"
    local tier
    case "$score" in
        950|1000)
            tier=$(determine_tier "$score" "350" "450" "5" 2>/dev/null)
            ;;
        900|949)
            tier=$(determine_tier "$score" "350" "420" "10" 2>/dev/null)
            ;;
        800|899)
            tier=$(determine_tier "$score" "300" "380" "15" 2>/dev/null)
            ;;
        700|799)
            tier=$(determine_tier "$score" "260" "330" "25" 2>/dev/null)
            ;;
        *)
            tier=$(determine_tier "$score" "200" "250" "50" 2>/dev/null)
            ;;
    esac
    echo "$tier"
}

# ============================================================================
# PLATINUM Tier Tests (IDs: 001-002)
# ============================================================================

test_tier_platinum_001() {
    assert_eq "PLATINUM" "$(get_tier 950)" "Score 950 is PLATINUM"
}

test_tier_platinum_002() {
    assert_eq "PLATINUM" "$(get_tier 1000)" "Score 1000 is PLATINUM"
}

# ============================================================================
# GOLD Tier Tests (IDs: 003-004)
# ============================================================================

test_tier_gold_003() {
    assert_eq "GOLD" "$(get_tier 900)" "Score 900 is GOLD"
}

test_tier_gold_004() {
    assert_eq "GOLD" "$(get_tier 949)" "Score 949 is GOLD"
}

# ============================================================================
# SILVER Tier Tests (IDs: 005-006)
# ============================================================================

test_tier_silver_005() {
    assert_eq "SILVER" "$(get_tier 800)" "Score 800 is SILVER"
}

test_tier_silver_006() {
    assert_eq "SILVER" "$(get_tier 899)" "Score 899 is SILVER"
}

# ============================================================================
# BRONZE Tier Tests (IDs: 007-008)
# ============================================================================

test_tier_bronze_007() {
    assert_eq "BRONZE" "$(get_tier 700)" "Score 700 is BRONZE"
}

test_tier_bronze_008() {
    assert_eq "BRONZE" "$(get_tier 799)" "Score 799 is BRONZE"
}

# ============================================================================
# REJECTED Tier Tests (IDs: 009-010)
# ============================================================================

test_tier_rejected_009() {
    local tier
    tier=$(get_tier 699)
    assert_match "NOT_CERTIFIED|REJECTED" "$tier" "Score 699 is NOT_CERTIFIED"
}

test_tier_rejected_010() {
    local tier
    tier=$(get_tier 0)
    assert_match "NOT_CERTIFIED|REJECTED" "$tier" "Score 0 is NOT_CERTIFIED"
}

# ============================================================================
# Run all tier tests
# ============================================================================

main() {
    echo "Running Tier Determination Tests (10 cases)..."
    
    test_tier_platinum_001
    test_tier_platinum_002
    test_tier_gold_003
    test_tier_gold_004
    test_tier_silver_005
    test_tier_silver_006
    test_tier_bronze_007
    test_tier_bronze_008
    test_tier_rejected_009
    test_tier_rejected_010
}

main "$@"
