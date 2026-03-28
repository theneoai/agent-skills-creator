#!/usr/bin/env bash
# _workflow.sh - 工作流控制

source "$(dirname "${BASH_SOURCE[0]}")/../lib/bootstrap.sh"
require constants concurrency errors integration
require_evolution rollback

# ============================================================================
# 工作流初始化
# ============================================================================

workflow_init() {
    local user_prompt="$1"
    local output_file="$2"
    local parent_skill="${3:-}"
    
    state_set_prompt "$user_prompt"
    state_set_target_file "$output_file"
    
    if [[ -f "$TARGET_SKILL_FILE" ]]; then
        create_snapshot "$TARGET_SKILL_FILE" "init"
    fi
    
    mkdir -p "$(dirname "$TARGET_SKILL_FILE")"
    touch "$TARGET_SKILL_FILE"
    
    if [[ -n "$parent_skill" ]]; then
        creator_init_skill_file "$TARGET_SKILL_FILE" "$(basename "$TARGET_SKILL_FILE" .md)" "$parent_skill"
    fi
    
    echo "Workflow initialized: $TARGET_SKILL_FILE"
    echo "Target tier: $TARGET_TIER"
}

# ============================================================================
# Creator Agent 执行
# ============================================================================

workflow_run_creator() {
    local evaluator_feedback="${1:-}"
    
    if [[ $CREATOR_SOURCED -eq 0 ]]; then
        source "${EVAL_DIR_FROM_ENGINE}/agents/creator.sh"
        CREATOR_SOURCED=1
    fi
    
    local context_file
    context_file=$(mktemp /tmp/creator_context_XXXXXX.json)
    jq -n \
        --arg prompt "$INITIAL_PROMPT" \
        --arg section "$CURRENT_SECTION" \
        --arg feedback "$evaluator_feedback" \
        '{user_prompt: $prompt, current_section: ($section | tonumber), evaluator_feedback: $feedback}' \
        > "$context_file"
    
    local result
    result=$(creator_generate "$context_file")
    local exit_code=$?
    
    rm -f "$context_file"
    
    if [[ $exit_code -eq 0 ]]; then
        echo "$result"
        return 0
    fi
    return 1
}

# ============================================================================
# Evaluator Agent 执行
# ============================================================================

workflow_run_evaluator() {
    if [[ $EVALUATOR_SOURCED -eq 0 ]]; then
        source "${EVAL_DIR_FROM_ENGINE}/agents/evaluator.sh"
        EVALUATOR_SOURCED=1
    fi
    
    local result
    result=$(evaluator_evaluate_file "$TARGET_SKILL_FILE" "$CURRENT_SECTION")
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        echo "$result"
        return 0
    fi
    return 1
}

# ============================================================================
# 内容追加
# ============================================================================

workflow_append_content() {
    local new_content="$1"
    
    if [[ -n "$new_content" ]] && [[ "$new_content" != "{}" ]]; then
        if [[ "$DRY_RUN" == "1" ]]; then
            echo "[DRY RUN] Would append content to $TARGET_SKILL_FILE"
        else
            with_lock "skill_file" "$SKILL_FILE_TIMEOUT" append_content_to_file "$TARGET_SKILL_FILE" "$new_content" || {
                log_error "LOCK_FAILED" "Failed to acquire skill_file lock" "workflow_append_content"
                return 1
            }
        fi
        return 0
    fi
    return 1
}

append_content_to_file() {
    local skill_file="$1"
    local new_content="$2"
    
    if [[ -f "$skill_file" ]]; then
        echo "" >> "$skill_file"
    fi
    echo "$new_content" >> "$skill_file"
}

# ============================================================================
# 主工作流
# ============================================================================

workflow_run() {
    if [[ "$DRY_RUN" == "1" ]]; then
        echo "DRY RUN MODE - No changes will be made"
    fi
    
    local skill_name
    skill_name=$(basename "$TARGET_SKILL_FILE" .md)
    local evaluator_feedback=""
    
    while true; do
        state_inc_iteration
        echo ""
        echo "=== Iteration $ITERATION_COUNT (Section $CURRENT_SECTION) ==="
        
        if [[ "$DRY_RUN" != "1" ]]; then
            create_snapshot "$TARGET_SKILL_FILE" "pre_creator"
        fi
        
        local new_content
        new_content=$(workflow_run_creator "$evaluator_feedback")
        
        if [[ -n "$new_content" ]]; then
            workflow_append_content "$new_content"
        fi
        
        local eval_result
        eval_result=$(workflow_run_evaluator)
        
        if [[ -n "$eval_result" ]] && [[ "$eval_result" != "{}" ]]; then
            local score tier suggestions
            score=$(echo "$eval_result" | jq -r '.score // 0')
            tier=$(echo "$eval_result" | jq -r '.tier // "UNKNOWN"')
            suggestions=$(echo "$eval_result" | jq -r '.suggestions // ""')
            
            state_inc_evaluation
            state_set_last_score "$score"
            
            echo "  Score: $score ($tier)"
            
            local action
            action=$(workflow_get_next_action "$score" "$tier")
            
            case "$action" in
                done)
                    echo "  Completion reached"
                    break
                    ;;
                continue)
                    state_inc_section
                    evaluator_feedback=""
                    continue
                    ;;
                improve)
                    evaluator_feedback="$suggestions"
                    if workflow_check_evolution_trigger; then
                        echo "  Evolution triggered"
                        workflow_trigger_evolution
                    fi
                    continue
                    ;;
            esac
        else
            handle_error "EVAL_FAILURE" "Evaluator returned empty result" "workflow_run"
            evaluator_feedback="Please fix the format and content issues."
        fi
        
        if [[ $ITERATION_COUNT -ge $MAX_ITERATIONS ]]; then
            echo "Max iterations reached"
            break
        fi
    done
    
    workflow_final_evaluate
}

workflow_final_evaluate() {
    local final_result
    final_result=$(evaluate_skill "$TARGET_SKILL_FILE" "full")
    
    if [[ -n "$final_result" ]]; then
        local final_score tier
        final_score=$(echo "$final_result" | jq -r '.total_score // 0')
        tier=$(echo "$final_result" | jq -r '.tier // "UNKNOWN"')
        
        log_usage "$(basename "$TARGET_SKILL_FILE" .md)" "$final_score" "$tier" "$ITERATION_COUNT"
        
        echo ""
        echo "=== Final Result ==="
        echo "Score: $final_score"
        echo "Tier: $tier"
        
        jq -n \
            --arg score "$final_score" \
            --arg tier "$tier" \
            --arg iterations "$ITERATION_COUNT" \
            '{final_score: ($score | tonumber), final_tier: $tier, iterations: ($iterations | tonumber)}'
    fi
}