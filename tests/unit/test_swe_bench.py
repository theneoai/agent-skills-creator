"""Tests for SWE-bench Verified evaluator."""

from __future__ import annotations

import pytest

from skill.eval.swe_bench import (
    Issue,
    PatchEvalResult,
    SWEBenchEvaluator,
    Testbed,
)


class TestSWEBenchEvaluator:
    """Test suite for SWEBenchEvaluator class."""

    def test_init_default_dataset(self):
        """Test evaluator initialization with default dataset."""
        evaluator = SWEBenchEvaluator()
        assert evaluator.dataset == "swe-bench-verified"

    def test_init_custom_dataset(self):
        """Test evaluator initialization with custom dataset."""
        evaluator = SWEBenchEvaluator(dataset="custom-dataset")
        assert evaluator.dataset == "custom-dataset"

    def test_get_issues_returns_list(self):
        """Test that get_issues returns a list of Issue objects."""
        evaluator = SWEBenchEvaluator()
        issues = evaluator.get_issues()
        assert isinstance(issues, list)

    def test_get_issues_with_limit(self):
        """Test that get_issues respects the limit parameter."""
        evaluator = SWEBenchEvaluator()
        issues = evaluator.get_issues(limit=5)
        assert len(issues) <= 5

    def test_get_issues_issue_structure(self):
        """Test that returned issues have expected structure."""
        evaluator = SWEBenchEvaluator()
        issues = evaluator.get_issues(limit=1)
        if issues:
            issue = issues[0]
            assert hasattr(issue, "issue_id")
            assert hasattr(issue, "repo")
            assert hasattr(issue, "problem_statement")
            assert hasattr(issue, "gold_patch")

    def test_get_testbed_env_returns_testbed(self):
        """Test that get_testbed_env returns a Testbed object."""
        evaluator = SWEBenchEvaluator()
        issues = evaluator.get_issues(limit=1)
        if issues:
            testbed = evaluator.get_testbed_env(issues[0].issue_id)
            assert isinstance(testbed, Testbed)

    def test_get_testbed_env_unknown_issue(self):
        """Test that get_testbed_env raises for unknown issue."""
        evaluator = SWEBenchEvaluator()
        with pytest.raises(ValueError, match="Unknown issue"):
            evaluator.get_testbed_env("unknown-issue-id")

    def test_evaluate_patch_returns_patch_eval_result(self):
        """Test that evaluate_patch returns a PatchEvalResult."""
        evaluator = SWEBenchEvaluator()
        issues = evaluator.get_issues(limit=1)
        if issues:
            issue = issues[0]
            result = evaluator.evaluate_patch(issue.issue_id, issue.gold_patch)
            assert isinstance(result, PatchEvalResult)

    def test_evaluate_patch_correct_patch(self):
        """Test that a correct patch is evaluated as passing."""
        evaluator = SWEBenchEvaluator()
        issues = evaluator.get_issues(limit=1)
        if issues:
            issue = issues[0]
            result = evaluator.evaluate_patch(issue.issue_id, issue.gold_patch)
            assert result.passed is True
            assert result.test_results is not None

    def test_evaluate_patch_incorrect_patch(self):
        """Test that an incorrect patch is evaluated as failing."""
        evaluator = SWEBenchEvaluator()
        issues = evaluator.get_issues(limit=1)
        if issues:
            issue = issues[0]
            result = evaluator.evaluate_patch(issue.issue_id, "incorrect patch content")
            assert result.passed is False

    def test_evaluate_patch_unknown_issue(self):
        """Test that evaluate_patch raises for unknown issue."""
        evaluator = SWEBenchEvaluator()
        with pytest.raises(ValueError, match="Unknown issue"):
            evaluator.evaluate_patch("unknown-issue-id", "some patch")

    def test_evaluate_patch_empty_patch(self):
        """Test that an empty patch is evaluated as failing."""
        evaluator = SWEBenchEvaluator()
        issues = evaluator.get_issues(limit=1)
        if issues:
            issue = issues[0]
            result = evaluator.evaluate_patch(issue.issue_id, "")
            assert result.passed is False


class TestIssue:
    """Test suite for Issue dataclass."""

    def test_issue_creation(self):
        """Test Issue dataclass creation."""
        issue = Issue(
            issue_id="test-issue",
            repo="test-repo",
            problem_statement="Test problem",
            gold_patch="test patch",
        )
        assert issue.issue_id == "test-issue"
        assert issue.repo == "test-repo"
        assert issue.problem_statement == "Test problem"
        assert issue.gold_patch == "test patch"


class TestPatchEvalResult:
    """Test suite for PatchEvalResult dataclass."""

    def test_patch_eval_result_creation(self):
        """Test PatchEvalResult dataclass creation."""
        result = PatchEvalResult(
            issue_id="test-issue",
            passed=True,
            test_results={"test_1": "PASSED"},
        )
        assert result.issue_id == "test-issue"
        assert result.passed is True
        assert result.test_results == {"test_1": "PASSED"}

    def test_patch_eval_result_failed(self):
        """Test PatchEvalResult for failed evaluation."""
        result = PatchEvalResult(
            issue_id="test-issue",
            passed=False,
            test_results={"test_1": "FAILED"},
        )
        assert result.passed is False


class TestTestbed:
    """Test suite for Testbed dataclass."""

    def test_testbed_creation(self):
        """Test Testbed dataclass creation."""
        testbed = Testbed(
            issue_id="test-issue",
            env_path="/tmp/test_env",
        )
        assert testbed.issue_id == "test-issue"
        assert testbed.env_path == "/tmp/test_env"
