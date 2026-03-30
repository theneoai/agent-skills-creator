#!/usr/bin/env bash
# cost_tracker.sh - API token usage tracking and cost circuit breaker
#
# Records per-call token usage, accumulates run cost, and aborts if budget exceeded.
# Supports Anthropic, OpenAI, Kimi, MiniMax pricing tiers.

if [[ -n "${_COST_TRACKER_SOURCED:-}" ]]; then return 0; fi
export _COST_TRACKER_SOURCED=1

# Default budget: $5 USD per evolution run. Override via env var.
COST_BUDGET_USD="${COST_BUDGET_USD:-5.0}"

# Per-1K-token pricing (USD), input / output
declare -A _COST_INPUT_PER_1K=(
    [claude-sonnet-4]=0.003
    [claude-haiku-4]=0.00025
    [gpt-4o]=0.005
    [gpt-4o-mini]=0.00015
    [moonshot-v1-8k]=0.001
    [kimi-for-coding]=0.001
    [MiniMax-M2.7-highspeed]=0.0008
)
declare -A _COST_OUTPUT_PER_1K=(
    [claude-sonnet-4]=0.015
    [claude-haiku-4]=0.00125
    [gpt-4o]=0.015
    [gpt-4o-mini]=0.0006
    [moonshot-v1-8k]=0.003
    [kimi-for-coding]=0.003
    [MiniMax-M2.7-highspeed]=0.002
)

COST_LOG_FILE="${COST_LOG_FILE:-/tmp/skill_cost_$$.log}"
_COST_ACCUMULATED=0

cost_tracker_record() {
    local provider="$1"
    local model="$2"
    local input_tokens="${3:-0}"
    local output_tokens="${4:-0}"

    # Normalize model to pricing key (strip version suffixes)
    local model_key="$model"
    if [[ "$model" == claude-sonnet* ]]; then model_key="claude-sonnet-4"; fi
    if [[ "$model" == claude-haiku* ]]; then model_key="claude-haiku-4"; fi
    if [[ "$model" == gpt-4o-mini* ]]; then model_key="gpt-4o-mini"; fi
    if [[ "$model" == gpt-4o* ]]; then model_key="gpt-4o"; fi

    local price_in="${_COST_INPUT_PER_1K[$model_key]:-0.002}"
    local price_out="${_COST_OUTPUT_PER_1K[$model_key]:-0.008}"

    local call_cost
    call_cost=$(echo "scale=6; ($input_tokens * $price_in / 1000) + ($output_tokens * $price_out / 1000)" | bc -l)

    _COST_ACCUMULATED=$(echo "scale=6; $_COST_ACCUMULATED + $call_cost" | bc -l)

    # Append JSON line to cost log
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    printf '{"ts":"%s","provider":"%s","model":"%s","in":%d,"out":%d,"cost_usd":%.6f,"total_usd":%.6f}\n' \
        "$timestamp" "$provider" "$model" "$input_tokens" "$output_tokens" "$call_cost" "$_COST_ACCUMULATED" \
        >> "$COST_LOG_FILE"
}

cost_tracker_check_budget() {
    local over
    over=$(echo "$_COST_ACCUMULATED > $COST_BUDGET_USD" | bc -l)
    if [[ "$over" == "1" ]]; then
        echo "COST_BUDGET_EXCEEDED: accumulated=\$$_COST_ACCUMULATED budget=\$$COST_BUDGET_USD" >&2
        echo "  Cost log: $COST_LOG_FILE" >&2
        return 1
    fi
    return 0
}

cost_tracker_summary() {
    echo "=== API Cost Summary ==="
    echo "  Accumulated: \$$_COST_ACCUMULATED"
    echo "  Budget:      \$$COST_BUDGET_USD"
    if [[ -f "$COST_LOG_FILE" ]]; then
        local calls
        calls=$(wc -l < "$COST_LOG_FILE")
        echo "  Total calls: $calls"
        echo "  Log file:    $COST_LOG_FILE"
    fi
}
