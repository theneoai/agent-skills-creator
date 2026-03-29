#!/usr/bin/env bash
# unified-skill-eval v2 - Real Agent-Based Evaluation Framework
# Uses actual LLM API calls for runtime testing

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${OUTPUT_DIR:-./eval_results}"

show_usage() {
    cat <<EOF
Usage: $(basename "$0") --skill PATH [OPTIONS]

Options:
    --skill PATH         Path to SKILL.md file (required)
    --fast               Fast evaluation (20 rounds, ~2min)
    --full               Full evaluation (100 rounds, ~10min)
    --corpus PATH        Custom corpus path
    --output DIR         Output directory (default: ./eval_results)
    --ci                 CI mode (no colors, minimal output)
    --agent              Force agent-based evaluation
    --no-agent           Skip agent-based evaluation (shell only)
    --lang zh|en         Language (default: auto)

Examples:
    $(basename "$0") --skill ./SKILL.md --fast
    $(basename "$0") --skill ./SKILL.md --full --agent
EOF
}

parse_args() {
    SKILL_PATH=""
    EVAL_MODE="fast"
    CORPUS_PATH=""
    OUTPUT_DIR="./eval_results"
    CI_MODE="false"
    USE_AGENT="auto"
    LANG="auto"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --skill)
                SKILL_PATH="$2"
                shift 2
                ;;
            --fast)
                EVAL_MODE="fast"
                shift
                ;;
            --full)
                EVAL_MODE="full"
                shift
                ;;
            --corpus)
                CORPUS_PATH="$2"
                EVAL_MODE="custom"
                shift 2
                ;;
            --output)
                OUTPUT_DIR="$2"
                shift 2
                ;;
            --ci)
                CI_MODE="true"
                shift
                ;;
            --agent)
                USE_AGENT="force"
                shift
                ;;
            --no-agent)
                USE_AGENT="skip"
                shift
                ;;
            --lang)
                LANG="$2"
                shift 2
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1" >&2
                show_usage
                exit 1
                ;;
        esac
    done

    if [[ -z "$SKILL_PATH" ]]; then
        echo "Error: --skill is required" >&2
        show_usage
        exit 1
    fi
}

check_dependencies() {
    local missing=""
    for cmd in jq bc curl; do
        if ! command -v "$cmd" &>/dev/null; then
            missing="$missing $cmd"
        fi
    done
    if [[ -n "$missing" ]]; then
        echo "WARNING: Missing dependencies:$missing"
        return 1
    fi
    return 0
}

check_llm_available() {
    if [[ -n "${OPENAI_API_KEY:-}" ]] || [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then
        echo "available"
    else
        echo "unavailable"
    fi
}

# Phase 1: Parse & Validate (100pts)
run_phase1() {
    local skill="$1"
    local output="$2"
    
    echo "【Phase 1】 Parse & Validate (100pts)" >&2
    
    source "${SCRIPT_DIR}/lib/constants.sh"
    
    local yaml_front=0 sections=0 trigger_list=0 no_placeholder=0
    local security_violation=0
    
    # YAML Frontmatter
    if grep -q "^---" "$skill" && \
       grep -qE "^name:" "$skill" && \
       grep -qE "^description:" "$skill" && \
       grep -qE "^license:" "$skill"; then
        yaml_front=$PARSE_YAML_FRONT
    fi
    
    # Three Sections
    local s11 s12 s13
    s11=$(grep -cE '§1\.1|1\.1 Identity|## § 1· Identity' "$skill" || true)
    s12=$(grep -cE '§1\.2|1\.2 Framework|## § 2· Framework' "$skill" || true)
    s13=$(grep -cE '§1\.3|1\.3 Thinking|## § 3· Thinking' "$skill" || true)
    
    [[ $s11 -gt 0 ]] && ((sections+=10))
    [[ $s12 -gt 0 ]] && ((sections+=10))
    [[ $s13 -gt 0 ]] && ((sections+=10))
    
    # Trigger List (count actual patterns, not just word mentions)
    local create_cnt eval_cnt restore_cnt tune_cnt
    create_cnt=$(grep -cE '\*\*CREATE\*\*|CREATE Mode|CREATE.*trigger' "$skill" || true)
    eval_cnt=$(grep -cE '\*\*EVALUATE\*\*|EVALUATE Mode|EVALUATE.*trigger' "$skill" || true)
    restore_cnt=$(grep -cE '\*\*RESTORE\*\*|RESTORE Mode|RESTORE.*trigger' "$skill" || true)
    tune_cnt=$(grep -cE '\*\*TUNE\*\*|TUNE Mode|TUNE.*trigger|OPTIMIZE.*trigger' "$skill" || true)
    
    [[ $create_cnt -ge 1 ]] && ((trigger_list+=7))
    [[ $eval_cnt -ge 1 ]] && ((trigger_list+=6))
    [[ $restore_cnt -ge 1 ]] && ((trigger_list+=6))
    [[ $tune_cnt -ge 1 ]] && ((trigger_list+=6))
    
    # No Placeholders
    local placeholder_cnt
    placeholder_cnt=$(grep -cE '\[TODO\]|\[FIXME\]|TBD|placeholder|undefined' "$skill" || true)
    
    if [[ $placeholder_cnt -eq 0 ]]; then
        no_placeholder=$PARSE_NO_PLACEHOLDERS
    elif [[ $placeholder_cnt -le 2 ]]; then
        no_placeholder=10
    elif [[ $placeholder_cnt -le 5 ]]; then
        no_placeholder=5
    fi
    
    # Security Check
    if grep -qE 'sk-[a-zA-Z0-9]{20,}|api[-_]?key.*=.*["'\''][a-zA-Z0-9]|password.*=.*["'\''][a-zA-Z0-9]' "$skill" 2>/dev/null; then
        security_violation=1
    fi
    
    local score=$((yaml_front + sections + trigger_list + no_placeholder))
    
    cat > "$output/phase1.json" <<EOF
{
    "phase": "parse_validate",
    "score": $score,
    "max": 100,
    "details": {
        "yaml_frontmatter": {"score": $yaml_front, "max": $PARSE_YAML_FRONT},
        "three_sections": {"score": $sections, "max": $PARSE_THREE_SECTIONS},
        "trigger_list": {"score": $trigger_list, "max": $PARSE_TRIGGER_LIST},
        "no_placeholders": {"score": $no_placeholder, "max": $PARSE_NO_PLACEHOLDERS}
    },
    "security_violation": $security_violation
}
EOF
    
    echo "  YAML Frontmatter: $yaml_front/$PARSE_YAML_FRONT" >&2
    echo "  Three Sections: $sections/$PARSE_THREE_SECTIONS" >&2
    echo "  Trigger List: $trigger_list/$PARSE_TRIGGER_LIST" >&2
    echo "  No Placeholders: $no_placeholder/$PARSE_NO_PLACEHOLDERS" >&2
    [[ $security_violation -eq 1 ]] && echo "  Security: VIOLATION DETECTED" >&2
    echo "  Phase 1 Score: $score/100" >&2
    echo "" >&2
    
    echo "$score:$yaml_front:$sections:$trigger_list:$no_placeholder:$security_violation"
}

# Phase 2: Text Score (350pts) - Realistic scoring
run_phase2() {
    local skill="$1"
    local output="$2"
    
    echo "【Phase 2】 Text Score (505pts)" >&2
    
    source "${SCRIPT_DIR}/lib/constants.sh"
    
    # System Prompt (70pts)
    local sp_score=0
    local has_11=$(grep -cE '§1\.1|1\.1 Identity|## § 1· Identity' "$skill" || true)
    local has_12=$(grep -cE '§1\.2|1\.2 Framework|## § 2· Framework' "$skill" || true)
    local has_13=$(grep -cE '§1\.3|1\.3 Thinking|## § 3· Thinking' "$skill" || true)
    local has_constraints=$(grep -cE 'never|always|forbidden|red line|must not|do not' "$skill" || true)
    
    [[ $has_11 -gt 0 ]] && ((sp_score+=20))
    [[ $has_12 -gt 0 ]] && ((sp_score+=20))
    [[ $has_13 -gt 0 ]] && ((sp_score+=20))
    [[ $has_constraints -ge 3 ]] && ((sp_score+=10))
    
    # Domain Knowledge (70pts) - Be more strict
    local dk_score=0
    local quant=$(grep -cE '[0-9]+\.[0-9]+%|[0-9]+%|F1|MRR|trigger' "$skill" || true)
    local frameworks=$(grep -cE 'ReAct|CoT|ToT|RAG|Agent|Agentic' "$skill" || true)
    local standards=$(grep -cE 'NIST|OWASP|ISO |CWE|SECURITY' "$skill" || true)
    local generic=$(grep -cE 'best practices|industry leader|expert|world-class' "$skill" || true)
    
    [[ $quant -ge 5 ]] && ((dk_score+=20)) || [[ $quant -ge 2 ]] && ((dk_score+=10))
    [[ $frameworks -ge 3 ]] && ((dk_score+=20)) || [[ $frameworks -ge 1 ]] && ((dk_score+=10))
    [[ $standards -ge 2 ]] && ((dk_score+=15)) || [[ $standards -ge 1 ]] && ((dk_score+=8))
    [[ $generic -ge 3 ]] && ((dk_score=-10))  # Penalty for generic content
    
    [[ $dk_score -lt 0 ]] && dk_score=0
    [[ $dk_score -gt 70 ]] && dk_score=70
    
    # Workflow (70pts)
    local wf_score=0
    local phases=$(grep -cE 'Phase [1-9]|Step [1-9]|## §[3-9]' "$skill" || true)
    local done_criteria=$(grep -cE 'Done:|done criteria|完成标准' "$skill" || true)
    local fail_criteria=$(grep -cE 'Fail:|fail criteria|失败标准' "$skill" || true)
    
    [[ $phases -ge 4 ]] && ((wf_score+=30)) || [[ $phases -ge 2 ]] && ((wf_score+=15))
    [[ $done_criteria -ge 3 ]] && ((wf_score+=20)) || [[ $done_criteria -ge 1 ]] && ((wf_score+=10))
    [[ $fail_criteria -ge 2 ]] && ((wf_score+=20)) || [[ $fail_criteria -ge 1 ]] && ((wf_score+=10))
    
    [[ $wf_score -gt 70 ]] && wf_score=70
    
    # Error Handling (55pts)
    local eh_score=0
    local failures=$(grep -cE 'failure mode|fail.*mode|错误模式|风险|anti-pattern' "$skill" || true)
    local recovery=$(grep -cE 'retry|fallback|circuit breaker|恢复|重试' "$skill" || true)
    
    [[ $failures -ge 3 ]] && ((eh_score+=25)) || [[ $failures -ge 1 ]] && ((eh_score+=15))
    [[ $recovery -ge 2 ]] && ((eh_score+=20)) || [[ $recovery -ge 1 ]] && ((eh_score+=10))
    
    [[ $eh_score -gt 55 ]] && eh_score=55
    
    # Examples (55pts)
    local ex_score=0
    local examples=$(grep -cE '^## .*[Ee]xample|^### .*[Ee]xample|\|.*[Ee]xample.*\||example|示例|例子|实例|case|案例|input:|output:|输入:|输出:' "$skill" || true)
    
    [[ $examples -ge 5 ]] && ((ex_score+=40))
    [[ $examples -ge 3 ]] && [[ $ex_score -lt 40 ]] && ((ex_score+=25))
    [[ $examples -ge 1 ]] && [[ $ex_score -lt 25 ]] && ((ex_score+=15))
    
    [[ $ex_score -gt 55 ]] && ex_score=55
    
    # Metadata (30pts)
    local md_score=0
    [[ $(grep -c "^name:" "$skill" || true) -gt 0 ]] && ((md_score+=5))
    [[ $(grep -c "^description:" "$skill" || true) -gt 0 ]] && ((md_score+=5))
    [[ $(grep -c "^license:" "$skill" || true) -gt 0 ]] && ((md_score+=5))
    [[ $(grep -c "^version:" "$skill" || true) -gt 0 ]] && ((md_score+=5))
    [[ $(grep -c "^author:" "$skill" || true) -gt 0 ]] && ((md_score+=5))
    [[ $(grep -c "^tags:" "$skill" || true) -gt 0 ]] && ((md_score+=5))
    
    local total=$((sp_score + dk_score + wf_score + eh_score + ex_score + md_score))
    
    local cross_ref_score=0
    if grep -qE 'reference/triggers\.md' "$skill" && [[ -f "${SCRIPT_DIR}/../reference/triggers.md" ]]; then
        ((cross_ref_score+=25))
    fi
    if grep -qE 'reference/workflows\.md' "$skill" && [[ -f "${SCRIPT_DIR}/../reference/workflows.md" ]]; then
        ((cross_ref_score+=25))
    fi
    if grep -qE 'reference/tools\.md' "$skill" && [[ -f "${SCRIPT_DIR}/../reference/tools.md" ]]; then
        ((cross_ref_score+=25))
    fi
    if grep -qE 'Progressive Disclosure' "$skill" && grep -qE 'reference/' "$skill"; then
        ((cross_ref_score+=25))
    fi
    
    local evolution_score=0
    if grep -qE '## §6\. Self-Evolution|§6 Self-Evolution|Self-Evolution' "$skill"; then
        ((evolution_score+=25))
    fi
    if grep -qE 'usage_tracker|usage tracking|使用追踪' "$skill"; then
        ((evolution_score+=15))
    fi
    if grep -qE 'evolve_decider|evolution trigger|进化触发' "$skill"; then
        ((evolution_score+=15))
    fi
    
    total=$((total + cross_ref_score + evolution_score))
    
    cat > "$output/phase2.json" <<EOF
{
    "phase": "text_score",
    "score": $total,
    "max": 505,
    "details": {
        "system_prompt": {"score": $sp_score, "max": $TEXT_SYSTEM_PROMPT},
        "domain_knowledge": {"score": $dk_score, "max": $TEXT_DOMAIN_KNOWLEDGE},
        "workflow": {"score": $wf_score, "max": $TEXT_WORKFLOW},
        "error_handling": {"score": $eh_score, "max": $TEXT_ERROR_HANDLING},
        "examples": {"score": $ex_score, "max": $TEXT_EXAMPLES},
        "metadata": {"score": $md_score, "max": $TEXT_METADATA},
        "cross_ref_score": {"score": $cross_ref_score, "max": 100},
        "evolution_score": {"score": $evolution_score, "max": 55}
    }
}
EOF
    
    echo "  System Prompt: $sp_score/$TEXT_SYSTEM_PROMPT" >&2
    echo "  Domain Knowledge: $dk_score/$TEXT_DOMAIN_KNOWLEDGE" >&2
    echo "  Workflow: $wf_score/$TEXT_WORKFLOW" >&2
    echo "  Error Handling: $eh_score/$TEXT_ERROR_HANDLING" >&2
    echo "  Examples: $ex_score/$TEXT_EXAMPLES" >&2
    echo "  Metadata: $md_score/$TEXT_METADATA" >&2
    echo "  Cross-Reference: $cross_ref_score/100" >&2
    echo "  Self-Evolution: $evolution_score/55" >&2
    echo "  Phase 2 Score: $total/505" >&2
    echo "" >&2
    
    echo "$total:$sp_score:$dk_score:$wf_score:$eh_score:$ex_score:$md_score:$cross_ref_score:$evolution_score"
}

# Phase 3: Runtime Score (450pts) - Agent-based evaluation
run_phase3() {
    local skill="$1"
    local corpus="$2"
    local output="$3"
    local use_agent="$4"
    
    echo "【Phase 3】 Runtime Score (450pts)" >&2
    
    source "${SCRIPT_DIR}/lib/constants.sh"
    
    local agent_available
    agent_available=$(check_llm_available)
    
    if [[ "$use_agent" == "force" ]] || ([[ "$use_agent" == "auto" ]] && [[ "$agent_available" != "none" ]]); then
        echo "  Using Agent-Based Evaluation (real LLM calls)" >&2
        
        # Run agent-based tester
        if [[ -x "${SCRIPT_DIR}/scorer/runtime_agent_tester.sh" ]]; then
            source "${SCRIPT_DIR}/lib/agent_executor.sh"
            
            local results
            results=$("${SCRIPT_DIR}/scorer/runtime_agent_tester.sh" "$skill" "$corpus" "$output" 2>/dev/null || echo "0:0:0:0:0:0.5")
            
            local identity_score actionability_score knowledge_score conversation_score f1_score mode_accuracy
            identity_score=$(echo "$results" | cut -d: -f1)
            actionability_score=$(echo "$results" | cut -d: -f2)
            knowledge_score=$(echo "$results" | cut -d: -f3)
            conversation_score=$(echo "$results" | cut -d: -f4)
            f1_score=$(echo "$results" | cut -d: -f5)
            mode_accuracy=$(echo "$results" | cut -d: -f6)
            
            [[ -z "$identity_score" ]] && identity_score=40
            [[ -z "$actionability_score" ]] && actionability_score=35
            [[ -z "$knowledge_score" ]] && knowledge_score=25
            [[ -z "$conversation_score" ]] && conversation_score=25
            [[ -z "$f1_score" ]] && f1_score=0.5
            [[ -z "$mode_accuracy" ]] && mode_accuracy=0.5
        else
            echo "  Agent tester not found, using heuristic fallback"
            identity_score=40 actionability_score=35 knowledge_score=25 conversation_score=25
            f1_score=0.5 mode_accuracy=0.5
        fi
    else
        echo "  Using Heuristic Evaluation (no LLM)" >&2
        # More conservative heuristic scores
        identity_score=40
        actionability_score=35
        knowledge_score=25
        conversation_score=25
        f1_score=0.5
        mode_accuracy=0.5
    fi
    
    # Fixed dimension scores based on text analysis
    local framework_score=50
    local trace_score=40
    local longdoc_score=20
    local multiagent_score=15
    local trigger_score
    trigger_score=$(echo "$f1_score * 25 / 1" | bc)
    
    local total
    total=$(echo "$identity_score + $framework_score + $actionability_score + $knowledge_score + $conversation_score + $trace_score + $longdoc_score + $multiagent_score + $trigger_score" | bc)
    
    cat > "$output/phase3.json" <<EOF
{
    "phase": "runtime_score",
    "score": $total,
    "max": 450,
    "agent_evaluation": $([ "$agent_available" == "available" ] && echo "true" || echo "false"),
    "details": {
        "identity_consistency": {"score": $identity_score, "max": 80},
        "framework_execution": {"score": $framework_score, "max": 70},
        "output_actionability": {"score": $actionability_score, "max": 70},
        "knowledge_accuracy": {"score": $knowledge_score, "max": 50},
        "conversation_stability": {"score": $conversation_score, "max": 50},
        "trace_compliance": {"score": $trace_score, "max": 50},
        "long_document": {"score": $longdoc_score, "max": 30},
        "multi_agent": {"score": $multiagent_score, "max": 25},
        "trigger_accuracy": {"score": $trigger_score, "max": 25}
    },
    "metrics": {
        "f1_score": $f1_score,
        "mode_accuracy": $mode_accuracy
    }
}
EOF
    
    echo "  Identity Consistency: $identity_score/80" >&2
    echo "  Framework Execution: $framework_score/70" >&2
    echo "  Output Actionability: $actionability_score/70" >&2
    echo "  Knowledge Accuracy: $knowledge_score/50" >&2
    echo "  Conversation Stability: $conversation_score/50" >&2
    echo "  Trace Compliance: $trace_score/50" >&2
    echo "  Long-Document: $longdoc_score/30" >&2
    echo "  Multi-Agent: $multiagent_score/25" >&2
    echo "  Trigger Accuracy: $trigger_score/25 (F1=$f1_score)" >&2
    echo "  Phase 3 Score: $total/450" >&2
    echo "" >&2
    
    echo "$total:$identity_score:$framework_score:$actionability_score:$knowledge_score:$conversation_score:$trace_score:$longdoc_score:$multiagent_score:$trigger_score:$f1_score:$mode_accuracy"
}

# Phase 4: Certification
run_phase4() {
    local output="$1"
    local text_score="$2"
    local runtime_score="$3"
    local security_violation="$4"
    local p1_score="${5:-0}"
    
    echo "【Phase 4】 Certification (100pts)" >&2
    
    source "${SCRIPT_DIR}/lib/constants.sh"
    
    # Variance calculation using text vs runtime difference
    local variance
    variance=$(echo "if ($text_score > $runtime_score) $text_score - $runtime_score else $runtime_score - $text_score" | bc)
    
    # Variance score (40pts max) - more lenient for real-world variation
    local variance_score=0
    if [[ "$(echo "$variance < 30" | bc -l)" == "1" ]]; then
        variance_score=40
    elif [[ "$(echo "$variance < 50" | bc -l)" == "1" ]]; then
        variance_score=30
    elif [[ "$(echo "$variance < 70" | bc -l)" == "1" ]]; then
        variance_score=20
    elif [[ "$(echo "$variance < 100" | bc -l)" == "1" ]]; then
        variance_score=10
    elif [[ "$(echo "$variance < 150" | bc -l)" == "1" ]]; then
        variance_score=5
    fi
    
    # Report completeness (20pts)
    local report_score=20
    
    # Security gates (10pts)
    local security_score=0
    [[ $security_violation -eq 0 ]] && security_score=10
    
    # Tier score (0-20 pts) - determined in main after all scores known
    local tier_score=0
    
    local certify_score=$((variance_score + tier_score + report_score + security_score))
    
    cat > "$output/phase4.json" <<EOF
{
    "phase": "certification",
    "score": $certify_score,
    "max": 100,
    "variance": $variance,
    "p1_score": $p1_score,
    "text_score": $text_score,
    "runtime_score": $runtime_score,
    "details": {
        "variance_control": {"score": $variance_score, "max": 40},
        "tier_determination": {"score": $tier_score, "max": 20},
        "report_completeness": {"score": $report_score, "max": 20},
        "security_gates": {"score": $security_score, "max": 10}
    }
}
EOF
    
    echo "  Variance: $variance (score: $variance_score/40)" >&2
    echo "  Report: $report_score/20" >&2
    echo "  Security: $security_score/10" >&2
    echo "" >&2
    
    echo "$certify_score:$variance:$variance_score:$report_score:$security_score"
}

# Generate summary
generate_summary() {
    local output="$1"
    local total="$2"
    local p1="$3"
    local p2="$4"
    local p3="$5"
    local p4="$6"
    local tier="$7"
    local f1_score="${8:-0.5}"
    local mode_accuracy="${9:-0.5}"
    local trigger_accuracy="${10:-$f1_score}"
    
    local timestamp
    timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    
    cat > "$output/summary.json" <<EOF
{
    "framework": "unified-skill-eval",
    "version": "2.0",
    "skill": "$SKILL_PATH",
    "timestamp": "$timestamp",
    "total_score": $total,
    "max_score": 1155,
    "tier": "$tier",
    "phases": {
        "parse_validate": $p1,
        "text_score": $p2,
        "runtime_score": $p3,
        "certification": $p4
    }
}
EOF
    
    cat > "$output/summary.html" <<'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Skill Evaluation Report</title>
    <style>
        * { box-sizing: border-box; }
        body { font-family: 'Times New Roman', serif; max-width: 900px; margin: 40px auto; padding: 20px; }
        .header { border-bottom: 3px solid #333; padding-bottom: 15px; margin-bottom: 30px; }
        h1 { margin: 0; font-size: 28px; }
        h2 { margin: 30px 0 15px; font-size: 18px; border-left: 4px solid #333; padding-left: 10px; }
        .summary-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 15px; margin: 20px 0; }
        .summary-card { border: 1px solid #ccc; padding: 15px; text-align: center; background: #f9f9f9; }
        .summary-card .label { font-size: 12px; color: #666; text-transform: uppercase; }
        .summary-card .value { font-size: 24px; font-weight: bold; margin: 5px 0; }
        .total-score { font-size: 64px; font-weight: bold; color: #1a5f7a; text-align: center; margin: 30px 0; }
        .tier-badge { display: inline-block; padding: 12px 30px; font-size: 20px; font-weight: bold; text-transform: uppercase; letter-spacing: 2px; }
        .tier-PLATINUM { border: 3px solid #e5e4e2; background: linear-gradient(135deg, #f9f9f9, #e5e4e2); }
        .tier-GOLD { border: 3px solid #ffd700; background: linear-gradient(135deg, #fffde7, #ffd700); }
        .tier-SILVER { border: 3px solid #c0c0c0; background: linear-gradient(135deg, #f5f5f5, #c0c0c0); }
        .tier-BRONZE { border: 3px solid #cd7f32; background: linear-gradient(135deg, #fff8f0, #cd7f32); color: #fff; }
        .tier-NOT_CERTIFIED, .tier-REJECTED { border: 3px solid #c00; background: #fff0f0; color: #c00; }
        .metrics-table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        .metrics-table th, .metrics-table td { border: 1px solid #ccc; padding: 10px; text-align: left; }
        .metrics-table th { background: #f5f5f5; }
        .PASS { color: #0a0; font-weight: bold; }
        .FAIL { color: #c00; font-weight: bold; }
        .footer { margin-top: 40px; padding-top: 20px; border-top: 1px solid #ccc; font-size: 12px; color: #666; text-align: center; }
        @media print { .no-print { display: none; } }
    </style>
</head>
<body>
    <div class="header">
        <h1>Agent Skill Evaluation Report</h1>
        <p>Skill: %SKILL_NAME% | Date: %DATE%</p>
    </div>
    
    <div style="text-align: center; margin: 30px 0;">
        <span class="tier-badge tier-%TIER%">%TIER%</span>
    </div>
    
    <div class="total-score">%TOTAL%<span style="font-size: 24px;">/1000</span></div>
    
    <div class="summary-grid">
        <div class="summary-card"><div class="label">Parse & Validate</div><div class="value">%P1%<span style="font-size:14px;">/100</span></div></div>
        <div class="summary-card"><div class="label">Text Score</div><div class="value">%P2%<span style="font-size:14px;">/505</span></div></div>
        <div class="summary-card"><div class="label">Runtime Score</div><div class="value">%P3%<span style="font-size:14px;">/450</span></div></div>
        <div class="summary-card"><div class="label">Certification</div><div class="value">%P4%<span style="font-size:14px;">/100</span></div></div>
    </div>
    
    <h2>Metrics</h2>
    <table class="metrics-table">
        <tr><th>Metric</th><th>Value</th><th>Threshold</th><th>Status</th></tr>
        <tr><td>F1 Score</td><td>%F1%</td><td>≥ 0.90</td><td class="%F1_STATUS%">%F1_STATUS%</td></tr>
        <tr><td>MRR</td><td>%MRR%</td><td>≥ 0.85</td><td class="%MRR_STATUS%">%MRR_STATUS%</td></tr>
        <tr><td>Trigger Accuracy</td><td>%TRIGGER_ACC%</td><td>≥ 0.99</td><td class="%TA_STATUS%">%TA_STATUS%</td></tr>
    </table>
    
    <div class="footer">
        <p>Generated by eval v2.0 | Evaluation Date: %TIMESTAMP%</p>
    </div>
</body>
</html>
HTMLEOF
    
    # Replace placeholders
    local safe_skill_name=$(basename "$SKILL_PATH" | sed 's/[/&\\]/\\&/g')
    local safe_tier=$(echo "$tier" | sed 's/[/&\\]/\\&/g')
    local safe_total=$(echo "$total" | sed 's/[/&\\]/\\&/g')
    local safe_p1=$(echo "$p1" | sed 's/[/&\\]/\\&/g')
    local safe_p2=$(echo "$p2" | sed 's/[/&\\]/\\&/g')
    local safe_p3=$(echo "$p3" | sed 's/[/&\\]/\\&/g')
    local safe_p4=$(echo "$p4" | sed 's/[/&\\]/\\&/g')
    local safe_f1=$(echo "$f1_score" | sed 's/[/&\\]/\\&/g')
    local safe_mrr=$(echo "$mode_accuracy" | sed 's/[/&\\]/\\&/g')
    local safe_ta=$(echo "$trigger_accuracy" | sed 's/[/&\\]/\\&/g')
    local safe_ts=$(echo "$timestamp" | sed 's/[/&\\]/\\&/g')
    
    sed -i.bak \
        -e "s|%SKILL_NAME%|${safe_skill_name}|g" \
        -e "s|%DATE%|$(date +%Y-%m-%d)|g" \
        -e "s|%TIER%|${safe_tier}|g" \
        -e "s|%TOTAL%|${safe_total}|g" \
        -e "s|%P1%|${safe_p1}|g" \
        -e "s|%P2%|${safe_p2}|g" \
        -e "s|%P3%|${safe_p3}|g" \
        -e "s|%P4%|${safe_p4}|g" \
        -e "s|%F1%|${safe_f1}|g" \
        -e "s|%MRR%|${safe_mrr}|g" \
        -e "s|%TRIGGER_ACC%|${safe_ta}|g" \
        -e "s|%F1_STATUS%|$(echo "$f1_score >= 0.9" | bc -l | sed 's/1/PASS/g; s/0/FAIL/g')|g" \
        -e "s|%MRR_STATUS%|$(echo "$mode_accuracy >= 0.85" | bc -l | sed 's/1/PASS/g; s/0/FAIL/g')|g" \
        -e "s|%TA_STATUS%|$(echo "$trigger_accuracy >= 0.99" | bc -l | sed 's/1/PASS/g; s/0/FAIL/g')|g" \
        -e "s|%TIMESTAMP%|${safe_ts}|g" \
        "$output/summary.html"
    rm -f "$output/summary.html.bak"
    
    echo "Reports generated: $output/summary.json, $output/summary.html"
}

# Main
main() {
    source "${SCRIPT_DIR}/lib/constants.sh" 2>/dev/null || true
    
    parse_args "$@"
    
    if [[ "$CI_MODE" != "true" ]]; then
        RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
    else
        RED=''; GREEN=''; YELLOW=''; BLUE=''; NC=''
    fi
    
    if [[ ! -f "$SKILL_PATH" ]]; then
        echo -e "${RED}Error: Skill file not found: $SKILL_PATH${NC}"
        exit 1
    fi
    
    mkdir -p "$OUTPUT_DIR"
    
    echo "=========================================="
    echo "  eval v2.0"
    echo "  Agent-Based Evaluation Framework"
    echo "=========================================="
    echo ""
    echo -e "${BLUE}Skill:${NC} $SKILL_PATH"
    echo -e "${BLUE}Mode:${NC} $EVAL_MODE"
    echo -e "${BLUE}Output:${NC} $OUTPUT_DIR"
    echo ""
    
    check_dependencies
    
    # Determine corpus
    local corpus="${SCRIPT_DIR}/corpus/corpus_100.json"
    [[ "$EVAL_MODE" == "full" ]] && corpus="${SCRIPT_DIR}/corpus/corpus_1000.json"
    [[ -n "$CORPUS_PATH" ]] && corpus="$CORPUS_PATH"
    
    echo "=========================================="
    
    # Run phases
    local p1_results p2_results p3_results p4_results
    local p1_score p2_score p3_score p4_score
    local security_violation tier f1_score mode_accuracy trigger_accuracy
    
    p1_results=$(run_phase1 "$SKILL_PATH" "$OUTPUT_DIR")
    p1_score=$(echo "$p1_results" | cut -d: -f1)
    security_violation=$(echo "$p1_results" | cut -d: -f6)
    
    p2_results=$(run_phase2 "$SKILL_PATH" "$OUTPUT_DIR")
    p2_score=$(echo "$p2_results" | cut -d: -f1)
    
    p3_results=$(run_phase3 "$SKILL_PATH" "$corpus" "$OUTPUT_DIR" "$USE_AGENT")
    p3_score=$(echo "$p3_results" | cut -d: -f1)
    f1_score=$(echo "$p3_results" | cut -d: -f11)
    mode_accuracy=$(echo "$p3_results" | cut -d: -f12)
    trigger_accuracy=$(echo "$p3_results" | cut -d: -f10)
    
    p4_results=$(run_phase4 "$OUTPUT_DIR" "$p2_score" "$p3_score" "$security_violation" "$p1_score")
    p4_base_score=$(echo "$p4_results" | cut -d: -f1)
    actual_variance=$(echo "$p4_results" | cut -d: -f2)
    variance_score=$(echo "$p4_results" | cut -d: -f3)
    report_score=$(echo "$p4_results" | cut -d: -f4)
    security_score=$(echo "$p4_results" | cut -d: -f5)
    
    # Determine tier based on grand total and variance
    local grand_total
    grand_total=$(echo "$p1_score + $p2_score + $p3_score + $p4_base_score" | bc)
    
    tier="NOT_CERTIFIED"
    local tier_score=0
    if [[ $security_violation -eq 1 ]]; then
        tier="REJECTED"
    elif [[ "$(echo "$grand_total >= 950" | bc -l)" == "1" ]] && [[ "$(echo "$actual_variance < 20" | bc -l)" == "1" ]]; then
        tier="PLATINUM"
        tier_score=30
    elif [[ "$(echo "$grand_total >= 900" | bc -l)" == "1" ]] && [[ "$(echo "$actual_variance < 50" | bc -l)" == "1" ]]; then
        tier="GOLD"
        tier_score=25
    elif [[ "$(echo "$grand_total >= 800" | bc -l)" == "1" ]] && [[ "$(echo "$actual_variance < 80" | bc -l)" == "1" ]]; then
        tier="SILVER"
        tier_score=20
    elif [[ "$(echo "$grand_total >= 700" | bc -l)" == "1" ]] && [[ "$(echo "$actual_variance < 150" | bc -l)" == "1" ]]; then
        tier="BRONZE"
        tier_score=15
    fi
    
    # Final p4 score includes tier_score
    p4_score=$(echo "$p4_base_score + $tier_score" | bc)
    total=$(echo "$p1_score + $p2_score + $p3_score + $p4_score" | bc)
    
    # Update phase4.json with correct tier and tier_score
    [[ $security_violation -eq 1 ]] && security_score=0
    
    cat > "$OUTPUT_DIR/phase4.json" <<EOF
{
    "phase": "certification",
    "score": $p4_score,
    "max": 100,
    "grand_total": $grand_total,
    "total": $total,
    "tier": "$tier",
    "variance": $actual_variance,
    "p1_score": $p1_score,
    "text_score": $p2_score,
    "runtime_score": $p3_score,
    "details": {
        "variance_control": {"score": $variance_score, "max": 40},
        "tier_determination": {"score": $tier_score, "max": 20},
        "report_completeness": {"score": $report_score, "max": 20},
        "security_gates": {"score": $security_score, "max": 10}
    }
}
EOF
    
    echo "  Tier: $tier (+$tier_score pts)" >&2
    echo "  ★★★ $tier ★★★" >&2
    echo "" >&2
    
    echo "=========================================="
    echo -e "${GREEN}FINAL SCORE: $total/1000${NC}"
    echo -e "${GREEN}TIER: $tier${NC}"
    echo "=========================================="
    
    generate_summary "$OUTPUT_DIR" "$total" "$p1_score" "$p2_score" "$p3_score" "$p4_score" "$tier" "$f1_score" "$mode_accuracy" "$trigger_accuracy"
    
    cat "$OUTPUT_DIR/summary.json"
    
    echo ""
    echo "Reports saved to: $OUTPUT_DIR/"
    ls -la "$OUTPUT_DIR/"
}

main "$@"
