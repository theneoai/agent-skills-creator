#!/usr/bin/env python3
"""
scripts/monitor_skill_drift.py — Skill health monitor: detects tier drift vs certified baseline.

Compares a skill's current LEAN score against its certified_lean_score in the YAML
frontmatter. Reports drift severity and recommends action. Integrates with the
UTE cadence system and GitHub Gist backend.

Use cases:
  - Run after `ute_gist_backend.py record` exits with code 2 (cadence event)
  - Schedule as a cron job for production skills (every N invocations)
  - Run before SHARE to confirm the skill hasn't degraded since last certification
  - CI gate to catch regressions introduced by manual edits

Drift thresholds (mirrors refs/use-to-evolve.md §4):
  OK       : drift  > -20 pts  (within expected LLM variance)
  WARNING  : drift -20 to -50 pts (re-evaluation recommended)
  DRIFT    : drift  < -50 pts  (likely tier change — re-certify required)

Usage
-----
    export ANTHROPIC_API_KEY=...

    # Basic drift check
    python3 scripts/monitor_skill_drift.py --skill my-skill.md

    # With Gist UTE state (reads cumulative_invocations + last_ute_check)
    export GITHUB_TOKEN=ghp_...
    python3 scripts/monitor_skill_drift.py --skill my-skill.md --gist-skill my-skill

    # Batch check all skills in a directory
    python3 scripts/monitor_skill_drift.py --skills-dir ~/.claude/skills/

    # Output JSON for machine consumption (CI)
    python3 scripts/monitor_skill_drift.py --skill my-skill.md --json

    # Dry-run (parse YAML only, no API call)
    python3 scripts/monitor_skill_drift.py --skill my-skill.md --dry-run

Exit codes:
  0 = OK (drift within normal range)
  1 = error
  2 = WARNING (drift -20 to -50 pts — re-evaluation recommended)
  3 = DRIFT (drift <= -50 pts — re-certification required)
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path

from common import ApiClient, build_api_client, extract_json, DEFAULT_MODEL

MAX_TOKENS = 1024

DRIFT_WARNING_THRESHOLD = -20
DRIFT_CRITICAL_THRESHOLD = -50

DIMENSIONS = [
    "d1_systemDesign", "d2_domainKnowledge", "d3_workflow",
    "d4_errorHandling", "d5_examples", "d6_security", "d7_metadata",
]

LEAN_SYSTEM = """You are a LEAN skill evaluator. Score this SKILL.md on 7 dimensions (each 0–100).
Return ONLY valid JSON:
{
  "d1_systemDesign":    <0-100>,
  "d2_domainKnowledge": <0-100>,
  "d3_workflow":        <0-100>,
  "d4_errorHandling":   <0-100>,
  "d5_examples":        <0-100>,
  "d6_security":        <0-100>,
  "d7_metadata":        <0-100>,
  "feedback": "<1-2 sentences on the weakest dimension>"
}"""


# ── YAML frontmatter parser (no PyYAML required) ──────────────────────────────

def parse_frontmatter(text: str) -> dict:
    """Extract key: value pairs from YAML frontmatter (--- ... ---). Best-effort."""
    fm_match = re.match(r"^---\s*\n([\s\S]*?)\n---\s*\n", text)
    if not fm_match:
        return {}
    fm_text = fm_match.group(1)
    result = {}
    for line in fm_text.splitlines():
        m = re.match(r"^(\w[\w_]*):\s*(.*)$", line)
        if m:
            key, val = m.group(1), m.group(2).strip().strip('"').strip("'")
            result[key] = val
    # Parse nested use_to_evolve block
    ute_block = re.search(r"use_to_evolve:\s*\n((?:  .+\n)*)", fm_text)
    if ute_block:
        ute_lines = ute_block.group(1)
        ute = {}
        for line in ute_lines.splitlines():
            m = re.match(r"^\s+(\w[\w_]*):\s*(.*)$", line)
            if m:
                k, v = m.group(1), m.group(2).strip().strip('"').strip("'")
                ute[k] = v
        result["use_to_evolve"] = ute
    return result


def _call_lean(api: ApiClient, skill_content: str) -> dict:
    # cache_system=True: LEAN_SYSTEM is identical for every skill in a batch check.
    try:
        raw = api.call(
            LEAN_SYSTEM,
            f"SKILL.md:\n```\n{skill_content}\n```",
            MAX_TOKENS,
            cache_system=True,
        )
    except Exception as e:
        return {"error": str(e)}

    data = extract_json(raw)
    return data if data is not None else {"error": "no JSON in response"}


# ── GitHub Gist state reader ──────────────────────────────────────────────────

def _read_gist_state(skill_name: str, token: str) -> dict | None:
    """Read UTE state from GitHub Gist (if available)."""
    try:
        import urllib.request
        headers = {
            "Authorization": f"Bearer {token}",
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
        }
        req = urllib.request.Request(
            "https://api.github.com/gists?per_page=100",
            headers=headers
        )
        with urllib.request.urlopen(req, timeout=10) as resp:
            gists = json.loads(resp.read().decode())

        target_desc = f"skill-writer UTE state: {skill_name}"
        for gist in gists:
            if gist.get("description", "") == target_desc:
                gist_id = gist["id"]
                req2 = urllib.request.Request(
                    f"https://api.github.com/gists/{gist_id}",
                    headers=headers
                )
                with urllib.request.urlopen(req2, timeout=10) as resp2:
                    full_gist = json.loads(resp2.read().decode())
                filename = f"{skill_name}-ute-state.json"
                content = full_gist.get("files", {}).get(filename, {}).get("content", "{}")
                return json.loads(content)
    except Exception as e:
        print(f"  ⚠ Gist state fetch failed: {e}", file=sys.stderr)
    return None


# ── Single skill check ────────────────────────────────────────────────────────

def check_skill(
    skill_path: Path,
    api: "ApiClient | None",
    gist_state: dict | None = None,
    dry_run: bool = False,
    as_json: bool = False,
) -> dict:
    text = skill_path.read_text()
    fm = parse_frontmatter(text)
    ute = fm.get("use_to_evolve", {})

    name = fm.get("name", skill_path.stem)
    version = fm.get("version", "unknown")
    skill_tier = fm.get("skill_tier", "functional")

    certified_lean_raw = ute.get("certified_lean_score") or fm.get("certified_lean_score")
    try:
        certified_lean = int(certified_lean_raw) if certified_lean_raw else None
    except (ValueError, TypeError):
        certified_lean = None

    validation_status = ute.get("validation_status", "unvalidated")
    generation_method = ute.get("generation_method", "unknown")
    last_check = ute.get("last_ute_check", "never")

    # Pull invocation count from Gist state if available
    cumulative_inv = None
    if gist_state:
        cumulative_inv = gist_state.get("cumulative_invocations")

    result: dict = {
        "skill": name,
        "path": str(skill_path),
        "version": version,
        "skill_tier": skill_tier,
        "generation_method": generation_method,
        "validation_status": validation_status,
        "certified_lean_score": certified_lean,
        "last_ute_check": last_check,
        "cumulative_invocations": cumulative_inv,
    }

    if dry_run or api is None:
        result["status"] = "DRY_RUN"
        result["current_lean"] = None
        result["drift"] = None
        result["recommendation"] = "Run without --dry-run to compute current LEAN score"
        return result

    # Run LEAN evaluation
    lean_result = _call_lean(api, text)
    if "error" in lean_result:
        result["status"] = "ERROR"
        result["error"] = lean_result["error"]
        return result

    dim_scores = {d: int(lean_result.get(d, 50)) for d in DIMENSIONS}
    current_lean = sum(dim_scores.values())
    result["current_lean"] = current_lean
    result["dim_scores"] = dim_scores
    result["feedback"] = lean_result.get("feedback", "")

    # Map 700-pt LEAN scale to 500-pt scale for comparison
    # (certified_lean_score uses 500-pt LEAN scale in YAML)
    # Convert: 700-pt = score × 500/700
    current_lean_500 = int(current_lean * 500 / 700)
    result["current_lean_500pt"] = current_lean_500

    if certified_lean is None:
        result["status"] = "NO_BASELINE"
        result["drift"] = None
        result["recommendation"] = (
            "No certified_lean_score in YAML. Run /eval to establish baseline."
        )
    else:
        drift = current_lean_500 - certified_lean
        result["drift"] = drift

        if drift <= DRIFT_CRITICAL_THRESHOLD:
            result["status"] = "DRIFT"
            result["recommendation"] = (
                f"Tier drift detected ({drift:+d} pts). Run /eval for full re-certification. "
                f"Then run /opt to recover quality."
            )
        elif drift <= DRIFT_WARNING_THRESHOLD:
            result["status"] = "WARNING"
            result["recommendation"] = (
                f"Moderate score drop ({drift:+d} pts). Re-evaluation recommended. "
                f"Run /eval or /lean to confirm."
            )
        else:
            result["status"] = "OK"
            result["recommendation"] = (
                f"Score consistent with baseline (drift: {drift:+d} pts). "
                f"No immediate action needed."
            )

    return result


def print_result(r: dict, as_json: bool = False) -> None:
    if as_json:
        print(json.dumps(r, indent=2))
        return

    icons = {"OK": "✓", "WARNING": "⚠", "DRIFT": "🚨", "NO_BASELINE": "ℹ", "DRY_RUN": "◌", "ERROR": "✗"}
    icon = icons.get(r.get("status", "?"), "?")
    drift = r.get("drift")
    drift_str = f" (drift: {drift:+d} pts)" if drift is not None else ""

    print(f"\n  {icon} {r['skill']} v{r['version']} [{r.get('status')}]{drift_str}")
    if r.get("current_lean"):
        print(f"    Current LEAN : {r['current_lean']}/700  ({r.get('current_lean_500pt')}/500)")
    if r.get("certified_lean_score"):
        print(f"    Certified    : {r['certified_lean_score']}/500")
    print(f"    Tier         : {r.get('skill_tier')}  |  Validation: {r.get('validation_status')}")
    if r.get("cumulative_invocations") is not None:
        print(f"    Invocations  : {r['cumulative_invocations']}")
    if r.get("feedback"):
        print(f"    Feedback     : {r['feedback']}")
    print(f"    → {r.get('recommendation', '')}")


# ── Main ──────────────────────────────────────────────────────────────────────

def main() -> int:
    ap = argparse.ArgumentParser(
        description="Monitor skill health: detect LEAN score drift vs certified baseline"
    )
    group = ap.add_mutually_exclusive_group(required=True)
    group.add_argument("--skill", type=Path, help="Single SKILL.md file to check")
    group.add_argument("--skills-dir", type=Path,
                       help="Directory of SKILL.md files — batch check all")

    ap.add_argument("--gist-skill", metavar="NAME",
                    help="Skill name in GitHub Gist UTE backend (reads cumulative_invocations)")
    ap.add_argument("--json", action="store_true", help="Output JSON (machine-readable)")
    ap.add_argument("--dry-run", action="store_true",
                    help="Parse YAML only; skip LEAN API call")
    ap.add_argument("--model", default=DEFAULT_MODEL, help=f"Claude model (default: {DEFAULT_MODEL})")
    args = ap.parse_args()

    api = build_api_client(model=args.model, dry_run=args.dry_run)

    # Gist state (optional)
    gist_state = None
    if args.gist_skill:
        token = os.environ.get("GITHUB_TOKEN")
        if token:
            gist_state = _read_gist_state(args.gist_skill, token)
            if gist_state:
                print(f"  ✓ Gist state loaded for '{args.gist_skill}'")
            else:
                print(f"  ⚠ No Gist state found for '{args.gist_skill}'", file=sys.stderr)

    # Collect skill paths
    if args.skill:
        paths = [args.skill]
    else:
        paths = sorted(args.skills_dir.glob("*.md"))
        if not paths:
            print(f"✗ No .md files found in {args.skills_dir}", file=sys.stderr)
            return 1
        print(f"  Batch checking {len(paths)} skills in {args.skills_dir}")

    results = []
    worst_exit = 0

    for path in paths:
        r = check_skill(path, api, gist_state, args.dry_run, args.json)
        results.append(r)
        print_result(r, as_json=args.json)

        status = r.get("status", "")
        if status == "DRIFT":
            worst_exit = max(worst_exit, 3)
        elif status == "WARNING":
            worst_exit = max(worst_exit, 2)
        elif status == "ERROR":
            worst_exit = max(worst_exit, 1)

    if not args.json and len(results) > 1:
        ok = sum(1 for r in results if r.get("status") == "OK")
        warn = sum(1 for r in results if r.get("status") == "WARNING")
        drift = sum(1 for r in results if r.get("status") == "DRIFT")
        print(f"\n  Summary: {ok} OK  {warn} WARNING  {drift} DRIFT  (of {len(results)} skills)")

    return worst_exit


if __name__ == "__main__":
    sys.exit(main())
