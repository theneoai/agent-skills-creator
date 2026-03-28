#!/usr/bin/env bash
# improver.sh - LLM执行改进

source "$(dirname "${BASH_SOURCE[0]}")/../lib/bootstrap.sh"
require constants integration
source "${EVAL_DIR}/lib/agent_executor.sh"

improver_system_prompt="You are an expert SKILL.md editor. Your task is to improve existing SKILL.md files based on improvement suggestions.

Follow the agentskills.io v2.1.0 specification strictly. When modifying a SKILL.md:
1. Preserve existing content unless explicitly told to replace
2. Add missing sections with high-quality content
3. Improve unclear or incomplete sections
4. Add better examples and edge case handling
5. Maintain consistent formatting and style

Output format: Return a JSON object with the improved SKILL.md content as the 'content' field."

generate() {
    local summary="$1"
    local skill_file="$2"
    
    if [[ ! -f "$skill_file" ]]; then
        return 1
    fi
    
    local current_content
    current_content=$(cat "$skill_file")
    
    local skill_name
    skill_name=$(basename "$skill_file" .md)
    
    local improvement_prompt="Improve the following SKILL.md file for '${skill_name}' based on this improvement plan:

${summary}

Current SKILL.md content:
${current_content}

Analyze the improvement plan and current content, then produce an improved version.
Return a JSON object: {\"content\": \"<improved SKILL.md content here>\"}"
    
    local response
    response=$(call_llm "$improver_system_prompt" "$improvement_prompt" "auto" "kimi-code")
    
    if [[ $? -ne 0 ]] || [[ -z "$response" ]] || [[ "$response" == ERROR:* ]]; then
        return 1
    fi
    
    echo "$response"
}

generate_targeted() {
    local skill_file="$1"
    local target_section="$2"
    local improvement_guide="$3"
    
    if [[ ! -f "$skill_file" ]]; then
        return 1
    fi
    
    local current_content
    current_content=$(cat "$skill_file")
    
    local skill_name
    skill_name=$(basename "$skill_file" .md)
    
    local improvement_prompt="Improve only section §${target_section} of this SKILL.md for '${skill_name}'.

Improvement guide:
${improvement_guide}

Current SKILL.md content:
${current_content}

Return a JSON object: {\"content\": \"<improved SKILL.md content here>\"}"
    
    local response
    response=$(call_llm "$improver_system_prompt" "$improvement_prompt" "auto" "kimi-code")
    
    if [[ $? -ne 0 ]] || [[ -z "$response" ]] || [[ "$response" == ERROR:* ]]; then
        return 1
    fi
    
    echo "$response"
}

validate_improvement() {
    local original_file="$1"
    local improved_file="$2"
    
    local original_result improved_result
    original_result=$(evaluate_skill "$original_file" "fast")
    improved_result=$(evaluate_skill "$improved_file" "fast")
    
    local original_score improved_score
    original_score=$(echo "$original_result" | jq -r '.total_score // 0')
    improved_score=$(echo "$improved_result" | jq -r '.total_score // 0')
    
    local delta=$((improved_score - original_score))
    
    jq -n \
        --arg original "$original_score" \
        --arg improved "$improved_score" \
        --arg delta "$delta" \
        --arg improved_file "$improved_file" \
        '{
            original_score: ($original | tonumber),
            improved_score: ($improved | tonumber),
            delta: ($delta | tonumber),
            improved_file: $improved_file
        }'
}

apply_with_validation() {
    local skill_file="$1"
    local improvements="$2"
    
    local temp_file
    temp_file=$(mktemp /tmp/improved_skill_XXXXXX.md)
    
    local improved_content
    improved_content=$(echo "$improvements" | jq -r '.content // empty')
    
    if [[ -z "$improved_content" ]]; then
        rm -f "$temp_file"
        return 1
    fi
    
    echo "$improved_content" > "$temp_file"
    
    require_evolution rollback
    create_snapshot "$skill_file" "pre_validation"
    
    local validation
    validation=$(validate_improvement "$skill_file" "$temp_file")
    
    local improved_score delta
    improved_score=$(echo "$validation" | jq -r '.improved_score')
    delta=$(echo "$validation" | jq -r '.delta')
    
    if [[ $delta -gt 0 ]]; then
        cp "$temp_file" "$skill_file"
        echo "Improvement applied: +$delta points"
    else
        echo "Improvement rejected: delta=$delta (would decrease score)"
    fi
    
    rm -f "$temp_file"
    
    echo "$validation"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -lt 2 ]]; then
        echo "Usage: $0 <summary_json> <skill_file>"
        exit 1
    fi
    
    generate "$1" "$2"
fi