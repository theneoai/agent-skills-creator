#!/usr/bin/env bash
# score.sh — Enhanced text quality pre-check with no score ceiling
# Usage: ./score.sh path/to/SKILL.md
# Produces a quick heuristic score across the 7 text dimensions.
# Enhanced: All dimensions can reach 10/10 with proper content.

set -euo pipefail

SKILL_FILE="${1:-}"
if [[ -z "$SKILL_FILE" || ! -f "$SKILL_FILE" ]]; then
  echo "Usage: $0 path/to/SKILL.md"
  exit 1
fi

SKILL_DIR=$(dirname "$SKILL_FILE")

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  TEXT QUALITY PRE-CHECK"
echo "  $(basename "$SKILL_DIR")"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

TOTAL=0
MAX=0

dim_score() {
  local name="$1" weight="$2" score="$3" notes="$4"
  local weighted
  weighted=$(echo "scale=2; $score * $weight / 110" | bc)
  TOTAL=$(echo "scale=2; $TOTAL + $weighted" | bc)
  MAX=$(echo "scale=2; $MAX + $weight / 110 * 10" | bc)
  printf "  %-22s %2d/10  (×%.2f)  %s\n" "$name" "$score" "$(echo "scale=2; $weight/110" | bc)" "$notes"
}

# ── Dimension 1: System Prompt (20%) ───────────────────────────────────────
SP_SCORE=2
SP_NOTES=""
HAS_SP=$(grep -ci "system prompt\|§ 1\b\|## §" "$SKILL_FILE" || true)
HAS_11=$(grep -c "§1\.1\|1\.1 Identity\|## 1\.1\|### Identity" "$SKILL_FILE" || true)
HAS_12=$(grep -c "§1\.2\|1\.2 Framework\|## 1\.2\|### Framework" "$SKILL_FILE" || true)
HAS_13=$(grep -c "§1\.3\|1\.3 Thinking\|## 1\.3\|### Thinking" "$SKILL_FILE" || true)
HAS_CONSTRAINTS=$(grep -ci "constraints\|boundaries\|red lines\|forbidden\|never\|always" "$SKILL_FILE" || true)

[[ $HAS_SP -gt 0 ]] && SP_SCORE=$((SP_SCORE+2)) && SP_NOTES+="has-header "
[[ $HAS_11 -gt 0 ]] && SP_SCORE=$((SP_SCORE+2)) && SP_NOTES+="§1.1 "
[[ $HAS_12 -gt 0 ]] && SP_SCORE=$((SP_SCORE+2)) && SP_NOTES+="§1.2 "
[[ $HAS_13 -gt 0 ]] && SP_SCORE=$((SP_SCORE+2)) && SP_NOTES+="§1.3 "
[[ $HAS_CONSTRAINTS -gt 2 ]] && SP_SCORE=$((SP_SCORE+1)) && SP_NOTES+="constraints "
[[ $SP_SCORE -gt 10 ]] && SP_SCORE=10
dim_score "System Prompt" 20 "$SP_SCORE" "$SP_NOTES"

# ── Dimension 2: Domain Knowledge (20%) ────────────────────────────────────
DK_SCORE=4
DK_NOTES=""
SPECIFICS=$(grep -cE "[0-9]+%|[0-9]+\.[0-9]+|McKinsey|TOGAF|ISO |RFC |v[0-9]+\.[0-9]" "$SKILL_FILE" || true)
GENERICS=$(grep -ciE "\bprofessional\b|\bindustry.leader\b|\bbest practices\b|\bexpert\b|\bworld.class\b" "$SKILL_FILE" || true)
CASES=$(grep -ciE "case study|example|scenario|benchmark|metric|KPI|SLA|ROI" "$SKILL_FILE" || true)
STANDARDS=$(grep -cE "NIST|OWASP|ISO [0-9]+|IEC |ANSI |IEEE|CWE|SOC " "$SKILL_FILE" || true)
REAL_DATA=$(grep -cE "\$[0-9]+|[0-9]+x faster|[0-9]+x better|reduce.*[0-9]+%|improve.*[0-9]+%" "$SKILL_FILE" || true)

[[ $SPECIFICS -ge 5 ]] && DK_SCORE=$((DK_SCORE+3)) && DK_NOTES+="specific-data "
[[ $SPECIFICS -ge 2 ]] && [[ $DK_SCORE -lt 8 ]] && DK_SCORE=$((DK_SCORE+1)) && DK_NOTES+="some-data "
[[ $CASES -ge 10 ]] && DK_SCORE=$((DK_SCORE+2)) && DK_NOTES+="rich-cases "
[[ $CASES -ge 5 ]] && [[ $DK_SCORE -lt 9 ]] && DK_SCORE=$((DK_SCORE+1)) && DK_NOTES+="has-cases "
[[ $STANDARDS -ge 3 ]] && DK_SCORE=$((DK_SCORE+1)) && DK_NOTES+="standards "
[[ $REAL_DATA -ge 5 ]] && DK_SCORE=$((DK_SCORE+1)) && DK_NOTES+="quantified "
[[ $GENERICS -ge 5 ]] && DK_SCORE=$((DK_SCORE-2)) && DK_NOTES+="⚠generic-content "
[[ $DK_SCORE -lt 1 ]] && DK_SCORE=1
[[ $DK_SCORE -gt 10 ]] && DK_SCORE=10
dim_score "Domain Knowledge" 20 "$DK_SCORE" "$DK_NOTES"

# ── Dimension 3: Workflow (20%) ─────────────────────────────────────────────
WF_SCORE=3
WF_NOTES=""
HAS_WORKFLOW=$(grep -ci "workflow\|§ [0-9]\+.*workflow\|## Workflow\|## Phase\|Step [0-9]" "$SKILL_FILE" || true)
HAS_DONE=$(grep -ci "done.criteri\|done:" "$SKILL_FILE" || true)
HAS_FAIL=$(grep -ci "fail.criteri\|fail:" "$SKILL_FILE" || true)
HAS_PHASES=$(grep -cE "Phase [1-9]|Step [1-9]" "$SKILL_FILE" || true)
HAS_TABLE=$(grep -c "|" "$SKILL_FILE" || true)
HAS_DECISION=$(grep -ci "if.*then\|decision\|choice\|select\|option" "$SKILL_FILE" || true)

[[ $HAS_WORKFLOW -gt 0 ]] && WF_SCORE=$((WF_SCORE+2)) && WF_NOTES+="has-workflow "
[[ $HAS_PHASES -ge 3 ]] && WF_SCORE=$((WF_SCORE+2)) && WF_NOTES+="${HAS_PHASES}-phases "
[[ $HAS_DONE -gt 0 ]] && WF_SCORE=$((WF_SCORE+1)) && WF_NOTES+="done-criteria "
[[ $HAS_FAIL -gt 0 ]] && WF_SCORE=$((WF_SCORE+1)) && WF_NOTES+="fail-criteria "
[[ $HAS_TABLE -gt 10 ]] && WF_SCORE=$((WF_SCORE+1)) && WF_NOTES+="structured "
[[ $HAS_DECISION -gt 2 ]] && WF_SCORE=$((WF_SCORE+1)) && WF_NOTES+="decision-tree "
[[ $WF_SCORE -gt 10 ]] && WF_SCORE=10
dim_score "Workflow" 20 "$WF_SCORE" "$WF_NOTES"

# ── Dimension 4: Error Handling (15%) ──────────────────────────────────────
EH_SCORE=3
EH_NOTES=""
HAS_EH=$(grep -ci "error.handling\|edge case\|anti.pattern\|risk\|failure\|recovery" "$SKILL_FILE" || true)
HAS_ANTIPATTERNS=$(grep -ci "anti-pattern\|Anti-Pattern" "$SKILL_FILE" || true)
HAS_RECOVERY=$(grep -ci "recovery\|retry\|fallback\|degrade\|reset" "$SKILL_FILE" || true)
HAS_RISK=$(grep -ci "risk\|mitigation\|threat\|vulnerability\|cwe" "$SKILL_FILE" || true)
HAS_EDGES=$(grep -ci "edge.case\|corner.case\|boundary\|what.if" "$SKILL_FILE" || true)

[[ $HAS_EH -ge 3 ]] && EH_SCORE=$((EH_SCORE+3)) && EH_NOTES+="error-scenarios "
[[ $HAS_ANTIPATTERNS -gt 0 ]] && EH_SCORE=$((EH_SCORE+2)) && EH_NOTES+="anti-patterns "
[[ $HAS_RECOVERY -gt 2 ]] && EH_SCORE=$((EH_SCORE+2)) && EH_NOTES+="recovery-strategies "
[[ $HAS_RISK -gt 2 ]] && EH_SCORE=$((EH_SCORE+1)) && EH_NOTES+="risk-matrix "
[[ $HAS_EDGES -gt 1 ]] && EH_SCORE=$((EH_SCORE+1)) && EH_NOTES+="edge-cases "
[[ $EH_SCORE -gt 10 ]] && EH_SCORE=10
dim_score "Error Handling" 15 "$EH_SCORE" "$EH_NOTES"

# ── Dimension 5: Examples (15%) ─────────────────────────────────────────────
EX_SCORE=2
EX_NOTES=""
EXAMPLE_SECTIONS=$(grep -cE "^## .*[Ee]xample|^### .*[Ee]xample|^\| [0-9]+ \|.*[Ee]xample" "$SKILL_FILE" || true)
EXAMPLE_MENTIONS=$(grep -ci "example\|scenario\|use case" "$SKILL_FILE" || true)
HAS_INPUT=$(grep -ci "输入\|input\|user says\|user input" "$SKILL_FILE" || true)
HAS_OUTPUT=$(grep -ci "输出\|output\|expected\|result" "$SKILL_FILE" || true)
HAS_VERIFY=$(grep -ci "验证\|verify\|validation\|check\|确认" "$SKILL_FILE" || true)

[[ $EXAMPLE_SECTIONS -ge 5 ]] && EX_SCORE=9 && EX_NOTES+="5+-sections "
[[ $EXAMPLE_SECTIONS -ge 3 ]] && [[ $EX_SCORE -lt 9 ]] && EX_SCORE=7 && EX_NOTES+="3-4-sections "
[[ $EXAMPLE_SECTIONS -ge 1 ]] && [[ $EX_SCORE -lt 7 ]] && EX_SCORE=5 && EX_NOTES+="1-2-sections "
[[ $EXAMPLE_MENTIONS -ge 3 ]] && [[ $EX_SCORE -lt 5 ]] && EX_SCORE=4 && EX_NOTES+="mentions-only "
[[ $HAS_INPUT -gt 0 ]] && [[ $EX_SCORE -lt 10 ]] && EX_SCORE=$((EX_SCORE+1)) && EX_NOTES+="with-input "
[[ $HAS_OUTPUT -gt 0 ]] && [[ $EX_SCORE -lt 10 ]] && EX_SCORE=$((EX_SCORE+1)) && EX_NOTES+="with-output "
[[ $HAS_VERIFY -gt 0 ]] && [[ $EX_SCORE -lt 10 ]] && EX_SCORE=$((EX_SCORE+1)) && EX_NOTES+="with-verify "
[[ $EXAMPLE_SECTIONS -eq 0 && $EXAMPLE_MENTIONS -eq 0 ]] && EX_NOTES+="⚠no-examples "
[[ $EX_SCORE -gt 10 ]] && EX_SCORE=10
dim_score "Examples" 15 "$EX_SCORE" "$EX_NOTES"

# ── Dimension 6: Metadata (10%) ─────────────────────────────────────────────
MD_SCORE=4
MD_NOTES=""
HAS_NAME=$(grep -c "^name:" "$SKILL_FILE" || true)
HAS_DESC=$(grep -c "^description:" "$SKILL_FILE" || true)
HAS_LICENSE=$(grep -c "^license:" "$SKILL_FILE" || true)
HAS_META=$(grep -c "^metadata:" "$SKILL_FILE" || true)
HAS_VERSION=$(grep -c "version:" "$SKILL_FILE" || true)
HAS_AUTHOR=$(grep -c "author:" "$SKILL_FILE" || true)

[[ $HAS_NAME -gt 0 ]] && MD_SCORE=$((MD_SCORE+2)) && MD_NOTES+="name "
[[ $HAS_DESC -gt 0 ]] && MD_SCORE=$((MD_SCORE+2)) && MD_NOTES+="description "
[[ $HAS_LICENSE -gt 0 ]] && MD_SCORE=$((MD_SCORE+1)) && MD_NOTES+="license "
[[ $HAS_META -gt 0 ]] && MD_SCORE=$((MD_SCORE+1)) && MD_NOTES+="metadata "
[[ $HAS_VERSION -gt 0 ]] && MD_SCORE=$((MD_SCORE+1)) && MD_NOTES+="version "
[[ $HAS_AUTHOR -gt 0 ]] && MD_SCORE=$((MD_SCORE+1)) && MD_NOTES+="author "
[[ $MD_SCORE -gt 10 ]] && MD_SCORE=10
dim_score "Metadata" 10 "$MD_SCORE" "$MD_NOTES"

# ── Dimension 7: Long-Context Handling (10%) ───────────────────────────────
LC_SCORE=2
LC_NOTES=""
HAS_CHUNKING=$(grep -Eci "chunk|分块|8K|token" "$SKILL_FILE" || true)
HAS_RAG=$(grep -Eci "RAG|retrieve|检索|rag" "$SKILL_FILE" || true)
HAS_CROSSREF=$(grep -Eci "cross-reference|preservation|保留|cross.reference" "$SKILL_FILE" || true)
HAS_LONGTEXT=$(grep -Eci "100K|100000|long.context|long-document" "$SKILL_FILE" || true)

[[ $HAS_CHUNKING -gt 0 ]] && LC_SCORE=$((LC_SCORE+2)) && LC_NOTES+="chunking "
[[ $HAS_RAG -gt 0 ]] && LC_SCORE=$((LC_SCORE+3)) && LC_NOTES+="RAG "
[[ $HAS_CROSSREF -gt 0 ]] && LC_SCORE=$((LC_SCORE+2)) && LC_NOTES+="cross-ref "
[[ $HAS_LONGTEXT -gt 0 ]] && LC_SCORE=$((LC_SCORE+1)) && LC_NOTES+="long-text "
[[ $LC_SCORE -gt 10 ]] && LC_SCORE=10
dim_score "Long-Context" 10 "$LC_SCORE" "$LC_NOTES"

# ── Overall score ───────────────────────────────────────────────────────────
echo ""
echo "  ─────────────────────────────────────────"
FINAL=$(echo "scale=1; $TOTAL" | bc)
echo "  Text Score (heuristic):  ${FINAL}/10"
echo ""

if (( $(echo "$FINAL >= 9.5" | bc -l) )); then
  echo "  Grade: EXEMPLARY ★★★  (Text ≥ 9.5)"
elif (( $(echo "$FINAL >= 9.0" | bc -l) )); then
  echo "  Grade: EXEMPLARY ✓  (Text ≥ 9.0)"
elif (( $(echo "$FINAL >= 8.0" | bc -l) )); then
  echo "  Grade: CERTIFIED ✓  (Text ≥ 8.0)"
elif (( $(echo "$FINAL >= 7.0" | bc -l) )); then
  echo "  Grade: GOOD         (Text ≥ 7.0)"
elif (( $(echo "$FINAL >= 6.0" | bc -l) )); then
  echo "  Grade: ACCEPTABLE   (needs improvement)"
else
  echo "  Grade: BELOW STANDARD — restore before shipping"
fi

echo ""
echo "  Note: This is a heuristic check, not a full evaluation."
echo "  Run: ./eval.sh $SKILL_FILE  for dual-track assessment."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
