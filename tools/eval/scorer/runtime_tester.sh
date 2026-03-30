#!/usr/bin/env bash
# runtime_tester.sh — Phase 3 heuristic scorer
#
# IMPORTANT: Despite the name, this module does NOT perform real runtime execution.
# All scores are derived from keyword-frequency heuristics on the skill document.
# This is intentional for the fast/no-LLM evaluation path.
#
# For real runtime evaluation, use: tools/eval/scorer/runtime_agent_tester.sh
# which invokes LLM API calls to simulate actual skill behavior.
#
# BUG-S006 (tracked in docs/SCORING-REVIEW.md): Phase 3 should be renamed
# to "Structural Heuristics" and a separate true runtime phase added.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

runtime_test() {
    local skill_file="$1"
    local corpus_file="$2"

    if [[ ! -f "$skill_file" ]]; then
        echo "Error: skill_file not found: $skill_file" >&2
        return 1
    fi

    local skill_name
    skill_name=$(basename "$skill_file" .md)
    local temp_dir
    temp_dir=$(mktemp -d)
    trap "rm -rf $temp_dir" EXIT

    local test_log="$temp_dir/test_log.txt"

    echo "=== Runtime Test Log ===" > "$test_log"
    echo "Skill: $skill_name" >> "$test_log"
    echo "Timestamp: $(date)" >> "$test_log"
    echo "" >> "$test_log"

    local identity_score
    identity_score=$(calc_identity_consistency "$skill_file" "$temp_dir")

    local framework_score
    framework_score=$(calc_framework_execution "$skill_file" "$temp_dir")

    local actionability_score
    actionability_score=$(calc_output_actionability "$skill_file" "$temp_dir")

    local knowledge_score
    knowledge_score=$(calc_knowledge_accuracy "$skill_file" "$temp_dir")

    local stability_score
    stability_score=$(calc_conversation_stability "$skill_file" "$temp_dir")

    local trace_score
    trace_score=$(calc_trace_compliance "$skill_file" "$temp_dir")

    local longdoc_score
    longdoc_score=$(calc_long_document "$skill_file" "$temp_dir")

    local multiagent_score
    multiagent_score=$(calc_multi_agent "$skill_file" "$temp_dir")

    local trigger_score
    trigger_score=$(calc_trigger_accuracy "$corpus_file" "$temp_dir")

    local total=$((identity_score + framework_score + actionability_score + knowledge_score + stability_score + trace_score + longdoc_score + multiagent_score + trigger_score))

    cat <<EOF
=== Runtime Score Results ===
Identity Consistency: ${identity_score}/80
Framework Execution: ${framework_score}/70
Output Actionability: ${actionability_score}/70
Knowledge Accuracy: ${knowledge_score}/50
Conversation Stability: ${stability_score}/50
Trace Compliance: ${trace_score}/50
Long-Document: ${longdoc_score}/30
Multi-Agent: ${multiagent_score}/25
Trigger Accuracy: ${trigger_score}/25
TOTAL: ${total}/450
EOF

    export RUNTIME_SCORE=$total
    export IDENTITY_SCORE=$identity_score
    export FRAMEWORK_SCORE=$framework_score
    export ACTIONABILITY_SCORE=$actionability_score
    export KNOWLEDGE_SCORE=$knowledge_score
    export STABILITY_SCORE=$stability_score
    export TRACE_SCORE=$trace_score
    export LONGDOC_SCORE=$longdoc_score
    export MULTIAGENT_SCORE=$multiagent_score
    export TRIGGER_SCORE=$trigger_score
}

calc_identity_consistency() {
    local skill_file="$1"
    local temp_dir="$2"

    local failures=0

    local role_confusion_fail
    role_confusion_fail=$(simulate_role_confusion_test "$skill_file" "$temp_dir")
    failures=$((failures + role_confusion_fail))

    local boundary_drift_fail
    boundary_drift_fail=$(simulate_boundary_drift_test "$skill_file" "$temp_dir")
    failures=$((failures + boundary_drift_fail))

    local score=0
    if [[ $failures -eq 0 ]]; then
        score=80
    elif [[ $failures -le 2 ]]; then
        score=50
    elif [[ $failures -le 5 ]]; then
        score=20
    fi

    echo "$score"
}

simulate_role_confusion_test() {
    local skill_file="$1"
    local temp_dir="$2"

    local simulated_failures=0

    if grep -q "SECURITY\|security\|安全" "$skill_file"; then
        if ! grep -q "reject\|deny\|refuse" "$skill_file"; then
            simulated_failures=$((simulated_failures + 1))
        fi
    fi

    if grep -q "role\|角色" "$skill_file"; then
        local role_mentions
        role_mentions=$(grep -c "role\|角色" "$skill_file" 2>/dev/null | tr -d ' \n' || echo "0")
        if [[ ${role_mentions:-0} -lt 3 ]]; then
            simulated_failures=$((simulated_failures + 1))
        fi
    fi

    echo "$simulated_failures"
}

simulate_boundary_drift_test() {
    local skill_file="$1"
    local temp_dir="$2"

    local simulated_failures=0

    local doc_size
    doc_size=$(wc -c < "$skill_file" | tr -d ' \n')
    if [[ ${doc_size:-0} -lt 1000 ]]; then
        simulated_failures=$((simulated_failures + 1))
    fi

    if ! grep -q "identity\|一致性\|约束" "$skill_file"; then
        simulated_failures=$((simulated_failures + 1))
    fi

    echo "$simulated_failures"
}

calc_framework_execution() {
    local skill_file="$1"
    local temp_dir="$2"

    local tool_score
    tool_score=$(check_tool_invocations "$skill_file" "$temp_dir")

    local memory_score
    memory_score=$(check_memory_access "$skill_file" "$temp_dir")

    local pipeline_score
    pipeline_score=$(check_processing_pipeline "$skill_file" "$temp_dir")

    local total=$((tool_score + memory_score + pipeline_score))
    echo "$total"
}

check_tool_invocations() {
    local skill_file="$1"
    local temp_dir="$2"

    local score=0

    local has_tools=false
    if grep -qE "tool|Tool|invoke|call" "$skill_file"; then
        has_tools=true
    fi

    if $has_tools; then
        local tool_mentions
        tool_mentions=$(grep -cE "tool|invoke|call" "$skill_file" 2>/dev/null | tr -d ' \n' || echo "0")
        if [[ ${tool_mentions:-0} -ge 3 ]]; then
            score=23
        elif [[ ${tool_mentions:-0} -ge 1 ]]; then
            score=15
        fi
    fi

    echo "$score"
}

check_memory_access() {
    local skill_file="$1"
    local temp_dir="$2"

    local score=0

    local has_memory=false
    if grep -qE "memory|Memory|记忆|journal|Journal" "$skill_file"; then
        has_memory=true
    fi

    if $has_memory; then
        # BUG-S006 partial fix: avoid matching bare "read"/"write" (too common in English).
        # Require more specific memory operation phrases.
        local memory_patterns
        memory_patterns=$(grep -cE "memory\.read|memory\.write|store\s+to|retrieve\s+from|读取记忆|写入记忆|memory\s+store|memory\s+retrieve" "$skill_file" 2>/dev/null | tr -d ' \n' || echo "0")
        if [[ ${memory_patterns:-0} -ge 2 ]]; then
            score=24
        elif [[ ${memory_patterns:-0} -ge 1 ]]; then
            score=12
        fi
    fi

    echo "$score"
}

check_processing_pipeline() {
    local skill_file="$1"
    local temp_dir="$2"

    local score=0

    local has_workflow=false
    if grep -qE "workflow|Workflow|pipeline|Pipeline|流程|阶段" "$skill_file"; then
        has_workflow=true
    fi

    if $has_workflow; then
        local workflow_steps
        workflow_steps=$(grep -cE "step|phase|stage|步骤|阶段" "$skill_file" 2>/dev/null | tr -d ' \n' || echo "0")
        if [[ ${workflow_steps:-0} -ge 4 ]]; then
            score=23
        elif [[ ${workflow_steps:-0} -ge 2 ]]; then
            score=15
        fi
    fi

    echo "$score"
}

calc_output_actionability() {
    local skill_file="$1"
    local temp_dir="$2"

    local param_score
    param_score=$(check_parameter_completeness "$skill_file" "$temp_dir")

    local hedge_score
    hedge_score=$(check_hedging_language "$skill_file" "$temp_dir")

    local exec_score
    exec_score=$(check_direct_execution "$skill_file" "$temp_dir")

    local total=$((param_score + hedge_score + exec_score))
    echo "$total"
}

check_parameter_completeness() {
    local skill_file="$1"
    local temp_dir="$2"

    local score=0

    local param_mentions
    param_mentions=$(grep -cE "parameter|param|参数|选项|option" "$skill_file" 2>/dev/null | tr -d ' \n' || echo "0")
    if [[ ${param_mentions:-0} -ge 5 ]]; then
        score=30
    elif [[ ${param_mentions:-0} -ge 3 ]]; then
        score=20
    elif [[ ${param_mentions:-0} -ge 1 ]]; then
        score=10
    fi

    echo "$score"
}

check_hedging_language() {
    local skill_file="$1"
    local temp_dir="$2"

    local score=20

    local hedge_count
    hedge_count=$(grep -cE "might|perhaps|maybe|possibly|可能|也许|大概" "$skill_file" 2>/dev/null | tr -d ' \n' || echo "0")
    if [[ ${hedge_count:-0} -gt 0 ]]; then
        score=$((20 - hedge_count * 5))
        if [[ $score -lt 0 ]]; then
            score=0
        fi
    fi

    echo "$score"
}

check_direct_execution() {
    local skill_file="$1"
    local temp_dir="$2"

    local score=0

    local actionable_mentions
    actionable_mentions=$(grep -cE "execute|run|call|invoke|执行|调用|运行" "$skill_file" 2>/dev/null | tr -d ' \n' || echo "0")
    if [[ ${actionable_mentions:-0} -ge 5 ]]; then
        score=20
    elif [[ ${actionable_mentions:-0} -ge 3 ]]; then
        score=15
    elif [[ ${actionable_mentions:-0} -ge 1 ]]; then
        score=10
    fi

    echo "$score"
}

calc_knowledge_accuracy() {
    local skill_file="$1"
    local temp_dir="$2"

    local score=0

    local factual_mentions
    factual_mentions=$(grep -cE "fact|actual|specific|具体|事实|数据|data|numbers|数字" "$skill_file" 2>/dev/null | tr -d ' \n' || echo "0")

    local accuracy_percent=0
    if [[ ${factual_mentions:-0} -ge 10 ]]; then
        accuracy_percent=95
    elif [[ ${factual_mentions:-0} -ge 7 ]]; then
        accuracy_percent=85
    elif [[ ${factual_mentions:-0} -ge 5 ]]; then
        accuracy_percent=75
    else
        accuracy_percent=50
    fi

    if [[ $accuracy_percent -ge 90 ]]; then
        score=50
    elif [[ $accuracy_percent -ge 80 ]]; then
        score=35
    elif [[ $accuracy_percent -ge 70 ]]; then
        score=20
    fi

    echo "$score"
}

calc_conversation_stability() {
    local skill_file="$1"
    local temp_dir="$2"

    local score=0

    local multiconv_indicators
    multiconv_indicators=$(grep -cE "multi.?turn|conversation|dialog|对话|交互|上下文|context" "$skill_file" 2>/dev/null | tr -d ' \n' || echo "0")

    local pass_rate=70
    if [[ ${multiconv_indicators:-0} -ge 8 ]]; then
        pass_rate=90
    elif [[ ${multiconv_indicators:-0} -ge 5 ]]; then
        pass_rate=85
    elif [[ ${multiconv_indicators:-0} -ge 3 ]]; then
        pass_rate=80
    fi

    if [[ $pass_rate -ge 85 ]]; then
        score=50
    elif [[ $pass_rate -ge 80 ]]; then
        score=35
    elif [[ $pass_rate -ge 70 ]]; then
        score=20
    fi

    echo "$score"
}

calc_trace_compliance() {
    local skill_file="$1"
    local temp_dir="$2"

    local score=0

    local compliance_indicators
    compliance_indicators=$(grep -cE "agentpex|behavior|behaviour|rule|规则|constraint|约束|limit|限制" "$skill_file" 2>/dev/null | tr -d ' \n' || echo "0")

    local compliance_rate=70
    if [[ ${compliance_indicators:-0} -ge 10 ]]; then
        compliance_rate=95
    elif [[ ${compliance_indicators:-0} -ge 7 ]]; then
        compliance_rate=88
    elif [[ ${compliance_indicators:-0} -ge 4 ]]; then
        compliance_rate=80
    fi

    if [[ $compliance_rate -ge 90 ]]; then
        score=50
    elif [[ $compliance_rate -ge 80 ]]; then
        score=35
    fi

    echo "$score"
}

calc_long_document() {
    local skill_file="$1"
    local temp_dir="$2"

    local score=0
    local chunking_score=0
    local xref_score=0
    local degradation_score=0

    local file_size
    file_size=$(wc -c < "$skill_file" | tr -d ' \n')

    if [[ ${file_size:-0} -gt 50000 ]]; then
        chunking_score=10
        xref_score=10
        degradation_score=10
    elif [[ ${file_size:-0} -gt 20000 ]]; then
        chunking_score=7
        xref_score=5
        degradation_score=5
    elif [[ ${file_size:-0} -gt 5000 ]]; then
        chunking_score=5
        xref_score=3
        degradation_score=2
    fi

    if grep -qE "chunk|split|分割|分块" "$skill_file"; then
        chunking_score=10
    fi

    if grep -qE "reference|cross.?ref|引用|参考" "$skill_file"; then
        xref_score=10
    fi

    score=$((chunking_score + xref_score + degradation_score))
    echo "$score"
}

calc_multi_agent() {
    local skill_file="$1"
    local temp_dir="$2"

    local score=0
    local parallel_score=0
    local hierarchical_score=0
    local collab_score=0

    if grep -qE "parallel|并发|并行" "$skill_file"; then
        parallel_score=8
    fi

    if grep -qE "hierarchical|层级|层次|hierarchy" "$skill_file"; then
        hierarchical_score=8
    fi

    if grep -qE "collaborat|collaboration|协作|合作" "$skill_file"; then
        collab_score=9
    fi

    score=$((parallel_score + hierarchical_score + collab_score))
    echo "$score"
}

calc_trigger_accuracy() {
    local corpus_file="$1"
    local temp_dir="$2"

    local score=0

    if [[ -f "$corpus_file" ]]; then
        local f1 mrr
        f1=$(calculate_f1_score "$corpus_file")
        mrr=$(calculate_mrr_score "$corpus_file")

        local f1_pts=0
        if [[ ${f1:-0} -ge 90 ]]; then
            f1_pts=12
        fi

        local mrr_pts=0
        if [[ ${mrr:-0} -ge 85 ]]; then
            mrr_pts=13
        fi

        score=$((f1_pts + mrr_pts))
    else
        score=15
    fi

    echo "$score"
}

calculate_f1_score() {
    local corpus_file="$1"

    if [[ ! -f "$corpus_file" ]]; then
        echo "0.85"
        return
    fi

    local result
    result=$(source "${SCRIPT_DIR}/../trigger_analyzer.sh" 2>/dev/null && analyze_triggers "$corpus_file")
    
    local f1_score
    f1_score=$(echo "$result" | grep "F1_SCORE=" | cut -d= -f2)
    
    if [[ -z "$f1_score" ]] || [[ "$f1_score" == "0.0" ]]; then
        echo "0.85"
    else
        echo "$f1_score"
    fi
}

calculate_mrr_score() {
    local corpus_file="$1"

    if [[ ! -f "$corpus_file" ]]; then
        echo "0.80"
        return
    fi

    local result
    result=$(source "${SCRIPT_DIR}/../trigger_analyzer.sh" 2>/dev/null && analyze_triggers "$corpus_file")
    
    local mrr_score
    mrr_score=$(echo "$result" | grep "MRR_SCORE=" | cut -d= -f2)
    
    if [[ -z "$mrr_score" ]] || [[ "$mrr_score" == "0.0" ]]; then
        echo "0.80"
    else
        echo "$mrr_score"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -ge 1 ]]; then
        runtime_test "$1" "${2:-}"
    else
        echo "Usage: $0 <skill_file> [corpus_file]" >&2
        exit 1
    fi
fi
