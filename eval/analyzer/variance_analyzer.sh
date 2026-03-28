#!/usr/bin/env bash
# variance_analyzer.sh - Calculate variance between Text Score and Runtime Score
# Variance = |Text Score - Runtime Score|
# Using 1000pts system: variance = |text_score - runtime_score|
# Returns: VARIANCE_SCORE
# If variance < 20: PASS
# If variance 20-30: WARNING
# If variance > 30: FAIL

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/constants.sh"

analyze_variance() {
    local text_score="$1"
    local runtime_score="$2"
    
    if [[ -z "$text_score" ]] || [[ -z "$runtime_score" ]]; then
        echo "Error: text_score and runtime_score are required" >&2
        return 1
    fi
    
    if ! [[ "$text_score" =~ ^-?[0-9]+\.?[0-9]*$ ]] || ! [[ "$runtime_score" =~ ^-?[0-9]+\.?[0-9]*$ ]]; then
        echo "Error: Scores must be numeric" >&2
        return 1
    fi
    
    local variance
    variance=$(echo "scale=2; if ($text_score > $runtime_score) $text_score - $runtime_score else $runtime_score - $text_score" | bc)
    
    local status
    local status_code
    local lt_20=$(echo "$variance < 20" | bc -l)
    local lt_30=$(echo "$variance < 30" | bc -l)
    
    if [[ "$lt_20" -eq 1 ]]; then
        status="PASS"
        status_code=0
    elif [[ "$lt_30" -eq 1 ]]; then
        status="WARNING"
        status_code=1
    else
        status="FAIL"
        status_code=2
    fi
    
    echo "VARIANCE_SCORE=$variance"
    echo "VARIANCE_STATUS=$status"
    
    return $status_code
}

analyze_variance_from_scores() {
    local json_scores="$1"
    
    local text_score
    text_score=$(echo "$json_scores" | jq -r '.text_score // .text // 0')
    local runtime_score
    runtime_score=$(echo "$json_scores" | jq -r '.runtime_score // .runtime // 0')
    
    analyze_variance "$text_score" "$runtime_score"
}

get_variance_points() {
    local variance="$1"
    
    if [[ -z "$variance" ]]; then
        echo "0"
        return 1
    fi
    
    local lt_10 lt_20 lt_30
    lt_10=$(echo "$variance < 10" | bc -l)
    lt_20=$(echo "$variance < 20" | bc -l)
    lt_30=$(echo "$variance < 30" | bc -l)
    
    if [[ "$lt_10" -eq 1 ]]; then
        echo "40"
    elif [[ "$lt_20" -eq 1 ]]; then
        echo "30"
    elif [[ "$lt_30" -eq 1 ]]; then
        echo "15"
    else
        echo "0"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -lt 2 ]]; then
        echo "Usage: $0 <text_score> <runtime_score>"
        echo "Example: $0 280 360"
        exit 1
    fi
    analyze_variance "$1" "$2"
fi
