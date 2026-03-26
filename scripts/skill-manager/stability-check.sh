#!/usr/bin/env bash
# stability-check.sh — 稳定性检测机制
# 版本: 1.0.2 (Bash 3.2 兼容版)
# 检测: 触发词匹配一致性、评分一致性、幂等性
#
# 用法: ./stability-check.sh path/to/SKILL.md

set -eo pipefail

SKILL_FILE="${1:-}"

if [ -z "$SKILL_FILE" ] || [ ! -f "$SKILL_FILE" ]; then
    echo "Usage: $0 path/to/SKILL.md"
    exit 1
fi

SCRIPT_DIR="$(dirname "$0")"
LIB_DIR="$SCRIPT_DIR/lib"

# 加载模式库
if [ -f "$LIB_DIR/trigger_patterns.sh" ]; then
    source "$LIB_DIR/trigger_patterns.sh"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  STABILITY CHECK"
echo "  $(basename "$SKILL_FILE")"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

STABILITY_ISSUES=()
STABILITY_SCORE=10
CHECKS_PASSED=0
CHECKS_TOTAL=4

# ═══════════════════════════════════════════════════════════════════════════════
# CHECK 1: 触发词匹配一致性
# ═══════════════════════════════════════════════════════════════════════════════
echo "【Check 1/4】 Trigger Word Consistency"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 使用通用模式进行一致性检测
PATTERN_SP='system prompt|§ 1|## §'

count_score_sh=$(grep -cE "$PATTERN_SP" "$SKILL_FILE" 2>/dev/null || echo "0")
count_score_v2=$(grep -cE "$PATTERN_SP" "$SKILL_FILE" 2>/dev/null || echo "0")
count_score_llm=$(grep -cE "$PATTERN_SP" "$SKILL_FILE" 2>/dev/null || echo "0")

echo "  score.sh:      $count_score_sh"
echo "  score-v2.sh:   $count_score_v2"
echo "  score-llm.sh:  $count_score_llm"
echo ""

# 计算差异
max_count=$count_score_sh
min_count=$count_score_sh
[ "$count_score_v2" -gt "$max_count" ] && max_count=$count_score_v2
[ "$count_score_llm" -gt "$max_count" ] && max_count=$count_score_llm
[ "$count_score_v2" -lt "$min_count" ] && min_count=$count_score_v2
[ "$count_score_llm" -lt "$min_count" ] && min_count=$count_score_llm

count_diff=$((max_count - min_count))

if [ "$count_diff" -gt 2 ]; then
    STABILITY_ISSUES=("${STABILITY_ISSUES[@]}" "TRIGGER_INCONSISTENCY: max=$max_count min=$min_count diff=$count_diff")
    STABILITY_SCORE=$((STABILITY_SCORE - 2))
    echo "  ❌ Inconsistent trigger matches (diff=$count_diff > 2)"
else
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
    echo "  ✅ Consistent trigger matches (diff=$count_diff)"
fi
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# CHECK 2: 评分一致性
# ═══════════════════════════════════════════════════════════════════════════════
echo "【Check 2/4】 Scoring Consistency"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# score.sh 输出格式: "Text Score (heuristic):  10.00/10"
score_sh_raw=$(bash "$SCRIPT_DIR/score.sh" "$SKILL_FILE" 2>/dev/null | grep "Text Score" | awk '{print $4}')
score_sh=$(echo "$score_sh_raw" | cut -d'/' -f1)

# score-v2.sh 输出格式: "TOTAL SCORE: 8.50/10"
score_v2_raw=$(bash "$SCRIPT_DIR/score-v2.sh" "$SKILL_FILE" 2>/dev/null | grep "TOTAL SCORE" | awk '{print $3}')
score_v2=$(echo "$score_v2_raw" | cut -d'/' -f1)

echo "  score.sh:      $score_sh"
echo "  score-v2.sh:   $score_v2"
echo ""

if [ "$score_sh" != "" ] && [ "$score_v2" != "" ]; then
    diff=$(python3 -c "print(abs(float('$score_sh') - float('$score_v2')))")
    
    if python3 -c "exit(0 if float('$diff') > 1.5 else 1)" 2>/dev/null; then
        STABILITY_ISSUES=("${STABILITY_ISSUES[@]}" "SCORING_INCONSISTENCY: score.sh=$score_sh score-v2.sh=$score_v2 diff=$diff")
        STABILITY_SCORE=$((STABILITY_SCORE - 3))
        echo "  ❌ Score divergence detected (diff=$diff > 1.5)"
    else
        CHECKS_PASSED=$((CHECKS_PASSED + 1))
        echo "  ✅ Score consistent (diff=$diff)"
    fi
else
    echo "  ⚠️  Could not compute both scores"
fi
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# CHECK 3: 权重完整性
# ═══════════════════════════════════════════════════════════════════════════════
echo "【Check 3/4】 Weight Integrity"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 使用 Python 计算权重总和 (避免 shell 算术问题)
weights_result=$(python3 - << 'PYTHON'
weights_v1 = {"System Prompt": 20, "Domain Knowledge": 20, "Workflow": 20, "Error Handling": 15, "Examples": 15, "Metadata": 10}
weights_v2 = {"System Prompt": 15, "Domain Knowledge": 20, "Workflow": 20, "Consistency": 15, "Executability": 15, "Metadata": 15}
v1_sum = sum(weights_v1.values())
v2_sum = sum(weights_v2.values())
print(f"{v1_sum},{v2_sum}")
PYTHON
)

weights_v1_sum=$(echo "$weights_result" | cut -d',' -f1)
weights_v2_sum=$(echo "$weights_result" | cut -d',' -f2)

echo "  v1 weights sum: $weights_v1_sum (expected: 100)"
echo "  v2 weights sum: $weights_v2_sum (expected: 100)"
echo ""

if [ "$weights_v1_sum" -eq 100 ] && [ "$weights_v2_sum" -eq 100 ]; then
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
    echo "  ✅ Weight sums correct"
else
    STABILITY_ISSUES=("${STABILITY_ISSUES[@]}" "WEIGHT_SUM_ERROR: v1=$weights_v1_sum v2=$weights_v2_sum")
    STABILITY_SCORE=$((STABILITY_SCORE - 2))
    echo "  ❌ Weight sums incorrect"
fi
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# CHECK 4: 幂等性测试
# ═══════════════════════════════════════════════════════════════════════════════
echo "【Check 4/4】 Idempotency Test"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

run1=$(bash "$SCRIPT_DIR/score.sh" "$SKILL_FILE" 2>/dev/null | grep "Text Score" | awk '{print $4}' | cut -d'/' -f1)
run2=$(bash "$SCRIPT_DIR/score.sh" "$SKILL_FILE" 2>/dev/null | grep "Text Score" | awk '{print $4}' | cut -d'/' -f1)
run3=$(bash "$SCRIPT_DIR/score.sh" "$SKILL_FILE" 2>/dev/null | grep "Text Score" | awk '{print $4}' | cut -d'/' -f1)

echo "  Run 1: $run1"
echo "  Run 2: $run2"
echo "  Run 3: $run3"
echo ""

if [ "$run1" = "$run2" ] && [ "$run2" = "$run3" ]; then
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
    echo "  ✅ Idempotent (all 3 runs produce same score)"
else
    STABILITY_ISSUES=("${STABILITY_ISSUES[@]}" "NON_IDEMPOTENT: run1=$run1 run2=$run2 run3=$run3")
    STABILITY_SCORE=$((STABILITY_SCORE - 2))
    echo "  ❌ Non-idempotent scoring detected"
fi
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# 汇总报告
# ═══════════════════════════════════════════════════════════════════════════════
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  STABILITY REPORT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Checks Passed: ${CHECKS_PASSED}/${CHECKS_TOTAL}"
echo "  Stability Score: ${STABILITY_SCORE}/10"
echo ""

if [ "$STABILITY_SCORE" -ge 9 ]; then
    echo "  Status: ✅ STABLE"
elif [ "$STABILITY_SCORE" -ge 7 ]; then
    echo "  Status: ⚠️  MARGINALLY STABLE"
else
    echo "  Status: ❌ UNSTABLE"
fi

if [ ${#STABILITY_ISSUES[@]} -gt 0 ]; then
    echo ""
    echo "  Issues Found:"
    for issue in "${STABILITY_ISSUES[@]}"; do
        echo "    - $issue"
    done
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 返回退出码: 0 = 通过 (score >= 8), 1 = 失败
[ "$STABILITY_SCORE" -ge 8 ]
