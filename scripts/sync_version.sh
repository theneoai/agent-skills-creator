#!/usr/bin/env bash
# sync_version.sh - 同步 manifest.json 与 SKILL.md 版本
#
# 用法: ./scripts/sync_version.sh [--check|--sync]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

MANIFEST_FILE="$PROJECT_ROOT/.claude-plugin/manifest.json"
SKILL_FILE="$PROJECT_ROOT/SKILL.md"

get_manifest_version() {
    jq -r '.version' "$MANIFEST_FILE"
}

get_skill_version() {
    grep -E '^version:' "$SKILL_FILE" | awk '{print $2}' | tr -d 'v'
}

check_version_sync() {
    local manifest_ver
    local skill_ver
    
    manifest_ver=$(get_manifest_version)
    skill_ver=$(get_skill_version)
    
    echo "manifest.json version: $manifest_ver"
    echo "SKILL.md version: $skill_ver"
    
    if [[ "$manifest_ver" == "$skill_ver" ]]; then
        echo "✓ Versions are in sync"
        return 0
    else
        echo "✗ Versions are out of sync!"
        return 1
    fi
}

sync_version() {
    local manifest_ver
    local skill_ver
    
    manifest_ver=$(get_manifest_version)
    skill_ver=$(get_skill_version)
    
    if [[ "$manifest_ver" != "$skill_ver" ]]; then
        echo "Updating manifest.json version from $manifest_ver to $skill_ver"
        jq --arg v "$skill_ver" '.version = $v' "$MANIFEST_FILE" > "${MANIFEST_FILE}.tmp"
        mv "${MANIFEST_FILE}.tmp" "$MANIFEST_FILE"
        echo "✓ Synced"
    else
        echo "✓ Already in sync"
    fi
}

case "${1:-check}" in
    --check|-c)
        check_version_sync
        ;;
    --sync|-s)
        sync_version
        ;;
    *)
        echo "Usage: $0 [--check|--sync]"
        exit 1
        ;;
esac
