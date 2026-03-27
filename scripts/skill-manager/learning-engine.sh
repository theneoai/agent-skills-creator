#!/usr/bin/env bash
# learning-engine.sh — Self-learning optimization engine
# Analyzes historical optimization data to guide future improvements
# Usage: source learning-engine.sh && learn_from_history "skill_type" "weakest_dim"

set -euo pipefail

LEARNING_DB="$SCRIPT_DIR/learning-db.csv"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

init_learning_db() {
  if [[ ! -f "$LEARNING_DB" ]]; then
    echo "skill_type,weakest_dim,improvement,rounds_avg,success_rate,avg_delta,last_updated" > "$LEARNING_DB"
  fi
}

learn_from_history() {
  local skill_type="$1"
  local weakest_dim="$2"
  
  init_learning_db
  
  echo "  [LEARNING] Analyzing historical data for ($skill_type, $weakest_dim)..."
  
  if [[ ! -s "$LEARNING_DB" ]]; then
    echo "  [LEARNING] No historical data, using default strategy"
    return 1
  fi
  
  local historical_best=$(awk -F',' -v st="$skill_type" -v wd="$weakest_dim" '
    $1 == st && $2 == wd {
      success_rate = $5 + 0
      if (success_rate >= 0.5) {
        print $3, success_rate, $6
      }
    }
  ' "$LEARNING_DB" | sort -k2 -rn | head -1)
  
  if [[ -n "$historical_best" ]]; then
    local best_improvement=$(echo "$historical_best" | awk '{print $1}')
    local success_rate=$(echo "$historical_best" | awk '{print $2}')
    local avg_delta=$(echo "$historical_best" | awk '{print $3}')
    echo "  [LEARNING] Historical best: $best_improvement (success: ${success_rate}%, avg delta: $avg_delta)"
    echo "HISTORICAL_BEST=$best_improvement"
    return 0
  fi
  
  echo "  [LEARNING] No successful historical strategy found"
  return 1
}

record_learning() {
  local skill_type="$1"
  local weakest_dim="$2"
  local improvement="$3"
  local score_delta="$4"
  local round_num="$5"
  
  init_learning_db
  
  local success=0
  if (( $(echo "$score_delta > 0" | bc -l 2>/dev/null) )); then
    success=1
  fi
  
  local existing_line=$(awk -F',' -v st="$skill_type" -v wd="$weakest_dim" -v imp="$improvement" '
    $1 == st && $2 == wd && $3 == imp {
      print NR": "$0
    }
  ' "$LEARNING_DB")
  
  if [[ -n "$existing_line" ]]; then
    local line_num=$(echo "$existing_line" | cut -d':' -f1)
    local current_rounds=$(echo "$existing_line" | cut -d',' -f4)
    local current_success=$(echo "$existing_line" | cut -d',' -f5)
    local current_delta=$(echo "$existing_line" | cut -d',' -f6)
    
    local new_rounds=$((current_rounds + round_num))
    local new_success=$((current_success + success))
    local new_delta=$(echo "scale=4; ($current_delta + $score_delta) / 2" | bc)
    local new_success_rate=$(echo "scale=4; $new_success / $new_rounds" | bc)
    
    sed -i.bak "${line_num}s/.*/${skill_type},${weakest_dim},${improvement},${new_rounds},${new_success_rate},${new_delta},$(date +%Y-%m-%d)/" "$LEARNING_DB"
    rm -f "${LEARNING_DB}.bak"
    
    echo "  [LEARNING] Updated existing entry: $improvement (new success rate: $new_success_rate)"
  else
    echo "${skill_type},${weakest_dim},${improvement},${round_num},${success},${score_delta},$(date +%Y-%m-%d)" >> "$LEARNING_DB"
    echo "  [LEARNING] Recorded new learning: $improvement"
  fi
}

get_skill_type_strategy() {
  local skill_type="$1"
  local weakest_dim="$2"
  
  init_learning_db
  
  echo "  [LEARNING] Strategy selection for ($skill_type, $weakest_dim)..."
  
  local strategies=$(awk -F',' -v st="$skill_type" '
    BEGIN { best="" }
    $1 == st {
      success_rate = $5 + 0
      if (success_rate >= 0.4) {
        if (best == "" || success_rate > best_rate) {
          best = $3
          best_rate = success_rate
        }
      }
    }
    END { print best }
  ' "$LEARNING_DB")
  
  if [[ -n "$strategies" ]]; then
    echo "HISTORICAL_STRATEGY=$strategies"
    return 0
  fi
  
  return 1
}

print_learning_stats() {
  init_learning_db
  
  echo ""
  echo "  ═══════════════════════════════════════════"
  echo "  LEARNING DATABASE STATISTICS"
  echo "  ═══════════════════════════════════════════"
  
  local total_entries=$(tail -n +2 "$LEARNING_DB" | wc -l)
  echo "  Total improvement strategies: $total_entries"
  
  if [[ $total_entries -gt 0 ]]; then
    echo ""
    echo "  By Skill Type:"
    awk -F',' 'NR>1 {types[$1]++} END {for (t in types) print "    "t": "types[t]" strategies"}' "$LEARNING_DB" | sort
    
    echo ""
    echo "  Top Performing Strategies:"
    awk -F',' 'NR>1 && $5 >= 0.6 {print "    "$3" ("$1","$2"): "$5*100"% success"}' "$LEARNING_DB" | sort -t':' -k2 -rn | head -5
  fi
  
  echo "  ═══════════════════════════════════════════"
  echo ""
}

if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
  :
else
  echo "learning-engine.sh is a library, source it from tune.sh"
  exit 1
fi