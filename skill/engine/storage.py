"""Storage module for usage log operations."""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path
from typing import Any

if sys.platform == "win32":
    import msvcrt
else:
    import fcntl


USAGE_LOG = os.environ.get("USAGE_LOG", "/tmp/usage.jsonl")

EVOLUTION_THRESHOLD_NEW = 10
EVOLUTION_THRESHOLD_GROWING = 5
EVOLUTION_THRESHOLD_STABLE = 2


def get_timestamp() -> str:
    """Get current timestamp."""
    from datetime import datetime

    return datetime.now().strftime("%Y%m%d_%H%M%S")


def ensure_directory(path: str) -> None:
    """Ensure directory exists."""
    Path(path).mkdir(parents=True, exist_ok=True)


def _iter_skill_entries(skill_name: str) -> list[dict[str, Any]]:
    """Return all parsed log entries matching *skill_name*.

    Uses JSON parsing (not string matching) so entries with extra whitespace or
    different key ordering are handled correctly.
    """
    if not Path(USAGE_LOG).exists():
        return []

    entries: list[dict[str, Any]] = []
    with open(USAGE_LOG) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                entry = json.loads(line)
                if entry.get("skill_name") == skill_name:
                    entries.append(entry)
            except json.JSONDecodeError:
                continue
    return entries


def storage_get_eval_count(skill_name: str) -> int:
    """Get count of evaluations for a skill."""
    return len(_iter_skill_entries(skill_name))


def storage_get_last_score(skill_name: str) -> float:
    """Get last score for a skill."""
    entries = _iter_skill_entries(skill_name)
    if not entries:
        return 0
    return entries[-1].get("score", 0)


def storage_get_all_scores(skill_name: str) -> list[dict[str, Any]]:
    """Get all score entries for a skill."""
    return _iter_skill_entries(skill_name)


def storage_log_usage(
    skill_name: str,
    score: float,
    tier: str,
    iterations: int,
) -> None:
    """Log usage entry with an exclusive file lock to prevent data races."""
    ensure_directory(str(Path(USAGE_LOG).parent))
    entry = {
        "timestamp": get_timestamp(),
        "skill_name": skill_name,
        "score": score,
        "tier": tier,
        "iterations": iterations,
    }
    with open(USAGE_LOG, "a") as f:
        if sys.platform == "win32":
            msvcrt.locking(f.fileno(), msvcrt.LK_LOCK, 1)
            try:
                f.write(json.dumps(entry) + "\n")
            finally:
                msvcrt.locking(f.fileno(), msvcrt.LK_UNLCK, 1)
        else:
            fcntl.flock(f, fcntl.LOCK_EX)
            try:
                f.write(json.dumps(entry) + "\n")
            finally:
                fcntl.flock(f, fcntl.LOCK_UN)


def storage_calculate_threshold(eval_count: int) -> int:
    """Calculate threshold based on evaluation count."""
    if eval_count < 10:
        return EVOLUTION_THRESHOLD_NEW
    elif eval_count < 50:
        return EVOLUTION_THRESHOLD_GROWING
    return EVOLUTION_THRESHOLD_STABLE
