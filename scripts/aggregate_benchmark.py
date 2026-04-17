#!/usr/bin/env python3
"""
scripts/aggregate_benchmark.py — Aggregate grader outputs into a benchmark.

Reads one or more grader JSON files (schema: see agents/grader.md) and emits
a single `benchmark.json` + human-readable `benchmark.md` summary.

Usage
-----
    python3 scripts/aggregate_benchmark.py \\
        --inputs eval/out/tc-*.json \\
        --json-out eval/out/benchmark.json \\
        --md-out  eval/out/benchmark.md
"""
from __future__ import annotations

import argparse
import glob
import json
import sys
from pathlib import Path


def load_graders(paths: list[str]) -> list[dict]:
    files: list[str] = []
    for p in paths:
        files.extend(sorted(glob.glob(p)))
    out: list[dict] = []
    for f in files:
        try:
            out.append(json.loads(Path(f).read_text(encoding="utf-8")))
        except (OSError, json.JSONDecodeError) as e:
            print(f"  skip {f}: {e}", file=sys.stderr)
    return out


def aggregate(graders: list[dict]) -> dict:
    assertion_rows: list[dict] = []
    per_case: list[dict] = []
    for g in graders:
        case_pass = case_total = 0
        for e in g.get("expectations", []):
            case_total += 1
            case_pass += 1 if e.get("passed") else 0
            assertion_rows.append({
                "test_id": g.get("test_id"),
                "assertion": e.get("text"),
                "passed": bool(e.get("passed")),
                "evidence": e.get("evidence", ""),
            })
        per_case.append({
            "test_id": g.get("test_id"),
            "verdict": g.get("verdict"),
            "triggered": bool(g.get("triggered")),
            "assertions_passed": case_pass,
            "assertions_total": case_total,
            "notes": g.get("notes", ""),
        })
    total = len(assertion_rows)
    passed = sum(1 for r in assertion_rows if r["passed"])
    pass_rate = round(passed / total, 3) if total else 0.0
    verdicts = {"pass": 0, "partial": 0, "fail": 0}
    for c in per_case:
        v = c.get("verdict")
        if v in verdicts:
            verdicts[v] += 1
    return {
        "n_cases": len(per_case),
        "n_assertions": total,
        "assertions_passed": passed,
        "pass_rate": pass_rate,
        "case_verdicts": verdicts,
        "cases": per_case,
        "assertions": assertion_rows,
    }


def to_md(report: dict) -> str:
    lines = ["# Benchmark Summary", ""]
    lines.append(f"- Cases: **{report['n_cases']}**")
    lines.append(f"- Assertions: **{report['assertions_passed']} / {report['n_assertions']}** "
                 f"(pass rate {report['pass_rate']:.2%})")
    v = report["case_verdicts"]
    lines.append(f"- Verdicts: pass={v['pass']}  partial={v['partial']}  fail={v['fail']}")
    lines.append("")
    lines.append("## Cases")
    lines.append("")
    lines.append("| Test ID | Verdict | Triggered | Assertions | Notes |")
    lines.append("|---------|---------|-----------|------------|-------|")
    for c in report["cases"]:
        lines.append(
            f"| {c['test_id']} | {c['verdict']} | {c['triggered']} | "
            f"{c['assertions_passed']}/{c['assertions_total']} | {c['notes'][:60]} |"
        )
    return "\n".join(lines) + "\n"


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--inputs", nargs="+", required=True,
                   help="Grader JSON files (glob patterns accepted)")
    p.add_argument("--json-out", default=None)
    p.add_argument("--md-out", default=None)
    args = p.parse_args()

    graders = load_graders(args.inputs)
    if not graders:
        print("no grader files matched", file=sys.stderr)
        return 1

    report = aggregate(graders)

    if args.json_out:
        Path(args.json_out).parent.mkdir(parents=True, exist_ok=True)
        Path(args.json_out).write_text(
            json.dumps(report, indent=2), encoding="utf-8")
        print(f"wrote {args.json_out}")
    if args.md_out:
        Path(args.md_out).parent.mkdir(parents=True, exist_ok=True)
        Path(args.md_out).write_text(to_md(report), encoding="utf-8")
        print(f"wrote {args.md_out}")
    # Always print summary to stdout.
    print(f"  cases={report['n_cases']}  "
          f"pass_rate={report['pass_rate']:.2%}  "
          f"verdicts={report['case_verdicts']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
