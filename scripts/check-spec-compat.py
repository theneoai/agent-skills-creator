#!/usr/bin/env python3
"""
scripts/check-spec-compat.py — Validate skill files against agentskills.io v1.0 spec.

Usage:
    python3 scripts/check-spec-compat.py                  # check all 8 platform files
    python3 scripts/check-spec-compat.py FILE [FILE...]   # check specific files
    python3 scripts/check-spec-compat.py --strict         # also require SHOULD fields

Checks:
  1. Required: `name` and `description` are present and non-empty.
  2. Namespace: every unknown top-level key starts with `x-` (per spec §4.2).
  3. Types:
     - name: kebab-case string
     - version: semver (MAJOR.MINOR.PATCH with optional pre-release)
     - license: SPDX id (small allowlist)
  4. Body length (warning): SKILL.md body SHOULD be under 500 lines
     (Anthropic skill authoring best practices).

Exits non-zero if any required check fails.

Called by: make check-spec-compat, .github/workflows/ci.yml
Spec source: https://agentskills.io/specification
"""

from __future__ import annotations

import os
import re
import sys
from pathlib import Path
from typing import Iterable

ROOT = Path(__file__).resolve().parent.parent

SPEC_REQUIRED = {"name", "description"}
SPEC_OPTIONAL = {
    "version", "license", "author", "homepage", "keywords",
    "spec_version",
}
SKILL_WRITER_EXTENSIONS = {
    "description_i18n", "skill_tier", "triggers", "interface", "extends",
    "graph", "use_to_evolve", "generation_method", "validation_status",
    "tags", "created", "updated", "type",
    # Lifecycle fields (v3.4.0)
    "lifecycle_status", "deprecated_at", "deprecation_reason", "replacement_skill",
    # Platform-specific metadata blocks
    "metadata",
    # Cursor MDC-specific
    "alwaysApply", "globs",
}
SPEC_ALLOWED = SPEC_REQUIRED | SPEC_OPTIONAL | SKILL_WRITER_EXTENSIONS

SPDX_ALLOWLIST = {
    "MIT", "Apache-2.0", "BSD-2-Clause", "BSD-3-Clause",
    "GPL-3.0", "LGPL-3.0", "MPL-2.0", "CC-BY-4.0", "ISC",
    "Unlicense", "Proprietary",
}

SEMVER_RE = re.compile(
    r"^\d+\.\d+\.\d+(?:-[0-9A-Za-z\-.]+)?(?:\+[0-9A-Za-z\-.]+)?$"
)
KEBAB_RE = re.compile(r"^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$")

MAX_BODY_LINES = 500  # Anthropic skill authoring best practice


class Issue:
    def __init__(self, path: str, level: str, msg: str) -> None:
        self.path, self.level, self.msg = path, level, msg

    def __str__(self) -> str:
        marker = {"error": "✗", "warn": "⚠", "info": "ℹ"}[self.level]
        return f"  {marker} {self.path}: {self.msg}"


def extract_frontmatter(content: str, is_mdc: bool = False) -> tuple[dict, int]:
    """Extract YAML frontmatter as a shallow dict of top-level keys only.
    Returns (keys_dict, body_line_count). Values are left as strings (stripped).

    For Cursor .mdc files, skip the first (MDC header) frontmatter block and parse
    the second (skill) frontmatter. Otherwise parse the first block.
    """
    lines = content.splitlines()
    if not lines or lines[0].strip() != "---":
        return {}, len(lines)

    # Locate first closing ---
    first_end = None
    for i in range(1, len(lines)):
        if lines[i].strip() == "---":
            first_end = i
            break
    if first_end is None:
        return {}, len(lines)

    fm_start = 1
    fm_end = first_end

    if is_mdc:
        # Look for a second frontmatter block after the MDC header
        j = first_end + 1
        while j < len(lines) and not lines[j].strip():
            j += 1
        if j < len(lines) and lines[j].strip() == "---":
            second_end = None
            for k in range(j + 1, len(lines)):
                if lines[k].strip() == "---":
                    second_end = k
                    break
            if second_end is not None:
                fm_start = j + 1
                fm_end = second_end

    keys: dict[str, str] = {}
    for line in lines[fm_start:fm_end]:
        if not line or line.startswith(" ") or line.startswith("\t") or line.startswith("#"):
            continue
        m = re.match(r"^([A-Za-z_][A-Za-z0-9_\-]*)\s*:\s*(.*)$", line)
        if m:
            keys[m.group(1)] = m.group(2).strip().strip('"').strip("'")

    body_line_count = len(lines) - fm_end - 1
    return keys, body_line_count


def check_file(path: Path, strict: bool = False) -> list[Issue]:
    rel = str(path.relative_to(ROOT)) if path.is_absolute() else str(path)
    try:
        content = path.read_text(encoding="utf-8")
    except OSError as e:
        return [Issue(rel, "error", f"cannot read: {e}")]

    is_mdc = str(path).endswith(".mdc")
    keys, body_lines = extract_frontmatter(content, is_mdc=is_mdc)
    issues: list[Issue] = []

    # 1. Required presence
    for req in SPEC_REQUIRED:
        if req not in keys or not keys[req]:
            issues.append(Issue(rel, "error", f"missing required field '{req}'"))

    # 2. Namespace check
    for k in keys:
        if k in SPEC_ALLOWED:
            continue
        if k.startswith("x-"):
            continue
        issues.append(Issue(
            rel, "error",
            f"unknown top-level key '{k}' (must be spec-defined or start with 'x-')"
        ))

    # 3. Type checks
    if "name" in keys and keys["name"] and not KEBAB_RE.match(keys["name"]):
        issues.append(Issue(
            rel, "error",
            f"'name' must be kebab-case, got {keys['name']!r}"
        ))

    if "version" in keys and keys["version"] and not SEMVER_RE.match(keys["version"]):
        issues.append(Issue(
            rel, "error",
            f"'version' must be semver, got {keys['version']!r}"
        ))

    if "license" in keys and keys["license"] and keys["license"] not in SPDX_ALLOWLIST:
        issues.append(Issue(
            rel, "warn",
            f"'license' {keys['license']!r} is not in the SPDX allowlist"
        ))

    # 4. Body length (warning only)
    if body_lines > MAX_BODY_LINES:
        issues.append(Issue(
            rel, "warn",
            f"body is {body_lines} lines; spec best-practice limit is {MAX_BODY_LINES}"
        ))

    # 5. Strict: SHOULD fields
    if strict:
        for rec in ("version", "license"):
            if rec not in keys:
                issues.append(Issue(rel, "warn", f"recommended field '{rec}' missing"))

    return issues


def iter_default_targets() -> Iterable[Path]:
    platforms = ["claude", "openclaw", "opencode", "gemini", "openai", "kimi", "hermes"]
    for p in platforms:
        f = ROOT / p / "skill-writer.md"
        if f.exists():
            yield f
    cursor = ROOT / "cursor" / "skill-writer.mdc"
    if cursor.exists():
        yield cursor


def main(argv: list[str]) -> int:
    strict = "--strict" in argv
    argv = [a for a in argv[1:] if a != "--strict"]

    targets: list[Path] = []
    if argv:
        targets = [Path(a) for a in argv]
    else:
        targets = list(iter_default_targets())

    if not targets:
        print("  ✗ no skill files found to check", file=sys.stderr)
        return 1

    errors = warns = 0
    for t in targets:
        issues = check_file(t, strict=strict)
        if not issues:
            print(f"  ✓ {t.relative_to(ROOT) if t.is_absolute() else t}: spec-compatible")
            continue
        for issue in issues:
            print(issue, file=sys.stderr if issue.level == "error" else sys.stdout)
            if issue.level == "error":
                errors += 1
            elif issue.level == "warn":
                warns += 1

    print()
    print(f"  summary: {errors} error(s), {warns} warning(s) across {len(targets)} file(s)")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
