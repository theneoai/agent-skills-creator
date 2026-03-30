#!/usr/bin/env bash
# swap_augmentation.sh - Position bias correction for multi-LLM evaluation
#
# Based on: Zheng et al. 2023 "Judging LLM-as-a-Judge with MT-Bench" (arXiv:2306.05685)
#
# Problem: When LLM-A and LLM-B evaluate in a fixed order, the first evaluator's
# framing can anchor the second. Swap augmentation runs two rounds with roles
# reversed and flags results that change direction as UNCERTAIN.
#
# Usage:
#   result=$(swap_augmented_eval "anthropic" "openai" "$skill_file" "$prompt")
#   confidence=$(echo "$result" | jq -r '.confidence')  # CONFIDENT | UNCERTAIN
#   verdict=$(echo "$result" | jq -r '.verdict')

if [[ -n "${_SWAP_AUGMENTATION_SOURCED:-}" ]]; then return 0; fi
export _SWAP_AUGMENTATION_SOURCED=1

# Run two-round swap evaluation between provider_a and provider_b.
# Returns JSON: {verdict, confidence, round1, round2, agreement}
swap_augmented_eval() {
    local provider_a="$1"
    local provider_b="$2"
    local skill_file="$3"
    local eval_prompt="$4"

    # Round 1: A evaluates first, B reviews
    local round1
    round1=$(_swap_single_round "$provider_a" "$provider_b" "$skill_file" "$eval_prompt" "round1")

    local verdict1
    verdict1=$(echo "$round1" | jq -r '.verdict // "unknown"')

    # Round 2: B evaluates first, A reviews (roles swapped)
    local round2
    round2=$(_swap_single_round "$provider_b" "$provider_a" "$skill_file" "$eval_prompt" "round2")

    local verdict2
    verdict2=$(echo "$round2" | jq -r '.verdict // "unknown"')

    # Determine confidence based on agreement
    local confidence agreement
    if [[ "$verdict1" == "$verdict2" ]]; then
        confidence="CONFIDENT"
        agreement="true"
    else
        confidence="UNCERTAIN"
        agreement="false"
    fi

    # Final verdict: use round1 if confident, flag UNCERTAIN if not
    local final_verdict
    if [[ "$confidence" == "CONFIDENT" ]]; then
        final_verdict="$verdict1"
    else
        final_verdict="UNCERTAIN:${verdict1}_vs_${verdict2}"
    fi

    jq -n \
        --arg verdict "$final_verdict" \
        --arg confidence "$confidence" \
        --arg agreement "$agreement" \
        --argjson r1 "$round1" \
        --argjson r2 "$round2" \
        '{
            verdict: $verdict,
            confidence: $confidence,
            agreement: ($agreement == "true"),
            round1: $r1,
            round2: $r2,
            method: "swap_augmentation"
        }'
}

_swap_single_round() {
    local primary_provider="$1"
    local reviewer_provider="$2"
    local skill_file="$3"
    local eval_prompt="$4"
    local round_id="$5"

    local content
    content=$(cat "$skill_file")

    local primary_system="You are an expert skill evaluator. Analyze the skill objectively."
    local primary_prompt="$eval_prompt

Skill content:
$content

Respond with JSON: {\"verdict\": \"pass|fail\", \"score\": X.X, \"reasoning\": \"...\"}"

    # Primary evaluation
    local primary_result
    primary_result=$(agent_call_llm "$primary_system" "$primary_prompt" "auto" "$primary_provider" 2>/dev/null || echo '{"verdict":"unknown","score":0,"reasoning":"LLM unavailable"}')

    local primary_verdict
    primary_verdict=$(echo "$primary_result" | jq -r '.verdict // "unknown"' 2>/dev/null || echo "unknown")

    # Reviewer cross-checks primary result
    local reviewer_system="You are a skill evaluation reviewer. Independently verify this assessment."
    local reviewer_prompt="An evaluator gave this assessment of a skill:
$primary_result

Please independently evaluate the same skill and state whether you agree.

Skill content:
$content

Respond with JSON: {\"verdict\": \"pass|fail\", \"agrees_with_primary\": true/false, \"reasoning\": \"...\"}"

    local reviewer_result
    reviewer_result=$(agent_call_llm "$reviewer_system" "$reviewer_prompt" "auto" "$reviewer_provider" 2>/dev/null || echo '{"verdict":"unknown","agrees_with_primary":false,"reasoning":"LLM unavailable"}')

    local reviewer_verdict
    reviewer_verdict=$(echo "$reviewer_result" | jq -r '.verdict // "unknown"' 2>/dev/null || echo "unknown")

    # Round verdict: unanimous if both agree
    local round_verdict
    if [[ "$primary_verdict" == "$reviewer_verdict" ]]; then
        round_verdict="$primary_verdict"
    else
        round_verdict="split"
    fi

    jq -n \
        --arg round "$round_id" \
        --arg primary "$primary_provider" \
        --arg reviewer "$reviewer_provider" \
        --arg verdict "$round_verdict" \
        --argjson pr "$primary_result" \
        --argjson rr "$reviewer_result" \
        '{
            round: $round,
            primary_provider: $primary,
            reviewer_provider: $reviewer,
            verdict: $verdict,
            primary_result: $pr,
            reviewer_result: $rr
        }'
}

# Convenience wrapper: returns true/false + confidence for simple pass/fail decisions
swap_eval_passthrough() {
    local provider_a="$1"
    local provider_b="$2"
    local skill_file="$3"
    local prompt="$4"

    local result
    result=$(swap_augmented_eval "$provider_a" "$provider_b" "$skill_file" "$prompt")

    local confidence verdict
    confidence=$(echo "$result" | jq -r '.confidence')
    verdict=$(echo "$result" | jq -r '.verdict')

    echo "VERDICT=$verdict"
    echo "CONFIDENCE=$confidence"

    if [[ "$confidence" == "UNCERTAIN" ]]; then
        return 2  # Signal: needs human review
    fi
    [[ "$verdict" == "pass" ]] && return 0 || return 1
}
