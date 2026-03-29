#!/usr/bin/env bash
# base.sh - Agent 基类
#
# 提供 Agent 的公共基础设施:
# - 路径初始化
# - 提示词加载
# - LLM 调用封装

source "$(dirname "${BASH_SOURCE[0]}")/../lib/bootstrap.sh"
source "${EVAL_DIR}/lib/agent_executor.sh"

# ============================================================================
# Agent 初始化
# ============================================================================

agent_init() {
    require constants concurrency errors
}

# ============================================================================
# 提示词加载
# ============================================================================

agent_load_system_prompt() {
    local prompt_name="$1"
    load_prompt "${prompt_name}-system"
}

agent_load_user_prompt() {
    local prompt_name="$1"
    load_prompt "${prompt_name}-user"
}

# ============================================================================
# LLM 调用封装
# ============================================================================

agent_call_llm() {
    local system_prompt="$1"
    local user_prompt="$2"
    local model="${3:-auto}"
    local provider="${4:-auto}"
    
    call_llm "$system_prompt" "$user_prompt" "$model" "$provider"
}

agent_call_llm_json() {
    local system_prompt="$1"
    local user_prompt="$2"
    local model="${3:-auto}"
    local provider="${4:-auto}"
    
    call_llm_json "$system_prompt" "$user_prompt" "$model" "$provider"
}

# ============================================================================
# 工具函数
# ============================================================================

agent_parse_json() {
    local json="$1"
    local key="$2"
    echo "$json" | jq -r "${key}" 2>/dev/null || echo ""
}

agent_validate_json() {
    local json="$1"
    echo "$json" | jq -e '.' >/dev/null 2>&1
}

agent_temp_file() {
    mktemp /tmp/agent_XXXXXX.json
}