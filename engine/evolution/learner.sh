#!/usr/bin/env bash
# learner.sh - Extract patterns from usage data to guide optimization

source "$(dirname "${BASH_SOURCE[0]}")/../lib/bootstrap.sh"
source "${EVAL_DIR}/lib/agent_executor.sh"

LEARNER_VERSION="1.0"

PATTERNS_DIR="${EVOLUTION_USAGE_DIR}/patterns"
KNOWLEDGE_DIR="${EVOLUTION_USAGE_DIR}/knowledge"

init_learner_dirs() {
    mkdir -p "$PATTERNS_DIR" "$KNOWLEDGE_DIR"
}

learn_from_usage() {
    local skill_file="$1"
    local rounds="${2:-10}"
    
    init_learner_dirs
    
    local skill_name
    skill_name=$(basename "$skill_file" .md)
    
    local usage_summary
    local usage_tracker_path="$(dirname "${BASH_SOURCE[0]}")/usage_tracker.sh"
    usage_summary=$(source "$usage_tracker_path" && get_usage_summary "$skill_name" "$rounds")
    
    local patterns_file="${PATTERNS_DIR}/${skill_name}_patterns.json"
    
    local trigger_f1
    trigger_f1=$(echo "$usage_summary" | jq -r '.trigger_f1')
    local task_rate
    task_rate=$(echo "$usage_summary" | jq -r '.task_completion_rate')
    
    local weak_triggers=()
    local failed_tasks=()
    
    for ((i=0; i<rounds; i++)); do
        local date
        date=$(date -v-${i}d +%Y%m%d 2>/dev/null || date -d "-${i} days" +%Y%m%d)
        local usage_file="${EVOLUTION_USAGE_DIR}/usage_${skill_name}_${date}.jsonl"
        
        [[ ! -f "$usage_file" ]] && continue
        
        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            local event_type correct
            event_type=$(echo "$line" | jq -r '.event_type')
            
            if [[ "$event_type" == "trigger" ]]; then
                correct=$(echo "$line" | jq -r '.correct')
                if [[ "$correct" == "false" ]]; then
                    local expected actual
                    expected=$(echo "$line" | jq -r '.expected_mode')
                    actual=$(echo "$line" | jq -r '.actual_mode')
                    weak_triggers+=("${expected}->${actual}")
                fi
            fi
            
            if [[ "$event_type" == "task" ]]; then
                local completed
                completed=$(echo "$line" | jq -r '.completed')
                if [[ "$completed" == "false" ]]; then
                    local task_type
                    task_type=$(echo "$line" | jq -r '.task_type')
                    failed_tasks+=("$task_type")
                fi
            fi
        done < "$usage_file"
    done
    
    local weak_triggers_json="[]"
    local failed_tasks_json="[]"
    
    if [[ ${#weak_triggers[@]} -gt 0 ]]; then
        weak_triggers_json=$(printf '%s\n' "${weak_triggers[@]}" | jq -R . | jq -s .)
    fi
    
    if [[ ${#failed_tasks[@]} -gt 0 ]]; then
        failed_tasks_json=$(printf '%s\n' "${failed_tasks[@]}" | jq -R . | jq -s .)
    fi
    
    local patterns
    patterns=$(jq -n \
        --arg skill "$skill_name" \
        --argjson trigger_f1 "$trigger_f1" \
        --argjson task_rate "$task_rate" \
        --argjson weak_triggers_count "${#weak_triggers[@]}" \
        --argjson failed_tasks_count "${#failed_tasks[@]}" \
        --argjson analyzed_days "$rounds" \
        --argjson weak_triggers "$weak_triggers_json" \
        --argjson failed_tasks "$failed_tasks_json" \
        '{
            skill: $skill,
            metrics: {
                trigger_f1: $trigger_f1,
                task_completion_rate: $task_rate
            },
            patterns: {
                weak_triggers: $weak_triggers,
                failed_task_types: $failed_tasks
            },
            analysis_days: $analyzed_days,
            generated_at: (now | strftime("%Y-%m-%dT%H:%M:%SZ"))
        }')
    
    echo "$patterns" > "$patterns_file"
    echo "$patterns"
}

get_improvement_hints() {
    local patterns_file="$1"
    
    local skill_name
    skill_name=$(basename "$patterns_file" _patterns.json)
    
    local patterns
    patterns=$(cat "$patterns_file")
    
    local trigger_f1
    trigger_f1=$(echo "$patterns" | jq -r '.metrics.trigger_f1')
    local task_rate
    task_rate=$(echo "$patterns" | jq -r '.metrics.task_completion_rate')
    
    local hints=()
    
    if [[ "$(echo "$trigger_f1 < 0.85" | bc -l)" != "0" ]] && [[ -n "$trigger_f1" ]]; then
        local weak_triggers
        weak_triggers=$(echo "$patterns" | jq -r '.patterns.weak_triggers | join(", ")')
        hints+=("Trigger confusion detected: $weak_triggers. Consider adding disambiguation examples.")
    fi
    
    if [[ "$(echo "$task_rate < 0.80" | bc -l)" == "1" ]]; then
        hints+=("Task completion issues detected. Review workflow steps and error handling.")
    fi
    
    if [[ ${#hints[@]} -eq 0 ]]; then
        hints+=("No specific issues found. Continue normal optimization.")
    fi
    
    local hints_json
    hints_json=$(printf '%s\n' "${hints[@]}" | jq -R . | jq -s .)
    
    jq -n \
        --arg skill "$skill_name" \
        --argjson hint_count "${#hints[@]}" \
        --argjson hints "$hints_json" \
        '{"skill": $skill, "hint_count": $hint_count, "hints": $hints}'
}

consolidate_knowledge() {
    local skill_name="$1"
    
    init_learner_dirs
    
    local patterns_file="${PATTERNS_DIR}/${skill_name}_patterns.json"
    local knowledge_file="${KNOWLEDGE_DIR}/${skill_name}_knowledge.md"
    
    if [[ ! -f "$patterns_file" ]]; then
        echo "# Knowledge for $skill_name

No data yet." > "$knowledge_file"
        return
    fi
    
    local patterns
    patterns=$(cat "$patterns_file")
    
    local trigger_f1
    trigger_f1=$(echo "$patterns" | jq -r '.metrics.trigger_f1')
    local task_rate
    task_rate=$(echo "$patterns" | jq -r '.metrics.task_completion_rate')
    local generated_at
    generated_at=$(echo "$patterns" | jq -r '.generated_at')
    
    cat > "$knowledge_file" << EOF
# Knowledge Consolidation: $skill_name

Generated: $generated_at

## Performance Metrics

| Metric | Value | Status |
|--------|-------|--------|
| Trigger F1 | $trigger_f1 | $([ "$(echo "$trigger_f1 >= 0.90" | bc)" == "1" ] && echo "GOOD" || echo "NEEDS_IMPROVEMENT") |
| Task Completion | $task_rate | $([ "$(echo "$task_rate >= 0.85" | bc)" == "1" ] && echo "GOOD" || echo "NEEDS_IMPROVEMENT") |

## Usage Patterns

### Weak Triggers
$(echo "$patterns" | jq -r '.patterns.weak_triggers | if length > 0 then . | to_entries | .[].value | "- \(.)" else "- None detected" end')

### Failed Task Types
$(echo "$patterns" | jq -r '.patterns.failed_task_types | if length > 0 then . | to_entries | .[].value | "- \(.)" else "- None detected" end')

## Recommendations

$(get_improvement_hints "$patterns_file" | jq -r '.hints | to_entries | .[].value | "- \(.value)"')
EOF
    
    echo "$knowledge_file"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Learner v${LEARNER_VERSION}"
    echo "Usage: source learner.sh and call learn_from_usage, get_improvement_hints, consolidate_knowledge"
fi