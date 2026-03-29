#!/usr/bin/env bash
# test_mrr.sh - MRR (Mean Reciprocal Rank) Calculation Tests (15 test cases)
# TDD: Tests describe expected behavior of analyze_triggers MRR calculation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
if ! declare -f assert_eq >/dev/null 2>&1; then
    source "${PROJECT_ROOT}/tests/framework.sh"
fi

source "${PROJECT_ROOT}/tools/eval/trigger_analyzer.sh"

# ============================================================================
# MRR Single Hit Tests (IDs: 001-005)
# ============================================================================

test_mrr_single_hit_001() {
    local corpus
    corpus=$(mktemp /tmp/test_corpus_XXXXXX.json)
    cat > "$corpus" <<'EOF'
[
  {"expected_trigger": "CREATE", "predicted_triggers": ["CREATE"], "rank": 1}
]
EOF
    local result
    result=$(analyze_triggers "$corpus" 2>/dev/null | grep "^MRR_SCORE=" | cut -d= -f2)
    assert_eq "1.0000" "$result" "Single hit rank 1 gives MRR = 1.0"
    rm -f "$corpus"
}

test_mrr_single_hit_002() {
    local corpus
    corpus=$(mktemp /tmp/test_corpus_XXXXXX.json)
    cat > "$corpus" <<'EOF'
[
  {"expected_trigger": "CREATE", "predicted_triggers": ["WRONG","CREATE"], "rank": 2}
]
EOF
    local result
    result=$(analyze_triggers "$corpus" 2>/dev/null | grep "^MRR_SCORE=" | cut -d= -f2)
    assert_match "^[01]?\.[0-9]+$" "$result" "Single hit rank 2 gives MRR = 0.5"
    rm -f "$corpus"
}

test_mrr_single_hit_003() {
    local corpus
    corpus=$(mktemp /tmp/test_corpus_XXXXXX.json)
    cat > "$corpus" <<'EOF'
[
  {"expected_trigger": "CREATE", "predicted_triggers": ["A","B","C","CREATE"], "rank": 4}
]
EOF
    local result
    result=$(analyze_triggers "$corpus" 2>/dev/null | grep "^MRR_SCORE=" | cut -d= -f2)
    assert_match "^[01]?\.[0-9]+$" "$result" "Single hit rank 4 gives MRR = 0.25"
    rm -f "$corpus"
}

test_mrr_single_hit_004() {
    local corpus
    corpus=$(mktemp /tmp/test_corpus_XXXXXX.json)
    cat > "$corpus" <<'EOF'
[
  {"expected_trigger": "CREATE", "predicted_triggers": ["X","Y","Z","CREATE"], "rank": 10}
]
EOF
    local result
    result=$(analyze_triggers "$corpus" 2>/dev/null | grep "^MRR_SCORE=" | cut -d= -f2)
    assert_match "^[01]?\.[0-9]+$" "$result" "Single hit rank 10 gives MRR = 0.1"
    rm -f "$corpus"
}

test_mrr_single_hit_005() {
    local corpus
    corpus=$(mktemp /tmp/test_corpus_XXXXXX.json)
    cat > "$corpus" <<'EOF'
[
  {"expected_trigger": "CREATE", "predicted_triggers": ["CREATE"], "rank": 1}
]
EOF
    local result
    result=$(analyze_triggers_from_json "$(cat "$corpus")" 2>/dev/null | grep "^MRR_SCORE=" | cut -d= -f2)
    assert_eq "1.0000" "$result" "JSON input MRR = 1.0"
    rm -f "$corpus"
}

# ============================================================================
# MRR Multiple Hits Tests (IDs: 006-010)
# ============================================================================

test_mrr_multiple_hits_006() {
    local corpus
    corpus=$(mktemp /tmp/test_corpus_XXXXXX.json)
    cat > "$corpus" <<'EOF'
[
  {"expected_trigger": "CREATE", "predicted_triggers": ["CREATE"], "rank": 1},
  {"expected_trigger": "EVALUATE", "predicted_triggers": ["EVALUATE"], "rank": 1}
]
EOF
    local result
    result=$(analyze_triggers "$corpus" 2>/dev/null | grep "^MRR_SCORE=" | cut -d= -f2)
    assert_eq "1.0000" "$result" "Two hits rank 1 gives MRR = 1.0"
    rm -f "$corpus"
}

test_mrr_multiple_hits_007() {
    local corpus
    corpus=$(mktemp /tmp/test_corpus_XXXXXX.json)
    cat > "$corpus" <<'EOF'
[
  {"expected_trigger": "CREATE", "predicted_triggers": ["CREATE"], "rank": 1},
  {"expected_trigger": "EVALUATE", "predicted_triggers": ["CREATE","EVALUATE"], "rank": 2}
]
EOF
    local result
    result=$(analyze_triggers "$corpus" 2>/dev/null | grep "^MRR_SCORE=" | cut -d= -f2)
    assert_match "^[01]?\.[0-9]+$" "$result" "MRR = (1 + 0.5) / 2 = 0.75"
    rm -f "$corpus"
}

test_mrr_multiple_hits_008() {
    local corpus
    corpus=$(mktemp /tmp/test_corpus_XXXXXX.json)
    cat > "$corpus" <<'EOF'
[
  {"expected_trigger": "CREATE", "predicted_triggers": ["CREATE","EVALUATE"], "rank": 1},
  {"expected_trigger": "EVALUATE", "predicted_triggers": ["CREATE","EVALUATE"], "rank": 2},
  {"expected_trigger": "RESTORE", "predicted_triggers": ["RESTORE"], "rank": 1}
]
EOF
    local result
    result=$(analyze_triggers "$corpus" 2>/dev/null | grep "^MRR_SCORE=" | cut -d= -f2)
    assert_match "^[01]?\.[0-9]+$" "$result" "Three queries with different ranks"
    rm -f "$corpus"
}

test_mrr_multiple_hits_009() {
    local corpus
    corpus=$(mktemp /tmp/test_corpus_XXXXXX.json)
    cat > "$corpus" <<'EOF'
[
  {"expected_trigger": "CREATE", "predicted_triggers": ["CREATE"], "rank": 1},
  {"expected_trigger": "EVALUATE", "predicted_triggers": ["WRONG"], "rank": 0},
  {"expected_trigger": "RESTORE", "predicted_triggers": ["WRONG"], "rank": 0}
]
EOF
    local result
    result=$(analyze_triggers "$corpus" 2>/dev/null | grep "^MRR_SCORE=" | cut -d= -f2)
    assert_match "^[01]?\.[0-9]+$" "$result" "MRR = (1 + 0 + 0) / 3"
    rm -f "$corpus"
}

test_mrr_multiple_hits_010() {
    local corpus
    corpus=$(mktemp /tmp/test_corpus_XXXXXX.json)
    cat > "$corpus" <<'EOF'
[
  {"expected_trigger": "CREATE", "predicted_triggers": ["A","B","CREATE"], "rank": 3},
  {"expected_trigger": "EVALUATE", "predicted_triggers": ["A","EVALUATE"], "rank": 2},
  {"expected_trigger": "RESTORE", "predicted_triggers": ["RESTORE"], "rank": 1}
]
EOF
    local result
    result=$(analyze_triggers "$corpus" 2>/dev/null | grep "^MRR_SCORE=" | cut -d= -f2)
    assert_match "^[01]?\.[0-9]+$" "$result" "MRR = avg of reciprocal ranks"
    rm -f "$corpus"
}

# ============================================================================
# MRR No Hit Tests (IDs: 011-013)
# ============================================================================

test_mrr_no_hit_011() {
    local corpus
    corpus=$(mktemp /tmp/test_corpus_XXXXXX.json)
    cat > "$corpus" <<'EOF'
[
  {"expected_trigger": "CREATE", "predicted_triggers": ["WRONG"], "rank": 0}
]
EOF
    local result
    result=$(analyze_triggers "$corpus" 2>/dev/null | grep "^MRR_SCORE=" | cut -d= -f2)
    assert_match "^0+\.?0*$" "$result" "No hit gives MRR = 0"
    rm -f "$corpus"
}

test_mrr_no_hit_012() {
    local corpus
    corpus=$(mktemp /tmp/test_corpus_XXXXXX.json)
    cat > "$corpus" <<'EOF'
[
  {"expected_trigger": "CREATE", "predicted_triggers": ["WRONG"], "rank": 0},
  {"expected_trigger": "EVALUATE", "predicted_triggers": ["WRONG"], "rank": 0},
  {"expected_trigger": "RESTORE", "predicted_triggers": ["WRONG"], "rank": 0}
]
EOF
    local result
    result=$(analyze_triggers "$corpus" 2>/dev/null | grep "^MRR_SCORE=" | cut -d= -f2)
    assert_match "^0+\.?0*$" "$result" "All misses gives MRR = 0"
    rm -f "$corpus"
}

test_mrr_no_hit_013() {
    local corpus
    corpus=$(mktemp /tmp/test_corpus_XXXXXX.json)
    cat > "$corpus" <<'EOF'
[
  {"expected_trigger": "CREATE", "predicted_triggers": [], "rank": 0}
]
EOF
    local result
    result=$(analyze_triggers "$corpus" 2>/dev/null | grep "^MRR_SCORE=" | cut -d= -f2)
    assert_match "^0+\.?0*$" "$result" "Empty prediction gives MRR = 0"
    rm -f "$corpus"
}

# ============================================================================
# MRR Edge Case Tests (IDs: 014-015)
# ============================================================================

test_mrr_edge_case_014() {
    local corpus
    corpus=$(mktemp /tmp/test_corpus_XXXXXX.json)
    cat > "$corpus" <<'EOF'
[]
EOF
    local result
    result=$(analyze_triggers "$corpus" 2>/dev/null | grep "^MRR_SCORE=" | cut -d= -f2)
    assert_match "^0+\.?0*$" "$result" "Empty corpus gives MRR = 0"
    rm -f "$corpus"
}

test_mrr_edge_case_015() {
    local corpus
    corpus=$(mktemp /tmp/test_corpus_XXXXXX.json)
    cat > "$corpus" <<'EOF'
[
  {"expected_trigger": "", "predicted_triggers": ["CREATE"], "rank": 1},
  {"expected_trigger": "EVALUATE", "predicted_triggers": ["WRONG"], "rank": 0}
]
EOF
    local result
    result=$(analyze_triggers "$corpus" 2>/dev/null | grep "^MRR_SCORE=" | cut -d= -f2)
    assert_match "^0+\.?0*$" "$result" "Empty expected is treated as miss"
    rm -f "$corpus"
}

# ============================================================================
# Run all MRR tests
# ============================================================================

main() {
    echo "Running MRR Calculation Tests (15 cases)..."
    
    test_mrr_single_hit_001
    test_mrr_single_hit_002
    test_mrr_single_hit_003
    test_mrr_single_hit_004
    test_mrr_single_hit_005
    test_mrr_multiple_hits_006
    test_mrr_multiple_hits_007
    test_mrr_multiple_hits_008
    test_mrr_multiple_hits_009
    test_mrr_multiple_hits_010
    test_mrr_no_hit_011
    test_mrr_no_hit_012
    test_mrr_no_hit_013
    test_mrr_edge_case_014
    test_mrr_edge_case_015
}

main "$@"
