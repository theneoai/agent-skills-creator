#!/usr/bin/env bash
# trigger_patterns.sh — 统一触发词匹配引擎
# 版本: 1.0.0 (Bash 3.2 兼容版)
# 解决: 触发词匹配不一致问题
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

# 导出模式变量供其他脚本使用
export PATTERN_IDENTITY PATTERN_FRAMEWORK PATTERN_THINKING
export PATTERN_SYSTEM_PROMPT PATTERN_WORKFLOW PATTERN_DONE PATTERN_FAIL
export PATTERN_ERROR PATTERN_EXAMPLES PATTERN_METADATA
