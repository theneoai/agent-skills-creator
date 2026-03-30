"""Trigger-based intent detection module."""

from __future__ import annotations

import json
import math
import os
import re
from pathlib import Path


TRIGGER_VERSION = "1.1"

_WEIGHT_FILE = os.environ.get(
    "SKILL_TRIGGERS_WEIGHTS", str(Path.home() / ".skill" / "trigger_weights.json")
)

_LEARNED_WEIGHTS: dict[str, dict[str, float]] = {}

_MODE_PATTERNS: dict[str, list[tuple[str, float]]] = {
    "CREATE": [
        (r"create.*skill|build.*skill|make.*skill", 3.0),
        (r"new.*skill|develop.*skill|add.*skill", 2.0),
        (r"generate.*skill|scaffold.*skill", 1.0),
        (r"创建|新建", 3.0),
        (r"开发|制作|生成", 2.0),
        (r"脚手架", 1.0),
    ],
    "EVALUATE": [
        (r"evaluate.*skill|test.*skill|score.*skill", 3.0),
        (r"review.*skill|assess.*skill|check.*skill", 2.0),
        (r"validate.*skill|benchmark.*skill", 1.0),
        (r"评估|测试|打分", 3.0),
        (r"审查|验证|检查", 2.0),
        (r"评分|基准", 1.0),
    ],
    "RESTORE": [
        (r"restore.*skill|fix.*skill|repair.*skill", 3.0),
        (r"recover.*skill|undo|rollback.*skill", 2.0),
        (r"broken.*skill|corrupt.*skill", 1.0),
        (r"恢复|修复|还原", 3.0),
        (r"补救|撤销|回滚", 2.0),
        (r"损坏|失效|破坏", 1.0),
    ],
    "SECURITY": [
        (r"security audit|owasp|vulnerability", 3.0),
        (r"cwe|security check|penetration test", 2.0),
        (r"security scan|exploit check", 1.0),
        (r"安全审计|漏洞扫描|owasp", 3.0),
        (r"安全检查|渗透测试", 2.0),
        (r"入侵|攻击", 1.0),
    ],
    "OPTIMIZE": [
        (r"optimize.*skill|improve.*skill|evolve.*skill", 3.0),
        (r"enhance.*skill|tune.*skill|refine.*skill", 2.0),
        (r"upgrade.*skill|performance", 1.0),
        (r"优化|改进|进化", 3.0),
        (r"提升|调优|完善", 2.0),
        (r"增强|性能", 1.0),
    ],
}

_SECONDARY_PATTERNS: dict[str, list[tuple[str, float]]] = {
    "CREATE": [
        (r'"generate"|"template"|"starter"|"boilerplate"', 1.0),
        (r"模板|起始框架|脚手架", 1.0),
    ],
    "EVALUATE": [
        (r'"compare"|"grade"|"rate"|"measure"', 1.0),
        (r"比较|评级|打分", 1.0),
    ],
    "RESTORE": [
        (r'"broken"|"corrupt"|"invalid"|"damage"', 1.0),
        (r"损坏|破坏|崩溃", 1.0),
    ],
    "SECURITY": [
        (r'"injection"|"xss"|"csrf"|"breach"', 1.0),
        (r"注入|跨站|攻击", 1.0),
    ],
    "OPTIMIZE": [
        (r'"speed"|"efficiency"|"refactor"|"dry"', 1.0),
        (r"速度|效率|重构", 1.0),
    ],
}

_NEGATIVE_PATTERNS: dict[str, list[str]] = {
    "CREATE": [
        r"don\'t create|skill exists|check if exists",
        r"不要创建|技能已存在",
    ],
    "EVALUATE": [
        r"evaluate code|test function|lint",
        r"评估代码|测试函数",
    ],
    "RESTORE": [
        r"restore file|recover data",
        r"恢复文件|恢复数据",
    ],
    "SECURITY": [
        r"secure password|encrypt data",
        r"加密密码|保护数据",
    ],
    "OPTIMIZE": [
        r"optimize algorithm|speed up",
        r"优化算法|加速",
    ],
}


def _load_weights() -> dict[str, dict[str, float]]:
    """Load learned weights from file."""
    global _LEARNED_WEIGHTS
    if _LEARNED_WEIGHTS:
        return _LEARNED_WEIGHTS
    if os.path.exists(_WEIGHT_FILE):
        try:
            with open(_WEIGHT_FILE) as f:
                _LEARNED_WEIGHTS = json.load(f)
        except (json.JSONDecodeError, IOError):
            _LEARNED_WEIGHTS = {}
    return _LEARNED_WEIGHTS


def _save_weights() -> None:
    """Save learned weights to file."""
    os.makedirs(os.path.dirname(_WEIGHT_FILE), exist_ok=True)
    with open(_WEIGHT_FILE, "w") as f:
        json.dump(_LEARNED_WEIGHTS, f)


def record_feedback(mode: str, pattern_key: str, success: bool) -> None:
    """Record feedback for a pattern to enable weight learning.

    Args:
        mode: Intent mode (CREATE/EVALUATE/RESTORE/SECURITY/OPTIMIZE)
        pattern_key: Unique key identifying the pattern used
        success: Whether the intent detection was correct
    """
    weights = _load_weights()
    if mode not in weights:
        weights[mode] = {}
    current = weights[mode].get(pattern_key, 1.0)
    delta = 0.1 if success else -0.1
    weights[mode][pattern_key] = max(0.1, min(5.0, current + delta))
    global _LEARNED_WEIGHTS
    _LEARNED_WEIGHTS = weights
    _save_weights()


def get_learned_weight(mode: str, pattern_key: str) -> float:
    """Get learned weight for a pattern, returns 1.0 if no learning recorded."""
    weights = _load_weights()
    return weights.get(mode, {}).get(pattern_key, 1.0)


def clear_weights() -> None:
    """Clear all learned weights."""
    global _LEARNED_WEIGHTS
    _LEARNED_WEIGHTS = {}
    if os.path.exists(_WEIGHT_FILE):
        os.remove(_WEIGHT_FILE)


def detect_language(input_text: str) -> str:
    """Detect language of input text.

    Returns: ZH for Chinese-only, EN for English-only, MIXED for both
    """
    has_zh = len(re.findall(r"[一-龥]", input_text))
    has_en = len(re.findall(r"[a-zA-Z]", input_text))

    if has_zh > 0 and has_en == 0:
        return "ZH"
    elif has_en > 0 and has_zh == 0:
        return "EN"
    else:
        return "MIXED"


def score_primary_keywords(input_text: str, lang: str, mode: str) -> float:
    """Score primary keywords for intent detection with learned weights.

    Args:
        input_text: User input
        lang: Detected language (EN/ZH/MIXED)
        mode: Intent mode (CREATE/EVALUATE/RESTORE/SECURITY/OPTIMIZE)

    Returns:
        Score based on keyword matches (weighted by learned history)
    """
    input_lower = input_text.lower()

    patterns = _MODE_PATTERNS.get(mode, [])
    for pattern, base_weight in patterns:
        if re.search(pattern, input_lower):
            pattern_key = f"primary:{pattern}"
            return get_learned_weight(mode, pattern_key) * base_weight

    return 0.0


def score_secondary_keywords(input_text: str, lang: str, mode: str) -> float:
    """Score secondary/context keywords for intent detection with learned weights."""
    input_lower = input_text.lower()
    score = 0.0

    patterns = _SECONDARY_PATTERNS.get(mode, [])
    for pattern, base_weight in patterns:
        if re.search(pattern, input_lower):
            pattern_key = f"secondary:{pattern}"
            weight = get_learned_weight(mode, pattern_key) * base_weight
            score += weight

    return score


def check_negative_patterns(input_text: str, lang: str, mode: str) -> int:
    """Check for negative patterns that should filter out a mode.

    Returns:
        1 if negative pattern found, 0 otherwise
    """
    input_lower = input_text.lower()
    patterns = _NEGATIVE_PATTERNS.get(mode, [])
    for pattern in patterns:
        if re.search(pattern, input_lower):
            return 1
    return 0


def calculate_confidence(
    primary: float, secondary: float, context: float, no_negative: float
) -> float:
    """Calculate confidence score based on components.

    Formula: primary * 0.5 + secondary * 0.2 + context * 0.2 + no_negative * 0.1
    """
    return primary * 0.5 + secondary * 0.2 + context * 0.2 + no_negative * 0.1


def detect_intent(input_text: str) -> str:
    """Detect intent mode from user input.

    Returns:
        String in format "MODE:confidence" or "ASK:MODE:confidence"
    """
    if not input_text:
        return "EVALUATE:0.30"

    lang = detect_language(input_text)

    modes = ["CREATE", "EVALUATE", "RESTORE", "SECURITY", "OPTIMIZE"]
    best_mode = "EVALUATE"
    best_score = 0.0
    best_confidence = 0.30

    for mode in modes:
        primary = score_primary_keywords(input_text, lang, mode)
        secondary = score_secondary_keywords(input_text, lang, mode)
        context = score_secondary_keywords(input_text, lang, mode)
        negative = check_negative_patterns(input_text, lang, mode)

        if negative == 1:
            confidence = 0.00
        else:
            no_negative_weight = 1.0
            confidence = calculate_confidence(primary, secondary, context, no_negative_weight)

        current_score = confidence * 10 + primary
        if current_score > best_score:
            best_mode = mode
            best_score = current_score
            best_confidence = confidence

    if best_confidence >= 0.80:
        return f"{best_mode}:{best_confidence}"

    if best_confidence >= 0.60:
        return f"{best_mode}:{best_confidence}"

    if best_confidence < 0.60:
        if best_confidence <= 0.30:
            return "EVALUATE:0.30"
        return f"ASK:{best_mode}:{best_confidence}"

    return "EVALUATE:0.30"


def get_detected_mode(result: str) -> str:
    """Extract mode from detect_intent result."""
    return result.split(":")[0]


def get_confidence(result: str) -> str:
    """Extract confidence from detect_intent result."""
    return result.split(":")[-1]


def is_ambiguous(result: str) -> bool:
    """Check if result indicates ambiguous intent."""
    return result.startswith("ASK:")
