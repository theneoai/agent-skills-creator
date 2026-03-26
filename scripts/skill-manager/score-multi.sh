#!/usr/bin/env bash
# score-multi.sh — Multi-LLM cross-validated skill evaluation
# Usage: ./score-multi.sh path/to/SKILL.md
# Uses GPT-4o AND Claude for cross-validation, detects gaming attempts

set -euo pipefail

SKILL_FILE="${1:-}"
if [[ -z "$SKILL_FILE" || ! -f "$SKILL_FILE" ]]; then
  echo "Usage: $0 path/to/SKILL.md"
  exit 1
fi

SKILL_DIR=$(dirname "$SKILL_FILE")
SKILL_NAME=$(basename "$SKILL_DIR")

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  MULTI-LLM CROSS-VALIDATED EVALUATION"
echo "  $SKILL_NAME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── Anti-Gaming Checks ────────────────────────────────────────────────────────
echo "【Security】 Running anti-gaming checks..."
echo ""

GAMING_SCORE=10
GAMING_ISSUES=()

# Check 1: Keyword density (too many keywords = suspicious)
TOTAL_WORDS=$(wc -w < "$SKILL_FILE")
KEYWORD_COUNT=$(grep -oE "[0-9]+%|[0-9]+\.[0-9]+|McKinsey|TOGAF|ISO|NIST|OWASP|RFC" "$SKILL_FILE" | wc -l)
KEYWORD_DENSITY=$(echo "scale=4; $KEYWORD_COUNT * 100 / $TOTAL_WORDS" | bc)

if (( $(echo "$KEYWORD_DENSITY > 5" | bc -l) )); then
  GAMING_SCORE=$((GAMING_SCORE - 2))
  GAMING_ISSUES+=("⚠️  Suspicious keyword density: ${KEYWORD_DENSITY}% (expected < 5%)")
fi

# Check 2: Repetition detection
REPEAT_LINES=$(sort "$SKILL_FILE" | uniq -c | awk '{if($1>3) print $2}' | wc -l)
if [[ $REPEAT_LINES -gt 5 ]]; then
  GAMING_SCORE=$((GAMING_SCORE - 2))
  GAMING_ISSUES+=("⚠️  Repetitive content detected: $REPEAT_LINES repeated lines")
fi

# Check 3: Empty/variable-only sections
EMPTY_PARAGRAPHS=$(awk '/^## /{section=$0} /^[a-z]/{if(length($0)<20) print section}' "$SKILL_FILE" | wc -l)
if [[ $EMPTY_PARAGRAPHS -gt 3 ]]; then
  GAMING_SCORE=$((GAMING_SCORE - 1))
  GAMING_ISSUES+=("⚠️  Thin content sections: $EMPTY_PARAGRAPHS")
fi

# Check 4: Placeholder detection
PLACEHOLDERS=$(grep -cE "\[TODO\]|\[FIXME\]|\[placeholder\]|\[\]" "$SKILL_FILE" || true)
if [[ $PLACEHOLDERS -gt 0 ]]; then
  GAMING_SCORE=$((GAMING_SCORE - 2))
  GAMING_ISSUES+=("⚠️  Placeholders found: $PLACEHOLDERS")
fi

# Check 5: Markdown structure validity
BROKEN_LINKS=$(grep -oE "\[.*\]\(\)" "$SKILL_FILE" | wc -l)
if [[ $BROKEN_LINKS -gt 0 ]]; then
  GAMING_SCORE=$((GAMING_SCORE - 1))
  GAMING_ISSUES+=("⚠️  Broken markdown links: $BROKEN_LINKS")
fi

echo "  Anti-Gaming Score: ${GAMING_SCORE}/10"
for issue in "${GAMING_ISSUES[@]}"; do
  echo "    $issue"
done
echo ""

# ── Multi-LLM Evaluation ─────────────────────────────────────────────────────
LLM_SCORES=()

# GPT-4o evaluation
if [[ -n "${OPENAI_API_KEY:-}" ]]; then
  echo "【Model 1/2】 GPT-4o evaluation..."
  
  CONTENT=$(cat "$SKILL_FILE" | head -200)
  
  GPT_PROMPT="Evaluate this AI skill document honestly. Be critical - don't give free points.

Score 0-10 for:
1. **Usefulness**: Would this actually help an AI agent perform better at its job?
2. **Clarity**: Is the workflow unambiguous and executable?
3. **Completeness**: Are edge cases and failure modes covered?
4. **Honesty**: Does it avoid buzzwords? Does it admit limitations?

JSON only:
{\"usefulness\": X, \"clarity\": X, \"completeness\": X, \"honesty\": X, \"overall\": X, \"concerns\": [\"...\"]}"

  GPT_RESPONSE=$(curl -s https://api.openai.com/v1/chat/completions \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$(jq -n \
      --arg model "gpt-4o" \
      --arg system "You are a strict skill evaluator. Be harsh but fair." \
      --arg user "$GPT_PROMPT"$'\n\n'"$CONTENT" \
      '{model: $model, messages: [{role: "system", content: $system}, {role: "user", content: $user}]}')")
  
  GPT_OVERALL=$(echo "$GPT_RESPONSE" | jq -r '.choices[0].message.content' 2>/dev/null | jq -r '.overall // 5' 2>/dev/null || echo "5")
  GPT_USEFULNESS=$(echo "$GPT_RESPONSE" | jq -r '.choices[0].message.content' 2>/dev/null | jq -r '.usefulness // 5' 2>/dev/null || echo "5")
  GPT_HONESTY=$(echo "$GPT_RESPONSE" | jq -r '.choices[0].message.content' 2>/dev/null | jq -r '.honesty // 5' 2>/dev/null || echo "5")
  
  echo "    Usefulness: ${GPT_USEFULNESS}/10"
  echo "    Honesty:    ${GPT_HONESTY}/10"
  echo "    Overall:    ${GPT_OVERALL}/10"
  
  LLM_SCORES+=("$GPT_OVERALL")
  echo ""
fi

# Claude evaluation
if [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then
  echo "【Model 2/2】 Claude evaluation..."
  
  CONTENT=$(cat "$SKILL_FILE" | head -200)
  
  CLAUDE_PROMPT="Evaluate this AI skill document critically. Be skeptical of inflated claims.

Score 0-10 for:
1. **Practical Value**: Can an AI actually use this to do its job better?
2. **Specificity**: Are there concrete examples vs vague advice?
3. **Soundness**: Are the recommendations based on valid reasoning?
4. **Completeness**: What's missing that would make this more useful?

JSON only:
{\"practical_value\": X, \"specificity\": X, \"soundness\": X, \"completeness\": X, \"overall\": X, \"missing\": [\"...\"]}"

  CLAUDE_RESPONSE=$(curl -s https://api.anthropic.com/v1/messages \
    -H "x-api-key: $ANTHROPIC_API_KEY" \
    -H "anthropic-version: 2023-06-01" \
    -H "Content-Type: application/json" \
    -d "$(jq -n \
      --arg model "claude-sonnet-4-20250514" \
      --arg max_tokens 600 \
      --arg prompt "$CLAUDE_PROMPT"$'\n\n'"$CONTENT" \
      '{model: $model, max_tokens: $max_tokens, messages: [{role: "user", content: $prompt}]}')")
  
  CLAUDE_OVERALL=$(echo "$CLAUDE_RESPONSE" | jq -r '.content[0].text' 2>/dev/null | jq -r '.overall // 5' 2>/dev/null || echo "5")
  CLAUDE_PRACTICAL=$(echo "$CLAUDE_RESPONSE" | jq -r '.content[0].text' 2>/dev/null | jq -r '.practical_value // 5' 2>/dev/null || echo "5")
  CLAUDE_SPECIFICITY=$(echo "$CLAUDE_RESPONSE" | jq -r '.content[0].text' 2>/dev/null | jq -r '.specificity // 5' 2>/dev/null || echo "5")
  
  echo "    Practical Value: ${CLAUDE_PRACTICAL}/10"
  echo "    Specificity:     ${CLAUDE_SPECIFICITY}/10"
  echo "    Overall:         ${CLAUDE_OVERALL}/10"
  
  LLM_SCORES+=("$CLAUDE_OVERALL")
  echo ""
fi

# ── Calculate Final Score ─────────────────────────────────────────────────────
echo "  ══════════════════════════════════════════"

# Calculate average LLM score
LLM_COUNT=${#LLM_SCORES[@]}
if [[ $LLM_COUNT -gt 0 ]]; then
  LLM_SUM=0
  for score in "${LLM_SCORES[@]}"; do
    LLM_SUM=$(echo "scale=2; $LLM_SUM + $score" | bc)
  done
  LLM_AVG=$(echo "scale=2; $LLM_SUM / $LLM_COUNT" | bc)
  
  # Combine: 40% anti-gaming, 60% LLM
  FINAL=$(echo "scale=2; $GAMING_SCORE * 0.4 + $LLM_AVG * 0.6" | bc)
else
  FINAL=$GAMING_SCORE
fi

echo "  Anti-Gaming Score: ${GAMING_SCORE}/10 (40% weight)"
[[ $LLM_COUNT -gt 0 ]] && echo "  LLM Average:      ${LLM_AVG}/10 (60% weight)"
echo ""
echo "  ★ FINAL SCORE: ${FINAL}/10 ★"
echo ""

# ── Grade & Recommendation ────────────────────────────────────────────────────
if (( $(echo "$FINAL >= 9.5" | bc -l) )); then
  echo "  Grade: EXEMPLARY ★★★"
  echo "  Status: Ready for production use"
elif (( $(echo "$FINAL >= 8.5" | bc -l) )); then
  echo "  Grade: EXCELLARY ★★"
  echo "  Status: Minor improvements possible"
elif (( $(echo "$FINAL >= 7.5" | bc -l) )); then
  echo "  Grade: GOOD ★"
  echo "  Status: Consider enhancements before production"
elif (( $(echo "$FINAL >= 6.0" | bc -l) )); then
  echo "  Grade: ACCEPTABLE"
  echo "  Status: Needs significant work"
else
  echo "  Grade: NEEDS WORK"
  echo "  Status: Major revisions required"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
