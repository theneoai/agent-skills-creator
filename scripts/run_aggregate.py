#!/usr/bin/env python3
"""
scripts/run_aggregate.py — AGGREGATE pipeline: synthesize session artifacts into
ranked improvement recommendations for the OPTIMIZE loop.

Closes the collective evolution loop (COLLECT → AGGREGATE → OPTIMIZE) without
requiring any external backend infrastructure. Works with session artifacts
produced by COLLECT mode (saved to JSON files or exported from ute_gist_backend.py).

What it does:
  1. LOAD    — read N session artifact JSON files (schema_version 1.0 or 1.1)
  2. GROUP   — group by skill_name; warn if artifacts span multiple skills
  3. ANALYZE — compute: feedback_signal distribution, failure modes, trigger misses,
               dimension health trends, newly observed trigger phrases
  4. SYNTHESIZE — call Claude API to generate ranked improvement recommendations
                  from cross-session patterns (richer signal than single-session L1)
  5. REPORT  — output JSON + markdown recommendation report

Research basis:
  collective-evolution design (arxiv.org/abs/2604.08377) — collective evolution
  consistently outperforms single-user optimization; the artifact aggregation
  pipeline is the mechanism that makes this work.

Key Rule 4 (Trigger Discovery, refs/modes/mode-router.md):
  Observed `trigger_phrase_used` values that differ from canonical triggers
  are promoted to candidate trigger phrases in the AGGREGATE output.

Usage
-----
    export ANTHROPIC_API_KEY=...

    # Aggregate artifacts from a directory
    python3 scripts/run_aggregate.py --artifacts-dir artifacts/

    # Aggregate specific files
    python3 scripts/run_aggregate.py \\
        --artifacts artifacts/my-skill-artifact-001.json \\
                    artifacts/my-skill-artifact-002.json \\
                    artifacts/my-skill-artifact-003.json

    # Export from Gist backend first, then aggregate
    python3 scripts/ute_gist_backend.py export-artifacts --skill my-skill --out artifacts/
    python3 scripts/run_aggregate.py --artifacts-dir artifacts/

    # Dry-run (analyze without API synthesis call)
    python3 scripts/run_aggregate.py --artifacts-dir artifacts/ --dry-run

Output
------
    aggregate-out/
        aggregate-report.json     structured recommendations
        aggregate-report.md       human-readable improvement plan

Exit codes: 0 = report generated, 1 = error, 3 = too few artifacts (< 2)
"""
from __future__ import annotations

import argparse
import json
import sys
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any

from common import ApiClient, build_api_client, extract_json, DEFAULT_MODEL

MAX_TOKENS = 3000

DIMENSIONS = [
    "systemDesign", "domainKnowledge", "workflow",
    "errorHandling", "examples", "security", "metadata",
]

# Map numeric to label for older schema_version 1.0 artifacts
SIGNAL_MAP = {"approval": 1, "correction": -1, "rephrasing": 0, "abandon": 0, "neutral": 0}


# ── Artifact loading ──────────────────────────────────────────────────────────

def load_artifacts(paths: list[Path]) -> list[dict]:
    artifacts = []
    for p in paths:
        try:
            data = json.loads(p.read_text())
            # Support both single artifact and list of artifacts per file
            if isinstance(data, list):
                artifacts.extend(data)
            elif isinstance(data, dict):
                artifacts.append(data)
        except (json.JSONDecodeError, OSError) as e:
            print(f"  ⚠ Skipping {p.name}: {e}", file=sys.stderr)
    return artifacts


def discover_artifact_paths(artifacts_dir: Path) -> list[Path]:
    paths = sorted(artifacts_dir.glob("*artifact*.json"))
    if not paths:
        paths = sorted(artifacts_dir.glob("*.json"))
    return paths


# ── Statistical analysis (no API required) ───────────────────────────────────

def analyze_artifacts(artifacts: list[dict]) -> dict[str, Any]:
    """Compute all statistics that don't require an LLM call."""

    # Group by skill name
    by_skill: dict[str, list[dict]] = defaultdict(list)
    for a in artifacts:
        name = a.get("skill_name") or a.get("skill_id") or "unknown"
        by_skill[name].append(a)

    skill_names = list(by_skill.keys())

    # Use the most common skill if multiple present
    primary_skill = max(by_skill, key=lambda k: len(by_skill[k]))
    working_set = by_skill[primary_skill]

    n = len(working_set)

    # Feedback signal distribution
    signals = [a.get("feedback_signal", a.get("prm_signal", "neutral")) for a in working_set]
    signal_counts = Counter(signals)

    # Outcome distribution
    outcomes = [a.get("outcome", a.get("invocation_outcome", "ambiguous")) for a in working_set]
    outcome_counts = Counter(outcomes)
    success_rate = outcome_counts.get("success", 0) / n if n else 0

    # Trigger miss patterns: collect trigger phrases that differ from expected
    trigger_phrases = [
        a.get("trigger_used", a.get("trigger_phrase_used", ""))
        for a in working_set
        if a.get("trigger_used") or a.get("trigger_phrase_used")
    ]
    trigger_counter = Counter(tp for tp in trigger_phrases if tp)

    # Dimension health: aggregate observations
    dim_health: dict[str, Counter] = {d: Counter() for d in DIMENSIONS}
    for a in working_set:
        obs = a.get("dimension_observations", {})
        for dim in DIMENSIONS:
            val = obs.get(dim, "n/a")
            if val and val != "n/a":
                dim_health[dim][val] += 1

    # Dimension health score: strong=1, adequate=0.5, weak=0
    dim_scores: dict[str, float] = {}
    for dim in DIMENSIONS:
        counts = dim_health[dim]
        total = sum(counts.values())
        if total == 0:
            dim_scores[dim] = 0.5   # unknown
        else:
            score = (counts.get("strong", 0) * 1.0 + counts.get("adequate", 0) * 0.5) / total
            dim_scores[dim] = round(score, 2)

    # Weakest dimensions (those most needing improvement)
    weak_dims = sorted(
        [(d, s) for d, s in dim_scores.items()],
        key=lambda x: x[1]
    )

    # Improvement hints: collect and deduplicate
    all_hints: list[str] = []
    for a in working_set:
        hints = a.get("improvement_hints", [])
        all_hints.extend(hints)
    hint_counter = Counter(all_hints)
    top_hints = [h for h, _ in hint_counter.most_common(10)]

    # Notable patterns
    all_patterns: list[str] = []
    for a in working_set:
        patterns = a.get("notable_patterns", [])
        all_patterns.extend(patterns)
    pattern_counter = Counter(all_patterns)
    top_patterns = [p for p, _ in pattern_counter.most_common(5)]

    # Lessons
    lessons = [
        a.get("lesson_summary", "") for a in working_set
        if a.get("lesson_summary")
    ]

    # Failure modes: artifacts with outcome=failure or correction feedback
    failures = [
        a for a in working_set
        if a.get("outcome") in ("failure", "partial")
        or a.get("feedback_signal") == "correction"
        or a.get("prm_signal") == "poor"
    ]
    failure_rate = len(failures) / n if n else 0

    # New trigger candidates (Rule 4: Trigger Discovery)
    # Phrases used that appear ≥2 times may be strong candidates
    trigger_candidates = [
        {"phrase": phrase, "count": count}
        for phrase, count in trigger_counter.most_common(10)
        if count >= 2
    ]

    return {
        "primary_skill": primary_skill,
        "all_skills": skill_names,
        "multi_skill_warning": len(skill_names) > 1,
        "n_artifacts": n,
        "n_total_loaded": len(artifacts),
        "success_rate": round(success_rate, 2),
        "failure_rate": round(failure_rate, 2),
        "signal_counts": dict(signal_counts),
        "outcome_counts": dict(outcome_counts),
        "dim_health_counts": {d: dict(c) for d, c in dim_health.items()},
        "dim_scores": dim_scores,
        "weak_dims": weak_dims[:3],  # top 3 weakest
        "top_hints": top_hints,
        "top_patterns": top_patterns,
        "lessons": lessons,
        "trigger_candidates": trigger_candidates,
        "trigger_phrases_seen": dict(trigger_counter.most_common(20)),
    }


# ── LLM synthesis ─────────────────────────────────────────────────────────────

SYNTHESIZE_SYSTEM = """You are a skill optimization expert analyzing cross-session usage data.
Your role is to synthesize session artifact patterns into actionable improvement recommendations
for the skill-writer OPTIMIZE pipeline.

Return ONLY valid JSON with this structure:
{
  "executive_summary": "<2-3 sentences: what the data reveals, what's working, what's not>",
  "top_recommendations": [
    {
      "rank": 1,
      "target_strategy": "S4|S5|S1|S3|S7|S8|S9|S17",
      "target_dim": "workflow|errorHandling|metadata|...",
      "description": "<what to fix and why, grounded in the data>",
      "evidence": "<specific observations from the artifacts supporting this>",
      "estimated_impact": "high|medium|low"
    }
  ],
  "trigger_discovery": {
    "promote_to_canonical": ["<phrase1>", "<phrase2>"],
    "remove_or_narrow": ["<phrase that caused false triggers>"]
  },
  "negative_boundaries_to_add": ["<anti-case 1>", "<anti-case 2>"],
  "health_verdict": "HEALTHY|NEEDS_ATTENTION|AT_RISK",
  "next_action": "OPTIMIZE|BENCHMARK|EVALUATE|COLLECT_MORE"
}

Rules:
- top_recommendations: 3-5 items, ranked by estimated impact × frequency
- Each recommendation MUST cite concrete evidence from the artifact data
- target_strategy must be one of S1-S18 from optimize/strategies.md
- health_verdict: HEALTHY (success_rate ≥ 0.8), NEEDS_ATTENTION (0.6-0.8), AT_RISK (<0.6)
- next_action: if artifacts show clear failure pattern → OPTIMIZE; if unclear → COLLECT_MORE"""


def synthesize(api: ApiClient, stats: dict, lessons: list[str]) -> dict:
    """Use Claude to synthesize patterns into ranked recommendations."""
    dim_health_summary = "\n".join(
        f"  {d}: score={stats['dim_scores'][d]:.2f} — {stats['dim_health_counts'].get(d, {})}"
        for d in DIMENSIONS
    )
    lessons_text = "\n".join(f"  - {l}" for l in lessons[:5]) or "  (none)"
    hints_text = "\n".join(f"  - {h}" for h in stats["top_hints"][:5]) or "  (none)"
    patterns_text = "\n".join(f"  - {p}" for p in stats["top_patterns"][:5]) or "  (none)"

    trigger_text = "\n".join(
        f"  '{tc['phrase']}': {tc['count']}x"
        for tc in stats["trigger_candidates"][:10]
    ) or "  (none)"

    user_msg = f"""Cross-session artifact analysis for skill: {stats['primary_skill']}

USAGE STATISTICS:
  Total sessions analyzed: {stats['n_artifacts']}
  Success rate: {stats['success_rate']:.0%}
  Failure rate: {stats['failure_rate']:.0%}
  Feedback: {stats['signal_counts']}
  Outcomes: {stats['outcome_counts']}

DIMENSION HEALTH (score 0.0=weak, 1.0=strong):
{dim_health_summary}

WEAKEST DIMENSIONS (top 3):
{chr(10).join(f"  {i+1}. {d} (score: {s:.2f})" for i, (d, s) in enumerate(stats['weak_dims']))}

OBSERVED TRIGGER PHRASES (potential Rule 4 candidates):
{trigger_text}

RECURRING IMPROVEMENT HINTS:
{hints_text}

NOTABLE PATTERNS:
{patterns_text}

SESSION LESSONS:
{lessons_text}

Based on this data, produce ranked improvement recommendations as JSON."""

    try:
        raw = api.call(SYNTHESIZE_SYSTEM, user_msg, MAX_TOKENS)
    except Exception as e:
        return {"error": str(e)}

    data = extract_json(raw)
    if data is None:
        return {"error": "no JSON in response", "raw": raw[:500]}
    return data


# ── Report generation ─────────────────────────────────────────────────────────

def build_report(stats: dict, synthesis: dict, model: str = DEFAULT_MODEL) -> tuple[dict, str]:
    """Build the final JSON report and Markdown summary."""
    report = {
        "skill": stats["primary_skill"],
        "n_artifacts": stats["n_artifacts"],
        "generated_by": "run_aggregate.py",
        "model": model,
        "statistics": stats,
        "synthesis": synthesis,
    }

    recs = synthesis.get("top_recommendations", [])
    verdict = synthesis.get("health_verdict", "UNKNOWN")
    next_action = synthesis.get("next_action", "COLLECT_MORE")
    summary = synthesis.get("executive_summary", "(synthesis unavailable in dry-run)")

    verdict_icon = {"HEALTHY": "✓", "NEEDS_ATTENTION": "⚠", "AT_RISK": "🚨"}.get(verdict, "?")

    md = [
        f"# AGGREGATE Report — {stats['primary_skill']}",
        "",
        f"**Sessions analyzed**: {stats['n_artifacts']}  ",
        f"**Success rate**: {stats['success_rate']:.0%}  ",
        f"**Health verdict**: {verdict_icon} {verdict}  ",
        f"**Recommended next action**: {next_action}  ",
        "",
        "## Executive Summary",
        "",
        summary,
        "",
        "## Top Improvement Recommendations",
        "",
        "| Rank | Strategy | Dimension | Impact | Description |",
        "|------|----------|-----------|--------|-------------|",
    ]

    for r in recs:
        md.append(
            f"| {r.get('rank','?')} | {r.get('target_strategy','?')} "
            f"| {r.get('target_dim','?')} "
            f"| {r.get('estimated_impact','?')} "
            f"| {r.get('description','?')[:80]}… |"
        )

    if recs:
        md += ["", "### Evidence per recommendation", ""]
        for r in recs:
            md.append(f"**{r.get('rank')}. {r.get('description', '')}**")
            md.append(f"> Evidence: {r.get('evidence', 'N/A')}")
            md.append(f"> Apply: `/opt` with strategy `{r.get('target_strategy', 'Auto')}`")
            md.append("")

    # Trigger discovery (Rule 4)
    td = synthesis.get("trigger_discovery", {})
    promote = td.get("promote_to_canonical", [])
    if promote:
        md += [
            "## Trigger Discovery (Rule 4)",
            "",
            "These phrases were observed in real sessions — add to `triggers.en` in YAML:",
            "",
        ]
        for phrase in promote:
            md.append(f"- `{phrase}`")
        md.append("")

    # Negative boundaries
    nb = synthesis.get("negative_boundaries_to_add", [])
    if nb:
        md += ["## Suggested Negative Boundaries", ""]
        for b in nb:
            md.append(f"- {b}")
        md.append("")

    # Dimension health summary
    md += [
        "## Dimension Health",
        "",
        "| Dimension | Score | Trend |",
        "|-----------|-------|-------|",
    ]
    for dim, score in sorted(stats["dim_scores"].items(), key=lambda x: x[1]):
        bar = "█" * int(score * 10) + "░" * (10 - int(score * 10))
        trend = "⚠" if score < 0.5 else "✓"
        md.append(f"| {dim} | {score:.2f} {bar} | {trend} |")

    md += [
        "",
        "## Next Steps",
        "",
        f"1. Run `/opt` with the top recommendation: strategy `{recs[0].get('target_strategy', 'Auto') if recs else 'Auto'}`",
        f"2. After optimization → run `/eval` for authoritative score",
        f"3. {'Collect more sessions' if next_action == 'COLLECT_MORE' else 'Benchmark'} → continue `/collect` sessions",
        f"4. Add trigger candidates to YAML: {[p['phrase'] for p in stats['trigger_candidates'][:3]]}",
    ]

    return report, "\n".join(md)


def run_aggregate(
    artifact_paths: list[Path],
    out_dir: Path,
    dry_run: bool = False,
    model: str = DEFAULT_MODEL,
) -> int:
    print(f"\nAGGREGATE Pipeline — skill-writer collective evolution")
    print(f"  artifacts : {len(artifact_paths)} files")
    print(f"  output    : {out_dir}")

    artifacts = load_artifacts(artifact_paths)
    if len(artifacts) < 2:
        print(f"✗ Need at least 2 session artifacts. Found: {len(artifacts)}", file=sys.stderr)
        print("  Run COLLECT mode after more skill sessions, then retry.", file=sys.stderr)
        return 3

    print(f"  loaded    : {len(artifacts)} artifacts")

    stats = analyze_artifacts(artifacts)
    skill = stats["primary_skill"]
    print(f"  skill     : {skill}  ({stats['n_artifacts']} sessions)")

    if stats["multi_skill_warning"]:
        print(f"  ⚠ Multiple skills found: {stats['all_skills']}")
        print(f"  ⚠ Analysis restricted to most common: {skill}")

    print(f"  success   : {stats['success_rate']:.0%}  failure: {stats['failure_rate']:.0%}")
    print(f"  weakest   : {', '.join(d for d, _ in stats['weak_dims'])}")

    if dry_run:
        print("\n  [dry-run] skipping LLM synthesis")
        synthesis = {
            "executive_summary": "[dry-run — synthesis skipped]",
            "top_recommendations": [],
            "trigger_discovery": {"promote_to_canonical": [c["phrase"] for c in stats["trigger_candidates"][:3]]},
            "negative_boundaries_to_add": [],
            "health_verdict": "HEALTHY" if stats["success_rate"] >= 0.8 else "NEEDS_ATTENTION",
            "next_action": "OPTIMIZE" if stats["failure_rate"] > 0.2 else "COLLECT_MORE",
        }
    else:
        api = build_api_client(model=model)
        if api is None:
            return 1
        print("\n  Synthesizing recommendations via Claude API…")
        synthesis = synthesize(api, stats, stats["lessons"])
        if "error" in synthesis:
            print(f"  ⚠ Synthesis error: {synthesis['error']}", file=sys.stderr)
            return 1

    report, md = build_report(stats, synthesis, model=model)

    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "aggregate-report.json").write_text(json.dumps(report, indent=2))
    (out_dir / "aggregate-report.md").write_text(md)

    recs = synthesis.get("top_recommendations", [])
    verdict = synthesis.get("health_verdict", "UNKNOWN")
    next_action = synthesis.get("next_action", "?")

    icon = {"HEALTHY": "✓", "NEEDS_ATTENTION": "⚠", "AT_RISK": "🚨"}.get(verdict, "?")
    print(f"\n{'─'*55}")
    print(f"  Health: {icon} {verdict}  |  Next: {next_action}")
    if recs:
        print(f"\n  Top recommendations:")
        for r in recs[:3]:
            print(f"    {r.get('rank')}. [{r.get('target_strategy')}] {r.get('description', '')[:60]}…")

    trigger_promote = synthesis.get("trigger_discovery", {}).get("promote_to_canonical", [])
    if trigger_promote:
        print(f"\n  New trigger candidates (Rule 4): {trigger_promote[:3]}")

    print(f"\n  Report: {out_dir}/aggregate-report.md")
    print(f"  Next: run `/opt` with strategy {recs[0].get('target_strategy', 'Auto') if recs else 'Auto'}")
    print("─" * 55)

    return 0


def main() -> int:
    ap = argparse.ArgumentParser(
        description="AGGREGATE pipeline: synthesize session artifacts into OPTIMIZE recommendations"
    )
    group = ap.add_mutually_exclusive_group(required=True)
    group.add_argument("--artifacts", nargs="+", type=Path, metavar="FILE",
                       help="Individual artifact JSON files")
    group.add_argument("--artifacts-dir", type=Path, metavar="DIR",
                       help="Directory containing artifact JSON files")

    ap.add_argument("--out", type=Path, default=Path("aggregate-out"),
                    help="Output directory (default: aggregate-out/)")
    ap.add_argument("--dry-run", action="store_true",
                    help="Analyze only; skip LLM synthesis API call")
    ap.add_argument("--model", default=DEFAULT_MODEL,
                    help=f"Claude model to use (default: {DEFAULT_MODEL})")
    args = ap.parse_args()

    if args.artifacts_dir:
        paths = discover_artifact_paths(args.artifacts_dir)
        if not paths:
            print(f"✗ No artifact JSON files found in {args.artifacts_dir}", file=sys.stderr)
            return 1
        print(f"  Found {len(paths)} artifact files in {args.artifacts_dir}")
    else:
        paths = args.artifacts

    return run_aggregate(paths, args.out, args.dry_run, model=args.model)


if __name__ == "__main__":
    sys.exit(main())
