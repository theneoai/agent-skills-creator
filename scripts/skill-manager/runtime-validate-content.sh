#!/usr/bin/env bash
# runtime-validate-content.sh — Runtime validation for content-type skills
# Validates: description accuracy, role definition, examples quality, workflow actionability
# Usage: ./runtime-validate-content.sh path/to/SKILL.md [text_score]

set -euo pipefail

SKILL_FILE="${1:-}"
TEXT_SCORE_PARAM="${2:-}"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
pass()  { echo -e "${GREEN}  ✓ $1${NC}"; }
fail()  { echo -e "${RED}  ✗ $1${NC}"; }
warn()  { echo -e "${YELLOW}  ⚠ $1${NC}"; }
info()  { echo -e "${BLUE}  → $1${NC}"; }

# Scoring variables
DESC_SCORE=0; DESC_TOTAL=4
ROLE_SCORE=0; ROLE_TOTAL=4
EXAMPLE_SCORE=0; EXAMPLE_TOTAL=4
WORKFLOW_SCORE=0; WORKFLOW_TOTAL=4
TRIGGER_SCORE=0; TRIGGER_TOTAL=3

validate_description() {
  local file="$1"
  local score=0
  local total=4
  
  # Check description exists and is meaningful
  local has_desc=$(grep -c "^description:" "$file" || true)
  if [[ $has_desc -gt 0 ]]; then
    local desc_len=$(grep "^description:" "$file" | head -1 | cut -d':' -f2 | tr -d ' ' | wc -c)
    if [[ $desc_len -gt 20 ]]; then
      score=$((score + 1))
      pass "Description exists and meaningful (${desc_len} chars)"
    else
      fail "Description too short"
    fi
  else
    fail "No description found"
  fi
  
  # Check description starts with "Use when"
  if grep -q "^description:.*Use when" "$file"; then
    score=$((score + 1))
    pass "Description starts with 'Use when'"
  else
    warn "Description should start with 'Use when' for better trigger matching"
  fi
  
  # Check description has trigger words
  local trigger_count=$(grep "^description:" "$file" | grep -ciE "use when|verify|check|analyze|detect|find" || true)
  if [[ $trigger_count -gt 0 ]]; then
    score=$((score + 1))
    pass "Description has trigger keywords"
  else
    fail "Description lacks trigger keywords"
  fi
  
  # Check description length under 500 chars (agentskills spec recommendation)
  local desc_text=$(grep "^description:" "$file" | head -1 | cut -d':' -f2-)
  local desc_len_chars=$(echo "$desc_text" | tr -d '\n' | wc -c)
  if [[ $desc_len_chars -lt 500 ]]; then
    score=$((score + 1))
    pass "Description length OK (${desc_len_chars} chars)"
  else
    warn "Description too long (${desc_len_chars} chars, recommended <500)"
  fi
  
  DESC_SCORE=$score
  DESC_TOTAL=$total
  
  echo ""
  echo "  Description Quality: $score/$total"
}

validate_role_definition() {
  local file="$1"
  local score=0
  local total=4
  
  # Check for role definition
  local has_role=$(grep -ciE "You are a|role:|## §1.*Identity|Identity —" "$file" || true)
  if [[ $has_role -gt 0 ]]; then
    score=$((score + 2))
    pass "Role definition found"
  else
    fail "No role definition found"
  fi
  
  # Check for expertise areas
  local has_expertise=$(grep -ciE "Expertise:|Core Expertise:|specialize|expert in" "$file" || true)
  if [[ $has_expertise -gt 0 ]]; then
    score=$((score + 1))
    pass "Expertise areas defined"
  else
    warn "No explicit expertise section"
  fi
  
  # Check for writing/style guidance
  local has_style=$(grep -ciE "Writing Style:|Communication Style:|Style:" "$file" || true)
  if [[ $has_style -gt 0 ]]; then
    score=$((score + 1))
    pass "Communication style defined"
  else
    warn "No explicit communication style"
  fi
  
  ROLE_SCORE=$score
  ROLE_TOTAL=$total
  
  echo ""
  echo "  Role Definition: $score/$total"
}

validate_examples() {
  local file="$1"
  local score=0
  local total=4
  
  # Count example sections
  local example_count=$(grep -cE "^## .*[Ee]xample|^### .*[Ee]xample" "$file" || true)
  if [[ $example_count -ge 3 ]]; then
    score=$((score + 2))
    pass "Has $example_count examples (≥3)"
  elif [[ $example_count -ge 1 ]]; then
    score=$((score + 1))
    pass "Has $example_count example(s)"
  else
    fail "No examples found"
  fi
  
  # Check for Input/Output format
  local has_input=$(grep -ciE "Input:|User:|human:" "$file" || true)
  local has_output=$(grep -ciE "Output:|Expert:|assistant:|response:" "$file" || true)
  if [[ $has_input -gt 0 ]] && [[ $has_output -gt 0 ]]; then
    score=$((score + 1))
    pass "Has Input/Output format"
  else
    warn "Missing Input/Output format in examples"
  fi
  
  # Check for verification checklist in examples
  local has_verify=$(grep -ciE "Verification:|Checklist:|✓|✅" "$file" || true)
  if [[ $has_verify -gt 0 ]]; then
    score=$((score + 1))
    pass "Has verification criteria"
  else
    warn "No verification criteria in examples"
  fi
  
  EXAMPLE_SCORE=$score
  EXAMPLE_TOTAL=$total
  
  echo ""
  echo "  Examples Quality: $score/$total"
}

validate_workflow() {
  local file="$1"
  local score=0
  local total=4
  
  # Check for workflow section
  local has_workflow=$(grep -ciE "Workflow:|workflow|## Phase|## Step" "$file" || true)
  if [[ $has_workflow -gt 0 ]]; then
    score=$((score + 2))
    pass "Workflow section found"
  else
    fail "No workflow section"
  fi
  
  # Check for Done criteria
  local has_done=$(grep -ciE "Done:|✓ Done|✅ Done" "$file" || true)
  if [[ $has_done -gt 0 ]]; then
    score=$((score + 1))
    pass "Has Done criteria"
  else
    warn "No explicit Done criteria"
  fi
  
  # Check for Fail criteria
  local has_fail=$(grep -ciE "Fail:|❌ Fail|✗ Fail" "$file" || true)
  if [[ $has_fail -gt 0 ]]; then
    score=$((score + 1))
    pass "Has Fail criteria"
  else
    warn "No explicit Fail criteria"
  fi
  
  WORKFLOW_SCORE=$score
  WORKFLOW_TOTAL=$total
  
  echo ""
  echo "  Workflow Quality: $score/$total"
}

validate_trigger_words() {
  local file="$1"
  local score=0
  local total=3
  
  # Check for Trigger Words section
  local has_trigger_section=$(grep -ciE "Trigger Words|## Trigger|TriGGer" "$file" || true)
  if [[ $has_trigger_section -gt 0 ]]; then
    score=$((score + 1))
    pass "Has Trigger Words section"
  fi
  
  # Check for actual trigger keywords
  local trigger_count=$(grep -ciE "^#|^  - |^  • " "$file" | head -20 || true)
  # More specific: check lines after "Trigger Words"
  local trigger_section=$(awk '/Trigger Words/,/^##|^#|^$/' "$file" 2>/dev/null | grep -cE "fact check|verify|detect|analyze|check" || true)
  if [[ $trigger_section -ge 3 ]]; then
    score=$((score + 2))
    pass "Has meaningful trigger keywords ($trigger_section found)"
  elif [[ $trigger_section -ge 1 ]]; then
    score=$((score + 1))
    pass "Has some trigger keywords ($trigger_section)"
  else
    warn "Trigger section may lack specificity"
  fi
  
  TRIGGER_SCORE=$score
  TRIGGER_TOTAL=$total
  
  echo ""
  echo "  Trigger Words: $score/$total"
}

calculate_runtime_score() {
  local total_possible=$((DESC_TOTAL + ROLE_TOTAL + EXAMPLE_TOTAL + WORKFLOW_TOTAL + TRIGGER_TOTAL))
  local total_earned=$((DESC_SCORE + ROLE_SCORE + EXAMPLE_SCORE + WORKFLOW_SCORE + TRIGGER_SCORE))
  
  if [[ $total_possible -eq 0 ]]; then
    echo "0.0"
    return
  fi
  
  # Simple weighted average scaled to 10
  local weighted_desc=0
  local weighted_role=0
  local weighted_example=0
  local weighted_workflow=0
  local weighted_trigger=0
  
  if [[ $DESC_TOTAL -gt 0 ]]; then
    weighted_desc=$(echo "scale=4; $DESC_SCORE * 25 / $DESC_TOTAL" | bc 2>/dev/null || echo "0")
  fi
  if [[ $ROLE_TOTAL -gt 0 ]]; then
    weighted_role=$(echo "scale=4; $ROLE_SCORE * 25 / $ROLE_TOTAL" | bc 2>/dev/null || echo "0")
  fi
  if [[ $EXAMPLE_TOTAL -gt 0 ]]; then
    weighted_example=$(echo "scale=4; $EXAMPLE_SCORE * 20 / $EXAMPLE_TOTAL" | bc 2>/dev/null || echo "0")
  fi
  if [[ $WORKFLOW_TOTAL -gt 0 ]]; then
    weighted_workflow=$(echo "scale=4; $WORKFLOW_SCORE * 20 / $WORKFLOW_TOTAL" | bc 2>/dev/null || echo "0")
  fi
  if [[ $TRIGGER_TOTAL -gt 0 ]]; then
    weighted_trigger=$(echo "scale=4; $TRIGGER_SCORE * 10 / $TRIGGER_TOTAL" | bc 2>/dev/null || echo "0")
  fi
  
  local total_weighted=$(echo "scale=2; $weighted_desc + $weighted_role + $weighted_example + $weighted_workflow + $weighted_trigger" | bc 2>/dev/null || echo "0")
  
  # Scale down to 10
  local scaled_score=$(echo "scale=2; $total_weighted / 10" | bc 2>/dev/null || echo "0")
  
  echo "$scaled_score"
}

main() {
  if [[ -z "$SKILL_FILE" ]]; then
    echo "Usage: $0 path/to/SKILL.md [text_score]"
    exit 1
  fi
  
  if [[ ! -f "$SKILL_FILE" ]]; then
    fail "File not found: $SKILL_FILE"
    exit 1
  fi
  
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  RUNTIME VALIDATION — content-type skill"
  echo "  $(basename "$(dirname "$SKILL_FILE")")"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  §1 · DESCRIPTION QUALITY"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  validate_description "$SKILL_FILE"
  
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  §2 · ROLE DEFINITION"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  validate_role_definition "$SKILL_FILE"
  
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  §3 · EXAMPLES"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  validate_examples "$SKILL_FILE"
  
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  §4 · WORKFLOW"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  validate_workflow "$SKILL_FILE"
  
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  §5 · TRIGGER WORDS"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  validate_trigger_words "$SKILL_FILE"
  
  local runtime_score=$(calculate_runtime_score)
  
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  RUNTIME SCORE"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  printf "  Description Quality:  %s/%s  (weight: 25%%)\n" "$DESC_SCORE" "$DESC_TOTAL"
  printf "  Role Definition:      %s/%s  (weight: 25%%)\n" "$ROLE_SCORE" "$ROLE_TOTAL"
  printf "  Examples:             %s/%s  (weight: 20%%)\n" "$EXAMPLE_SCORE" "$EXAMPLE_TOTAL"
  printf "  Workflow:             %s/%s  (weight: 20%%)\n" "$WORKFLOW_SCORE" "$WORKFLOW_TOTAL"
  printf "  Trigger Words:        %s/%s  (weight: 10%%)\n" "$TRIGGER_SCORE" "$TRIGGER_TOTAL"
  echo ""
  echo "  ─────────────────────────────────────────"
  printf "  RUNTIME SCORE:        %s/10\n" "$runtime_score"
  
  # Grade
  if (( $(echo "$runtime_score >= 9.0" | bc -l) )); then
    echo -e "  ${GREEN}Grade: EXEMPLARY${NC}"
  elif (( $(echo "$runtime_score >= 8.0" | bc -l) )); then
    echo -e "  ${GREEN}Grade: EXCELLENT${NC}"
  elif (( $(echo "$runtime_score >= 7.0" | bc -l) )); then
    echo -e "  ${YELLOW}Grade: GOOD${NC}"
  elif (( $(echo "$runtime_score >= 6.0" | bc -l) )); then
    echo -e "  ${YELLOW}Grade: ACCEPTABLE${NC}"
  else
    echo -e "  ${RED}Grade: NEEDS WORK${NC}"
  fi
  
  # Variance check
  if [[ -n "$TEXT_SCORE_PARAM" ]]; then
    TEXT_SCORE="$TEXT_SCORE_PARAM"
  else
    TEXT_SCORE="7.5"
  fi
  
  VARIANCE=$(echo "scale=2; $TEXT_SCORE - $runtime_score" | bc | sed 's/^-//')
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  VARIANCE CHECK (Text vs Runtime)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Text Score:    $TEXT_SCORE/10"
  echo "  Runtime Score: $runtime_score/10"
  echo "  Variance:      $VARIANCE"
  
  if (( $(echo "$VARIANCE < 1.0" | bc -l) )); then
    echo -e "  ${GREEN}Variance < 1.0 ✓ — Consistent${NC}"
  elif (( $(echo "$VARIANCE < 1.5" | bc -l) )); then
    echo -e "  ${YELLOW}Variance < 1.5 — Moderate gap${NC}"
  elif (( $(echo "$VARIANCE < 2.0" | bc -l) )); then
    echo -e "  ${YELLOW}Variance < 2.0 — Acceptable gap${NC}"
  else
    echo -e "  ${RED}Variance ≥ 2.0 — Large gap detected${NC}"
    echo "  Note: For content skills, variance < 2.0 is acceptable"
  fi
  
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

main "$@"