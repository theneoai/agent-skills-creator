#!/usr/bin/env bash
# bootstrap.sh - 统一模块加载机制
#
# 所有 engine 脚本应通过此文件初始化路径和加载依赖
# 使用方法: source "$(dirname "${BASH_SOURCE[0]}")/bootstrap.sh"

# ============================================================================
# Guard against re-sourcing
# ============================================================================

if [[ -n "${_BOOTSTRAP_SOURCED:-}" ]]; then
    return 0
fi
export _BOOTSTRAP_SOURCED=1

# ============================================================================
# 路径初始化
# ============================================================================

# 如果尚未定义 EVAL_DIR_FROM_ENGINE，则根据脚本位置自动计算
if [[ -z "${EVAL_DIR_FROM_ENGINE:-}" ]]; then
    EVAL_DIR_FROM_ENGINE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

# eval 路径（可通过环境变量覆盖）
if [[ -z "${EVAL_DIR:-}" ]]; then
    if [[ -d "$EVAL_DIR_FROM_ENGINE/../eval" ]]; then
        EVAL_DIR="$(cd "$EVAL_DIR_FROM_ENGINE/../eval" && pwd)"
    elif [[ -d "$EVAL_DIR_FROM_ENGINE/../../eval" ]]; then
        EVAL_DIR="$(cd "$EVAL_DIR_FROM_ENGINE/../../eval" && pwd)"
    elif [[ -d "./eval" ]]; then
        EVAL_DIR="$(cd ./eval && pwd)"
    else
        echo "ERROR: Cannot locate eval directory" >&2
        return 1
    fi
fi

# ============================================================================
# 目录配置
# ============================================================================

LOG_DIR="${EVAL_DIR_FROM_ENGINE}/logs"
SNAPSHOT_DIR="${SNAPSHOT_DIR:-/tmp/engine/snapshots}"
LOCK_DIR="${LOCK_DIR:-/tmp/engine/locks}"
EVOLUTION_USAGE_DIR="${LOG_DIR}/evolution"

# 确保必要目录存在
mkdir -p "$LOG_DIR" "$SNAPSHOT_DIR" "$LOCK_DIR" 2>/dev/null || true

# ============================================================================
# 日志文件路径
# ============================================================================

USAGE_LOG="${LOG_DIR}/usage.log"
EVOLUTION_LOG="${LOG_DIR}/evolution.log"
ERROR_LOG="${LOG_DIR}/error.log"

# ============================================================================
# 模块加载函数
# ============================================================================

# require - 统一加载 lib/evolution/agent 模块
# 用法:
#   require constants errors        # lib modules
#   require evolution:rollback     # evolution modules
#   require agent:evaluator      # agent modules
require() {
    local module
    for module in "$@"; do
        case "$module" in
            agent:*)
                local agent_name="${module#agent:}"
                if [[ -f "${EVAL_DIR_FROM_ENGINE}/agents/${agent_name}.sh" ]]; then
                    source "${EVAL_DIR_FROM_ENGINE}/agents/${agent_name}.sh"
                fi
                ;;
            evolution:*)
                local evo_name="${module#evolution:}"
                if [[ -f "${EVAL_DIR_FROM_ENGINE}/evolution/${evo_name}.sh" ]]; then
                    source "${EVAL_DIR_FROM_ENGINE}/evolution/${evo_name}.sh"
                fi
                ;;
            *)
                if [[ -f "${EVAL_DIR_FROM_ENGINE}/lib/${module}.sh" ]]; then
                    source "${EVAL_DIR_FROM_ENGINE}/lib/${module}.sh"
                fi
                ;;
        esac
    done
}

# require_evolution - 加载 evolution 模块 (保持向后兼容)
require_evolution() {
    local module
    for module in "$@"; do
        if [[ -f "${EVAL_DIR_FROM_ENGINE}/evolution/${module}.sh" ]]; then
            source "${EVAL_DIR_FROM_ENGINE}/evolution/${module}.sh"
        fi
    done
}

# require_agent - 加载 agent 模块 (保持向后兼容)
require_agent() {
    local module="${1:-}"
    if [[ -n "$module" ]] && [[ -f "${EVAL_DIR_FROM_ENGINE}/agents/${module}.sh" ]]; then
        source "${EVAL_DIR_FROM_ENGINE}/agents/${module}.sh"
    fi
}

# load_prompt - 从 prompts 目录加载提示词
# 用法: load_prompt creator-system
load_prompt() {
    local prompt_name="$1"
    local prompt_file="${EVAL_DIR_FROM_ENGINE}/prompts/${prompt_name}.md"
    
    if [[ -f "$prompt_file" ]]; then
        cat "$prompt_file"
    else
        echo "ERROR: Prompt file not found: $prompt_file" >&2
        return 1
    fi
}

# ============================================================================
# 工具函数
# ============================================================================

# get_timestamp - 获取 ISO 8601 格式时间戳
get_timestamp() {
    date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date +%Y-%m-%dT%H:%M:%SZ
}

# ensure_directory - 确保目录存在
ensure_directory() {
    local dir="$1"
    mkdir -p "$dir"
}

# ============================================================================
# 导出环境
# ============================================================================

export EVAL_DIR_FROM_ENGINE EVAL_DIR
export LOG_DIR SNAPSHOT_DIR LOCK_DIR
export USAGE_LOG EVOLUTION_LOG ERROR_LOG EVOLUTION_USAGE_DIR