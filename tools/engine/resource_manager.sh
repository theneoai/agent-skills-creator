#!/usr/bin/env bash
# resource_manager.sh - 资源清理管理
#
# 管理日志、快照、usage文件的TTL清理:
# - 快照: 保留最近N个版本
# - Usage文件: 保留最近N天
# - 日志: 保留最近N天, 自动压缩

RESOURCE_MANAGER_VERSION="1.0"

MAX_SNAPSHOTS="${MAX_SNAPSHOTS:-10}"
MAX_USAGE_DAYS="${MAX_USAGE_DAYS:-30}"
MAX_LOG_DAYS="${MAX_LOG_DAYS:-14}"
SNAPSHOT_DIR="${SNAPSHOT_DIR:-${PROJECT_ROOT}/snapshots}"
EVOLUTION_USAGE_DIR="${EVOLUTION_USAGE_DIR:-${PROJECT_ROOT}/evolution/usage}"
LOG_DIR="${LOG_DIR:-${PROJECT_ROOT}/logs}"

cleanup_snapshots() {
    local skill_name="${1:-}"
    local max="${2:-$MAX_SNAPSHOTS}"
    
    local snapshot_dir="$SNAPSHOT_DIR"
    if [[ -n "$skill_name" ]]; then
        snapshot_dir="${snapshot_dir}/${skill_name}"
    fi
    
    if [[ ! -d "$snapshot_dir" ]]; then
        return 0
    fi
    
    local count
    count=$(find "$snapshot_dir" -name "*.tar.gz" -type f 2>/dev/null | wc -l | tr -d ' ')
    
    if [[ $count -le $max ]]; then
        return 0
    fi
    
    local excess
    excess=$((count - max))
    
    find "$snapshot_dir" -name "*.tar.gz" -type f -printf '%T+ %p\n' 2>/dev/null | \
        sort | head -$excess | cut -d' ' -f2 | \
        while read -r file; do
            rm -f "$file"
            echo "Cleaned snapshot: $file"
        done
    
    local remaining
    remaining=$(find "$snapshot_dir" -name "*.tar.gz" -type f 2>/dev/null | wc -l | tr -d ' ')
    echo "Snapshots cleaned: $excess removed, $remaining remaining"
}

cleanup_usage_files() {
    local max_days="${1:-$MAX_USAGE_DAYS}"
    local skill_name="${2:-}"
    
    local usage_dir="$EVOLUTION_USAGE_DIR"
    [[ -n "$skill_name" ]] && usage_dir="${usage_dir}/usage_${skill_name}"
    
    if [[ ! -d "$usage_dir" ]]; then
        return 0
    fi
    
    local cutoff_date
    cutoff_date=$(date -v-${max_days}d +%Y%m%d 2>/dev/null || date -d "-${max_days} days" +%Y%m%d)
    
    local cleaned=0
    for file in "$usage_dir"/*.jsonl 2>/dev/null; do
        [[ -f "$file" ]] || continue
        
        local filename
        filename=$(basename "$file")
        
        local file_date
        file_date=$(echo "$filename" | grep -oE '[0-9]{8}' | head -1)
        
        if [[ -n "$file_date" ]] && [[ "$file_date" < "$cutoff_date" ]]; then
            rm -f "$file"
            cleaned=$((cleaned + 1))
        fi
    done
    
    echo "Usage files cleaned: $cleaned files removed"
}

cleanup_logs() {
    local max_days="${1:-$MAX_LOG_DAYS}"
    local log_dir="${2:-$LOG_DIR}"
    
    if [[ ! -d "$log_dir" ]]; then
        return 0
    fi
    
    local cutoff_date
    cutoff_date=$(date -v-${max_days}d +%Y%m%d 2>/dev/null || date -d "-${max_days} days" +%Y%m%d)
    
    local cleaned=0
    local compressed=0
    
    for file in "$log_dir"/*.log 2>/dev/null; do
        [[ -f "$file" ]] || continue
        
        local filename
        filename=$(basename "$file")
        
        local file_date
        file_date=$(echo "$filename" | grep -oE '[0-9]{8}' | head -1)
        
        if [[ -n "$file_date" ]] && [[ "$file_date" < "$cutoff_date" ]]; then
            if [[ ! -f "${file}.gz" ]]; then
                gzip -f "$file"
                compressed=$((compressed + 1))
            else
                rm -f "$file"
            fi
            cleaned=$((cleaned + 1))
        fi
    done
    
    for file in "$log_dir"/*.log.gz 2>/dev/null; do
        [[ -f "$file" ]] || continue
        
        local gz_date
        gz_date=$(stat -f "%Sm" -t "%Y%m%d" "$file" 2>/dev/null || stat -c "%y" "$file" | cut -d' ' -f1 | tr -d '-')
        
        if [[ -n "$gz_date" ]] && [[ "$gz_date" < "$cutoff_date" ]]; then
            rm -f "$file"
            cleaned=$((cleaned + 1))
        fi
    done
    
    echo "Logs cleaned: $cleaned files processed, $compressed compressed"
}

cleanup_all() {
    local skill_name="${1:-}"
    local dry_run="${2:-false}"
    
    echo "=== Resource Cleanup ==="
    echo "Skill: ${skill_name:-all}"
    echo "Max Snapshots: $MAX_SNAPSHOTS"
    echo "Max Usage Days: $MAX_USAGE_DAYS"
    echo "Max Log Days: $MAX_LOG_DAYS"
    echo ""
    
    if [[ "$dry_run" == "true" ]]; then
        echo "[DRY RUN] Would clean:"
    else
        echo "Cleaning:"
    fi
    
    echo ""
    echo "Snapshots:"
    if [[ "$dry_run" == "true" ]]; then
        find "${SNAPSHOT_DIR}/${skill_name:-.}" -name "*.tar.gz" -type f 2>/dev/null | wc -l | xargs echo "  Would keep:"
    else
        cleanup_snapshots "$skill_name"
    fi
    
    echo ""
    echo "Usage Files:"
    if [[ "$dry_run" == "true" ]]; then
        find "${EVOLUTION_USAGE_DIR}" -name "*.jsonl" -type f 2>/dev/null | wc -l | xargs echo "  Would keep:"
    else
        cleanup_usage_files "$MAX_USAGE_DAYS" "$skill_name"
    fi
    
    echo ""
    echo "Logs:"
    if [[ "$dry_run" == "true" ]]; then
        find "${LOG_DIR}" -name "*.log" -type f 2>/dev/null | wc -l | xargs echo "  Would keep:"
    else
        cleanup_logs "$MAX_LOG_DAYS"
    fi
    
    echo ""
    echo "=== Cleanup Complete ==="
}

get_disk_usage() {
    local skill_name="${1:-}"
    
    echo "=== Disk Usage ==="
    
    echo ""
    echo "Snapshots:"
    du -sh "${SNAPSHOT_DIR}/${skill_name:-.}" 2>/dev/null || echo "  N/A"
    
    echo ""
    echo "Usage Files:"
    du -sh "${EVOLUTION_USAGE_DIR}" 2>/dev/null || echo "  N/A"
    
    echo ""
    echo "Logs:"
    du -sh "${LOG_DIR}" 2>/dev/null || echo "  N/A"
    
    echo ""
    echo "Total Project:"
    du -sh "${PROJECT_ROOT}" 2>/dev/null || echo "  N/A"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Resource Manager v${RESOURCE_MANAGER_VERSION}"
    echo ""
    echo "Usage:"
    echo "  source resource_manager.sh"
    echo "  cleanup_snapshots [skill_name] [max]"
    echo "  cleanup_usage_files [max_days] [skill_name]"
    echo "  cleanup_logs [max_days] [log_dir]"
    echo "  cleanup_all [skill_name] [dry_run]"
    echo "  get_disk_usage [skill_name]"
fi
