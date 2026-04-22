#!/usr/bin/env python3
"""
scripts/run_gepa_optimize.py — GEPA reflective evolutionary optimization for SKILL.md

Implements the S15 Reflective Prompt Evolution strategy using only the Anthropic API.
No dspy or gepa package required. Requires: pip install anthropic

Algorithm (Agrawal et al. 2025, arXiv 2507.19457 — adapted for skill optimization):
  1. Seed    — base skill + N perturbations (S1/S3/S5 strategy variants)
  2. Evaluate — 7-dim LEAN scoring + textual feedback per variant
  3. Reflect  — LM proposes 3 edit candidates from top-K trajectories
  4. Crossover— produce offspring by applying edits to Pareto-optimal parents
  5. Select   — keep top-M by total score, retain 1 elite
  6. Loop     — until convergence (plateau/volatility/budget exhausted)
  7. Verify   — context-reset independent LEAN pass on the best variant

Why GEPA over the standard 9-step loop (refs/modes/optimize.md):
  - Maintains a diverse population (escapes local optima)
  - Reflection step turns LM evaluation feedback into edit proposals
    (richer signal than pure scalar reward)
  - Pareto selection across 7 dimensions prevents single-dim over-optimization
  - Empirically converges to better final scores in ~1/3 the rollouts

Usage
-----
    export ANTHROPIC_API_KEY=...

    # Basic run
    python3 scripts/run_gepa_optimize.py --skill my-skill.md

    # With explicit options
    python3 scripts/run_gepa_optimize.py \\
        --skill my-skill.md \\
        --rounds 10 \\
        --population 5 \\
        --out gepa-output/

    # Dry-run (plan only, no API calls)
    python3 scripts/run_gepa_optimize.py --skill my-skill.md --dry-run

Output
------
    gepa-output/
        best-skill.md          best skill variant found
        gepa-report.json       full run metrics
        gepa-report.md         human-readable summary

Exit codes: 0 = improved, 1 = error, 3 = no improvement (score unchanged)
"""
from __future__ import annotations

import argparse
import json
import re
import sys
import uuid
from dataclasses import dataclass, field, asdict
from pathlib import Path
from typing import Optional

from common import ApiClient, build_api_client, extract_json, extract_json_array, DEFAULT_MODEL

# ── Scoring constants ──────────────────────────────────────────────────────────

MAX_TOKENS_EVAL = 1024
MAX_TOKENS_REFLECT = 2048
MAX_TOKENS_APPLY = 8192

DIMENSIONS = [
    "d1_systemDesign",
    "d2_domainKnowledge",
    "d3_workflow",
    "d4_errorHandling",
    "d5_examples",
    "d6_security",
    "d7_metadata",
]

# Convergence thresholds (mirrors refs/convergence.md)
PLATEAU_ROUNDS = 5          # stop if no net gain in this many consecutive rounds
VOLATILITY_THRESHOLD = 30   # stop if best-score swings ±this across 3 consecutive rounds
STABLE_DELTA_MIN = 5        # "stable" if gain is in [5, 10] for 3+ rounds


# ── Data model ────────────────────────────────────────────────────────────────

@dataclass
class SkillVariant:
    variant_id: str = field(default_factory=lambda: str(uuid.uuid4())[:8])
    content: str = ""
    dim_scores: dict = field(default_factory=dict)   # dim_name -> int (0–100)
    total_score: int = 0
    feedback: str = ""
    generation: int = 0
    lineage: list = field(default_factory=list)      # parent variant_ids

    @property
    def weakest_dim(self) -> str:
        if not self.dim_scores:
            return "d3_workflow"
        return min(self.dim_scores, key=lambda d: self.dim_scores[d])

    def pareto_dominates(self, other: "SkillVariant") -> bool:
        """True if self is at least as good as other on all dims and better on ≥1."""
        if not self.dim_scores or not other.dim_scores:
            return False
        at_least_as_good = all(
            self.dim_scores.get(d, 0) >= other.dim_scores.get(d, 0)
            for d in DIMENSIONS
        )
        strictly_better = any(
            self.dim_scores.get(d, 0) > other.dim_scores.get(d, 0)
            for d in DIMENSIONS
        )
        return at_least_as_good and strictly_better


# ── Stage 1: Seed ─────────────────────────────────────────────────────────────

SEED_SYSTEM = """You are a skill quality improver applying a single targeted strategy.
Apply ONLY the specified strategy—do not rewrite the whole skill.
Return the COMPLETE improved skill.md file with NO other commentary."""

SEED_STRATEGIES = {
    "S1_triggers": (
        "S1 — Expand Trigger Keywords: Add 3–5 new trigger phrases to the YAML "
        "`triggers.en` and `triggers.zh` fields. Add phrases users would realistically "
        "type to invoke this skill. Keep all existing triggers intact."
    ),
    "S3_domain": (
        "S3 — Deepen Domain Knowledge: Expand the domain-specific vocabulary, add one "
        "concrete field/schema reference, and ensure the Skill Summary encodes "
        "what/when/who/not-for in dense prose. Keep the skill under 500 lines."
    ),
    "S5_errors": (
        "S5 — Harden Error Handling: Add or expand the Error Handling section with "
        "an explicit recovery table covering at least 3 failure modes (trigger, action, "
        "recovery path). Add retry logic and escalation path."
    ),
}


def seed_population(api: ApiClient, base: SkillVariant, n_perturbations: int) -> list[SkillVariant]:
    """Generate base + N strategy-specific perturbations."""
    population = [base]
    strategies = list(SEED_STRATEGIES.items())[:n_perturbations]

    for strategy_key, strategy_desc in strategies:
        print(f"  ✦ Seeding variant: {strategy_key}…")
        user_msg = (
            f"Strategy to apply: {strategy_desc}\n\n"
            f"SKILL.md to improve:\n```\n{base.content}\n```\n\n"
            "Return the full improved skill.md with NO commentary."
        )
        try:
            new_content = api.call(SEED_SYSTEM, user_msg, MAX_TOKENS_APPLY)
            # Strip possible markdown fences
            new_content = re.sub(r"^```[a-z]*\n?", "", new_content, flags=re.MULTILINE)
            new_content = re.sub(r"\n?```$", "", new_content, flags=re.MULTILINE)
            variant = SkillVariant(
                content=new_content.strip(),
                generation=0,
                lineage=[base.variant_id],
            )
            variant.variant_id = f"seed-{strategy_key[:6]}"
            population.append(variant)
        except Exception as e:
            print(f"    ⚠ Seed {strategy_key} failed: {e}", file=sys.stderr)

    return population


# ── Stage 2: Evaluate ─────────────────────────────────────────────────────────

EVAL_SYSTEM = """You are a LEAN skill evaluator. Score the provided SKILL.md on 7 dimensions
(each 0–100). Be objective and precise. Return ONLY valid JSON with this exact structure:

{
  "d1_systemDesign":    <0-100>,
  "d2_domainKnowledge": <0-100>,
  "d3_workflow":        <0-100>,
  "d4_errorHandling":   <0-100>,
  "d5_examples":        <0-100>,
  "d6_security":        <0-100>,
  "d7_metadata":        <0-100>,
  "feedback": "<2-3 sentences identifying the weakest dimension and what specifically needs improving>"
}

Scoring guide (0–100 per dimension):
- d1 systemDesign:    Identity section clarity, Red Lines present and specific, role hierarchy
- d2 domainKnowledge: Domain vocabulary depth, Skill Summary quality (what/when/who/not-for)
- d3 workflow:        Phase table completeness, exit criteria, loop gates, rollback paths
- d4 errorHandling:   Recovery table (3+ failure modes), retry logic, escalation path
- d5 examples:        ≥2 concrete examples with input→output, bilingual if applicable
- d6 security:        CWE/OWASP ASI baseline present, no hardcoded credentials, least-privilege
- d7 metadata:        YAML frontmatter complete, ≥3 trigger phrases, negative boundaries"""


def evaluate_variant(api: ApiClient, variant: SkillVariant) -> SkillVariant:
    """Score all 7 LEAN dimensions and capture textual feedback."""
    user_msg = f"SKILL.md to evaluate:\n\n```\n{variant.content}\n```"
    # cache_system=True: EVAL_SYSTEM is identical on every call in the loop —
    # ephemeral cache cuts input-token cost on repeated evaluations.
    raw = api.call(EVAL_SYSTEM, user_msg, MAX_TOKENS_EVAL, cache_system=True)

    data = extract_json(raw)
    if data is None:
        print(f"    ⚠ No JSON in eval response for {variant.variant_id}", file=sys.stderr)
        variant.dim_scores = {d: 50 for d in DIMENSIONS}
        variant.total_score = 350
        variant.feedback = "Evaluation parse error — using default scores."
        return variant

    variant.dim_scores = {d: int(data.get(d, 50)) for d in DIMENSIONS}
    variant.total_score = sum(variant.dim_scores.values())
    variant.feedback = data.get("feedback", "")
    return variant


def evaluate_population(api: ApiClient, population: list[SkillVariant]) -> list[SkillVariant]:
    """Evaluate all unevaluated variants in the population."""
    for i, v in enumerate(population):
        if not v.dim_scores:
            print(f"  ↳ Evaluating variant {v.variant_id} ({i+1}/{len(population)})…")
            evaluate_variant(api, v)
            print(f"    score: {v.total_score}/700  weakest: {v.weakest_dim}")
    return population


# ── Stage 3: Reflect ──────────────────────────────────────────────────────────

REFLECT_SYSTEM = """You are an expert skill quality optimizer using reflective prompt evolution.
Given K skill variants with their evaluation scores and feedback, propose 3 concrete edit
candidates most likely to raise the weakest dimension WITHOUT degrading others.

Return ONLY valid JSON array:
[
  {
    "edit_id": "e1",
    "target_dim": "<dimension name>",
    "description": "<one sentence: what to change and why>",
    "patch": "<the exact text to ADD or REPLACE — must be specific, not placeholder>"
  },
  ...
]

Rules:
- Each edit must be atomic (single focused change, ≤3 lines)
- Each edit must target a specific section (e.g. "Add to Error Handling table:", "Replace Skill Summary with:")
- patch content must be concrete — no placeholders like "[your content here]"
- All 3 edits should target different root causes"""


def reflect(api: ApiClient, top_variants: list[SkillVariant]) -> list[dict]:
    """LM reflection: turn evaluation trajectories into edit proposals."""
    trajectories = []
    for v in top_variants:
        dim_str = "  ".join(f"{k}={val}" for k, val in v.dim_scores.items())
        trajectories.append(
            f"[Variant {v.variant_id}] total={v.total_score}/700\n"
            f"  scores: {dim_str}\n"
            f"  feedback: {v.feedback}\n"
            f"  weakest: {v.weakest_dim}\n"
            f"  content (first 400 chars): {v.content[:400]}…"
        )

    user_msg = (
        "Top skill variants with evaluation trajectories:\n\n"
        + "\n\n---\n\n".join(trajectories)
        + "\n\nPropose 3 concrete edit candidates as JSON."
    )
    raw = api.call(REFLECT_SYSTEM, user_msg, MAX_TOKENS_REFLECT)

    edits = extract_json_array(raw)
    if edits is None:
        return []
    return [e for e in edits if isinstance(e, dict) and "patch" in e]


# ── Stage 4: Crossover ────────────────────────────────────────────────────────

APPLY_SYSTEM = """You are a precise skill editor. Apply the specified edit to the provided SKILL.md.
Make ONLY the described change—do not rewrite other sections. Return the COMPLETE updated SKILL.md
with NO commentary before or after."""


def apply_edit(api: ApiClient, parent: SkillVariant, edit: dict, generation: int) -> Optional[SkillVariant]:
    """Apply a single edit proposal to a parent variant."""
    user_msg = (
        f"Edit to apply: {edit['description']}\n\n"
        f"Exact patch content:\n{edit['patch']}\n\n"
        f"SKILL.md to edit:\n```\n{parent.content}\n```\n\n"
        "Return the complete updated skill file."
    )
    try:
        new_content = api.call(APPLY_SYSTEM, user_msg, MAX_TOKENS_APPLY)
        new_content = re.sub(r"^```[a-z]*\n?", "", new_content, flags=re.MULTILINE)
        new_content = re.sub(r"\n?```$", "", new_content, flags=re.MULTILINE)
        child = SkillVariant(
            content=new_content.strip(),
            generation=generation,
            lineage=[parent.variant_id],
        )
        child.variant_id = f"g{generation}-{edit.get('edit_id', 'ex')[:4]}"
        return child
    except Exception as e:
        print(f"    ⚠ Apply edit failed: {e}", file=sys.stderr)
        return None


def crossover(
    api: ApiClient,
    top_parents: list[SkillVariant],
    edits: list[dict],
    generation: int,
    k: int = 5,
) -> list[SkillVariant]:
    """Apply edits to top parents, produce up to K offspring."""
    offspring = []
    for parent in top_parents[:2]:
        for edit in edits[:3]:
            child = apply_edit(api, parent, edit, generation)
            if child:
                offspring.append(child)
            if len(offspring) >= k:
                break
        if len(offspring) >= k:
            break
    return offspring


# ── Stage 5: Select ───────────────────────────────────────────────────────────

def select(population: list[SkillVariant], elite: SkillVariant, m: int = 3) -> list[SkillVariant]:
    """Keep top-M by total score + 1 elite; deduplicate by content hash."""
    seen = set()
    unique = []
    for v in sorted(population, key=lambda x: x.total_score, reverse=True):
        h = hash(v.content[:200])
        if h not in seen:
            seen.add(h)
            unique.append(v)

    top = unique[:m]
    # Ensure elite is always included
    elite_ids = {v.variant_id for v in top}
    if elite.variant_id not in elite_ids:
        top = top[: m - 1] + [elite]
    return top


# ── Stage 6: Convergence ──────────────────────────────────────────────────────

def check_convergence(score_history: list[int]) -> Optional[str]:
    """
    Three-signal convergence check (mirrors refs/convergence.md).
    Returns convergence reason string, or None to continue.
    """
    if len(score_history) < PLATEAU_ROUNDS:
        return None

    recent = score_history[-PLATEAU_ROUNDS:]
    net_change = recent[-1] - recent[0]
    if net_change == 0:
        return "PLATEAU"

    if len(score_history) >= 3:
        last3 = score_history[-3:]
        swings = [abs(last3[i + 1] - last3[i]) for i in range(2)]
        if all(s > VOLATILITY_THRESHOLD for s in swings):
            return "VOLATILITY"

    if len(score_history) >= 3:
        last3_deltas = [score_history[-3 + i + 1] - score_history[-3 + i] for i in range(2)]
        if all(STABLE_DELTA_MIN <= d <= 10 for d in last3_deltas):
            return "STABLE"

    return None


# ── Stage 7: Verify ───────────────────────────────────────────────────────────

VERIFY_SYSTEM = """You are a fresh-context LEAN evaluator. You have NO knowledge of any prior
optimization history. Score this SKILL.md as if you are seeing it for the first time.

Return ONLY valid JSON:
{
  "d1_systemDesign":    <0-100>,
  "d2_domainKnowledge": <0-100>,
  "d3_workflow":        <0-100>,
  "d4_errorHandling":   <0-100>,
  "d5_examples":        <0-100>,
  "d6_security":        <0-100>,
  "d7_metadata":        <0-100>,
  "feedback": "<2-3 sentence independent assessment>"
}"""


def verify(api: ApiClient, best: SkillVariant) -> dict:
    """Context-reset independent VERIFY pass (identical to optimize.md Step 10)."""
    print("\n  ── VERIFY (context-reset independent pass) ─────────────")
    user_msg = f"SKILL.md to evaluate independently:\n\n```\n{best.content}\n```"
    raw = api.call(VERIFY_SYSTEM, user_msg, MAX_TOKENS_EVAL)

    data = extract_json(raw)
    if data is None:
        return {"total": best.total_score, "status": "PARSE_ERROR"}

    scores = {d: int(data.get(d, 50)) for d in DIMENSIONS}
    verify_total = sum(scores.values())
    delta = abs(verify_total - best.total_score)

    if delta <= 20:
        status = "CONSISTENT"
    elif delta <= 50:
        status = "WARNING"
    else:
        status = "SUSPECT"

    print(f"  VERIFY: {verify_total}/700 | OPTIMIZE: {best.total_score}/700 | DELTA: {delta} | {status}")
    if status == "SUSPECT":
        print("  ⚠ Score inflation suspected — HUMAN_REVIEW recommended before registry push.")
    elif status == "WARNING":
        print("  ⚠ Minor discrepancy — review changed sections before certifying.")
    else:
        print("  ✓ Scores consistent — VERIFY result is the more conservative baseline.")

    return {
        "dim_scores": scores,
        "total": verify_total,
        "optimize_total": best.total_score,
        "delta": delta,
        "status": status,
        "feedback": data.get("feedback", ""),
    }


# ── Main loop ─────────────────────────────────────────────────────────────────

def run_gepa(
    skill_path: Path,
    out_dir: Path,
    rounds: int = 10,
    population_size: int = 5,
    dry_run: bool = False,
    model: str = DEFAULT_MODEL,
) -> int:
    """Main GEPA optimization loop. Returns exit code."""
    print(f"\nGEPA Reflective Optimizer — skill-writer S17")
    print(f"  skill      : {skill_path}")
    print(f"  rounds     : {rounds}")
    print(f"  population : {population_size}")
    print(f"  output     : {out_dir}")

    if not skill_path.exists():
        print(f"✗ skill not found: {skill_path}", file=sys.stderr)
        return 1

    if dry_run:
        print("\n  [dry-run] GEPA pipeline plan:")
        print("    1. seed         → perturb base skill with S1/S3/S5")
        print("    2. evaluate     → 7-dim LEAN scoring per variant")
        print("    3. reflect      → LM proposes 3 edits from trajectories")
        print("    4. crossover    → apply edits to Pareto-optimal parents")
        print("    5. select       → keep top-M + 1 elite")
        print("    6. loop         → until convergence or budget exhausted")
        print("    7. verify       → context-reset independent validation")
        print("\n  [dry-run] exiting without API calls")
        return 0

    api = build_api_client(model=model)
    if api is None:
        return 1

    out_dir.mkdir(parents=True, exist_ok=True)

    base_content = skill_path.read_text()
    base = SkillVariant(content=base_content, variant_id="base", generation=0)

    # ── Stage 1: Seed ──────────────────────────────────────────────────────────
    print(f"\n[Stage 1] Seeding population (base + {population_size - 1} perturbations)…")
    n_perturbations = min(population_size - 1, len(SEED_STRATEGIES))
    population = seed_population(api, base, n_perturbations)

    # ── Stage 2: Initial evaluation ────────────────────────────────────────────
    print(f"\n[Stage 2] Initial evaluation of {len(population)} variants…")
    population = evaluate_population(api, population)
    population.sort(key=lambda v: v.total_score, reverse=True)

    elite = population[0]
    start_score = population[0].total_score
    score_history = [start_score]
    run_log = []

    print(f"\n  Initial best: {elite.total_score}/700  (id: {elite.variant_id})")
    print(f"  {'─'*55}")

    # ── Main loop ──────────────────────────────────────────────────────────────
    stop_reason = "MAX_ROUNDS"
    for gen in range(1, rounds + 1):
        print(f"\n[Round {gen}/{rounds}]  best={elite.total_score}/700  weakest={elite.weakest_dim}")

        # Stage 3: Reflect
        top_k = population[:3]
        edits = reflect(api, top_k)
        if not edits:
            print("  ⚠ Reflection returned no edits — skipping crossover this round.")
            run_log.append({"gen": gen, "best": elite.total_score, "edits": 0, "offspring": 0})
            score_history.append(elite.total_score)
            reason = check_convergence(score_history)
            if reason:
                stop_reason = reason
                print(f"  ► Convergence: {reason}")
                break
            continue

        print(f"  ↳ Reflection produced {len(edits)} edit candidates")

        # Stage 4: Crossover
        pareto_parents = [v for v in population[:3] if not any(
            other.pareto_dominates(v) for other in population[:3] if other is not v
        )]
        if not pareto_parents:
            pareto_parents = population[:2]

        offspring = crossover(api, pareto_parents, edits, gen, k=population_size)
        print(f"  ↳ Crossover produced {len(offspring)} offspring")

        if not offspring:
            score_history.append(elite.total_score)
            run_log.append({"gen": gen, "best": elite.total_score, "edits": len(edits), "offspring": 0})
            continue

        # Evaluate offspring
        print(f"  ↳ Evaluating offspring…")
        offspring = evaluate_population(api, offspring)

        # Stage 5: Select
        combined = population + offspring
        population = select(combined, elite, m=population_size)
        new_best = max(population, key=lambda v: v.total_score)

        if new_best.total_score > elite.total_score:
            print(f"  ✓ New elite: {new_best.variant_id}  {elite.total_score} → {new_best.total_score} (+{new_best.total_score - elite.total_score})")
            elite = new_best
        else:
            print(f"  ─ No improvement this round (best: {elite.total_score})")

        score_history.append(elite.total_score)
        run_log.append({
            "gen": gen,
            "best": elite.total_score,
            "edits": len(edits),
            "offspring": len(offspring),
            "new_best": new_best.total_score > score_history[-2] if len(score_history) > 1 else False,
        })

        # Stage 6: Convergence check
        reason = check_convergence(score_history)
        if reason:
            stop_reason = reason
            print(f"\n  ► Convergence detected: {reason} — stopping early.")
            break

    # ── Stage 7: Verify ────────────────────────────────────────────────────────
    print("\n[Stage 7] Independent VERIFY pass…")
    verify_result = verify(api, elite)

    # ── Output ─────────────────────────────────────────────────────────────────
    best_file = out_dir / "best-skill.md"
    best_file.write_text(elite.content)

    net_delta = elite.total_score - start_score
    verify_score = verify_result.get("total", elite.total_score)
    verify_status = verify_result.get("status", "UNKNOWN")

    report = {
        "skill": str(skill_path),
        "model": api.model,
        "rounds_completed": len(run_log),
        "rounds_max": rounds,
        "population_size": population_size,
        "start_score": start_score,
        "final_score": elite.total_score,
        "verify_score": verify_score,
        "verify_status": verify_status,
        "net_delta": net_delta,
        "stop_reason": stop_reason,
        "score_history": score_history,
        "run_log": run_log,
        "elite_variant_id": elite.variant_id,
        "elite_lineage": elite.lineage,
        "best_dim_scores": elite.dim_scores,
        "verify_dim_scores": verify_result.get("dim_scores", {}),
        "verify_feedback": verify_result.get("feedback", ""),
    }

    report_json = out_dir / "gepa-report.json"
    report_json.write_text(json.dumps(report, indent=2))

    # Tier estimate (LEAN scale: 700 pts = 7 dims × 100)
    # Map to EVALUATE 1000-pt scale: lean × (1000/700) ≈ lean × 1.43
    est_eval = int(verify_score * 1000 / 700)
    if est_eval >= 950:
        tier = "PLATINUM"
    elif est_eval >= 900:
        tier = "GOLD"
    elif est_eval >= 800:
        tier = "SILVER"
    elif est_eval >= 700:
        tier = "BRONZE"
    else:
        tier = "FAIL"

    md_lines = [
        "# GEPA Optimization Report",
        "",
        f"**Skill**: `{skill_path.name}`  ",
        f"**Rounds**: {len(run_log)} / {rounds}  ",
        f"**Stop reason**: {stop_reason}  ",
        "",
        "## Score Summary",
        "",
        f"| Metric | Value |",
        f"|--------|-------|",
        f"| Starting score | {start_score}/700 |",
        f"| Final score (OPTIMIZE) | {elite.total_score}/700 |",
        f"| VERIFY score | {verify_score}/700 ({verify_status}) |",
        f"| Net delta | {net_delta:+d} pts |",
        f"| Est. EVALUATE | ~{est_eval}/1000 → **{tier}** |",
        "",
        "## Dimension Scores (VERIFY)",
        "",
        "| Dimension | Score |",
        "|-----------|-------|",
    ]
    for d, s in verify_result.get("dim_scores", elite.dim_scores).items():
        bar = "█" * (s // 10) + "░" * (10 - s // 10)
        md_lines.append(f"| {d} | {s}/100 {bar} |")

    md_lines += [
        "",
        "## VERIFY Feedback",
        "",
        verify_result.get("feedback", "N/A"),
        "",
        "## Next Steps",
        "",
        f"- `best-skill.md` contains the best variant found",
        f"- Run `/eval` for authoritative 1000-pt certification",
        f"- Run `/share` when ready to publish (requires BRONZE+ and `validation_status: full-eval`)",
        "",
        f"> VERIFY status {verify_status}: "
        + ("scores consistent ✓" if verify_status == "CONSISTENT"
           else "minor discrepancy — review before certifying ⚠" if verify_status == "WARNING"
           else "score inflation suspected — HUMAN_REVIEW required 🚨"),
    ]

    report_md = out_dir / "gepa-report.md"
    report_md.write_text("\n".join(md_lines))

    print("\n" + "─" * 57)
    print(f"GEPA Complete")
    print(f"  Rounds    : {len(run_log)} / {rounds}  (stop: {stop_reason})")
    print(f"  Score     : {start_score} → {elite.total_score} ({net_delta:+d})  |  VERIFY: {verify_score} ({verify_status})")
    print(f"  Est. EVAL : ~{est_eval}/1000 → {tier}")
    print(f"  Output    : {best_file}")
    print(f"  Report    : {report_json}")
    print("─" * 57)

    return 0 if net_delta > 0 else 3


# ── CLI ───────────────────────────────────────────────────────────────────────

def main() -> int:
    ap = argparse.ArgumentParser(
        description="GEPA reflective evolutionary optimizer for SKILL.md (S17 strategy)"
    )
    ap.add_argument("--skill", type=Path, required=True, help="Path to input SKILL.md")
    ap.add_argument("--rounds", type=int, default=10,
                    help="Max generations (default 10; paper recommends 5–20)")
    ap.add_argument("--population", type=int, default=5,
                    help="Population size per generation (default 5)")
    ap.add_argument("--out", type=Path, default=Path("gepa-output"),
                    help="Output directory (default: gepa-output/)")
    ap.add_argument("--dry-run", action="store_true",
                    help="Print plan only; no API calls")
    ap.add_argument("--model", default=DEFAULT_MODEL,
                    help=f"Claude model to use (default: {DEFAULT_MODEL})")
    args = ap.parse_args()

    return run_gepa(
        skill_path=args.skill,
        out_dir=args.out,
        rounds=args.rounds,
        population_size=args.population,
        dry_run=args.dry_run,
        model=args.model,
    )


if __name__ == "__main__":
    sys.exit(main())
