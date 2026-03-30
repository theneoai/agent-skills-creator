"""Tests for multi-dimensional evaluation system."""

from __future__ import annotations

import pytest

from skill.eval.multi_dimensional import (
    DimensionResult,
    EvaluationResult,
    MultiDimensionalEvaluator,
)


class TestDimensionResult:
    """Test suite for DimensionResult dataclass."""

    def test_creation_with_required_fields(self):
        """Test DimensionResult creation with required fields."""
        result = DimensionResult(
            name="test_dimension",
            score=0.85,
            weight=0.25,
            details={"metric": "value"},
        )
        assert result.name == "test_dimension"
        assert result.score == 0.85
        assert result.weight == 0.25
        assert result.details == {"metric": "value"}

    def test_creation_with_empty_details(self):
        """Test DimensionResult creation with empty details."""
        result = DimensionResult(
            name="test",
            score=0.5,
            weight=0.1,
            details={},
        )
        assert result.details == {}


class TestEvaluationResult:
    """Test suite for EvaluationResult dataclass."""

    def test_creation_with_all_fields(self):
        """Test EvaluationResult creation with all fields."""
        result = EvaluationResult(
            overall_score=0.75,
            weights={"dim1": 0.5, "dim2": 0.5},
            dimensions={"dim1": DimensionResult("dim1", 0.8, 0.5, {})},
            cross_validation_score=0.7,
        )
        assert result.overall_score == 0.75
        assert result.weights == {"dim1": 0.5, "dim2": 0.5}
        assert "dim1" in result.dimensions
        assert result.cross_validation_score == 0.7

    def test_weights_sum_to_one(self):
        """Test that default weights sum to 1.0."""
        evaluator = MultiDimensionalEvaluator()
        total = sum(evaluator.weights.values())
        assert abs(total - 1.0) < 0.0001


class TestMultiDimensionalEvaluator:
    """Test suite for MultiDimensionalEvaluator class."""

    def test_init_default_weights(self):
        """Test evaluator initialization with default weights."""
        evaluator = MultiDimensionalEvaluator()
        assert "llm_runtime" in evaluator.weights
        assert "static_quality" in evaluator.weights
        assert "ground_truth" in evaluator.weights
        assert "cross_validation" in evaluator.weights

    def test_init_custom_weights(self):
        """Test evaluator initialization with custom weights."""
        custom_weights = {
            "llm_runtime": 0.50,
            "static_quality": 0.25,
            "ground_truth": 0.15,
            "cross_validation": 0.10,
        }
        evaluator = MultiDimensionalEvaluator(weights=custom_weights)
        assert evaluator.weights == custom_weights

    def test_default_weight_values(self):
        """Test default weight values match specification."""
        evaluator = MultiDimensionalEvaluator()
        expected = {
            "llm_runtime": 0.55,
            "static_quality": 0.20,
            "ground_truth": 0.15,
            "cross_validation": 0.10,
        }
        for key, value in expected.items():
            assert key in evaluator.weights
            assert abs(evaluator.weights[key] - value) < 0.0001

    def test_weights_sum_to_one(self):
        """Test that weights sum to 1.0."""
        evaluator = MultiDimensionalEvaluator()
        total = sum(evaluator.weights.values())
        assert abs(total - 1.0) < 0.0001

    def test_evaluate_returns_evaluation_result(self):
        """Test that evaluate returns an EvaluationResult."""
        evaluator = MultiDimensionalEvaluator()
        result = evaluator.evaluate("test_target")
        assert isinstance(result, EvaluationResult)

    def test_evaluate_has_all_dimensions(self):
        """Test that evaluate result contains all dimensions."""
        evaluator = MultiDimensionalEvaluator()
        result = evaluator.evaluate("test_target")
        for dimension_name in evaluator.weights.keys():
            assert dimension_name in result.dimensions

    def test_evaluate_overall_score_in_range(self):
        """Test that overall score is between 0 and 1."""
        evaluator = MultiDimensionalEvaluator()
        result = evaluator.evaluate("test_target")
        assert 0.0 <= result.overall_score <= 1.0

    def test_evaluate_dimension_scores_in_range(self):
        """Test that all dimension scores are between 0 and 1."""
        evaluator = MultiDimensionalEvaluator()
        result = evaluator.evaluate("test_target")
        for dim_result in result.dimensions.values():
            assert 0.0 <= dim_result.score <= 1.0

    def test_evaluate_dimension_weights_match_config(self):
        """Test that dimension weights in result match configuration."""
        evaluator = MultiDimensionalEvaluator()
        result = evaluator.evaluate("test_target")
        for name, weight in evaluator.weights.items():
            assert name in result.dimensions
            assert abs(result.dimensions[name].weight - weight) < 0.0001

    def test_get_dimension_scores_returns_dict(self):
        """Test that get_dimension_scores returns a dictionary."""
        evaluator = MultiDimensionalEvaluator()
        scores = evaluator.get_dimension_scores()
        assert isinstance(scores, dict)

    def test_get_dimension_scores_has_all_dimensions(self):
        """Test that get_dimension_scores contains all dimension names."""
        evaluator = MultiDimensionalEvaluator()
        scores = evaluator.get_dimension_scores()
        for dimension_name in evaluator.weights.keys():
            assert dimension_name in scores

    def test_get_dimension_scores_values_are_floats(self):
        """Test that dimension scores are floats."""
        evaluator = MultiDimensionalEvaluator()
        scores = evaluator.get_dimension_scores()
        for score in scores.values():
            assert isinstance(score, float)

    def test_cross_validation_score_in_range(self):
        """Test that cross validation score is between 0 and 1."""
        evaluator = MultiDimensionalEvaluator()
        result = evaluator.evaluate("test_target")
        assert 0.0 <= result.cross_validation_score <= 1.0


class TestMultiDimensionalEvaluatorIntegration:
    """Integration tests for MultiDimensionalEvaluator with real components."""

    def test_evaluate_with_mock_target(self):
        """Test evaluate with a mock target string."""
        evaluator = MultiDimensionalEvaluator()
        result = evaluator.evaluate("def hello(): return 'world'")
        assert result is not None
        assert isinstance(result.overall_score, float)
