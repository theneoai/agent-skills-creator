#!/usr/bin/env bash
# orchestrator.sh - 双Agent协调器
#
# 使用模块化结构:
#   _state.sh     - 状态管理
#   _workflow.sh  - 工作流控制
#   _actions.sh  - 操作决策
#   _parallel.sh  - 并行执行

source "$(dirname "${BASH_SOURCE[0]}")/lib/bootstrap.sh"
source "$(dirname "${BASH_SOURCE[0]}")/orchestrator/_state.sh"
source "$(dirname "${BASH_SOURCE[0]}")/orchestrator/_workflow.sh"
source "$(dirname "${BASH_SOURCE[0]}")/orchestrator/_actions.sh"
source "$(dirname "${BASH_SOURCE[0]}")/orchestrator/_parallel.sh"

# ============================================================================
# 主入口
# ============================================================================

orchestrate() {
    local user_prompt="$1"
    local output_file="$2"
    
    workflow_init "$user_prompt" "$output_file"
    workflow_run
}

# ============================================================================
# CLI 接口
# ============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -lt 2 ]]; then
        echo "Usage: $0 <user_prompt> <output_file> [target_tier]"
        echo "  user_prompt   - Description of the skill to create"
        echo "  output_file   - Path to output SKILL.md file"
        echo "  target_tier   - Target tier (GOLD/SILVER/BRONZE, default: BRONZE)"
        exit 1
    fi
    
    if [[ -n "${3:-}" ]]; then
        TARGET_TIER="$3"
    fi
    
    orchestrate "$1" "$2"
fi