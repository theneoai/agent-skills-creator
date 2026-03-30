"""Tests for GPQAEvaluator."""

from __future__ import annotations

import pytest

from skill.eval.ground_truth import GPQAEvaluator, GPQAResult


class TestGPQAEvaluator:
    """Test suite for GPQAEvaluator."""

    def test_init_without_subset(self) -> None:
        """Test evaluator initialization without subset."""
        evaluator = GPQAEvaluator()
        assert evaluator.subset is None

    def test_init_with_subset(self) -> None:
        """Test evaluator initialization with subset."""
        evaluator = GPQAEvaluator(subset="biology")
        assert evaluator.subset == "biology"

    def test_evaluate_returns_gpqa_result(self) -> None:
        """Test that evaluate returns a GPQAResult."""
        evaluator = GPQAEvaluator()
        result = evaluator.evaluate(
            model_response="The answer is A",
            question_id="gpqa_bio_001",
        )
        assert isinstance(result, GPQAResult)

    def test_evaluate_has_question_id(self) -> None:
        """Test that result contains the question_id."""
        evaluator = GPQAEvaluator()
        result = evaluator.evaluate(
            model_response="The answer is A",
            question_id="gpqa_bio_001",
        )
        assert result.question_id == "gpqa_bio_001"

    def test_evaluate_has_correct_field(self) -> None:
        """Test that result has correct boolean field."""
        evaluator = GPQAEvaluator()
        result = evaluator.evaluate(
            model_response="The answer is A",
            question_id="gpqa_bio_001",
        )
        assert isinstance(result.correct, bool)

    def test_evaluate_has_confidence_field(self) -> None:
        """Test that result has confidence field."""
        evaluator = GPQAEvaluator()
        result = evaluator.evaluate(
            model_response="The answer is A",
            question_id="gpqa_bio_001",
        )
        assert hasattr(result, "confidence")
        assert result.confidence is None or isinstance(result.confidence, float)

    def test_evaluate_has_expert_verified_field(self) -> None:
        """Test that result has expert_verified field."""
        evaluator = GPQAEvaluator()
        result = evaluator.evaluate(
            model_response="The answer is A",
            question_id="gpqa_bio_001",
        )
        assert hasattr(result, "expert_verified")


class TestGPQAResult:
    """Test suite for GPQAResult dataclass."""

    def test_result_creation(self) -> None:
        """Test GPQAResult can be created with required fields."""
        result = GPQAResult(question_id="test_001", correct=True)
        assert result.question_id == "test_001"
        assert result.correct is True

    def test_result_with_confidence(self) -> None:
        """Test GPQAResult with confidence."""
        result = GPQAResult(
            question_id="test_001",
            correct=True,
            confidence=0.95,
        )
        assert result.confidence == 0.95

    def test_result_with_expert_verified(self) -> None:
        """Test GPQAResult with expert_verified."""
        result = GPQAResult(
            question_id="test_001",
            correct=True,
            expert_verified=True,
        )
        assert result.expert_verified is True
