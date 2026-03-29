#!/usr/bin/env bash
# _state.sh - 状态管理

# ============================================================================
# Guard against re-sourcing
# ============================================================================

if [[ -n "${_STATE_SOURCED:-}" ]]; then
    return 0
fi
export _STATE_SOURCED=1

# ============================================================================
# 全局状态变量 (全部导出以便子进程访问)
# ============================================================================

export INITIAL_PROMPT=""
export TARGET_SKILL_FILE=""
export TARGET_TIER="${TARGET_TIER:-BRONZE}"
export MAX_ITERATIONS=20
export CURRENT_SECTION=0
export EVALUATION_COUNT=0
export LAST_SCORE=0
export ITERATION_COUNT=0
export CREATOR_SOURCED=0
export EVALUATOR_SOURCED=0
export DRY_RUN="${DRY_RUN:-0}"
export VERBOSE="${VERBOSE:-0}"

# ============================================================================
# 状态函数
# ============================================================================

state_init() {
    INITIAL_PROMPT=""
    TARGET_SKILL_FILE=""
    TARGET_TIER="${TARGET_TIER:-BRONZE}"
    MAX_ITERATIONS=20
    CURRENT_SECTION=0
    EVALUATION_COUNT=0
    LAST_SCORE=0
    ITERATION_COUNT=0
    CREATOR_SOURCED=0
    EVALUATOR_SOURCED=0
}

state_set_prompt() {
    INITIAL_PROMPT="$1"
}

state_set_target_file() {
    TARGET_SKILL_FILE="$1"
}

state_set_tier() {
    TARGET_TIER="$1"
}

state_inc_iteration() {
    ITERATION_COUNT=$((ITERATION_COUNT + 1))
}

state_inc_evaluation() {
    EVALUATION_COUNT=$((EVALUATION_COUNT + 1))
}

state_inc_section() {
    CURRENT_SECTION=$((CURRENT_SECTION + 1))
}

state_set_last_score() {
    LAST_SCORE="$1"
}

state_get_context() {
    jq -n \
        --arg prompt "$INITIAL_PROMPT" \
        --arg section "$CURRENT_SECTION" \
        --arg tier "$TARGET_TIER" \
        --arg iteration "$ITERATION_COUNT" \
        --arg eval_count "$EVALUATION_COUNT" \
        '{
            user_prompt: $prompt,
            current_section: ($section | tonumber),
            target_tier: $tier,
            iteration: ($iteration | tonumber),
            eval_count: ($eval_count | tonumber)
        }'
}

state_dump() {
    echo "=== State ==="
    echo "PROMPT: $INITIAL_PROMPT"
    echo "TARGET: $TARGET_SKILL_FILE"
    echo "TIER: $TARGET_TIER"
    echo "SECTION: $CURRENT_SECTION"
    echo "EVAL_COUNT: $EVALUATION_COUNT"
    echo "LAST_SCORE: $LAST_SCORE"
    echo "ITERATION: $ITERATION_COUNT"
    echo "==========="
}