
# ── Dimension 9: Consistency (5%) ──────────────────────────────────────────
CN_SCORE=5
CN_NOTES=""
UNIQUE_VERSIONS=$(grep -oP 'version: "[^"]*"' "$SKILL_FILE" | sort -u | wc -l)
UNIQUE_AUTHORS=$(grep -oP 'author: "[^"]*"' "$SKILL_FILE" | sort -u | wc -l)
SECTION_COUNT=$(grep -c "^## §" "$SKILL_FILE" || true)
HAS_VERSION_HISTORY=$(grep -ci "changelog\|version.*history\|v[0-9]" "$SKILL_FILE" || true)

[[ $UNIQUE_VERSIONS -eq 1 ]] && CN_SCORE=$((CN_SCORE+2)) && CN_NOTES+="single-version "
[[ $UNIQUE_AUTHORS -ge 1 ]] && CN_SCORE=$((CN_SCORE+1)) && CN_NOTES+="author-defined "
[[ $SECTION_COUNT -ge 8 ]] && CN_SCORE=$((CN_SCORE+2)) && CN_NOTES+="complete-sections "
[[ $HAS_VERSION_HISTORY -gt 0 ]] && CN_SCORE=$((CN_SCORE+1)) && CN_NOTES+="version-tracked "
[[ $CN_SCORE -gt 10 ]] && CN_SCORE=10
dim_score "Consistency" 5 "$CN_SCORE" "$CN_NOTES"
