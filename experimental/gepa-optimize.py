#!/usr/bin/env python3
"""
scripts/gepa-optimize.py — Reflective prompt evolution for skill OPTIMIZE mode.

Status: SKELETON / ROADMAP v3.6.0
   This file is scaffolding. It documents the shape of the S15 strategy
   described in `optimize/strategies.md §4a`. The full GEPA integration
   requires optional dependencies (dspy, gepa) and runtime LM access.

Usage (future):
    python3 scripts/gepa-optimize.py SKILL.md
    python3 scripts/gepa-optimize.py --dry-run SKILL.md   # plan only, no calls

Design notes:
  - We deliberately keep this file runnable without dspy/gepa installed. When
    the user asks for real optimization, we detect missing deps and print an
    install hint.
  - Rollouts = EVALUATE invocations. Budget capped at 500 per run (GEPA paper
    reports SOTA with <500 rollouts).
  - Fitness = 7-dim vector (NOT scalar), preserved for Pareto selection.
  - Reflection step is an LM call that consumes up to 3 trajectory summaries
    and returns 3 concrete diff proposals.

References:
  - Agrawal et al. 2025, "GEPA: Reflective Prompt Evolution..." (arXiv 2507.19457)
  - https://dspy.ai/api/optimizers/GEPA/overview/
  - https://github.com/gepa-ai/gepa
"""

from __future__ import annotations

import argparse
import sys
from dataclasses import dataclass
from pathlib import Path


@dataclass
class SkillVariant:
    """One member of the evolutionary population."""
    content: str          # full SKILL.md content
    dim_scores: dict      # {D1..D8: int}  from EVALUATE Phase 2
    trace: str            # EVALUATE textual feedback (for reflection)
    lineage: list         # ancestor variant IDs (for debugging)

    @property
    def total(self) -> int:
        return sum(v for k, v in self.dim_scores.items() if k != "D8")


# ── Stage stubs (documentation of the pipeline) ──────────────────────────────

def stage_seed(base_skill: str, n: int = 3) -> list[SkillVariant]:
    """Stage 1: Initialize population with base skill + N perturbations.

    Perturbations apply one of S1/S3/S5 (expand triggers, refine domain
    language, tighten workflow) to produce diverse seeds.

    Planned implementation: call EVALUATE in --apply mode with one strategy
    per perturbation; collect resulting SKILL.md texts.
    """
    raise NotImplementedError("[ROADMAP v3.6.0] stage_seed")


def stage_evaluate(variants: list[SkillVariant]) -> list[SkillVariant]:
    """Stage 2: Run EVALUATE (Phase 2 + behavioral verifier) on every variant.
    Returns the same list with dim_scores + trace populated.
    """
    raise NotImplementedError("[ROADMAP v3.6.0] stage_evaluate")


def stage_reflect(variants: list[SkillVariant], k: int = 3) -> list[str]:
    """Stage 3: LM reflection turns trajectories into edit proposals.

    Prompt template (schematic):
        SYSTEM: You are optimizing a SKILL.md file. Consider these K trajectories.
        USER:   For each, the EVALUATE feedback was: {trace}. The lowest-scoring
                dimension was {min_dim}. Propose 3 concrete, single-paragraph
                edit candidates most likely to raise the minimum dimension
                WITHOUT reducing others. Return as JSON array.
    """
    raise NotImplementedError("[ROADMAP v3.6.0] stage_reflect")


def stage_crossover(variants: list[SkillVariant], edits: list[str], k: int = 5) -> list[SkillVariant]:
    """Stage 4: Produce K offspring by combining top edits across parents.
    Pareto-front parents preferred over single-dim winners.
    """
    raise NotImplementedError("[ROADMAP v3.6.0] stage_crossover")


def stage_select(population: list[SkillVariant], m: int = 3) -> list[SkillVariant]:
    """Stage 5: Keep top-M by total score, preserving 1 elite regardless."""
    raise NotImplementedError("[ROADMAP v3.6.0] stage_select")


def convergence_reached(history: list[list[SkillVariant]]) -> bool:
    """Stage 6 gate: re-uses `refs/convergence.md` three-signal algorithm
    (volatility, plateau, trend) applied to the best-of-generation curve.
    """
    raise NotImplementedError("[ROADMAP v3.6.0] convergence_reached")


def stage_verify(best: SkillVariant) -> SkillVariant:
    """Stage 7: Context-reset independent VERIFY identical to §2 step 10.
    Ensures the best variant doesn't owe its score to in-context bias.
    """
    raise NotImplementedError("[ROADMAP v3.6.0] stage_verify")


# ── Main (dry-run only today) ────────────────────────────────────────────────

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("skill", type=Path, help="Path to SKILL.md to optimize")
    ap.add_argument("--dry-run", action="store_true",
                    help="Print the plan without running rollouts")
    ap.add_argument("--rounds", type=int, default=10,
                    help="Max generations (default 10; paper suggests 5–20)")
    ap.add_argument("--population", type=int, default=5,
                    help="Population size per generation (default 5)")
    args = ap.parse_args()

    if not args.skill.exists():
        print(f"  ✗ skill not found: {args.skill}", file=sys.stderr)
        return 1

    have_dspy = _has_module("dspy")
    have_gepa = _has_module("gepa")
    have_deps = have_dspy and have_gepa

    print(f"  skill       : {args.skill}")
    print(f"  rounds      : {args.rounds}")
    print(f"  population  : {args.population}")
    print(f"  dspy        : {'✓' if have_dspy else '✗ (pip install dspy)'}")
    print(f"  gepa        : {'✓' if have_gepa else '✗ (pip install gepa)'}")
    print()

    print("  planned pipeline (v3.6.0):")
    print("    1. seed         — perturb base skill with S1/S3/S5 (×N)")
    print("    2. evaluate     — EVALUATE each variant (7-dim vector)")
    print("    3. reflect      — LM proposes 3 edits from trace+scores")
    print("    4. crossover    — produce K offspring from Pareto-front parents")
    print("    5. select       — keep top-M + 1 elite")
    print("    6. loop         — until convergence or budget exhausted")
    print("    7. verify       — context-reset independent validation")
    print()

    if args.dry_run:
        print("  [dry-run] — exiting without making LM calls")
        return 0

    if not have_deps:
        print("  ✗ required deps missing; cannot run live GEPA yet", file=sys.stderr)
        print("    this is expected in v3.5.0; integration lands in v3.6.0", file=sys.stderr)
        return 2

    print("  ✗ [ROADMAP v3.6.0] live GEPA integration not yet wired", file=sys.stderr)
    print("    see optimize/strategies.md §4a for the design", file=sys.stderr)
    return 2


def _has_module(name: str) -> bool:
    try:
        __import__(name)
        return True
    except ImportError:
        return False


if __name__ == "__main__":
    sys.exit(main())
