
# ── Dimension 7: Readability (5%) ──────────────────────────────────────────
RD_SCORE=5
RD_NOTES=""
HAS_SECTIONS=$(grep -c "^## " "$SKILL_FILE" || true)
HAS_PARAGRAPHS=$(grep -c "^$" "$SKILL_FILE" || true)
AVG_LINE_LEN=$(awk '{sum+=length; count++} END {print sum/count}' "$SKILL_FILE")
LONG_LINES=$(awk -F: 'length($2) > 120 {count++} END {print count+0}' "$SKILL_FILE")

[[ $HAS_SECTIONS -ge 5 ]] && RD_SCORE=$((RD_SCORE+2)) && RD_NOTES+="well-structured "
[[ $HAS_SECTIONS -ge 10 ]] && RD_SCORE=$((RD_SCORE+1)) && RD_NOTES+="detailed-toc "
[[ $LONG_LINES -lt 5 ]] && RD_SCORE=$((RD_SCORE+1)) && RD_NOTES+="readable-lines "
[[ $AVG_LINE_LEN -lt 100 ]] && RD_SCORE=$((RD_SCORE+1)) && RD_NOTES+="concise "
[[ $RD_SCORE -gt 10 ]] && RD_SCORE=10
dim_score "Readability" 5 "$RD_SCORE" "$RD_NOTES"
