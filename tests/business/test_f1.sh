#!/usr/bin/env bash
# test_f1.sh - F1 Score Calculation Tests (25 test cases)
# TDD: Tests describe expected behavior of analyze_triggers function

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
if ! declare -f assert_eq >/dev/null 2>&1; then
    source "${PROJECT_ROOT}/tests/framework.sh"
fi

source "${PROJECT_ROOT}/tools/eval/trigger_analyzer.sh"

# ============================================================================
# F1 Perfect Hit Tests (IDs: 001-005)
# ============================================================================

test_f1_perfect_hit_001() {
    local corpus
    corpus=$(mktemp /tmp/test_corpus_XXXXXX.json)
    cat > "$corpus" <<'EOF'
[
  {"expected_trigger": "CREATE", "predicted_triggers": ["CREATE"], "rank": 1},
  {"expected_trigger": "EVALUATE", "predicted_triggers": ["EVALUATE"], "rank": 1},
  {"expected_trigger": "RESTORE", "predicted_triggers": ["RESTORE"], "rank": 1}
]
EOF
    local result
    result=$(analyze_triggers "$corpus" 2>/dev/null | grep "^F1_SCORE=" | cut -d= -f2)
    assert_match "^[01]\.?0*$" "$result" "Perfect F1 = 1.0 (all hits)"
    rm -f "$corpus"
}

test_f1_perfect_hit_002() {
    local corpus
    corpus=$(mktemp /tmp/test_corpus_XXXXXX.json)
    cat > "$corpus" <<'EOF'
[
  {"expected_trigger": "CREATE", "predicted_triggers": ["CREATE"], "rank": 1},
  {"expected_trigger": "CREATE", "predicted_triggers": ["CREATE"], "rank": 1}
]
EOF
    local result
    result=$(analyze_triggers "$corpus" 2>/dev/null | grep "^F1_SCORE=" | cut -d= -f2)
    assert_match "^1\.0*$" "$result" "Perfect F1 = 1.0 (double CREATE)"
    rm -f "$corpus"
}

test_f1_perfect_hit_003() {
    local corpus
    corpus=$(mktemp /tmp/test_corpus_XXXXXX.json)
    cat > "$corpus" <<'EOF'
[
  {"expected_trigger": "SECURITY", "predicted_triggers": ["SECURITY"], "rank": 1}
]
EOF
    local result
    result=$(analyze_triggers "$corpus" 2>/dev/null | grep "^F1_SCORE=" | cut -d= -f2)
    assert_eq "1.0000" "$result" "Perfect F1 = 1.0 (SECURITY trigger)"
    rm -f "$corpus"
}

test_f1_perfect_hit_004() {
    local corpus
    corpus=$(mktemp /tmp/test_corpus_XXXXXX.json)
    cat > "$corpus" <<'EOF'
[
  {"expected_trigger": "OPTIMIZE", "predicted_triggers": ["OPTIMIZE"], "rank": 1}
]
EOF
    local result
    result=$(analyze_triggers "$corpus" 2>/dev/null | grep "^F1_SCORE=" | cut -d= -f2)
    assert_eq "1.0000" "$result" "Perfect F1 = 1.0 (OPTIMIZE trigger)"
    rm -f "$corpus"
}

test_f1_perfect_hit_005() {
    local corpus
    corpus=$(mktemp /tmp/test_corpus_XXXXXX.json)
    cat > "$corpus" <<'EOF'
[
  {"expected_trigger": "CREATE", "predicted_triggers": ["CREATE","EVALUATE","RESTORE"], "rank": 1}
]
EOF
    local result
    result=$(analyze_triggers "$corpus" 2>/dev/null | grep "^F1_SCORE=" | cut -d= -f2)
    assert_eq "1.0000" "$result" "Perfect F1 when expected in predicted list"
    rm -f "$corpus"
}

# ============================================================================
# F1 Partial Hit Tests (IDs: 006-010)
# ============================================================================

test_f1_partial_hit_006() {
    local corpus
    corpus=$(mktemp /tmp/test_corpus_XXXXXX.json)
    cat > "$corpus" <<'EOF'
[
  {"expected_trigger": "CREATE", "predicted_triggers": ["CREATE","EVALUATE"], "rank": 1},
  {"expected_trigger": "EVALUATE", "predicted_triggers": ["CREATE","EVALUATE"], "rank": 2},
  {"expected_trigger": "RESTORE", "predicted_triggers": ["CREATE"], "rank": 0}
]
EOF
    local result
    result=$(analyze_triggers "$corpus" 2>/dev/null | grep "^F1_SCORE=" | cut -d= -f2)
    assert_match "^[01]?\.[0-9]+$" "$result" "Partial F1 < 1.0"
    rm -f "$corpus"
}

test_f1_partial_hit_007() {
    local corpus
    corpus=$(mktemp /tmp/test_corpus_XXXXXX.json)
    cat > "$corpus" <<'EOF'
[
  {"expected_trigger": "CREATE", "predicted_triggers": ["CREATE"], "rank": 1},
  {"expected_trigger": "EVALUATE", "predicted_triggers": ["WRONG"], "rank": 0}
]
EOF
    local result
    result=$(analyze_triggers "$corpus" 2>/dev/null | grep "^F1_SCORE=" | cut -d= -f2)
    assert_match "^[01]?\.[0-9]+$" "$result" "50% hit rate F1 ≈ 0.67"
    rm -f "$corpus"
}

test_f1_partial_hit_008() {
    local corpus
    corpus=$(mktemp /tmp/test_corpus_XXXXXX.json)
    cat > "$corpus" <<'EOF'
[
  {"expected_trigger": "CREATE", "predicted_triggers": ["EVALUATE"], "rank": 0},
  {"expected_trigger": "EVALUATE", "predicted_triggers": ["RESTORE"], "rank": 0}
]
EOF
    local result
    result=$(analyze_triggers "$corpus" 2>/dev/null | grep "^F1_SCORE=" | cut -d= -f2)
    assert_match "^0+\.?0*$" "$result" "0% hit rate F1 = 0"
    rm -f "$corpus"
}

test_f1_partial_hit_009() {
    local corpus
    corpus=$(mktemp /tmp/test_corpus_XXXXXX.json)
    cat > "$corpus" <<'EOF'
[
  {"expected_trigger": "CREATE", "predicted_triggers": ["CREATE"], "rank": 1},
  {"expected_trigger": "EVALUATE", "predicted_triggers": ["CREATE"], "rank": 0},
  {"expected_trigger": "RESTORE", "predicted_triggers": ["CREATE"], "rank": 0}
]
EOF
    local result
    result=$(analyze_triggers "$corpus" 2>/dev/null | grep "^F1_SCORE=" | cut -d= -f2)
    assert_match "^[01]?\.[0-9]+$" "$result" "1/3 hit rate"
    rm -f "$corpus"
}

test_f1_partial_hit_010() {
    local corpus
    corpus=$(mktemp /tmp/test_corpus_XXXXXX.json)
    cat > "$corpus" <<'EOF'
[
  {"expected_trigger": "CREATE", "predicted_triggers": ["CREATE"], "rank": 1},
  {"expected_trigger": "CREATE", "predicted_triggers": ["CREATE"], "rank": 1},
  {"expected_trigger": "CREATE", "predicted_triggers": ["WRONG"], "rank": 0},
  {"expected_trigger": "CREATE", "predicted_triggers": ["WRONG"], "rank": 0}
]
EOF
    local result
    result=$(analyze_triggers "$corpus" 2>/dev/null | grep "^F1_SCORE=" | cut -d= -f2)
    assert_match "^[01]?\.[0-9]+$" "$result" "50% hit rate with duplicates"
    rm -f "$corpus"
}

# ============================================================================
# F1 No Hit Tests (IDs: 011-015)
# ============================================================================

test_f1_no_hit_011() {
    local corpus
    corpus=$(mktemp /tmp/test_corpus_XXXXXX.json)
    cat > "$corpus" <<'EOF'
[
  {"expected_trigger": "CREATE", "predicted_triggers": ["WRONG"], "rank": 0}
]
EOF
    local result
    result=$(analyze_triggers "$corpus" 2>/dev/null | grep "^F1_SCORE=" | cut -d= -f2)
    assert_match "^0+\.?0*$" "$result" "No hit F1 = 0"
    rm -f "$corpus"
}

test_f1_no_hit_012() {
    local corpus
    corpus=$(mktemp /tmp/test_corpus_XXXXXX.json)
    cat > "$corpus" <<'EOF'
[
  {"expected_trigger": "CREATE", "predicted_triggers": ["EVALUATE"], "rank": 0},
  {"expected_trigger": "EVALUATE", "predicted_triggers": ["RESTORE"], "rank": 0},
  {"expected_trigger": "RESTORE", "predicted_triggers": ["CREATE"], "rank": 0}
]
EOF
    local result
    result=$(analyze_triggers "$corpus" 2>/dev/null | grep "^F1_SCORE=" | cut -d= -f2)
    assert_match "^0+\.?0*$" "$result" "Complete miss all wrong"
    rm -f "$corpus"
}

test_f1_no_hit_013() {
    local corpus
    corpus=$(mktemp /tmp/test_corpus_XXXXXX.json)
    cat > "$corpus" <<'EOF'
[
  {"expected_trigger": "SECURITY", "predicted_triggers": ["OPTIMIZE"], "rank": 0}
]
EOF
    local result
    result=$(analyze_triggers "$corpus" 2>/dev/null | grep "^F1_SCORE=" | cut -d= -f2)
    assert_match "^0+\.?0*$" "$result" "Security vs Optimize no match"
    rm -f "$corpus"
}

test_f1_no_hit_014() {
    local corpus
    corpus=$(mktemp /tmp/test_corpus_XXXXXX.json)
    cat > "$corpus" <<'EOF'
[
  {"expected_trigger": "CREATE", "predicted_triggers": [], "rank": 0}
]
EOF
    local result
    result=$(analyze_triggers "$corpus" 2>/dev/null | grep "^F1_SCORE=" | cut -d= -f2)
    assert_match "^0+\.?0*$" "$result" "Empty predicted triggers"
    rm -f "$corpus"
}

test_f1_no_hit_015() {
    local corpus
    corpus=$(mktemp /tmp/test_corpus_XXXXXX.json)
    cat > "$corpus" <<'EOF'
[
  {"expected_trigger": "CREATE", "predicted_triggers": null, "rank": 0}
]
EOF
    local result
    result=$(analyze_triggers "$corpus" 2>/dev/null | grep "^F1_SCORE=" | cut -d= -f2)
    assert_match "^0+\.?0*$" "$result" "null predicted triggers"
    rm -f "$corpus"
}

# ============================================================================
# F1 Edge Case Tests (IDs: 016-020)
# ============================================================================

test_f1_edge_case_016() {
    local corpus
    corpus=$(mktemp /tmp/test_corpus_XXXXXX.json)
    cat > "$corpus" <<'EOF'
[]
EOF
    local result
    result=$(analyze_triggers "$corpus" 2>/dev/null | grep "^F1_SCORE=" | cut -d= -f2)
    assert_match "^0+\.?0*$" "$result" "Empty corpus F1 = 0"
    rm -f "$corpus"
}

test_f1_edge_case_017() {
    local corpus
    corpus=$(mktemp /tmp/test_corpus_XXXXXX.json)
    cat > "$corpus" <<'EOF'
[
  {"expected_trigger": "", "predicted_triggers": ["CREATE"], "rank": 1}
]
EOF
    local result
    result=$(analyze_triggers "$corpus" 2>/dev/null | grep "^F1_SCORE=" | cut -d= -f2)
    assert_match "^0+\.?0*$" "$result" "Empty expected trigger"
    rm -f "$corpus"
}

test_f1_edge_case_018() {
    local corpus
    corpus=$(mktemp /tmp/test_corpus_XXXXXX.json)
    cat > "$corpus" <<'EOF'
[
  {"expected_trigger": null, "predicted_triggers": ["CREATE"], "rank": 1}
]
EOF
    local result
    result=$(analyze_triggers "$corpus" 2>/dev/null | grep "^F1_SCORE=" | cut -d= -f2)
    assert_match "^0+\.?0*$" "$result" "null expected trigger"
    rm -f "$corpus"
}

test_f1_edge_case_019() {
    local corpus
    corpus=$(mktemp /tmp/test_corpus_XXXXXX.json)
    cat > "$corpus" <<'EOF'
[
  {"expected_trigger": "CREATE", "predicted_triggers": ["CREATE"], "rank": 1},
  {"expected_trigger": "CREATE", "predicted_triggers": ["CREATE"], "rank": 1},
  {"expected_trigger": "CREATE", "predicted_triggers": ["CREATE"], "rank": 1},
  {"expected_trigger": "CREATE", "predicted_triggers": ["CREATE"], "rank": 1},
  {"expected_trigger": "CREATE", "predicted_triggers": ["CREATE"], "rank": 1}
]
EOF
    local result
    result=$(analyze_triggers "$corpus" 2>/dev/null | grep "^F1_SCORE=" | cut -d= -f2)
    assert_eq "1.0000" "$result" "Five identical perfect hits"
    rm -f "$corpus"
}

test_f1_edge_case_020() {
    local corpus
    corpus=$(mktemp /tmp/test_corpus_XXXXXX.json)
    cat > "$corpus" <<'EOF'
[
  {"expected_trigger": "CREATE", "predicted_triggers": ["CREATE"], "rank": 1},
  {"expected_trigger": "CREATE", "predicted_triggers": ["CREATE"], "rank": 2},
  {"expected_trigger": "CREATE", "predicted_triggers": ["CREATE"], "rank": 3},
  {"expected_trigger": "CREATE", "predicted_triggers": ["CREATE"], "rank": 4},
  {"expected_trigger": "CREATE", "predicted_triggers": ["CREATE"], "rank": 5}
]
EOF
    local result
    result=$(analyze_triggers "$corpus" 2>/dev/null | grep "^F1_SCORE=" | cut -d= -f2)
    assert_eq "1.0000" "$result" "CREATE found in all predictions"
    rm -f "$corpus"
}

# ============================================================================
# F1 Multi-LLM Validation Tests (IDs: 021-025)
# ============================================================================

test_f1_cross_validate_021() {
    local corpus
    corpus=$(mktemp /tmp/test_corpus_XXXXXX.json)
    cat > "$corpus" <<'EOF'
[
  {"expected_trigger": "CREATE", "predicted_triggers": ["CREATE","EVALUATE"], "rank": 1},
  {"expected_trigger": "EVALUATE", "predicted_triggers": ["CREATE","EVALUATE"], "rank": 2}
]
EOF
    local result1 result2
    result1=$(analyze_triggers "$corpus" 2>/dev/null | grep "^F1_SCORE=" | cut -d= -f2)
    result2=$(analyze_triggers_from_json "$(cat "$corpus")" 2>/dev/null | grep "^F1_SCORE=" | cut -d= -f2)
    assert_eq "$result1" "$result2" "F1 file and JSON input consistent"
    rm -f "$corpus"
}

test_f1_cross_validate_022() {
    local corpus
    corpus=$(mktemp /tmp/test_corpus_XXXXXX.json)
    cat > "$corpus" <<'EOF'
[
  {"expected_trigger": "CREATE", "predicted_triggers": ["CREATE"], "rank": 1},
  {"expected_trigger": "EVALUATE", "predicted_triggers": ["EVALUATE"], "rank": 1}
]
EOF
    local result1 result2
    result1=$(analyze_triggers "$corpus" 2>/dev/null | grep "^F1_SCORE=" | cut -d= -f2)
    result2=$(analyze_triggers_from_json "$(cat "$corpus")" 2>/dev/null | grep "^F1_SCORE=" | cut -d= -f2)
    assert_eq "1.0000" "$result1" "Perfect F1 from file"
    assert_eq "1.0000" "$result2" "Perfect F1 from JSON"
    rm -f "$corpus"
}

test_f1_cross_validate_023() {
    local corpus
    corpus=$(mktemp /tmp/test_corpus_XXXXXX.json)
    cat > "$corpus" <<'EOF'
[
  {"expected_trigger": "RESTORE", "predicted_triggers": ["WRONG"], "rank": 0}
]
EOF
    local result1 result2
    result1=$(analyze_triggers "$corpus" 2>/dev/null | grep "^F1_SCORE=" | cut -d= -f2)
    result2=$(analyze_triggers_from_json "$(cat "$corpus")" 2>/dev/null | grep "^F1_SCORE=" | cut -d= -f2)
    assert_eq "$result1" "$result2" "Zero F1 consistent across inputs"
    rm -f "$corpus"
}

test_f1_threshold_check_024() {
    local corpus
    corpus=$(mktemp /tmp/test_corpus_XXXXXX.json)
    cat > "$corpus" <<'EOF'
[
  {"expected_trigger": "CREATE", "predicted_triggers": ["CREATE"], "rank": 1},
  {"expected_trigger": "EVALUATE", "predicted_triggers": ["EVALUATE"], "rank": 1},
  {"expected_trigger": "RESTORE", "predicted_triggers": ["RESTORE"], "rank": 1},
  {"expected_trigger": "SECURITY", "predicted_triggers": ["SECURITY"], "rank": 1},
  {"expected_trigger": "OPTIMIZE", "predicted_triggers": ["OPTIMIZE"], "rank": 1},
  {"expected_trigger": "CREATE", "predicted_triggers": ["CREATE"], "rank": 1},
  {"expected_trigger": "EVALUATE", "predicted_triggers": ["EVALUATE"], "rank": 1},
  {"expected_trigger": "RESTORE", "predicted_triggers": ["RESTORE"], "rank": 1},
  {"expected_trigger": "SECURITY", "predicted_triggers": ["SECURITY"], "rank": 1},
  {"expected_trigger": "OPTIMIZE", "predicted_triggers": ["OPTIMIZE"], "rank": 1}
]
EOF
    local output
    output=$(analyze_triggers "$corpus" 2>/dev/null)
    local f1_score
    f1_score=$(echo "$output" | grep "^F1_SCORE=" | cut -d= -f2)
    assert_match "1\.0" "$f1_score" "Large perfect corpus F1 = 1.0"
    rm -f "$corpus"
}

test_f1_threshold_check_025() {
    local corpus
    corpus=$(mktemp /tmp/test_corpus_XXXXXX.json)
    cat > "$corpus" <<'EOF'
[
  {"expected_trigger": "CREATE", "predicted_triggers": ["CREATE"], "rank": 1},
  {"expected_trigger": "EVALUATE", "predicted_triggers": ["EVALUATE"], "rank": 1},
  {"expected_trigger": "RESTORE", "predicted_triggers": ["RESTORE"], "rank": 1},
  {"expected_trigger": "SECURITY", "predicted_triggers": ["SECURITY"], "rank": 1},
  {"expected_trigger": "OPTIMIZE", "predicted_triggers": ["OPTIMIZE"], "rank": 1}
]
EOF
    local output
    output=$(analyze_triggers "$corpus" 2>/dev/null)
    local f1_score
    f1_score=$(echo "$output" | grep "^F1_SCORE=" | cut -d= -f2)
    local f1_numeric
    f1_numeric=$(echo "$f1_score" | bc)
    local passes
    passes=$(echo "$f1_numeric >= 0.9" | bc)
    assert_eq "1" "$passes" "Mixed corpus passes F1 threshold 0.9"
    rm -f "$corpus"
}

# ============================================================================
# Run all F1 tests
# ============================================================================

main() {
    echo "Running F1 Calculation Tests (25 cases)..."
    
    test_f1_perfect_hit_001
    test_f1_perfect_hit_002
    test_f1_perfect_hit_003
    test_f1_perfect_hit_004
    test_f1_perfect_hit_005
    test_f1_partial_hit_006
    test_f1_partial_hit_007
    test_f1_partial_hit_008
    test_f1_partial_hit_009
    test_f1_partial_hit_010
    test_f1_no_hit_011
    test_f1_no_hit_012
    test_f1_no_hit_013
    test_f1_no_hit_014
    test_f1_no_hit_015
    test_f1_edge_case_016
    test_f1_edge_case_017
    test_f1_edge_case_018
    test_f1_edge_case_019
    test_f1_edge_case_020
    test_f1_cross_validate_021
    test_f1_cross_validate_022
    test_f1_cross_validate_023
    test_f1_threshold_check_024
    test_f1_threshold_check_025
}

main "$@"
