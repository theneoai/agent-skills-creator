#!/usr/bin/env bash
# test_errors.sh - 错误处理模块测试 (10用例)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TOOLS_LIB="${PROJECT_ROOT}/tools/lib"

source "${TOOLS_LIB}/bootstrap.sh"
source "${TOOLS_LIB}/constants.sh"
source "${TOOLS_LIB}/errors.sh"

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

assert_match() {
    local pattern="$1"
    local text="$2"
    local msg="${3:-}"
    ((TEST_COUNT++))
    if [[ "$text" =~ $pattern ]]; then
        ((TEST_PASSED++))
        echo "  ✓ $msg"
        return 0
    else
        ((TEST_FAILED++))
        echo "  ✗ $msg"
        return 1
    fi
}

test_errors_get_error_type_001() {
    echo "  Testing get_error_type"
    local type
    type=$(get_error_type "LLM_TIMEOUT")
    assert_eq "LLM调用超时" "$type" "LLM_TIMEOUT maps to Chinese description"
}

test_errors_get_error_type_002() {
    local type
    type=$(get_error_type "LLM_ERROR")
    assert_eq "LLM返回错误" "$type" "LLM_ERROR maps correctly"
}

test_errors_get_error_type_003() {
    local type
    type=$(get_error_type "INVALID_FORMAT")
    assert_eq "SKILL.md格式无效" "$type" "INVALID_FORMAT maps correctly"
}

test_errors_get_error_type_004() {
    local type
    type=$(get_error_type "UNKNOWN_TYPE")
    assert_eq "未知错误" "$type" "Unknown type defaults to '未知错误'"
}

test_errors_get_error_recovery_001() {
    echo "  Testing get_error_recovery"
    local recovery
    recovery=$(get_error_recovery "LLM_TIMEOUT")
    assert_match "^retry:" "$recovery" "LLM_TIMEOUT recovery starts with retry"
}

test_errors_get_error_recovery_002() {
    local recovery
    recovery=$(get_error_recovery "INVALID_FORMAT")
    assert_eq "rollback" "$recovery" "INVALID_FORMAT recovery is rollback"
}

test_errors_get_error_recovery_003() {
    local recovery
    recovery=$(get_error_recovery "LOCK_FAILED")
    assert_eq "fail" "$recovery" "LOCK_FAILED recovery is fail"
}

test_errors_log_error_001() {
    echo "  Testing log_error"
    local before
    before=$(grep -c "TEST_ERROR_UNIT" "$ERROR_LOG" 2>/dev/null || echo 0)
    log_error "TEST_ERROR_UNIT" "test message" "test_errors_log_error_001"
    local after
    after=$(grep -c "TEST_ERROR_UNIT" "$ERROR_LOG" 2>/dev/null || echo 0)
    assert_eq "1" "$((after - before))" "Error logged successfully"
}

test_errors_log_error_002() {
    local before
    before=$(grep -c "TEST_ERROR_JSON" "$ERROR_LOG" 2>/dev/null || echo 0)
    log_error "TEST_ERROR_JSON" "{\"key\":\"value\"}" "test"
    local after
    after=$(grep -c "TEST_ERROR_JSON" "$ERROR_LOG" 2>/dev/null || echo 0)
    assert_eq "1" "$((after - before))" "JSON error message logged"
}

test_errors_timestamp_001() {
    echo "  Testing timestamp generation"
    local ts
    ts=$(get_timestamp)
    assert_match "^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z" "$ts" "Timestamp matches ISO 8601 format"
}

run_test_errors_tests() {
    echo ""
    echo "=== Errors Module Tests ==="
    test_errors_get_error_type_001
    test_errors_get_error_type_002
    test_errors_get_error_type_003
    test_errors_get_error_type_004
    test_errors_get_error_recovery_001
    test_errors_get_error_recovery_002
    test_errors_get_error_recovery_003
    test_errors_log_error_001
    test_errors_log_error_002
    test_errors_timestamp_001
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_test_errors_tests
    echo ""
    echo "Results: $TEST_PASSED/$TEST_COUNT passed"
    [[ $TEST_FAILED -gt 0 ]] && exit 1 || exit 0
fi
