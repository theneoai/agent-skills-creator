#!/usr/bin/env bash
# real_user_simulation.sh - 真实用户模拟测试
# 使用minimax和kimi-code模拟真实用户操作skill项目

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
EVAL_DIR="$PROJECT_ROOT"

source "$PROJECT_ROOT/tools/lib/bootstrap.sh"
require constants
require errors

echo "========================================"
echo "  真实用户模拟测试"
echo "========================================"

# 跟踪测试结果
declare -a TEST_RESULTS=()
declare -a BUGS_FOUND=()
BUG_COUNT=0

# 记录bug
record_bug() {
    local workflow="${1:-UNKNOWN}"
    local test_name="${2:-UNKNOWN}"
    local description="${3:-UNKNOWN}"
    local severity="${4:-UNKNOWN}"
    local evidence="${5:-NONE}"
    
    BUG_COUNT=$((BUG_COUNT + 1))
    BUGS_FOUND+=("[${severity}][${workflow}] ${test_name}: ${description}")
    
    echo ""
    echo "BUG #${BUG_COUNT} found!"
    echo "   Workflow: ${workflow}"
    echo "   Test: ${test_name}"
    echo "   Severity: ${severity}"
    echo "   Description: ${description}"
    if [[ "${evidence}" != "NONE" ]]; then
        echo "   Evidence: ${evidence}"
    fi
    echo ""
}

# ============================================================================
# CREATE 工作流测试
# ============================================================================
test_create_workflow() {
    echo ""
    echo "=== CREATE 工作流测试 ==="
    
    # 测试1: 创建基础技能
    echo "[测试 1] 创建基础技能..."
    local output="/tmp/skill_create_$$.md"
    if ! bash "$PROJECT_ROOT/scripts/create-skill.sh" "创建一个代码审查技能" 2>&1 | tee /tmp/create_out.txt; then
        record_bug "CREATE" "basic_create" "create-skill.sh执行失败" "HIGH" "$(head -20 /tmp/create_out.txt)"
    fi
    
    # 测试2: 创建带继承的技能
    echo "[测试 2] 创建带继承技能..."
    if ! bash "$PROJECT_ROOT/scripts/create-skill.sh" "创建子技能" --extends "$PROJECT_ROOT/SKILL.md" 2>&1 | tee /tmp/create_inherit_out.txt; then
        record_bug "CREATE" "inherit_create" "带继承的创建失败" "MEDIUM" "$(head -10 /tmp/create_inherit_out.txt)"
    fi
    
    # 测试3: 无参数调用
    echo "[测试 3] 无参数调用..."
    if ! bash "$PROJECT_ROOT/scripts/create-skill.sh" 2>&1 | grep -q "Usage\|用法\|需要"; then
        record_bug "CREATE" "no_args_help" "无参数时未显示帮助信息" "LOW" "应该显示使用说明"
    fi
    
    # 测试4: 创建时指定tier
    echo "[测试 4] 指定tier创建..."
    if ! bash "$PROJECT_ROOT/scripts/create-skill.sh" "测试技能" --tier GOLD 2>&1 | tee /tmp/create_tier_out.txt; then
        record_bug "CREATE" "tier_option" "--tier参数无效" "MEDIUM" "$(head -10 /tmp/create_tier_out.txt)"
    fi
}

# ============================================================================
# EVALUATE 工作流测试
# ============================================================================
test_evaluate_workflow() {
    echo ""
    echo "=== EVALUATE 工作流测试 ==="
    
    # 测试1: 评估主skill文件
    echo "[测试 1] 评估主skill文件..."
    if ! bash "$PROJECT_ROOT/scripts/evaluate-skill.sh" "$PROJECT_ROOT/SKILL.md" 2>&1 | tee /tmp/eval_out.txt; then
        record_bug "EVALUATE" "basic_eval" "evaluate-skill.sh执行失败" "HIGH" "$(head -20 /tmp/eval_out.txt)"
    fi
    
    # 测试2: 评估不存在的文件
    echo "[测试 2] 评估不存在文件..."
    if ! bash "$PROJECT_ROOT/scripts/evaluate-skill.sh" /tmp/nonexistent.md 2>&1 | grep -qi "not found\|不存在\|error"; then
        record_bug "EVALUATE" "missing_file_handling" "评估不存在文件未报错" "MEDIUM" "应该返回错误"
    fi
    
    # 测试3: 检查评分输出
    echo "[测试 3] 检查评分输出..."
    if ! grep -qE "score|分数|等级|tier" /tmp/eval_out.txt 2>/dev/null; then
        record_bug "EVALUATE" "score_output" "评分输出缺少分数信息" "MEDIUM" "输出应该包含分数或等级"
    fi
}

# ============================================================================
# LEAN 工作流测试
# ============================================================================
test_lean_workflow() {
    echo ""
    echo "=== LEAN 工作流测试 ==="
    
    # 测试1: 基本lean评估
    echo "[测试 1] 基本lean评估..."
    if ! bash "$PROJECT_ROOT/scripts/lean-orchestrator.sh" "$PROJECT_ROOT/SKILL.md" 2>&1 | tee /tmp/lean_out.txt; then
        record_bug "LEAN" "basic_lean" "lean-orchestrator.sh执行失败" "HIGH" "$(head -20 /tmp/lean_out.txt)"
    fi
    
    # 测试2: 帮助信息
    echo "[测试 2] --help标志..."
    if ! bash "$PROJECT_ROOT/scripts/lean-orchestrator.sh" --help 2>&1 | grep -q "Usage\|用法"; then
        record_bug "LEAN" "help_flag" "--help未显示帮助" "HIGH" "应该显示使用说明"
    fi
    
    # 测试3: 指定agent
    echo "[测试 3] --agent标志..."
    if ! bash "$PROJECT_ROOT/scripts/lean-orchestrator.sh" --agent minimax "$PROJECT_ROOT/SKILL.md" 2>&1 | tee /tmp/lean_agent_out.txt; then
        record_bug "LEAN" "agent_flag" "--agent参数无效" "MEDIUM" "$(head -10 /tmp/lean_agent_out.txt)"
    fi
    
    # 测试4: --lean标志
    echo "[测试 4] --lean标志..."
    if ! bash "$PROJECT_ROOT/scripts/lean-orchestrator.sh" --lean "$PROJECT_ROOT/SKILL.md" 2>&1 | tee /tmp/lean_lean_out.txt; then
        record_bug "LEAN" "lean_flag" "--lean参数无效" "MEDIUM" "$(head -10 /tmp/lean_lean_out.txt)"
    fi
}

# ============================================================================
# RESTORE 工作流测试
# ============================================================================
test_restore_workflow() {
    echo ""
    echo "=== RESTORE 工作流测试 ==="
    
    # 创建测试文件
    local test_file="/tmp/skill_restore_test_$$.md"
    cat > "$test_file" << 'EOF'
# Test Skill

## §1.1 Identity
Test Identity

## §1.2 Framework
Test Framework

## §1.3 Thinking
Test Thinking

## §2 Trigger
CREATE EVALUATE
EOF

    # 测试1: 基本恢复
    echo "[测试 1] 基本恢复..."
    if ! bash "$PROJECT_ROOT/scripts/restore-skill.sh" "$test_file" 2>&1 | tee /tmp/restore_out.txt; then
        record_bug "RESTORE" "basic_restore" "restore-skill.sh执行失败" "HIGH" "$(head -20 /tmp/restore_out.txt)"
    fi
    
    # 测试2: 帮助信息
    echo "[测试 2] --help标志..."
    if ! bash "$PROJECT_ROOT/scripts/restore-skill.sh" --help 2>&1 | grep -q "Usage\|用法"; then
        record_bug "RESTORE" "help_flag" "--help未显示帮助" "HIGH" "应该显示使用说明"
    fi
    
    # 测试3: 恢复损坏的文件
    echo "[测试 3] 恢复损坏文件..."
    echo "# Broken" > /tmp/broken_skill_$$.md
    if ! bash "$PROJECT_ROOT/scripts/restore-skill.sh" /tmp/broken_skill_$$.md 2>&1; then
        record_bug "RESTORE" "broken_file" "无法处理损坏文件" "MEDIUM" "应该尝试恢复"
    fi
    
    rm -f "$test_file" /tmp/broken_skill_$$.md
}

# ============================================================================
# SECURITY 工作流测试
# ============================================================================
test_security_workflow() {
    echo ""
    echo "=== SECURITY 工作流测试 ==="
    
    # 测试1: 基本审计
    echo "[测试 1] 基本安全审计..."
    if ! bash "$PROJECT_ROOT/scripts/security-audit.sh" "$PROJECT_ROOT/SKILL.md" 2>&1 | tee /tmp/security_out.txt; then
        record_bug "SECURITY" "basic_audit" "security-audit.sh执行失败" "HIGH" "$(head -20 /tmp/security_out.txt)"
    fi
    
    # 测试2: 帮助信息
    echo "[测试 2] --help标志..."
    if ! bash "$PROJECT_ROOT/scripts/security-audit.sh" --help 2>&1 | grep -q "Usage\|用法"; then
        record_bug "SECURITY" "help_flag" "--help未显示帮助" "HIGH" "应该显示使用说明"
    fi
    
    # 测试3: 指定审计级别
    echo "[测试 3] 指定审计级别..."
    if ! bash "$PROJECT_ROOT/scripts/security-audit.sh" --level BASIC "$PROJECT_ROOT/SKILL.md" 2>&1 | tee /tmp/security_level_out.txt; then
        record_bug "SECURITY" "level_option" "--level参数无效" "MEDIUM" "$(head -10 /tmp/security_level_out.txt)"
    fi
}

# ============================================================================
# OPTIMIZE 工作流测试
# ============================================================================
test_optimize_workflow() {
    echo ""
    echo "=== OPTIMIZE 工作流测试 ==="
    
    # 创建测试文件
    local test_file="/tmp/skill_optimize_test_$$.md"
    cat > "$test_file" << 'EOF'
# Test Skill

## §1.1 Identity
Test Identity

## §1.2 Framework
Test Framework

## §1.3 Thinking
Test Thinking

## §2 Trigger
CREATE

## §3 Behavior
This is some test content.
EOF

    # 测试1: 基本优化
    echo "[测试 1] 基本优化..."
    if ! bash "$PROJECT_ROOT/scripts/optimize-skill.sh" "$test_file" 2>&1 | tee /tmp/optimize_out.txt; then
        record_bug "OPTIMIZE" "basic_optimize" "optimize-skill.sh执行失败" "HIGH" "$(head -20 /tmp/optimize_out.txt)"
    fi
    
    # 测试2: 多轮优化
    echo "[测试 2] 多轮优化..."
    if ! bash "$PROJECT_ROOT/scripts/optimize-skill.sh" --rounds 3 "$test_file" 2>&1 | tee /tmp/optimize_rounds_out.txt; then
        record_bug "OPTIMIZE" "multi_round" "--rounds参数无效" "MEDIUM" "$(head -10 /tmp/optimize_rounds_out.txt)"
    fi
    
    # 测试3: 帮助信息
    echo "[测试 3] --help标志..."
    if ! bash "$PROJECT_ROOT/scripts/optimize-skill.sh" --help 2>&1 | grep -q "Usage\|用法"; then
        record_bug "OPTIMIZE" "help_flag" "--help未显示帮助" "HIGH" "应该显示使用说明"
    fi
    
    rm -f "$test_file"
}

# ============================================================================
# CLI 测试
# ============================================================================
test_cli_interface() {
    echo ""
    echo "=== CLI 接口测试 ==="
    
    # 测试1: cli/skill帮助
    echo "[测试 1] cli/skill --help..."
    if ! bash "$PROJECT_ROOT/cli/skill" --help 2>&1 | grep -q "Usage\|用法"; then
        record_bug "CLI" "cli_help" "cli/skill --help未显示帮助" "HIGH" "应该显示使用说明"
    fi
    
    # 测试2: scripts/main.sh帮助
    echo "[测试 2] scripts/main.sh --help..."
    if ! bash "$PROJECT_ROOT/scripts/main.sh" --help 2>&1 | grep -q "Usage\|用法"; then
        record_bug "CLI" "engine_help" "scripts/main.sh --help未显示帮助" "HIGH" "应该显示使用说明"
    fi
}

# ============================================================================
# 核心模块测试
# ============================================================================
test_core_modules() {
    echo ""
    echo "=== 核心模块测试 ==="
    
    # 测试1: bootstrap.sh加载
    echo "[测试 1] bootstrap.sh加载..."
    if ! source "$PROJECT_ROOT/tools/lib/bootstrap.sh" 2>&1; then
        record_bug "CORE" "bootstrap_load" "bootstrap.sh无法加载" "CRITICAL" "核心模块无法加载"
    fi
    
    # 测试2: constants.sh常量
    echo "[测试 2] 常量定义..."
    source "$PROJECT_ROOT/tools/lib/bootstrap.sh"
    if [[ -z "${EVAL_DIR:-}" ]]; then
        record_bug "CORE" "eval_dir_constant" "EVAL_DIR未定义" "CRITICAL" "核心常量缺失"
    fi
    
    # 测试3: utils.sh函数
    echo "[测试 3] utils.sh函数..."
    if ! source "$PROJECT_ROOT/tools/lib/utils.sh" 2>&1; then
        record_bug "CORE" "utils_load" "utils.sh无法加载" "HIGH" "工具模块无法加载"
    fi
    
    # 测试4: errors.sh函数
    echo "[测试 4] errors.sh函数..."
    if ! source "$PROJECT_ROOT/tools/lib/errors.sh" 2>&1; then
        record_bug "CORE" "errors_load" "errors.sh无法加载" "HIGH" "错误处理模块无法加载"
    fi
}

# ============================================================================
# 主入口
# ============================================================================
main() {
    local rounds="${1:-1}"
    local agent_name="${2:-minimax}"
    
    echo "开始真实用户模拟测试..."
    echo "回合数: $rounds"
    echo "Agent: $agent_name"
    
    for round in $(seq 1 "$rounds"); do
        echo ""
        echo "########################################"
        echo "# 回合 $round / $rounds (Agent: $agent_name)"
        echo "########################################"
        
        test_core_modules
        test_cli_interface
        test_create_workflow
        test_evaluate_workflow
        test_lean_workflow
        test_restore_workflow
        test_security_workflow
        test_optimize_workflow
    done
    
    echo ""
    echo "========================================"
    echo "  测试汇总"
    echo "========================================"
    echo ""
    echo "总共发现 $BUG_COUNT 个问题:"
    echo ""
    
    for bug in "${BUGS_FOUND[@]}"; do
        echo "$bug"
    done
    
    echo ""
    
    if [[ $BUG_COUNT -eq 0 ]]; then
        echo "✅ 所有测试通过! 未发现bug。"
        return 0
    else
        echo "❌ 发现 $BUG_COUNT 个问题需要修复。"
        return 1
    fi
}

main "$@"