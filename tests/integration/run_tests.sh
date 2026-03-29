#!/usr/bin/env bash
# 集成测试运行器

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "${PROJECT_ROOT}/tests/framework.sh"

echo "========================================"
echo "  集成测试"
echo "========================================"

TEST_DIR="${SCRIPT_DIR}"

run_test_file() {
    local test_file="$1"
    local test_name
    test_name=$(basename "$test_file" .sh)
    echo ""
    echo "=== $test_name ==="
    source "$test_file"
    
    local test_funcs
    test_funcs=$(grep -oE '^test_[a-zA-Z0-9_]+[[:space:]]*\(\)' "$test_file" | sed 's/()$//' | sort)
    
    for func in $test_funcs; do
        echo "  Running: $func"
        $func || true
    done
}

for test_file in "${TEST_DIR}"/test_*.sh; do
    if [[ -f "$test_file" ]]; then
        run_test_file "$test_file"
    fi
done

report
