#!/usr/bin/env bash
# lean-orchestrator.sh - Lean, Fast, Cost-effective Skill Lifecycle
#
# Design Principles:
# 1. Fast Path: Parse + Heuristic scoring (no LLM)
# 2. LLM on-demand: Multi-LLM only for critical decisions
# 3. Parallel Execution: Independent dimensions run in parallel
# 4. Incremental: Only fix what needs fixing

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "${PROJECT_ROOT}/engine/lib/bootstrap.sh"
require constants concurrency errors integration

LEAN_LOG="${LOG_DIR}/lean.log"

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
    [[ $quant_count -ge 10 ]] && ((domain_score+=70)) || \
    [[ $quant_count -ge 5 ]] && ((domain_score+=50)) || \
    [[ $quant_count -ge 1 ]] && ((domain_score+=30))
    
    local phase_count
    phase_count=$(grep -cE '(Phase|Step|pipeline|流程|步骤)' "$skill_file" || true)
    [[ $phase_count -ge 3 ]] && ((workflow_score+=40)) || \
    [[ $phase_count -ge 1 ]] && ((workflow_score+=20))
    
    local fail_count
    fail_count=$(grep -cE '(failure|Fail|error|错误)' "$skill_file" || true)
    [[ $fail_count -ge 3 ]] && ((error_score+=30)) || \
    [[ $fail_count -ge 1 ]] && ((error_score+=15))
    
    local example_count
    example_count=$(grep -cE '(example|Example|示例|例子)' "$skill_file" || true)
    [[ $example_count -ge 5 ]] && ((example_score+=35)) || \
    [[ $example_count -ge 2 ]] && ((example_score+=20)) || \
    [[ $example_count -ge 1 ]] && ((example_score+=10))
    
    if grep -qE '^name:|^description:|^license:|^version:' "$skill_file"; then
        ((metadata_score+=20))
    fi
    
    local total=$((system_score + domain_score + workflow_score + error_score + example_score + metadata_score))
    
    echo "$total"
    
    log_lean "Text score: $total/350"
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
    
    local table_found=0
    if grep -qE '\| Mode ' "$skill_file"; then
        ((table_found++))
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
    
    [[ $runtime_score -gt 50 ]] && runtime_score=50
    
    echo "$runtime_score"
    
    log_lean "Runtime score: $runtime_score/50"
}

# ============================================================================
# MULTI-LLM DELIBERATION (Only when needed)
# ============================================================================

llm_deliberate() {
    local skill_file="$1"
    local dimension="$2"
    local prompt="$3"
    
    log_lean "LLM Deliberation: $dimension"
    
    local r1 r2 r3
    r1=$(call_llm "You are an expert skill evaluator." "$prompt" "auto" "kimi-code")
    r2=$(call_llm "You are an expert skill evaluator." "$prompt" "auto" "openai")
    
    local s1 s2
    s1=$(echo "$r1" | jq -r '.score // 0' 2>/dev/null || echo "0")
    s2=$(echo "$r2" | jq -r '.score // 0' 2>/dev/null || echo "0")
    
    local diff
    diff=$(echo "$s1 - $s2" | bc 2>/dev/null || echo "0")
    diff=${diff#-}
    
    if (( $(echo "$diff > 15" | bc -l) )); then
        log_lean "High disagreement ($diff), requesting third opinion"
        r3=$(call_llm "You are an expert skill evaluator." "$prompt" "auto" "anthropic")
        local s3
        s3=$(echo "$r3" | jq -r '.score // 0' 2>/dev/null || echo "0")
        
        local avg
        avg=$(echo "($s1 + $s2 + $s3) / 3" | bc -l)
        echo "$avg"
    else
        local avg
        avg=$(echo "($s1 + $s2) / 2" | bc -l)
        echo "$avg"
    fi
}

# ============================================================================
# FAST ITERATE (Creator fixes specific issues)
# ============================================================================

fast_iterate() {
    local skill_file="$1"
    local issues="$2"
    
    log_lean "Fast Iterate: Fixing specific issues"
    
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

    local response
    response=$(call_llm "You are an expert SKILL.md editor." "$fix_prompt" "auto" "kimi-code")
    
    local fixed_content
    fixed_content=$(echo "$response" | jq -r '.content // empty' 2>/dev/null || true)
    
    if [[ -n "$fixed_content" ]]; then
        echo "$fixed_content" > "$skill_file"
        log_lean "Fixed $issues_count issues"
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
    
    log_lean "CERTIFY: Total=$total"
    
    if [[ $total -ge 475 ]]; then
        echo "GOLD"
    elif [[ $total -ge 425 ]]; then
        echo "SILVER"
    elif [[ $total -ge 350 ]]; then
        echo "BRONZE"
    else
        echo "FAIL"
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
        GOLD) min_score=450 ;;
        SILVER) min_score=400 ;;
        BRONZE) min_score=350 ;;
        *) min_score=350 ;;
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
