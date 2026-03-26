#!/usr/bin/env bash
# score-v2.sh — V2 Enhanced scoring with consistency & executability checks
# Usage: ./score-v2.sh path/to/SKILL.md
# Features: Anti-gaming, consistency validation, executability checks

set -euo pipefail

SKILL_FILE="${1:-}"
if [[ -z "$SKILL_FILE" || ! -f "$SKILL_FILE" ]]; then
  echo "Usage: $0 path/to/SKILL.md"
  exit 1
fi

SKILL_DIR=$(dirname "$SKILL_FILE")
SKILL_NAME=$(basename "$SKILL_DIR")

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  SCORE-V2 EVALUATION"
echo "  $SKILL_NAME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

TOTAL=0
MAX=0

dim_score() {
  local name="$1" weight="$2" score="$3" notes="$4"
  local weighted
  weighted=$(echo "scale=4; $score * $weight / 100" | bc)
  TOTAL=$(echo "scale=4; $TOTAL + $weighted" | bc)
  MAX=$(echo "scale=4; $MAX + $weight / 100 * 10" | bc)
  printf "  %-20s %2.1f/10  (×%.2f)  %s\n" "$name" "$score" "$(echo "scale=2; $weight/100" | bc)" "$notes"
}

# ══════════════════════════════════════════════════════════════
# DIMENSION 1: SYSTEM PROMPT (15%)
# ══════════════════════════════════════════════════════════════
SP_SCORE=2
SP_NOTES=""
HAS_SP=$(grep -ci "system prompt\|## §\|§ [0-9]" "$SKILL_FILE" || true)
HAS_11=$(grep -c "§1\.1\|Identity" "$SKILL_FILE" || true)
HAS_12=$(grep -c "§1\.2\|Framework" "$SKILL_FILE" || true)
HAS_13=$(grep -c "§1\.3\|Thinking\|Constraints" "$SKILL_FILE" || true)

[[ $HAS_SP -gt 0 ]] && SP_SCORE=$((SP_SCORE+2)) && SP_NOTES+="has-header "
[[ $HAS_11 -gt 0 ]] && SP_SCORE=$((SP_SCORE+2)) && SP_NOTES+="§1.1 "
[[ $HAS_12 -gt 0 ]] && SP_SCORE=$((SP_SCORE+2)) && SP_NOTES+="§1.2 "
[[ $HAS_13 -gt 0 ]] && SP_SCORE=$((SP_SCORE+2)) && SP_NOTES+="§1.3 "
[[ $SP_SCORE -gt 10 ]] && SP_SCORE=10
dim_score "System Prompt" 15 "$SP_SCORE" "$SP_NOTES"

# ══════════════════════════════════════════════════════════════
# DIMENSION 2: DOMAIN KNOWLEDGE (20%)
# Enhanced: quantitative metrics, frameworks, lower thresholds
# ══════════════════════════════════════════════════════════════
DK_SCORE=4
DK_NOTES=""
SPECIFICS=$(grep -cE "[0-9]+%|[0-9]+\.[0-9]+" "$SKILL_FILE" || true)
CASES=$(grep -ciE "case study|benchmark|metric|KPI|SLA|ROI" "$SKILL_FILE" || true)
STANDARDS=$(grep -cE "NIST|OWASP|ISO [0-9]+|IEC|CWE|IEEE" "$SKILL_FILE" || true)
CONTEXT_KEYWORDS=$(grep -cE "[A-Z][a-z]+-[0-9]+|McKinsey [0-9]|TOGAF|ISO [0-9]{4}" "$SKILL_FILE" || true)
QUANTITATIVE=$(grep -ciE "F1|MRR|Accuracy|PassRate|BLEU|Recall|Precision|AUC|ROC" "$SKILL_FILE" || true)
FRAMEWORKS=$(grep -ciE "ReAct|CoT|ToT|RAG|Agent|AutoGen|CrewAI|langchain" "$SKILL_FILE" || true)

[[ $SPECIFICS -ge 3 ]] && DK_SCORE=$((DK_SCORE+2)) && DK_NOTES+="specific-data "
[[ $CASES -ge 3 ]] && DK_SCORE=$((DK_SCORE+2)) && DK_NOTES+="benchmarks "
[[ $QUANTITATIVE -ge 2 ]] && DK_SCORE=$((DK_SCORE+1)) && DK_NOTES+="quantitative "
[[ $STANDARDS -ge 2 ]] && DK_SCORE=$((DK_SCORE+2)) && DK_NOTES+="standards "
[[ $CONTEXT_KEYWORDS -ge 3 ]] && DK_SCORE=$((DK_SCORE+1)) && DK_NOTES+="contextual "
[[ $FRAMEWORKS -ge 2 ]] && DK_SCORE=$((DK_SCORE+1)) && DK_NOTES+="frameworks "
[[ $DK_SCORE -gt 10 ]] && DK_SCORE=10
dim_score "Domain Knowledge" 20 "$DK_SCORE" "$DK_NOTES"

# ══════════════════════════════════════════════════════════════
# DIMENSION 3: WORKFLOW (20%)
# Enhanced: control flow detection, parallel, sequential
# ══════════════════════════════════════════════════════════════
WF_SCORE=2
WF_NOTES=""
HAS_WORKFLOW=$(grep -ci "workflow\|## Workflow\|## Phase\|Step [0-9]" "$SKILL_FILE" || true)
HAS_DONE=$(grep -ci "done.criteria\|Done:\|✅" "$SKILL_FILE" || true)
HAS_FAIL=$(grep -ci "fail.criteria\|Fail:\|❌" "$SKILL_FILE" || true)
HAS_PHASES=$(grep -cE "Phase [0-9]+|Step [0-9]+[:\.\-]" "$SKILL_FILE" || true)
STEPS_WITH_PARAMS=$(grep -cE "Step [0-9]+[:\.\-].*[a-z]{10,}" "$SKILL_FILE" || true)
HAS_LOOPS=$(grep -ciE "while |for |until |loop|repeat|iterate" "$SKILL_FILE" || true)
HAS_CONDITIONALS=$(grep -ciE "if |when |case |switch|select|choose|decision" "$SKILL_FILE" || true)
HAS_PARALLEL=$(grep -ciE "parallel|concurrent|async|await|\|\|" "$SKILL_FILE" || true)

[[ $HAS_WORKFLOW -gt 0 ]] && WF_SCORE=$((WF_SCORE+2)) && WF_NOTES+="has-workflow "
[[ $HAS_PHASES -ge 3 ]] && WF_SCORE=$((WF_SCORE+2)) && WF_NOTES+="${HAS_PHASES}-phases "
[[ $HAS_DONE -gt 0 ]] && WF_SCORE=$((WF_SCORE+1)) && WF_NOTES+="done-criteria "
[[ $HAS_FAIL -gt 0 ]] && WF_SCORE=$((WF_SCORE+1)) && WF_NOTES+="fail-criteria "
[[ $STEPS_WITH_PARAMS -ge 3 ]] && WF_SCORE=$((WF_SCORE+1)) && WF_NOTES+="actionable "
[[ $HAS_LOOPS -gt 0 ]] && WF_SCORE=$((WF_SCORE+1)) && WF_NOTES+="loops "
[[ $HAS_CONDITIONALS -gt 0 ]] && WF_SCORE=$((WF_SCORE+1)) && WF_NOTES+="branching "
[[ $HAS_PARALLEL -gt 0 ]] && WF_SCORE=$((WF_SCORE+1)) && WF_NOTES+="parallel "
[[ $WF_SCORE -gt 10 ]] && WF_SCORE=10
dim_score "Workflow" 20 "$WF_SCORE" "$WF_NOTES"

# ══════════════════════════════════════════════════════════════
# DIMENSION 4: INTERNAL CONSISTENCY (15%)
# Enhanced: metadata checks, lower thresholds, expanded placeholder detection
# ══════════════════════════════════════════════════════════════
IC_SCORE=6
IC_NOTES=""

# Count cross-references
SECTION_REFS=$(grep -cE "§[0-9]+\.[0-9]|references/.*\.md" "$SKILL_FILE" || true)
INTERNAL_LINKS=$(grep -cE "\[.*\]\(.*\.md\)" "$SKILL_FILE" || true)

# Check for version consistency
HAS_VERSION=$(grep -c "^version:" "$SKILL_FILE" || true)
HAS_UPDATED=$(grep -c "^updated:\|^updated_at:" "$SKILL_FILE" || true)

# Check metadata completeness
HAS_DESCRIPTION=$(grep -c "^description:" "$SKILL_FILE" || true)
HAS_TAGS=$(grep -c "^tags:\|^categories:" "$SKILL_FILE" || true)

# Check for placeholder inconsistency (expanded detection)
PLACEHOLDERS=$(grep -ciE "\[TODO\]|\[FIXME\]|\[placeholder\]|TBD|undefined|null" "$SKILL_FILE" || true)

[[ $SECTION_REFS -ge 2 ]] && IC_SCORE=$((IC_SCORE+1)) && IC_NOTES+="cross-refs "
[[ $INTERNAL_LINKS -ge 1 ]] && IC_SCORE=$((IC_SCORE+1)) && IC_NOTES+="internal-links "
[[ $HAS_VERSION -gt 0 ]] && IC_SCORE=$((IC_SCORE+1)) && IC_NOTES+="versioned "
[[ $HAS_UPDATED -gt 0 ]] && IC_SCORE=$((IC_SCORE+1)) && IC_NOTES+="dated "
[[ $HAS_DESCRIPTION -gt 0 ]] && IC_SCORE=$((IC_SCORE+1)) && IC_NOTES+="described "
[[ $HAS_TAGS -gt 0 ]] && IC_SCORE=$((IC_SCORE+1)) && IC_NOTES+="tagged "
[[ $PLACEHOLDERS -eq 0 ]] && IC_SCORE=$((IC_SCORE+1)) && IC_NOTES+="clean "
[[ $PLACEHOLDERS -gt 0 ]] && IC_SCORE=$((IC_SCORE-1)) && IC_NOTES+="⚠placeholders "
[[ $IC_SCORE -gt 10 ]] && IC_SCORE=10
[[ $IC_SCORE -lt 1 ]] && IC_SCORE=1
dim_score "Consistency" 15 "$IC_SCORE" "$IC_NOTES"

# ══════════════════════════════════════════════════════════════
# DIMENSION 5: EXECUTABILITY (15%)
# Enhanced: expanded command patterns, step detection, code examples
# ══════════════════════════════════════════════════════════════
EX_SCORE=3
EX_NOTES=""
EXAMPLE_SECTIONS=$(grep -cE "^## .*[Ee]xample|^### .*[Ee]xample" "$SKILL_FILE" || true)
HAS_INPUT=$(grep -ciE "input:|输入:|user says|parameters:|arguments:" "$SKILL_FILE" || true)
HAS_OUTPUT=$(grep -ciE "output:|输出:|expected result|returns:|response:" "$SKILL_FILE" || true)
HAS_COMMAND=$(grep -cE '`[^`]+`|bash|\$\(|node |python |npm |yarn |git |./|cd |pip |cargo ' "$SKILL_FILE" || true)
HAS_STEPS=$(grep -cE "^## .*[Ss]tep|^## .*步骤|^1\." "$SKILL_FILE" || true)
EXAMPLE_CODES=$(grep -cE '```|    [a-z]|\t[a-z]' "$SKILL_FILE" || true)

# Check for vague language
VAGUE_WORDS=$(grep -ciE "soon|later|maybe|perhaps|might|possibly" "$SKILL_FILE" || true)

[[ $EXAMPLE_SECTIONS -ge 3 ]] && EX_SCORE=$((EX_SCORE+2)) && EX_NOTES+="examples "
[[ $EXAMPLE_SECTIONS -ge 5 ]] && EX_SCORE=$((EX_SCORE+1)) && EX_NOTES+="rich "
[[ $HAS_INPUT -gt 0 ]] && EX_SCORE=$((EX_SCORE+1)) && EX_NOTES+="has-input "
[[ $HAS_OUTPUT -gt 0 ]] && EX_SCORE=$((EX_SCORE+1)) && EX_NOTES+="has-output "
[[ $HAS_COMMAND -gt 0 ]] && EX_SCORE=$((EX_SCORE+1)) && EX_NOTES+="has-commands "
[[ $HAS_STEPS -ge 3 ]] && EX_SCORE=$((EX_SCORE+1)) && EX_NOTES+="stepped "
[[ $EXAMPLE_CODES -ge 2 ]] && EX_SCORE=$((EX_SCORE+1)) && EX_NOTES+="code-examples "
[[ $VAGUE_WORDS -gt 5 ]] && EX_SCORE=$((EX_SCORE-1)) && EX_NOTES+="⚠vague "
[[ $EX_SCORE -gt 10 ]] && EX_SCORE=10
[[ $EX_SCORE -lt 1 ]] && EX_SCORE=1
dim_score "Executability" 15 "$EX_SCORE" "$EX_NOTES"

# ══════════════════════════════════════════════════════════════
# DIMENSION 6: METADATA (15%)
# ══════════════════════════════════════════════════════════════
MD_SCORE=3
MD_NOTES=""
HAS_NAME=$(grep -c "^name:" "$SKILL_FILE" || true)
HAS_DESC=$(grep -c "^description:" "$SKILL_FILE" || true)
HAS_LICENSE=$(grep -c "^license:" "$SKILL_FILE" || true)
HAS_TAGS=$(grep -c "^tags:" "$SKILL_FILE" || true)
HAS_VERSION=$(grep -c "^version:" "$SKILL_FILE" || true)
HAS_AUTHOR=$(grep -c "^author:\|^metadata:" "$SKILL_FILE" || true)

[[ $HAS_NAME -gt 0 ]] && MD_SCORE=$((MD_SCORE+2)) && MD_NOTES+="name "
[[ $HAS_DESC -gt 0 ]] && MD_SCORE=$((MD_SCORE+2)) && MD_NOTES+="description "
[[ $HAS_LICENSE -gt 0 ]] && MD_SCORE=$((MD_SCORE+1)) && MD_NOTES+="license "
[[ $HAS_TAGS -gt 0 ]] && MD_SCORE=$((MD_SCORE+1)) && MD_NOTES+="tags "
[[ $HAS_VERSION -gt 0 ]] && MD_SCORE=$((MD_SCORE+1)) && MD_NOTES+="version "
[[ $HAS_AUTHOR -gt 0 ]] && MD_SCORE=$((MD_SCORE+1)) && MD_NOTES+="author "
[[ $MD_SCORE -gt 10 ]] && MD_SCORE=10
dim_score "Metadata" 15 "$MD_SCORE" "$MD_NOTES"

# ══════════════════════════════════════════════════════════════
# DIMENSION 7: RECENCY (10%)
# Enhanced: support markdown bold format **Updated:** **Version:**
# ══════════════════════════════════════════════════════════════
RC_SCORE=5
RC_NOTES=""

# Check Updated metadata field (supports **Updated:** or Updated:)
HAS_UPDATED=$(grep -cEi "^\*\*Updated\*\*:|[Uu]pdated:" "$SKILL_FILE" || true)
if [[ $HAS_UPDATED -gt 0 ]]; then
    RC_SCORE=$((RC_SCORE+2))
    RC_NOTES+="has-updated-date "
fi

# Check if references include version years (standards dating)
RECENT_REFS=$(grep -cE "(ISO|OWASP|NIST|RFC|CWE|TOGAF).*20[12][0-9]" "$SKILL_FILE" || true)
TOTAL_REFS=$(grep -cE "(ISO|OWASP|NIST|RFC|CWE|TOGAF)" "$SKILL_FILE" || true)
if [[ $TOTAL_REFS -gt 0 ]]; then
    REF_RATIO=$(echo "scale=2; $RECENT_REFS * 100 / $TOTAL_REFS" | bc)
    if (( $(echo "$REF_RATIO >= 50" | bc -l) )); then
        RC_SCORE=$((RC_SCORE+2))
        RC_NOTES+="standards-dated "
    elif (( $(echo "$REF_RATIO >= 25" | bc -l) )); then
        RC_SCORE=$((RC_SCORE+1))
        RC_NOTES+="partial-standards "
    fi
fi

# Check for recent benchmarks (2023+)
RECENT_BENCHMARKS=$(grep -cE "(2023|2024|2025)" "$SKILL_FILE" || true)
if [[ $RECENT_BENCHMARKS -gt 0 ]]; then
    RC_SCORE=$((RC_SCORE+1))
    RC_NOTES+="recent-benchmarks "
fi

# Check version field (supports **Version:** or Version:)
HAS_VERSION=$(grep -cEi "^\*\*Version\*\*:|[Vv]ersion:" "$SKILL_FILE" || true)
if [[ $HAS_VERSION -gt 0 ]]; then
    RC_SCORE=$((RC_SCORE+1))
    RC_NOTES+="has-version "
fi

[[ $RC_SCORE -gt 10 ]] && RC_SCORE=10
dim_score "Recency" 10 "$RC_SCORE" "$RC_NOTES"

# ══════════════════════════════════════════════════════════════
# OVERALL SCORE
# ══════════════════════════════════════════════════════════════
echo ""
echo "  ══════════════════════════════════════════"
FINAL=$(echo "scale=2; $TOTAL" | bc)
echo "  TOTAL SCORE: ${FINAL}/10"
echo ""

# Grade
if (( $(echo "$FINAL >= 9.5" | bc -l) )); then
  echo "  Grade: ★★★ EXEMPLARY"
elif (( $(echo "$FINAL >= 8.5" | bc -l) )); then
  echo "  Grade: ★★ EXCELLENT"
elif (( $(echo "$FINAL >= 7.5" | bc -l) )); then
  echo "  Grade: ★ GOOD"
elif (( $(echo "$FINAL >= 6.5" | bc -l) )); then
  echo "  Grade: ACCEPTABLE"
else
  echo "  Grade: NEEDS WORK"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
