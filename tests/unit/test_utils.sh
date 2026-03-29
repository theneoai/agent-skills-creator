#!/usr/bin/env bash
# test_utils.sh - 工具函数模块测试 (20用例)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TOOLS_LIB="${PROJECT_ROOT}/tools/lib"

source "${TOOLS_LIB}/bootstrap.sh"
source "${TOOLS_LIB}/constants.sh"
source "${TOOLS_LIB}/utils.sh"

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
        echo "    Pattern: $pattern"
        echo "    Text: $text"
        return 1
    fi
}

sed_i() {
    local pattern="$1"
    local file="$2"
    case "$(uname -s)" in
        Darwin|*BSD)
            sed -i '' "$pattern" "$file"
            ;;
        *)
            sed -i "$pattern" "$file"
            ;;
    esac
}

test_utils_check_dependencies_001() {
    echo "  Testing check_dependencies"
    check_dependencies
    assert_eq "0" "$?" "check_dependencies succeeds with required tools"
}

test_utils_parse_yaml_001() {
    echo "  Testing parse_yaml_frontmatter"
    local test_file
    test_file=$(mktemp /tmp/test_yaml_XXXXXX)
    cat > "$test_file" <<'EOF'
---
name: test
version: 1.0
---
Content here
EOF
    local yaml
    yaml=$(parse_yaml_frontmatter "$test_file")
    assert_success "[[ \$yaml == *'name: test'* ]]" "parse_yaml extracts frontmatter"
    rm -f "$test_file"
}

test_utils_parse_yaml_002() {
    local test_file
    test_file=$(mktemp /tmp/test_yaml_XXXXXX)
    echo "No frontmatter" > "$test_file"
    local yaml
    yaml=$(parse_yaml_frontmatter "$test_file")
    assert_eq "" "$yaml" "parse_yaml returns empty for no frontmatter"
    rm -f "$test_file"
}

test_utils_parse_yaml_003() {
    local test_file
    test_file=$(mktemp /tmp/test_yaml_XXXXXX)
    cat > "$test_file" <<'EOF'
---
key: value
---
Body content
EOF
    local yaml
    yaml=$(parse_yaml_frontmatter "$test_file")
    assert_success "[[ \$yaml == *'key: value'* ]]" "parse_yaml handles single section"
    rm -f "$test_file"
}

test_utils_count_lines_001() {
    echo "  Testing count_lines"
    local test_file
    test_file=$(mktemp /tmp/test_lines_XXXXXX)
    printf "line1\nline2\nline3\n" > "$test_file"
    local count
    count=$(count_lines "$test_file")
    assert_eq "3" "$count" "count_lines returns correct count"
    rm -f "$test_file"
}

test_utils_count_lines_002() {
    local test_file
    test_file=$(mktemp /tmp/test_lines_XXXXXX)
    > "$test_file"
    local count
    count=$(count_lines "$test_file")
    assert_eq "0" "$count" "count_lines returns 0 for empty file"
    rm -f "$test_file"
}

test_utils_count_lines_003() {
    local count
    count=$(count_lines "/nonexistent/file.txt" 2>/dev/null || true)
    assert_eq "0" "$count" "count_lines returns 0 for missing file"
}

test_utils_extract_trigger_001() {
    echo "  Testing extract_trigger_section"
    local test_file
    test_file=$(mktemp /tmp/test_trigger_XXXXXX)
    cat > "$test_file" <<'EOF'
# Trigger
trigger1
trigger2

## Examples
EOF
    extract_trigger_section "$test_file" >/dev/null 2>&1
    assert_eq "0" "$?" "extract_trigger_section executes without error"
    rm -f "$test_file"
}

test_utils_calculate_percentage_001() {
    echo "  Testing calculate_percentage"
    local pct
    pct=$(calculate_percentage 50 100)
    assert_eq "50.00" "$pct" "calculate_percentage 50/100 = 50.00"
}

test_utils_calculate_percentage_002() {
    local pct
    pct=$(calculate_percentage 1 3)
    assert_match "^33\." "$pct" "calculate_percentage 1/3 ≈ 33.33"
}

test_utils_calculate_percentage_003() {
    local pct
    pct=$(calculate_percentage 1 0)
    assert_eq "0" "$pct" "calculate_percentage handles division by zero"
}

test_utils_log_functions_001() {
    echo "  Testing log functions"
    assert_success "log_info 'test' 2>/dev/null" "log_info executes without error"
}

test_utils_log_functions_002() {
    assert_success "log_warn 'test' 2>/dev/null" "log_warn executes without error"
}

test_utils_log_functions_003() {
    assert_success "log_error 'test' 2>/dev/null" "log_error executes without error"
}

test_utils_log_functions_004() {
    assert_success "log_success 'test' 2>/dev/null" "log_success executes without error"
}

test_utils_sed_i_001() {
    echo "  Testing sed_i cross-platform"
    local test_file
    test_file=$(mktemp /tmp/test_sed_XXXXXX)
    echo "original line" > "$test_file"
    sed_i 's/original/modified/' "$test_file"
    local content
    content=$(cat "$test_file")
    assert_eq "modified line" "$content" "sed_i modifies file content"
    rm -f "$test_file"
}

test_utils_sed_i_002() {
    local test_file
    test_file=$(mktemp /tmp/test_sed_XXXXXX)
    echo "foo bar foo" > "$test_file"
    sed_i 's/foo/baz/' "$test_file"
    local content
    content=$(cat "$test_file")
    assert_eq "baz bar foo" "$content" "sed_i replaces first occurrence only"
    rm -f "$test_file"
}

test_utils_run_with_timeout_001() {
    echo "  Testing run_with_timeout"
    local result
    result=$(run_with_timeout 2 sleep 0.5)
    assert_eq "0" "$?" "run_with_timeout completes successfully"
}

test_utils_run_with_timeout_002() {
    local result
    result=$(run_with_timeout 1 sleep 2 2>&1) && result=0 || result=$?
    assert_eq "124" "$result" "run_with_timeout times out (exit 124)"
}

test_utils_file_operations_001() {
    echo "  Testing file operations"
    assert_success "[[ -f ${BASH_SOURCE[0]} ]]" "Test file exists"
}

run_test_utils_tests() {
    echo ""
    echo "=== Utils Module Tests ==="
    test_utils_check_dependencies_001
    test_utils_parse_yaml_001
    test_utils_parse_yaml_002
    test_utils_parse_yaml_003
    test_utils_count_lines_001
    test_utils_count_lines_002
    test_utils_count_lines_003
    test_utils_extract_trigger_001
    test_utils_calculate_percentage_001
    test_utils_calculate_percentage_002
    test_utils_calculate_percentage_003
    test_utils_log_functions_001
    test_utils_log_functions_002
    test_utils_log_functions_003
    test_utils_log_functions_004
    test_utils_sed_i_001
    test_utils_sed_i_002
    test_utils_run_with_timeout_001
    test_utils_run_with_timeout_002
    test_utils_file_operations_001
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_test_utils_tests
    echo ""
    echo "Results: $TEST_PASSED/$TEST_COUNT passed"
    [[ $TEST_FAILED -gt 0 ]] && exit 1 || exit 0
fi
