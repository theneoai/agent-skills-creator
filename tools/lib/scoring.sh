#!/usr/bin/env bash
# UNIFIED_SCORING.md - 统一评分系统
#
# 所有评分系统必须使用此常量文件确保一致性
#
# 评分系统: 1000分制 (兼容1155分实际得分)
#
# ============================================================================
# 评分维度 (与 eval/main.sh 保持一致)
# ============================================================================

# Phase 1: Parse & Validate
readonly PARSE_MAX=100

# Phase 2: Text Score  
readonly TEXT_MAX=505

# Phase 3: Runtime Score
readonly RUNTIME_MAX=450

# Phase 4: Certification
readonly CERTIFY_MAX=100

# 总分 (实际)
readonly TOTAL_ACTUAL_MAX=1155

# 显示总分 (归一化到1000)
readonly TOTAL_DISPLAY_MAX=1000

# ============================================================================
# 等级阈值 (1000分制)
# ============================================================================

readonly TIER_PLATINUM=950
readonly TIER_GOLD=900
readonly TIER_SILVER=800
readonly TIER_BRONZE=700

# ============================================================================
# 向后兼容: lean-orchestrator.sh 使用
# ============================================================================

# lean-orchestrator 600分制 -> 1000分制转换系数
readonly LEAN_TO_STANDARD=1.667  # 600 * 1.667 ≈ 1000

# lean-orchestrator 等级阈值 (600分制)
readonly LEAN_TIER_GOLD=570
readonly LEAN_TIER_SILVER=510
readonly LEAN_TIER_BRONZE=420

# lean-orchestrator 等级阈值 (转换到1000分制后用于比较)
readonly LEAN_TIER_PLATINUM=950    # 570 * 1.667 ≈ 950 (matches 1000-point PLATINUM)
readonly LEAN_TIER_GOLD_NORM=950   # 570 * 1.667 ≈ 950
readonly LEAN_TIER_SILVER_NORM=850 # 510 * 1.667 ≈ 850
readonly LEAN_TIER_BRONZE_NORM=700 # 420 * 1.667 ≈ 700

# ============================================================================
# 导出
# ============================================================================

export PARSE_MAX TEXT_MAX RUNTIME_MAX CERTIFY_MAX
export TOTAL_ACTUAL_MAX TOTAL_DISPLAY_MAX
export TIER_PLATINUM TIER_GOLD TIER_SILVER TIER_BRONZE
export LEAN_TO_STANDARD LEAN_TIER_GOLD LEAN_TIER_SILVER LEAN_TIER_BRONZE
export LEAN_TIER_PLATINUM LEAN_TIER_GOLD_NORM LEAN_TIER_SILVER_NORM LEAN_TIER_BRONZE_NORM
