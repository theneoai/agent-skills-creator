#!/usr/bin/env bash
# rollback.sh - 回滚机制

source "$(dirname "${BASH_SOURCE[0]}")/../lib/bootstrap.sh"
require constants errors

# ============================================================================
# 快照管理
# ============================================================================

create_snapshot() {
    local skill_file="$1"
    local reason="${2:-auto}"
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local snapshot_name="skill_${timestamp}_${reason}"
    local snapshot_dir="${SNAPSHOT_DIR}/$(basename "$skill_file")"
    local snapshot_file="${snapshot_dir}/${snapshot_name}.tar.gz"
    
    if [[ ! -f "$skill_file" ]]; then
        log_error "SNAPSHOT_ERROR" "Skill file not found: $skill_file" "create_snapshot"
        return 1
    fi
    
    mkdir -p "$snapshot_dir"
    tar -czf "$snapshot_file" -C "$(dirname "$skill_file")" "$(basename "$skill_file")"
    cleanup_snapshots
    
    echo "$snapshot_file"
}

list_snapshots() {
    find "${SNAPSHOT_DIR}" -name "*.tar.gz" -type f 2>/dev/null | sort -r | head -20
}

rollback_to() {
    local snapshot_file="$1"
    local skill_file="$2"
    
    if [[ ! -f "$snapshot_file" ]]; then
        log_error "SNAPSHOT_ERROR" "Snapshot not found: $snapshot_file" "rollback_to"
        return 1
    fi
    
    tar -xzf "$snapshot_file" -C "$(dirname "$skill_file")"
    echo "Rolled back to: $snapshot_file"
}

rollback_to_latest() {
    local skill_file="${1:-$SKILL_FILE}"
    local latest
    latest=$(find "${SNAPSHOT_DIR}" -name "*.tar.gz" -type f 2>/dev/null | head -1)
    
    if [[ -n "$latest" ]]; then
        rollback_to "$latest" "$skill_file"
    else
        echo "No snapshots found"
        return 1
    fi
}

rollback_to_date() {
    local date_str="$1"
    local skill_file="$2"
    local snapshot
    snapshot=$(find "${SNAPSHOT_DIR}" -name "skill_${date_str}_*.tar.gz" -type f 2>/dev/null | head -1)
    
    if [[ -n "$snapshot" ]]; then
        rollback_to "$snapshot" "$skill_file"
    else
        echo "No snapshots found for date: $date_str"
        return 1
    fi
}

cleanup_snapshots() {
    local count
    count=$(find "${SNAPSHOT_DIR}" -name "*.tar.gz" -type f 2>/dev/null | wc -l)
    
    if [[ $count -gt $MAX_SNAPSHOTS ]]; then
        find "${SNAPSHOT_DIR}" -name "*.tar.gz" -type f 2>/dev/null | tail -n $((count - MAX_SNAPSHOTS)) | xargs rm -f 2>/dev/null
    fi
}

check_auto_rollback() {
    local current_score="$1"
    local previous_score="$2"
    local format_valid="${3:-true}"
    local skill_file="${4:-$SKILL_FILE}"
    
    if [[ "$format_valid" != "true" ]]; then
        echo "AUTO_ROLLBACK: Invalid format detected"
        rollback_to_latest "$skill_file"
        return 0
    fi
    
    local regression=$(echo "$previous_score - $current_score" | bc)
    
    if [[ "$(echo "$regression > 20" | bc -l)" == "1" ]]; then
        echo "AUTO_ROLLBACK: Score regression $regression points"
        rollback_to_latest "$skill_file"
        return 0
    fi
    
    return 1
}