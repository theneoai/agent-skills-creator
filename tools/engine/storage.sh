#!/usr/bin/env bash
# _storage.sh - 存储抽象层
#
# 提供对 usage.log 的统一访问接口

source "$(dirname "${BASH_SOURCE[0]}")/../lib/bootstrap.sh"
require constants

# ============================================================================
# 使用日志操作
# ============================================================================

storage_get_eval_count() {
    local skill_name="$1"
    
    if [[ ! -f "$USAGE_LOG" ]]; then
        echo 0
        return
    fi
    
    local count
    count=$(grep -c "\"skill_name\":\"${skill_name}\"" "$USAGE_LOG" 2>/dev/null || echo 0)
    
    echo "$count"
}

storage_get_last_score() {
    local skill_name="$1"
    
    if [[ ! -f "$USAGE_LOG" ]]; then
        echo 0
        return
    fi
    
    local last_score
    last_score=$(grep "\"skill_name\":\"${skill_name}\"" "$USAGE_LOG" 2>/dev/null | tail -1 | jq -r '.score // 0')
    
    echo "${last_score:-0}"
}

storage_log_usage() {
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

storage_get_all_scores() {
    local skill_name="$1"
    
    if [[ ! -f "$USAGE_LOG" ]]; then
        echo "[]"
        return
    fi
    
    grep "\"skill_name\":\"${skill_name}\"" "$USAGE_LOG" 2>/dev/null | jq -s '.' || echo "[]"
}

storage_calculate_threshold() {
    local eval_count="$1"
    
    if [[ $eval_count -lt 10 ]]; then
        echo $EVOLUTION_THRESHOLD_NEW
    elif [[ $eval_count -lt 50 ]]; then
        echo $EVOLUTION_THRESHOLD_GROWING
    else
        echo $EVOLUTION_THRESHOLD_STABLE
    fi
}