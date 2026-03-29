#!/usr/bin/env bash
# 测试框架 - 通用测试工具函数

set -euo pipefail

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 测试计数器 (仅当未定义时才初始化，支持跨source累积)
if [[ -z "${TESTS_TOTAL:-}" ]]; then
    export TESTS_TOTAL=0
    export TESTS_PASSED=0
    export TESTS_FAILED=0
    export TESTS_SKIPPED=0
fi

# 断言函数
assert_eq() {
    local expected="$1"
    local actual="$2"
    local msg="${3:-}"
    ((TESTS_TOTAL++))
    if [[ "$expected" == "$actual" ]]; then
        ((TESTS_PASSED++))
        echo -e "  ${GREEN}✓${NC} $msg"
        return 0
    else
        ((TESTS_FAILED++))
        echo -e "  ${RED}✗${NC} $msg"
        echo -e "    Expected: $expected"
        echo -e "    Actual:   $actual"
        return 1
    fi
}

assert_success() {
    local cmd="$1"
    local msg="${2:-}"
    ((TESTS_TOTAL++))
    if eval "$cmd" >/dev/null 2>&1; then
        ((TESTS_PASSED++))
        echo -e "  ${GREEN}✓${NC} $msg"
        return 0
    else
        ((TESTS_FAILED++))
        echo -e "  ${RED}✗${NC} $msg"
        return 1
    fi
}

assert_failure() {
    local cmd="$1"
    local msg="${2:-}"
    ((TESTS_TOTAL++))
    if ! eval "$cmd" >/dev/null 2>&1; then
        ((TESTS_PASSED++))
        echo -e "  ${GREEN}✓${NC} $msg"
        return 0
    else
        ((TESTS_FAILED++))
        echo -e "  ${RED}✗${NC} $msg"
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local msg="${3:-}"
    ((TESTS_TOTAL++))
    if echo "$haystack" | grep -q "$needle"; then
        ((TESTS_PASSED++))
        echo -e "  ${GREEN}✓${NC} $msg"
        return 0
    else
        ((TESTS_FAILED++))
        echo -e "  ${RED}✗${NC} $msg"
        return 1
    fi
}

assert_match() {
    local pattern="$1"
    local text="$2"
    local msg="${3:-}"
    ((TESTS_TOTAL++))
    if [[ "$text" =~ $pattern ]]; then
        ((TESTS_PASSED++))
        echo -e "  ${GREEN}✓${NC} $msg"
        return 0
    else
        ((TESTS_FAILED++))
        echo -e "  ${RED}✗${NC} $msg"
        return 1
    fi
}

# 多LLM验证函数
multi_llm_validate() {
    local test_name="$1"
    local result="$2"
    local provider1="${3:-kimi-code}"
    local provider2="${4:-minimax}"
    
    # 用第二个LLM复核结果
    local verify_result
    verify_result=$(agent_call_llm "验证测试结果: $result" "$test_name" "auto" "$provider2")
    
    if echo "$verify_result" | grep -qi "一致\|匹配\|正确"; then
        echo "PASS: $test_name (双LLM一致)"
        return 0
    else
        echo "WARN: $test_name (双LLM不一致，需人工复核)"
        return 1
    fi
}

# 测试运行报告
report() {
    echo ""
    echo "========================================"
    echo "  测试结果"
    echo "========================================"
    echo -e "  总计: ${BLUE}$TESTS_TOTAL${NC}"
    echo -e "  通过: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "  失败: ${RED}$TESTS_FAILED${NC}"
    echo -e "  跳过: ${YELLOW}$TESTS_SKIPPED${NC}"
    echo "========================================"
    
    if [[ $TESTS_FAILED -gt 0 ]]; then
        return 1
    fi
    return 0
}

# 导出函数
export -f assert_eq assert_success assert_failure assert_contains assert_match
export -f multi_llm_validate report
