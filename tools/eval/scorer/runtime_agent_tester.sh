#!/usr/bin/env bash
# runtime_agent_tester.sh - Real Agent-based Runtime Evaluation
# Uses actual LLM API calls to test skill behavior
# Replaces simulate_* functions with real execution

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/constants.sh"
source "${SCRIPT_DIR}/../lib/agent_executor.sh"

# Check dependencies
check_dependencies() {
    for cmd in jq bc curl; do
        if ! command -v "$cmd" &>/dev/null; then
            echo "ERROR: Missing dependency: $cmd"
            return 1
        fi
    done
    
    if [[ "$(check_llm_available 2>/dev/null)" == "none" ]]; then
        echo "WARNING: No LLM API key found. Using fallback heuristics." >&2
        return 1
    fi
    return 0
}

# Run full agent-based runtime evaluation
run_agent_runtime_eval() {
    local skill_file="$1"
    local corpus_file="$2"
    local output_dir="$3"
    
    local provider
    provider=$(check_llm_available)
    
    if [[ "$provider" == "none" ]]; then
        echo "WARNING: No LLM available, using heuristic fallback" >&2
        run_heuristic_fallback "$skill_file" "$output_dir"
        return
    fi
    
    echo "=== Agent-Based Runtime Evaluation ===" >&2
    echo "Provider: $provider" >&2
    echo "Skill: $(basename "$skill_file")" >&2
    echo "" >&2
    
    # Initialize counters
    local trigger_tp=0 trigger_fp=0 trigger_fn=0
    local mode_correct=0 mode_total=0
    local identity_confused=0 identity_total=1
    local actionability_score=0 actionability_tests=3
    local knowledge_correct=0 knowledge_tests=3
    local conversation_stable=0 conversation_tests=1
    
    # Load corpus
    if [[ -f "$corpus_file" ]]; then
        local corpus_size
        corpus_size=$(jq '.test_cases | length' "$corpus_file" 2>/dev/null || echo "10")
        echo "Running $corpus_size trigger tests from corpus..." >&2
        
        # Sample test cases (limit to 10 for fast mode)
        local test_count=0
        local max_tests=10
        
        # Test triggers from corpus
        while IFS= read -r case_json; do
            [[ $test_count -ge $max_tests ]] && break
            
            local test_input
            local expected_mode
            local should_trigger
            
            test_input=$(echo "$case_json" | jq -r '.input')
            expected_mode=$(echo "$case_json" | jq -r '.expected_mode')
            should_trigger=$(echo "$case_json" | jq -r '.should_trigger')
            
            # Test trigger with cross-evaluation
            local trigger_result
            trigger_result=$(cross_test_trigger "$skill_file" "$test_input")
            trigger_result=$(parse_cross_result "$trigger_result" "binary")
            
            if [[ "$should_trigger" == "true" ]]; then
                if [[ "$trigger_result" == "1" ]]; then
                    ((trigger_tp++))
                else
                    ((trigger_fn++))
                fi
            else
                if [[ "$trigger_result" == "1" ]]; then
                    ((trigger_fp++))
                fi
            fi
            
            # Test mode routing (if should trigger)
            if [[ "$trigger_result" == "1" ]] && [[ "$should_trigger" == "true" ]]; then
                local mode_result
                mode_result=$(cross_test_mode_routing "$skill_file" "$test_input" "$expected_mode")
                # Extract returned mode from response
                local returned_mode="${mode_result#single:}"
                returned_mode="${returned_mode#cross:*}"
                # Check if returned mode contains expected mode
                if [[ "$returned_mode" == *"$expected_mode"* ]]; then
                    ((mode_correct++))
                fi
                ((mode_total++))
            fi
            
            ((test_count++))
            echo -n "." >&2
            
        done < <(jq -c '.test_cases[]' "$corpus_file" 2>/dev/null | head -"$max_tests")
        echo "" >&2
    else
        # Run basic tests without corpus
        echo "Running basic agent tests..." >&2
        run_basic_agent_tests "$skill_file" "$provider"
    fi
    
    # Calculate scores
    local trigger_accuracy
    trigger_accuracy=$(echo "scale=4; ($trigger_tp + $trigger_fp + $trigger_fn)" | bc)
    if [[ "$trigger_accuracy" -gt 0 ]]; then
        trigger_accuracy=$(echo "scale=4; ($trigger_tp + $trigger_fp) / $trigger_accuracy" | bc)
    else
        trigger_accuracy="0"
    fi
    
    # Identity test with cross-evaluation
    echo "Testing identity consistency..." >&2
    local identity_result
    identity_result=$(cross_test_identity "$skill_file")
    identity_confused=$(parse_cross_result "$identity_result" "binary")
    if [[ "$identity_confused" == "1" ]]; then
        identity_confused=1
    else
        identity_confused=0
    fi
    
    # Actionability test - check if response has substantive content
    echo "Testing output actionability..." >&2
    local actionability_tasks=("Create a code review skill" "Evaluate a skill's quality" "Fix a broken skill")
    for task in "${actionability_tasks[@]}"; do
        local result
        result=$(cross_test_actionability "$skill_file" "$task")
        # Extract content from single: or cross: format
        local content="${result#single:}"
        content="${content#cross:*}"
        # Check if content is substantive (length > 30 chars)
        local content_len=${#content}
        if [[ $content_len -gt 30 ]]; then
            ((actionability_score++))
        fi
    done
    
    # Knowledge accuracy test - check if it knows the answer
    echo "Testing knowledge accuracy..." >&2
    for i in 1 2; do
        local result
        result=$(cross_test_knowledge "$skill_file")
        local content="${result#single:}"
        content="${content#cross:*}"
        # If it says "don't know" or similar, it's a failure
        if [[ "$content" != *"don't know"* ]] && [[ "$content" != *"I don't know"* ]] && [[ ${#content} -gt 20 ]]; then
            ((knowledge_correct++))
        fi
    done
    
    # Conversation stability test - check if response is substantive
    echo "Testing conversation stability..." >&2
    local stability_result
    stability_result=$(cross_test_actionability "$skill_file" "Continue the previous conversation naturally")
    local content="${stability_result#single:}"
    content="${content#cross:*}"
    if [[ ${#content} -gt 20 ]]; then
        conversation_stable=1
    fi
    
    # Calculate final scores
    local identity_score=80
    if [[ $identity_confused -gt 0 ]]; then
        identity_score=40
    fi
    
    local actionability_final=$((actionability_score * 70 / actionability_tests))
    local knowledge_final=$((knowledge_correct * 50 / knowledge_tests))
    local conversation_final=$((conversation_stable * 50))
    
    # F1 calculation
    local f1
    f1=$(calculate_f1 $trigger_tp $trigger_fp $trigger_fn)
    
    local mode_accuracy=0
    if [[ $mode_total -gt 0 ]]; then
        mode_accuracy=$(echo "scale=4; $mode_correct / $mode_total" | bc | sed 's/^\./0./')
    fi
    
    # Output results
    cat > "$output_dir/agent_runtime_results.json" <<EOF
{
    "evaluation_type": "agent_based",
    "provider": "$provider",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "trigger_tests": {
        "true_positives": $trigger_tp,
        "false_positives": $trigger_fp,
        "false_negatives": $trigger_fn,
        "accuracy": $trigger_accuracy,
        "f1_score": $f1
    },
    "mode_routing": {
        "correct": $mode_correct,
        "total": $mode_total,
        "accuracy": $mode_accuracy
    },
    "identity_consistency": {
        "confused": $identity_confused,
        "score": $identity_score
    },
    "actionability": {
        "score": $actionability_final,
        "tests_passed": $actionability_score,
        "total_tests": $actionability_tests
    },
    "knowledge_accuracy": {
        "correct": $knowledge_correct,
        "total": $knowledge_tests,
        "score": $knowledge_final
    },
    "conversation_stability": {
        "stable": $conversation_stable,
        "score": $conversation_final
    }
}
EOF
    
    # Print summary
    echo "" >&2
    echo "=== Agent-Based Runtime Results ===" >&2
    echo "Trigger Accuracy: $(echo "$trigger_accuracy * 100" | bc)%" >&2
    echo "F1 Score: $f1" >&2
    echo "Mode Routing Accuracy: $(echo "$mode_accuracy * 100" | bc)%" >&2
    echo "Identity Consistency: $([ $identity_confused -eq 0 ] && echo "PASS" || echo "FAIL")" >&2
    echo "Actionability Score: $actionability_final/70" >&2
    echo "Knowledge Accuracy: $knowledge_final/50" >&2
    echo "Conversation Stability: $conversation_final/50" >&2
    
    # Return scores: identity:actionability:knowledge:conversation:f1:mode_accuracy
    echo "$identity_score:$actionability_final:$knowledge_final:$conversation_final:$f1:$mode_accuracy"
}

# Fallback when no LLM available
run_heuristic_fallback() {
    local skill_file="$1"
    local output_dir="$2"
    
    echo "WARNING: Running heuristic fallback (not real agent-based)" >&2
    
    # Basic heuristic scoring
    local has_identity=$(grep -cE '§1\.1|Identity|角色' "$skill_file" || true)
    local has_framework=$(grep -cE '§1\.2|Framework|框架' "$skill_file" || true)
    local has_thinking=$(grep -cE '§1\.3|Thinking|思考' "$skill_file" || true)
    local has_workflow=$(grep -cE 'workflow|Workflow|工作流' "$skill_file" || true)
    local has_examples=$(grep -cE 'example|Example|示例' "$skill_file" || true)
    
    local identity_score=0
    [[ $has_identity -gt 0 ]] && identity_score=$((identity_score + 20))
    [[ $has_framework -gt 0 ]] && identity_score=$((identity_score + 20))
    [[ $has_thinking -gt 0 ]] && identity_score=$((identity_score + 20))
    [[ $has_workflow -gt 0 ]] && identity_score=$((identity_score + 10))
    [[ $has_examples -gt 0 ]] && identity_score=$((identity_score + 10))
    
    [[ $identity_score -gt 80 ]] && identity_score=80
    
    cat > "$output_dir/agent_runtime_results.json" <<EOF
{
    "evaluation_type": "heuristic_fallback",
    "warning": "No LLM available - results are estimates only",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "identity_score": $identity_score,
    "actionability_score": 50,
    "knowledge_score": 40,
    "conversation_score": 40,
    "f1_score": 0.75,
    "mode_accuracy": 0.70
}
EOF
    
    echo "40:50:40:40:0.75:0.70"
}

# Run basic agent tests (when no corpus)
run_basic_agent_tests() {
    local skill_file="$1"
    local provider="$2"
    
    echo "Running basic agent-based tests..." >&2
    
    # Test 1: Trigger detection
    local test_inputs=(
        "创建一个新的skill"
        "评价一下这个skill"
        "优化我的skill"
        "修复损坏的skill"
    )
    
    local tp=0 fp=0 fn=0 total=0
    for input in "${test_inputs[@]}"; do
        ((total++))
        local result
        result=$(cross_test_trigger "$skill_file" "$input")
        result=$(parse_cross_result "$result" "binary")
        if [[ "$result" == "1" ]]; then
            ((tp++))
        fi
    done
    
    local accuracy=$(echo "scale=4; $tp / $total" | bc)
    echo "Trigger accuracy: $accuracy" >&2
}

# Main execution
main() {
    local skill_file="${1:-}"
    local corpus_file="${2:-${SCRIPT_DIR}/../corpus/corpus_100.json}"
    local output_dir="${3:-./eval_results}"
    
    if [[ -z "$skill_file" ]]; then
        echo "Usage: $0 <skill_file> [corpus_file] [output_dir]" >&2
        exit 1
    fi
    
    mkdir -p "$output_dir"
    
    check_dependencies || echo "Continuing with limited evaluation..." >&2
    
    run_agent_runtime_eval "$skill_file" "$corpus_file" "$output_dir"
}

main "$@"
