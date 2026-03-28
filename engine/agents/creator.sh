#!/usr/bin/env bash
# creator.sh - Creator Agent

source "$(dirname "${BASH_SOURCE[0]}")/base.sh"

# ============================================================================
# 初始化
# ============================================================================

agent_init

# ============================================================================
# Creator 生成逻辑
# ============================================================================

creator_generate() {
    local context_file="$1"
    
    local user_prompt section_num evaluator_feedback
    user_prompt=$(jq -r '.user_prompt' "$context_file")
    section_num=$(jq -r '.current_section' "$context_file")
    evaluator_feedback=$(jq -r '.evaluator_feedback' "$context_file")
    
    local system_prompt
    system_prompt=$(agent_load_system_prompt "creator")
    
    local prompt
    prompt="Create section §${section_num} of the SKILL.md file.

User's original request: ${user_prompt}

Current section number: ${section_num}

Evaluator feedback from previous iteration (if any):
${evaluator_feedback:-No feedback yet. This is the first section.}

"
    
    local response
    response=$(agent_call_llm "$system_prompt" "$prompt" "auto" "kimi-code")
    
    if [[ $? -ne 0 ]] || [[ -z "$response" ]] || [[ "$response" == ERROR:* ]]; then
        return 1
    fi
    
    jq -n --arg content "$response" '{content: $content}'
}

creator_init_skill_file() {
    local skill_file="$1"
    local skill_name="$2"
    local parent_skill="${3:-}"
    
    local content="# ${skill_name}

> **Version**: 0.1.0
> **Date**: $(date +%Y-%m-%d)
> **Status**: DRAFT

---

"
    
    echo "$content" > "$skill_file"
    
    if [[ -n "$parent_skill" ]]; then
        inherit_sections "$parent_skill" "$skill_file"
    fi
}

extract_inherited_sections() {
    local parent_skill="$1"
    
    if [[ ! -f "$parent_skill" ]]; then
        echo "WARNING: Parent skill not found: $parent_skill" >&2
        return 1
    fi
    
    local content=""
    
    local identity
    identity=$(awk '/^## §1\.1/{found=1} found{print} /^## [^§]/{if(found && NR>1) exit}' "$parent_skill")
    if [[ -n "$identity" ]]; then
        content+="$identity"$'\n'
    fi
    
    local redlines
    redlines=$(awk '/\*\*Red Lines|严禁/{found=1} found{print} /^## [^§]/{if(found) exit}' "$parent_skill")
    if [[ -n "$redlines" ]]; then
        content+="$redlines"$'\n'
    fi
    
    local evolution
    evolution=$(awk '/^## §6/,/^## [^§]/ {print}' "$parent_skill" | head -n -1)
    if [[ -n "$evolution" ]]; then
        content+="$evolution"$'\n'
    fi
    
    echo "$content"
}

inherit_sections() {
    local parent_skill="$1"
    local target_file="$2"
    
    local inherited
    inherited=$(extract_inherited_sections "$parent_skill")
    
    if [[ -z "$inherited" ]]; then
        echo "No inheritance content found"
        return 1
    fi
    
    if [[ -s "$target_file" ]]; then
        echo "Target file already has content, inheritance skipped (child content priority)"
        return 0
    fi
    
    echo "$inherited" >> "$target_file"
    echo "" >> "$target_file"
}

creator_get_next_section_prompt() {
    local section_num="$1"
    local skill_type="$2"
    
    case "$section_num" in
        1) echo "§1.1 Identity - Define the skill's name, purpose, and core characteristics" ;;
        2) echo "§1.2 Framework - Describe the operating principles" ;;
        3) echo "§1.3 Thinking - Define the cognitive framework" ;;
        4) echo "§2.1 Invocation - How to activate this skill" ;;
        5) echo "§2.2 Recognition - Pattern matching rules" ;;
        6) echo "§3.1 Process - Main workflow steps" ;;
        7) echo "§4.1 Tool Set - Available tools" ;;
        8) echo "§5.1 Validation - Quality checks" ;;
        9) echo "§8.1 Metrics - Success criteria" ;;
        *) echo "Continue developing the skill with additional sections" ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -lt 1 ]]; then
        echo "Usage: $0 <context_file>"
        exit 1
    fi
    
    creator_generate "$1"
fi