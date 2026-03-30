"""Tests for GEPA trajectory-level scoring."""

from __future__ import annotations

import pytest

from skill.eval.gepa import GEPAResult, GEPAScorer


class TestGEPAScorer:
    """Test suite for GEPAScorer."""

    def test_init_without_model(self) -> None:
        """Test scorer initialization without model."""
        scorer = GEPAScorer()
        assert scorer.model is None

    def test_init_with_model(self) -> None:
        """Test scorer initialization with model name."""
        scorer = GEPAScorer(model="gpt-4")
        assert scorer.model == "gpt-4"

    def test_score_trajectory_returns_gepa_result(self) -> None:
        """Test that score_trajectory returns a GEPAResult."""
        scorer = GEPAScorer()
        trajectory = {"steps": [{"action": "test"}], "final_state": {}}
        result = scorer.score_trajectory(trajectory)
        assert isinstance(result, GEPAResult)

    def test_score_trajectory_has_trajectory_score(self) -> None:
        """Test that result contains trajectory_score field."""
        scorer = GEPAScorer()
        trajectory = {"steps": [{"action": "test"}], "final_state": {}}
        result = scorer.score_trajectory(trajectory)
        assert hasattr(result, "trajectory_score")
        assert isinstance(result.trajectory_score, float)

    def test_score_trajectory_has_step_scores(self) -> None:
        """Test that result contains step_scores field."""
        scorer = GEPAScorer()
        trajectory = {"steps": [{"action": "test"}], "final_state": {}}
        result = scorer.score_trajectory(trajectory)
        assert hasattr(result, "step_scores")
        assert isinstance(result.step_scores, list)

    def test_score_trajectory_has_convergence_indicator(self) -> None:
        """Test that result contains convergence_indicator field."""
        scorer = GEPAScorer()
        trajectory = {"steps": [{"action": "test"}], "final_state": {}}
        result = scorer.score_trajectory(trajectory)
        assert hasattr(result, "convergence_indicator")
        assert isinstance(result.convergence_indicator, float)

    def test_score_trajectory_single_step(self) -> None:
        """Test scoring a trajectory with a single step."""
        scorer = GEPAScorer()
        trajectory = {
            "steps": [{"action": "start", "reward": 1.0}],
            "final_state": {"status": "complete"},
        }
        result = scorer.score_trajectory(trajectory)
        assert result.trajectory_score == 1.0
        assert len(result.step_scores) == 1

    def test_score_trajectory_multiple_steps(self) -> None:
        """Test scoring a trajectory with multiple steps."""
        scorer = GEPAScorer()
        trajectory = {
            "steps": [
                {"action": "start", "reward": 0.5},
                {"action": "continue", "reward": 0.8},
                {"action": "finish", "reward": 1.0},
            ],
            "final_state": {"status": "complete"},
        }
        result = scorer.score_trajectory(trajectory)
        assert len(result.step_scores) == 3
        assert result.trajectory_score > 0

    def test_score_trajectory_empty_steps(self) -> None:
        """Test scoring a trajectory with no steps."""
        scorer = GEPAScorer()
        trajectory = {"steps": [], "final_state": {"status": "empty"}}
        result = scorer.score_trajectory(trajectory)
        assert result.trajectory_score == 0.0
        assert result.step_scores == []

    def test_aggregate_step_rewards_single(self) -> None:
        """Test aggregating a single reward."""
        scorer = GEPAScorer()
        aggregated = scorer.aggregate_step_rewards([1.0])
        assert aggregated == 1.0

    def test_aggregate_step_rewards_multiple(self) -> None:
        """Test aggregating multiple rewards."""
        scorer = GEPAScorer()
        aggregated = scorer.aggregate_step_rewards([0.5, 0.8, 1.0])
        assert aggregated == 2.3

    def test_aggregate_step_rewards_empty(self) -> None:
        """Test aggregating empty rewards list."""
        scorer = GEPAScorer()
        aggregated = scorer.aggregate_step_rewards([])
        assert aggregated == 0.0


class TestGEPAResult:
    """Test suite for GEPAResult dataclass."""

    def test_result_creation(self) -> None:
        """Test GEPAResult can be created with required fields."""
        result = GEPAResult(
            trajectory_score=1.0,
            step_scores=[0.5, 1.0],
            convergence_indicator=0.95,
        )
        assert result.trajectory_score == 1.0
        assert result.step_scores == [0.5, 1.0]
        assert result.convergence_indicator == 0.95

    def test_result_defaults(self) -> None:
        """Test GEPAResult with default values."""
        result = GEPAResult(
            trajectory_score=0.0,
            step_scores=[],
            convergence_indicator=0.0,
        )
        assert result.trajectory_score == 0.0
        assert result.step_scores == []
        assert result.convergence_indicator == 0.0
