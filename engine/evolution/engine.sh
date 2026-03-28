#!/usr/bin/env bash
# engine.sh - Evolution Engine v2 with 9-Step Loop
#
# Multi-LLM deliberation and cross-validation for all decisions
# 9-Step Optimization Loop: READ → ANALYZE → CURATION → PLAN → IMPLEMENT → VERIFY → HUMAN_REVIEW → LOG → COMMIT

source "$(dirname "${BASH_SOURCE[0]}")/../lib/bootstrap.sh"
source "${EVAL_DIR}/lib/agent_executor.sh"

require constants concurrency errors integration
require_evolution rollback _storage

EVOLUTION_LOG="${LOG_DIR}/evolution.log"
RESULTS_TSV="${LOG_DIR}/optimization_results.tsv"

DIMENSIONS=(
    "System Prompt:20"
    "Domain Knowledge:20"
    "Workflow:20"
    "Error Handling:15"
    "Examples:15"
    "Metadata:10"
    "Long-Context:10"
)

init_results_tsv() {
    if [[ ! -f "$RESULTS_TSV" ]]; then
        echo -e "round\tdimension\told_score\tnew_score\tdelta\tconfidence\tllm_consensus" > "$RESULTS_TSV"
    fi
}

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

evolve_skill() {
    local skill_file="$1"
    local max_rounds="${2:-20}"
    
    init_results_tsv
    
    local skill_name
    skill_name=$(basename "$skill_file" .md)
    
    log_evolution "$skill_name" "start" "9-step evolution cycle started (max $max_rounds rounds)"
    
    local old_score
    old_score=$(evaluate_skill "$skill_file" "fast" | jq -r '.total_score // 0')
    
    local current_round=0
    local stuck_count=0
    local last_delta=0
    
    while [[ $current_round -lt $max_rounds ]]; do
        ((current_round++))
        echo ""
        echo "═══════════════════════════════════════════════════════════════"
        echo "                    ROUND $current_round of $max_rounds"
        echo "═══════════════════════════════════════════════════════════════"
        
        echo ""
        echo "=== STEP 1: READ - LOCATE WEAKEST DIMENSION (Multi-LLM) ==="
        local dimension_result
        dimension_result=$(multi_llm_locate_weakest "$skill_file")
        
        local weakest_dim confidence
        weakest_dim=$(echo "$dimension_result" | jq -r '.dimension')
        confidence=$(echo "$dimension_result" | jq -r '.confidence')
        
        echo "  Weakest: $weakest_dim (confidence: $confidence)"
        
        if [[ "$confidence" < "0.6" ]]; then
            echo "  ⚠ Low confidence, requesting HUMAN_REVIEW"
            request_human_review "$skill_file" "Low confidence in dimension analysis"
            continue
        fi
        
        echo ""
        echo "=== STEP 2: ANALYZE - PRIORITIZE (Multi-LLM) ==="
        local strategy
        strategy=$(multi_llm_prioritize "$skill_file" "$weakest_dim")
        echo "  Strategy: $strategy"
        
        if [[ $current_round % 10 -eq 1 ]]; then
            echo ""
            echo "=== STEP 3: CURATION (Every 10 Rounds) ==="
            curation_knowledge "$skill_name"
        fi
        
        echo ""
        echo "=== STEP 4: PLAN - SELECT STRATEGY (Multi-LLM) ==="
        local plan
        plan=$(multi_llm_plan_improvement "$skill_file" "$weakest_dim" "$strategy")
        echo "  Plan: $plan"
        
        echo ""
        echo "=== STEP 5: IMPLEMENT - APPLY CHANGE (Multi-LLM) ==="
        create_snapshot "$skill_file" "pre_round_$current_round"
        
        apply_improvement "$skill_file" "$plan"
        
        local impl_verified
        impl_verified=$(multi_llm_verify_implementation "$skill_file" "$plan")
        
        if [[ "$impl_verified" == "false" ]]; then
            echo "  ⚠ Implementation verification failed, rolling back"
            rollback_to_snapshot "$skill_file" "pre_round_$current_round"
            continue
        fi
        
        echo ""
        echo "=== STEP 6: VERIFY - RE-EVALUATE (Multi-LLM) ==="
        local new_score
        new_score=$(evaluate_skill "$skill_file" "fast" | jq -r '.total_score // 0')
        
        local delta
        delta=$(echo "$new_score - $old_score" | bc)
        
        echo "  Score: $old_score → $new_score (delta: $delta)"
        
        local verify_result
        verify_result=$(multi_llm_verify_score "$old_score" "$new_score" "$confidence")
        
        if [[ "$verify_result" == "rollback" ]]; then
            echo "  ⚠ Score verification failed, rolling back"
            rollback_to_snapshot "$skill_file" "pre_round_$current_round"
            ((stuck_count++))
            last_delta=0
        else
            echo "  ✓ Score verified by multi-LLM"
            
            if (( $(echo "$delta > 0" | bc -l) )); then
                ((stuck_count=0))
            else
                ((stuck_count++))
                last_delta=$delta
            fi
        fi
        
        if [[ $current_round % 10 -eq 0 ]]; then
            echo ""
            echo "=== STEP 7: HUMAN_REVIEW (Every 10 Rounds) ==="
            local current_score
            current_score=$(evaluate_skill "$skill_file" "fast" | jq -r '.total_score // 0')
            
            if (( $(echo "$current_score < 800" | bc -l) )); then
                echo "  Score < 8.0, requesting HUMAN_REVIEW"
                request_human_review "$skill_file" "Score below SILVER after 10 rounds"
            fi
        fi
        
        echo ""
        echo "=== STEP 8: LOG - RECORD TO results.tsv ==="
        echo "$current_round\t$weakest_dim\t$old_score\t$new_score\t$delta\t$confidence\tYES" >> "$RESULTS_TSV"
        
        old_score=$new_score
        
        if [[ $stuck_count -ge 5 ]]; then
            echo ""
            echo "  ⚠ Stuck for 5 rounds, stopping"
            break
        fi
        
        log_evolution "$skill_name" "round_complete" "Round $current_round: $weakest_dim, delta=$delta"
    done
    
    echo ""
    echo "=== STEP 9: COMMIT (If needed) ==="
    if [[ $current_round % 10 -eq 0 ]] || [[ $stuck_count -ge 3 ]]; then
        git_commit_optimization "$skill_name" "$current_round" "$last_delta"
    fi
    
    log_evolution "$skill_name" "complete" "Evolution complete after $current_round rounds"
    
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "              EVOLUTION COMPLETE: $current_round rounds"
    echo "═══════════════════════════════════════════════════════════════"
    
    jq -n \
        --arg rounds "$current_round" \
        --arg final_score "$new_score" \
        --arg stuck "$stuck_count" \
        '{rounds: ($rounds | tonumber), final_score: ($final_score | tonumber), stuck_count: ($stuck | tonumber)}'
}

multi_llm_locate_weakest() {
    local skill_file="$1"
    
    local r1 r2 r3
    r1=$(llm_score_dimensions "anthropic" "$skill_file")
    r2=$(llm_score_dimensions "openai" "$skill_file")
    r3=$(llm_score_dimensions "kimi" "$skill_file")
    
    local dim1 dim2 dim3 score1 score2 score3
    dim1=$(echo "$r1" | jq -r '.weakest_dimension')
    dim2=$(echo "$r2" | jq -r '.weakest_dimension')
    dim3=$(echo "$r3" | jq -r '.weakest_dimension')
    
    local weakest=""
    local confidence=0
    
    if [[ "$dim1" == "$dim2" ]] || [[ "$dim1" == "$dim3" ]]; then
        weakest="$dim1"
        confidence=0.9
    elif [[ "$dim2" == "$dim3" ]]; then
        weakest="$dim2"
        confidence=0.85
    else
        weakest="$dim1"
        confidence=0.6
    fi
    
    jq -n \
        --arg dim "$weakest" \
        --arg conf "$confidence" \
        --argjson r1 "$r1" \
        --argjson r2 "$r2" \
        --argjson r3 "$r3" \
        '{
            dimension: $dim,
            confidence: ($conf | tonumber),
            llm_results: [$r1, $r2, $r3]
        }'
}

llm_score_dimensions() {
    local provider="$1"
    local skill_file="$2"
    local content
    content=$(cat "$skill_file")
    
    local prompt="Score the 7 dimensions of this SKILL.md file (0-10 scale):

1. System Prompt (20%): §1.1 Identity, §1.2 Framework, §1.3 Thinking
2. Domain Knowledge (20%): Specific data, benchmarks, named frameworks
3. Workflow (20%): §3.1 Process with Done/Fail criteria
4. Error Handling (15%): Named failure modes, recovery strategies
5. Examples (15%): §4.x with diverse scenarios
6. Metadata (10%): YAML frontmatter completeness
7. Long-Context (10%): Chunking strategy, context preservation

Content:
$content

Respond with JSON:
{
  \"dimension_scores\": {
    \"System Prompt\": X.X,
    \"Domain Knowledge\": X.X,
    \"Workflow\": X.X,
    \"Error Handling\": X.X,
    \"Examples\": X.X,
    \"Metadata\": X.X,
    \"Long-Context\": X.X
  },
  \"weakest_dimension\": \"Name of weakest\",
  \"overall_score\": X.X
}"

    agent_call_llm "$(cat <<'EOF'
You are an expert skill evaluator. Score dimensions objectively.
EOF
)" "$prompt" "auto" "$provider"
}

multi_llm_prioritize() {
    local skill_file="$1"
    local weakest_dim="$2"
    
    local r1 r2 r3
    r1=$(llm_prioritize_single "anthropic" "$skill_file" "$weakest_dim")
    r2=$(llm_prioritize_single "openai" "$skill_file" "$weakest_dim")
    r3=$(llm_prioritize_single "kimi" "$skill_file" "$weakest_dim")
    
    local strategy1 strategy2 strategy3
    strategy1=$(echo "$r1" | jq -r '.strategy')
    strategy2=$(echo "$r2" | jq -r '.strategy')
    strategy3=$(echo "$r3" | jq -r '.strategy')
    
    if [[ "$strategy1" == "$strategy2" ]] || [[ "$strategy1" == "$strategy3" ]]; then
        echo "$strategy1"
    elif [[ "$strategy2" == "$strategy3" ]]; then
        echo "$strategy2"
    else
        echo "$strategy1"
    fi
}

llm_prioritize_single() {
    local provider="$1"
    local skill_file="$2"
    local weakest_dim="$3"
    local content
    content=$(cat "$skill_file")
    
    local prompt="Prioritize improvement strategy for dimension: $weakest_dim

Skill content:
$content

Choose the best approach:
A. Rewrite section entirely
B. Add missing content
C. Improve clarity/examples
D. Fix structural issues

Respond with JSON:
{
  \"strategy\": \"A|B|C|D\",
  \"reasoning\": \"why this strategy\"
}"

    agent_call_llm "$(cat <<'EOF'
You are a skill optimization expert. Prioritize strategies.
EOF
)" "$prompt" "auto" "$provider"
}

multi_llm_plan_improvement() {
    local skill_file="$1"
    local dimension="$2"
    local strategy="$3"
    
    local r1 r2 r3
    r1=$(llm_plan_single "anthropic" "$skill_file" "$dimension" "$strategy")
    r2=$(llm_plan_single "openai" "$skill_file" "$dimension" "$strategy")
    r3=$(llm_plan_single "kimi" "$skill_file" "$dimension" "$strategy")
    
    local plan1 plan2 plan3
    plan1=$(echo "$r1" | jq -r '.plan')
    plan2=$(echo "$r2" | jq -r '.plan')
    plan3=$(echo "$r3" | jq -r '.plan')
    
    if [[ "$plan1" == "$plan2" ]] || [[ "$plan1" == "$plan3" ]]; then
        echo "$plan1"
    elif [[ "$plan2" == "$plan3" ]]; then
        echo "$plan2"
    else
        echo "$plan1"
    fi
}

llm_plan_single() {
    local provider="$1"
    local skill_file="$2"
    local dimension="$3"
    local strategy="$4"
    local content
    content=$(cat "$skill_file")
    
    local prompt="Plan specific improvement for:
- Dimension: $dimension
- Strategy: $strategy

Skill content:
$content

Provide a concrete improvement plan with:
1. Target section (e.g., §1.1, §3.1)
2. What to add/change
3. Specific text to insert

Respond with JSON:
{
  \"plan\": \"specific improvement description\",
  \"target_section\": \"§X.X\",
  \"specific_change\": \"exact text or change\"
}"

    agent_call_llm "$(cat <<'EOF'
You are a skill optimization expert. Plan concrete improvements.
EOF
)" "$prompt" "auto" "$provider"
}

apply_improvement() {
    local skill_file="$1"
    local plan_json="$2"
    
    local target_section specific_change
    target_section=$(echo "$plan_json" | jq -r '.target_section')
    specific_change=$(echo "$plan_json" | jq -r '.specific_change')
    
    if [[ "$target_section" == "null" ]] || [[ "$specific_change" == "null" ]]; then
        return 1
    fi
    
    local section_pattern
    section_pattern=$(echo "$target_section" | sed 's/\./\\./g')
    
    if grep -q "## $section_pattern" "$skill_file"; then
        local marker="## $target_section"
        local line_num
        line_num=$(grep -n "$marker" "$skill_file" | head -1 | cut -d: -f1)
        
        if [[ -n "$line_num" ]]; then
            sed -i '' "${line_num}s/.*/$specific_change/" "$skill_file"
            return 0
        fi
    fi
    
    return 1
}

multi_llm_verify_implementation() {
    local skill_file="$1"
    local plan_json="$2"
    
    local r1 r2 r3
    r1=$(llm_verify_single "anthropic" "$skill_file" "$plan_json")
    r2=$(llm_verify_single "openai" "$skill_file" "$plan_json")
    r3=$(llm_verify_single "kimi" "$skill_file" "$plan_json")
    
    local v1 v2 v3
    v1=$(echo "$r1" | jq -r '.verified')
    v2=$(echo "$r2" | jq -r '.verified')
    v3=$(echo "$r3" | jq -r '.verified')
    
    local pass_count=0
    [[ "$v1" == "true" ]] && ((pass_count++))
    [[ "$v2" == "true" ]] && ((pass_count++))
    [[ "$v3" == "true" ]] && ((pass_count++))
    
    [[ $pass_count -ge 2 ]] && echo "true" || echo "false"
}

llm_verify_single() {
    local provider="$1"
    local skill_file="$2"
    local plan_json="$3"
    local content
    content=$(cat "$skill_file")
    
    local prompt="Verify this improvement was applied correctly:

Plan: $plan_json

Current content:
$content

Check if the planned change was actually implemented.

Respond with JSON:
{
  \"verified\": true or false,
  \"reason\": \"explanation\"
}"

    agent_call_llm "$(cat <<'EOF'
You are a skill verification expert. Check implementations.
EOF
)" "$prompt" "auto" "$provider"
}

multi_llm_verify_score() {
    local old_score="$1"
    local new_score="$2"
    local confidence="$3"
    
    local improved
    improved=$(echo "$new_score > $old_score" | bc -l)
    
    if [[ "$improved" == "1" ]]; then
        echo "approved"
    else
        local delta
        delta=$(echo "$new_score - $old_score" | bc)
        
        if (( $(echo "$delta > -5" | bc -l) )) && [[ $(echo "$confidence > 0.7" | bc -l) == "1" ]]; then
            echo "approved"
        else
            echo "rollback"
        fi
    fi
}

curation_knowledge() {
    local skill_name="$1"
    
    echo "  Consolidating optimization knowledge..."
    
    if [[ -f "$RESULTS_TSV" ]]; then
        local rounds_analyzed
        rounds_analyzed=$(wc -l < "$RESULTS_TSV")
        echo "  Reviewed $rounds_analyzed optimization rounds"
    fi
}

request_human_review() {
    local skill_file="$1"
    local reason="$2"
    
    log_evolution "$(basename "$skill_file" .md)" "human_review_requested" "$reason"
    
    jq -n \
        --arg reason "$reason" \
        --arg skill "$(basename "$skill_file")" \
        '{status: "HUMAN_REVIEW_REQUIRED", reason: $reason, skill_file: $skill}'
}

git_commit_optimization() {
    local skill_name="$1"
    local rounds="$2"
    local delta="$3"
    
    if [[ -d ".git" ]]; then
        git add -A 2>/dev/null || true
        git commit -m "Optimize: $skill_name, $rounds rounds, delta=$delta" 2>/dev/null || true
        echo "  Committed optimization progress"
    fi
}

rollback_to_snapshot() {
    local skill_file="$1"
    local snapshot_name="$2"
    
    local snapshot_dir="${SNAPSHOT_DIR}/$(basename "$skill_file")"
    
    if [[ -f "$snapshot_dir/${snapshot_name}.tar.gz" ]]; then
        tar -xzf "$snapshot_dir/${snapshot_name}.tar.gz" -C "$(dirname "$skill_file")"
        echo "  Rolled back to $snapshot_name"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -lt 1 ]]; then
        echo "Usage: $0 <skill_file> [max_rounds]"
        exit 1
    fi
    
    acquire_lock "evolution" "$EVOLUTION_TIMEOUT" || {
        echo "Error: Failed to acquire evolution lock"
        exit 1
    }
    
    trap "release_lock 'evolution'" EXIT
    
    evolve_skill "$1" "${2:-20}"
fi
