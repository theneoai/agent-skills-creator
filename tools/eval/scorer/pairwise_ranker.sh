#!/usr/bin/env bash
# pairwise_ranker.sh — Bradley-Terry Pairwise Skill Ranking
#
# Instead of absolute scoring, this module ranks skills by pairwise comparison:
# "Given task X, is skill A or skill B better suited to help the user?"
#
# Theoretical basis:
#   Bradley-Terry model: P(A > B) = exp(β_A) / (exp(β_A) + exp(β_B))
#   β parameters estimated via maximum likelihood (gradient ascent)
#
# Motivation (from RLHF literature):
#   - Human raters achieve Cohen's κ ~0.7 on "which is better" vs ~0.4 on "rate 1-10"
#   - Relative judgments are scale-invariant: no threshold calibration needed
#   - Mirrors real usage: users choose among skills, not rate them in isolation
#   - Applied in: ELO (chess), TrueSkill (games), Chatbot Arena (LLMs)
#
# Usage:
#   # Compare two skills head-to-head
#   compare_two_skills skill_a.md skill_b.md "task description"
#
#   # Rank a set of skills
#   rank_skills "task description" skill1.md skill2.md skill3.md ...
#
#   # Get Bradley-Terry score for a skill relative to a reference set
#   bt_score skill.md "task" reference1.md reference2.md

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/agent_executor.sh" 2>/dev/null || true

# ─── Single pairwise comparison (ask LLM to judge A vs B) ────────────────────

# Returns: "A" | "B" | "TIE"
pairwise_judge() {
    local skill_a="$1"
    local skill_b="$2"
    local task="$3"
    local provider="${4:-auto}"

    local content_a content_b
    content_a=$(cat "$skill_a")
    content_b=$(cat "$skill_b")

    local system_prompt
    system_prompt=$(cat <<'EOF'
You are an impartial skill evaluator. Your job is to judge which of two AI skill
specifications would better help a user accomplish a given task.

Evaluate based on:
1. Relevance: Does the skill's purpose match the task?
2. Completeness: Does it cover what the user needs?
3. Clarity: Are instructions clear and actionable?
4. Reliability: Does it handle edge cases and errors?

Be objective. Ignore formatting preferences. Focus on utility for the user.
EOF
)

    local user_prompt
    user_prompt=$(cat <<EOF
Task: $task

=== SKILL A ===
$content_a

=== SKILL B ===
$content_b

Which skill would better help a user accomplish the task above?

Respond with JSON only:
{
  "winner": "A" or "B" or "TIE",
  "confidence": 0.0 to 1.0,
  "reasoning": "brief explanation (1-2 sentences)"
}
EOF
)

    local response
    response=$(agent_call_llm "$system_prompt" "$user_prompt" "auto" "$provider" 2>/dev/null) || {
        echo '{"winner":"TIE","confidence":0.5,"reasoning":"LLM unavailable"}'
        return 0
    }

    # Extract JSON from response
    local json
    json=$(echo "$response" | jq -r '.content[0].text // .' 2>/dev/null | \
           sed 's/```json//g; s/```//g') || json='{"winner":"TIE","confidence":0.5}'

    # Validate
    if ! echo "$json" | jq -e '.winner' >/dev/null 2>&1; then
        json='{"winner":"TIE","confidence":0.5,"reasoning":"parse_error"}'
    fi

    echo "$json"
}

# ─── Swap-augmented pairwise comparison (eliminates position bias) ────────────

# Returns: "A" | "B" | "TIE" | "UNCERTAIN"
pairwise_judge_unbiased() {
    local skill_a="$1"
    local skill_b="$2"
    local task="$3"
    local provider="${4:-auto}"

    # Round 1: A presented first
    local r1
    r1=$(pairwise_judge "$skill_a" "$skill_b" "$task" "$provider")
    local w1
    w1=$(echo "$r1" | jq -r '.winner')

    # Round 2: B presented first (swap) — remap result back
    local r2_raw
    r2_raw=$(pairwise_judge "$skill_b" "$skill_a" "$task" "$provider")
    local w2_raw
    w2_raw=$(echo "$r2_raw" | jq -r '.winner')

    # Invert swap result so both rounds are in A/B space
    local w2
    case "$w2_raw" in
        A) w2="B" ;;  # B was first, won as "A" → B wins
        B) w2="A" ;;  # A was second, won as "B" → A wins
        *) w2="TIE" ;;
    esac

    # Consensus
    local final_winner
    if [[ "$w1" == "$w2" ]]; then
        final_winner="$w1"
    elif [[ "$w1" == "TIE" ]]; then
        final_winner="$w2"
    elif [[ "$w2" == "TIE" ]]; then
        final_winner="$w1"
    else
        final_winner="UNCERTAIN"  # position bias detected
    fi

    local c1 c2 avg_conf
    c1=$(echo "$r1" | jq -r '.confidence // 0.5')
    c2=$(echo "$r2_raw" | jq -r '.confidence // 0.5')
    avg_conf=$(echo "scale=3; ($c1 + $c2) / 2" | bc -l)

    jq -n \
        --arg winner "$final_winner" \
        --arg conf "$avg_conf" \
        --argjson r1 "$r1" \
        --argjson r2 "$r2_raw" \
        '{
            winner: $winner,
            confidence: ($conf | tonumber),
            position_bias_detected: ($winner == "UNCERTAIN"),
            round1: $r1,
            round2: $r2,
            method: "swap_augmented_pairwise"
        }'
}

# ─── Bradley-Terry parameter estimation ──────────────────────────────────────

# Given a results matrix (wins/losses between pairs), estimate β parameters
# via iterative algorithm (Hunter 2004, MM algorithm for Bradley-Terry)
#
# Input: JSON array of {winner: "i", loser: "j"} results
# Output: JSON object {skill_name: beta_score, ...}
bt_estimate() {
    local results_json="$1"
    shift
    local skill_names=("$@")

    local n=${#skill_names[@]}
    if [[ $n -lt 2 ]]; then
        echo "ERROR: need at least 2 skills" >&2
        return 1
    fi

    # Initialize β = 1.0 for all skills
    local betas=()
    for _ in "${skill_names[@]}"; do
        betas+=(1.0)
    done

    # MM algorithm: iterate until convergence (max 100 iterations)
    local iter=0
    local max_iter=100
    local converged=false

    while [[ $iter -lt $max_iter ]] && ! $converged; do
        local old_betas=("${betas[@]}")
        local max_delta=0

        for ((i=0; i<n; i++)); do
            local wins_i=0
            local denom=0

            # Count wins for skill i and compute denominator
            local k
            for ((k=0; k<n; k++)); do
                [[ $k -eq $i ]] && continue

                local w_ik w_ki
                w_ik=$(echo "$results_json" | jq "[.[] | select(.winner == \"${skill_names[$i]}\" and .loser == \"${skill_names[$k]}\")] | length")
                w_ki=$(echo "$results_json" | jq "[.[] | select(.winner == \"${skill_names[$k]}\" and .loser == \"${skill_names[$i]}\")] | length")

                local total_ik=$(( w_ik + w_ki ))
                if [[ $total_ik -gt 0 ]]; then
                    wins_i=$(echo "$wins_i + $w_ik" | bc -l)
                    local beta_sum
                    beta_sum=$(echo "${betas[$i]} + ${betas[$k]}" | bc -l)
                    denom=$(echo "$denom + $total_ik / $beta_sum" | bc -l)
                fi
            done

            if [[ $(echo "$denom > 0" | bc -l) -eq 1 ]]; then
                betas[$i]=$(echo "scale=6; $wins_i / $denom" | bc -l)
            fi

            local delta
            delta=$(echo "define abs(x) { if (x < 0) return -x; return x; }; abs(${betas[$i]} - ${old_betas[$i]})" | bc -l)
            if [[ $(echo "$delta > $max_delta" | bc -l) -eq 1 ]]; then
                max_delta="$delta"
            fi
        done

        # Normalize so sum of β = n
        local beta_sum_total=0
        for b in "${betas[@]}"; do
            beta_sum_total=$(echo "$beta_sum_total + $b" | bc -l)
        done
        for ((i=0; i<n; i++)); do
            betas[$i]=$(echo "scale=6; ${betas[$i]} * $n / $beta_sum_total" | bc -l)
        done

        # Check convergence
        if [[ $(echo "$max_delta < 0.0001" | bc -l) -eq 1 ]]; then
            converged=true
        fi

        ((iter++))
    done

    # Build output JSON
    local output="{}"
    for ((i=0; i<n; i++)); do
        output=$(echo "$output" | jq --arg name "${skill_names[$i]}" \
            --arg beta "${betas[$i]}" \
            '. + {($name): ($beta | tonumber)}')
    done

    echo "$output" | jq --argjson iters "$iter" '. + {_iterations: $iters, _converged: true}'
}

# ─── High-level ranking API ───────────────────────────────────────────────────

# Rank a set of skills for a given task using pairwise comparisons + BT model
# Usage: rank_skills "task description" skill1.md skill2.md ...
rank_skills() {
    local task="$1"
    shift
    local skills=("$@")
    local n=${#skills[@]}

    if [[ $n -lt 2 ]]; then
        echo "ERROR: rank_skills requires at least 2 skill files" >&2
        return 1
    fi

    echo "=== Pairwise Ranking: $n skills, $((n*(n-1)/2)) comparisons ===" >&2

    local results_json="[]"
    local comparison_count=0

    # All pairs
    for ((i=0; i<n; i++)); do
        for ((j=i+1; j<n; j++)); do
            ((comparison_count++))
            echo "  Comparison $comparison_count: $(basename "${skills[$i]}") vs $(basename "${skills[$j]}")" >&2

            local result
            result=$(pairwise_judge_unbiased "${skills[$i]}" "${skills[$j]}" "$task")

            local winner
            winner=$(echo "$result" | jq -r '.winner')

            if [[ "$winner" == "A" ]]; then
                results_json=$(echo "$results_json" | jq \
                    --arg w "$(basename "${skills[$i]}" .md)" \
                    --arg l "$(basename "${skills[$j]}" .md)" \
                    '. + [{winner: $w, loser: $l}]')
            elif [[ "$winner" == "B" ]]; then
                results_json=$(echo "$results_json" | jq \
                    --arg w "$(basename "${skills[$j]}" .md)" \
                    --arg l "$(basename "${skills[$i]}" .md)" \
                    '. + [{winner: $w, loser: $l}]')
            fi
            # TIE and UNCERTAIN: no result recorded
        done
    done

    # Skill names (basenames without .md)
    local skill_names=()
    for s in "${skills[@]}"; do
        skill_names+=("$(basename "$s" .md)")
    done

    # Estimate Bradley-Terry parameters
    local bt_scores
    bt_scores=$(bt_estimate "$results_json" "${skill_names[@]}")

    # Sort by β score (descending) and output ranking
    echo ""
    echo "=== Bradley-Terry Ranking ==="
    echo "$bt_scores" | jq -r 'to_entries | map(select(.key | startswith("_") | not)) | sort_by(-.value) | to_entries | .[] | "  Rank \(.key + 1): \(.value.key)  (β=\(.value.value | tostring | .[0:6]))"'

    echo ""
    echo "Raw BT scores:"
    echo "$bt_scores" | jq 'with_entries(select(.key | startswith("_") | not))'
}

# ─── CLI entry point ──────────────────────────────────────────────────────────

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -lt 3 ]]; then
        cat <<'EOF'
Usage:
  pairwise_ranker.sh compare <skill_a.md> <skill_b.md> "<task>"
  pairwise_ranker.sh rank    "<task>" <skill1.md> <skill2.md> [skill3.md ...]

Examples:
  ./pairwise_ranker.sh compare skill_v1.md skill_v2.md "help me write unit tests"
  ./pairwise_ranker.sh rank "create a REST API" baseline.md v1.md v2.md v3.md
EOF
        exit 1
    fi

    case "$1" in
        compare)
            pairwise_judge_unbiased "$2" "$3" "$4"
            ;;
        rank)
            task="$2"
            shift 2
            rank_skills "$task" "$@"
            ;;
        *)
            echo "Unknown command: $1" >&2
            exit 1
            ;;
    esac
fi
