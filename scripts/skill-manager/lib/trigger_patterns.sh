#!/usr/bin/env bash
# trigger_patterns.sh — 统一触发词匹配引擎
# 版本: 1.1.0 (Bash 3.2 兼容版)
# 解决: 触发词匹配不一致问题
# 新增: 模式级触发词匹配 (MODE_TRIGGER_* 系列)
#
# 用法: source trigger_patterns.sh

# 不使用 nounset 以避免关联数组问题
set -eo pipefail

# ═══════════════════════════════════════════════════════════════════════════════
# 标准化模式库 (所有评分脚本必须使用此库)
# ═══════════════════════════════════════════════════════════════════════════════
# 使用简单的变量前缀来组织模式

# Identity sections (§1.1)
PATTERN_IDENTITY='§1\.1|1\.1 Identity|## 1\.1|### Identity|## § 1 · Identity'

# Framework sections (§1.2)
PATTERN_FRAMEWORK='§1\.2|1\.2 Framework|## 1\.2|### Framework|## § 2 ·'

# Thinking/Constraints sections (§1.3)
PATTERN_THINKING='§1\.3|1\.3 Thinking|## 1\.3|### Thinking|## § 3 ·'

# System prompt header
PATTERN_SYSTEM_PROMPT='system prompt|§ 1\b|## §'

# Workflow patterns
PATTERN_WORKFLOW='workflow|## Workflow|## Phase|Step [0-9]'
PATTERN_DONE='done\.criteria|done:|✅'
PATTERN_FAIL='fail\.criteria|fail:|❌'

# Error handling
PATTERN_ERROR='error\.handling|edge case|anti\.pattern|risk|failure|recovery'

# Examples
PATTERN_EXAMPLES='^## .*[Ee]xample|^### .*[Ee]xample'

# Metadata
PATTERN_METADATA='^name:|^description:|^license:|^version:|^metadata:'

# ═══════════════════════════════════════════════════════════════════════════════
# 模式级触发词匹配 (v1.1.0 新增)
# 用于检测 SKILL.md §2 Triggers 部分是否覆盖了所有必要的操作模式
# ═══════════════════════════════════════════════════════════════════════════════

# CREATE 模式触发词 — 检查 §2 Triggers 是否包含足够的 CREATE 关键词
# 至少需要包含 4 个以上的创建动词
MODE_TRIGGER_CREATE='create|write|build|make|develop|generate|design|initiate|setup|prepare|scaffold|bootstrap|draft'

# EVALUATE 模式触发词 — 检查是否包含足够的评估关键词
# 至少需要包含 4 个以上的评估动词
MODE_TRIGGER_EVALUATE='evaluate|score|assess|certify|validate|benchmark|audit|test|review|check'

# RESTORE 模式触发词 — 检查是否包含足够的修复关键词
MODE_TRIGGER_RESTORE='restore|fix|repair|recover|rollback|heal|rebuild|patch|upgrade|reset'

# TUNE 模式触发词 — 检查是否包含足够的优化关键词
MODE_TRIGGER_TUNE='tune|optimize|autotune|enhance|boost|refine|sharpen|streamline|polish|self-optimize|自优化|调优'

# SECURITY 模式触发词
MODE_TRIGGER_SECURITY='security|OWASP|vulnerability|CWE|CVE|pentest|hardening|injection'

# 中文触发词覆盖 — 检查是否包含中文触发词
MODE_TRIGGER_ZH='创建技能|新建技能|评估技能|测试技能|优化技能|自优化|调优|修复技能|恢复技能'

# 触发词覆盖质量门槛
TRIGGER_MIN_CREATE=6       # CREATE 模式最少需要的关键词数
TRIGGER_MIN_EVALUATE=5     # EVALUATE 模式最少需要的关键词数
TRIGGER_MIN_RESTORE=5      # RESTORE 模式最少需要的关键词数
TRIGGER_MIN_TUNE=5         # TUNE 模式最少需要的关键词数
TRIGGER_MIN_ZH=3           # 中文触发词最少需要的数量

# ═══════════════════════════════════════════════════════════════════════════════
# 核心函数
# ═══════════════════════════════════════════════════════════════════════════════

# 获取匹配数 (安全版本，错误时返回0)
# 用法: count=$(get_match_count "$pattern" "$file")
get_match_count() {
    local pattern="$1"
    local file="$2"
    grep -cE "$pattern" "$file" 2>/dev/null || echo "0"
}

# 检查模式是否存在
# 用法: if has_pattern "$PATTERN_IDENTITY" "$file"; then ...
has_pattern() {
    local pattern="$1"
    local file="$2"
    local threshold="${3:-1}"
    local count
    count=$(get_match_count "$pattern" "$file")
    [ "$count" -ge "$threshold" ] 2>/dev/null
}

# 诊断触发词匹配情况
# 用法: diagnose_triggers "$skill_file"
diagnose_triggers() {
    local file="$1"
    echo "=== Trigger Diagnosis for: $file ==="
    echo "  IDENTITY:        $(get_match_count "$PATTERN_IDENTITY" "$file") matches"
    echo "  FRAMEWORK:       $(get_match_count "$PATTERN_FRAMEWORK" "$file") matches"
    echo "  THINKING:        $(get_match_count "$PATTERN_THINKING" "$file") matches"
    echo "  SYSTEM_PROMPT:   $(get_match_count "$PATTERN_SYSTEM_PROMPT" "$file") matches"
    echo "  WORKFLOW:        $(get_match_count "$PATTERN_WORKFLOW" "$file") matches"
    echo "  DONE:            $(get_match_count "$PATTERN_DONE" "$file") matches"
    echo "  FAIL:            $(get_match_count "$PATTERN_FAIL" "$file") matches"
    echo "  ERROR:           $(get_match_count "$PATTERN_ERROR" "$file") matches"
    echo "  EXAMPLES:        $(get_match_count "$PATTERN_EXAMPLES" "$file") matches"
    echo "  METADATA:        $(get_match_count "$PATTERN_METADATA" "$file") matches"
}

# 获取最低分维度名称
# 用法: weakest_dim=$(get_weakest_dimension "$score_output")
get_weakest_dimension() {
    local score_output="$1"
    echo "$score_output" | grep -E "^  [A-Za-z]" | \
        while read line; do
            echo "$line" | awk '{print $1}'
        done | \
        sort -t'/' -k1 -n | head -1
}

# ═══════════════════════════════════════════════════════════════════════════════
# 模式级触发词覆盖检测函数
# ═══════════════════════════════════════════════════════════════════════════════

# 检测 §2 Triggers 部分的触发词覆盖质量
# 用法: check_trigger_coverage "$skill_file"
# 返回: 0=通过, 1=触发词不足
check_trigger_coverage() {
    local file="$1"
    local all_pass=true

    for mode_var in CREATE EVALUATE RESTORE TUNE; do
        local pattern_var="MODE_TRIGGER_${mode_var}"
        local min_var="TRIGGER_MIN_${mode_var}"
        local pattern="${!pattern_var}"
        local min_count="${!min_var}"

        # Count how many trigger keywords from the pattern appear in the §2 section
        local section
        section=$(awk '/^## §2/,/^## §[3-9]/' "$file" 2>/dev/null || true)
        local found=0

        IFS='|' read -ra keywords <<< "$pattern"
        for kw in "${keywords[@]}"; do
            if echo "$section" | grep -qi "$kw" 2>/dev/null; then
                found=$((found + 1))
            fi
        done

        if [[ $found -lt $min_count ]]; then
            echo "  ⚠ ${mode_var} mode: only ${found}/${min_count} required trigger keywords found"
            all_pass=false
        fi
    done

    # Check Chinese triggers
    local zh_section
    zh_section=$(awk '/^## §2/,/^## §[3-9]/' "$file" 2>/dev/null || true)
    local zh_found=0
    IFS='|' read -ra zh_keywords <<< "$MODE_TRIGGER_ZH"
    for kw in "${zh_keywords[@]}"; do
        if echo "$zh_section" | grep -qF "$kw" 2>/dev/null; then
            zh_found=$((zh_found + 1))
        fi
    done

    if [[ $zh_found -lt $TRIGGER_MIN_ZH ]]; then
        echo "  ⚠ Chinese triggers: only ${zh_found}/${TRIGGER_MIN_ZH} required ZH keywords found"
        all_pass=false
    fi

    if $all_pass; then
        return 0
    else
        return 1
    fi
}

# 导出模式变量供其他脚本使用
export PATTERN_IDENTITY PATTERN_FRAMEWORK PATTERN_THINKING
export PATTERN_SYSTEM_PROMPT PATTERN_WORKFLOW PATTERN_DONE PATTERN_FAIL
export PATTERN_ERROR PATTERN_EXAMPLES PATTERN_METADATA
export MODE_TRIGGER_CREATE MODE_TRIGGER_EVALUATE MODE_TRIGGER_RESTORE
export MODE_TRIGGER_TUNE MODE_TRIGGER_SECURITY MODE_TRIGGER_ZH
export TRIGGER_MIN_CREATE TRIGGER_MIN_EVALUATE TRIGGER_MIN_RESTORE
export TRIGGER_MIN_TUNE TRIGGER_MIN_ZH
