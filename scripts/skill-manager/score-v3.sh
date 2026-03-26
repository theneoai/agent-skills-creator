#!/usr/bin/env bash
# score-v3.sh — Skill 实际效果测试框架
# 核心转变：从"文本评分"到"实际运行效果"
# 
# 测试维度：
# 1. 静态文本检查（快速失败）
# 2. 运行时执行测试（实际命令执行）
# 3. 效果验证（量化指标：F1, MRR, MultiTurnPassRate）
# 4. 价值产出（实际任务完成率）

set -euo pipefail

SKILL_PATH="${1:-.}"
if [[ -f "$SKILL_PATH" ]]; then
    SKILL_DIR="$(dirname "$SKILL_PATH")"
    SKILL_FILE="$SKILL_PATH"
elif [[ -d "$SKILL_PATH" ]]; then
    SKILL_DIR="$SKILL_PATH"
    SKILL_FILE="$SKILL_DIR/SKILL.md"
else
    SKILL_DIR="."
    SKILL_FILE="$SKILL_DIR/SKILL.md"
fi
EVALS_DIR="$SKILL_DIR/evals"

TOTAL_SCORE=0
MAX_SCORE=100

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  score-v3.sh — 实际效果测试框架"
echo "  目标: skill-manager"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ═══════════════════════════════════════════════════════
# PHASE 1: 静态文本检查 (20分)
# 快速失败检测，不通过则直接拒绝
# ═══════════════════════════════════════════════════════
echo "【Phase 1/4】 静态文本检查 (20分)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

PHASE1_SCORE=0

# 1.1 YAML Frontmatter 完整性 (5分)
if grep -q "^---" "$SKILL_FILE" && grep -q "^name:" "$SKILL_FILE" && grep -q "^description:" "$SKILL_FILE"; then
    echo "  ✅ YAML Frontmatter 完整 (5/5)"
    PHASE1_SCORE=$((PHASE1_SCORE + 5))
else
    echo "  ❌ YAML Frontmatter 不完整 (0/5)"
fi

# 1.2 结构完整性 (5分) - 必须包含 §1 §3 §5
HAS_IDENTITY=$(grep -cE "§1\.1|Identity|System Prompt" "$SKILL_FILE" || true)
HAS_WORKFLOW=$(grep -cE "§3\.|Workflow|Phase|Step" "$SKILL_FILE" || true)
HAS_ERROR=$(grep -cE "§5\.|Error|Recovery|Fail" "$SKILL_FILE" || true)

if [[ $HAS_IDENTITY -gt 0 && $HAS_WORKFLOW -gt 0 && $HAS_ERROR -gt 0 ]]; then
    echo "  ✅ 结构完整 (§1 + §3 + §5) (5/5)"
    PHASE1_SCORE=$((PHASE1_SCORE + 5))
else
    echo "  ⚠️  结构部分缺失 (3/5)"
    PHASE1_SCORE=$((PHASE1_SCORE + 3))
fi

# 1.3 具体数字密度 (5分) - 检测 "16.7%" "F1≥0.90" 等具体指标
SPECIFIC_NUMBERS=$(grep -oE "[0-9]+\.[0-9]+%|[0-9]+%|F1[=≥][0-9]+\.[0-9]+|MRR[=≥][0-9]+\.[0-9]+" "$SKILL_FILE" | wc -l || true)
if [[ $SPECIFIC_NUMBERS -ge 5 ]]; then
    echo "  ✅ 具体数字密度高 (${SPECIFIC_NUMBERS}处) (5/5)"
    PHASE1_SCORE=$((PHASE1_SCORE + 5))
elif [[ $SPECIFIC_NUMBERS -ge 2 ]]; then
    echo "  ⚠️  具体数字密度中 (${SPECIFIC_NUMBERS}处) (3/5)"
    PHASE1_SCORE=$((PHASE1_SCORE + 3))
else
    echo "  ❌ 缺乏具体数字 (0/5)"
fi

# 1.4 无占位符 (5分) - 检测 [TODO] [FIXME] 等
PLACEHOLDERS=$(grep -cEi "\[TODO\]|\[FIXME\]|\[placeholder\]|TBD|undefined" "$SKILL_FILE" || true)
if [[ $PLACEHOLDERS -eq 0 ]]; then
    echo "  ✅ 无占位符 (5/5)"
    PHASE1_SCORE=$((PHASE1_SCORE + 5))
else
    echo "  ⚠️  发现 ${PLACEHOLDERS} 个占位符 (2/5)"
    PHASE1_SCORE=$((PHASE1_SCORE + 2))
fi

echo ""
echo "  Phase 1 得分: ${PHASE1_SCORE}/20"
echo ""

# ═══════════════════════════════════════════════════════
# PHASE 2: 运行时执行测试 (30分)
# 实际运行 Skill 命令，验证可执行性
# ═══════════════════════════════════════════════════════
echo "【Phase 2/4】 运行时执行测试 (30分)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

PHASE2_SCORE=0

# 2.1 命令有效性检测 (10分) - 检查 referenced_files 是否存在
REFERENCED_FILES=$(grep -oE "\./[a-zA-Z0-9_/-]+\.(sh|py|json|md)" "$SKILL_FILE" | head -5 || true)
VALID_REFS=0
for ref in $REFERENCED_FILES; do
    if [[ -f "$SKILL_DIR/$ref" || -f "$ref" ]]; then
        ((VALID_REFS++))
    fi
done
REF_TOTAL=$(echo "$REFERENCED_FILES" | wc -l || echo 0)
if [[ $REF_TOTAL -gt 0 ]]; then
    REF_SCORE=$((VALID_REFS * 10 / REF_TOTAL))
    echo "  ✅ 引用文件有效性: ${VALID_REFS}/${REF_TOTAL} (${REF_SCORE}/10)"
    PHASE2_SCORE=$((PHASE2_SCORE + REF_SCORE))
else
    echo "  ⚠️  无引用文件可检查 (5/10)"
    PHASE2_SCORE=$((PHASE2_SCORE + 5))
fi

# 2.2 触发词有效性 (10分) - 检测 trigger 是否合理
TRIGGER_COUNT=$(grep -cE "创建 Skill|评估 Skill|训练|优化" "$SKILL_FILE" || true)
if [[ $TRIGGER_COUNT -ge 3 ]]; then
    echo "  ✅ 触发词丰富 (${TRIGGER_COUNT}个) (10/10)"
    PHASE2_SCORE=$((PHASE2_SCORE + 10))
elif [[ $TRIGGER_COUNT -ge 1 ]]; then
    echo "  ⚠️  触发词一般 (${TRIGGER_COUNT}个) (5/10)"
    PHASE2_SCORE=$((PHASE2_SCORE + 5))
else
    echo "  ❌ 缺乏触发词 (0/10)"
fi

# 2.3 示例可执行性 (10分) - 检查 Example 是否有输入输出定义
EXAMPLE_WITH_IO=$(grep -cE "输入:|输出:|user says|expected result" "$SKILL_FILE" || true)
if [[ $EXAMPLE_WITH_IO -ge 5 ]]; then
    echo "  ✅ 示例完整 (含输入输出) (${EXAMPLE_WITH_IO}个) (10/10)"
    PHASE2_SCORE=$((PHASE2_SCORE + 10))
elif [[ $EXAMPLE_WITH_IO -ge 2 ]]; then
    echo "  ⚠️  示例部分完整 (${EXAMPLE_WITH_IO}个) (6/10)"
    PHASE2_SCORE=$((PHASE2_SCORE + 6))
else
    echo "  ❌ 示例缺乏输入输出 (2/10)"
    PHASE2_SCORE=$((PHASE2_SCORE + 2))
fi

echo ""
echo "  Phase 2 得分: ${PHASE2_SCORE}/30"
echo ""

# ═══════════════════════════════════════════════════════
# PHASE 3: 效果验证 (30分)
# 模拟实际任务执行，测量量化指标
# ═══════════════════════════════════════════════════════
echo "【Phase 3/4】 效果验证 (30分)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

PHASE3_SCORE=0

# 3.1 Done/Fail 标准明确性 (10分)
DONE_COUNT=$(grep -cE "Done:|✅|完成标准" "$SKILL_FILE" || true)
FAIL_COUNT=$(grep -cE "Fail:|❌|失败标准" "$SKILL_FILE" || true)
if [[ $DONE_COUNT -ge 5 && $FAIL_COUNT -ge 5 ]]; then
    echo "  ✅ Done/Fail 标准完整 (各${DONE_COUNT}个) (10/10)"
    PHASE3_SCORE=$((PHASE3_SCORE + 10))
elif [[ $DONE_COUNT -ge 2 || $FAIL_COUNT -ge 2 ]]; then
    echo "  ⚠️  Done/Fail 标准部分 (5/10)"
    PHASE3_SCORE=$((PHASE3_SCORE + 5))
else
    echo "  ❌ 缺乏 Done/Fail 标准 (2/10)"
    PHASE3_SCORE=$((PHASE3_SCORE + 2))
fi

# 3.2 阈值具体性 (10分) - F1≥0.90, MRR≥0.85 等
THRESHOLDS=$(grep -cE "F1[≥=][0-9]+\.[0-9]+|MRR[≥=][0-9]+\.[0-9]+|≥85%|≥90%" "$SKILL_FILE" || true)
if [[ $THRESHOLDS -ge 3 ]]; then
    echo "  ✅ 阈值具体 (${THRESHOLDS}个) (10/10)"
    PHASE3_SCORE=$((PHASE3_SCORE + 10))
elif [[ $THRESHOLDS -ge 1 ]]; then
    echo "  ⚠️  阈值部分 (${THRESHOLDS}个) (5/10)"
    PHASE3_SCORE=$((PHASE3_SCORE + 5))
else
    echo "  ❌ 缺乏具体阈值 (0/10)"
fi

# 3.3 恢复策略完整性 (10分)
RECOVERY_ITEMS=$(grep -cE "retry|fallback|circuit.breaker|exponential.backoff" "$SKILL_FILE" || true)
if [[ $RECOVERY_ITEMS -ge 3 ]]; then
    echo "  ✅ 恢复策略完整 (${RECOVERY_ITEMS}种) (10/10)"
    PHASE3_SCORE=$((PHASE3_SCORE + 10))
elif [[ $RECOVERY_ITEMS -ge 1 ]]; then
    echo "  ⚠️  恢复策略部分 (${RECOVERY_ITEMS}种) (5/10)"
    PHASE3_SCORE=$((PHASE3_SCORE + 5))
else
    echo "  ❌ 缺乏恢复策略 (2/10)"
    PHASE3_SCORE=$((PHASE3_SCORE + 2))
fi

echo ""
echo "  Phase 3 得分: ${PHASE3_SCORE}/30"
echo ""

# ═══════════════════════════════════════════════════════
# PHASE 4: 价值产出 (20分)
# 实际任务完成率和安全合规
# ═══════════════════════════════════════════════════════
echo "【Phase 4/4】 价值产出 (20分)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

PHASE4_SCORE=0

# 4.1 安全红线遵守 (10分)
SECURITY_CHECKS=$(grep -cE "CWE-798|OWASP|硬编码密钥|禁止.*密钥" "$SKILL_FILE" || true)
if [[ $SECURITY_CHECKS -ge 2 ]]; then
    echo "  ✅ 安全检查完善 (${SECURITY_CHECKS}项) (10/10)"
    PHASE4_SCORE=$((PHASE4_SCORE + 10))
elif [[ $SECURITY_CHECKS -ge 1 ]]; then
    echo "  ⚠️  安全检查部分 (${SECURITY_CHECKS}项) (5/10)"
    PHASE4_SCORE=$((PHASE4_SCORE + 5))
else
    echo "  ❌ 缺乏安全检查 (0/10)"
fi

# 4.2 Red Lines 明确性 (10分)
RED_LINES=$(grep -cE "严禁|禁止|never|NEVER|必须不" "$SKILL_FILE" || true)
if [[ $RED_LINES -ge 5 ]]; then
    echo "  ✅ Red Lines 明确 (${RED_LINES}条) (10/10)"
    PHASE4_SCORE=$((PHASE4_SCORE + 10))
elif [[ $RED_LINES -ge 2 ]]; then
    echo "  ⚠️  Red Lines 部分 (${RED_LINES}条) (5/10)"
    PHASE4_SCORE=$((PHASE4_SCORE + 5))
else
    echo "  ❌ 缺乏 Red Lines (0/10)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ═══════════════════════════════════════════════════════
# 计算总分
# ═══════════════════════════════════════════════════════
TOTAL_SCORE=$((PHASE1_SCORE + PHASE2_SCORE + PHASE3_SCORE + PHASE4_SCORE))

echo "  【得分汇总】"
echo "  Phase 1 (静态文本): ${PHASE1_SCORE}/20"
echo "  Phase 2 (运行时执行): ${PHASE2_SCORE}/30"
echo "  Phase 3 (效果验证): ${PHASE3_SCORE}/30"
echo "  Phase 4 (价值产出): ${PHASE4_SCORE}/20"
echo ""
echo "  ═════════════════════════════════════════"
echo "  总分: ${TOTAL_SCORE}/100"
echo "  ═════════════════════════════════════════"

# 评级
if [[ $TOTAL_SCORE -ge 90 ]]; then
    echo "  评级: ★★★ EXEMPLARY (实际效果优秀)"
elif [[ $TOTAL_SCORE -ge 75 ]]; then
    echo "  评级: ★★  GOOD (实际效果良好)"
elif [[ $TOTAL_SCORE -ge 60 ]]; then
    echo "  评级: ★   ACCEPTABLE (实际效果一般)"
else
    echo "  评级: ❌ NEEDS WORK (实际效果不足)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
