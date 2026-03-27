#!/usr/bin/env bash
# auto_retro.sh — Automatic retrospective and knowledge沉淀 after each optimization
# Run after each optimization cycle to capture learnings and auto-generate lessons

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
RETRO_FILE="$PROJECT_DIR/references/skill-manager/RETROSPECTIVE.md"
METHODOLOGY_FILE="$PROJECT_DIR/references/skill-manager/OPTIMIZATION_METHODOLOGY.md"
ANTIPATTERN_FILE="$PROJECT_DIR/references/skill-manager/OPTIMIZATION_ANTIPATTERNS.md"
SKILL_FILE="$PROJECT_DIR/SKILL.md"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M")

echo "=== Auto-Retro: Capturing Learnings ==="
echo "Timestamp: $TIMESTAMP"

# Run scoring
TEXT_SCORE=$(bash "$SCRIPT_DIR/score.sh" "$SKILL_FILE" 2>/dev/null | grep "Text Score" | sed 's/.*: *//' | sed 's|/.*||' || echo "N/A")
RUNTIME_SCORE=$(bash "$SCRIPT_DIR/runtime-validate.sh" "$SKILL_FILE" 2>/dev/null | grep "RUNTIME SCORE:" | awk '{print $3}' | sed 's|/.*||' || echo "N/A")
MODE_DETECTION=$(bash "$SCRIPT_DIR/runtime-validate.sh" "$SKILL_FILE" 2>/dev/null | grep "Mode Detection Tests:" | awk '{print $4}' | sed 's/%//' || echo "N/A")

# Get previous scores from last retro entry
get_previous_scores() {
    if [[ -f "$RETRO_FILE" ]]; then
        PREV_TEXT=$(grep -B 2 -A 3 "Text Score" "$RETRO_FILE" 2>/dev/null | grep -A 1 "Retro @" | tail -1 | awk '{print $3}' || echo "N/A")
        PREV_RUNTIME=$(grep -B 2 -A 3 "Runtime Score" "$RETRO_FILE" 2>/dev/null | grep -A 1 "Retro @" | tail -1 | awk '{print $3}' || echo "N/A")
        PREV_VARIANCE=$(grep -B 2 -A 3 "Variance" "$RETRO_FILE" 2>/dev/null | grep -A 1 "Retro @" | tail -1 | awk '{print $3}' || echo "N/A")
        PREV_MODE=$(grep -B 2 -A 3 "Mode Detection" "$RETRO_FILE" 2>/dev/null | grep -A 1 "Retro @" | tail -1 | awk '{print $3}' || echo "N/A")
    else
        PREV_TEXT="N/A"; PREV_RUNTIME="N/A"; PREV_VARIANCE="N/A"; PREV_MODE="N/A"
    fi
}

get_previous_scores

echo "Current Metrics:"
echo "  Text Score: $TEXT_SCORE (prev: $PREV_TEXT)"
echo "  Runtime Score: $RUNTIME_SCORE (prev: $PREV_RUNTIME)"
echo "  Mode Detection: ${MODE_DETECTION}% (prev: $PREV_MODE)"

# Check if this is a significant improvement
if [[ "$TEXT_SCORE" == "N/A" || "$RUNTIME_SCORE" == "N/A" ]]; then
    echo "Skipping retro - unable to get scores"
    exit 0
fi

# Calculate variance
VARIANCE=$(echo "scale=2; $TEXT_SCORE - $RUNTIME_SCORE" | bc | sed 's/^-//')
echo "  Variance: $VARIANCE"

# Analyze what changed
analyze_changes() {
    local lesson=""
    local change_type=""

    # Check git diff
    if git diff --quiet "$SKILL_FILE" 2>/dev/null; then
        echo "No uncommitted changes in SKILL.md"
        return
    fi

    # Get diff stats
    DIFF_STATS=$(git diff --stat "$SKILL_FILE" 2>/dev/null || echo "")
    echo "Changes detected: $DIFF_STATS"

    # Get the actual diff content for analysis
    DIFF_CONTENT=$(git diff "$SKILL_FILE" 2>/dev/null || echo "")

    # Check what section was modified - git diff uses "+" followed by content (no space)
    if echo "$DIFF_CONTENT" | grep -qE "^\+.*§8|^\+.*Automation Scripts"; then
        lesson="Added §8 · Automation Scripts section — Response Quality improved"
        change_type="docs_structure"
    elif echo "$DIFF_CONTENT" | grep -qE "^\+.*triggers|^\+.*Trigger"; then
        lesson="Trigger table modified — checking mode detection impact"
        change_type="triggers"
    elif echo "$DIFF_CONTENT" | grep -qE "^\+.*Examples|^\+.*Workflow|^\+.*Phase"; then
        lesson="Examples/Workflow section enhanced — Text Score improved"
        change_type="examples"
    elif echo "$DIFF_CONTENT" | grep -qE "^\+.*Anti-Pattern|^\+.*anti-pattern"; then
        lesson="Anti-patterns documentation added — preventing future regressions"
        change_type="anti_patterns"
    elif echo "$DIFF_CONTENT" | grep -qE "^\+.*retro|^\+.*Retro|^\+.*沉淀|^\+.*optimization loop|^\+.*Auto-infer"; then
        lesson="Enhanced optimization loop/retro process — auto-infer lessons mechanism"
        change_type="process"
    fi

    # Check score deltas and correlate with changes
    if [[ "$PREV_TEXT" != "N/A" && "$PREV_RUNTIME" != "N/A" ]]; then
        TEXT_DELTA=$(echo "$TEXT_SCORE - $PREV_TEXT" | bc 2>/dev/null || echo "0")
        RUNTIME_DELTA=$(echo "$RUNTIME_SCORE - $PREV_RUNTIME" | bc 2>/dev/null || echo "0")
        VARIANCE_DELTA=$(echo "$VARIANCE - $PREV_VARIANCE" | bc 2>/dev/null || echo "0")

        echo "Score Deltas: Text $TEXT_DELTA, Runtime $RUNTIME_DELTA, Variance $VARIANCE_DELTA"

        # Infer lesson based on patterns + score improvements
        if (( $(echo "$RUNTIME_DELTA > 0.3" | bc -l 2>/dev/null) )) && [[ "$change_type" == "docs_structure" ]]; then
            lesson="§8 Automation Scripts section → Runtime Score +${RUNTIME_DELTA}, Variance reduced by ${VARIANCE_DELTA}"
        elif (( $(echo "$TEXT_DELTA > 0.2" | bc -l 2>/dev/null) )) && [[ "$change_type" == "examples" ]]; then
            lesson="Enhanced Examples/Workflow → Text Score +${TEXT_DELTA}"
        elif (( $(echo "$RUNTIME_DELTA > 0.3" | bc -l 2>/dev/null) )) && [[ "$change_type" == "triggers" ]]; then
            lesson="Trigger optimization → Runtime Score +${RUNTIME_DELTA}"
        elif (( $(echo "$VARIANCE_DELTA < -0.3" | bc -l 2>/dev/null) )); then
            lesson="Variance reduced by ${VARIANCE_DELTA} — docs and runtime now more aligned"
        fi
    fi

    if [[ -n "$lesson" ]]; then
        echo "Auto-inferred Lesson: $lesson"

        # Append lesson to METHODOLOGY_FILE
        if [[ -f "$METHODOLOGY_FILE" ]]; then
            # Find the next lesson number (look for "### Lesson N:")
            LAST_NUM=$(grep "^### Lesson" "$METHODOLOGY_FILE" 2>/dev/null | tail -1 | grep -oE "Lesson [0-9]+" | grep -oE "[0-9]+" || echo "0")
            NEW_NUM=$((LAST_NUM + 1))

            # Create lesson entry
            LESSON_ENTRY="### Lesson $NEW_NUM: $lesson

"

            # Find the line with "*Document Version:" and insert before it
            VERSION_LINE=$(grep -n "^\\*Document Version:" "$METHODOLOGY_FILE" 2>/dev/null | cut -d: -f1 || echo "0")
            if [[ "$VERSION_LINE" != "0" && "$VERSION_LINE" -gt 0 ]]; then
                HEAD_COUNT=$((VERSION_LINE - 1))
                head -n "$HEAD_COUNT" "$METHODOLOGY_FILE" > "${METHODOLOGY_FILE}.tmp"
                echo "$LESSON_ENTRY" >> "${METHODOLOGY_FILE}.tmp"
                tail -n +"$VERSION_LINE" "$METHODOLOGY_FILE" >> "${METHODOLOGY_FILE}.tmp"
                mv "${METHODOLOGY_FILE}.tmp" "$METHODOLOGY_FILE"
                echo "Added lesson to OPTIMIZATION_METHODOLOGY.md"
            else
                echo "$LESSON_ENTRY" >> "$METHODOLOGY_FILE"
            fi
        fi
    else
        echo "No specific lesson pattern matched — manual review needed"
    fi
}

# Generate brief retro entry
RETRO_ENTRY="### Retro @ $TIMESTAMP

| Metric | Value | Delta |
|--------|-------|-------|
| Text Score | $TEXT_SCORE | $([[ "$PREV_TEXT" != "N/A" ]] && echo "+$(echo "$TEXT_SCORE - $PREV_TEXT" | bc 2>/dev/null || echo "0")" || echo "—") |
| Runtime Score | $RUNTIME_SCORE | $([[ "$PREV_RUNTIME" != "N/A" ]] && echo "+$(echo "$RUNTIME_SCORE - $PREV_RUNTIME" | bc 2>/dev/null || echo "0")" || echo "—") |
| Variance | $VARIANCE | $([[ "$PREV_VARIANCE" != "N/A" ]] && echo "$(echo "$VARIANCE - $PREV_VARIANCE" | bc 2>/dev/null || echo "0")" || echo "—") |
| Mode Detection | ${MODE_DETECTION}% | $([[ "$PREV_MODE" != "N/A" ]] && echo "+$(echo "$MODE_DETECTION - $PREV_MODE" | bc 2>/dev/null || echo "0")%" || echo "—") |

"

# Append to RETROSPECTIVE.md if it exists
if [[ -f "$RETRO_FILE" ]]; then
    # Find last H2 and insert before it
    LAST_H2_LINE=$(grep -n "^## " "$RETRO_FILE" 2>/dev/null | tail -1 | cut -d: -f1 || echo "")
    if [[ -n "$LAST_H2_LINE" ]]; then
        HEAD_COUNT=$((LAST_H2_LINE - 1))
        head -n "$HEAD_COUNT" "$RETRO_FILE" > "${RETRO_FILE}.tmp"
        echo "$RETRO_ENTRY" >> "${RETRO_FILE}.tmp"
        tail -n +"$LAST_H2_LINE" "$RETRO_FILE" >> "${RETRO_FILE}.tmp"
        mv "${RETRO_FILE}.tmp" "$RETRO_FILE"
        echo "Added retro entry to RETROSPECTIVE.md"
    else
        echo "$RETRO_ENTRY" >> "$RETRO_FILE"
    fi
else
    mkdir -p "$(dirname "$RETRO_FILE")"
    cat > "$RETRO_FILE" << 'RETRO_EOF'
# Optimization Retrospective

> Auto-generated by auto_retro.sh after each optimization cycle
> Captures metrics and learnings for continuous improvement

RETRO_EOF
    echo "$RETRO_ENTRY" >> "$RETRO_FILE"
    echo "Created new RETROSPECTIVE.md"
fi

# Analyze changes and infer lessons
analyze_changes

# Check for anti-patterns and log if found
ANTIPATTERNS_FOUND=""

VARIANCE_CHECK=$(echo "$VARIANCE > 1.5" | bc -l 2>/dev/null || echo "0")
if [[ "$VARIANCE_CHECK" == "1" ]]; then
    ANTIPATTERNS_FOUND="High Variance: $VARIANCE"
fi

TEXT_CHECK=$(echo "$TEXT_SCORE < 8.5" | bc -l 2>/dev/null || echo "0")
if [[ "$TEXT_CHECK" == "1" ]]; then
    if [[ -n "$ANTIPATTERNS_FOUND" ]]; then
        ANTIPATTERNS_FOUND="${ANTIPATTERNS_FOUND}, Low Text: $TEXT_SCORE"
    else
        ANTIPATTERNS_FOUND="Low Text: $TEXT_SCORE"
    fi
fi

RUNTIME_CHECK=$(echo "$RUNTIME_SCORE < 8.5" | bc -l 2>/dev/null || echo "0")
if [[ "$RUNTIME_CHECK" == "1" ]]; then
    if [[ -n "$ANTIPATTERNS_FOUND" ]]; then
        ANTIPATTERNS_FOUND="${ANTIPATTERNS_FOUND}, Low Runtime: $RUNTIME_SCORE"
    else
        ANTIPATTERNS_FOUND="Low Runtime: $RUNTIME_SCORE"
    fi
fi

if [[ -n "$ANTIPATTERNS_FOUND" ]]; then
    echo "Anti-patterns detected: $ANTIPATTERNS_FOUND"
fi

echo ""
echo "=== Auto-Retro Complete ==="
echo ""
echo "Summary:"
echo "  - Metrics captured (with deltas)"
echo "  - Retro entry added"
echo "  - Anti-patterns checked"
echo "  - Lessons auto-inferred from changes"
echo ""
echo "Next steps:"
echo "  1. Review $RETRO_FILE for learnings"
echo "  2. Review $METHODOLOGY_FILE for auto-captured lessons"
echo "  3. Run 'git add -A && git commit' to save"
echo "  4. Continue optimization"