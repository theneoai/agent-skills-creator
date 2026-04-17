#!/usr/bin/env python3
"""
sanitize_refs.py — Strip fake academic citations across the repo.

Background: v3.x docs referenced "arxiv:2603.xxxxx" / "arxiv:2604.xxxxx" papers
which do not exist (arxiv IDs encode year-month; those dates are in the future
relative to the referenced papers). Vendor-branded names (SkillRouter, SkillX,
SkillProbe, SkillForge, SkillNet, SkillClaw, SkillRL, EvoSkills, ToxicSkills,
ClawHavoc) were presented as prior work but are internal design heuristics.

This script rewrites those references to honest labels ("internal design
heuristic"). It preserves genuine references (agentskills.io, Anthropic's
public announcements, SKILL.md pattern).

Usage:
    python3 scripts/sanitize_refs.py            # dry-run (default)
    python3 scripts/sanitize_refs.py --apply    # write changes
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# Patterns to rewrite. Order matters — most specific first.
REPLACEMENTS: list[tuple[re.Pattern[str], str]] = [
    # Drop fake arxiv ids.
    (re.compile(r"\s*\(arxiv:260[0-9]\.[0-9]{4,5}\)"), ""),
    (re.compile(r"\s*arxiv:260[0-9]\.[0-9]{4,5}"), ""),
    # Vendor-branded "research names" → honest label.
    (re.compile(r"\bSkillRouter\b"), "Skill Summary heuristic"),
    (re.compile(r"\bSkillForge\b"), "Failure-Driven CREATE heuristic"),
    (re.compile(r"\bEvoSkills\b"), "co-evolutionary verifier heuristic"),
    (re.compile(r"\bSkillNet\b"), "typed-dependency Graph of Skills design"),
    (re.compile(r"\bSkillClaw\b"), "collective-evolution design"),
    (re.compile(r"\bSkillRL\b"), "reinforcement-style evolution design"),
    (re.compile(r"\bSkillProbe\b"), "Negative Boundaries heuristic"),
    (re.compile(r"\bSkillX\b"), "three-tier skill hierarchy"),
    (re.compile(r"\bToxicSkills\b"), "supply-chain threat model"),
    (re.compile(r"\bClawHavoc\b"), "supply-chain threat model"),
    # "Research basis" lines lose their authoritative ring.
    (re.compile(r"Research basis:", re.IGNORECASE), "Design heuristic:"),
    (re.compile(r"Research base:", re.IGNORECASE), "Design heuristic:"),
    # Specific made-up statistics that had no source.
    (re.compile(r"91\.7%\s*of\s*cross-encoder\s*attention"),
     "a large share of router attention (empirical, unpublished)"),
    (re.compile(r"degrades routing accuracy 29[-–]44pp"),
     "materially degrades routing accuracy (observed internally)"),
    (re.compile(r"26\.1%\s*of\s*public\s*skills\s*have\s*OWASP\s*vulnerabilities"),
     "a material fraction of public skills have OWASP vulnerabilities (industry audits)"),
    # Named paper titles in quotes → generic reference.
    (re.compile(r'"Skills in the Wild"'),
     "industry observations on unvalidated skills"),
]

# Files where references are code-like identifiers (do NOT rewrite).
SKIP_SUFFIXES = {".png", ".jpg", ".jpeg", ".svg", ".ico", ".pdf"}
SKIP_DIRS = {".git", "node_modules", "__pycache__"}


def should_process(path: Path) -> bool:
    if any(part in SKIP_DIRS for part in path.parts):
        return False
    if path.suffix in SKIP_SUFFIXES:
        return False
    if path == Path(__file__).resolve():
        return False
    return path.is_file()


def sanitize(content: str) -> tuple[str, int]:
    new = content
    hits = 0
    for pattern, replacement in REPLACEMENTS:
        new, n = pattern.subn(replacement, new)
        hits += n
    return new, hits


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--apply", action="store_true",
                        help="Write changes (default: dry-run)")
    parser.add_argument("--root", default=str(ROOT))
    args = parser.parse_args()

    root = Path(args.root).resolve()
    total_files = 0
    total_hits = 0

    for path in root.rglob("*"):
        if not should_process(path):
            continue
        try:
            original = path.read_text(encoding="utf-8")
        except (UnicodeDecodeError, PermissionError):
            continue
        new, hits = sanitize(original)
        if hits == 0 or new == original:
            continue
        total_files += 1
        total_hits += hits
        rel = path.relative_to(root)
        print(f"{'WRITE' if args.apply else 'DRY  '} {rel} ({hits} changes)")
        if args.apply:
            path.write_text(new, encoding="utf-8")

    print(f"\n{'Applied' if args.apply else 'Would change'}: "
          f"{total_hits} replacements across {total_files} files.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
