#!/usr/bin/env bash
# score-secure.sh — Secure LLM scoring with injection protection
# Usage: ./score-secure.sh path/to/SKILL.md
# Features: Input sanitization, output validation, API key security

set -euo pipefail

SKILL_FILE="${1:-}"
if [[ -z "$SKILL_FILE" || ! -f "$SKILL_FILE" ]]; then
  echo "Usage: $0 path/to/SKILL.md"
  exit 1
fi

SKILL_DIR=$(dirname "$SKILL_FILE")
SKILL_NAME=$(basename "$SKILL_DIR")

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  SECURE LLM EVALUATION"
echo "  $SKILL_NAME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ══════════════════════════════════════════════════════════════
# STEP 1: INPUT SANITIZATION (Prevent Prompt Injection)
# ══════════════════════════════════════════════════════════════
echo "【Security】 Sanitizing input..."

# Create sanitized temp file
SANITIZED_CONTENT=$(mktemp)

# Remove potential injection patterns
sed -e 's/ignore previous instructions//gi' \
    -e 's/ignore all previous instructions//gi' \
    -e 's/forget all previous instructions//gi' \
    -e 's/you are now //gi' \
    -e 's/ignore.*system//gi' \
    -e 's/\[SYSTEM\]//g' \
    -e 's/<!--.*-->//g' \
    "$SKILL_FILE" > "$SANITIZED_CONTENT"

CONTENT_SIZE=$(wc -c < "$SANITIZED_CONTENT")
if [[ $CONTENT_SIZE -lt 100 ]]; then
  echo "⚠️  File too small after sanitization"
  rm -f "$SANITIZED_CONTENT"
  exit 1
fi

echo "  ✓ Input sanitized (${CONTENT_SIZE} bytes)"
echo ""

# ══════════════════════════════════════════════════════════════
# STEP 2: RUN SCORE-V2 (Base Scoring)
# ══════════════════════════════════════════════════════════════
echo "【Scoring】 Running v2 scoring..."

BASE_SCORE=$(bash "$(dirname "$0")/score-v2.sh" "$SKILL_FILE" 2>/dev/null | grep "TOTAL SCORE" | awk '{print $3}')
BASE_SCORE=${BASE_SCORE:-5.0}

echo "  Base Score: ${BASE_SCORE}/10"
echo ""

# ══════════════════════════════════════════════════════════════
# STEP 3: LLM EVALUATION (if API key available)
# ══════════════════════════════════════════════════════════════
LLM_SCORE=""
LLM_MODEL=""

if [[ -n "${OPENAI_API_KEY:-}" ]]; then
  echo "【LLM】 Running GPT-4o evaluation..."
  
  # Extract key sections (first 150 lines for context)
  EXTRACTED_CONTENT=$(head -150 "$SANITIZED_CONTENT")
  
  # Escape JSON special chars
  ESCAPED_CONTENT=$(echo "$EXTRACTED_CONTENT" | jq -Rs .)
  
  GPT_PROMPT="You are evaluating a skill document. Score 0-10 honestly.
Be critical - do not give free points. Return ONLY JSON.

{
  \"clarity\": score (0-10),
  \"usefulness\": score (0-10), 
  \"completeness\": score (0-10),
  \"honesty\": score (0-10, is it honest about limitations?),
  \"overall\": score (0-10),
  \"concerns\": [list of 1-3 specific issues]
}"

  LLM_RESPONSE=$(curl -s https://api.openai.com/v1/chat/completions \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$(jq -n \
      --arg model "gpt-4o" \
      --arg content "$GPT_PROMPT" \
      --arg doc "$ESCAPED_CONTENT" \
      '{
        "model": $model,
        "messages": [
          {"role": "system", "content": "You are a strict skill evaluator. Return ONLY valid JSON."},
          {"role": "user", "content": ($content + "\n\nDOCUMENT:\n" + $doc)}
        ]
      }')")
  
  # Parse with validation
  LLM_TEXT=$(echo "$LLM_RESPONSE" | jq -r '.choices[0].message.content // empty' 2>/dev/null)
  
  if [[ -n "$LLM_TEXT" ]]; then
    # Validate JSON structure
    LLM_SCORE=$(echo "$LLM_TEXT" | jq -r '.overall // empty' 2>/dev/null)
    if [[ "$LLM_SCORE" =~ ^[0-9]+(\.[0-9]+)?$ ]] && (( $(echo "$LLM_SCORE >= 0 && $LLM_SCORE <= 10" | bc -l) )); then
      echo "  GPT-4o Score: ${LLM_SCORE}/10"
      LLM_MODEL="gpt-4o"
    else
      echo "  ⚠️  Invalid LLM response, using base score"
      LLM_SCORE=""
    fi
  else
    echo "  ⚠️  No LLM response"
  fi
  echo ""

elif [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then
  echo "【LLM】 Running Claude evaluation..."
  
  EXTRACTED_CONTENT=$(head -150 "$SANITIZED_CONTENT")
  
  CLAUDE_PROMPT="Evaluate this skill document honestly. Score 0-10 for: clarity, usefulness, completeness, honesty (about limitations). Return ONLY valid JSON with keys: clarity, usefulness, completeness, honesty, overall, concerns (array)."

  LLM_RESPONSE=$(curl -s https://api.anthropic.com/v1/messages \
    -H "x-api-key: $ANTHROPIC_API_KEY" \
    -H "anthropic-version: 2023-06-01" \
    -H "Content-Type: application/json" \
    -d "$(jq -n \
      --arg model "claude-sonnet-4-20250514" \
      --arg prompt "$CLAUDE_PROMPT\n\n$EXTRACTED_CONTENT" \
      --arg max_tokens 400 \
      '{
        "model": $model,
        "max_tokens": $max_tokens,
        "messages": [{"role": "user", "content": $prompt}]
      }')")
  
  LLM_TEXT=$(echo "$LLM_RESPONSE" | jq -r '.content[0].text // empty' 2>/dev/null)
  
  if [[ -n "$LLM_TEXT" ]]; then
    LLM_SCORE=$(echo "$LLM_TEXT" | jq -r '.overall // empty' 2>/dev/null)
    if [[ "$LLM_SCORE" =~ ^[0-9]+(\.[0-9]+)?$ ]] && (( $(echo "$LLM_SCORE >= 0 && $LLM_SCORE <= 10" | bc -l) )); then
      echo "  Claude Score: ${LLM_SCORE}/10"
      LLM_MODEL="claude"
    else
      echo "  ⚠️  Invalid LLM response, using base score"
      LLM_SCORE=""
    fi
  fi
  echo ""
fi

# Cleanup
rm -f "$SANITIZED_CONTENT"

# ══════════════════════════════════════════════════════════════
# STEP 4: COMBINE SCORES
# ══════════════════════════════════════════════════════════════
echo "  ══════════════════════════════════════════"

if [[ -n "$LLM_SCORE" ]]; then
  # Weighted combination: 40% base, 60% LLM
  FINAL=$(echo "scale=2; $BASE_SCORE * 0.4 + $LLM_SCORE * 0.6" | bc)
  echo "  Base Score:  ${BASE_SCORE}/10 (40%)"
  echo "  LLM Score:   ${LLM_SCORE}/10 (60%)"
  echo "  Model Used:  ${LLM_MODEL}"
else
  FINAL=$BASE_SCORE
  echo "  Score:       ${FINAL}/10 (base only)"
fi

echo ""
echo "  ★ FINAL SCORE: ${FINAL}/10 ★"
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
