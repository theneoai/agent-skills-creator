#!/usr/bin/env bash
# trigger_analyzer.sh - Calculate F1, MRR, and Trigger Accuracy from corpus test results
# Input: corpus JSON with test cases and results
# Output: F1_SCORE, MRR_SCORE, TRIGGER_ACCURACY

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/constants.sh"

analyze_triggers() {
    local corpus_file="$1"
    
    if [[ ! -f "$corpus_file" ]]; then
        echo "Error: Corpus file not found: $corpus_file" >&2
        return 1
    fi
    
    local total_queries
    total_queries=$(jq 'length' "$corpus_file" 2>/dev/null || echo "0")
    
    if [[ "$total_queries" -eq 0 ]]; then
        echo "F1_SCORE=0.0"
        echo "MRR_SCORE=0.0"
        echo "TRIGGER_ACCURACY=0.0"
        return 0
    fi
    
    local true_positives=0
    local false_positives=0
    local false_negatives=0
    local reciprocal_ranks_sum=0
    
    for i in $(seq 0 $((total_queries - 1))); do
        local query_result
        query_result=$(jq -r ".[$i]" "$corpus_file" 2>/dev/null)
        
        local expected_trigger
        expected_trigger=$(echo "$query_result" | jq -r '.expected_trigger // empty')
        local predicted_triggers
        predicted_triggers=$(echo "$query_result" | jq -r '.predicted_triggers // [] | join(",")')
        local rank
        rank=$(echo "$query_result" | jq -r '.rank // 0')
        
        if [[ -z "$expected_trigger" ]] || [[ "$expected_trigger" == "null" ]]; then
            reciprocal_ranks_sum=$(echo "$reciprocal_ranks_sum + 0" | bc -l)
            continue
        fi
        
        if echo "$predicted_triggers" | grep -q "$expected_trigger"; then
            true_positives=$((true_positives + 1))
            if [[ "$rank" -gt 0 ]]; then
                reciprocal_ranks_sum=$(echo "$reciprocal_ranks_sum + 1/$rank" | bc -l)
            fi
        else
            reciprocal_ranks_sum=$(echo "$reciprocal_ranks_sum + 0" | bc -l)
            if [[ -n "$predicted_triggers" ]] && [[ "$predicted_triggers" != "null" ]] && [[ "$predicted_triggers" != "" ]]; then
                false_positives=$((false_positives + 1))
            fi
            false_negatives=$((false_negatives + 1))
        fi
    done
    
    local precision recall f1_score
    if [[ $((true_positives + false_positives)) -gt 0 ]]; then
        precision=$(echo "scale=4; $true_positives / ($true_positives + $false_positives)" | bc)
    else
        precision="0.0"
    fi
    
    if [[ $((true_positives + false_negatives)) -gt 0 ]]; then
        recall=$(echo "scale=4; $true_positives / ($true_positives + $false_negatives)" | bc)
    else
        recall="0.0"
    fi
    
    if [[ $(echo "$precision + $recall > 0" | bc -l) -eq 1 ]]; then
        f1_score=$(echo "scale=4; 2 * $precision * $recall / ($precision + $recall)" | bc)
    else
        f1_score="0.0"
    fi
    
    local mrr_score
    if [[ "$total_queries" -gt 0 ]]; then
        mrr_score=$(echo "scale=4; $reciprocal_ranks_sum / $total_queries" | bc)
    else
        mrr_score="0.0"
    fi
    
    local trigger_accuracy
    if [[ "$total_queries" -gt 0 ]]; then
        trigger_accuracy=$(echo "scale=4; $true_positives / $total_queries" | bc)
    else
        trigger_accuracy="0.0"
    fi
    
    echo "F1_SCORE=$f1_score"
    echo "MRR_SCORE=$mrr_score"
    echo "TRIGGER_ACCURACY=$trigger_accuracy"

    echo ""
    echo "=== Threshold Checks ==="
    local f1_pass mrr_pass acc_pass
    f1_pass=$(echo "$f1_score >= $F1_THRESHOLD" | bc -l)
    mrr_pass=$(echo "$mrr_score >= $MRR_THRESHOLD" | bc -l)
    acc_pass=$(echo "$trigger_accuracy >= $TRIGGER_ACCURACY_THRESHOLD" | bc -l)

    if [[ "$f1_pass" -eq 1 ]]; then
        echo -e "${GREEN}✓${NC} F1 ($f1_score) >= $F1_THRESHOLD"
    else
        echo -e "${RED}✗${NC} F1 ($f1_score) < $F1_THRESHOLD"
    fi

    if [[ "$mrr_pass" -eq 1 ]]; then
        echo -e "${GREEN}✓${NC} MRR ($mrr_score) >= $MRR_THRESHOLD"
    else
        echo -e "${RED}✗${NC} MRR ($mrr_score) < $MRR_THRESHOLD"
    fi

    if [[ "$acc_pass" -eq 1 ]]; then
        echo -e "${GREEN}✓${NC} Trigger Accuracy ($trigger_accuracy) >= $TRIGGER_ACCURACY_THRESHOLD"
    else
        echo -e "${RED}✗${NC} Trigger Accuracy ($trigger_accuracy) < $TRIGGER_ACCURACY_THRESHOLD"
    fi

    return 0
}

analyze_triggers_from_json() {
    local json_data="$1"
    
    local total_queries
    total_queries=$(echo "$json_data" | jq 'length' 2>/dev/null || echo "0")
    
    if [[ "$total_queries" -eq 0 ]]; then
        echo "F1_SCORE=0.0"
        echo "MRR_SCORE=0.0"
        echo "TRIGGER_ACCURACY=0.0"
        return 0
    fi
    
    local true_positives=0
    local false_positives=0
    local false_negatives=0
    local reciprocal_ranks_sum=0
    
    for i in $(seq 0 $((total_queries - 1))); do
        local expected_trigger
        expected_trigger=$(echo "$json_data" | jq -r ".[$i].expected_trigger // empty")
        local predicted_triggers
        predicted_triggers=$(echo "$json_data" | jq -r ".[$i].predicted_triggers // [] | join(\",\")")
        local rank
        rank=$(echo "$json_data" | jq -r ".[$i].rank // 0")
        
        if [[ -z "$expected_trigger" ]] || [[ "$expected_trigger" == "null" ]]; then
            reciprocal_ranks_sum=$(echo "$reciprocal_ranks_sum + 0" | bc -l)
            continue
        fi
        
        if echo "$predicted_triggers" | grep -q "$expected_trigger"; then
            true_positives=$((true_positives + 1))
            if [[ "$rank" -gt 0 ]]; then
                reciprocal_ranks_sum=$(echo "$reciprocal_ranks_sum + 1/$rank" | bc -l)
            fi
        else
            reciprocal_ranks_sum=$(echo "$reciprocal_ranks_sum + 0" | bc -l)
            if [[ -n "$predicted_triggers" ]] && [[ "$predicted_triggers" != "null" ]] && [[ "$predicted_triggers" != "" ]]; then
                false_positives=$((false_positives + 1))
            fi
            false_negatives=$((false_negatives + 1))
        fi
    done
    
    local precision recall f1_score
    if [[ $((true_positives + false_positives)) -gt 0 ]]; then
        precision=$(echo "scale=4; $true_positives / ($true_positives + $false_positives)" | bc)
    else
        precision="0.0"
    fi
    
    if [[ $((true_positives + false_negatives)) -gt 0 ]]; then
        recall=$(echo "scale=4; $true_positives / ($true_positives + $false_negatives)" | bc)
    else
        recall="0.0"
    fi
    
    if [[ $(echo "$precision + $recall > 0" | bc -l) -eq 1 ]]; then
        f1_score=$(echo "scale=4; 2 * $precision * $recall / ($precision + $recall)" | bc)
    else
        f1_score="0.0"
    fi
    
    local mrr_score
    if [[ "$total_queries" -gt 0 ]]; then
        mrr_score=$(echo "scale=4; $reciprocal_ranks_sum / $total_queries" | bc)
    else
        mrr_score="0.0"
    fi
    
    local trigger_accuracy
    if [[ "$total_queries" -gt 0 ]]; then
        trigger_accuracy=$(echo "scale=4; $true_positives / $total_queries" | bc)
    else
        trigger_accuracy="0.0"
    fi
    
    echo "F1_SCORE=$f1_score"
    echo "MRR_SCORE=$mrr_score"
    echo "TRIGGER_ACCURACY=$trigger_accuracy"

    echo ""
    echo "=== Threshold Checks ==="
    local f1_pass mrr_pass acc_pass
    f1_pass=$(echo "$f1_score >= $F1_THRESHOLD" | bc -l)
    mrr_pass=$(echo "$mrr_score >= $MRR_THRESHOLD" | bc -l)
    acc_pass=$(echo "$trigger_accuracy >= $TRIGGER_ACCURACY_THRESHOLD" | bc -l)

    if [[ "$f1_pass" -eq 1 ]]; then
        echo -e "${GREEN}✓${NC} F1 ($f1_score) >= $F1_THRESHOLD"
    else
        echo -e "${RED}✗${NC} F1 ($f1_score) < $F1_THRESHOLD"
    fi

    if [[ "$mrr_pass" -eq 1 ]]; then
        echo -e "${GREEN}✓${NC} MRR ($mrr_score) >= $MRR_THRESHOLD"
    else
        echo -e "${RED}✗${NC} MRR ($mrr_score) < $MRR_THRESHOLD"
    fi

    if [[ "$acc_pass" -eq 1 ]]; then
        echo -e "${GREEN}✓${NC} Trigger Accuracy ($trigger_accuracy) >= $TRIGGER_ACCURACY_THRESHOLD"
    else
        echo -e "${RED}✗${NC} Trigger Accuracy ($trigger_accuracy) < $TRIGGER_ACCURACY_THRESHOLD"
    fi

    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -lt 1 ]]; then
        echo "Usage: $0 <corpus.json>"
        exit 1
    fi
    analyze_triggers "$1"
fi
