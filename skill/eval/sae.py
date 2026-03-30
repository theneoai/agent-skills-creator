"""SAE (Survivability-Aware Execution) evaluator for skill供应链安全."""

from __future__ import annotations

import importlib
import os
from dataclasses import dataclass
from enum import Enum
from pathlib import Path


class SurvivabilityLevel(Enum):
    """Survivability levels for skill evaluation."""

    CRITICAL = "critical"
    DEGRADED = "degraded"
    HEALTHY = "healthy"


@dataclass
class SurvivabilityReport:
    """Report of skill survivability evaluation."""

    level: SurvivabilityLevel
    score: float
    checks: dict[str, bool]
    recommendations: list[str]


class SAEEvaluator:
    """Evaluator for skill survivability assessment."""

    def __init__(self) -> None:
        """Initialize the SAE evaluator."""
        pass

    def evaluate(self, skill_path: str) -> SurvivabilityReport:
        """Evaluate skill survivability.

        Args:
            skill_path: Path to the skill to evaluate.

        Returns:
            SurvivabilityReport with evaluation results.
        """
        skill_exists = os.path.exists(skill_path)
        skill_content = ""

        if skill_exists:
            try:
                skill_content = Path(skill_path).read_text()
            except Exception:
                pass

        checks: dict[str, bool] = {}

        if not skill_exists:
            checks["skill_exists"] = False

        dep_checks = self.check_dependencies(skill_content)
        checks.update(dep_checks)

        env_checks = self.check_environment(dict(os.environ))
        checks.update(env_checks)

        score = self._calculate_score(checks)

        level = self._determine_level(score, checks)

        recommendations = self._generate_recommendations(checks, level)

        return SurvivabilityReport(
            level=level,
            score=score,
            checks=checks,
            recommendations=recommendations,
        )

    def check_dependencies(self, skill_content: str) -> dict[str, bool]:
        """Check skill dependencies availability.

        Args:
            skill_content: Content of the skill file.

        Returns:
            Dict mapping dependency name to availability status.
        """
        checks: dict[str, bool] = {}

        import_patterns = [
            "import ",
            "from ",
        ]

        for line in skill_content.split("\n"):
            line = line.strip()
            for pattern in import_patterns:
                if line.startswith(pattern):
                    module_name = self._extract_module_name(line, pattern)
                    if module_name and module_name not in checks:
                        checks[module_name] = self._check_module_available(module_name)

        return checks

    def check_environment(self, env_vars: dict[str, str]) -> dict[str, bool]:
        """Check environment variables availability.

        Args:
            env_vars: Environment variables to check.

        Returns:
            Dict mapping variable name to availability status.
        """
        checks: dict[str, bool] = {}
        for var_name in env_vars:
            checks[var_name] = var_name in os.environ and bool(os.environ.get(var_name))
        return checks

    def _extract_module_name(self, line: str, pattern: str) -> str | None:
        """Extract module name from import line."""
        if pattern == "import ":
            parts = line[len(pattern) :].split()
            if parts:
                return parts[0].split(".")[0]
        elif pattern == "from ":
            parts = line[len(pattern) :].split()
            if parts:
                return parts[0].split(".")[0]
        return None

    def _check_module_available(self, module_name: str) -> bool:
        """Check if a Python module is available."""
        if module_name in (
            "os",
            "sys",
            "json",
            "re",
            "time",
            "datetime",
            "collections",
            "itertools",
            "functools",
            "typing",
        ):
            return True
        try:
            importlib.import_module(module_name)
            return True
        except ImportError:
            return False

    def _calculate_score(self, checks: dict[str, bool]) -> float:
        """Calculate survivability score from checks."""
        if not checks:
            return 1.0

        true_count = sum(1 for v in checks.values() if v)
        return true_count / len(checks)

    def _determine_level(self, score: float, checks: dict[str, bool]) -> SurvivabilityLevel:
        """Determine survivability level from score and checks."""
        if checks.get("skill_exists", True) is False:
            return SurvivabilityLevel.CRITICAL

        if score >= 0.8 and all(checks.values()):
            return SurvivabilityLevel.HEALTHY
        elif score >= 0.5:
            return SurvivabilityLevel.DEGRADED
        else:
            return SurvivabilityLevel.CRITICAL

    def _generate_recommendations(
        self, checks: dict[str, bool], level: SurvivabilityLevel
    ) -> list[str]:
        """Generate recommendations based on checks and level."""
        recommendations = []

        missing_deps = [k for k, v in checks.items() if not v and k not in os.environ]
        if missing_deps:
            recommendations.append(f"Missing dependencies: {', '.join(missing_deps)}")
            recommendations.append("Install missing dependencies or use virtual environment")

        missing_envs = [k for k, v in checks.items() if not v and k in os.environ]
        if missing_envs:
            recommendations.append(f"Missing environment variables: {', '.join(missing_envs)}")

        if level == SurvivabilityLevel.CRITICAL:
            recommendations.append("Critical: Skill may not execute properly")
            recommendations.append("Review and fix missing dependencies before use")
        elif level == SurvivabilityLevel.DEGRADED:
            recommendations.append("Degraded: Some features may not work")
            recommendations.append("Consider fixing missing dependencies for full functionality")
        else:
            recommendations.append("Skill is healthy and ready to execute")

        return recommendations
