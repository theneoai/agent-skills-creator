#!/usr/bin/env bash
# score-llm.sh — LLM-enhanced skill quality evaluation
# Usage: ./score-llm.sh path/to/SKILL.md
# Combines shell format checks (30%) with LLM semantic evaluation (70%)

set -euo pipefail

SKILL_FILE="${1:-}"
if [[ -z "$SKILL_FILE" || ! -f "$SKILL_FILE" ]]; then
  echo "Usage: $0 path/to/SKILL.md"
  exit 1
fi

SKILL_DIR=$(dirname "$SKILL_FILE")
SKILL_NAME=$(basename "$SKILL_DIR")

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  LLM-ENHANCED EVALUATION"
echo "  $SKILL_NAME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check for API key
if [[ -z "${OPENAI_API_KEY:-}" && -z "${ANTHROPIC_API_KEY:-}" ]]; then
  echo "⚠️  No API key found. Using shell-only mode."
  USE_LLM=false
else
  USE_LLM=true
fi

# ── Part 1: Shell Format Check (30% weight) ──────────────────────────────────
echo "【1/2】 Running format checks..."

TOTAL=0
MAX=0

dim_score() {
  local name="$1" weight="$2" score="$3" notes="$4"
  local weighted
  weighted=$(echo "scale=4; $score * $weight / 100" | bc)
  TOTAL=$(echo "scale=4; $TOTAL + $weighted" | bc)
  MAX=$(echo "scale=4; $MAX + $weight / 100 * 10" | bc)
  printf "  %-22s %2.1f/10  (×%.2f)  %s\n" "$name" "$score" "$(echo "scale=2; $weight/100" | bc)" "$notes"
}

# System Prompt (20%)
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
dim_score "System Prompt" 10 "$SP_SCORE" "$SP_NOTES"

# Domain Knowledge (20%)
DK_SCORE=4
DK_NOTES=""
SPECIFICS=$(grep -cE "[0-9]+%|[0-9]+\.[0-9]+|McKinsey|TOGAF|ISO |RFC |v[0-9]+\.[0-9]" "$SKILL_FILE" || true)
GENERICS=$(grep -ciE "\bprofessional\b|\bindustry.leader\b|\bbest practices\b|\bexpert\b|\bworld.class\b" "$SKILL_FILE" || true)
CASES=$(grep -ciE "case study|example|scenario|benchmark|metric|KPI|SLA|ROI" "$SKILL_FILE" || true)
STANDARDS=$(grep -cE "NIST|OWASP|ISO [0-9]+|IEC |ANSI |IEEE|CWE|SOC " "$SKILL_FILE" || true)

[[ $SPECIFICS -ge 5 ]] && DK_SCORE=$((DK_SCORE+3)) && DK_NOTES+="specific-data "
[[ $CASES -ge 10 ]] && DK_SCORE=$((DK_SCORE+2)) && DK_NOTES+="rich-cases "
[[ $CASES -ge 5 ]] && [[ $DK_SCORE -lt 9 ]] && DK_SCORE=$((DK_SCORE+1)) && DK_NOTES+="has-cases "
[[ $STANDARDS -ge 3 ]] && DK_SCORE=$((DK_SCORE+1)) && DK_NOTES+="standards "
[[ $GENERICS -ge 5 ]] && DK_SCORE=$((DK_SCORE-2)) && DK_NOTES+="⚠generic "
[[ $DK_SCORE -lt 1 ]] && DK_SCORE=1
[[ $DK_SCORE -gt 10 ]] && DK_SCORE=10
dim_score "Domain Knowledge" 10 "$DK_SCORE" "$DK_NOTES"

# Workflow (20%)
WF_SCORE=3
WF_NOTES=""
HAS_WORKFLOW=$(grep -ci "workflow\|## Workflow\|## Phase\|Step [0-9]" "$SKILL_FILE" || true)
HAS_DONE=$(grep -ci "done.criteri\|done:" "$SKILL_FILE" || true)
HAS_FAIL=$(grep -ci "fail.criteri\|fail:" "$SKILL_FILE" || true)
HAS_PHASES=$(grep -cE "Phase [1-9]|Step [1-9]" "$SKILL_FILE" || true)

[[ $HAS_WORKFLOW -gt 0 ]] && WF_SCORE=$((WF_SCORE+2)) && WF_NOTES+="has-workflow "
[[ $HAS_PHASES -ge 3 ]] && WF_SCORE=$((WF_SCORE+2)) && WF_NOTES+="${HAS_PHASES}-phases "
[[ $HAS_DONE -gt 0 ]] && WF_SCORE=$((WF_SCORE+1)) && WF_NOTES+="done-criteria "
[[ $HAS_FAIL -gt 0 ]] && WF_SCORE=$((WF_SCORE+1)) && WF_NOTES+="fail-criteria "
[[ $WF_SCORE -gt 10 ]] && WF_SCORE=10
dim_score "Workflow" 5 "$WF_SCORE" "$WF_NOTES"

# Error Handling (15%)
EH_SCORE=3
EH_NOTES=""
HAS_EH=$(grep -ci "error.handling\|edge case\|anti.pattern\|risk\|failure\|recovery" "$SKILL_FILE" || true)
HAS_ANTIPATTERNS=$(grep -ci "anti-pattern\|Anti-Pattern" "$SKILL_FILE" || true)
HAS_RECOVERY=$(grep -ci "recovery\|retry\|fallback\|degrade\|reset" "$SKILL_FILE" || true)

[[ $HAS_EH -ge 3 ]] && EH_SCORE=$((EH_SCORE+3)) && EH_NOTES+="error-scenarios "
[[ $HAS_ANTIPATTERNS -gt 0 ]] && EH_SCORE=$((EH_SCORE+2)) && EH_NOTES+="anti-patterns "
[[ $HAS_RECOVERY -gt 2 ]] && EH_SCORE=$((EH_SCORE+2)) && EH_NOTES+="recovery "
[[ $EH_SCORE -gt 10 ]] && EH_SCORE=10
dim_score "Error Handling" 3 "$EH_SCORE" "$EH_NOTES"

# Examples (15%)
EX_SCORE=2
EX_NOTES=""
EXAMPLE_SECTIONS=$(grep -cE "^## .*[Ee]xample|^### .*[Ee]xample" "$SKILL_FILE" || true)

[[ $EXAMPLE_SECTIONS -ge 5 ]] && EX_SCORE=9 && EX_NOTES+="5+-sections "
[[ $EXAMPLE_SECTIONS -ge 3 ]] && [[ $EX_SCORE -lt 9 ]] && EX_SCORE=7 && EX_NOTES+="3-4-sections "
[[ $EXAMPLE_SECTIONS -ge 1 ]] && [[ $EX_SCORE -lt 7 ]] && EX_SCORE=5 && EX_NOTES+="1-2-sections "
[[ $EX_SCORE -lt 5 ]] && EX_SCORE=4 && EX_NOTES+="mentions-only "
[[ $EX_SCORE -gt 10 ]] && EX_SCORE=10
dim_score "Examples" 2 "$EX_SCORE" "$EX_NOTES"

# Metadata (10%)
MD_SCORE=4
MD_NOTES=""
HAS_NAME=$(grep -c "^name:" "$SKILL_FILE" || true)
HAS_DESC=$(grep -c "^description:" "$SKILL_FILE" || true)
HAS_LICENSE=$(grep -c "^license:" "$SKILL_FILE" || true)
HAS_VERSION=$(grep -c "version:" "$SKILL_FILE" || true)

[[ $HAS_NAME -gt 0 ]] && MD_SCORE=$((MD_SCORE+2)) && MD_NOTES+="name "
[[ $HAS_DESC -gt 0 ]] && MD_SCORE=$((MD_SCORE+2)) && MD_NOTES+="description "
[[ $HAS_LICENSE -gt 0 ]] && MD_SCORE=$((MD_SCORE+1)) && MD_NOTES+="license "
[[ $HAS_VERSION -gt 0 ]] && MD_SCORE=$((MD_SCORE+1)) && MD_NOTES+="version "
[[ $MD_SCORE -gt 10 ]] && MD_SCORE=10
dim_score "Metadata" 0 "$MD_SCORE" "$MD_NOTES"

SHELL_SCORE=$(echo "scale=2; $TOTAL" | bc)
echo ""
echo "  Shell Format Score: ${SHELL_SCORE}/10 (30% weight)"
echo ""

# ── Part 2: LLM Semantic Evaluation (70% weight) ────────────────────────────
if [[ "$USE_LLM" == "true" ]]; then
  echo "【2/2】 Running LLM semantic evaluation..."
  echo ""
  
  # Extract key sections
  SYSTEM_PROMPT=$(sed -n '/## § 1 · Identity/,/## § 2/p' "$SKILL_FILE" | head -50)
  WORKFLOW=$(sed -n '/## §.*Workflow/,/## §/p' "$SKILL_FILE" | head -80)
  EXAMPLES=$(sed -n '/## §.*Example/,/## §/p' "$SKILL_FILE" | head -100)
  
  # Build LLM prompt
  LLM_PROMPT="You are an expert skill evaluator. Evaluate this AI skill document.

SCORING CRITERIA (0-10 each):
1. **Clarity**: Is the language unambiguous? Can an AI follow this?
2. **Completeness**: Are all scenarios covered? Are there critical gaps?
3. **Consistency**: Do sections reference each other correctly? Any contradictions?
4. **Actionability**: Are the steps executable? Are success criteria clear?
5. **Helpfulness**: Would this actually help an AI agent perform better?

Return ONLY valid JSON (no markdown, no explanation):
{
  \"clarity\": X,
  \"completeness\": X,
  \"consistency\": X,
  \"actionability\": X,
  \"helpfulness\": X,
  \"overall\": X,
  \"issues\": [\"issue1\", \"issue2\"],
  \"strengths\": [\"strength1\"]
}"

  # Try OpenAI first, then Anthropic
  if [[ -n "${OPENAI_API_KEY:-}" ]]; then
    FULL_PROMPT="${LLM_PROMPT}

DOCUMENT:
${SYSTEM_PROMPT}

---
WORKFLOW:
${WORKFLOW}

---
EXAMPLES:
${EXAMPLES}"
    LLM_RESPONSE=$(curl -s https://api.openai.com/v1/chat/completions \
      -H "Authorization: Bearer $OPENAI_API_KEY" \
      -H "Content-Type: application/json" \
      -d "$(jq -n \
        --arg model "gpt-4o-mini" \
        --arg system "You are a skill quality evaluator." \
        --arg user "$FULL_PROMPT" \
        '{model: $model, messages: [{role: "system", content: $system}, {role: "user", content: $user}]}')" 2>/dev/null || LLM_RESPONSE="{}")
     
    # Parse response
    LLM_OVERALL=$(echo "$LLM_RESPONSE" | jq -r '.choices[0].message.content // empty' 2>/dev/null | jq -r '.overall // 5' 2>/dev/null || echo "5")
    LLM_CLARITY=$(echo "$LLM_RESPONSE" | jq -r '.choices[0].message.content // empty' 2>/dev/null | jq -r '.clarity // 5' 2>/dev/null || echo "5")
    LLM_COMPLETENESS=$(echo "$LLM_RESPONSE" | jq -r '.choices[0].message.content // empty' 2>/dev/null | jq -r '.completeness // 5' 2>/dev/null || echo "5")
    LLM_ACTIONABILITY=$(echo "$LLM_RESPONSE" | jq -r '.choices[0].message.content // empty' 2>/dev/null | jq -r '.actionability // 5' 2>/dev/null || echo "5")
  elif [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then
    FULL_PROMPT="${LLM_PROMPT}

DOCUMENT:
${SYSTEM_PROMPT}

---
WORKFLOW:
${WORKFLOW}

---
EXAMPLES:
${EXAMPLES}"
    LLM_RESPONSE=$(curl -s https://api.anthropic.com/v1/messages \
      -H "x-api-key: $ANTHROPIC_API_KEY" \
      -H "anthropic-version: 2023-06-01" \
      -H "Content-Type: application/json" \
      -d "$(jq -n \
        --arg model "claude-sonnet-4-20250514" \
        --arg max_tokens 500 \
        --arg prompt "$FULL_PROMPT" \
        '{model: $model, max_tokens: $max_tokens, messages: [{role: "user", content: $prompt}]}')" 2>/dev/null || LLM_RESPONSE="{}")
     
    LLM_OVERALL=$(echo "$LLM_RESPONSE" | jq -r '.content[0].text // empty' 2>/dev/null | jq -r '.overall // 5' 2>/dev/null || echo "5")
    LLM_CLARITY=$(echo "$LLM_RESPONSE" | jq -r '.content[0].text // empty' 2>/dev/null | jq -r '.clarity // 5' 2>/dev/null || echo "5")
    LLM_COMPLETENESS=$(echo "$LLM_RESPONSE" | jq -r '.content[0].text // empty' 2>/dev/null | jq -r '.completeness // 5' 2>/dev/null || echo "5")
    LLM_ACTIONABILITY=$(echo "$LLM_RESPONSE" | jq -r '.content[0].text // empty' 2>/dev/null | jq -r '.actionability // 5' 2>/dev/null || echo "5")
  fi
  
  # Ensure numeric values
  LLM_OVERALL=${LLM_OVERALL:-5}
  LLM_CLARITY=${LLM_CLARITY:-5}
  LLM_COMPLETENESS=${LLM_COMPLETENESS:-5}
  LLM_ACTIONABILITY=${LLM_ACTIONABILITY:-5}
  
  echo "  LLM Scores:"
  echo "    Clarity:        ${LLM_CLARITY}/10"
  echo "    Completeness:   ${LLM_COMPLETENESS}/10"
  echo "    Actionability:  ${LLM_ACTIONABILITY}/10"
  echo "    Overall (LLM): ${LLM_OVERALL}/10"
  echo ""
  
  # Weighted combination
  FINAL=$(echo "scale=2; $SHELL_SCORE * 0.3 + $LLM_OVERALL * 0.7" | bc)
else
  echo "【2/2】 LLM evaluation skipped (no API key)"
  FINAL=$SHELL_SCORE
fi

# ── Results ───────────────────────────────────────────────────────────────────
echo "  ══════════════════════════════════════════"
echo "  Combined Score: ${FINAL}/10"
echo ""

if (( $(echo "$FINAL >= 9.5" | bc -l) )); then
  echo "  Grade: EXEMPLARY ★★★  (≥ 9.5)"
elif (( $(echo "$FINAL >= 9.0" | bc -l) )); then
  echo "  Grade: EXEMPLARY ★★   (≥ 9.0)"
elif (( $(echo "$FINAL >= 8.0" | bc -l) )); then
  echo "  Grade: CERTIFIED ★    (≥ 8.0)"
elif (( $(echo "$FINAL >= 7.0" | bc -l) )); then
  echo "  Grade: GOOD           (≥ 7.0)"
elif (( $(echo "$FINAL >= 6.0" | bc -l) )); then
  echo "  Grade: ACCEPTABLE     (≥ 6.0)"
else
  echo "  Grade: NEEDS WORK     (< 6.0)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
