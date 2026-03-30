"""Tests for IFEvalEvaluator."""

from __future__ import annotations

import pytest

from skill.eval.ground_truth import IFEvalEvaluator, IFEvalResult, Instruction


class TestIFEvalEvaluator:
    """Test suite for IFEvalEvaluator."""

    def test_init_default_level(self) -> None:
        """Test evaluator initialization with default level."""
        evaluator = IFEvalEvaluator()
        assert evaluator.level == "relaxed"

    def test_init_with_strict_level(self) -> None:
        """Test evaluator initialization with strict level."""
        evaluator = IFEvalEvaluator(level="strict")
        assert evaluator.level == "strict"

    def test_evaluate_returns_ifeval_result(self) -> None:
        """Test that evaluate returns an IFEvalResult."""
        evaluator = IFEvalEvaluator()
        result = evaluator.evaluate(
            model_response="Here is the answer.",
            instruction="Provide a concise answer.",
        )
        assert isinstance(result, IFEvalResult)

    def test_evaluate_has_passed_field(self) -> None:
        """Test that result has passed boolean field."""
        evaluator = IFEvalEvaluator()
        result = evaluator.evaluate(
            model_response="Here is the answer.",
            instruction="Provide a concise answer.",
        )
        assert isinstance(result.passed, bool)

    def test_evaluate_has_level_field(self) -> None:
        """Test that result contains the level."""
        evaluator = IFEvalEvaluator(level="strict")
        result = evaluator.evaluate(
            model_response="Here is the answer.",
            instruction="Provide a concise answer.",
        )
        assert result.level == "strict"

    def test_evaluate_has_details_field(self) -> None:
        """Test that result has details dict field."""
        evaluator = IFEvalEvaluator()
        result = evaluator.evaluate(
            model_response="Here is the answer.",
            instruction="Provide a concise answer.",
        )
        assert hasattr(result, "details")
        assert result.details is None or isinstance(result.details, dict)

    def test_get_instructions_returns_list(self) -> None:
        """Test that get_instructions returns a list."""
        evaluator = IFEvalEvaluator()
        instructions = evaluator.get_instructions()
        assert isinstance(instructions, list)

    def test_get_instructions_returns_instruction_objects(self) -> None:
        """Test that returned list contains Instruction objects."""
        evaluator = IFEvalEvaluator()
        instructions = evaluator.get_instructions()
        if len(instructions) > 0:
            assert all(isinstance(inst, Instruction) for inst in instructions)

    def test_get_instructions_with_limit(self) -> None:
        """Test get_instructions with limit parameter."""
        evaluator = IFEvalEvaluator()
        instructions = evaluator.get_instructions(limit=5)
        assert len(instructions) <= 5


class TestIFEvalResult:
    """Test suite for IFEvalResult dataclass."""

    def test_result_creation(self) -> None:
        """Test IFEvalResult can be created with required fields."""
        result = IFEvalResult(
            instruction_id="inst_001",
            passed=True,
            level="relaxed",
        )
        assert result.instruction_id == "inst_001"
        assert result.passed is True
        assert result.level == "relaxed"

    def test_result_with_details(self) -> None:
        """Test IFEvalResult with details dict."""
        result = IFEvalResult(
            instruction_id="inst_001",
            passed=True,
            level="relaxed",
            details={"checks": ["format", "length"]},
        )
        assert result.details == {"checks": ["format", "length"]}


class TestInstruction:
    """Test suite for Instruction dataclass."""

    def test_instruction_creation(self) -> None:
        """Test Instruction can be created with required fields."""
        instruction = Instruction(
            id="inst_001",
            instruction="Provide a summary.",
            level="relaxed",
        )
        assert instruction.id == "inst_001"
        assert instruction.instruction == "Provide a summary."
        assert instruction.level == "relaxed"

    def test_instruction_with_prompt(self) -> None:
        """Test Instruction with optional prompt."""
        instruction = Instruction(
            id="inst_001",
            instruction="Provide a summary.",
            level="relaxed",
            prompt="Write a brief summary of the text.",
        )
        assert instruction.prompt == "Write a brief summary of the text."
