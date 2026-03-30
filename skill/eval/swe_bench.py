"""SWE-bench Verified evaluator for code skill absolute assessment."""

from __future__ import annotations

import hashlib
import tempfile
from dataclasses import dataclass, field


@dataclass
class Issue:
    """Represents a SWE-bench issue."""

    issue_id: str
    repo: str
    problem_statement: str
    gold_patch: str


@dataclass
class PatchEvalResult:
    """Result of patch evaluation."""

    issue_id: str
    passed: bool
    test_results: dict[str, str] | None = None


@dataclass
class Testbed:
    """Represents a testbed environment for an issue."""

    issue_id: str
    env_path: str


SAMPLE_ISSUES: list[Issue] = [
    Issue(
        issue_id="django__django-11099",
        repo="django/django",
        problem_statement="GenericForeignKey is not working with model inheritance",
        gold_patch="""diff --git a/django/contrib/contenttypes/fields.py b/django/contrib/contenttypes/fields.py
--- a/django/contrib/contenttypes/fields.py
+++ b/django/contrib/contenttypes/fields.py
@@ -123,7 +123,7 @@ class GenericForeignKey:
         if self.instance is None:
             return
         cache_name = self.get_cache_name()
-        if not hasattr(self.instance, cache_name):
+        if not hasattr(self.instance, cache_name) or getattr(self.instance, cache_name) is None:
             return None
         return getattr(self.instance, cache_name)
""",
    ),
    Issue(
        issue_id="scikit-learn__scikit-learn-12042",
        repo="scikit-learn/scikit-learn",
        problem_statement="Feature names are not properly handled in ColumnTransformer",
        gold_patch="""diff --git a/sklearn/compose/_column_transformer.py b/sklearn/compose/_column_transformer.py
--- a/sklearn/compose/_column_transformer.py
+++ b/sklearn/compose/_column_transformer.py
@@ -456,7 +456,10 @@ class ColumnTransformer:
                 else:
                     if not callable(get_feature_names):
                         raise ValueError(
-                            f"Estimator {name} does not provide get_feature_names."
+                            f"Estimator {name!r} does not provide "
+                            "get_feature_names. The following estimators don't: "
+                            f"{sorted(est for est in self.named_estimators_"
+                            "if not hasattr(est, 'get_feature_names'))}"
                         )
                     feature_names = get_feature_names()
""",
    ),
    Issue(
        issue_id="pytest-dev__pytest-8342",
        repo="pytest-dev/pytest",
        problem_statement="Fixture is not teardown after exception in parametrize",
        gold_patch="""diff --git a/src/_pytest/python.py b/src/_pytest/python.py
--- a/src/_pytest/python.py
+++ b/src/_pytest/python.py
@@ -1524,7 +1524,7 @@ class Function(FunctionMixin, _pytest.unittest.TestCaseFunction):
     @pytest.hookimpl(hookwrapper=True)
     def _pytest_runtest_protocol(self):
         item = self
-        for phase in ("setup", "call", "teardown"):
+        for phase in ("setup", "call"):
             yields = None
             with suppress(Exception):
                 yields = next(iter(self.genyield))
""",
    ),
]


class SWEBenchEvaluator:
    """Evaluator for SWE-bench Verified benchmark."""

    def __init__(self, dataset: str = "swe-bench-verified") -> None:
        """Initialize the SWE-bench evaluator.

        Args:
            dataset: The dataset to use. Defaults to "swe-bench-verified".
        """
        self.dataset = dataset
        self._issues: dict[str, Issue] = {issue.issue_id: issue for issue in SAMPLE_ISSUES}
        self._testbeds: dict[str, Testbed] = {}

    def _get_issue(self, issue_id: str) -> Issue:
        """Get an issue by ID or raise ValueError."""
        if issue_id not in self._issues:
            raise ValueError(f"Unknown issue: {issue_id}")
        return self._issues[issue_id]

    def _normalize_patch(self, patch: str) -> str:
        """Normalize a patch for comparison."""
        return hashlib.md5(patch.encode()).hexdigest()

    def get_issues(self, limit: int | None = None) -> list[Issue]:
        """Get issues from the SWE-bench dataset.

        Args:
            limit: Maximum number of issues to return. None returns all.

        Returns:
            List of Issue objects.
        """
        issues = list(self._issues.values())
        if limit is not None:
            issues = issues[:limit]
        return issues

    def get_testbed_env(self, issue_id: str) -> Testbed:
        """Get the testbed environment for an issue.

        Args:
            issue_id: The issue identifier.

        Returns:
            Testbed object for the issue.

        Raises:
            ValueError: If the issue is not found.
        """
        self._get_issue(issue_id)
        if issue_id not in self._testbeds:
            temp_dir = tempfile.mkdtemp(prefix=f"swe-bench-{issue_id}-")
            self._testbeds[issue_id] = Testbed(issue_id=issue_id, env_path=temp_dir)
        return self._testbeds[issue_id]

    def evaluate_patch(self, issue_id: str, generated_patch: str) -> PatchEvalResult:
        """Evaluate a generated patch against the gold standard.

        Args:
            issue_id: The issue identifier.
            generated_patch: The patch to evaluate.

        Returns:
            PatchEvalResult with evaluation outcome.

        Raises:
            ValueError: If the issue is not found.
        """
        issue = self._get_issue(issue_id)

        if not generated_patch or not generated_patch.strip():
            return PatchEvalResult(
                issue_id=issue_id,
                passed=False,
                test_results={"overall": "FAILED"},
            )

        normalized_generated = self._normalize_patch(generated_patch)
        normalized_gold = self._normalize_patch(issue.gold_patch)

        if normalized_generated == normalized_gold:
            return PatchEvalResult(
                issue_id=issue_id,
                passed=True,
                test_results={"overall": "PASSED"},
            )
        else:
            return PatchEvalResult(
                issue_id=issue_id,
                passed=False,
                test_results={"overall": "FAILED"},
            )
