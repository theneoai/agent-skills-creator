#!/usr/bin/env bash
# _actions.sh - 操作决策

source "$(dirname "${BASH_SOURCE[0]}")/_state.sh"

# ============================================================================
# 决策函数
# ============================================================================

workflow_get_next_action() {
    local score="$1"
    local tier="$2"
    
    if [[ "$tier" == "GOLD" ]] || [[ "$tier" == "SILVER" ]] || [[ "$tier" == "BRONZE" ]]; then
        if [[ $score -ge 800 ]]; then
            echo "done"
            return 0
        fi
    fi
    
    if [[ $ITERATION_COUNT -ge $MAX_ITERATIONS ]]; then
        echo "done"
        return 0
    fi
    
    if [[ $score -gt $LAST_SCORE ]]; then
        echo "continue"
        return 0
    fi
    
    echo "improve"
    return 0
}

workflow_check_evolution_trigger() {
    local threshold
    if [[ $EVALUATION_COUNT -lt 10 ]]; then
        threshold=$EVOLUTION_THRESHOLD_NEW
    elif [[ $EVALUATION_COUNT -lt 50 ]]; then
        threshold=$EVOLUTION_THRESHOLD_GROWING
    else
        threshold=$EVOLUTION_THRESHOLD_STABLE
    fi
    
    if [[ $EVALUATION_COUNT -gt 0 ]] && [[ $((EVALUATION_COUNT % threshold)) -eq 0 ]]; then
        return 0
    fi
    return 1
}

workflow_trigger_evolution() {
    source "${EVAL_DIR_FROM_ENGINE}/evolution/engine.sh"
    
    if is_lock_available "evolution" 5; then
        evolve_skill "$TARGET_SKILL_FILE"
    else
        echo "Evolution skipped: engine busy"
    fi
}

# ============================================================================
# 日志记录
# ============================================================================

log_usage() {
    local skill_name="$1"
    local score="$2"
    local tier="$3"
    local iterations="$4"
    local timestamp
    timestamp=$(get_timestamp)
    
    ensure_directory "$(dirname "$USAGE_LOG")"
    jq -n \
        --arg ts "$timestamp" \
        --arg name "$skill_name" \
        --arg score "$score" \
        --arg tier "$tier" \
        --arg iter "$iterations" \
        '{timestamp: $ts, skill_name: $name, score: ($score | tonumber), tier: $tier, iterations: ($iterations | tonumber)}' \
        >> "$USAGE_LOG" 2>/dev/null || true
}

# ============================================================================
# 调试输出
# ============================================================================

log_verbose() {
    if [[ "$VERBOSE" == "1" ]]; then
        echo "[VERBOSE] $1" >&2
    fi
}