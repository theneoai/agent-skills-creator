#!/usr/bin/env bash
# self-optimize.sh — Trigger script for AI-driven skill optimization
# Usage: echo "自优化 SKILL.md" | self-optimize.sh
#        echo "self-optimize agent-skill-creator" | self-optimize.sh

set -euo pipefail

SCRIPT_DIR="$(dirname "$0")"
TUNE_SCRIPT="$SCRIPT_DIR/skill-manager/tune.sh"

read -r input

if [[ "$input" =~ ^(自优化|self-optimize)\s+(.+)$ ]]; then
    target="${BASH_REMATCH[2]}"
    target="${target%"${target##*[![:space:]]}"}"

    if [[ "$target" == */SKILL.md || "$target" == SKILL.md ]]; then
        skill_path="$target"
    else
        skill_path="$target/SKILL.md"
    fi

    echo "Triggering self-optimization: $skill_path (10 rounds)"
    bash "$TUNE_SCRIPT" "$skill_path" 10
else
    echo "Usage: echo \"自优化 SKILL.md\" | $0"
    echo "       echo \"self-optimize agent-skill-creator\" | $0"
    exit 1
fi
