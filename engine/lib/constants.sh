#!/usr/bin/env bash
# constants.sh - 配置常量
#
# 注意: 路径已在 bootstrap.sh 中初始化
# 此文件只包含业务配置常量

# ============================================================================
# 进化阈值配置
# ============================================================================

EVOLUTION_THRESHOLD_NEW=10
EVOLUTION_THRESHOLD_GROWING=50
EVOLUTION_THRESHOLD_STABLE=100

# ============================================================================
# Agent 超时配置（秒）
# ============================================================================

CREATOR_TIMEOUT=60
EVALUATOR_TIMEOUT=30
EVOLUTION_TIMEOUT=120
SKILL_FILE_TIMEOUT=10

# ============================================================================
# LLM 配置
# ============================================================================

DEFAULT_LLM_PROVIDER="${DEFAULT_LLM_PROVIDER:-kimi-code}"
MAX_LLM_RETRIES=3
LLM_TIMEOUT=15

# ============================================================================
# 评估阈值
# ============================================================================

PASSING_SCORE=800
TARGET_TIER="${TARGET_TIER:-BRONZE}"

# ============================================================================
# 快照配置
# ============================================================================

MAX_SNAPSHOTS=10

# ============================================================================
# 错误码
# ============================================================================

ERROR_INVALID_FORMAT=10
ERROR_EVAL_FAILURE=20
ERROR_LLM_TIMEOUT=30
ERROR_LLM_ERROR=31
ERROR_LOCK_FAILED=40
ERROR_SNAPSHOT_ERROR=50

# ============================================================================
# 导出
# ============================================================================

export EVOLUTION_THRESHOLD_NEW EVOLUTION_THRESHOLD_GROWING EVOLUTION_THRESHOLD_STABLE
export CREATOR_TIMEOUT EVALUATOR_TIMEOUT EVOLUTION_TIMEOUT SKILL_FILE_TIMEOUT
export DEFAULT_LLM_PROVIDER MAX_LLM_RETRIES LLM_TIMEOUT
export PASSING_SCORE TARGET_TIER
export MAX_SNAPSHOTS
export ERROR_INVALID_FORMAT ERROR_EVAL_FAILURE ERROR_LLM_TIMEOUT ERROR_LLM_ERROR ERROR_LOCK_FAILED ERROR_SNAPSHOT_ERROR