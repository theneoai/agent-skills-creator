"""ROAD (Retrospective Optimization with Agentic Decisions) error recovery."""

from __future__ import annotations

from collections import defaultdict
from dataclasses import dataclass, field
from enum import Enum
from typing import Any


class DecisionType(Enum):
    RETRY = "retry"
    ROLLBACK = "rollback"
    ESCALATE = "escalate"
    ABORT = "abort"
    FALLBACK = "fallback"


@dataclass
class FailureLog:
    error_type: str
    error_message: str
    context: dict[str, Any]
    timestamp: float
    recovered: bool = False


@dataclass
class DecisionTreeNode:
    condition: str
    decision: DecisionType
    children: list[DecisionTreeNode] = field(default_factory=list)
    visit_count: int = 0
    success_rate: float = 0.0


class ROADRecover:
    def __init__(self) -> None:
        self._failure_logs: list[FailureLog] = []
        self._decision_tree: dict[str, DecisionTreeNode] = {}
        self._error_stats: dict[str, dict[DecisionType, tuple[int, int]]] = defaultdict(
            lambda: {decision: (0, 0) for decision in DecisionType}
        )

    def log_failure(self, log: FailureLog) -> None:
        self._failure_logs.append(log)
        if log.error_type not in self._decision_tree:
            self._decision_tree[log.error_type] = DecisionTreeNode(
                condition=f"error_type == '{log.error_type}'",
                decision=self._suggest_decision(log.error_type, log.context),
            )

    def build_decision_tree(self) -> DecisionTreeNode:
        if not self._decision_tree:
            return DecisionTreeNode(
                condition="default",
                decision=DecisionType.RETRY,
            )
        root_conditions = list(self._decision_tree.keys())
        if len(root_conditions) == 1:
            return self._decision_tree[root_conditions[0]]
        return DecisionTreeNode(
            condition=" OR ".join(f"error_type == '{c}'" for c in root_conditions),
            decision=DecisionType.ESCALATE,
            children=list(self._decision_tree.values()),
        )

    def suggest_recovery(self, error_type: str, context: dict[str, Any]) -> DecisionType:
        if error_type in self._decision_tree:
            node = self._decision_tree[error_type]
            node.visit_count += 1
            return node.decision
        return self._suggest_decision(error_type, context)

    def update_tree(self, error_type: str, decision: DecisionType, success: bool) -> None:
        if error_type not in self._decision_tree:
            self._decision_tree[error_type] = DecisionTreeNode(
                condition=f"error_type == '{error_type}'",
                decision=decision,
            )
        node = self._decision_tree[error_type]
        node.visit_count += 1
        node.decision = decision
        successes, failures = self._error_stats[error_type][decision]
        if success:
            successes += 1
        else:
            failures += 1
        total = successes + failures
        node.success_rate = successes / total if total > 0 else 0.0
        self._error_stats[error_type][decision] = (successes, failures)

    def get_failure_patterns(self) -> list[str]:
        return list(set(log.error_type for log in self._failure_logs))

    def _suggest_decision(self, error_type: str, context: dict[str, Any]) -> DecisionType:
        if "retry_count" in context and context["retry_count"] > 2:
            return DecisionType.ROLLBACK
        if error_type in ("TimeoutError", "ConnectionError"):
            return DecisionType.RETRY
        if error_type in ("PermissionError", "AuthenticationError"):
            return DecisionType.ESCALATE
        if error_type in ("ValueError", "TypeError"):
            return DecisionType.ABORT
        return DecisionType.RETRY
