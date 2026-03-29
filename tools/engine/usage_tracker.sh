#!/usr/bin/env bash
# usage_tracker.sh - Track skill usage data for learn-from-usage

source "$(dirname "${BASH_SOURCE[0]}")/../lib/bootstrap.sh"

USAGE_TRACKER_VERSION="1.0"

init_usage_file() {
    local skill_name="$1"
    local date
    date=$(date +%Y%m%d)
    local usage_file="${EVOLUTION_USAGE_DIR}/usage_${skill_name}_${date}.jsonl"
    
    if [[ ! -f "$usage_file" ]]; then
        : > "$usage_file"
    fi
}

track_trigger() {
    local skill_name="$1"
    local expected_mode="$2"
    local actual_mode="$3"
    
    local date
    date=$(date +%Y%m%d_%H%M%S)
    local usage_file="${EVOLUTION_USAGE_DIR}/usage_${skill_name}_$(date +%Y%m%d).jsonl"
    
    local correct="false"
    [[ "$expected_mode" == "$actual_mode" ]] && correct="true"
    
    jq -cn \
        --arg ts "$(get_timestamp)" \
        --arg skill "$skill_name" \
        --arg type "trigger" \
        --arg expected "$expected_mode" \
        --arg actual "$actual_mode" \
        --arg correct "$correct" \
        '{timestamp: $ts, skill: $skill, event_type: $type, expected_mode: $expected, actual_mode: $actual, correct: ($correct == "true")}' \
        >> "$usage_file"
}

track_task() {
    local skill_name="$1"
    local task_type="$2"
    local completed="$3"
    local rounds="${4:-1}"
    
    local usage_file="${EVOLUTION_USAGE_DIR}/usage_${skill_name}_$(date +%Y%m%d).jsonl"
    
    jq -cn \
        --arg ts "$(get_timestamp)" \
        --arg skill "$skill_name" \
        --arg type "task" \
        --arg task_type "$task_type" \
        --arg completed "$completed" \
        --arg rounds "$rounds" \
        '{timestamp: $ts, skill: $skill, event_type: $type, task_type: $task_type, completed: ($completed == "true"), rounds: ($rounds | tonumber)}' \
        >> "$usage_file"
}

track_feedback() {
    local skill_name="$1"
    local rating="$2"
    local comment="${3:-}"
    
    local usage_file="${EVOLUTION_USAGE_DIR}/usage_${skill_name}_$(date +%Y%m%d).jsonl"
    
    jq -cn \
        --arg ts "$(get_timestamp)" \
        --arg skill "$skill_name" \
        --arg type "feedback" \
        --arg rating "$rating" \
        --arg comment "$comment" \
        '{timestamp: $ts, skill: $skill, event_type: $type, rating: ($rating | tonumber), comment: $comment}' \
        >> "$usage_file"
}

get_usage_summary() {
    local skill_name="$1"
    local days="${2:-7}"
    
    local total_triggers=0 correct_triggers=0
    local total_tasks=0 completed_tasks=0
    local total_feedback=0 avg_rating=0
    
    for ((i=0; i<days; i++)); do
        local date
        date=$(date -v-${i}d +%Y%m%d 2>/dev/null || date -d "-${i} days" +%Y%m%d)
        local usage_file="${EVOLUTION_USAGE_DIR}/usage_${skill_name}_${date}.jsonl"
        
        [[ ! -f "$usage_file" ]] && continue
        
        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            local event_type
            event_type=$(echo "$line" | jq -r '.event_type')
            
            case "$event_type" in
                trigger)
                    ((total_triggers++))
                    local correct
                    correct=$(echo "$line" | jq -r '.correct')
                    [[ "$correct" == "true" ]] && ((correct_triggers++))
                    ;;
                task)
                    ((total_tasks++))
                    local completed
                    completed=$(echo "$line" | jq -r '.completed')
                    [[ "$completed" == "true" ]] && ((completed_tasks++))
                    ;;
                feedback)
                    ((total_feedback++))
                    local rating
                    rating=$(echo "$line" | jq -r '.rating')
                    avg_rating=$(echo "$avg_rating + $rating" | bc)
                    ;;
            esac
        done < "$usage_file"
    done
    
    local trigger_f1=0
    [[ $total_triggers -gt 0 ]] && trigger_f1=$(echo "scale=4; $correct_triggers / $total_triggers" | bc)
    
    local task_rate=0
    [[ $total_tasks -gt 0 ]] && task_rate=$(echo "scale=4; $completed_tasks / $total_tasks" | bc)
    
    local feedback_avg=0
    [[ $total_feedback -gt 0 ]] && feedback_avg=$(echo "scale=2; $avg_rating / $total_feedback" | bc)
    
    jq -n \
        --argjson trigger_f1 "$trigger_f1" \
        --argjson task_rate "$task_rate" \
        --argjson feedback_avg "$feedback_avg" \
        --argjson total_triggers "$total_triggers" \
        --argjson correct_triggers "$correct_triggers" \
        --argjson total_tasks "$total_tasks" \
        --argjson completed_tasks "$completed_tasks" \
        --argjson total_feedback "$total_feedback" \
        '{
            trigger_f1: $trigger_f1,
            task_completion_rate: $task_rate,
            avg_feedback_rating: $feedback_avg,
            stats: {
                triggers: {total: $total_triggers, correct: $correct_triggers},
                tasks: {total: $total_tasks, completed: $completed_tasks},
                feedback: {count: $total_feedback}
            }
        }'
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Usage Tracker v${USAGE_TRACKER_VERSION}"
    echo "Usage: source usage_tracker.sh and call track_* functions"
fi