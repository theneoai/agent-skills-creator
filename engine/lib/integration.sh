#!/usr/bin/env bash
# integration.sh - 集成 eval 框架

source "$(dirname "${BASH_SOURCE[0]}")/bootstrap.sh"
source "${EVAL_DIR}/lib/agent_executor.sh"

# ============================================================================
# 评估函数
# ============================================================================

evaluate_skill() {
    local skill_file="$1"
    local mode="${2:-fast}"
    
    if [[ ! -f "$skill_file" ]]; then
        echo "Error: Skill file not found: $skill_file" >&2
        return 1
    fi
    
    cd "$EVAL_DIR"
    
    local result
    result=$(./main.sh --skill "$skill_file" --${mode} 2>/dev/null)
    local exit_code=$?
    
    cd - >/dev/null
    
    if [[ $exit_code -ne 0 ]]; then
        return 1
    fi
    
    echo "$result"
}

evaluate_partial() {
    local partial_content="$1"
    local temp_file=$(mktemp /tmp/partial_skill_XXXXXX.md)
    
    echo "$partial_content" > "$temp_file"
    
    local result
    result=$(evaluate_skill "$temp_file" "fast")
    
    rm -f "$temp_file"
    
    echo "$result"
}

parse_evaluation_result() {
    local result="$1"
    
    local score tier p1 p2 p3 p4
    score=$(echo "$result" | jq -r '.total_score' 2>/dev/null || echo 0)
    tier=$(echo "$result" | jq -r '.tier' 2>/dev/null || echo "UNKNOWN")
    p1=$(echo "$result" | jq -r '.phases.parse_validate' 2>/dev/null || echo 0)
    p2=$(echo "$result" | jq -r '.phases.text_score' 2>/dev/null || echo 0)
    p3=$(echo "$result" | jq -r '.phases.runtime_score' 2>/dev/null || echo 0)
    p4=$(echo "$result" | jq -r '.phases.certification' 2>/dev/null || echo 0)
    
    jq -n \
        --arg score "$score" \
        --arg tier "$tier" \
        --arg p1 "$p1" \
        --arg p2 "$p2" \
        --arg p3 "$p3" \
        --arg p4 "$p4" \
        '{
            score: ($score | tonumber),
            tier: $tier,
            phases: {
                parse: ($p1 | tonumber),
                text: ($p2 | tonumber),
                runtime: ($p3 | tonumber),
                cert: ($p4 | tonumber)
            }
        }'
}