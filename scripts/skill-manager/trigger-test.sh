#!/usr/bin/env bash
# trigger-test.sh — Comprehensive trigger accuracy tester
# Tests that user inputs are correctly routed to CREATE/EVALUATE/RESTORE/TUNE/SECURITY
# Target: ≥95% mode detection accuracy across 70+ diverse test inputs
#
# Usage: ./trigger-test.sh [path/to/SKILL.md] [--verbose] [--json]
# Returns: 0 if accuracy ≥ 95%, 1 otherwise

set -euo pipefail

SKILL_FILE="${1:-SKILL.md}"
VERBOSE=false
JSON_OUTPUT=false

for arg in "$@"; do
    case "$arg" in
        --verbose|-v) VERBOSE=true ;;
        --json)       JSON_OUTPUT=true ;;
    esac
done

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

pass()  { $VERBOSE && echo -e "${GREEN}  ✓ $1${NC}" || true; }
fail()  { echo -e "${RED}  ✗ $1${NC}"; }
info()  { echo -e "${BLUE}  → $1${NC}"; }
warn()  { echo -e "${YELLOW}  ⚠ $1${NC}"; }

# ─── Test Data ──────────────────────────────────────────────────────────────────
# Format: "input|expected_mode"
# 70 test cases covering:
#   - Exact keyword matches
#   - Natural language patterns
#   - Ambiguous inputs
#   - Chinese inputs
#   - Edge cases

declare -a TEST_CASES=(
    # ── CREATE (20 cases) ─────────────────────────────────────────────────────
    "create a code-review skill|CREATE"
    "I want to write a new skill for data extraction|CREATE"
    "build skill for API integration|CREATE"
    "make skill for web scraping|CREATE"
    "develop a new skill from scratch|CREATE"
    "write skill for image processing|CREATE"
    "design a skill for content moderation|CREATE"
    "generate skill for document parsing|CREATE"
    "initiate skill project for NLP|CREATE"
    "setup skill for database operations|CREATE"
    "prepare skill for text analysis|CREATE"
    "scaffold a new skill|CREATE"
    "help me create an agent skill|CREATE"
    "new skill please|CREATE"
    "start a skill from scratch|CREATE"
    "write me a skill for file management|CREATE"
    "bootstrap a skill for CI/CD|CREATE"
    "draft a skill specification|CREATE"
    "新建技能|CREATE"
    "创建技能 for code review|CREATE"

    # ── EVALUATE (15 cases) ───────────────────────────────────────────────────
    "evaluate my skill at skills/data-proc|EVALUATE"
    "test the skill quality|EVALUATE"
    "score my skill|EVALUATE"
    "assess the skill performance|EVALUATE"
    "check skill for issues|EVALUATE"
    "review skill quality|EVALUATE"
    "certify my skill|EVALUATE"
    "audit skill for production|EVALUATE"
    "validate skill output|EVALUATE"
    "benchmark skill accuracy|EVALUATE"
    "how good is this skill|EVALUATE"
    "is my skill GOLD certified|EVALUATE"
    "evaluate my skill score|EVALUATE"
    "评估技能|EVALUATE"
    "给我的技能打分|EVALUATE"

    # ── RESTORE (15 cases) ────────────────────────────────────────────────────
    "restore the underperforming skill|RESTORE"
    "fix skill at skills/broken|RESTORE"
    "repair the broken skill|RESTORE"
    "upgrade skill to fix the broken logic|RESTORE"
    "restore my low-scoring skill|RESTORE"
    "heal the damaged skill|RESTORE"
    "fix skill quality issues|RESTORE"
    "recover corrupted skill|RESTORE"
    "rollback to previous version|RESTORE"
    "reset skill to defaults|RESTORE"
    "my skill is broken please fix it|RESTORE"
    "skill regression detected|RESTORE"
    "skill not working as expected|RESTORE"
    "修复技能|RESTORE"
    "恢复损坏的技能|RESTORE"

    # ── TUNE (15 cases) ───────────────────────────────────────────────────────
    "optimize skill performance|TUNE"
    "tune the skill for better results|TUNE"
    "autotune my skill|TUNE"
    "boost skill quality|TUNE"
    "autotune my skill for higher score|TUNE"
    "skill optimization loop|TUNE"
    "enhance skill capabilities|TUNE"
    "refine skill precision|TUNE"
    "sharpen skill accuracy|TUNE"
    "streamline skill workflow|TUNE"
    "polish the skill to PLATINUM|TUNE"
    "self-optimize|TUNE"
    "自优化|TUNE"
    "调优技能|TUNE"
    "优化我的技能|TUNE"

    # ── SECURITY (5 cases) ────────────────────────────────────────────────────
    "run security review on skill|SECURITY"
    "OWASP audit for my skill|SECURITY"
    "check skill for vulnerabilities|SECURITY"
    "security hardening review|SECURITY"
    "scan for CWE violations|SECURITY"
)

# ─── Trigger Extraction ─────────────────────────────────────────────────────────

extract_triggers_for_mode() {
    local mode="$1"
    local file="$2"

    # Extract all quoted strings from the mode's row in the trigger table
    # Use whole quoted phrases only (2-50 chars, no pipe chars which are table delimiters)
    grep -E "\*\*${mode}\*\*" "$file" 2>/dev/null | \
        grep -oE '"[^"]{2,50}"' | \
        sed 's/"//g' | \
        tr '[:upper:]' '[:lower:]' | \
        sort -u
}

classify_input() {
    local input="$1"
    local input_lower
    input_lower=$(echo "$input" | tr '[:upper:]' '[:lower:]')

    # Check each mode in priority order using WHOLE-PHRASE matching.
    # Each extracted trigger is matched as a complete substring against the input,
    # NOT split into individual words. This prevents "skill for" in CREATE from
    # matching EVALUATE inputs like "check skill for issues".
    for mode in SECURITY CREATE EVALUATE RESTORE TUNE; do
        while IFS= read -r trigger; do
            [[ -z "$trigger" ]] && continue
            # Whole-phrase substring match (case-insensitive fixed string)
            if echo "$input_lower" | grep -qiF "$trigger" 2>/dev/null; then
                echo "$mode"
                return
            fi
        done < <(extract_triggers_for_mode "$mode" "$SKILL_FILE")
    done

    echo "UNKNOWN"
}

# ─── Run Tests ──────────────────────────────────────────────────────────────────

TOTAL=0
PASSED=0
FAILED=0
declare -A MODE_TOTAL MODE_PASSED

for mode in CREATE EVALUATE RESTORE TUNE SECURITY; do
    MODE_TOTAL[$mode]=0
    MODE_PASSED[$mode]=0
done

declare -a FAILURES=()

for test_case in "${TEST_CASES[@]}"; do
    IFS='|' read -r input expected_mode <<< "$test_case"
    TOTAL=$((TOTAL + 1))
    MODE_TOTAL[$expected_mode]=$((${MODE_TOTAL[$expected_mode]} + 1))

    detected=$(classify_input "$input")

    if [[ "$detected" == "$expected_mode" ]]; then
        PASSED=$((PASSED + 1))
        MODE_PASSED[$expected_mode]=$((${MODE_PASSED[$expected_mode]} + 1))
        pass "[$expected_mode] $input"
    else
        FAILED=$((FAILED + 1))
        FAILURES+=("EXPECTED=$expected_mode DETECTED=$detected: $input")
        fail "[$expected_mode → $detected] $input"
    fi
done

# ─── Compute Accuracy ───────────────────────────────────────────────────────────

ACCURACY=0
if [[ $TOTAL -gt 0 ]]; then
    ACCURACY=$(echo "scale=1; $PASSED * 100 / $TOTAL" | bc)
fi

# ─── Report ─────────────────────────────────────────────────────────────────────

if $JSON_OUTPUT; then
    echo "{"
    echo "  \"total\": $TOTAL,"
    echo "  \"passed\": $PASSED,"
    echo "  \"failed\": $FAILED,"
    echo "  \"accuracy\": $ACCURACY,"
    echo "  \"target\": 95.0,"
    echo "  \"passed_target\": $(echo "$ACCURACY >= 95.0" | bc -l),"
    echo "  \"mode_breakdown\": {"
    first=true
    for mode in CREATE EVALUATE RESTORE TUNE SECURITY; do
        m_total=${MODE_TOTAL[$mode]}
        m_passed=${MODE_PASSED[$mode]}
        m_acc=0
        [[ $m_total -gt 0 ]] && m_acc=$(echo "scale=1; $m_passed * 100 / $m_total" | bc)
        $first && first=false || echo ","
        printf '    "%s": {"total": %d, "passed": %d, "accuracy": %s}' \
            "$mode" "$m_total" "$m_passed" "$m_acc"
    done
    echo ""
    echo "  },"
    echo "  \"failures\": ["
    first=true
    for f in "${FAILURES[@]:-}"; do
        $first && first=false || echo ","
        printf '    "%s"' "$f"
    done
    echo ""
    echo "  ]"
    echo "}"
else
    echo ""
    echo "══════════════════════════════════════════════════════"
    echo "  Trigger Accuracy Test — agent-skill-creator"
    echo "══════════════════════════════════════════════════════"
    echo ""
    echo "  Per-Mode Results:"
    for mode in CREATE EVALUATE RESTORE TUNE SECURITY; do
        m_total=${MODE_TOTAL[$mode]}
        m_passed=${MODE_PASSED[$mode]}
        m_acc=0
        [[ $m_total -gt 0 ]] && m_acc=$(echo "scale=1; $m_passed * 100 / $m_total" | bc)
        status_icon="✓"
        status_color=$GREEN
        if echo "$m_acc < 95.0" | bc -l | grep -q "^1"; then
            status_icon="✗"
            status_color=$RED
        fi
        echo -e "  ${status_color}${status_icon}${NC} ${mode}: ${m_passed}/${m_total} (${m_acc}%)"
    done
    echo ""
    echo "  Overall: ${PASSED}/${TOTAL} correct"
    echo ""

    if [[ ${#FAILURES[@]} -gt 0 ]]; then
        echo "  Failures:"
        for f in "${FAILURES[@]}"; do
            echo -e "  ${RED}  • $f${NC}"
        done
        echo ""
    fi

    # Final verdict
    TARGET_MET=$(echo "$ACCURACY >= 95.0" | bc -l)
    if [[ "$TARGET_MET" == "1" ]]; then
        echo -e "  ${GREEN}PASS${NC}: Accuracy ${ACCURACY}% ≥ 95% target"
        echo ""
        exit 0
    else
        echo -e "  ${RED}FAIL${NC}: Accuracy ${ACCURACY}% < 95% target"
        echo ""
        echo "  Fix: Add missing trigger keywords to §2 Triggers table in SKILL.md"
        echo "  See failures above and add matching keywords for each failed input."
        echo ""
        exit 1
    fi
fi
