#!/usr/bin/env bash
# evolve_decider.sh - Evolution decision engine
# Decides when to trigger self-evolution based on thresholds and schedule

source "$(dirname "${BASH_SOURCE[0]}")/../lib/bootstrap.sh"
source "${EVAL_DIR}/lib/agent_executor.sh"

EVOLVE_DECIDER_VERSION="1.0"

GOLD_THRESHOLD=475
SILVER_THRESHOLD=425
BRONZE_THRESHOLD=350

CHECK_INTERVAL_HOURS=24
LAST_CHECK_FILE="${EVOLUTION_USAGE_DIR}/.last_evolution_check"

should_evolve() {
    local skill_file="$1"
    local force="${2:-false}"
    
    local skill_name
    skill_name=$(basename "$skill_file" .md)
    
    if [[ "$force" == "true" ]]; then
        echo '{"decision": "evolve", "reason": "forced"}'
        return
    fi
    
    local current_score
    current_score=$(bash scripts/lean-orchestrator.sh "$skill_file" SILVER 2>/dev/null | jq -r '.total // 0')
    
    if [[ "$(echo "$current_score < $GOLD_THRESHOLD" | bc -l)" == "1" ]]; then
        local reason="score_below_gold"
        reason="${reason}_${current_score}"
        echo "{\"decision\": \"evolve\", \"reason\": \"$reason\", \"score\": $current_score}"
        return
    fi
    
    if should_check_scheduled; then
        echo "{\"decision\": \"evolve\", \"reason\": \"scheduled\", \"score\": $current_score}"
        return
    fi
    
    local usage_summary
    local usage_tracker_path="$(dirname "${BASH_SOURCE[0]}")/usage_tracker.sh"
    usage_summary=$(source "$usage_tracker_path" && get_usage_summary "$skill_name" 7)
    
    local trigger_f1
    trigger_f1=$(echo "$usage_summary" | jq -r '.trigger_f1')
    local task_rate
    task_rate=$(echo "$usage_summary" | jq -r '.task_completion_rate')
    
    if [[ "$(echo "$trigger_f1 < 0.85" | bc -l)" == "1" ]] || [[ "$(echo "$task_rate < 0.80" | bc -l)" == "1" ]]; then
        echo "{\"decision\": \"evolve\", \"reason\": \"usage_metrics_low\", \"trigger_f1\": $trigger_f1, \"task_rate\": $task_rate, \"score\": $current_score}"
        return
    fi
    
    echo "{\"decision\": \"skip\", \"reason\": \"metrics_ok\", \"score\": $current_score, \"trigger_f1\": $trigger_f1, \"task_rate\": $task_rate}"
}

should_check_scheduled() {
    if [[ ! -f "$LAST_CHECK_FILE" ]]; then
        return 0
    fi
    
    local last_check
    last_check=$(cat "$LAST_CHECK_FILE")
    local last_check_epoch
    last_check_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$last_check" +%s 2>/dev/null || echo "0")
    local now_epoch
    now_epoch=$(date +%s)
    local hours_elapsed=$(( (now_epoch - last_check_epoch) / 3600 ))
    
    [[ $hours_elapsed -ge $CHECK_INTERVAL_HOURS ]] && return 0 || return 1
}

update_last_check() {
    echo "$(get_timestamp)" > "$LAST_CHECK_FILE"
}

get_evolution_recommendations() {
    local skill_file="$1"
    
    local skill_name
    skill_name=$(basename "$skill_file" .md)
    
    local usage_summary
    local usage_tracker_path="$(dirname "${BASH_SOURCE[0]}")/usage_tracker.sh"
    usage_summary=$(source "$usage_tracker_path" && get_usage_summary "$skill_name" 7)
    
    local trigger_f1
    trigger_f1=$(echo "$usage_summary" | jq -r '.trigger_f1')
    local task_rate
    task_rate=$(echo "$usage_summary" | jq -r '.task_completion_rate')
    local avg_feedback
    avg_feedback=$(echo "$usage_summary" | jq -r '.avg_feedback_rating')
    
    local recommendations=()
    
    if [[ "$(echo "$trigger_f1 < 0.90" | bc -l)" == "1" ]]; then
        recommendations+=("Improve trigger accuracy (current: $trigger_f1)")
    fi
    
    if [[ "$(echo "$task_rate < 0.85" | bc -l)" == "1" ]]; then
        recommendations+=("Improve task completion rate (current: $task_rate)")
    fi
    
    if [[ "$(echo "$avg_feedback < 3.5" | bc -l)" == "1" ]] && [[ "$(echo "$avg_feedback > 0" | bc -l)" == "1" ]]; then
        recommendations+=("Address user feedback issues (avg: $avg_feedback)")
    fi
    
    if [[ ${#recommendations[@]} -eq 0 ]]; then
        recommendations+=("All metrics look good, minor refinements only")
    fi
    
    local recs_json
    recs_json=$(printf '%s\n' "${recommendations[@]}" | jq -R . | jq -s .)
    
    jq -n \
        --argjson trigger_f1 "$trigger_f1" \
        --argjson task_rate "$task_rate" \
        --argjson avg_feedback "$avg_feedback" \
        --argjson count "${#recommendations[@]}" \
        --argjson recommendations "$recs_json" \
        '{"trigger_f1": $trigger_f1, "task_completion_rate": $task_rate, "avg_feedback": $avg_feedback, "recommendation_count": $count, "recommendations": $recommendations}'
}

main() {
    if [[ $# -lt 1 ]]; then
        echo "Usage: $0 <skill_file> [force]"
        echo "Example: $0 SKILL.md true"
        exit 1
    fi
    
    should_evolve "$1" "${2:-false}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi