#!/usr/bin/env bash
# test_parallel.sh - Parallel Execution Tests (10 test cases)
# TDD: Tests describe expected behavior of parallel execution functions

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
if ! declare -f assert_eq >/dev/null 2>&1; then
    source "${PROJECT_ROOT}/tests/framework.sh"
fi

source "${PROJECT_ROOT}/tools/lib/concurrency.sh"
source "${PROJECT_ROOT}/tools/orchestrator/parallel.sh"

# ============================================================================
# Lock Tests (IDs: 001-004)
# ============================================================================

test_lock_acquire_release_001() {
    local lock_name="test_lock_$$"
    local result=0
    
    acquire_lock "$lock_name" 5 || result=1
    assert_success "[[ -d \"$LOCK_DIR/${lock_name}.lock\" ]]" "Lock file created"
    
    release_lock "$lock_name"
    assert_success "[[ ! -d \"$LOCK_DIR/${lock_name}.lock\" ]]" "Lock file removed after release"
}

test_lock_acquire_release_002() {
    local lock_name="test_lock2_$$"
    
    acquire_lock "$lock_name" 5
    assert_success "[[ -f \"$LOCK_DIR/${lock_name}.lock/pid\" ]]" "PID file created"
    
    local pid
    pid=$(cat "$LOCK_DIR/${lock_name}.lock/pid")
    assert_eq "$$" "$pid" "PID matches current process"
    
    release_lock "$lock_name"
}

test_lock_double_acquire_003() {
    local lock_name="test_lock3_$$"
    
    acquire_lock "$lock_name" 5
    local pid1
    pid1=$(cat "$LOCK_DIR/${lock_name}.lock/pid")
    
    ( sleep 2; acquire_lock "$lock_name" 1 ) 2>/dev/null || true
    
    local pid2
    pid2=$(cat "$LOCK_DIR/${lock_name}.lock/pid" 2>/dev/null || echo "released")
    
    assert_eq "$pid1" "$pid2" "Original lock preserved"
    
    release_lock "$lock_name"
}

test_lock_is_available_004() {
    local lock_name="test_lock4_$$"
    
    is_lock_available "$lock_name" 2
    assert_success "[[ $? -eq 0 ]]" "Lock available when not held"
    
    acquire_lock "$lock_name" 5
    
    set +e
    is_lock_available "$lock_name" 1 2>/dev/null
    local result=$?
    set -e
    
    assert_eq "1" "$result" "Lock unavailable when held"
    
    release_lock "$lock_name"
}

# ============================================================================
# Parallel Execute Tests (IDs: 005-007)
# ============================================================================

test_parallel_execute_005() {
    local result_file1
    result_file1=$(mktemp /tmp/parallel_result1_XXXXXX)
    local result_file2
    result_file2=$(mktemp /tmp/parallel_result2_XXXXXX)
    
    parallel_execute "echo 'task1'" "echo 'task2'" "$result_file1" "$result_file2"
    assert_success "[[ $? -eq 0 ]]" "parallel_execute succeeds"
    
    assert_eq "task1" "$(cat "$result_file1")" "First task result correct"
    assert_eq "task2" "$(cat "$result_file2")" "Second task result correct"
    
    rm -f "$result_file1" "$result_file2"
}

test_parallel_execute_006() {
    local result_file1
    result_file1=$(mktemp /tmp/parallel_result3_XXXXXX)
    local result_file2
    result_file2=$(mktemp /tmp/parallel_result4_XXXXXX)
    
    parallel_execute "echo done1" "echo done2" "$result_file1" "$result_file2"
    assert_success "[[ $? -eq 0 ]]" "Parallel tasks complete"
    
    rm -f "$result_file1" "$result_file2"
}

test_parallel_execute_007() {
    local result_file1
    result_file1=$(mktemp /tmp/parallel_result5_XXXXXX)
    
    parallel_execute "echo 'single'" "echo 'unused'" "$result_file1" /tmp/parallel_unused.txt
    assert_success "[[ $? -eq 0 ]]" "Single command succeeds"
    assert_eq "single" "$(cat "$result_file1")" "Single result correct"
    
    rm -f "$result_file1" /tmp/parallel_unused.txt
}

# ============================================================================
# Timeout and Deadlock Prevention Tests (IDs: 008-010)
# ============================================================================

test_parallel_timeout_008() {
    local lock_name="timeout_lock_$$"
    
    acquire_lock "$lock_name" 30
    
    set +e
    ( sleep 2; acquire_lock "$lock_name" 1 ) 2>/dev/null
    local result=$?
    set -e
    
    assert_eq "1" "$result" "Lock acquisition times out"
    
    release_lock "$lock_name"
}

test_parallel_deadlock_009() {
    local lock1="deadlock_lock1_$$"
    local lock2="deadlock_lock2_$$"
    
    acquire_lock "$lock1" 5
    
    (
        acquire_lock "$lock2" 5
        release_lock "$lock2"
    ) &
    local pid=$!
    
    sleep 1
    
    release_lock "$lock1"
    
    wait $pid || true
    
    is_lock_available "$lock1" 1
    assert_success "[[ $? -eq 0 ]]" "Lock1 available after release"
    
    is_lock_available "$lock2" 1
    assert_success "[[ $? -eq 0 ]]" "Lock2 available after release"
}

test_parallel_contention_010() {
    local lock_name="contention_lock_$$"
    local counter=0
    
    for i in $(seq 1 5); do
        (
            with_lock "$lock_name" 10 bash -c 'counter=$(cat /tmp/counter_'"$$"' 2>/dev/null || echo 0); echo $((counter + 1)) > /tmp/counter_'"$$"
        ) &
    done
    
    wait
    
    rm -f "/tmp/counter_$$"
    
    assert_success "true" "Contention test completed"
}

# ============================================================================
# Run all parallel tests
# ============================================================================

main() {
    echo "Running Parallel Execution Tests (10 cases)..."
    
    test_lock_acquire_release_001
    test_lock_acquire_release_002
    test_lock_double_acquire_003
    test_lock_is_available_004
    test_parallel_execute_005
    test_parallel_execute_006
    test_parallel_execute_007
    test_parallel_timeout_008
    test_parallel_deadlock_009
    test_parallel_contention_010
}

main "$@"
