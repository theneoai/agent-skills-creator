#!/usr/bin/env bash
# run_tests.sh - 单元测试运行器

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TOOLS_LIB="${PROJECT_ROOT}/tools/lib"

source "${TOOLS_LIB}/bootstrap.sh"

echo "========================================"
echo "  单元测试"
echo "========================================"

TOTAL_COUNT=0
TOTAL_PASSED=0
TOTAL_FAILED=0

run_test_file() {
    local test_file="$1"
    local test_name
    test_name=$(basename "$test_file" .sh)
    
    echo ""
    echo "=== $test_name ==="
    
    TEST_COUNT=0
    TEST_PASSED=0
    TEST_FAILED=0
    
    source "$test_file"
    
    local test_func="run_${test_name}_tests"
    if declare -f "$test_func" > /dev/null; then
        "$test_func"
    fi
    
    echo ""
    echo "  $test_name: $TEST_PASSED/$TEST_COUNT passed"
    
    TOTAL_COUNT=$((TOTAL_COUNT + TEST_COUNT))
    TOTAL_PASSED=$((TOTAL_PASSED + TEST_PASSED))
    TOTAL_FAILED=$((TOTAL_FAILED + TEST_FAILED))
}

for test_file in "${SCRIPT_DIR}"/test_*.sh; do
    if [[ -f "$test_file" ]] && [[ "$test_file" != "${BASH_SOURCE[0]}" ]]; then
        run_test_file "$test_file"
    fi
done

echo ""
echo "========================================"
echo "  总计: $TOTAL_PASSED/$TOTAL_COUNT passed"
[[ $TOTAL_FAILED -gt 0 ]] && echo "  失败: $TOTAL_FAILED" || true
echo "========================================"

[[ $TOTAL_FAILED -gt 0 ]] && exit 1 || exit 0
