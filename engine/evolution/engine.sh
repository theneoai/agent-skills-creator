#!/usr/bin/env bash
# engine.sh - Evolution Engine 主控

source "$(dirname "${BASH_SOURCE[0]}")/../lib/bootstrap.sh"
source "${EVAL_DIR}/lib/agent_executor.sh"

# ============================================================================
# 加载依赖模块
# ============================================================================

require constants concurrency errors integration
require_evolution rollback _storage

EVOLUTION_LOG="${LOG_DIR}/evolution.log"

# ============================================================================
# 进化日志
# ============================================================================

log_evolution() {
    local skill_name="$1"
    local action="$2"
    local details="$3"
    local timestamp
    timestamp=$(get_timestamp)
    
    ensure_directory "$(dirname "$EVOLUTION_LOG")"
    jq -n \
        --arg ts "$timestamp" \
        --arg skill "$skill_name" \
        --arg action "$action" \
        --arg details "$details" \
        '{timestamp: $ts, skill_name: $skill, action: $action, details: $details}' \
        >> "$EVOLUTION_LOG" 2>/dev/null || true
}

# ============================================================================
# 进化管道
# ============================================================================

evolve_skill() {
    local skill_file="$1"
    
    local skill_name
    skill_name=$(basename "$skill_file" .md)
    
    log_evolution "$skill_name" "start" "Evolution cycle started"
    
    create_snapshot "$skill_file" "pre_evolution"
    
    local eval_count
    eval_count=$(storage_get_eval_count "$skill_name")
    
    local threshold
    threshold=$(storage_calculate_threshold "$eval_count")
    
    log_evolution "$skill_name" "threshold_check" "Eval count: $eval_count, Threshold: $threshold"
    
    if [[ $eval_count -lt $threshold ]]; then
        echo "Evolution skipped: eval_count ($eval_count) < threshold ($threshold)"
        return 0
    fi
    
    local analysis
    analysis=$(analyze_usage_logs "$skill_file")
    
    if [[ $? -ne 0 ]] || [[ -z "$analysis" ]]; then
        log_evolution "$skill_name" "analysis_failed" "Unable to analyze usage logs"
        handle_error "EVAL_FAILURE" "Analysis failed" "evolve_skill"
        return 1
    fi
    
    local summary
    summary=$(summarize_findings "$analysis" "$skill_name")
    
    if [[ $? -ne 0 ]] || [[ -z "$summary" ]]; then
        log_evolution "$skill_name" "summary_failed" "Unable to summarize findings"
        handle_error "EVAL_FAILURE" "Summary failed" "evolve_skill"
        return 1
    fi
    
    local improvements
    improvements=$(generate_improvements "$summary" "$skill_file")
    
    if [[ $? -ne 0 ]] || [[ -z "$improvements" ]]; then
        log_evolution "$skill_name" "improvement_failed" "Unable to generate improvements"
        handle_error "EVAL_FAILURE" "Improvement generation failed" "evolve_skill"
        return 1
    fi
    
    apply_improvements "$skill_file" "$improvements"
    
    local new_result
    new_result=$(evaluate_skill "$skill_file" "full")
    local new_score
    new_score=$(echo "$new_result" | jq -r '.total_score // 0')
    
    local old_score
    old_score=$(storage_get_last_score "$skill_name")
    
    if check_auto_rollback "$new_score" "$old_score" "true" "$skill_file"; then
        log_evolution "$skill_name" "rollback" "Score regression detected, rolled back"
        return 1
    fi
    
    log_evolution "$skill_name" "complete" "Score: $old_score -> $new_score"
    
    echo "Evolution complete: $old_score -> $new_score"
    return 0
}

# ============================================================================
# 子步骤
# ============================================================================

analyze_usage_logs() {
    source "${EVAL_DIR_FROM_ENGINE}/evolution/analyzer.sh"
    analyze_logs "$1"
}

summarize_findings() {
    source "${EVAL_DIR_FROM_ENGINE}/evolution/summarizer.sh"
    summarize "$1" "$2"
}

generate_improvements() {
    source "${EVAL_DIR_FROM_ENGINE}/evolution/improver.sh"
    generate "$1" "$2"
}

apply_improvements() {
    local skill_file="$1"
    local improvements="$2"
    
    local improved_content
    improved_content=$(echo "$improvements" | jq -r '.content // empty')
    
    if [[ -n "$improved_content" ]]; then
        echo "$improved_content" > "$skill_file"
        log_evolution "$(basename "$skill_file" .md)" "applied" "Improvements applied"
    fi
}

# ============================================================================
# CLI 接口
# ============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -lt 1 ]]; then
        echo "Usage: $0 <skill_file>"
        exit 1
    fi
    
    acquire_lock "evolution" "$EVOLUTION_TIMEOUT" || {
        echo "Error: Failed to acquire evolution lock"
        exit 1
    }
    
    trap "release_lock 'evolution'" EXIT
    
    evolve_skill "$1"
fi