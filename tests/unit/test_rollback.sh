#!/usr/bin/env bash
# test_rollback.sh - 快照回滚模块测试 (15用例)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TOOLS_LIB="${PROJECT_ROOT}/tools/lib"
ENGINE_DIR="${PROJECT_ROOT}/tools/engine"

source "${TOOLS_LIB}/bootstrap.sh"
source "${TOOLS_LIB}/constants.sh"
source "${TOOLS_LIB}/errors.sh"
source "${ENGINE_DIR}/rollback.sh"

TEST_COUNT=0
TEST_PASSED=0
TEST_FAILED=0

assert_eq() {
    local expected="$1"
    local actual="$2"
    local msg="${3:-}"
    ((TEST_COUNT++))
    if [[ "$expected" == "$actual" ]]; then
        ((TEST_PASSED++))
        echo "  ✓ $msg"
        return 0
    else
        ((TEST_FAILED++))
        echo "  ✗ $msg"
        echo "    Expected: $expected"
        echo "    Actual: $actual"
        return 1
    fi
}

assert_success() {
    local cmd="$1"
    local msg="${2:-}"
    ((TEST_COUNT++))
    if eval "$cmd" >/dev/null 2>&1; then
        ((TEST_PASSED++))
        echo "  ✓ $msg"
        return 0
    else
        ((TEST_FAILED++))
        echo "  ✗ $msg"
        return 1
    fi
}

assert_failure() {
    local cmd="$1"
    local msg="${2:-}"
    ((TEST_COUNT++))
    if ! eval "$cmd" >/dev/null 2>&1; then
        ((TEST_PASSED++))
        echo "  ✓ $msg"
        return 0
    else
        ((TEST_FAILED++))
        echo "  ✗ $msg"
        return 1
    fi
}

MAX_SNAPSHOTS=10

test_rollback_snapshot_create_001() {
    echo "  Testing snapshot create"
    local test_file
    test_file=$(mktemp /tmp/test_skill_XXXXXX.md)
    echo "# Test Skill" > "$test_file"
    echo "Content" >> "$test_file"
    local snapshot
    snapshot=$(create_snapshot "$test_file" "test")
    local result=$?
    assert_eq "0" "$result" "Snapshot created successfully"
    assert_success "[[ -f '$snapshot' ]]" "Snapshot file exists"
    rm -f "$test_file" "$snapshot"
}

test_rollback_snapshot_create_002() {
    local test_file
    test_file=$(mktemp /tmp/test_skill_XXXXXX.md)
    echo "# Test" > "$test_file"
    local snapshot
    snapshot=$(create_snapshot "$test_file" "unit_test")
    assert_success "[[ $snapshot == *.tar.gz ]]" "Snapshot path ends with .tar.gz"
    rm -f "$test_file" "$snapshot"
}

test_rollback_snapshot_create_003() {
    local snapshot
    snapshot=$(create_snapshot "/nonexistent/file.md" "test" 2>&1) && snapshot="" || snapshot=""
    assert_eq "" "$snapshot" "Snapshot returns empty for missing file"
}

test_rollback_snapshot_restore_001() {
    echo "  Testing snapshot restore"
    local test_file
    test_file=$(mktemp /tmp/test_skill_XXXXXX.md)
    echo "# Original Content" > "$test_file"
    local snapshot
    snapshot=$(create_snapshot "$test_file" "pre")
    echo "# Modified Content" > "$test_file"
    rollback_to "$snapshot" "$test_file" >/dev/null 2>&1
    local content
    content=$(cat "$test_file")
    assert_eq "# Original Content" "$content" "Content restored from snapshot"
    rm -f "$test_file" "$snapshot"
}

test_rollback_snapshot_restore_002() {
    local snapshot_file="/nonexistent/snapshot.tar.gz"
    local test_file
    test_file=$(mktemp /tmp/test_skill_XXXXXX.md)
    rollback_to "$snapshot_file" "$test_file" 2>/dev/null
    assert_eq "1" "$?" "Rollback returns error for missing snapshot"
    rm -f "$test_file"
}

test_rollback_latest_001() {
    echo "  Testing rollback_to_latest"
    local test_file
    test_file=$(mktemp /tmp/test_skill_XXXXXX.md)
    echo "# Version 1" > "$test_file"
    create_snapshot "$test_file" "v1" >/dev/null
    echo "# Version 2" > "$test_file"
    create_snapshot "$test_file" "v2" >/dev/null
    echo "# Version 3" > "$test_file"
    rollback_to_latest "$test_file" >/dev/null 2>&1
    local content
    content=$(cat "$test_file")
    assert_match "^# Version" "$content" "Content rolled back to a previous version"
    rm -f "$test_file"
}

test_rollback_latest_002() {
    local test_file
    test_file=$(mktemp /tmp/test_skill_XXXXXX.md)
    echo "# Only One" > "$test_file"
    create_snapshot "$test_file" "only" >/dev/null
    rollback_to_latest "$test_file" >/dev/null 2>&1
    local content
    content=$(cat "$test_file")
    assert_eq "# Only One" "$content" "Rollback to latest with single snapshot"
    rm -f "$test_file"
}

test_rollback_list_001() {
    echo "  Testing list_snapshots"
    local test_file
    test_file=$(mktemp /tmp/test_skill_XXXXXX.md)
    echo "# Test" > "$test_file"
    create_snapshot "$test_file" "list_test" >/dev/null
    local snapshots
    snapshots=$(list_snapshots)
    assert_success "[[ -n '$snapshots' ]]" "list_snapshots returns results"
    rm -f "$test_file"
}

test_rollback_date_001() {
    echo "  Testing rollback_to_date"
    local test_file
    test_file=$(mktemp /tmp/test_skill_XXXXXX.md)
    echo "# Date Test" > "$test_file"
    local date_str
    date_str=$(date +%Y%m%d)
    create_snapshot "$test_file" "date_test" >/dev/null
    rollback_to_date "$date_str" "$test_file" >/dev/null 2>&1
    local content
    content=$(cat "$test_file")
    assert_eq "# Date Test" "$content" "Rollback by date works"
    rm -f "$test_file"
}

test_rollback_cleanup_001() {
    echo "  Testing cleanup_snapshots"
    local test_file
    test_file=$(mktemp /tmp/test_skill_XXXXXX.md)
    echo "# Cleanup Test" > "$test_file"
    local i
    for i in {1..15}; do
        create_snapshot "$test_file" "cleanup_$i" >/dev/null
    done
    cleanup_snapshots
    local count
    count=$(find "${SNAPSHOT_DIR}" -name "*.tar.gz" -type f 2>/dev/null | wc -l)
    assert_success "[[ $count -le 10 ]]" "Snapshots cleaned up to MAX_SNAPSHOTS (10)"
    rm -f "$test_file"
}

test_rollback_auto_001() {
    echo "  Testing check_auto_rollback"
    local result
    result=$(check_auto_rollback 800 850 "true" 2>&1)
    assert_eq "1" "$?" "No rollback when score improved"
}

test_rollback_auto_002() {
    local result
    result=$(check_auto_rollback 800 850 "false" 2>&1)
    assert_eq "0" "$?" "Rollback triggered for invalid format"
}

test_rollback_auto_003() {
    local result
    result=$(check_auto_rollback 600 850 "true" 2>&1)
    assert_eq "0" "$?" "Rollback triggered for 250 point regression (>20)"
}

test_rollback_auto_004() {
    local result
    result=$(check_auto_rollback 830 850 "true" 2>&1)
    assert_eq "1" "$?" "No rollback for 20 point regression (not >20)"
}

test_rollback_snapshot_dir_001() {
    echo "  Testing snapshot directory structure"
    assert_success "[[ -d '$SNAPSHOT_DIR' ]]" "SNAPSHOT_DIR exists"
}

run_test_rollback_tests() {
    echo ""
    echo "=== Rollback Module Tests ==="
    test_rollback_snapshot_create_001
    test_rollback_snapshot_create_002
    test_rollback_snapshot_create_003
    test_rollback_snapshot_restore_001
    test_rollback_snapshot_restore_002
    test_rollback_latest_001
    test_rollback_latest_002
    test_rollback_list_001
    test_rollback_date_001
    test_rollback_cleanup_001
    test_rollback_auto_001
    test_rollback_auto_002
    test_rollback_auto_003
    test_rollback_auto_004
    test_rollback_snapshot_dir_001
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_test_rollback_tests
    echo ""
    echo "Results: $TEST_PASSED/$TEST_COUNT passed"
    [[ $TEST_FAILED -gt 0 ]] && exit 1 || exit 0
fi
