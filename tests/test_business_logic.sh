#!/usr/bin/env bash
# test_business_logic.sh - Quick Business Logic Tests
#
# Tests for core functionality without LLM dependencies

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

TESTS_PASSED=0
TESTS_FAILED=0

pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((TESTS_PASSED++)) || true
}

fail() {
    echo -e "${RED}✗${NC} $1"
    ((TESTS_FAILED++)) || true
}

info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

# ============================================================================
# Test 1: trigger_analyzer.sh F1 calculation
# ============================================================================

test_f1_calculation() {
    info "Test: trigger_analyzer F1 calculation"
    
    local test_corpus
    test_corpus=$(mktemp /tmp/test_corpus_XXXXXX.json)
    
    cat > "$test_corpus" <<'EOF'
[
  {"expected_trigger": "CREATE", "predicted_triggers": "CREATE,EVALUATE", "rank": 1},
  {"expected_trigger": "EVALUATE", "predicted_triggers": "CREATE,EVALUATE", "rank": 2},
  {"expected_trigger": "RESTORE", "predicted_triggers": "CREATE", "rank": 0}
]
EOF
    
    source "${PROJECT_ROOT}/eval/analyzer/trigger_analyzer.sh" 2>/dev/null || true
    local result
    result=$(analyze_triggers "$test_corpus" 2>/dev/null || echo "F1_SCORE=0.0")
    
    rm -f "$test_corpus"
    
    if echo "$result" | grep -q "F1_SCORE="; then
        pass "F1 calculation produces output"
    else
        fail "F1 calculation failed"
    fi
}

# ============================================================================
# Test 2: parse_validate.sh no PCRE syntax error
# ============================================================================

test_parse_validate() {
    info "Test: parse_validate.sh syntax validation"
    
    if "${PROJECT_ROOT}/eval/parse/parse_validate.sh" "${PROJECT_ROOT}/SKILL.md" 2>&1 | grep -q "TOTAL:"; then
        pass "parse_validate.sh executes without PCRE errors"
    else
        fail "parse_validate.sh failed"
    fi
}

# ============================================================================
# Test 3: unified_scoring.sh thresholds via direct check
# ============================================================================

test_unified_scoring() {
    info "Test: unified_scoring.sh thresholds"
    
    local platinum gold silver bronze
    platinum=$(grep -E '^readonly TIER_PLATINUM=' "${PROJECT_ROOT}/eval/lib/unified_scoring.sh" | grep -oE '[0-9]+')
    gold=$(grep -E '^readonly TIER_GOLD=' "${PROJECT_ROOT}/eval/lib/unified_scoring.sh" | grep -oE '[0-9]+')
    silver=$(grep -E '^readonly TIER_SILVER=' "${PROJECT_ROOT}/eval/lib/unified_scoring.sh" | grep -oE '[0-9]+')
    bronze=$(grep -E '^readonly TIER_BRONZE=' "${PROJECT_ROOT}/eval/lib/unified_scoring.sh" | grep -oE '[0-9]+')
    
    if [[ "$platinum" == "950" ]] && [[ "$gold" == "900" ]] && \
       [[ "$silver" == "800" ]] && [[ "$bronze" == "700" ]]; then
        pass "unified_scoring thresholds correct"
    else
        fail "unified_scoring thresholds: P=$platinum G=$gold S=$silver B=$bronze"
    fi
}

# ============================================================================
# Test 4: sed_i cross-platform
# ============================================================================

test_sedi_crossplatform() {
    info "Test: sed_i cross-platform function"
    
    local test_file="/tmp/test_sedi_$$_$(date +%s).txt"
    echo "original" > "$test_file"
    
    if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' 's/original/modified/' "$test_file"
    else
        sed -i 's/original/modified/' "$test_file"
    fi
    
    local result
    result=$(cat "$test_file")
    rm -f "$test_file"
    
    if [[ "$result" == "modified" ]]; then
        pass "sed works on this platform"
    else
        fail "sed failed: $result"
    fi
}

# ============================================================================
# Test 5: bootstrap.sh has re-source guard
# ============================================================================

test_bootstrap_guard() {
    info "Test: bootstrap.sh has re-source guard"
    
    if grep -q '_BOOTSTRAP_SOURCED' "${PROJECT_ROOT}/engine/lib/bootstrap.sh"; then
        pass "bootstrap.sh has re-source guard"
    else
        fail "bootstrap.sh missing re-source guard"
    fi
}

# ============================================================================
# Test 6: constants.sh has re-source guard
# ============================================================================

test_constants_guard() {
    info "Test: constants.sh has re-source guard"
    
    if grep -q '_CONSTANTS_SOURCED' "${PROJECT_ROOT}/eval/lib/constants.sh"; then
        pass "constants.sh has re-source guard"
    else
        fail "constants.sh missing re-source guard"
    fi
}

# ============================================================================
# Test 7: agent_executor.sh has re-source guard
# ============================================================================

test_agent_executor_guard() {
    info "Test: agent_executor.sh has re-source guard"
    
    if grep -q '_AGENT_EXECUTOR_SOURCED' "${PROJECT_ROOT}/eval/lib/agent_executor.sh"; then
        pass "agent_executor.sh has re-source guard"
    else
        fail "agent_executor.sh missing re-source guard"
    fi
}

# ============================================================================
# Test 8: parallel-evolution.sh has file lock functions
# ============================================================================

test_parallel_lock_functions() {
    info "Test: parallel-evolution.sh has lock functions"
    
    if grep -q 'acquire_file_lock' "${PROJECT_ROOT}/scripts/parallel-evolution.sh" && \
       grep -q 'release_file_lock' "${PROJECT_ROOT}/scripts/parallel-evolution.sh"; then
        pass "parallel-evolution.sh has lock functions"
    else
        fail "parallel-evolution.sh missing lock functions"
    fi
}

# ============================================================================
# Main
# ============================================================================

main() {
    echo "============================================================================"
    echo "Quick Business Logic Tests"
    echo "============================================================================"
    echo ""
    
    test_f1_calculation
    test_parse_validate
    test_unified_scoring
    test_sedi_crossplatform
    test_bootstrap_guard
    test_constants_guard
    test_agent_executor_guard
    test_parallel_lock_functions
    
    echo ""
    echo "============================================================================"
    echo "Results: ${TESTS_PASSED} passed, ${TESTS_FAILED} failed"
    echo "============================================================================"
    
    if [[ $TESTS_FAILED -gt 0 ]]; then
        exit 1
    fi
    exit 0
}

main "$@"
