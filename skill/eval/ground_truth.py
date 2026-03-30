"""Ground truth benchmark evaluators for GPQA and IFEval."""

from __future__ import annotations

import json
import os
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Literal

GPQA_QUESTIONS: dict[str, dict] = {
    "gpqa_bio_001": {
        "question": "Which organ is primarily responsible for filtering blood?",
        "options": ["A) Heart", "B) Liver", "C) Kidneys", "D) Lungs"],
        "answer": "C",
        "subset": "biology",
    },
    "gpqa_bio_002": {
        "question": "What is the primary function of DNA?",
        "options": [
            "A) Energy storage",
            "B) Protein synthesis",
            "C) Genetic information storage",
            "D) Cell membrane structure",
        ],
        "answer": "C",
        "subset": "biology",
    },
    "gpqa_chem_001": {
        "question": "What is the pH of a neutral solution at 25°C?",
        "options": ["A) 0", "B) 7", "C) 14", "D) 1"],
        "answer": "B",
        "subset": "chemistry",
    },
    "gpqa_chem_002": {
        "question": "Which element has the atomic number 6?",
        "options": ["A) Nitrogen", "B) Carbon", "C) Oxygen", "D) Boron"],
        "answer": "B",
        "subset": "chemistry",
    },
    "gpqa_physics_001": {
        "question": "What is the SI unit of force?",
        "options": ["A) Joule", "B) Watt", "C) Newton", "D) Pascal"],
        "answer": "C",
        "subset": "physics",
    },
}

IFEVAL_INSTRUCTIONS: list[dict] = [
    {
        "id": "ife_strict_001",
        "instruction": "Your response must be exactly 3 sentences long.",
        "level": "strict",
        "prompt": "Tell me about photosynthesis.",
    },
    {
        "id": "ife_strict_002",
        "instruction": "Start your response with 'Yes, I can help with that.'",
        "level": "strict",
        "prompt": "Can you help me with a task?",
    },
    {
        "id": "ife_strict_003",
        "instruction": "Do not use any numbers in your response.",
        "level": "strict",
        "prompt": "List three benefits of exercise.",
    },
    {
        "id": "ife_relaxed_001",
        "instruction": "Use a professional tone in your response.",
        "level": "relaxed",
        "prompt": "Explain quantum computing to a beginner.",
    },
    {
        "id": "ife_relaxed_002",
        "instruction": "Provide a concise summary.",
        "level": "relaxed",
        "prompt": "What are the main causes of climate change?",
    },
    {
        "id": "ife_relaxed_003",
        "instruction": "Include examples in your explanation.",
        "level": "relaxed",
        "prompt": "How does machine learning work?",
    },
    {
        "id": "ife_relaxed_004",
        "instruction": "Structure your response with bullet points.",
        "level": "relaxed",
        "prompt": "What are the best practices for coding?",
    },
]


@dataclass
class GPQAResult:
    """Result of GPQA evaluation."""

    question_id: str
    correct: bool
    confidence: float | None = None
    expert_verified: bool | None = None


@dataclass
class IFEvalResult:
    """Result of IFEval evaluation."""

    instruction_id: str
    passed: bool
    level: str
    details: dict | None = None


@dataclass
class Instruction:
    """IFEval instruction."""

    id: str
    instruction: str
    level: str
    prompt: str | None = None


def load_gpqa_from_jsonl(file_path: str | Path) -> dict[str, dict]:
    """Load GPQA questions from a JSONL file.

    Expected format per line: {"id": "q001", "question": "...", "answer": "C", "options": [...], "subset": "..."}

    Args:
        file_path: Path to JSONL file.

    Returns:
        Dictionary mapping question IDs to question data.
    """
    questions = {}
    with open(file_path) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            data = json.loads(line)
            qid = data.get("id", f"gpqa_{len(questions) + 1:03d}")
            questions[qid] = {
                "question": data.get("question", ""),
                "options": data.get("options", []),
                "answer": data.get("answer", ""),
                "subset": data.get("subset", "general"),
            }
    return questions


def load_ifeval_from_jsonl(file_path: str | Path) -> list[dict]:
    """Load IFEval instructions from a JSONL file.

    Expected format per line: {"id": "inst_001", "instruction": "...", "level": "strict", "prompt": "..."}

    Args:
        file_path: Path to JSONL file.

    Returns:
        List of instruction dictionaries.
    """
    instructions = []
    with open(file_path) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            data = json.loads(line)
            instructions.append(
                {
                    "id": data.get("id", f"ife_{len(instructions) + 1:03d}"),
                    "instruction": data.get("instruction", ""),
                    "level": data.get("level", "relaxed"),
                    "prompt": data.get("prompt"),
                }
            )
    return instructions


def load_from_huggingface(
    dataset_name: str, split: str = "train"
) -> tuple[dict[str, dict], list[dict]]:
    """Load GPQA and IFEval data from HuggingFace datasets.

    Attempts to load 'parasaurolophus/GPQA' or 'google/IFEval' datasets.

    Args:
        dataset_name: HuggingFace dataset name or path.
        split: Dataset split to load.

    Returns:
        Tuple of (gpqa_questions dict, ifeval_instructions list).
    """
    try:
        from datasets import load_dataset
    except ImportError:
        raise ImportError("HuggingFace datasets not installed. Run: pip install datasets")

    dataset = load_dataset(dataset_name, split=split)
    gpqa_questions = {}
    ifeval_instructions = []

    if "gpqa" in dataset_name.lower():
        for i, row in enumerate(dataset):
            qid = row.get("id", f"gpqa_{i + 1:03d}")
            gpqa_questions[qid] = {
                "question": row.get("question", ""),
                "options": row.get("options", []),
                "answer": row.get("answer", ""),
                "subset": row.get("subset", "general"),
            }
    elif "ifeval" in dataset_name.lower():
        for i, row in enumerate(dataset):
            ifeval_instructions.append(
                {
                    "id": row.get("id", f"ife_{i + 1:03d}"),
                    "instruction": row.get("instruction", ""),
                    "level": row.get("level", "relaxed"),
                    "prompt": row.get("prompt"),
                }
            )

    return gpqa_questions, ifeval_instructions


class GPQAEvaluator:
    """GPQA (General Purpose Question Answering) evaluator.

    Evaluates model responses against expert-validated answers from GPQA dataset.
    Supports multiple choice questions with expert verification.
    """

    def __init__(
        self,
        subset: str | None = None,
        jsonl_path: str | Path | None = None,
        hf_dataset: str | None = None,
    ) -> None:
        """Initialize GPQA evaluator.

        Args:
            subset: Optional subset of GPQA to use (e.g., 'biology', 'chemistry').
            jsonl_path: Optional path to JSONL file to load questions from.
            hf_dataset: Optional HuggingFace dataset name to load from.
        """
        self.subset = subset
        if jsonl_path:
            self._questions = load_gpqa_from_jsonl(jsonl_path)
        elif hf_dataset:
            gpqa_data, _ = load_from_huggingface(hf_dataset)
            self._questions = gpqa_data
        else:
            self._questions = GPQA_QUESTIONS

    def evaluate(self, model_response: str, question_id: str) -> GPQAResult:
        """Evaluate a model response for a GPQA question.

        Args:
            model_response: The model's response text.
            question_id: The GPQA question identifier.

        Returns:
            GPQAResult with evaluation outcome.
        """
        if question_id not in self._questions:
            return GPQAResult(
                question_id=question_id,
                correct=False,
                confidence=0.0,
                expert_verified=False,
            )

        question = self._questions[question_id]

        if self.subset is not None and question.get("subset") != self.subset:
            return GPQAResult(
                question_id=question_id,
                correct=False,
                confidence=0.0,
                expert_verified=False,
            )

        correct_answer = question["answer"]
        response_upper = model_response.upper()

        answer_pattern = r"\b([A-D])\b"
        match = re.search(answer_pattern, response_upper)

        detected_answer = match.group(1) if match else None

        is_correct = detected_answer == correct_answer

        confidence = 1.0 if is_correct else 0.0

        return GPQAResult(
            question_id=question_id,
            correct=is_correct,
            confidence=confidence,
            expert_verified=True,
        )


class IFEvalEvaluator:
    """IFEval (Instruction Following Evaluation) evaluator.

    Evaluates whether model responses follow given instructions.
    Supports both 'relaxed' and 'strict' evaluation levels.
    """

    def __init__(
        self,
        level: Literal["relaxed", "strict"] = "relaxed",
        jsonl_path: str | Path | None = None,
        hf_dataset: str | None = None,
    ) -> None:
        """Initialize IFEval evaluator.

        Args:
            level: Strictness level ('relaxed' or 'strict').
            jsonl_path: Optional path to JSONL file to load instructions from.
            hf_dataset: Optional HuggingFace dataset name to load from.
        """
        self.level = level
        if jsonl_path:
            self._instructions = load_ifeval_from_jsonl(jsonl_path)
        elif hf_dataset:
            _, ifeval_data = load_from_huggingface(hf_dataset)
            self._instructions = ifeval_data
        else:
            self._instructions = IFEVAL_INSTRUCTIONS

    def evaluate(self, model_response: str, instruction: str) -> IFEvalResult:
        """Evaluate if model response follows the instruction.

        Args:
            model_response: The model's response text.
            instruction: The instruction to check compliance against.

        Returns:
            IFEvalResult with pass/fail outcome.
        """
        passed = self._check_compliance(model_response, instruction)
        instruction_id = self._find_matching_instruction_id(instruction)

        return IFEvalResult(
            instruction_id=instruction_id,
            passed=passed,
            level=self.level,
            details={"instruction": instruction},
        )

    def _check_compliance(self, response: str, instruction: str) -> bool:
        """Check if response complies with instruction."""
        instruction_lower = instruction.lower()
        compliant = True

        if "exactly 3 sentences" in instruction_lower:
            sentence_count = len(re.split(r"[.!?]+", response.strip())) - 1
            compliant = sentence_count == 3
        elif "start your response with" in instruction_lower:
            required_start = instruction.rsplit("'", maxsplit=1)[-1] if "'" in instruction else ""
            compliant = bool(required_start) and response.strip().lower().startswith(
                required_start.lower()
            )
        elif "do not use any numbers" in instruction_lower:
            compliant = not bool(re.search(r"\d", response))
        elif "professional tone" in instruction_lower:
            informal_patterns = [r"\b(wow|awesome|cool|great|hey|yo)\b", r"!{2,}"]
            compliant = not any(re.search(p, response, re.IGNORECASE) for p in informal_patterns)
        elif "concise summary" in instruction_lower:
            word_count = len(response.split())
            compliant = 50 <= word_count <= 200
        elif "include examples" in instruction_lower:
            example_indicators = [r"\bfor example\b", r"\bsuch as\b", r"\bincluding\b", r"\be\.g\."]
            compliant = any(re.search(p, response, re.IGNORECASE) for p in example_indicators)
        elif "bullet points" in instruction_lower:
            bullet_patterns = [r"^[\s]*[-*•]", r"^\s*\d+\.", r"^[\s]*\([a-z]\)"]
            compliant = any(re.search(p, response, re.MULTILINE) for p in bullet_patterns)

        return compliant

    def _find_matching_instruction_id(self, instruction: str) -> str:
        """Find matching instruction ID from the instruction text."""
        for inst in self._instructions:
            if inst["instruction"].lower() in instruction.lower():
                return inst["id"]
            if instruction.lower() in inst["instruction"].lower():
                return inst["id"]
        return "unknown"

    def get_instructions(self, limit: int | None = None) -> list[Instruction]:
        """Get IFEval instructions.

        Args:
            limit: Maximum number of instructions to return.

        Returns:
            List of Instruction objects.
        """
        filtered = [
            inst
            for inst in self._instructions
            if self.level == "relaxed" or inst["level"] == self.level
        ]

        if limit is not None:
            filtered = filtered[:limit]

        return [
            Instruction(
                id=inst["id"],
                instruction=inst["instruction"],
                level=inst["level"],
                prompt=inst.get("prompt"),
            )
            for inst in filtered
        ]
