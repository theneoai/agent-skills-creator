#!/usr/bin/env bash
# evaluator.sh - Evaluator Agent

source "$(dirname "${BASH_SOURCE[0]}")/base.sh"
require integration

# ============================================================================
# 初始化
# ============================================================================

agent_init

# ============================================================================
# 评估函数
# ============================================================================

evaluator_evaluate_file() {
    local skill_file="$1"
    local section_num="${2:-0}"
    
    if [[ ! -f "$skill_file" ]]; then
        echo '{"error": "Skill file not found"}'
        return 1
    fi
    
    local eval_result
    eval_result=$(evaluate_skill "$skill_file" "fast")
    
    if [[ $? -ne 0 ]] || [[ -z "$eval_result" ]]; then
        return 1
    fi
    
    local score tier
    score=$(echo "$eval_result" | jq -r '.total_score // 0')
    tier=$(echo "$eval_result" | jq -r '.tier // "UNKNOWN"')
    
    local suggestions
    suggestions=$(evaluator_generate_suggestions "$skill_file" "$score" "$section_num")
    
    jq -n \
        --arg score "$score" \
        --arg tier "$tier" \
        --arg suggestions "$suggestions" \
        --arg section "$section_num" \
        '{
            score: ($score | tonumber),
            tier: $tier,
            suggestions: $suggestions,
            evaluated_section: ($section | tonumber)
        }'
}

evaluator_evaluate_section() {
    local section_content="$1"
    local section_num="${2:-0}"
    
    local temp_file
    temp_file=$(mktemp /tmp/section_eval_XXXXXX.md)
    echo "$section_content" > "$temp_file"
    
    local result
    result=$(evaluator_evaluate_file "$temp_file" "$section_num")
    
    rm -f "$temp_file"
    
    echo "$result"
}

evaluator_generate_suggestions() {
    local skill_file="$1"
    local current_score="$2"
    local section_num="${3:-0}"
    
    local system_prompt
    system_prompt=$(agent_load_system_prompt "evaluator")
    
    local normalized_score
    normalized_score=$(echo "scale=0; $current_score * 1000 / 1155 / 1" | bc)
    
    local prompt="Based on the current SKILL.md content and a score of ${current_score} (normalized: ${normalized_score}/1000), generate specific improvement suggestions.

Current section being developed: §${section_num}

Read the SKILL.md file and identify:
1. Missing or incomplete sections
2. Unclear instructions or parameters
3. Missing error handling
4. Missing edge case coverage
5. Quality issues in existing content

Provide 3-5 concrete, actionable suggestions. Each suggestion should:
- Be specific (not "improve the documentation")
- Include what to add or change
- Explain why it matters

Format your response as a numbered list."
    
    local response
    response=$(agent_call_llm "$system_prompt" "$prompt" "auto" "kimi-code")
    
    if [[ $? -ne 0 ]] || [[ -z "$response" ]] || [[ "$response" == ERROR:* ]]; then
        echo "Unable to generate suggestions at this time."
        return 1
    fi
    
    echo "$response"
}

evaluator_check_format() {
    local skill_file="$1"
    
    if [[ ! -f "$skill_file" ]]; then
        echo "ERROR: File not found"
        return 1
    fi
    
    local has_header=false
    local has_sections=false
    
    if grep -q "^# " "$skill_file"; then
        has_header=true
    fi
    
    if grep -qE "^## §[0-9]" "$skill_file"; then
        has_sections=true
    fi
    
    if [[ "$has_header" == "true" ]] && [[ "$has_sections" == "true" ]]; then
        echo "VALID"
        return 0
    else
        echo "INVALID: Missing header or sections"
        return 1
    fi
}

evaluator_compare_versions() {
    local old_file="$1"
    local new_file="$2"
    
    if [[ ! -f "$old_file" ]] || [[ ! -f "$new_file" ]]; then
        echo "ERROR: One or both files not found"
        return 1
    fi
    
    local old_result new_result
    old_result=$(evaluate_skill "$old_file" "fast")
    new_result=$(evaluate_skill "$new_file" "fast")
    
    local old_score new_score
    old_score=$(echo "$old_result" | jq -r '.total_score // 0')
    new_score=$(echo "$new_result" | jq -r '.total_score // 0')
    
    local delta=$(echo "$new_score - $old_score" | bc)
    
    jq -n \
        --arg old_score "$old_score" \
        --arg new_score "$new_score" \
        --arg delta "$delta" \
        '{
            old_score: ($old_score | tonumber),
            new_score: ($new_score | tonumber),
            delta: ($delta | tonumber)
        }'
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -lt 1 ]]; then
        echo "Usage: $0 <skill_file> [section_num]"
        exit 1
    fi
    
    evaluator_evaluate_file "$1" "${2:-0}"
fi