#!/usr/bin/env bash
# main.sh - CLI 主入口

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EVAL_DIR_FROM_ENGINE="$SCRIPT_DIR"

source "${EVAL_DIR_FROM_ENGINE}/lib/bootstrap.sh"
require constants concurrency errors

show_usage() {
    cat <<EOF
create-with-eval - Skill creation framework with real-time evaluation

Usage: $(basename "$0") [OPTIONS]

Options:
    --skill PROMPT        Create a new skill from PROMPT
    --target TIER         Target tier: GOLD, SILVER, BRONZE (default: BRONZE)
    --evolve SKILL_FILE   Trigger evolution for existing skill
    --stats               Show usage statistics
    --test                Run unit tests
    --dry-run             Preview changes without making them
    --help                Show this help message

Examples:
    $(basename "$0") --skill "Create a code review skill"
    $(basename "$0") --skill "Create skill" --target SILVER
    $(basename "$0") --skill "Create skill" --dry-run
    $(basename "$0") --evolve path/to/skill.md
    $(basename "$0") --stats

EOF
}

run_tests() {
    if [[ -f "${EVAL_DIR_FROM_ENGINE}/tests/run_tests.sh" ]]; then
        bash "${EVAL_DIR_FROM_ENGINE}/tests/run_tests.sh"
    else
        echo "Tests not found"
        return 1
    fi
}

show_stats() {
    require_evolution storage
    
    if [[ ! -f "$USAGE_LOG" ]]; then
        echo "No usage statistics available"
        return 0
    fi
    
    echo "=== Usage Statistics ==="
    echo ""
    
    local total_evals
    total_evals=$(wc -l < "$USAGE_LOG" 2>/dev/null || echo 0)
    echo "Total evaluations: $total_evals"
    
    local avg_score
    avg_score=$(cat "$USAGE_LOG" | jq -r '.score' 2>/dev/null | jq -s 'add / length' 2>/dev/null || echo 0)
    echo "Average score: ${avg_score:-0}"
    
    echo ""
    echo "By skill:"
    cat "$USAGE_LOG" | jq -r '.skill_name' 2>/dev/null | sort | uniq -c | while read count name; do
        echo "  $name: $count evaluations"
    done
}

create_skill() {
    local user_prompt="$1"
    local target_tier="${2:-BRONZE}"
    
    local skill_name
    skill_name=$(echo "$user_prompt" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]+/-/g' | sed 's/^-//;s/-$//')
    
    local output_file="${EVAL_DIR_FROM_ENGINE}/skills/${skill_name}.md"
    
    mkdir -p "$(dirname "$output_file")"
    
    echo "Creating skill: $skill_name"
    echo "Target tier: $target_tier"
    echo "Output: $output_file"
    echo ""
    
    TARGET_TIER="$target_tier" "${EVAL_DIR_FROM_ENGINE}/orchestrator.sh" "$user_prompt" "$output_file"
    
    echo ""
    echo "Skill created: $output_file"
}

evolve_skill() {
    local skill_file="$1"
    
    if [[ ! -f "$skill_file" ]]; then
        echo "Error: Skill file not found: $skill_file"
        return 1
    fi
    
    echo "Triggering evolution for: $skill_file"
    
    acquire_lock "evolution" "$EVOLUTION_TIMEOUT" || {
        echo "Error: Failed to acquire evolution lock"
        return 1
    }
    
    trap "release_lock 'evolution'" EXIT
    
    engine/evolution/engine.sh "$skill_file"
}

main() {
    if [[ $# -eq 0 ]]; then
        show_usage
        exit 0
    fi
    
    local command=""
    local skill_prompt=""
    local target_tier="BRONZE"
    local evolve_file=""
    local dry_run=0
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)
                show_usage
                exit 0
                ;;
            --skill)
                command="create"
                skill_prompt="$2"
                shift 2
                ;;
            --target)
                target_tier="$2"
                shift 2
                ;;
            --evolve)
                command="evolve"
                evolve_file="$2"
                shift 2
                ;;
            --stats)
                command="stats"
                shift
                ;;
            --test)
                command="test"
                shift
                ;;
            --dry-run)
                dry_run=1
                shift
                ;;
            *)
                echo "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    case "$command" in
        create)
            if [[ $dry_run -eq 1 ]]; then
                DRY_RUN=1 TARGET_TIER="$target_tier" "${EVAL_DIR_FROM_ENGINE}/orchestrator.sh" "$skill_prompt" "/dev/null"
            else
                create_skill "$skill_prompt" "$target_tier"
            fi
            ;;
        evolve)
            evolve_skill "$evolve_file"
            ;;
        stats)
            show_stats
            ;;
        test)
            run_tests
            ;;
        *)
            show_usage
            exit 1
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi