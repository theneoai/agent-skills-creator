"""GEPA (Generalized Policy Evaluation) trajectory-level scoring."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Protocol


class Trajectory(Protocol):
    """Protocol for execution trajectories."""

    steps: list[dict]
    final_state: dict


@dataclass
class GEPAResult:
    """Result of GEPA trajectory evaluation."""

    trajectory_score: float
    step_scores: list[float]
    convergence_indicator: float


class GEPAScorer:
    """GEPA (Generalized Policy Evaluation) scorer for trajectory-level rewards.

    Evaluates complete execution trajectories and computes trajectory-level
    reward scores with convergence indicators.
    """

    def __init__(self, model: str | None = None) -> None:
        """Initialize GEPA scorer.

        Args:
            model: Optional model identifier for scoring.
        """
        self.model = model

    def score_trajectory(self, trajectory: Trajectory) -> GEPAResult:
        """Score a complete execution trajectory.

        Args:
            trajectory: The execution trajectory to evaluate.

        Returns:
            GEPAResult with trajectory score, step scores, and convergence.
        """
        steps = trajectory.steps if hasattr(trajectory, "steps") else trajectory["steps"]
        step_scores = [step.get("reward", 0.0) for step in steps]
        trajectory_score = self.aggregate_step_rewards(step_scores)
        convergence_indicator = self._compute_convergence(step_scores)

        return GEPAResult(
            trajectory_score=trajectory_score,
            step_scores=step_scores,
            convergence_indicator=convergence_indicator,
        )

    def aggregate_step_rewards(self, rewards: list[float]) -> float:
        """Aggregate step rewards into a trajectory-level score.

        Args:
            rewards: List of step-level reward values.

        Returns:
            Aggregated trajectory score.
        """
        return sum(rewards)

    def _compute_convergence(self, step_scores: list[float]) -> float:
        """Compute convergence indicator based on step score variance."""
        if not step_scores:
            return 0.0

        if len(step_scores) == 1:
            return 1.0

        mean = sum(step_scores) / len(step_scores)
        variance = sum((s - mean) ** 2 for s in step_scores) / len(step_scores)
        max_variance = mean * (1 - mean) if mean > 0 and mean < 1 else 0.0

        if max_variance == 0:
            return 1.0

        return max(0.0, 1.0 - variance / max_variance)
