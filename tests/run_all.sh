#!/usr/bin/env bash
# 运行所有测试

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================"
echo "  运行所有测试"
echo "========================================"

# 单元测试
if [[ -f "${SCRIPT_DIR}/unit/run_tests.sh" ]]; then
    bash "${SCRIPT_DIR}/unit/run_tests.sh" || true
fi

# 业务测试
if [[ -f "${SCRIPT_DIR}/business/run_tests.sh" ]]; then
    bash "${SCRIPT_DIR}/business/run_tests.sh" || true
fi

# 集成测试
if [[ -f "${SCRIPT_DIR}/integration/run_tests.sh" ]]; then
    bash "${SCRIPT_DIR}/integration/run_tests.sh" || true
fi

# E2E测试
if [[ -f "${SCRIPT_DIR}/e2e/run_tests.sh" ]]; then
    bash "${SCRIPT_DIR}/e2e/run_tests.sh" || true
fi

echo ""
echo "========================================"
echo "  所有测试完成"
echo "========================================"
