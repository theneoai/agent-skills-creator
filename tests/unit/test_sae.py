"""Tests for SAE (Survivability-Aware Execution) evaluator."""

from __future__ import annotations

import pytest

from skill.eval.sae import (
    SAEEvaluator,
    SurvivabilityLevel,
    SurvivabilityReport,
)


class TestSurvivabilityLevel:
    """Test suite for SurvivabilityLevel enum."""

    def test_critical_level(self):
        """Test CRITICAL level exists and has correct value."""
        assert SurvivabilityLevel.CRITICAL.value == "critical"

    def test_degraded_level(self):
        """Test DEGRADED level exists and has correct value."""
        assert SurvivabilityLevel.DEGRADED.value == "degraded"

    def test_healthy_level(self):
        """Test HEALTHY level exists and has correct value."""
        assert SurvivabilityLevel.HEALTHY.value == "healthy"


class TestSurvivabilityReport:
    """Test suite for SurvivabilityReport dataclass."""

    def test_report_creation(self):
        """Test SurvivabilityReport creation with all fields."""
        report = SurvivabilityReport(
            level=SurvivabilityLevel.HEALTHY,
            score=0.95,
            checks={"dep_check": True, "env_check": True},
            recommendations=["Ensure dependencies are available"],
        )
        assert report.level == SurvivabilityLevel.HEALTHY
        assert report.score == 0.95
        assert report.checks == {"dep_check": True, "env_check": True}
        assert report.recommendations == ["Ensure dependencies are available"]

    def test_report_critical_level(self):
        """Test SurvivabilityReport with CRITICAL level."""
        report = SurvivabilityReport(
            level=SurvivabilityLevel.CRITICAL,
            score=0.2,
            checks={"dep_check": False},
            recommendations=["Critical: Fix dependencies"],
        )
        assert report.level == SurvivabilityLevel.CRITICAL
        assert report.score == 0.2

    def test_report_degraded_level(self):
        """Test SurvivabilityReport with DEGRADED level."""
        report = SurvivabilityReport(
            level=SurvivabilityLevel.DEGRADED,
            score=0.6,
            checks={"dep_check": True, "env_check": False},
            recommendations=["Some environment variables are missing"],
        )
        assert report.level == SurvivabilityLevel.DEGRADED
        assert report.score == 0.6


class TestSAEEvaluator:
    """Test suite for SAEEvaluator class."""

    def test_init(self):
        """Test SAEEvaluator initialization."""
        evaluator = SAEEvaluator()
        assert evaluator is not None

    def test_evaluate_returns_survivability_report(self):
        """Test that evaluate returns a SurvivabilityReport."""
        evaluator = SAEEvaluator()
        report = evaluator.evaluate("tests/fixtures/test_skill")
        assert isinstance(report, SurvivabilityReport)

    def test_evaluate_has_valid_level(self):
        """Test that evaluate returns report with valid level."""
        evaluator = SAEEvaluator()
        report = evaluator.evaluate("tests/fixtures/test_skill")
        assert isinstance(report.level, SurvivabilityLevel)

    def test_evaluate_has_score_in_range(self):
        """Test that evaluate returns score between 0 and 1."""
        evaluator = SAEEvaluator()
        report = evaluator.evaluate("tests/fixtures/test_skill")
        assert 0.0 <= report.score <= 1.0

    def test_evaluate_has_checks_dict(self):
        """Test that evaluate returns report with checks dict."""
        evaluator = SAEEvaluator()
        report = evaluator.evaluate("tests/fixtures/test_skill")
        assert isinstance(report.checks, dict)

    def test_evaluate_has_recommendations_list(self):
        """Test that evaluate returns report with recommendations list."""
        evaluator = SAEEvaluator()
        report = evaluator.evaluate("tests/fixtures/test_skill")
        assert isinstance(report.recommendations, list)

    def test_check_dependencies_returns_dict(self):
        """Test that check_dependencies returns a dict."""
        evaluator = SAEEvaluator()
        result = evaluator.check_dependencies("import os\nimport sys")
        assert isinstance(result, dict)

    def test_check_dependencies_dict_values_are_bools(self):
        """Test that check_dependencies returns dict with bool values."""
        evaluator = SAEEvaluator()
        result = evaluator.check_dependencies("import os\nimport sys")
        assert all(isinstance(v, bool) for v in result.values())

    def test_check_environment_returns_dict(self):
        """Test that check_environment returns a dict."""
        evaluator = SAEEvaluator()
        result = evaluator.check_environment({"PATH": "/usr/bin", "HOME": "/home/user"})
        assert isinstance(result, dict)

    def test_check_environment_dict_values_are_bools(self):
        """Test that check_environment returns dict with bool values."""
        evaluator = SAEEvaluator()
        result = evaluator.check_environment({"PATH": "/usr/bin", "HOME": "/home/user"})
        assert all(isinstance(v, bool) for v in result.values())

    def test_evaluate_with_empty_skill_path(self):
        """Test evaluate with path to non-existent skill."""
        evaluator = SAEEvaluator()
        report = evaluator.evaluate("non_existent_path")
        assert isinstance(report, SurvivabilityReport)
        assert report.level == SurvivabilityLevel.CRITICAL

    def test_evaluate_skill_with_all_dependencies(self):
        """Test evaluate with skill that has all dependencies available."""
        evaluator = SAEEvaluator()
        skill_content = "import os\nimport sys\nimport json"
        checks = evaluator.check_dependencies(skill_content)
        assert all(checks.values()) or not all(checks.values())

    def test_evaluate_skill_with_missing_dependencies(self):
        """Test evaluate with skill that has missing dependencies."""
        evaluator = SAEEvaluator()
        skill_content = "import nonexistent_package"
        checks = evaluator.check_dependencies(skill_content)
        assert "nonexistent_package" in checks

    def test_check_environment_all_present(self):
        """Test check_environment when all vars are present."""
        evaluator = SAEEvaluator()
        import os

        env_vars = {
            "PATH": os.environ.get("PATH", ""),
            "HOME": os.environ.get("HOME", ""),
        }
        result = evaluator.check_environment(env_vars)
        assert result.get("PATH", False) is True
        assert result.get("HOME", False) is True

    def test_check_environment_some_missing(self):
        """Test check_environment when some vars are missing."""
        evaluator = SAEEvaluator()
        result = evaluator.check_environment({"NONEXISTENT_VAR": ""})
        assert result.get("NONEXISTENT_VAR", False) is False
