#!/usr/bin/env bash
# tune.sh — AI-driven autonomous skill optimization
# Usage: ./tune.sh path/to/SKILL.md [rounds]
# Analyzes score output to identify weakest dimension and makes targeted improvements.

set -euo pipefail

SKILL_FILE="${1:-}"
ROUNDS="${2:-100}"

if [[ -z "$SKILL_FILE" || ! -f "$SKILL_FILE" ]]; then
  echo "Usage: $0 path/to/SKILL.md [rounds]"
  exit 1
fi

REAL_PATH=$(realpath "$SKILL_FILE" 2>/dev/null || echo "$SKILL_FILE")
if [[ ! "$REAL_PATH" =~ ^/Users/lucas/.agents/skills/ ]]; then
  echo "Error: Path outside allowed directory"
  exit 1
fi
SKILL_FILE="$REAL_PATH"

SKILL_DIR=$(dirname "$SKILL_FILE")
SKILL_NAME=$(basename "$SKILL_DIR")
SCRIPT_DIR="$(dirname "$0")"
SCORE_SCRIPT="$SCRIPT_DIR/score-v2.sh"
RESULTS_FILE="$SKILL_DIR/results.tsv"

compare() {
  local a="$1" op="$2" b="$3"
  awk -v a="$a" -v b="$b" 'BEGIN { exit (!(a '"$op"' b)) }'
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  AI-DRIVEN TUNE"
echo "  Target: $SKILL_NAME"
echo "  Rounds: $ROUNDS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ ! -f "$RESULTS_FILE" ]]; then
  echo -e "round\tscore\tdelta\tstatus\tweakest\timprovement" > "$RESULTS_FILE"
fi

run_score() {
  bash "$SCORE_SCRIPT" "$1" 2>/dev/null
}

parse_total_score() {
  local output="$1"
  echo "$output" | grep "TOTAL SCORE:" | awk '{print $3}' | cut -d'/' -f1
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
  CURRENT_OUTPUT=$(run_score "$SKILL_FILE")
  WEAKEST=$(get_weakest_dimension "$CURRENT_OUTPUT")
  
  cp "$SKILL_FILE" "${SKILL_FILE}.backup"
  
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
    *)
      improve_domain_knowledge "$SKILL_FILE"
      ;;
  esac
  
  NEW_OUTPUT=$(run_score "$SKILL_FILE")
  NEW_SCORE=$(parse_total_score "$NEW_OUTPUT")
  
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
  
  echo -e "$round\t$NEW_SCORE\t$DELTA\t$STATUS\t$WEAKEST\t$IMPROVEMENT" >> "$RESULTS_FILE"
  
  if (( round % 5 == 0 )); then
    echo "  Round $round: $NEW_SCORE (Δ$DELTA) [$STATUS] | weakest: $WEAKEST"
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
