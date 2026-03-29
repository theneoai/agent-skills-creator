#!/usr/bin/env bash
# lean-orchestrator.sh - Lean, Fast, Cost-effective Skill Lifecycle
#
# ============================================================================
# ARCHITECTURE: Lean vs Eval
# ============================================================================
#
# This script implements the LEAN evaluation path - fast, heuristic-based
# scoring for rapid iteration during development.
#
# | Path    | Purpose              | Speed  | LLM | Use Case              |
# |---------|----------------------|--------|-----|------------------------|
# | LEAN    | Fast pre-evaluation  | ~0s    | No  | Dev feedback, CI       |
# | EVAL    | Final certification  | ~30s   | Yes | Release, formal review |
#
# LEAN Output: Estimated tier, directional improvement hints
# EVAL Output: Certified tier, F1/MRR metrics, formal report
#
# Design Principles:
# 1. Fast Path: Parse + Heuristic scoring (no LLM)
# 2. LLM on-demand: Multi-LLM only for critical decisions
# 3. Parallel Execution: Independent dimensions run in parallel
# 4. Incremental: Only fix what needs fixing
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "${PROJECT_ROOT}/engine/lib/bootstrap.sh"
require constants concurrency errors integration

source "${EVAL_DIR}/lib/agent_executor.sh"

source "${EVAL_DIR}/lib/unified_scoring.sh"

LEAN_LOG="${LOG_DIR}/lean.log"

get_provider_strength() {
    local provider="$1"
    case "$provider" in
        anthropic) echo 100 ;;
        openai) echo 90 ;;
        kimi-code) echo 85 ;;
        minimax) echo 80 ;;
        kimi) echo 75 ;;
        *) echo 0 ;;
    esac
}

select_top_providers() {
    local available providers_map sorted
    available=$(check_llm_available)
    
    if [[ "$available" == "none" ]] || [[ -z "$available" ]]; then
        echo ""
        return
    fi
    
    declare -A providers_map
    while read -r provider; do
        [[ -z "$provider" ]] && continue
        providers_map["$provider"]=$(get_provider_strength "$provider")
    done <<< "$available"
    
    sorted=$(for p in "${!providers_map[@]}"; do
        echo "${providers_map[$p]} $p"
    done | sort -rn | head -2)
    
    echo "$sorted" | awk '{print $2}' | tr '\n' ' ' | sed 's/ $//'
}

log_lean() {
    echo "[LEAN $(date +%H:%M:%S)] $1" >&2
}

# ============================================================================
# PHASE 1: FAST PARSE (No LLM - ~100ms)
# ============================================================================

fast_parse() {
    local skill_file="$1"
    
    log_lean "PHASE 1: Fast Parse"
    
    local yaml_front=0 sections=0 triggers=0 placeholders=0
    
    if grep -q "^---" "$skill_file" && \
       grep -qE "^name:" "$skill_file" && \
       grep -qE "^description:" "$skill_file" && \
       grep -qE "^license:" "$skill_file"; then
        yaml_front=30
    fi
    
    local s11 s12 s13
    s11=$(grep -cE '§1\.1|1\.1 Identity' "$skill_file" || true)
    s12=$(grep -cE '§1\.2|1\.2 Framework' "$skill_file" || true)
    s13=$(grep -cE '§1\.3|1\.3 Thinking' "$skill_file" || true)
    
    [[ $s11 -gt 0 ]] && ((sections+=10))
    [[ $s12 -gt 0 ]] && ((sections+=10))
    [[ $s13 -gt 0 ]] && ((sections+=10))
    
    local trigger_count
    trigger_count=$(grep -cE 'CREATE|EVALUATE|OPTIMIZE|RESTORE|SECURITY' "$skill_file" || true)
    [[ $trigger_count -ge 5 ]] && ((triggers+=25)) || ((triggers+=10))
    
    local placeholder_count
    placeholder_count=$(grep -cE '\[TODO\]|\[FIXME\]|TBD|undefined' "$skill_file" || true)
    [[ $placeholder_count -eq 0 ]] && ((placeholders+=15)) || ((placeholders+=5))
    
    local parse_score=$((yaml_front + sections + triggers + placeholders))
    
    echo "$parse_score"
    
    log_lean "Parse score: $parse_score/100"
}

# ============================================================================
# PHASE 2: TEXT SCORE (Heuristic - No LLM - ~200ms)
# ============================================================================

text_score_heuristic() {
    local skill_file="$1"
    
    log_lean "PHASE 2: Text Score (Heuristic)"
    
    local system_score=0 domain_score=0 workflow_score=0
    local error_score=0 example_score=0 metadata_score=0
    
    if grep -qE '(^|\n)## §1\.' "$skill_file"; then
        ((system_score+=20))
        log_lean "  Found §1.x sections"
    fi
    if grep -qE '(never|always|forbidden|must|shall)' "$skill_file"; then
        ((system_score+=10))
        log_lean "  Found principle keywords"
    fi
    
    local quant_count
    quant_count=$(grep -cE '[0-9]+\.[0-9]+%|[0-9]+%|\$[0-9]+|NIST|OWASP|ISO|SECURITY|F1|MRR' "$skill_file" || true)
    log_lean "  Quant count: $quant_count"
    if [[ $quant_count -ge 10 ]]; then
        ((domain_score+=70))
    elif [[ $quant_count -ge 5 ]]; then
        ((domain_score+=50))
    elif [[ $quant_count -ge 1 ]]; then
        ((domain_score+=30))
    fi
    
    local phase_count
    phase_count=$(grep -cE '(Phase|Step|pipeline|流程|步骤)' "$skill_file" || true)
    if [[ $phase_count -ge 3 ]]; then
        ((workflow_score+=40))
    elif [[ $phase_count -ge 1 ]]; then
        ((workflow_score+=20))
    fi
    
    local fail_count
    fail_count=$(grep -cE '(failure|Fail|error|错误)' "$skill_file" || true)
    if [[ $fail_count -ge 3 ]]; then
        ((error_score+=30))
    elif [[ $fail_count -ge 1 ]]; then
        ((error_score+=15))
    fi
    
    local example_count
    example_count=$(grep -cE '(example|Example|示例|例子)' "$skill_file" || true)
    if [[ $example_count -ge 5 ]]; then
        ((example_score+=35))
    elif [[ $example_count -ge 2 ]]; then
        ((example_score+=20))
    elif [[ $example_count -ge 1 ]]; then
        ((example_score+=10))
    fi
    
    if grep -qE '^name:|^description:|^license:|^version:' "$skill_file"; then
        ((metadata_score+=20))
    fi
    
    local cross_ref_score=0
    if grep -qE 'reference/triggers\.md' "$skill_file" && [[ -f "${PROJECT_ROOT}/reference/triggers.md" ]]; then
        ((cross_ref_score+=25))
    fi
    if grep -qE 'reference/workflows\.md' "$skill_file" && [[ -f "${PROJECT_ROOT}/reference/workflows.md" ]]; then
        ((cross_ref_score+=25))
    fi
    if grep -qE 'reference/tools\.md' "$skill_file" && [[ -f "${PROJECT_ROOT}/reference/tools.md" ]]; then
        ((cross_ref_score+=25))
    fi
    if grep -qE 'Progressive Disclosure' "$skill_file" && grep -qE 'reference/' "$skill_file"; then
        ((cross_ref_score+=25))
    fi
    
    local evolution_score=0
    if grep -qE '## §6\. Self-Evolution|§6 Self-Evolution' "$skill_file"; then
        ((evolution_score+=25))
    fi
    if grep -qE 'usage_tracker|usage tracking|使用追踪' "$skill_file"; then
        ((evolution_score+=15))
    fi
    if grep -qE 'evolve_decider|evolution trigger|进化触发' "$skill_file"; then
        ((evolution_score+=15))
    fi
    
    local total=$((system_score + domain_score + workflow_score + error_score + example_score + metadata_score + cross_ref_score + evolution_score))
    
    echo "$total"
    
    log_lean "Text score: $total/350"
}

# ============================================================================
# SEMANTIC CHECK (Validate content consistency)
# ============================================================================

semantic_check() {
    local skill_file="$1"
    
    log_lean "SEMANTIC CHECK: Validating content consistency"
    
    local issues=0
    
    if grep -qE '§1\.' "$skill_file"; then
        if ! grep -qE '§1\.1|§1\.2|§1\.3' "$skill_file"; then
            log_lean "  WARNING: §1.x exists but §1.1/§1.2/§1.3 missing"
            ((issues++))
        fi
    fi
    
    if grep -qE 'trigger|trigger' "$skill_file"; then
        local trigger_count
        trigger_count=$(grep -ciE '(CREATE|EVALUATE|OPTIMIZE|RESTORE|SECURITY)' "$skill_file" || echo "0")
        if [[ $trigger_count -lt 3 ]]; then
            log_lean "  WARNING: Trigger keywords mentioned but few actual triggers"
            ((issues++))
        fi
    fi
    
    if grep -qE 'error|fail|exception' "$skill_file"; then
        if ! grep -qE '(retry|handle|recover|catch)' "$skill_file"; then
            log_lean "  WARNING: Error mentions without handling"
            ((issues++))
        fi
    fi
    
    if grep -qE 'example|示例' "$skill_file"; then
        if ! grep -qE '```' "$skill_file"; then
            log_lean "  WARNING: Examples mentioned but no code blocks"
            ((issues++))
        fi
    fi
    
    log_lean "Semantic issues found: $issues"
    echo "$issues"
}

# ============================================================================
# PHASE 3: RUNTIME TEST (Fast - Check trigger patterns)
# ============================================================================

runtime_test_fast() {
    local skill_file="$1"
    
    log_lean "PHASE 3: Runtime Test (Trigger Patterns)"
    
    local runtime_score=0
    
    if grep -qE '## §2\.' "$skill_file"; then
        ((runtime_score+=20))
        log_lean "  Found §2 Invocation section"
    fi
    
    if grep -qE '\| CREATE ' "$skill_file"; then
        ((runtime_score+=5))
    fi
    if grep -qE '\| EVALUATE ' "$skill_file"; then
        ((runtime_score+=5))
    fi
    if grep -qE '\| OPTIMIZE ' "$skill_file"; then
        ((runtime_score+=5))
    fi
    if grep -qE '\| RESTORE ' "$skill_file"; then
        ((runtime_score+=5))
    fi
    if grep -qE '\| SECURITY ' "$skill_file"; then
        ((runtime_score+=5))
    fi
    
    if grep -qE '(workflow|process|步骤|流程)' "$skill_file"; then
        ((runtime_score+=5))
    fi
    
    if grep -qE '(trigger|keyword|keyword|触发)' "$skill_file"; then
        ((runtime_score+=40))
        log_lean "  Found trigger pattern accuracy indicators"
    fi
    
    if grep -qE '(EN|ZH|bilingual|双语)' "$skill_file"; then
        ((runtime_score+=15))
        log_lean "  Found bilingual trigger support"
    fi
    
    if grep -qE '(Progressive Disclosure|≤400|reference/)' "$skill_file"; then
        ((runtime_score+=20))
        log_lean "  Found progressive disclosure reference"
    fi
    
    if grep -qE '(Self-Evolution|auto-evolve|threshold|scheduled)' "$skill_file"; then
        ((runtime_score+=25))
        log_lean "  Found self-evolution triggers"
    fi
    
    [[ $runtime_score -gt 150 ]] && runtime_score=150
    
    echo "$runtime_score"
    
    log_lean "Runtime score: $runtime_score/150"
}

# ============================================================================
# MULTI-LLM DELIBERATION (kimi-code + minimax cross-validation)
# ============================================================================

llm_deliberate() {
    local skill_file="$1"
    local dimension="$2"
    local prompt="$3"
    
    log_lean "LLM Deliberation: $dimension"
    log_lean "Using kimi-code + minimax for cross-validation"
    
    local kimi_result minimax_result
    kimi_result=$(call_llm "You are an expert skill evaluator." "$prompt" "auto" "kimi-code" 2>/dev/null || echo '{"score": 0}')
    minimax_result=$(call_llm "You are an expert skill evaluator." "$prompt" "auto" "minimax" 2>/dev/null || echo '{"score": 0}')
    
    local kimi_score minimax_score
    kimi_score=$(echo "$kimi_result" | jq -r '.score // 0' 2>/dev/null || echo "0")
    minimax_score=$(echo "$minimax_result" | jq -r '.score // 0' 2>/dev/null || echo "0")
    
    log_lean "kimi-code score: $kimi_score, minimax score: $minimax_score"
    
    local diff
    diff=$(echo "$kimi_score - $minimax_score" | bc 2>/dev/null || echo "0")
    diff=${diff#-}
    
    if [[ "$(echo "$diff > 15" | bc -l)" == "1" ]]; then
        log_lean "High disagreement ($diff), requesting third opinion"
        local third_result
        third_result=$(call_llm "You are an expert skill evaluator." "$prompt" "auto" "openai" 2>/dev/null || echo '{"score": 0}')
        local third_score
        third_score=$(echo "$third_result" | jq -r '.score // 0' 2>/dev/null || echo "0")
        
        log_lean "Third opinion (openai): $third_score"
        
        local avg
        avg=$(echo "($kimi_score + $minimax_score + $third_score) / 3" | bc -l)
        echo "$avg"
    else
        local avg
        avg=$(echo "($kimi_score + $minimax_score) / 2" | bc -l)
        echo "$avg"
    fi
}

# ============================================================================
# FAST ITERATE (Creator fixes specific issues)
# ============================================================================

fast_iterate() {
    local skill_file="$1"
    local issues="$2"
    
    log_lean "Fast Iterate: Fixing specific issues (kimi-code + minimax)"
    
    local issues_count
    issues_count=$(echo "$issues" | jq 'length' 2>/dev/null || echo "0")
    
    if [[ "$issues_count" -eq 0 ]]; then
        return 0
    fi
    
    local fix_prompt="Fix these issues in $skill_file:

$(echo "$issues" | jq -r '.[] | "- \(.issue): \(.suggestion)"' 2>/dev/null || echo "$issues")

Current content:
$(cat "$skill_file")

Return JSON with fixed content: {\"content\": \"<fixed SKILL.md>\"}"

    local kimi_response minimax_response
    kimi_response=$(call_llm "You are an expert SKILL.md editor." "$fix_prompt" "auto" "kimi-code")
    minimax_response=$(call_llm "You are an expert SKILL.md editor." "$fix_prompt" "auto" "minimax")
    
    local kimi_content minimax_content
    kimi_content=$(echo "$kimi_response" | jq -r '.content // empty' 2>/dev/null || true)
    minimax_content=$(echo "$minimax_response" | jq -r '.content // empty' 2>/dev/null || true)
    
    if [[ -n "$kimi_content" ]] && [[ "$kimi_content" == "$minimax_content" ]]; then
        echo "$kimi_content" > "$skill_file"
        log_lean "Fixed $issues_count issues (cross-validated)"
    elif [[ -n "$kimi_content" ]]; then
        echo "$kimi_content" > "$skill_file"
        log_lean "Fixed $issues_count issues (kimi-code)"
    elif [[ -n "$minimax_content" ]]; then
        echo "$minimax_content" > "$skill_file"
        log_lean "Fixed $issues_count issues (minimax)"
    fi
}

# ============================================================================
# CERTIFY (Final tier determination)
# ============================================================================

certify() {
    local parse_score="$1"
    local text_score="$2"
    local runtime_score="$3"
    
    local total=$((parse_score + text_score + runtime_score))
    local normalized_total=$(echo "scale=0; $total * $LEAN_TO_STANDARD / 1" | bc)
    
    log_lean "CERTIFY: Total=$total (normalized: $normalized_total)"
    
    if [[ $normalized_total -ge $LEAN_TIER_PLATINUM ]]; then
        echo "PLATINUM"
    elif [[ $normalized_total -ge $LEAN_TIER_GOLD_NORM ]]; then
        echo "GOLD"
    elif [[ $normalized_total -ge $LEAN_TIER_SILVER_NORM ]]; then
        echo "SILVER"
    elif [[ $normalized_total -ge $LEAN_TIER_BRONZE_NORM ]]; then
        echo "BRONZE"
    else
        echo "NOT_CERTIFIED"
    fi
}

# ============================================================================
# MAIN ORCHESTRATION
# ============================================================================

main() {
    local skill_file="$1"
    local target_tier="${2:-BRONZE}"
    
    log_lean "START: Lean orchestration for $skill_file"
    
    local start_time
    start_time=$(date +%s)
    
    log_lean "=== PHASE 0: Create/Load ==="
    if [[ ! -f "$skill_file" ]]; then
        log_lean "File not found, need to create"
        return 1
    fi
    
    log_lean "=== PHASE 1-3: Parallel Fast Evaluation ==="
    local parse_score text_score runtime_score
    
    parse_score=$(fast_parse "$skill_file")
    
    text_score=$(text_score_heuristic "$skill_file")
    
    runtime_score=$(runtime_test_fast "$skill_file")
    
    log_lean "Scores: Parse=$parse_score Text=$text_score Runtime=$runtime_score"
    
    log_lean "=== PHASE 4: Decide ==="
    local total=$((parse_score + text_score + runtime_score))
    
    local min_score
    case "$target_tier" in
        PLATINUM) min_score=950 ;;
        GOLD) min_score=900 ;;
        SILVER) min_score=800 ;;
        BRONZE) min_score=700 ;;
        *) min_score=700 ;;
    esac
    
    if [[ $total -ge $min_score ]]; then
        log_lean "PASS: Score $total >= $min_score"
        local tier
        tier=$(certify "$parse_score" "$text_score" "$runtime_score")
        echo "{\"status\":\"PASS\",\"tier\":\"$tier\",\"parse\":$parse_score,\"text\":$text_score,\"runtime\":$runtime_score,\"total\":$total}"
    else
        log_lean "BELOW THRESHOLD: $total < $min_score"
        echo "{\"status\":\"NEEDS_IMPROVEMENT\",\"parse\":$parse_score,\"text\":$text_score,\"runtime\":$runtime_score,\"total\":$total}"
    fi
    
    local end_time
    end_time=$(date +%s)
    local elapsed=$((end_time - start_time))
    
    log_lean "COMPLETE in ${elapsed}s"
}

main "$@"
