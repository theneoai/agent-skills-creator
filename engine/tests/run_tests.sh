#!/usr/bin/env bash
# run_tests.sh - 测试入口

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EVAL_DIR_FROM_ENGINE="$(cd "$SCRIPT_DIR/.." && pwd)"

source "${EVAL_DIR_FROM_ENGINE}/lib/bootstrap.sh"
require constants concurrency errors
require_evolution rollback

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

test_lock_acquire() {
    echo "Testing lock acquire..."
    
    local lock_name="test_$$"
    
    acquire_lock "$lock_name" 5
    local result=$?
    
    assert_eq "0" "$result" "Lock acquired successfully"
    
    release_lock "$lock_name"
}

test_lock_timeout() {
    echo "Testing lock timeout..."
    
    local lock_name="test_timeout_$$"
    
    acquire_lock "$lock_name" 5
    local result1=$?
    assert_eq "0" "$result1" "First acquire succeeds"
    
    local result2
    result2=$(acquire_lock "$lock_name" 1 2>&1) && result2=0 || result2=$?
    
    assert_eq "1" "$result2" "Second acquire times out"
    
    release_lock "$lock_name"
}

test_lock_release() {
    echo "Testing lock release..."
    
    local lock_name="test_release_$$"
    
    acquire_lock "$lock_name" 5
    release_lock "$lock_name"
    
    acquire_lock "$lock_name" 5
    local result=$?
    
    assert_eq "0" "$result" "Lock released and re-acquired"
    
    release_lock "$lock_name"
}

test_snapshot_create() {
    echo "Testing snapshot create..."
    
    local test_file
    test_file=$(mktemp /tmp/test_skill_XXXXXX.md)
    echo "# Test Skill" > "$test_file"
    echo "Content" >> "$test_file"
    
    local snapshot
    snapshot=$(create_snapshot "$test_file" "test")
    local result=$?
    
    assert_eq "0" "$result" "Snapshot created"
    assert_success "[[ -f \"$snapshot\" ]]" "Snapshot file exists"
    
    rm -f "$test_file" "$snapshot"
}

test_rollback() {
    echo "Testing rollback..."
    
    local test_file
    test_file=$(mktemp /tmp/test_skill_XXXXXX.md)
    echo "# Original" > "$test_file"
    
    create_snapshot "$test_file" "pre"
    echo "# Modified" > "$test_file"
    
    rollback_to_latest "$test_file" >/dev/null 2>&1
    
    local content
    content=$(cat "$test_file")
    
    assert_eq "# Original" "$content" "Rollback restored original content"
    
    rm -f "$test_file"
}

test_log_error() {
    echo "Testing error logging..."
    
    local before_count
    before_count=$(grep -c "TEST_ERROR" "$ERROR_LOG" 2>/dev/null || echo 0)
    
    log_error "TEST_ERROR" "Test error message" "test_log_error"
    
    local after_count
    after_count=$(grep -c "TEST_ERROR" "$ERROR_LOG" 2>/dev/null || echo 0)
    
    local logged=$((after_count - before_count))
    
    assert_eq "1" "$logged" "Error logged successfully"
}

test_bootstrap() {
    echo "Testing bootstrap..."
    
    assert_success "[[ -n \"$EVAL_DIR_FROM_ENGINE\" ]]" "EVAL_DIR_FROM_ENGINE is set"
    assert_success "[[ -d \"$LOCK_DIR\" ]]" "LOCK_DIR exists"
    assert_success "[[ -d \"$SNAPSHOT_DIR\" ]]" "SNAPSHOT_DIR exists"
    assert_success "[[ -d \"$LOG_DIR\" ]]" "LOG_DIR exists"
}

test_concurrency() {
    echo ""
    echo "=== Concurrency Tests ==="
    test_lock_acquire
    test_lock_timeout
    test_lock_release
}

test_errors() {
    echo ""
    echo "=== Error Handling Tests ==="
    test_log_error
}

test_rollback_features() {
    echo ""
    echo "=== Rollback Tests ==="
    test_snapshot_create
    test_rollback
}

test_bootstrap_features() {
    echo ""
    echo "=== Bootstrap Tests ==="
    test_bootstrap
}

run_tests() {
    echo "========================================"
    echo "  Running create-with-eval Tests"
    echo "========================================"
    echo ""
    
    test_bootstrap_features
    test_concurrency
    test_errors
    test_rollback_features
    
    echo ""
    echo "========================================"
    echo "  Results: $TEST_PASSED/$TEST_COUNT passed"
    [[ $TEST_FAILED -gt 0 ]] && echo "  FAILED: $TEST_FAILED"
    echo "========================================"
    
    [[ $TEST_FAILED -gt 0 ]] && exit 1 || exit 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_tests
fi