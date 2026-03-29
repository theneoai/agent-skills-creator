#!/usr/bin/env bash
# test_concurrency.sh - 并发锁模块测试 (15用例)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TOOLS_LIB="${PROJECT_ROOT}/tools/lib"

source "${TOOLS_LIB}/bootstrap.sh"
source "${TOOLS_LIB}/constants.sh"
source "${TOOLS_LIB}/concurrency.sh"

TEST_COUNT=0
TEST_PASSED=0
TEST_FAILED=0

assert_eq() {
    local expected="$1"
    local actual="$2"
    local msg="${3:-}"
    ((TEST_COUNT++))
    if [[ "$expected" == "$actual" ]]; then
        ((TEST_PASSED++))
        echo "  ✓ $msg"
        return 0
    else
        ((TEST_FAILED++))
        echo "  ✗ $msg"
        echo "    Expected: $expected"
        echo "    Actual: $actual"
        return 1
    fi
}

assert_success() {
    local cmd="$1"
    local msg="${2:-}"
    ((TEST_COUNT++))
    if eval "$cmd" >/dev/null 2>&1; then
        ((TEST_PASSED++))
        echo "  ✓ $msg"
        return 0
    else
        ((TEST_FAILED++))
        echo "  ✗ $msg"
        return 1
    fi
}

assert_failure() {
    local cmd="$1"
    local msg="${2:-}"
    ((TEST_COUNT++))
    if ! eval "$cmd" >/dev/null 2>&1; then
        ((TEST_PASSED++))
        echo "  ✓ $msg"
        return 0
    else
        ((TEST_FAILED++))
        echo "  ✗ $msg"
        return 1
    fi
}

test_concurrency_lock_acquire_001() {
    echo "  Testing lock acquire"
    local lock_name="test_acquire_$$"
    acquire_lock "$lock_name" 5
    assert_eq "0" "$?" "Lock acquired successfully"
    release_lock "$lock_name"
}

test_concurrency_lock_acquire_002() {
    local lock_name="test_acquire2_$$"
    acquire_lock "$lock_name" 10
    assert_eq "0" "$?" "Lock acquired with 10s timeout"
    release_lock "$lock_name"
}

test_concurrency_lock_release_001() {
    echo "  Testing lock release"
    local lock_name="test_release_$$"
    acquire_lock "$lock_name" 5
    release_lock "$lock_name"
    acquire_lock "$lock_name" 5
    assert_eq "0" "$?" "Lock released and re-acquired"
    release_lock "$lock_name"
}

test_concurrency_lock_timeout_001() {
    echo "  Testing lock timeout"
    local lock_name="test_timeout_$$"
    acquire_lock "$lock_name" 5
    assert_eq "0" "$?" "First acquire succeeds"
    local result
    result=$(acquire_lock "$lock_name" 1 2>&1) && result=0 || result=$?
    assert_eq "1" "$result" "Second acquire times out"
    release_lock "$lock_name"
}

test_concurrency_lock_timeout_002() {
    local lock_name="test_timeout2_$$"
    acquire_lock "$lock_name" 2
    local result
    result=$(acquire_lock "$lock_name" 1 2>&1) && result=0 || result=$?
    assert_eq "1" "$result" "Lock timeout returns 1"
    release_lock "$lock_name"
}

test_concurrency_is_running_001() {
    echo "  Testing is_running"
    local lock_name="test_running_$$"
    acquire_lock "$lock_name" 10
    is_running "$lock_name"
    assert_eq "0" "$?" "is_running returns 0 when lock held"
    release_lock "$lock_name"
}

test_concurrency_is_running_002() {
    local lock_name="test_not_running_$$"
    is_running "$lock_name"
    assert_eq "1" "$?" "is_running returns 1 when lock not held"
}

test_concurrency_is_lock_available_001() {
    echo "  Testing is_lock_available"
    local lock_name="test_available_$$"
    is_lock_available "$lock_name" 2
    assert_eq "0" "$?" "Lock is available initially"
}

test_concurrency_is_lock_available_002() {
    local lock_name="test_not_available_$$"
    acquire_lock "$lock_name" 10
    is_lock_available "$lock_name" 1
    assert_eq "1" "$?" "Lock not available when held"
    release_lock "$lock_name"
}

test_concurrency_lock_directory_001() {
    echo "  Testing lock directory exists"
    assert_success "[[ -d '$LOCK_DIR' ]]" "LOCK_DIR exists"
}

test_concurrency_lock_pid_001() {
    echo "  Testing lock PID tracking"
    local lock_name="test_pid_$$"
    acquire_lock "$lock_name" 10
    local lock_file="${LOCK_DIR}/${lock_name}.lock"
    local pid_file="${lock_file}/pid"
    assert_success "[[ -f '$pid_file' ]]" "PID file created"
    local pid
    pid=$(cat "$pid_file")
    assert_eq "$$" "$pid" "PID file contains correct PID"
    release_lock "$lock_name"
}

test_concurrency_lock_cleanup_001() {
    echo "  Testing lock cleanup on stale PID"
    local lock_name="test_cleanup_$$"
    acquire_lock "$lock_name" 10
    local lock_file="${LOCK_DIR}/${lock_name}.lock"
    local pid_file="${lock_file}/pid"
    echo "99999" > "$pid_file"
    acquire_lock "$lock_name" 2
    assert_eq "0" "$?" "Stale lock cleaned up and re-acquired"
    release_lock "$lock_name"
}

test_concurrency_with_lock_001() {
    echo "  Testing with_lock"
    local lock_name="test_with_lock_$$"
    with_lock "$lock_name" 5 true
    assert_eq "0" "$?" "with_lock executes command"
}

test_concurrency_double_lock_001() {
    echo "  Testing double lock prevention"
    local lock_name="test_double_$$"
    acquire_lock "$lock_name" 5
    local result
    result=$(acquire_lock "$lock_name" 1 2>&1)
    local exit_code=$?
    assert_eq "1" "$exit_code" "Double lock attempt fails"
    release_lock "$lock_name"
}

test_concurrency_lock_scope_001() {
    echo "  Testing lock scope isolation"
    local lock1="test_scope1_$$"
    local lock2="test_scope2_$$"
    acquire_lock "$lock1" 5
    acquire_lock "$lock2" 5
    assert_eq "0" "$?" "Different locks can be acquired"
    release_lock "$lock1"
    release_lock "$lock2"
}

run_test_concurrency_tests() {
    echo ""
    echo "=== Concurrency Module Tests ==="
    test_concurrency_lock_acquire_001
    test_concurrency_lock_acquire_002
    test_concurrency_lock_release_001
    test_concurrency_lock_timeout_001
    test_concurrency_lock_timeout_002
    test_concurrency_is_running_001
    test_concurrency_is_running_002
    test_concurrency_is_lock_available_001
    test_concurrency_is_lock_available_002
    test_concurrency_lock_directory_001
    test_concurrency_lock_pid_001
    test_concurrency_lock_cleanup_001
    test_concurrency_with_lock_001
    test_concurrency_double_lock_001
    test_concurrency_lock_scope_001
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_test_concurrency_tests
    echo ""
    echo "Results: $TEST_PASSED/$TEST_COUNT passed"
    [[ $TEST_FAILED -gt 0 ]] && exit 1 || exit 0
fi
