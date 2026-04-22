#!/usr/bin/env python3
"""
scripts/run_multi_eval.py — Statistical multi-run EVALUATE for high-confidence certification

Addresses the ±20–40 pt variance problem in single-run EVALUATE (Phase 3 is LLM-judged
and inherently variable). This script runs N independent evaluation passes on the same
skill, computes median + confidence interval, and provides a statistically-grounded
certification recommendation.

When to use vs. standard /eval:
  - Standard /eval: fast, adequate for BRONZE/SILVER decisions
  - run_multi_eval: use when targeting PLATINUM/GOLD where a ±30 pt swing changes tier

Statistical approach:
  - N=3 independent LLM evaluation calls (each treated as an independent judge)
  - Median score (robust to outliers) used for certification decision
  - Confidence interval: max-min spread across N runs
  - Per-dimension CV (coefficient of variation) to identify unreliable scores
  - Certification recommendation is conservative: uses median for tier, CI to flag
    borderline decisions (within 30 pts of a tier boundary)

Usage
-----
    export ANTHROPIC_API_KEY=...

    # Standard 3-run evaluation
    python3 scripts/run_multi_eval.py --skill my-skill.md

    # Higher confidence (5 runs, slower)
    python3 scripts/run_multi_eval.py --skill my-skill.md --runs 5

    # Specific output dir
    python3 scripts/run_multi_eval.py --skill my-skill.md --runs 3 --out eval/out/

    # Dry-run (no API calls)
    python3 scripts/run_multi_eval.py --skill my-skill.md --dry-run

Output
------
    eval/out/
        multi-eval-report.json    full statistical results
        multi-eval-report.md      human-readable summary

Exit codes:
  0 = certified (BRONZE or higher)
  1 = error
  2 = FAIL tier (score < 700)
  3 = BORDERLINE (within 30 pts of a tier boundary — review recommended)
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from statistics import median, stdev, mean

from common import ApiClient, build_api_client, extract_json, DEFAULT_MODEL

MAX_TOKENS = 2048

DIMENSIONS = [
    "d1_systemDesign",
    "d2_domainKnowledge",
    "d3_workflow",
    "d4_errorHandling",
    "d5_examples",
    "d6_security",
    "d7_metadata",
]

# Certification tiers (EVALUATE 1000-pt scale; LEAN 700-pt × 10/7 ≈ 1000-pt)
# We collect 7-dim scores (each 0-100), total max=700.
# Map to 1000-pt: total_700 × (1000/700) ≈ total_700 × 1.4286
TIER_THRESHOLDS_700 = {
    "PLATINUM": 665,   # ≈ 950/1000
    "GOLD":     630,   # ≈ 900/1000
    "SILVER":   560,   # ≈ 800/1000
    "BRONZE":   490,   # ≈ 700/1000
}
TIER_BORDER_MARGIN = 21   # within 21/700 ≈ 30/1000 pts = borderline


EVAL_SYSTEM = """You are an independent LEAN skill evaluator (run {run_n} of {total_runs}).
Score this SKILL.md on 7 dimensions (each 0–100) independently and objectively.
You have no knowledge of any prior evaluation of this skill.

Return ONLY valid JSON with this exact structure:
{{
  "d1_systemDesign":    <0-100>,
  "d2_domainKnowledge": <0-100>,
  "d3_workflow":        <0-100>,
  "d4_errorHandling":   <0-100>,
  "d5_examples":        <0-100>,
  "d6_security":        <0-100>,
  "d7_metadata":        <0-100>,
  "phase4_security_clear": <true|false>,
  "feedback": "<2-3 sentences: lowest dimension, specific gap, suggested fix>"
}}

Scoring rubric (0–100 per dimension):
d1 systemDesign:    Identity section present + specific, Red Lines ≥3 measurable prohibitions,
                    role hierarchy explicit, design patterns named
d2 domainKnowledge: Skill Summary encodes what/when/who/not-for in ≤5 dense sentences,
                    domain vocabulary depth, API/schema specificity
d3 workflow:        Phase/step table with exit criteria, loop gates, rollback paths, no vague steps
d4 errorHandling:   Recovery table ≥3 failure modes with trigger+action+escalation, retry logic
d5 examples:        ≥2 concrete examples with realistic INPUT→OUTPUT, bilingual where applicable
d6 security:        CWE-798/89/78 CLEAR, ASI01-ASI05 addressed, least-privilege documented
d7 metadata:        YAML complete (name/version/triggers/tags), ≥3 trigger phrases, negative boundaries"""


def single_eval(api: ApiClient, skill_content: str, run_n: int, total_runs: int) -> dict:
    """Run one independent evaluation pass. Returns scored dict."""
    system = EVAL_SYSTEM.format(run_n=run_n, total_runs=total_runs)
    user_msg = f"SKILL.md to evaluate:\n\n```\n{skill_content}\n```"
    raw = api.call(system, user_msg, MAX_TOKENS)

    data = extract_json(raw)
    if data is None:
        return {d: 50 for d in DIMENSIONS} | {"feedback": "parse error", "phase4_security_clear": False}
    try:
        result = {d: int(data.get(d, 50)) for d in DIMENSIONS}
        result["feedback"] = data.get("feedback", "")
        result["phase4_security_clear"] = bool(data.get("phase4_security_clear", True))
        return result
    except (TypeError, ValueError):
        return {d: 50 for d in DIMENSIONS} | {"feedback": "json parse error", "phase4_security_clear": False}


def compute_statistics(runs: list[dict]) -> dict:
    """Compute median, CI, and per-dimension CV across N runs."""
    stats = {}
    for dim in DIMENSIONS:
        vals = [r[dim] for r in runs]
        med = median(vals)
        ci_width = max(vals) - min(vals)
        cv = (stdev(vals) / mean(vals) * 100) if len(vals) > 1 and mean(vals) > 0 else 0.0
        stats[dim] = {
            "median": int(med),
            "mean": round(mean(vals), 1),
            "min": min(vals),
            "max": max(vals),
            "ci_width": ci_width,   # max-min spread
            "cv_pct": round(cv, 1),  # coefficient of variation %
            "high_variance": ci_width > 20,   # flag if spread >20 pts
        }

    total_vals = [sum(r[dim] for dim in DIMENSIONS) for r in runs]
    total_med = median(total_vals)
    stats["_total"] = {
        "median": int(total_med),
        "mean": round(mean(total_vals), 1),
        "min": min(total_vals),
        "max": max(total_vals),
        "ci_width": max(total_vals) - min(total_vals),
        "runs": total_vals,
    }
    return stats


def determine_tier(total_score_700: int) -> str:
    for tier, threshold in TIER_THRESHOLDS_700.items():
        if total_score_700 >= threshold:
            return tier
    return "FAIL"


def is_borderline(total_score_700: int) -> tuple[bool, str]:
    """Returns (is_borderline, nearest_boundary_name)."""
    for tier, threshold in TIER_THRESHOLDS_700.items():
        dist = abs(total_score_700 - threshold)
        if dist <= TIER_BORDER_MARGIN:
            return True, tier
    return False, ""


def run_multi_eval(
    skill_path: Path,
    out_dir: Path,
    n_runs: int = 3,
    dry_run: bool = False,
    model: str = DEFAULT_MODEL,
) -> int:
    print(f"\nMulti-Run Statistical EVALUATE — skill-writer")
    print(f"  skill  : {skill_path}")
    print(f"  runs   : {n_runs}")
    print(f"  output : {out_dir}")

    if not skill_path.exists():
        print(f"✗ skill not found: {skill_path}", file=sys.stderr)
        return 1

    if dry_run:
        print(f"\n  [dry-run] Would run {n_runs} independent LEAN evaluations using Claude API.")
        print(f"  [dry-run] Would compute: median score + CI + per-dim CV + tier recommendation.")
        print(f"  [dry-run] exiting without API calls")
        return 0

    api = build_api_client(model=model)
    if api is None:
        return 1

    skill_content = skill_path.read_text()
    out_dir.mkdir(parents=True, exist_ok=True)

    runs = []
    for i in range(1, n_runs + 1):
        print(f"\n  [Run {i}/{n_runs}] Evaluating…")
        result = single_eval(api, skill_content, i, n_runs)
        total = sum(result[d] for d in DIMENSIONS)
        result["_total"] = total
        runs.append(result)
        dim_line = "  ".join(f"{d.split('_')[0]}={result[d]}" for d in DIMENSIONS)
        print(f"    Total: {total}/700  |  {dim_line}")

    stats = compute_statistics(runs)
    median_total = stats["_total"]["median"]
    ci_total = stats["_total"]["ci_width"]
    est_eval_1000 = int(median_total * 1000 / 700)
    tier = determine_tier(median_total)
    borderline, border_tier = is_borderline(median_total)

    high_var_dims = [d for d in DIMENSIONS if stats[d]["high_variance"]]
    security_clear = all(r.get("phase4_security_clear", True) for r in runs)

    print(f"\n{'─'*55}")
    print(f"Statistical Results ({n_runs} runs)")
    print(f"  Median score : {median_total}/700  (CI: ±{ci_total//2} pts)")
    print(f"  Est. EVALUATE: ~{est_eval_1000}/1000 → {tier}")
    if borderline:
        print(f"  ⚠ BORDERLINE: within {TIER_BORDER_MARGIN}/700 pts of {border_tier} boundary")
    if high_var_dims:
        print(f"  ⚠ High-variance dimensions (CI > 20 pts): {', '.join(high_var_dims)}")
    print(f"{'─'*55}")

    # Per-dimension summary table
    print(f"\n  {'Dimension':<22} {'Median':>6} {'CI':>4} {'CV%':>5} {'Status':>10}")
    print(f"  {'─'*22} {'─'*6} {'─'*4} {'─'*5} {'─'*10}")
    for d in DIMENSIONS:
        s = stats[d]
        status = "⚠ NOISY" if s["high_variance"] else "OK"
        bar = "█" * (s["median"] // 10) + "░" * (10 - s["median"] // 10)
        print(f"  {d:<22} {s['median']:>6} {s['ci_width']:>4} {s['cv_pct']:>5.1f} {status:>10}")

    # Certification recommendation
    if tier == "FAIL":
        cert_recommendation = "FAIL — run /opt before re-evaluating"
        exit_code = 2
    elif borderline:
        cert_recommendation = f"BORDERLINE {tier} — run additional /eval pass to confirm"
        exit_code = 3
    else:
        cert_recommendation = f"CERTIFIED {tier} (statistical confidence: CI={ci_total} pts)"
        exit_code = 0

    print(f"\n  Recommendation: {cert_recommendation}")
    if not security_clear:
        print(f"  🚨 Security scan: P0 violation detected in ≥1 run — ABORT delivery")
        exit_code = 2

    # Save outputs
    report = {
        "skill": str(skill_path),
        "model": api.model,
        "n_runs": n_runs,
        "run_scores": [r["_total"] for r in runs],
        "median_total_700": median_total,
        "ci_width_700": ci_total,
        "est_evaluate_1000": est_eval_1000,
        "tier": tier,
        "borderline": borderline,
        "borderline_tier": border_tier if borderline else None,
        "high_variance_dims": high_var_dims,
        "security_clear": security_clear,
        "recommendation": cert_recommendation,
        "per_run_results": runs,
        "statistics": stats,
    }

    report_json = out_dir / "multi-eval-report.json"
    report_json.write_text(json.dumps(report, indent=2))

    md_lines = [
        "# Multi-Run Statistical EVALUATE Report",
        "",
        f"**Skill**: `{skill_path.name}`  ",
        f"**Runs**: {n_runs}  ",
        f"**Model**: {api.model}  ",
        "",
        "## Summary",
        "",
        f"| Metric | Value |",
        f"|--------|-------|",
        f"| Median score | {median_total}/700 |",
        f"| CI width | ±{ci_total // 2} pts (spread: {stats['_total']['min']}–{stats['_total']['max']}) |",
        f"| Est. EVALUATE | ~{est_eval_1000}/1000 |",
        f"| Tier | **{tier}** |",
        f"| Borderline | {'YES ⚠' if borderline else 'No'} |",
        f"| Security | {'CLEAR ✓' if security_clear else 'VIOLATION 🚨'} |",
        "",
        f"**Recommendation**: {cert_recommendation}",
        "",
        "## Per-Dimension Statistics",
        "",
        f"| Dimension | Median | CI | CV% | Status |",
        f"|-----------|--------|-----|-----|--------|",
    ]
    for d in DIMENSIONS:
        s = stats[d]
        status = "⚠ NOISY" if s["high_variance"] else "✓ OK"
        md_lines.append(f"| {d} | {s['median']}/100 | ±{s['ci_width']//2} | {s['cv_pct']:.1f}% | {status} |")

    md_lines += [
        "",
        "## Per-Run Scores",
        "",
        f"| Run | Score | {'  '.join(d.split('_')[0] for d in DIMENSIONS)} |",
        f"|-----|-------|{'|'.join(['------'] * len(DIMENSIONS))}|",
    ]
    for i, r in enumerate(runs, 1):
        dim_vals = "  ".join(str(r[d]) for d in DIMENSIONS)
        md_lines.append(f"| {i} | {r['_total']}/700 | {dim_vals} |")

    md_lines += [
        "",
        "## Interpretation Guide",
        "",
        "- **CI width ≤ 20 pts**: scores consistent — safe to certify at median tier",
        "- **CI width 20–40 pts**: moderate variance — use median tier but note uncertainty",
        "- **CI width > 40 pts**: high variance — manual review recommended before certification",
        "- **Borderline**: within 30/1000 pts of a tier boundary — run additional /eval pass",
        "- **Noisy dimension**: re-run /opt targeting that dimension, then re-evaluate",
    ]

    report_md = out_dir / "multi-eval-report.md"
    report_md.write_text("\n".join(md_lines))

    print(f"\n  Report JSON: {report_json}")
    print(f"  Report MD : {report_md}")

    return exit_code


def main() -> int:
    ap = argparse.ArgumentParser(
        description="Statistical multi-run EVALUATE for high-confidence skill certification"
    )
    ap.add_argument("--skill", type=Path, required=True, help="Path to SKILL.md")
    ap.add_argument("--runs", type=int, default=3,
                    help="Number of independent evaluation passes (default: 3)")
    ap.add_argument("--out", type=Path, default=Path("eval/out"),
                    help="Output directory (default: eval/out/)")
    ap.add_argument("--dry-run", action="store_true",
                    help="Print plan only; no API calls")
    ap.add_argument("--model", default=DEFAULT_MODEL,
                    help=f"Claude model to use (default: {DEFAULT_MODEL})")
    args = ap.parse_args()

    return run_multi_eval(
        skill_path=args.skill,
        out_dir=args.out,
        n_runs=args.runs,
        dry_run=args.dry_run,
        model=args.model,
    )


if __name__ == "__main__":
    sys.exit(main())
