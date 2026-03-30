from __future__ import annotations
from dataclasses import dataclass, field
from typing import Any
import time


@dataclass
class MemoryEntry:
    timestamp: float
    task_type: str
    trajectory: list[dict[str, Any]]
    outcome: str
    reward: float
    lessons: list[str] = field(default_factory=list)


class EvolutionMemory:
    def __init__(self) -> None:
        self._entries: list[MemoryEntry] = []

    def add(self, entry: MemoryEntry) -> None:
        self._entries.append(entry)

    def get_successful_trajectories(self, task_type: str) -> list[list[dict[str, Any]]]:
        return [
            e.trajectory
            for e in self._entries
            if e.task_type == task_type and e.outcome == "success"
        ]

    def get_similar(self, task_type: str, k: int = 5) -> list[MemoryEntry]:
        return [e for e in self._entries if e.task_type == task_type][:k]
