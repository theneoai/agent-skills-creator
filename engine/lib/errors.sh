#!/usr/bin/env bash
# errors.sh - 错误处理 (bash 3.2 compatible)

source "$(dirname "${BASH_SOURCE[0]}")/bootstrap.sh"
require constants

# ============================================================================
# 错误类型查询
# ============================================================================

get_error_type() {
    local error_type="$1"
    case "$error_type" in
        LLM_TIMEOUT) echo "LLM调用超时" ;;
        LLM_ERROR) echo "LLM返回错误" ;;
        INVALID_FORMAT) echo "SKILL.md格式无效" ;;
        EVAL_FAILURE) echo "评估失败" ;;
        FILE_ERROR) echo "文件操作失败" ;;
        NETWORK_ERROR) echo "网络错误" ;;
        LOCK_FAILED) echo "获取锁失败" ;;
        SNAPSHOT_ERROR) echo "快照保存失败" ;;
        *) echo "未知错误" ;;
    esac
}

get_error_recovery() {
    local error_type="$1"
    case "$error_type" in
        LLM_TIMEOUT) echo "retry:3:exp_backoff:1,2,4" ;;
        LLM_ERROR) echo "retry:2:exp_backoff:1,2" ;;
        INVALID_FORMAT) echo "rollback" ;;
        EVAL_FAILURE) echo "skip" ;;
        FILE_ERROR) echo "alert" ;;
        NETWORK_ERROR) echo "retry:3:exp_backoff:5,10,15" ;;
        LOCK_FAILED) echo "fail" ;;
        SNAPSHOT_ERROR) echo "fail" ;;
        *) echo "fail" ;;
    esac
}

# ============================================================================
# 错误处理函数
# ============================================================================

log_error() {
    local error_type="$1"
    local error_msg="$2"
    local context="${3:-}"
    local timestamp
    timestamp=$(get_timestamp)
    
    ensure_directory "$(dirname "$ERROR_LOG")"
    echo "{\"timestamp\":\"$timestamp\",\"type\":\"$error_type\",\"message\":\"$error_msg\",\"context\":\"$context\"}" >> "$ERROR_LOG" 2>/dev/null || true
}

handle_error() {
    local error_type="$1"
    local error_msg="$2"
    local context="$3"
    shift 3
    
    log_error "$error_type" "$error_msg" "$context"
    
    local recovery
    recovery=$(get_error_recovery "$error_type")
    local action="${recovery%%:*}"
    
    case "$action" in
        retry)
            local max_retries="${recovery%%:*}"
            max_retries="${max_retries#retry:}"
            local delay_type="${recovery#*:}"
            delay_type="${delay_type%%:*}"
            local delays="${recovery##*:}"
            IFS=',' read -ra delay_array <<< "$delays"
            
            local i
            for i in "${!delay_array[@]}"; do
                local delay="${delay_array[$i]}"
                sleep "$delay" 2>/dev/null || sleep 1
                if "$@"; then
                    return 0
                fi
            done
            return 1
            ;;
        rollback)
            rollback_to_latest 2>/dev/null
            return 1
            ;;
        skip)
            return 1
            ;;
        alert)
            echo "ALERT: $error_type - $error_msg" >&2
            return 1
            ;;
        fail)
            echo "FATAL: $error_type - $error_msg" >&2
            return 1
            ;;
    esac
}

retry_with_backoff() {
    local max_attempts="${1:-3}"
    shift
    local delays="1 2 4 8 16"
    
    local i
    for i in 1 2 3; do
        if "$@"; then
            return 0
        fi
        if [[ $i -lt $max_attempts ]]; then
            local delay=$(echo "$delays" | cut -d' ' -f$((i)))
            sleep "${delay:-1}" 2>/dev/null || sleep 1
        fi
    done
    return 1
}