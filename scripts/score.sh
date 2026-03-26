
# ── Dimension 10: Actionability (5%) ─────────────────────────────────────
AC_SCORE=5
AC_NOTES=""
HAS_COMMANDS=$(grep -cE "```bash|```sh|\$ [a-z]|run |execute |bash " "$SKILL_FILE" || true)
HAS_STEPS=$(grep -cE "Step [0-9]|Phase [0-9]|[0-9]+\." "$SKILL_FILE" || true)
HAS_DECISIONS=$(grep -ciE "if.*then|when.*choose|select.*option|decision" "$SKILL_FILE" || true)
HAS_RECOVERY=$(grep -ciE "fallback|retry|recover|rollback|reset" "$SKILL_FILE" || true)

[[ $HAS_COMMANDS -ge 2 ]] && AC_SCORE=$((AC_SCORE+2)) && AC_NOTES+="has-commands "
[[ $HAS_STEPS -ge 5 ]] && AC_SCORE=$((AC_SCORE+2)) && AC_NOTES+="step-by-step "
[[ $HAS_DECISIONS -gt 0 ]] && AC_SCORE=$((AC_SCORE+1)) && AC_NOTES+="decision-points "
[[ $HAS_RECOVERY -gt 0 ]] && AC_SCORE=$((AC_SCORE+1)) && AC_NOTES+="recovery-path "
[[ $AC_SCORE -gt 10 ]] && AC_SCORE=10
dim_score "Actionability" 5 "$AC_SCORE" "$AC_NOTES"
