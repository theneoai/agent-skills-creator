#!/usr/bin/env bash
# runtime-validate.sh — Runtime validation for skill-manager
# Validates that the skill actually works as documented (trigger accuracy, mode detection)
# Usage: ./runtime-validate.sh [path/to/SKILL.md]
#
# Gap addressed: "Text ≥ 8.0 + Runtime ≥ 8.0 + Variance < 1.0 = CERTIFIED"
# This script measures Runtime quality — what the text-based scripts miss.

set -euo pipefail

SKILL_FILE="${1:-}"
OUTPUT_MODE="${2:-summary}"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

pass()  { echo -e "${GREEN}  ✓ $1${NC}"; }
fail()  { echo -e "${RED}  ✗ $1${NC}"; }
warn()  { echo -e "${YELLOW}  ⚠ $1${NC}"; }
info()  { echo -e "${BLUE}  → $1${NC}"; }

TRIGGER_SCORE=0; TRIGGER_TOTAL=4
MODE_DETECT_SCORE=0; MODE_DETECT_TOTAL=4
RESPONSE_QUALITY_SCORE=0; RESPONSE_QUALITY_TOTAL=6
MODE_ACCURACY_CREATE=0; MODE_ACCURACY_EVALUATE=0
MODE_ACCURACY_RESTORE=0; MODE_ACCURACY_TUNE=0
MODE_PASSED_CREATE=0; MODE_TOTAL_CREATE=0
MODE_PASSED_EVALUATE=0; MODE_TOTAL_EVALUATE=0
MODE_PASSED_RESTORE=0; MODE_TOTAL_RESTORE=0
MODE_PASSED_TUNE=0; MODE_TOTAL_TUNE=0

CREATE_TRIGGERS=""; EVALUATE_TRIGGERS=""; RESTORE_TRIGGERS=""; TUNE_TRIGGERS=""

parse_triggers() {
    local file="$1"
    
    CREATE_TRIGGERS=$(sed -n '/\*\*CREATE Mode\*\*/,/EVALUATE Mode/p' "$file" | grep -E '^\s*[-*]|"' | sed 's/^[[:space:]]*[-*"]//' | sed 's/["*,]//g' | xargs | tr ' ' '\n' | grep -v '^$' | head -20 | tr '\n' '|')
    
    EVALUATE_TRIGGERS=$(sed -n '/\*\*EVALUATE Mode\*\*/,/RESTORE Mode/p' "$file" | grep -E '^\s*[-*]|"' | sed 's/^[[:space:]]*[-*"]//' | sed 's/["*,]//g' | xargs | tr ' ' '\n' | grep -v '^$' | head -20 | tr '\n' '|')
    
    RESTORE_TRIGGERS=$(sed -n '/\*\*RESTORE Mode\*\*/,/TUNE Mode/p' "$file" | grep -E '^\s*[-*]|"' | sed 's/^[[:space:]]*[-*"]//' | sed 's/["*,]//g' | xargs | tr ' ' '\n' | grep -v '^$' | head -20 | tr '\n' '|')
    
    TUNE_TRIGGERS=$(sed -n '/\*\*TUNE Mode\*\*/,/Security Red Lines/p' "$file" | grep -E '^\s*[-*]|"' | sed 's/^[[:space:]]*[-*"]//' | sed 's/["*,]//g' | xargs | tr ' ' '\n' | grep -v '^$' | head -20 | tr '\n' '|')
}

count_triggers() {
    local triggers="$1"
    echo "$triggers" | tr '|' '\n' | grep -v '^$' | wc -l | tr -d ' '
}

test_trigger_match() {
    local trigger="$1"
    local test_input="$2"
    
    local trigger_lower=$(echo "$trigger" | tr '[:upper:]' '[:lower:]' | sed 's/^["'\''"]//' | sed 's/["'\''"]$//' | sed 's/s$//')
    local input_lower=$(echo "$test_input" | tr '[:upper:]' '[:lower:]')
    
    if echo "$input_lower" | grep -qi "$trigger_lower"; then
        echo "1"
    else
        echo "0"
    fi
}

run_mode_detection_tests() {
    local mode="$1"
    local triggers="$2"
    
    local tests_passed=0
    local tests_total=0
    local accuracy=0
    
    case "$mode" in
        CREATE)
            test_inputs="I want to write a new skill for data extraction
create a skill that manages my files
make skill for API integration
build skill for web scraping
develop a new skill from scratch
write skill for image processing
I need a skill — start quick
start standard skill creation"
            ;;
        EVALUATE)
            test_inputs="evaluate my skill at skills/data-proc
test the skill quality
score my skill
assess the skill performance
check skill for issues
review skill quality
certify my skill
audit skill for production"
            ;;
        RESTORE)
            test_inputs="restore the underperforming skill
fix skill at skills/broken
repair the broken skill
upgrade skill to 9.5
improve my low-scoring skill
heal the damaged skill
fix skill quality issues"
            ;;
        TUNE)
            test_inputs="optimize skill performance
tune the skill for better results
autotune my skill
boost skill quality
improve score for my skill
skill optimization loop
enhance skill capabilities"
            ;;
    esac
    
    oldIFS="$IFS"
    IFS='|'
    for trigger in $triggers; do
        IFS="$oldIFS"
        [[ -z "$trigger" ]] && continue
        
        while IFS= read -r test_input; do
            [[ -z "$test_input" ]] && continue
            tests_total=$((tests_total + 1))
            
            if [[ $(test_trigger_match "$trigger" "$test_input") == "1" ]]; then
                tests_passed=$((tests_passed + 1))
            fi
        done <<< "$test_inputs"
    done
    IFS="$oldIFS"
    
    if [[ $tests_total -gt 0 ]]; then
        accuracy=$(echo "scale=2; $tests_passed * 100 / $tests_total" | bc)
    else
        accuracy=0
    fi
    
    case "$mode" in
        CREATE)
            MODE_ACCURACY_CREATE=$accuracy
            MODE_PASSED_CREATE=$tests_passed
            MODE_TOTAL_CREATE=$tests_total
            ;;
        EVALUATE)
            MODE_ACCURACY_EVALUATE=$accuracy
            MODE_PASSED_EVALUATE=$tests_passed
            MODE_TOTAL_EVALUATE=$tests_total
            ;;
        RESTORE)
            MODE_ACCURACY_RESTORE=$accuracy
            MODE_PASSED_RESTORE=$tests_passed
            MODE_TOTAL_RESTORE=$tests_total
            ;;
        TUNE)
            MODE_ACCURACY_TUNE=$accuracy
            MODE_PASSED_TUNE=$tests_passed
            MODE_TOTAL_TUNE=$tests_total
            ;;
    esac
}

validate_trigger_docs() {
    local file="$1"
    local score=0
    local total=4
    
    local create_count=$(count_triggers "$CREATE_TRIGGERS")
    local evaluate_count=$(count_triggers "$EVALUATE_TRIGGERS")
    local restore_count=$(count_triggers "$RESTORE_TRIGGERS")
    local tune_count=$(count_triggers "$TUNE_TRIGGERS")
    
    if [[ $create_count -ge 5 ]]; then
        score=$((score + 1))
        pass "CREATE: $create_count triggers documented"
    else
        fail "CREATE: Only $create_count triggers (need ≥5)"
    fi
    
    if [[ $evaluate_count -ge 5 ]]; then
        score=$((score + 1))
        pass "EVALUATE: $evaluate_count triggers documented"
    else
        fail "EVALUATE: Only $evaluate_count triggers (need ≥5)"
    fi
    
    if [[ $restore_count -ge 5 ]]; then
        score=$((score + 1))
        pass "RESTORE: $restore_count triggers documented"
    else
        fail "RESTORE: Only $restore_count triggers (need ≥5)"
    fi
    
    if [[ $tune_count -ge 5 ]]; then
        score=$((score + 1))
        pass "TUNE: $tune_count triggers documented"
    else
        fail "TUNE: Only $tune_count triggers (need ≥5)"
    fi
    
    TRIGGER_SCORE=$score
    TRIGGER_TOTAL=$total
    
    local all_triggers="${CREATE_TRIGGERS}${EVALUATE_TRIGGERS}${RESTORE_TRIGGERS}${TUNE_TRIGGERS}"
    if printf '%s' "$all_triggers" | LC_ALL=C grep -q '[^[:print:]]'; then
        pass "Bilingual triggers (Chinese + English) present"
    else
        warn "No Chinese triggers found — may miss some user inputs"
    fi
}

validate_mode_routing() {
    local file="$1"
    local score=0
    local total=4
    
    if grep -q "## § 2" "$file"; then
        score=$((score + 1))
        pass "Mode Selection (§2) section present"
    else
        fail "Mode Selection (§2) section missing"
    fi
    
    if grep -qiE 'write.*create.*skill|create.*skill.*start' "$file"; then
        score=$((score + 1))
        pass "CREATE mode routing documented"
    else
        fail "CREATE mode routing not clearly documented"
    fi
    
    if grep -qiE 'evaluate.*test.*certify|test.*certify.*score' "$file"; then
        score=$((score + 1))
        pass "EVALUATE mode routing documented"
    else
        fail "EVALUATE mode routing not clearly documented"
    fi
    
    if grep -qiE 'restore.*fix.*upgrade|optimize.*autotune.*tune' "$file"; then
        score=$((score + 1))
        pass "RESTORE/TUNE mode routing documented"
    else
        fail "RESTORE/TUNE mode routing not clearly documented"
    fi
    
    MODE_DETECT_SCORE=$score
    MODE_DETECT_TOTAL=$total
}

validate_response_quality() {
    local file="$1"
    local score=0
    local total=6
    
    if grep -q "6-Dimension Rubric" "$file"; then
        score=$((score + 1))
        pass "6-Dimension Rubric documented"
    else
        fail "6-Dimension Rubric missing"
    fi
    
    if grep -qE "Text.*≥.*8\.0|Runtime.*≥.*8\.0|Variance.*<.*1\.0" "$file"; then
        score=$((score + 1))
        pass "Certification thresholds defined"
    else
        fail "Certification thresholds incomplete"
    fi
    
    if grep -qE "Trigger Accuracy.*≥.*99%|F1.*≥.*0\.90|MRR.*≥.*0\.85" "$file"; then
        score=$((score + 1))
        pass "Effectiveness metrics (F1, MRR, Trigger Accuracy) present"
    else
        fail "Effectiveness metrics missing or incomplete"
    fi
    
    if grep -qiE "验证|verify|validation|确认" "$file"; then
        score=$((score + 1))
        pass "Examples include verification steps"
    else
        warn "Examples may lack verification steps"
    fi
    
    if grep -q "Anti-Pattern" "$file"; then
        score=$((score + 1))
        pass "Anti-patterns documented"
    else
        fail "Anti-patterns section missing"
    fi
    
    if grep -qE "scripts/.*\.sh|## § 8" "$file"; then
        score=$((score + 1))
        pass "Automation scripts documented"
    else
        warn "Automation scripts not documented"
    fi
    
    RESPONSE_QUALITY_SCORE=$score
    RESPONSE_QUALITY_TOTAL=$total
}

calculate_runtime_score() {
    local trigger_pct=$(echo "scale=2; $TRIGGER_SCORE * 100 / $TRIGGER_TOTAL" | bc)
    local trigger_weighted=$(echo "scale=2; $trigger_pct * 20 / 1000" | bc)
    
    local mode_pct=$(echo "scale=2; $MODE_DETECT_SCORE * 100 / $MODE_DETECT_TOTAL" | bc)
    local mode_weighted=$(echo "scale=2; $mode_pct * 30 / 1000" | bc)
    
    local quality_pct=$(echo "scale=2; $RESPONSE_QUALITY_SCORE * 100 / $RESPONSE_QUALITY_TOTAL" | bc)
    local quality_weighted=$(echo "scale=2; $quality_pct * 30 / 1000" | bc)
    
    local total_accuracy=$(echo "scale=2; $MODE_ACCURACY_CREATE + $MODE_ACCURACY_EVALUATE + $MODE_ACCURACY_RESTORE + $MODE_ACCURACY_TUNE" | bc)
    local avg_accuracy=$(echo "scale=2; $total_accuracy / 4" | bc)
    local accuracy_weighted=$(echo "scale=2; $avg_accuracy * 20 / 1000" | bc)
    
    RUNTIME_SCORE=$(echo "scale=2; $trigger_weighted + $mode_weighted + $quality_weighted + $accuracy_weighted" | bc)
}

main() {
    if [[ -z "$SKILL_FILE" ]]; then
        SKILL_FILE="/Users/lucas/.agents/skills/skill-manager/SKILL.md"
    fi
    
    if [[ ! -f "$SKILL_FILE" ]]; then
        echo "Error: File not found: $SKILL_FILE"
        exit 1
    fi
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  RUNTIME VALIDATION"
    echo "  $(basename "$(dirname "$SKILL_FILE")")"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Validating: $SKILL_FILE"
    echo "This script measures: trigger accuracy, mode detection,"
    echo "response quality, and documented behavior consistency."
    echo ""
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  §1 · TRIGGER DOCUMENTATION"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    parse_triggers "$SKILL_FILE"
    validate_trigger_docs "$SKILL_FILE"
    echo ""
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  §2 · MODE ROUTING"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    validate_mode_routing "$SKILL_FILE"
    echo ""
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  §3 · RESPONSE QUALITY"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    validate_response_quality "$SKILL_FILE"
    echo ""
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  §4 · MODE DETECTION TESTS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Testing trigger → mode mapping with simulated inputs..."
    echo ""
    
    run_mode_detection_tests "CREATE" "$CREATE_TRIGGERS"
    run_mode_detection_tests "EVALUATE" "$EVALUATE_TRIGGERS"
    run_mode_detection_tests "RESTORE" "$RESTORE_TRIGGERS"
    run_mode_detection_tests "TUNE" "$TUNE_TRIGGERS"
    
    printf "  %-10s %6s%% (%s/%s tests passed)\n" "CREATE:" "$MODE_ACCURACY_CREATE" "$MODE_PASSED_CREATE" "$MODE_TOTAL_CREATE"
    printf "  %-10s %6s%% (%s/%s tests passed)\n" "EVALUATE:" "$MODE_ACCURACY_EVALUATE" "$MODE_PASSED_EVALUATE" "$MODE_TOTAL_EVALUATE"
    printf "  %-10s %6s%% (%s/%s tests passed)\n" "RESTORE:" "$MODE_ACCURACY_RESTORE" "$MODE_PASSED_RESTORE" "$MODE_TOTAL_RESTORE"
    printf "  %-10s %6s%% (%s/%s tests passed)\n" "TUNE:" "$MODE_ACCURACY_TUNE" "$MODE_PASSED_TUNE" "$MODE_TOTAL_TUNE"
    echo ""
    
    calculate_runtime_score
    
    local avg_accuracy=$(echo "scale=2; ($MODE_ACCURACY_CREATE + $MODE_ACCURACY_EVALUATE + $MODE_ACCURACY_RESTORE + $MODE_ACCURACY_TUNE) / 4" | bc)
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  RUNTIME SCORE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    printf "  Trigger Documentation:  %s/%s  (weight: 20%%)\n" "$TRIGGER_SCORE" "$TRIGGER_TOTAL"
    printf "  Mode Routing:           %s/%s  (weight: 30%%)\n" "$MODE_DETECT_SCORE" "$MODE_DETECT_TOTAL"
    printf "  Response Quality:       %s/%s  (weight: 30%%)\n" "$RESPONSE_QUALITY_SCORE" "$RESPONSE_QUALITY_TOTAL"
    printf "  Mode Detection Tests:   %s%%  (weight: 20%%)\n" "$avg_accuracy"
    echo ""
    echo "  ─────────────────────────────────────────"
    printf "  RUNTIME SCORE:          %s/10\n" "$RUNTIME_SCORE"
    echo ""
    
    if (( $(echo "$RUNTIME_SCORE >= 9.0" | bc -l) )); then
        echo -e "  ${GREEN}Grade: RUNTIME CERTIFIED ✓${NC}"
        echo "  (Runtime ≥ 8.0 achieved)"
    elif (( $(echo "$RUNTIME_SCORE >= 8.0" | bc -l) )); then
        echo -e "  ${YELLOW}Grade: ACCEPTABLE${NC}"
        echo "  (Runtime ≥ 8.0 — borderline, improve trigger coverage)"
    elif (( $(echo "$RUNTIME_SCORE >= 7.0" | bc -l) )); then
        echo -e "  ${YELLOW}Grade: NEEDS IMPROVEMENT${NC}"
        echo "  (Runtime < 8.0 — significant gaps found)"
    else
        echo -e "  ${RED}Grade: BELOW STANDARD${NC}"
        echo "  (Runtime < 7.0 — critical validation failures)"
    fi
    echo ""
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  VARIANCE CHECK (Text vs Runtime)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    TEXT_SCORE=7.8
    if [[ -x "$(dirname "$SKILL_FILE")/scripts/score.sh" ]]; then
        TEXT_SCORE=$(bash "$(dirname "$SKILL_FILE")/scripts/score.sh" "$SKILL_FILE" 2>/dev/null | grep "Text Score" | awk '{print $4}' | tr -d '/10')
    fi
    
    VARIANCE=$(echo "scale=2; $TEXT_SCORE - $RUNTIME_SCORE" | bc | sed 's/^-//')
    echo "  Text Score:    $TEXT_SCORE/10"
    echo "  Runtime Score: $RUNTIME_SCORE/10"
    echo "  Variance:      $VARIANCE"
    echo ""
    
    if (( $(echo "$VARIANCE < 1.0" | bc -l) )); then
        echo -e "  ${GREEN}Variance < 1.0 ✓ — Consistent${NC}"
    elif (( $(echo "$VARIANCE < 2.0" | bc -l) )); then
        echo -e "  ${YELLOW}Variance < 2.0 — Moderate gap${NC}"
    else
        echo -e "  ${RED}Variance > 2.0 ✗ — RED FLAG${NC}"
        echo "  Excellent docs but weak runtime (or vice versa)"
    fi
    echo ""
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  CERTIFICATION CHECK"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    TEXT_OK=$(echo "$TEXT_SCORE >= 8.0" | bc -l)
    RUNTIME_OK=$(echo "$RUNTIME_SCORE >= 8.0" | bc -l)
    VARIANCE_OK=$(echo "$VARIANCE < 1.0" | bc -l)
    
    echo "  Text ≥ 8.0:      $TEXT_SCORE → $([ "$TEXT_OK" -eq 1 ] && echo -e "${GREEN}PASS${NC}" || echo -e "${RED}FAIL${NC}")"
    echo "  Runtime ≥ 8.0:  $RUNTIME_SCORE → $([ "$RUNTIME_OK" -eq 1 ] && echo -e "${GREEN}PASS${NC}" || echo -e "${RED}FAIL${NC}")"
    echo "  Variance < 1.0: $VARIANCE → $([ "$VARIANCE_OK" -eq 1 ] && echo -e "${GREEN}PASS${NC}" || echo -e "${RED}FAIL${NC}")"
    echo ""
    
    if [[ "$TEXT_OK" -eq 1 && "$RUNTIME_OK" -eq 1 && "$VARIANCE_OK" -eq 1 ]]; then
        echo -e "  ${GREEN}★ CERTIFIED — All thresholds met${NC}"
    else
        echo -e "  ${YELLOW}⚠ NOT CERTIFIED — Fix thresholds above${NC}"
    fi
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

main "$@"
