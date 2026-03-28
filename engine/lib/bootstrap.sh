#!/usr/bin/env bash
# bootstrap.sh - 统一模块加载机制
#
# 所有 engine 脚本应通过此文件初始化路径和加载依赖
# 使用方法: source "$(dirname "${BASH_SOURCE[0]}")/bootstrap.sh"

# ============================================================================
# 路径初始化
# ============================================================================

# 如果尚未定义 EVAL_DIR_FROM_ENGINE，则根据脚本位置自动计算
if [[ -z "${EVAL_DIR_FROM_ENGINE:-}" ]]; then
    EVAL_DIR_FROM_ENGINE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

# eval 路径（可通过环境变量覆盖）
if [[ -z "${EVAL_DIR:-}" ]]; then
    EVAL_DIR="$(cd "$EVAL_DIR_FROM_ENGINE/../eval" && pwd)"
fi

# ============================================================================
# 目录配置
# ============================================================================

LOG_DIR="${EVAL_DIR_FROM_ENGINE}/logs"
SNAPSHOT_DIR="/tmp/engine/snapshots"
LOCK_DIR="/tmp/engine/locks"

# 确保必要目录存在
mkdir -p "$LOG_DIR" "$SNAPSHOT_DIR" "$LOCK_DIR"

# ============================================================================
# 日志文件路径
# ============================================================================

USAGE_LOG="${LOG_DIR}/usage.log"
EVOLUTION_LOG="${LOG_DIR}/evolution.log"
ERROR_LOG="${LOG_DIR}/error.log"

# ============================================================================
# 模块加载函数
# ============================================================================

# require - 加载指定的 lib 模块
# 用法: require constants errors concurrency
require() {
    local module
    for module in "$@"; do
        if [[ -f "${EVAL_DIR_FROM_ENGINE}/lib/${module}.sh" ]]; then
            source "${EVAL_DIR_FROM_ENGINE}/lib/${module}.sh"
        fi
    done
}

# require_evolution - 加载 evolution 模块
require_evolution() {
    local module
    for module in "$@"; do
        if [[ -f "${EVAL_DIR_FROM_ENGINE}/evolution/${module}.sh" ]]; then
            source "${EVAL_DIR_FROM_ENGINE}/evolution/${module}.sh"
        fi
    done
}

# require_agent - 加载 agent 模块
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
export USAGE_LOG EVOLUTION_LOG ERROR_LOG