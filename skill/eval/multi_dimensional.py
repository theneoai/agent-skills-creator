"""Multi-dimensional evaluation system for skill framework."""

from __future__ import annotations

import math
import re
from dataclasses import dataclass
from typing import Any

from skill.eval.ground_truth import GPQAEvaluator, IFEvalEvaluator
from skill.eval.lm_harness import LMEvaluator as BaseLMEvaluator
from skill.eval.swe_bench import SWEBenchEvaluator


@dataclass
class DimensionResult:
    """Result of a single evaluation dimension."""

    name: str
    score: float
    weight: float
    details: dict[str, Any]


@dataclass
class EvaluationResult:
    """Result of multi-dimensional evaluation."""

    overall_score: float
    weights: dict[str, float]
    dimensions: dict[str, DimensionResult]
    cross_validation_score: float


class StaticQualityEvaluator:
    """Evaluates static text quality dimensions.

    Evaluates:
    - Semantic cohesion: measures how semantically related text segments are
    - Readability: measures text readability using syllable count and sentence structure
    - Structure: measures structural quality (headers, lists, paragraphs)
    """

    def evaluate(self, text: str) -> dict[str, float]:
        """Evaluate text quality.

        Args:
            text: The text to evaluate.

        Returns:
            Dictionary with scores for cohesion, readability, structure.
        """
        if not text or not text.strip():
            return {"cohesion": 0.0, "readability": 0.0, "structure": 0.0}

        cohesion = self._evaluate_cohesion(text)
        readability = self._evaluate_readability(text)
        structure = self._evaluate_structure(text)

        return {
            "cohesion": cohesion,
            "readability": readability,
            "structure": structure,
        }

    def _evaluate_cohesion(self, text: str) -> float:
        """Evaluate semantic cohesion using word overlap."""
        sentences = re.split(r"[.!?]+", text)
        sentences = [s.strip() for s in sentences if s.strip()]

        if len(sentences) < 2:
            return 1.0

        sentence_words = [set(s.lower().split()) for s in sentences]
        overlaps = []

        for i in range(len(sentence_words) - 1):
            current = sentence_words[i]
            next_sent = sentence_words[i + 1]
            overlap = len(current & next_sent)
            max_words = max(len(current), len(next_sent))
            if max_words > 0:
                overlaps.append(overlap / max_words)

        if overlaps:
            return sum(overlaps) / len(overlaps)
        return 0.0

    def _evaluate_readability(self, text: str) -> float:
        """Evaluate readability based on sentence length and word complexity."""
        sentences = re.split(r"[.!?]+", text)
        sentences = [s.strip() for s in sentences if s.strip()]

        if not sentences:
            return 0.0

        total_score = 0.0
        for sentence in sentences:
            words = sentence.split()
            if not words:
                continue

            avg_word_len = sum(len(w) for w in words) / len(words)
            syllables = sum(self._count_syllables(w) for w in words)
            avg_syllables = syllables / len(words) if words else 0

            sentence_score = 1.0
            if avg_word_len > 8:
                sentence_score -= 0.2
            if avg_syllables > 2.5:
                sentence_score -= 0.2
            if len(words) > 30:
                sentence_score -= 0.2

            total_score += max(0.0, sentence_score)

        return total_score / len(sentences) if sentences else 0.0

    def _count_syllables(self, word: str) -> int:
        """Count syllables in a word using vowel groups."""
        word = word.lower()
        vowels = "aeiouy"
        count = 0
        prev_vowel = False

        for char in word:
            is_vowel = char in vowels
            if is_vowel and not prev_vowel:
                count += 1
            prev_vowel = is_vowel

        if word.endswith("e"):
            count = max(1, count - 1)

        return max(1, count)

    def _evaluate_structure(self, text: str) -> float:
        """Evaluate structural quality."""
        score = 0.5

        has_headers = bool(re.search(r"^#+\s+\w+", text, re.MULTILINE))
        if has_headers:
            score += 0.15

        has_lists = bool(re.search(r"^\s*[-*•]\s+\w+", text, re.MULTILINE))
        if has_lists:
            score += 0.15

        paragraphs = [p.strip() for p in text.split("\n\n") if p.strip()]
        if len(paragraphs) >= 2:
            score += 0.1

        has_code_blocks = bool(re.search(r"```", text))
        if has_code_blocks:
            score += 0.1

        return min(1.0, score)


class MultiDimensionalEvaluator:
    """Multi-dimensional evaluator integrating multiple assessment approaches.

    Dimensions and weights:
    - LLM Runtime Evaluation: 55%
    - Static Text Quality: 20%
    - Ground Truth Benchmark: 15%
    - Cross-Validation: 10%
    """

    DEFAULT_WEIGHTS: dict[str, float] = {
        "llm_runtime": 0.55,
        "static_quality": 0.20,
        "ground_truth": 0.15,
        "cross_validation": 0.10,
    }

    def __init__(self, weights: dict[str, float] | None = None) -> None:
        """Initialize multi-dimensional evaluator.

        Args:
            weights: Optional custom weights for dimensions.
        """
        self.weights = weights if weights is not None else self.DEFAULT_WEIGHTS.copy()
        self._static_evaluator = StaticQualityEvaluator()
        self._lm_evaluator = BaseLMEvaluator()
        self._swe_evaluator = SWEBenchEvaluator()
        self._gpqa_evaluator = GPQAEvaluator()
        self._ifeval_evaluator = IFEvalEvaluator()
        self._last_scores: dict[str, float] = {}

    def evaluate(self, target: str) -> EvaluationResult:
        """Evaluate a target using multi-dimensional assessment.

        Args:
            target: The target to evaluate.

        Returns:
            EvaluationResult with scores for all dimensions.
        """
        static_result = self._evaluate_static_quality(target)
        llm_result = self._evaluate_llm_runtime(target)
        ground_truth_result = self._evaluate_ground_truth(target)

        llm_score = llm_result["score"]
        static_score = static_result["overall"]
        ground_truth_score = ground_truth_result["overall"]

        cross_validation = self._compute_cross_validation(
            llm_score, static_score, ground_truth_score
        )

        self._last_scores = {
            "llm_runtime": llm_score,
            "static_quality": static_score,
            "ground_truth": ground_truth_score,
            "cross_validation": cross_validation,
        }

        dimensions = {
            "llm_runtime": DimensionResult(
                name="llm_runtime",
                score=llm_score,
                weight=self.weights["llm_runtime"],
                details=llm_result.get("details", {}),
            ),
            "static_quality": DimensionResult(
                name="static_quality",
                score=static_score,
                weight=self.weights["static_quality"],
                details=static_result,
            ),
            "ground_truth": DimensionResult(
                name="ground_truth",
                score=ground_truth_score,
                weight=self.weights["ground_truth"],
                details=ground_truth_result.get("details", {}),
            ),
            "cross_validation": DimensionResult(
                name="cross_validation",
                score=cross_validation,
                weight=self.weights["cross_validation"],
                details={"method": "consistency_check"},
            ),
        }

        overall_score = sum(self._last_scores[key] * self.weights[key] for key in self.weights)

        return EvaluationResult(
            overall_score=overall_score,
            weights=self.weights.copy(),
            dimensions=dimensions,
            cross_validation_score=cross_validation,
        )

    def get_dimension_scores(self) -> dict[str, float]:
        """Get scores for all dimensions.

        Returns:
            Dictionary mapping dimension names to scores.
        """
        if not self._last_scores:
            result = self.evaluate("")
            return {name: result.dimensions[name].score for name in self.weights}
        return self._last_scores.copy()

    def _evaluate_static_quality(self, text: str) -> dict[str, Any]:
        """Evaluate static text quality."""
        scores = self._static_evaluator.evaluate(text)
        overall = (scores["cohesion"] + scores["readability"] + scores["structure"]) / 3
        return {"overall": overall, **scores}

    def _evaluate_llm_runtime(self, target: str) -> dict[str, Any]:
        """Evaluate LLM runtime performance."""
        result = self._lm_evaluator.evaluate(model="default", prompt=target)
        return {"score": result.score, "details": {"task": result.task}}

    def _evaluate_ground_truth(self, target: str) -> dict[str, Any]:
        """Evaluate ground truth benchmarks."""
        swe_score = self._evaluate_swe_bench(target)
        gpqa_score = self._evaluate_gpqa(target)
        ifeval_score = self._evaluate_ifeval(target)

        overall = (swe_score + gpqa_score + ifeval_score) / 3

        return {
            "overall": overall,
            "details": {
                "swe_bench": swe_score,
                "gpqa": gpqa_score,
                "ifeval": ifeval_score,
            },
        }

    def _evaluate_swe_bench(self, target: str) -> float:
        """Evaluate SWE-bench benchmark."""
        issues = self._swe_evaluator.get_issues(limit=1)
        if not issues:
            return 0.0

        issue = issues[0]
        patch_result = self._swe_evaluator.evaluate_patch(issue.issue_id, target)
        return 1.0 if patch_result.passed else 0.0

    def _evaluate_gpqa(self, target: str) -> float:
        """Evaluate GPQA benchmark."""
        questions = list(self._gpqa_evaluator._questions.keys())[:1]
        if not questions:
            return 0.0

        question_id = questions[0]
        result = self._gpqa_evaluator.evaluate(target, question_id)
        return 1.0 if result.correct else 0.0

    def _evaluate_ifeval(self, target: str) -> float:
        """Evaluate IFEval benchmark."""
        instructions = self._ifeval_evaluator.get_instructions(limit=1)
        if not instructions:
            return 0.0

        instruction = instructions[0]
        result = self._ifeval_evaluator.evaluate(target, instruction.instruction)
        return 1.0 if result.passed else 0.0

    def _compute_cross_validation(
        self, llm_score: float, static_score: float, ground_truth_score: float
    ) -> float:
        """Compute cross-validation score based on consistency."""
        scores = [llm_score, static_score, ground_truth_score]
        mean = sum(scores) / len(scores)
        variance = sum((s - mean) ** 2 for s in scores) / len(scores)
        std_dev = math.sqrt(variance)

        consistency = 1.0 - min(1.0, std_dev)

        return consistency
