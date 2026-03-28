#!/usr/bin/env bash
set -euo pipefail

generate_json_report() {
    local output_file="$1"
    local skill_name="$2"
    local skill_version="$3"
    local evaluated_at="$4"
    
    local parse_score="$5"
    local text_score="$6"
    local runtime_score="$7"
    local certify_score="$8"
    local total_score="$9"
    
    local f1_score="${10}"
    local mrr_score="${11}"
    local trigger_accuracy="${12}"
    local variance="${13}"
    
    local tier="${14}"
    local certified="${15}"
    
    local dimension_json="${16}"
    local recommendations_json="${17}"
    
    local f1_threshold="0.90"
    local mrr_threshold="0.85"
    local ta_threshold="0.99"
    local text_threshold="280"
    local runtime_threshold="360"
    local variance_threshold="20"
    
    local f1_met=$(echo "$f1_score >= $f1_threshold" | bc -l)
    local mrr_met=$(echo "$mrr_score >= $mrr_threshold" | bc -l)
    local ta_met=$(echo "$trigger_accuracy >= $ta_threshold" | bc -l)
    local text_met=$(echo "$text_score >= $text_threshold" | bc -l)
    local runtime_met=$(echo "$runtime_score >= $runtime_threshold" | bc -l)
    local variance_met=$(echo "$variance < $variance_threshold" | bc -l)
    
    if [ "$f1_met" = "1" ]; then f1_met="true"; else f1_met="false"; fi
    if [ "$mrr_met" = "1" ]; then mrr_met="true"; else mrr_met="false"; fi
    if [ "$ta_met" = "1" ]; then ta_met="true"; else ta_met="false"; fi
    if [ "$text_met" = "1" ]; then text_met="true"; else text_met="false"; fi
    if [ "$runtime_met" = "1" ]; then runtime_met="true"; else runtime_met="false"; fi
    if [ "$variance_met" = "1" ]; then variance_met="true"; else variance_met="false"; fi
    
    cat > "$output_file" << EOF
{
  "skill_name": "$skill_name",
  "version": "$skill_version",
  "evaluated_at": "$evaluated_at",
  "scores": {
    "parse_validate": $parse_score,
    "text_score": $text_score,
    "runtime_score": $runtime_score,
    "certify": $certify_score,
    "total": $total_score
  },
  "metrics": {
    "f1_score": $f1_score,
    "mrr": $mrr_score,
    "trigger_accuracy": $trigger_accuracy,
    "variance": $variance
  },
  "tier": "$tier",
  "certified": $certified,
  "dimensions": $dimension_json,
  "weakest_dimensions": $recommendations_json,
  "thresholds_met": {
    "f1": $f1_met,
    "mrr": $mrr_met,
    "trigger_accuracy": $ta_met,
    "text_score": $text_met,
    "runtime_score": $runtime_met,
    "variance": $variance_met
  }
}
EOF
}

generate_dimension_json() {
    local system_prompt_score="${1}"
    local domain_knowledge_score="${2}"
    local workflow_score="${3}"
    local error_handling_score="${4}"
    local examples_score="${5}"
    local metadata_score="${6}"
    local identity_consistency_score="${7}"
    local framework_execution_score="${8}"
    local output_actionability_score="${9}"
    local knowledge_accuracy_score="${10}"
    local conversation_stability_score="${11}"
    local trace_compliance_score="${12}"
    local long_document_score="${13}"
    local multi_agent_score="${14}"
    local trigger_accuracy_score="${15}"
    
    cat << EOF
{
  "system_prompt": {"score": $system_prompt_score, "max": 70},
  "domain_knowledge": {"score": $domain_knowledge_score, "max": 70},
  "workflow": {"score": $workflow_score, "max": 70},
  "error_handling": {"score": $error_handling_score, "max": 55},
  "examples": {"score": $examples_score, "max": 55},
  "metadata": {"score": $metadata_score, "max": 30},
  "identity_consistency": {"score": $identity_consistency_score, "max": 80},
  "framework_execution": {"score": $framework_execution_score, "max": 70},
  "output_actionability": {"score": $output_actionability_score, "max": 70},
  "knowledge_accuracy": {"score": $knowledge_accuracy_score, "max": 50},
  "conversation_stability": {"score": $conversation_stability_score, "max": 50},
  "trace_compliance": {"score": $trace_compliance_score, "max": 50},
  "long_document": {"score": $long_document_score, "max": 30},
  "multi_agent": {"score": $multi_agent_score, "max": 25},
  "trigger_accuracy_score": {"score": $trigger_accuracy_score, "max": 25}
}
EOF
}

generate_weakest_dimensions_json() {
    local dims_json="$1"
    local count="${2:-3}"
    
    local temp_file=$(mktemp)
    echo "$dims_json" > "$temp_file"
    
    local result="["
    local first=true
    
    while IFS= read -r line; do
        if [[ "$line" =~ \"([^\"]+)\":.*\"score\":[[:space:]]*([0-9]+) ]]; then
            local dim="${BASH_REMATCH[1]}"
            local score="${BASH_REMATCH[2]}"
            if [ "$first" = true ]; then
                first=false
            else
                result+=","
            fi
            result+="{\"dimension\": \"$dim\", \"score\": $score}"
        fi
    done < "$temp_file"
    
    result+="]"
    rm -f "$temp_file"
    
    echo "$result"
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    echo "json_reporter.sh - JSON report generator for unified-skill-eval"
    echo "Usage: source this file and call generate_json_report with parameters"
fi
