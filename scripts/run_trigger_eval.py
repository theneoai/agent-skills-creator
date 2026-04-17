#!/usr/bin/env python3
"""
scripts/run_trigger_eval.py — Real trigger-accuracy eval for a skill's
description field.

What it does
------------
Given a skill file and a trigger-eval set (JSON list of should-trigger /
should-not-trigger queries), runs each query N times through the Anthropic API
and reports the fraction of runs where the skill "would have triggered".

Triggering signal: we prepend a system prompt that lists (name, description)
from the skill's frontmatter and asks the model to reply with exactly one token:
  YES  — this query should invoke the skill
  NO   — this query should not

Then we aggregate per-query, per-set, and compute accuracy/precision/recall.

This is the direct analogue of Anthropic skill-creator's `scripts.run_loop`
trigger evaluation — no rubric scoring, just real API calls.

Usage
-----
    export ANTHROPIC_API_KEY=...
    python3 scripts/run_trigger_eval.py \\
        --skill claude/skill-writer.md \\
        --eval-set eval/trigger-eval.example.json \\
        --runs 3 \\
        --model claude-sonnet-4-6 \\
        --out eval/out/trigger-report.json

Exit 0 on success; 1 on API/validation errors. Accuracy thresholds are
advisory — this script reports, it does not gate CI.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
import time
from pathlib import Path

try:
    import anthropic  # type: ignore
except ImportError:
    anthropic = None  # Deferred error — only needed if --dry-run not set.

SYSTEM_PROMPT = """You are a skill-routing classifier.
A "skill" is a specialized instruction module activated by user intent.
Given exactly one candidate skill (name + description) and a user message,
answer with a single token on a single line:

  YES   — the user message clearly matches the skill's purpose
  NO    — the user message does NOT match (ambiguous counts as NO)

No reasoning, no punctuation, no explanation. Just YES or NO."""

USER_TEMPLATE = """Candidate skill:
  name: {name}
  description: {description}

User message:
  {query}

Answer (YES or NO):"""


def parse_frontmatter(path: Path) -> dict:
    text = path.read_text(encoding="utf-8")
    # Walk through all leading --- blocks and pick the one that has both a
    # `name:` and a `description:`. Cursor .mdc files carry an outer MDC
    # wrapper block plus the canonical skill-writer block; we want the latter.
    candidates: list[str] = []
    cursor = 0
    while True:
        m = re.match(r"^---\n(.*?)\n---\n", text[cursor:], re.DOTALL)
        if not m:
            break
        candidates.append(m.group(1))
        cursor += m.end()
    if not candidates:
        raise ValueError(f"no YAML frontmatter in {path}")

    def extract(block: str) -> dict:
        out: dict = {}
        name_m = re.search(r'^name:\s*"?([^"\n]+)"?', block, re.MULTILINE)
        desc_m = re.search(r'^description:\s*"([^"]+)"', block, re.MULTILINE)
        if not desc_m:
            desc_m = re.search(
                r"^description:\s*(.+?)(?=\n[a-z_]+:)",
                block, re.MULTILINE | re.DOTALL,
            )
        if name_m:
            out["name"] = name_m.group(1).strip()
        if desc_m:
            out["description"] = desc_m.group(1).strip().replace("\n", " ")
        return out

    for block in candidates:
        parsed = extract(block)
        if "name" in parsed and "description" in parsed:
            return parsed
    raise ValueError(f"missing name or description in {path}")


def load_eval_set(path: Path) -> list[dict]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, list):
        raise ValueError(f"{path}: expected top-level JSON array")
    for i, row in enumerate(data):
        if not isinstance(row, dict) or "query" not in row or "should_trigger" not in row:
            raise ValueError(f"{path}[{i}]: missing query or should_trigger")
    return data


def classify(client, model: str, name: str, description: str, query: str) -> str:
    msg = client.messages.create(
        model=model,
        max_tokens=4,
        system=SYSTEM_PROMPT,
        messages=[
            {
                "role": "user",
                "content": USER_TEMPLATE.format(
                    name=name, description=description, query=query
                ),
            }
        ],
    )
    # Collect text content.
    parts = [b.text for b in msg.content if getattr(b, "type", "") == "text"]
    raw = " ".join(parts).strip().upper()
    if raw.startswith("YES"):
        return "YES"
    if raw.startswith("NO"):
        return "NO"
    return "UNKNOWN"


def run(args) -> int:
    skill = parse_frontmatter(Path(args.skill))
    eval_set = load_eval_set(Path(args.eval_set))

    if args.dry_run:
        print(f"# dry-run — {len(eval_set)} queries against {skill['name']}")
        for row in eval_set:
            print(f"  [{row['should_trigger']}] {row['query']}")
        return 0

    if anthropic is None:
        print("ERROR: `anthropic` package not installed. "
              "Install with: pip install anthropic", file=sys.stderr)
        return 1
    if not os.environ.get("ANTHROPIC_API_KEY"):
        print("ERROR: ANTHROPIC_API_KEY not set in environment.", file=sys.stderr)
        return 1

    client = anthropic.Anthropic()

    results: list[dict] = []
    for row in eval_set:
        runs: list[str] = []
        for _ in range(args.runs):
            try:
                runs.append(
                    classify(
                        client, args.model,
                        skill["name"], skill["description"], row["query"],
                    )
                )
            except Exception as e:  # noqa: BLE001
                runs.append(f"ERROR:{type(e).__name__}")
                time.sleep(1.0)
        triggered = sum(1 for r in runs if r == "YES")
        trigger_rate = triggered / args.runs
        expected = bool(row["should_trigger"])
        # Majority-vote verdict.
        got = trigger_rate >= 0.5
        correct = got == expected
        results.append({
            "query": row["query"],
            "should_trigger": expected,
            "runs": runs,
            "trigger_rate": trigger_rate,
            "verdict": "correct" if correct else "wrong",
        })
        marker = "✓" if correct else "✗"
        print(f"  {marker} [{expected!s:<5}] rate={trigger_rate:.2f}  {row['query'][:60]}")

    # Aggregate.
    tp = sum(1 for r in results if r["should_trigger"] and r["trigger_rate"] >= 0.5)
    fp = sum(1 for r in results if not r["should_trigger"] and r["trigger_rate"] >= 0.5)
    fn = sum(1 for r in results if r["should_trigger"] and r["trigger_rate"] < 0.5)
    tn = sum(1 for r in results if not r["should_trigger"] and r["trigger_rate"] < 0.5)
    total = len(results)
    accuracy = (tp + tn) / total if total else 0.0
    precision = tp / (tp + fp) if (tp + fp) else 0.0
    recall = tp / (tp + fn) if (tp + fn) else 0.0
    f1 = (2 * precision * recall / (precision + recall)) if (precision + recall) else 0.0

    report = {
        "skill": skill["name"],
        "description": skill["description"],
        "model": args.model,
        "runs_per_query": args.runs,
        "n_queries": total,
        "metrics": {
            "tp": tp, "fp": fp, "fn": fn, "tn": tn,
            "accuracy": round(accuracy, 3),
            "precision": round(precision, 3),
            "recall": round(recall, 3),
            "f1": round(f1, 3),
        },
        "results": results,
    }

    print()
    print(f"  accuracy={accuracy:.2f}  precision={precision:.2f}  "
          f"recall={recall:.2f}  f1={f1:.2f}")
    print(f"  (tp={tp} fp={fp} fn={fn} tn={tn})")

    if args.out:
        out_path = Path(args.out)
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
        print(f"  wrote report → {out_path}")
    return 0


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--skill", required=True, help="Path to skill .md file")
    p.add_argument("--eval-set", required=True,
                   help="JSON array of {query, should_trigger} entries")
    p.add_argument("--runs", type=int, default=3,
                   help="API calls per query for majority vote (default 3)")
    p.add_argument("--model", default="claude-sonnet-4-6")
    p.add_argument("--out", default=None, help="Write JSON report to this path")
    p.add_argument("--dry-run", action="store_true",
                   help="Print queries without calling API")
    args = p.parse_args()
    try:
        return run(args)
    except Exception as e:  # noqa: BLE001
        print(f"ERROR: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
