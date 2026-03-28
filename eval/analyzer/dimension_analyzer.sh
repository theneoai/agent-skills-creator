#!/usr/bin/env bash
# dimension_analyzer.sh - Identify weakest dimensions for improvement recommendations
# Input: all dimension scores
# Output: sorted list of weakest dimensions with specific recommendations
# Returns: WEAKEST_DIMENSIONS array with format: "dimension_name:score:recommended_action"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/constants.sh"

declare -A DIMENSION_WEIGHTS=(
    ["system_prompt"]=20
    ["domain_knowledge"]=20
    ["workflow"]=20
    ["error_handling"]=15
    ["examples"]=15
    ["metadata"]=10
    ["identity_consistency"]=18
    ["framework_execution"]=16
    ["output_actionability"]=16
    ["knowledge_accuracy"]=11
    ["conversation_stability"]=11
    ["trace_compliance"]=11
    ["long_document"]=7
    ["multi_agent"]=5
    ["trigger_accuracy"]=5
)

declare -A DIMENSION_THRESHOLDS=(
    ["system_prompt"]=56
    ["domain_knowledge"]=56
    ["workflow"]=56
    ["error_handling"]=44
    ["examples"]=44
    ["metadata"]=24
    ["identity_consistency"]=64
    ["framework_execution"]=56
    ["output_actionability"]=56
    ["knowledge_accuracy"]=40
    ["conversation_stability"]=40
    ["trace_compliance"]=40
    ["long_document"]=24
    ["multi_agent"]=20
    ["trigger_accuracy"]=20
)

declare -A DIMENSION_RECOMMENDATIONS=(
    ["system_prompt"]="Enhance system prompt with more context from §1.1, §1.2, §1.3 and explicit constraints"
    ["domain_knowledge"]="Add more specific data and facts (≥10 concrete data points required)"
    ["workflow"]="Expand workflow to 4-6 clear stages with explicit Done/Fail conditions"
    ["error_handling"]="Add ≥5 named failure cases with specific recovery strategies"
    ["examples"]="Include ≥5 complete scenarios with input/output/verification"
    ["metadata"]="Ensure agentskills-spec compliance for metadata section"
    ["identity_consistency"]="Strengthen role definition to prevent identity drift in long conversations"
    ["framework_execution"]="Improve tool call patterns and memory structure access"
    ["output_actionability"]="Enhance parameter completeness in generated outputs"
    ["knowledge_accuracy"]="Reduce hallucination by adding factual grounding references"
    ["conversation_stability"]="Improve MultiTurnPassRate to ≥85%"
    ["trace_compliance"]="Align behavior with AgentPex rules (≥90% compliance)"
    ["long_document"]="Test and stabilize 100K token processing"
    ["multi_agent"]="Strengthen collaboration patterns for multi-agent scenarios"
    ["trigger_accuracy"]="Improve trigger matching with synonym coverage"
)

analyze_dimensions() {
    local json_dimensions="$1"
    
    if [[ -z "$json_dimensions" ]]; then
        echo "Error: JSON dimensions required" >&2
        return 1
    fi
    
    local temp_file
    temp_file=$(mktemp)
    
    local keys
    keys=$(echo "$json_dimensions" | jq -r 'keys[]' 2>/dev/null || echo "")
    
    if [[ -z "$keys" ]]; then
        echo "Error: No dimensions found in JSON" >&2
        rm -f "$temp_file"
        return 1
    fi
    
    > "$temp_file"
    
    for key in $keys; do
        local score
        score=$(echo "$json_dimensions" | jq -r ".[\"$key\"] // 0")
        local weight="${DIMENSION_WEIGHTS[$key]:-10}"
        local threshold="${DIMENSION_THRESHOLDS[$key]:-0}"
        local recommendation="${DIMENSION_RECOMMENDATIONS[$key]:-Review and improve this dimension}"
        
        local max_score
        case "$key" in
            system_prompt|domain_knowledge|workflow)
                max_score=70
                ;;
            error_handling|examples)
                max_score=55
                ;;
            metadata)
                max_score=30
                ;;
            identity_consistency)
                max_score=80
                ;;
            framework_execution|output_actionability)
                max_score=70
                ;;
            knowledge_accuracy|conversation_stability|trace_compliance)
                max_score=50
                ;;
            long_document)
                max_score=30
                ;;
            multi_agent|trigger_accuracy)
                max_score=25
                ;;
            *)
                max_score=100
                ;;
        esac
        
        local percentage
        percentage=$(echo "scale=2; ($score / $max_score) * 100" | bc)
        local gap
        gap=$(echo "scale=2; $threshold - $score" | bc)
        
        if [[ $(echo "$score < $threshold" | bc -l) -eq 1 ]]; then
            echo "${key}:${score}:${recommendation}" >> "$temp_file"
        fi
    done
    
    local result
    result=$(sort -t':' -k2 -n "$temp_file" < "$temp_file")
    
    rm -f "$temp_file"
    
    echo "WEAKEST_DIMENSIONS:"
    echo "$result"
    
    return 0
}

analyze_dimensions_from_file() {
    local score_file="$1"
    
    if [[ ! -f "$score_file" ]]; then
        echo "Error: Score file not found: $score_file" >&2
        return 1
    fi
    
    local json_data
    json_data=$(cat "$score_file")
    analyze_dimensions "$json_data"
}

get_top_weaknesses() {
    local json_dimensions="$1"
    local count="${2:-3}"
    
    local temp_file
    temp_file=$(mktemp)
    
    analyze_dimensions "$json_dimensions" > "$temp_file" 2>&1
    
    local weaknesses
    weaknesses=$(tail -n +2 "$temp_file" | head -n "$count")
    
    rm -f "$temp_file"
    
    echo "$weaknesses"
}

format_dimension_report() {
    local json_dimensions="$1"
    
    local temp_file
    temp_file=$(mktemp)
    
    analyze_dimensions "$json_dimensions" > "$temp_file" 2>&1
    
    echo "=== Dimension Analysis ==="
    echo ""
    echo "Weakest dimensions requiring improvement:"
    echo ""
    
    local line_num=1
    while IFS=: read -r dimension score recommendation; do
        if [[ -n "$dimension" ]] && [[ "$dimension" != "WEAKEST_DIMENSIONS" ]]; then
            echo "[$line_num] $dimension (score: $score)"
            echo "    → $recommendation"
            echo ""
            line_num=$((line_num + 1))
        fi
    done < "$temp_file"
    
    rm -f "$temp_file"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -lt 1 ]]; then
        echo "Usage: $0 <dimensions.json>"
        echo "Example: $0 '{\"system_prompt\":45,\"domain_knowledge\":60}'"
        exit 1
    fi
    analyze_dimensions "$1"
fi
