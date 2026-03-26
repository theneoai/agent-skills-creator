#!/usr/bin/env bash
# weights.sh — 统一权重体系
# 版本: 1.0.0 (Bash 3.2 兼容版)
# 解决: 不同评分脚本权重不一致问题
#
# 用法: source weights.sh

set -eo pipefail

# ═══════════════════════════════════════════════════════════════════════════════
# V1 权重体系 (score.sh)
# ═══════════════════════════════════════════════════════════════════════════════
WEIGHT_V1_SYSTEM_PROMPT=20
WEIGHT_V1_DOMAIN_KNOWLEDGE=20
WEIGHT_V1_WORKFLOW=20
WEIGHT_V1_ERROR_HANDLING=15
WEIGHT_V1_EXAMPLES=15
WEIGHT_V1_METADATA=10

# ═══════════════════════════════════════════════════════════════════════════════
# V2 权重体系 (score-v2.sh)
# ═══════════════════════════════════════════════════════════════════════════════
WEIGHT_V2_SYSTEM_PROMPT=15
WEIGHT_V2_DOMAIN_KNOWLEDGE=20
WEIGHT_V2_WORKFLOW=20
WEIGHT_V2_CONSISTENCY=15
WEIGHT_V2_EXECUTABILITY=15
WEIGHT_V2_METADATA=15

# ═══════════════════════════════════════════════════════════════════════════════
# 辅助函数
# ═══════════════════════════════════════════════════════════════════════════════

# 验证权重总和 (应为100)
# 用法: validate_weights_v1 && echo "OK"
validate_weights_v1() {
    local total
    total=$(expr $WEIGHT_V1_SYSTEM_PROMPT + $WEIGHT_V1_DOMAIN_KNOWLEDGE + $WEIGHT_V1_WORKFLOW + $WEIGHT_V1_ERROR_HANDLING + $WEIGHT_V1_EXAMPLES + $WEIGHT_V1_METADATA)
    [ "$total" -eq 100 ]
}

validate_weights_v2() {
    local total
    total=$(expr $WEIGHT_V2_SYSTEM_PROMPT + $WEIGHT_V2_DOMAIN_KNOWLEDGE + $WEIGHT_V2_WORKFLOW + $WEIGHT_V2_CONSISTENCY + $WEIGHT_V2_EXECUTABILITY + $WEIGHT_V2_METADATA)
    [ "$total" -eq 100 ]
}

# 获取权重总和
# 用法: total=$(get_weight_sum_v1)
get_weight_sum_v1() {
    expr $WEIGHT_V1_SYSTEM_PROMPT + $WEIGHT_V1_DOMAIN_KNOWLEDGE + $WEIGHT_V1_WORKFLOW + $WEIGHT_V1_ERROR_HANDLING + $WEIGHT_V1_EXAMPLES + $WEIGHT_V1_METADATA
}

get_weight_sum_v2() {
    expr $WEIGHT_V2_SYSTEM_PROMPT + $WEIGHT_V2_DOMAIN_KNOWLEDGE + $WEIGHT_V2_WORKFLOW + $WEIGHT_V2_CONSISTENCY + $WEIGHT_V2_EXECUTABILITY + $WEIGHT_V2_METADATA
}

# 计算加权分数 (使用 Python 保证精度)
# 用法: weighted=$(calculate_weighted_score_v1 8 7 8 7 8 8)
calculate_weighted_score_v1() {
    local sp="$1" dk="$2" wf="$3" eh="$4" ex="$5" md="$6"
    python3 - << PYTHON
sp, dk, wf, eh, ex, md = $sp, $dk, $wf, $eh, $ex, $md
total = sp * 0.20 + dk * 0.20 + wf * 0.20 + eh * 0.15 + ex * 0.15 + md * 0.10
print(f"{total:.2f}")
PYTHON
}

# 导出供其他脚本使用
export WEIGHT_V1_SYSTEM_PROMPT WEIGHT_V1_DOMAIN_KNOWLEDGE WEIGHT_V1_WORKFLOW
export WEIGHT_V1_ERROR_HANDLING WEIGHT_V1_EXAMPLES WEIGHT_V1_METADATA
export WEIGHT_V2_SYSTEM_PROMPT WEIGHT_V2_DOMAIN_KNOWLEDGE WEIGHT_V2_WORKFLOW
export WEIGHT_V2_CONSISTENCY WEIGHT_V2_EXECUTABILITY WEIGHT_V2_METADATA
