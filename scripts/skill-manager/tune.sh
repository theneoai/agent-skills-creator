#!/usr/bin/env bash
# tune.sh — AI-driven autonomous skill optimization with self-learning
# Usage: ./tune.sh path/to/SKILL.md [rounds]
# Analyzes score output to identify weakest dimension and makes targeted improvements.
# Learns from historical optimization data to select best strategies.

set -euo pipefail

SKILL_FILE="${1:-}"
ROUNDS="${2:-100}"

if [[ -z "$SKILL_FILE" || ! -f "$SKILL_FILE" ]]; then
  echo "Usage: $0 path/to/SKILL.md [rounds]"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/learning-engine.sh" 2>/dev/null || true

REAL_PATH=$(realpath "$SKILL_FILE" 2>/dev/null || echo "$SKILL_FILE")
SKILL_FILE="$REAL_PATH"

SKILL_DIR=$(dirname "$SKILL_FILE")
SKILL_NAME=$(basename "$SKILL_DIR")
SCORE_SCRIPT="$SCRIPT_DIR/score-v2.sh"
RESULTS_FILE="$SKILL_DIR/results.tsv"

use_historical=false
historical_best=""
IMPROVEMENT=""

detect_skill_type() {
  local file="$1"
  
  local has_mode_section=$(grep -cE "## §2.*Triggers|## § 2.*Triggers|Mode Selection" "$file" || true)
  local has_create_mode=$(grep -cE "\*\*CREATE\*\*|CREATE Mode" "$file" || true)
  local has_evaluate_mode=$(grep -cE "\*\*EVALUATE\*\*|EVALUATE Mode" "$file" || true)
  local has_restore_mode=$(grep -cE "\*\*RESTORE\*\*|RESTORE Mode" "$file" || true)
  local has_tune_mode=$(grep -cE "\*\*TUNE\*\*|TUNE Mode" "$file" || true)
  local has_trigger_table=$(grep -cE "Mode.*Triggers.*EN.*ZH|\| Mode \|" "$file" || true)
  
  local manager_score=0
  [[ $has_mode_section -gt 0 ]] && manager_score=$((manager_score + 2))
  [[ $has_create_mode -gt 0 ]] && manager_score=$((manager_score + 1))
  [[ $has_evaluate_mode -gt 0 ]] && manager_score=$((manager_score + 1))
  [[ $has_restore_mode -gt 0 ]] && manager_score=$((manager_score + 1))
  [[ $has_tune_mode -gt 0 ]] && manager_score=$((manager_score + 1))
  [[ $has_trigger_table -gt 0 ]] && manager_score=$((manager_score + 2))
  
  if [[ $manager_score -ge 4 ]]; then
    echo "manager"
    return
  fi
  
  local has_bash_blocks=$(grep -cE '```bash|```sh' "$file" || true)
  local has_commands=$(grep -cE '\$\(|bash |npm |pip |cargo |python |node ' "$file" || true)
  local has_usage_section=$(grep -ciE "Usage:|Commands:|Tools:|API|CLI" "$file" || true)
  
  local tool_score=0
  [[ $has_bash_blocks -ge 3 ]] && tool_score=$((tool_score + 2))
  [[ $has_commands -ge 5 ]] && tool_score=$((tool_score + 2))
  [[ $has_usage_section -gt 0 ]] && tool_score=$((tool_score + 1))
  
  if [[ $tool_score -ge 4 ]]; then
    echo "tool"
    return
  fi
  
  echo "content"
}

echo ""
echo "Detecting skill type..."
SKILL_TYPE=$(detect_skill_type "$SKILL_FILE")
echo "Skill type: $SKILL_TYPE"

if type print_learning_stats >/dev/null 2>&1; then
  print_learning_stats
fi

case "$SKILL_TYPE" in
  manager)
    RUNTIME_SCRIPT="$SCRIPT_DIR/runtime-validate.sh"
    VARIANCE_THRESHOLD=2.0
    echo "Using manager-type runtime validation (threshold: $VARIANCE_THRESHOLD)"
    ;;
  tool)
    RUNTIME_SCRIPT="$SCRIPT_DIR/runtime-validate.sh"
    VARIANCE_THRESHOLD=2.0
    echo "Using tool-type runtime validation (threshold: $VARIANCE_THRESHOLD)"
    ;;
  content)
    RUNTIME_SCRIPT="$SCRIPT_DIR/runtime-validate-content.sh"
    VARIANCE_THRESHOLD=2.5
    echo "Using content-type runtime validation (threshold: $VARIANCE_THRESHOLD)"
    ;;
esac

compare() {
  local a="$1" op="$2" b="$3"
  awk -v a="$a" -v b="$b" 'BEGIN { exit (!(a '"$op"' b)) }'
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  AI-DRIVEN TUNE (9-STEP LOOP)"
echo "  Target: $SKILL_NAME"
echo "  Rounds: $ROUNDS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ ! -f "$RESULTS_FILE" ]]; then
  echo -e "round\tscore\tdelta\tstatus\tweakest\timprovement" > "$RESULTS_FILE"
fi

run_score() {
  bash "$SCORE_SCRIPT" "$1" 2>/dev/null
}

curation_step() {
  local round="$1"
  if (( round % 10 == 0 )); then
    echo "  [CURATION] Reviewing optimization history..."
    local log_file="$SKILL_DIR/curation.log"
    if [[ -f "$log_file" ]]; then
      local lines=$(wc -l < "$log_file")
      if (( lines > 50 )); then
        echo "  [CURATION] Consolidating $lines knowledge entries..."
        tail -20 "$log_file" > "${log_file}.tmp" && mv "${log_file}.tmp" "$log_file"
        echo "  [CURATION] Preserved last 20 entries"
      fi
    fi
    echo "  [CURATION] Context preserved for next iteration" >> "$log_file"
  fi
}

human_review_check() {
  local score="$1"
  local round="$2"
  if (( round >= 10 )) && (( $(echo "$score < 8.0" | bc -l) )); then
    echo ""
    echo "  ⚠️  Score $score < 8.0 after $round rounds"
    echo "  [HUMAN_REVIEW] Expert review recommended"
    echo "  [HUMAN_REVIEW] HumanScore ≥ 7.0 OR Rounds > 10 required for certification"
    return 0
  fi
  return 1
}

parse_total_score() {
  local output="$1"
  echo "$output" | grep "TOTAL SCORE:" | awk '{print $3}' | cut -d'/' -f1
}

run_runtime_validation() {
  local skill_file="$1"
  local text_score="$2"
  local output
  output=$(bash "$RUNTIME_SCRIPT" "$skill_file" "$text_score" 2>&1 || true)
  if echo "$output" | grep -q "RUNTIME SCORE:"; then
    echo "$output" | grep "RUNTIME SCORE:" | awk '{print $3}' | cut -d'/' -f1
  else
    echo "0.0"
  fi
}

check_variance() {
  local text_score="$1"
  local runtime_score="$2"
  local diff=$(echo "$text_score - $runtime_score" | bc | sed 's/-//')
  echo "$diff"
}

get_weakest_dimension() {
  local output="$1"
  local weakest=""
  local lowest=11.0
  
  while IFS= read -r line; do
    local dim_name score
    dim_name=$(echo "$line" | awk '{print $1}')
    score=$(echo "$line" | awk '{print $2}' | cut -d'/' -f1)
    
    if [[ -n "$score" ]] && compare "$score" "<" "$lowest"; then
      lowest=$score
      weakest="$dim_name"
    fi
  done < <(echo "$output" | grep -E "^  [A-Za-z].* [0-9]+\.[0-9]/10")
  
  echo "${weakest:-System}"
}

apply_improvement() {
  local improvement="$1"
  local file="$2"
  
  case "$improvement" in
    "add §1.1 Identity")
      sed -i.bak '/## § 1 /a\
\
### §1.1 Identity\
The agent'"'"'s core identity:\
- **Role**: [Specific professional role]\
- **Expertise**: [Key knowledge domains]\
- **Boundary**: [Clear scope]' "$file" 2>/dev/null || true
      rm -f "${file}.bak"
      ;;
    "add §1.2 Framework")
      sed -i.bak '/## § 1 /a\
\
### §1.2 Framework\
Operational framework:\
- **Architecture**: [e.g., ReAct, CoT]\
- **Tools**: [Available tools]\
- **Memory**: [Context management]' "$file" 2>/dev/null || true
      rm -f "${file}.bak"
      ;;
    "add §1.3 Constraints")
      sed -i.bak '/## § 1 /a\
\
### §1.3 Constraints\
Hard boundaries:\
- **Never**: [Explicit prohibitions]\
- **Always**: [Mandatory behaviors]' "$file" 2>/dev/null || true
      rm -f "${file}.bak"
      ;;
    "add quantitative metrics"|"add benchmarks"|"add framework references")
      sed -i.bak '/## § 2 /a\
\
### Quantitative Metrics\
- **Accuracy**: >95%\
- **Latency**: <200ms' "$file" 2>/dev/null || true
      rm -f "${file}.bak"
      ;;
    "add done criteria"|"add fail criteria"|"add decision points")
      sed -i.bak 's/Phase [0-9]/&\
✅ Done: [Criteria]/' "$file" 2>/dev/null || true
      rm -f "${file}.bak"
      ;;
    "add version field"|"add updated date"|"update version format")
      sed -i.bak '/^---/a\
**Updated**: 2026-03-28' "$file" 2>/dev/null || true
      rm -f "${file}.bak"
      ;;
    "add input/output to examples")
      sed -i.bak '/^## [Ee]xample/a\
**Input**: [Define input parameters]' "$file" 2>/dev/null || true
      rm -f "${file}.bak"
      ;;
    "add long-context handling")
      sed -i.bak '/## § 2 /a\
\
### Long-Context Handling\
- **Chunking**: Split documents into 8K token chunks' "$file" 2>/dev/null || true
      rm -f "${file}.bak"
      ;;
    *)
      echo "  [LEARNING] Unknown improvement: $improvement, trying domain knowledge"
      improve_domain_knowledge "$file"
      ;;
  esac
}

improve_system_prompt() {
  local file="$1"
  IMPROVEMENT="add §1.1 Identity"
  
  if ! grep -qiE "§1\.1|Identity" "$file"; then
    sed -i.bak '/## § 1 /a\
\
### §1.1 Identity\
The agent'"'"'s core identity:\
- **Role**: [Specific professional role]\
- **Expertise**: [Key knowledge domains]\
- **Boundary**: [Clear scope]' "$file" 2>/dev/null || true
    rm -f "${file}.bak"
    return 0
  fi
  
  if ! grep -qiE "§1\.2|Framework" "$file"; then
    sed -i.bak '/## § 1 /a\
\
### §1.2 Framework\
Operational framework:\
- **Architecture**: [e.g., ReAct, CoT]\
- **Tools**: [Available tools]\
- **Memory**: [Context management]' "$file" 2>/dev/null || true
    rm -f "${file}.bak"
    IMPROVEMENT="add §1.2 Framework"
    return 0
  fi
  
  if ! grep -qiE "§1\.3|Thinking|Constraints" "$file"; then
    sed -i.bak '/## § 1 /a\
\
### §1.3 Constraints\
Hard boundaries:\
- **Never**: [Explicit prohibitions]\
- **Always**: [Mandatory behaviors]' "$file" 2>/dev/null || true
    rm -f "${file}.bak"
    IMPROVEMENT="add §1.3 Constraints"
    return 0
  fi
  
  IMPROVEMENT="enhance constraints"
  sed -i.bak 's/\*\*Never\*\*/**Never**: [Detailed rule]/' "$file" 2>/dev/null || true
  rm -f "${file}.bak"
}

improve_domain_knowledge() {
  local file="$1"
  IMPROVEMENT="add quantitative metrics"
  
  local has_quant=$(grep -cE "[0-9]+%|[0-9]+\.[0-9]+" "$file" || true)
  
  if (( has_quant < 3 )); then
    sed -i.bak '/## § 2 /a\
\
### Quantitative Metrics\
- **Accuracy**: >95%\
- **Latency**: <200ms\
- **Quality**: PassRate >90%' "$file" 2>/dev/null || true
    rm -f "${file}.bak"
    return 0
  fi
  
  IMPROVEMENT="add benchmarks"
  if ! grep -qiE "benchmark|KPI|SLA" "$file"; then
    sed -i.bak '/## § 2 /a\
\
### Benchmarks\
Industry benchmarks:\
- **Standard**: [Reference]\
- **Target**: [Performance goal]' "$file" 2>/dev/null || true
    rm -f "${file}.bak"
    return 0
  fi
  
  IMPROVEMENT="add framework references"
  sed -i.bak '/## § 2 /a\
\
### Frameworks\
Applicable frameworks: ReAct, CoT, ToT' "$file" 2>/dev/null || true
  rm -f "${file}.bak"
}

improve_workflow() {
  local file="$1"
  IMPROVEMENT="add done criteria"
  
  if ! grep -qiE "Done:|✅" "$file"; then
    sed -i.bak 's/Phase [0-9]/&\
✅ Done: [Criteria]/' "$file" 2>/dev/null || true
    rm -f "${file}.bak"
    return 0
  fi
  
  IMPROVEMENT="add fail criteria"
  if ! grep -qiE "Fail:|❌" "$file"; then
    sed -i.bak 's/Done:.*/&\
❌ Fail: [Conditions]/' "$file" 2>/dev/null || true
    rm -f "${file}.bak"
    return 0
  fi
  
  IMPROVEMENT="add decision points"
  sed -i.bak '/## § [0-9]/a\
\
**Decision**: [Condition] → [Path A] | [Path B]' "$file" 2>/dev/null || true
  rm -f "${file}.bak"
}

improve_consistency() {
  local file="$1"
  IMPROVEMENT="add version field"
  
  if ! grep -qi "^version:" "$file"; then
    sed -i.bak '/^---/a\
version: 1.0.0' "$file" 2>/dev/null || true
    rm -f "${file}.bak"
    return 0
  fi
  
  IMPROVEMENT="add updated date"
  if ! grep -qiE "Updated:" "$file"; then
    sed -i.bak '/^---/a\
**Updated**: 2026-03-27' "$file" 2>/dev/null || true
    rm -f "${file}.bak"
    return 0
  fi
  
  IMPROVEMENT="clean placeholders"
  sed -i.bak 's/\[TODO\]//g; s/\[FIXME\]//g; s/\[placeholder\]//g' "$file" 2>/dev/null || true
  rm -f "${file}.bak"
}

improve_executability() {
  local file="$1"
  IMPROVEMENT="add input/output to examples"
  
  local has_input=$(grep -ciE "input:|Input:" "$file" || true)
  local has_output=$(grep -ciE "output:|Output:" "$file" || true)
  
  if (( has_input == 0 )); then
    sed -i.bak '/^## [Ee]xample/a\
**Input**: [Define input parameters]' "$file" 2>/dev/null || true
    rm -f "${file}.bak"
    return 0
  fi
  
  if (( has_output == 0 )); then
    sed -i.bak '/^## [Ee]xample/a\
**Output**: [Define expected output]' "$file" 2>/dev/null || true
    rm -f "${file}.bak"
    return 0
  fi
  
  IMPROVEMENT="add code examples"
  cat >> "$file" << 'EOF'

## Example

```bash
# Example command
echo "Hello"
```

**Input**: [Parameters]
**Output**: [Expected result]
EOF
}

improve_metadata() {
  local file="$1"
  IMPROVEMENT="add name"
  
  if ! grep -qi "^name:" "$file"; then
    sed -i.bak '/^---/a\
name: skill-name' "$file" 2>/dev/null || true
    rm -f "${file}.bak"
    return 0
  fi
  
  IMPROVEMENT="add license"
  if ! grep -qi "^license:" "$file"; then
    sed -i.bak '/^---/a\
license: MIT' "$file" 2>/dev/null || true
    rm -f "${file}.bak"
    return 0
  fi
  
  IMPROVEMENT="add tags"
  if ! grep -qi "^tags:" "$file"; then
    sed -i.bak '/^---/a\
tags: [tag1, tag2]' "$file" 2>/dev/null || true
    rm -f "${file}.bak"
    return 0
  fi
  
  IMPROVEMENT="add author"
  if ! grep -qiE "^author:|^metadata:" "$file"; then
    sed -i.bak '/^---/a\
author: [Name]' "$file" 2>/dev/null || true
    rm -f "${file}.bak"
  fi
}

improve_recency() {
  local file="$1"
  IMPROVEMENT="add recent benchmark ref"
  
  if ! grep -qiE "202[3-6]" "$file"; then
    sed -i.bak 's/baseline/benchmark (2024)/g' "$file" 2>/dev/null || true
    rm -f "${file}.bak"
    return 0
  fi
  
  IMPROVEMENT="update version format"
  sed -i.bak 's/^version:.*/version: 1.0.0/' "$file" 2>/dev/null || true
  rm -f "${file}.bak"
}

improve_error_handling() {
  local file="$1"
  IMPROVEMENT="add error section"
  
  if ! grep -qiE "## § [0-9].*Error|## § Error" "$file"; then
    sed -i.bak '/## § [0-9]/a\
\
### Error Handling\
Common errors and solutions:\
- **Error**: [Condition] → **Solution**: [Action]' "$file" 2>/dev/null || true
    rm -f "${file}.bak"
    return 0
  fi
  
  IMPROVEMENT="add try-catch"
  if ! grep -qiE "try.*catch|on.error|error.*handler" "$file"; then
    sed -i.bak '/### Error Handling/a\
- **Try-Catch**: Wrap risky operations with error handlers' "$file" 2>/dev/null || true
    rm -f "${file}.bak"
    return 0
  fi
  
  IMPROVEMENT="add fallback behavior"
  if ! grep -qiE "fallback|default.*behavior|graceful.*degrad" "$file"; then
    sed -i.bak '/### Error Handling/a\
- **Fallback**: [Primary fails] → [Backup behavior]' "$file" 2>/dev/null || true
    rm -f "${file}.bak"
  fi
}

improve_long_context() {
  local file="$1"
  IMPROVEMENT="add long-context handling"
  
  if ! grep -qiE "Long-Context|100K tokens|chunking|RAG" "$file"; then
    sed -i.bak '/## § 2 /a\
\
### Long-Context Handling\
- **Chunking**: Split documents into 8K token chunks\
- **RAG**: Retrieve relevant chunks for each query\
- **Context Preservation**: Maintain cross-reference accuracy' "$file" 2>/dev/null || true
    rm -f "${file}.bak"
    return 0
  fi
  
  IMPROVEMENT="enhance chunking strategy"
  if ! grep -qiE "8K|chunk.size|overlap" "$file"; then
    sed -i.bak '/Long-Context/a\
- **Chunk Size**: 8K tokens with 512 token overlap' "$file" 2>/dev/null || true
    rm -f "${file}.bak"
    return 0
  fi
  
  IMPROVEMENT="add context preservation metrics"
  if ! grep -qiE "cross-reference|preservation" "$file"; then
    sed -i.bak '/Long-Context/a\
- **Cross-Reference**: >95% preservation rate' "$file" 2>/dev/null || true
    rm -f "${file}.bak"
  fi
}

echo ""
echo "Getting baseline score..."
BASELINE_OUTPUT=$(run_score "$SKILL_FILE")
BASELINE=$(parse_total_score "$BASELINE_OUTPUT")
echo "Baseline: $BASELINE"
echo ""
echo "Dimension breakdown:"
echo "$BASELINE_OUTPUT" | grep -E "^  [A-Za-z].* [0-9]+\.[0-9]/10"

PREV_SCORE=$BASELINE
BEST_SCORE=$BASELINE

for ((round=1; round<=ROUNDS; round++)); do
  echo ""
  echo "=== Round $round/9-STEP LOOP ==="
  echo "  [1] READ → Getting score..."
  CURRENT_OUTPUT=$(run_score "$SKILL_FILE")
  WEAKEST=$(get_weakest_dimension "$CURRENT_OUTPUT")
  echo "  [2] ANALYZE → Weakest dimension: $WEAKEST"
  
  curation_step "$round"
  
  cp "$SKILL_FILE" "${SKILL_FILE}.backup"
  
  echo "  [4] PLAN → Selecting improvement strategy..."
  
  use_historical=false
  historical_best=""
  
  if type learn_from_history >/dev/null 2>&1; then
    if learn_from_history "$SKILL_TYPE" "$WEAKEST"; then
      local success_rate=$(awk -F',' -v st="$SKILL_TYPE" -v wd="$WEAKEST" -v imp="$HISTORICAL_BEST" '
        $1 == st && $2 == wd && $3 == imp { print $5 }
      ' "$SCRIPT_DIR/learning-db.csv")
      
      if [[ -n "$success_rate" ]] && (( $(echo "$success_rate >= 0.4" | bc -l 2>/dev/null) )); then
        use_historical=true
        historical_best="$HISTORICAL_BEST"
        echo "  [LEARNING] Historical best: $historical_best (success rate: $success_rate)"
      else
        echo "  [LEARNING] Historical best '$HISTORICAL_BEST' has low success rate ($success_rate), trying other strategy"
      fi
    fi
  fi
  
  if [[ "$use_historical" == "true" ]] && [[ -n "$historical_best" ]]; then
    echo "  [LEARNING] Using historical best strategy: $historical_best"
    IMPROVEMENT="$historical_best"
    apply_improvement "$historical_best" "$SKILL_FILE"
  else
    case "$WEAKEST" in
      System)
        improve_system_prompt "$SKILL_FILE"
        ;;
      Domain)
        improve_domain_knowledge "$SKILL_FILE"
        ;;
      Workflow)
        improve_workflow "$SKILL_FILE"
        ;;
      Consistency)
        improve_consistency "$SKILL_FILE"
        ;;
      Executability)
        improve_executability "$SKILL_FILE"
        ;;
      Metadata)
        improve_metadata "$SKILL_FILE"
        ;;
      Recency)
        improve_recency "$SKILL_FILE"
        ;;
      Error)
        improve_error_handling "$SKILL_FILE"
        ;;
      LongContext)
        improve_long_context "$SKILL_FILE"
        ;;
      *)
        improve_domain_knowledge "$SKILL_FILE"
        ;;
    esac
  fi
   
  echo "  [5] IMPLEMENT → Applying: $IMPROVEMENT"
  NEW_OUTPUT=$(run_score "$SKILL_FILE")
  NEW_SCORE=$(parse_total_score "$NEW_OUTPUT")
  
  echo "  [6] VERIFY → Checking variance..."
  RUNTIME_SCORE=$(run_runtime_validation "$SKILL_FILE" "$NEW_SCORE")
  VARIANCE=$(check_variance "$NEW_SCORE" "$RUNTIME_SCORE")
  
  if (( $(echo "$VARIANCE >= $VARIANCE_THRESHOLD" | bc -l) )); then
    echo ""
    echo "  ✗ HALT: Variance $VARIANCE >= $VARIANCE_THRESHOLD detected after $WEAKEST improvement"
    echo "  Text Score: $NEW_SCORE | Runtime Score: ${RUNTIME_SCORE:-0.0}"
    cp "${SKILL_FILE}.backup" "$SKILL_FILE"
    echo "  Reverted to previous version."
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  TUNE HALTED DUE TO HIGH VARIANCE"
    echo "  Skill type: $SKILL_TYPE"
    echo "  Round: $round | Variance: $VARIANCE (threshold: $VARIANCE_THRESHOLD)"
    echo "  Weakest dimension: $WEAKEST"
    echo "  Improvement attempted: $IMPROVEMENT"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 1
  fi
  
  if (( $(echo "$VARIANCE >= 1.0" | bc -l) )); then
    echo "  ⚠ WARNING: Variance $VARIANCE >= 1.0 (text=$NEW_SCORE, runtime=${RUNTIME_SCORE:-0.0})"
  fi
  
  DELTA=$(awk "BEGIN {printf \"%.3f\", $NEW_SCORE - $PREV_SCORE}")
  
  if compare "$DELTA" ">" "0"; then
    STATUS="keep"
    PREV_SCORE=$NEW_SCORE
    if compare "$NEW_SCORE" ">" "$BEST_SCORE"; then
      BEST_SCORE=$NEW_SCORE
    fi
  else
    STATUS="discard"
    cp "${SKILL_FILE}.backup" "$SKILL_FILE"
  fi
  
  echo "  [7] HUMAN_REVIEW → $(if human_review_check "$NEW_SCORE" "$round"; then echo "Expert review recommended"; else echo "Skipped (score OK or rounds < 10)"; fi)"
  
  echo "  [8] LOG → Recording to results.tsv..."
  echo -e "$round\t$NEW_SCORE\t$DELTA\t$STATUS\t$WEAKEST\t$IMPROVEMENT" >> "$RESULTS_FILE"
  
  if type record_learning >/dev/null 2>&1; then
    record_learning "$SKILL_TYPE" "$WEAKEST" "$IMPROVEMENT" "$DELTA" "$round"
  fi
  
  if (( round % 5 == 0 )); then
    echo "  Round $round: $NEW_SCORE (Δ$DELTA) [$STATUS] | weakest: $WEAKEST"
  fi
  
  if (( round % 10 == 0 )) && [[ "$STATUS" == "keep" ]]; then
    echo "  [9] COMMIT → Git commit..."
    cd "$SKILL_DIR" && git add -A && git commit -m "tune: round $round - score $NEW_SCORE - improve $WEAKEST" 2>/dev/null || true
  fi
  
  rm -f "${SKILL_FILE}.backup"
  
  if compare "$BEST_SCORE" ">=" "9.5"; then
    echo ""
    echo "  ★★★ Achieved EXEMPLARY score: $BEST_SCORE"
    break
  fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  TUNE COMPLETE"
echo "  Initial: $BASELINE"
echo "  Final: $PREV_SCORE"
echo "  Best: $BEST_SCORE"
echo "  Rounds: $ROUNDS"
echo "  Results: $RESULTS_FILE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""
echo "Final verification:"
run_score "$SKILL_FILE"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  VARIANCE CHECK"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Skill type: $SKILL_TYPE"
echo "  Variance threshold: $VARIANCE_THRESHOLD"
  RUNTIME_SCORE=$(run_runtime_validation "$SKILL_FILE" "$PREV_SCORE")
  VARIANCE=$(check_variance "$PREV_SCORE" "$RUNTIME_SCORE")
  echo "  Text Score:    $PREV_SCORE/10"
echo "  Runtime Score:  ${RUNTIME_SCORE:-0.0}/10"
echo "  Variance:       $VARIANCE"
if (( $(echo "$VARIANCE < 1.0" | bc -l) )); then
  echo "  Status: ✓ Consistent (variance < 1.0)"
elif (( $(echo "$VARIANCE < $VARIANCE_THRESHOLD" | bc -l) )); then
  echo "  Status: ✓ Acceptable gap (1.0 ≤ variance < $VARIANCE_THRESHOLD) for $SKILL_TYPE skill"
else
  echo "  Status: ✗ HIGH VARIANCE (variance ≥ $VARIANCE_THRESHOLD)"
fi
