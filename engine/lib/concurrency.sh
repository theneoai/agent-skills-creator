#!/usr/bin/env bash
# concurrency.sh - 多Agent并发控制

source "$(dirname "${BASH_SOURCE[0]}")/bootstrap.sh"
require constants

# ============================================================================
# 锁管理
# ============================================================================

acquire_lock() {
    local lock_name="$1"
    local lock_file="${LOCK_DIR}/${lock_name}.lock"
    local timeout="${2:-30}"
    local start_time=$(date +%s)
    
    while true; do
        if mkdir "$lock_file" 2>/dev/null; then
            echo $$ > "${lock_file}/pid"
            return 0
        fi
        
        if [[ -d "$lock_file" ]]; then
            local pid_file="${lock_file}/pid"
            if [[ -f "$pid_file" ]]; then
                local pid=$(cat "$pid_file" 2>/dev/null)
                if [[ -n "$pid" ]] && ! kill -0 "$pid" 2>/dev/null; then
                    rm -rf "$lock_file"
                    continue
                fi
            fi
        fi
        
        local elapsed=$(($(date +%s) - start_time))
        if [[ $elapsed -ge $timeout ]]; then
            return 1
        fi
        
        sleep 1
    done
}

release_lock() {
    local lock_name="$1"
    local lock_file="${LOCK_DIR}/${lock_name}.lock"
    [[ -d "$lock_file" ]] && rm -rf "$lock_file"
}

with_lock() {
    local lock_name="$1"
    local timeout="${2:-60}"
    shift 2
    
    acquire_lock "$lock_name" "$timeout" || {
        echo "Error: Failed to acquire lock: $lock_name" >&2
        return 1
    }
    
    trap "release_lock '$lock_name'" EXIT
    
    "$@"
}

is_lock_available() {
    local lock_name="$1"
    local timeout="${2:-5}"
    
    acquire_lock "$lock_name" "$timeout" 2>/dev/null
    local result=$?
    
    if [[ $result -eq 0 ]]; then
        release_lock "$lock_name"
    fi
    
    return $result
}

is_running() {
    local lock_name="$1"
    local lock_file="${LOCK_DIR}/${lock_name}.lock"
    
    if [[ ! -d "$lock_file" ]]; then
        return 1
    fi
    
    local pid_file="${lock_file}/pid"
    if [[ -f "$pid_file" ]]; then
        local pid=$(cat "$pid_file" 2>/dev/null)
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            return 0
        fi
    fi
    
    rm -rf "$lock_file"
    return 1
}