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
    
    local r1 r2
    r1=$(agent_call_llm "$system_prompt" "$prompt" "auto" "kimi-code")
    r2=$(agent_call_llm "$system_prompt" "$prompt" "auto" "minimax")
    
    local status1 status2
    status1=$(echo "$r1" | jq -r '.status // "ERROR"')
    status2=$(echo "$r2" | jq -r '.status // "ERROR"')
    
    local content1 content2
    content1=$(echo "$r1" | jq -r '.content // ""')
    content2=$(echo "$r2" | jq -r '.content // ""')
    
    if [[ "$status1" != "success" ]] && [[ "$status2" != "success" ]]; then
        return 1
    fi
    
    if [[ "$status1" != "success" ]]; then
        jq -n --arg content "$content2" '{content: $content, deliberation: "single_llm"}'
        return 0
    fi
    
    if [[ "$status2" != "success" ]]; then
        jq -n --arg content "$content1" '{content: $content, deliberation: "single_llm"}'
        return 0
    fi
    
    if [[ -z "$content1" ]] || [[ "$content1" == "null" ]]; then
        jq -n --arg content "$content2" '{content: $content, deliberation: "single_llm"}'
        return 0
    fi
    
    if [[ -z "$content2" ]] || [[ "$content2" == "null" ]]; then
        jq -n --arg content "$content1" '{content: $content, deliberation: "single_llm"}'
        return 0
    fi
    
    if [[ "$content1" == "$content2" ]]; then
        jq -n --arg content "$content1" '{content: $content, deliberation: "unanimous"}'
        return 0
    fi
    
    local deliberation_prompt="Compare two proposed sections for §${section_num} and determine the better one.

Proposal A:
$content1

Proposal B:
$content2

User request: ${user_prompt}

Respond with JSON:
{\"chosen\": \"A\" or \"B\", \"reason\": \"brief explanation\"}"
    
    local decision
    decision=$(agent_call_llm_json "$(cat <<'EOF'
You are a skill architecture expert. Select the better section implementation.
EOF
)" "$deliberation_prompt" "auto" "kimi")
    
    if [[ $? -eq 0 ]] && [[ -n "$decision" ]] && [[ "$decision" != "null" ]]; then
        local chosen
        chosen=$(echo "$decision" | jq -r '.chosen')
        local reason
        reason=$(echo "$decision" | jq -r '.reason')
        if [[ "$chosen" == "A" ]]; then
            jq -n --arg content "$content1" --arg reason "$reason" '{content: $content, deliberation: "deliberated", reason: $reason}'
        else
            jq -n --arg content "$content2" --arg reason "$reason" '{content: $content, deliberation: "deliberated", reason: $reason}'
        fi
    else
        local len1 len2
        len1=${#content1}
        len2=${#content2}
        if [[ $len1 -ge $len2 ]]; then
            jq -n --arg content "$content1" '{content: $content, deliberation: "conflict_length_fallback"}'
        else
            jq -n --arg content "$content2" '{content: $content, deliberation: "conflict_length_fallback"}'
        fi
    fi
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
    evolution=$(awk '/^## §6/,/^## [^§]/ {print}' "$parent_skill" | sed '$ d')
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