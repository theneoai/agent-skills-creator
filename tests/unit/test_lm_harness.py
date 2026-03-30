"""Tests for lm-evaluation-harness integration."""

import pytest


class TestLMEvaluator:
    """Test LMEvaluator class."""

    def test_init_default_tasks(self):
        """Test LMEvaluator initializes with default tasks."""
        from skill.eval.lm_harness import LMEvaluator

        evaluator = LMEvaluator()
        assert evaluator is not None

    def test_init_with_custom_tasks(self):
        """Test LMEvaluator accepts custom task list."""
        from skill.eval.lm_harness import LMEvaluator

        tasks = ["mmlu", "gsm8k"]
        evaluator = LMEvaluator(tasks=tasks)
        assert evaluator is not None

    def test_get_supported_tasks(self):
        """Test getting list of supported tasks."""
        from skill.eval.lm_harness import LMEvaluator

        evaluator = LMEvaluator()
        tasks = evaluator.get_supported_tasks()
        assert isinstance(tasks, list)

    def test_evaluate_returns_eval_result(self):
        """Test evaluate returns an EvalResult."""
        from skill.eval.lm_harness import LMEvaluator, EvalResult

        evaluator = LMEvaluator(tasks=["mmlu"])
        result = evaluator.evaluate(model="gpt2", prompt="What is 2+2?")
        assert isinstance(result, EvalResult)

    def test_eval_result_has_required_fields(self):
        """Test EvalResult contains all required fields."""
        from skill.eval.lm_harness import LMEvaluator

        evaluator = LMEvaluator(tasks=["mmlu"])
        result = evaluator.evaluate(model="gpt2", prompt="What is 2+2?")
        assert hasattr(result, "score")
        assert hasattr(result, "task")
        assert hasattr(result, "model")
