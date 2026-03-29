#!/usr/bin/env bash
# _parallel.sh - 并行执行支持

# ============================================================================
# 并行执行两个命令
# ============================================================================

parallel_execute() {
    local cmd1="$1"
    local cmd2="$2"
    local result_file1="${3:-}"
    local result_file2="${4:-}"
    
    if [[ -z "$cmd1" ]] || [[ -z "$cmd2" ]]; then
        echo "Error: Commands cannot be empty" >&2
        return 1
    fi
    
    if echo "$cmd1" | grep -qE '[;&|`$]' || echo "$cmd2" | grep -qE '[;&|`$]'; then
        echo "Error: Dangerous characters in parallel commands" >&2
        return 1
    fi
    
    local pid1 pid2 exit1 exit2
    
    if [[ -n "$result_file1" ]]; then
        bash -c "$cmd1" > "$result_file1" &
    else
        bash -c "$cmd1" &
    fi
    pid1=$!
    
    if [[ -n "$result_file2" ]]; then
        bash -c "$cmd2" > "$result_file2" &
    else
        bash -c "$cmd2" &
    fi
    pid2=$!
    
    wait $pid1
    exit1=$?
    
    wait $pid2
    exit2=$?
    
    if [[ $exit1 -eq 0 ]] && [[ $exit2 -eq 0 ]]; then
        return 0
    fi
    return 1
}

# ============================================================================
# 后台运行评估
# ============================================================================

run_parallel_evaluation() {
    local skill_file="$1"
    local temp_dir
    temp_dir=$(mktemp -d /tmp/parallel_eval_XXXXXX)
    local result_file="${temp_dir}/result.json"
    
    source "${EVAL_DIR_FROM_ENGINE}/agents/evaluator.sh"
    evaluator_evaluate_file "$skill_file" "$CURRENT_SECTION" > "$result_file" &
    local eval_pid=$!
    
    echo "$eval_pid" > "${temp_dir}/eval.pid"
    echo "$result_file" > "${temp_dir}/result_path"
    
    echo "$temp_dir"
}

wait_for_evaluation() {
    local temp_dir="$1"
    local eval_pid
    eval_pid=$(cat "${temp_dir}/eval.pid")
    local result_file
    result_file=$(cat "${temp_dir}/result_path")
    
    wait $eval_pid 2>/dev/null || true
    
    cat "$result_file"
    
    rm -rf "$temp_dir"
}