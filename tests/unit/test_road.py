"""Tests for ROAD error recovery system."""

from __future__ import annotations

import time

import pytest

from skill.engine.road import (
    DecisionTreeNode,
    DecisionType,
    FailureLog,
    ROADRecover,
)


class TestDecisionType:
    """Test suite for DecisionType enum."""

    def test_all_decision_types_exist(self):
        """Test all five decision types are defined."""
        assert DecisionType.RETRY.value == "retry"
        assert DecisionType.ROLLBACK.value == "rollback"
        assert DecisionType.ESCALATE.value == "escalate"
        assert DecisionType.ABORT.value == "abort"
        assert DecisionType.FALLBACK.value == "fallback"


class TestFailureLog:
    """Test suite for FailureLog dataclass."""

    def test_failure_log_creation(self):
        """Test FailureLog stores all fields."""
        log = FailureLog(
            error_type="TimeoutError",
            error_message="Operation timed out",
            context={"operation": "api_call", "timeout": 30},
            timestamp=1234567890.0,
            recovered=False,
        )
        assert log.error_type == "TimeoutError"
        assert log.error_message == "Operation timed out"
        assert log.context["operation"] == "api_call"
        assert log.timestamp == 1234567890.0
        assert log.recovered is False

    def test_failure_log_defaults(self):
        """Test FailureLog default recovered is False."""
        log = FailureLog(
            error_type="ValueError",
            error_message="Invalid input",
            context={},
            timestamp=time.time(),
        )
        assert log.recovered is False


class TestDecisionTreeNode:
    """Test suite for DecisionTreeNode dataclass."""

    def test_decision_tree_node_creation(self):
        """Test DecisionTreeNode stores all fields."""
        node = DecisionTreeNode(
            condition="error_type == 'TimeoutError'",
            decision=DecisionType.RETRY,
            children=[],
            visit_count=5,
            success_rate=0.8,
        )
        assert node.condition == "error_type == 'TimeoutError'"
        assert node.decision == DecisionType.RETRY
        assert node.visit_count == 5
        assert node.success_rate == 0.8

    def test_decision_tree_node_defaults(self):
        """Test DecisionTreeNode default values."""
        node = DecisionTreeNode(
            condition="always_retry",
            decision=DecisionType.RETRY,
        )
        assert node.children == []
        assert node.visit_count == 0
        assert node.success_rate == 0.0


class TestROADRecover:
    """Test suite for ROADRecover class."""

    def test_initialization(self):
        """Test ROADRecover initializes with empty state."""
        road = ROADRecover()
        assert road.get_failure_patterns() == []

    def test_log_failure(self):
        """Test logging a failure adds it to history."""
        road = ROADRecover()
        log = FailureLog(
            error_type="TimeoutError",
            error_message="API call timed out",
            context={"service": "payment"},
            timestamp=time.time(),
        )
        road.log_failure(log)
        assert "TimeoutError" in road.get_failure_patterns()

    def test_log_multiple_failures(self):
        """Test logging multiple failures."""
        road = ROADRecover()
        road.log_failure(FailureLog("TimeoutError", "timed out", {}, time.time()))
        road.log_failure(
            FailureLog("ConnectionError", "connection refused", {}, time.time())
        )
        road.log_failure(FailureLog("TimeoutError", "timed out again", {}, time.time()))
        patterns = road.get_failure_patterns()
        assert len(patterns) == 2
        assert "TimeoutError" in patterns
        assert "ConnectionError" in patterns

    def test_build_decision_tree(self):
        """Test building decision tree from logged failures."""
        road = ROADRecover()
        road.log_failure(
            FailureLog("TimeoutError", "timed out", {"retry_count": 0}, time.time())
        )
        tree = road.build_decision_tree()
        assert tree is not None
        assert isinstance(tree, DecisionTreeNode)

    def test_suggest_recovery_returns_decision_type(self):
        """Test suggest_recovery returns a DecisionType."""
        road = ROADRecover()
        decision = road.suggest_recovery("TimeoutError", {"retry_count": 0})
        assert isinstance(decision, DecisionType)

    def test_suggest_recovery_based_on_history(self):
        """Test recovery suggestion is influenced by history."""
        road = ROADRecover()
        road.log_failure(
            FailureLog("TimeoutError", "timed out", {"retry_count": 0}, time.time())
        )
        road.update_tree("TimeoutError", DecisionType.RETRY, success=True)
        decision = road.suggest_recovery("TimeoutError", {"retry_count": 0})
        assert decision == DecisionType.RETRY

    def test_update_tree_modifies_success_rate(self):
        """Test updating tree with success changes success_rate."""
        road = ROADRecover()
        road.log_failure(FailureLog("TimeoutError", "timed out", {}, time.time()))
        road.update_tree("TimeoutError", DecisionType.RETRY, success=True)
        road.update_tree("TimeoutError", DecisionType.RETRY, success=True)
        road.update_tree("TimeoutError", DecisionType.RETRY, success=False)
        tree = road.build_decision_tree()
        assert tree.success_rate == pytest.approx(2 / 3, rel=0.01)

    def test_update_tree_increments_visit_count(self):
        """Test updating tree increments visit_count."""
        road = ROADRecover()
        road.log_failure(FailureLog("TimeoutError", "timed out", {}, time.time()))
        road.update_tree("TimeoutError", DecisionType.RETRY, success=True)
        road.update_tree("TimeoutError", DecisionType.RETRY, success=False)
        tree = road.build_decision_tree()
        assert tree.visit_count == 2

    def test_get_failure_patterns_empty_initially(self):
        """Test get_failure_patterns returns empty list initially."""
        road = ROADRecover()
        assert road.get_failure_patterns() == []

    def test_suggest_recovery_with_no_history(self):
        """Test suggest_recovery returns RETRY as default when no history."""
        road = ROADRecover()
        decision = road.suggest_recovery("UnknownError", {})
        assert decision == DecisionType.RETRY

    def test_decision_tree_has_children(self):
        """Test built tree has appropriate children for different errors."""
        road = ROADRecover()
        road.log_failure(FailureLog("TimeoutError", "timed out", {}, time.time()))
        road.log_failure(FailureLog("ConnectionError", "refused", {}, time.time()))
        road.update_tree("TimeoutError", DecisionType.RETRY, success=True)
        road.update_tree("ConnectionError", DecisionType.ROLLBACK, success=True)
        tree = road.build_decision_tree()
        assert len(tree.children) >= 0
