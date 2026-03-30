"""lm-evaluation-harness integration for skill framework."""

from dataclasses import dataclass
from typing import ClassVar


@dataclass
class EvalResult:
    """Result from evaluating a model on a task."""

    score: float
    task: str
    model: str


class LMEvaluator:
    """Wrapper for lm-evaluation-harness evaluation framework."""

    DEFAULT_TASKS: ClassVar[list[str]] = ["mmlu", "gsm8k", "hellaswag"]

    def __init__(self, tasks: list[str] | None = None) -> None:
        """Initialize evaluator with optional task list."""
        self.tasks = tasks if tasks is not None else self.DEFAULT_TASKS

    def get_supported_tasks(self) -> list[str]:
        """Return list of supported evaluation tasks."""
        return self.DEFAULT_TASKS

    def evaluate(self, model: str, prompt: str) -> EvalResult:
        """Evaluate a model on configured tasks."""
        task = self.tasks[0] if self.tasks else "mmlu"
        return EvalResult(score=0.0, task=task, model=model)
