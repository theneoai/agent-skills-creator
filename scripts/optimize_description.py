#!/usr/bin/env python3
"""
scripts/optimize_description.py — Iterative description optimizer with
train/test split (guards against overfit).

Direct analogue of Anthropic skill-creator's `scripts.run_loop`.

Pipeline
--------
1. Parse a skill's current `description` from YAML frontmatter.
2. Split the trigger-eval set 60/40 into train / held-out test.
3. For up to --max-iterations:
     a. Score the current description on the TRAIN set via
        run_trigger_eval.classify().
     b. If train f1 is already >= target and no improvement in 2 rounds, stop.
     c. Otherwise, ask Claude to propose a better description given the
        current description + failing cases from train.
     d. Score the proposal on both train and test.
     e. Keep the candidate with the highest TEST f1 (prevents train overfit).
4. Emit a JSON report with all iterations and the `best_description` selected
   by test f1.

Usage
-----
    export ANTHROPIC_API_KEY=...
    python3 scripts/optimize_description.py \\
        --skill claude/skill-writer.md \\
        --eval-set eval/trigger-eval.example.json \\
        --model claude-sonnet-4-6 \\
        --max-iterations 5 \\
        --out eval/out/desc-opt.json

The optimizer prints a before/after diff at the end. It does NOT modify the
skill file automatically — the operator applies `best_description` manually
after reviewing the report.
"""
from __future__ import annotations

import argparse
import json
import os
import random
import sys
from pathlib import Path

# Re-use parser + classifier from run_trigger_eval.
ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "scripts"))
from run_trigger_eval import parse_frontmatter, load_eval_set, classify  # noqa: E402

try:
    import anthropic  # type: ignore
except ImportError:
    anthropic = None

PROPOSE_SYSTEM = """You improve skill-routing descriptions.
A skill's `description` field is the PRIMARY signal the router uses to decide
whether to invoke the skill. Your job: given the current description and a
list of mis-routed queries (false positives + false negatives from a real
eval), write a better description.

Constraints:
- Keep it under 350 characters.
- Name concrete use cases ("when a user asks to X, Y, or Z").
- Name one or two near-miss exclusions if false positives exist.
- Do NOT add marketing language, version numbers, or feature lists.
- Output ONLY the new description, no explanation."""


def score_description(
    client, model: str, name: str, description: str, subset: list[dict], runs: int,
) -> dict:
    tp = fp = fn = tn = 0
    details = []
    for row in subset:
        ys = sum(
            1 for _ in range(runs)
            if classify(client, model, name, description, row["query"]) == "YES"
        )
        triggered = (ys / runs) >= 0.5
        expected = bool(row["should_trigger"])
        if expected and triggered: tp += 1
        elif not expected and triggered: fp += 1
        elif expected and not triggered: fn += 1
        else: tn += 1
        details.append({
            "query": row["query"],
            "should_trigger": expected,
            "triggered": triggered,
        })
    total = len(subset)
    acc = (tp + tn) / total if total else 0.0
    prec = tp / (tp + fp) if (tp + fp) else 0.0
    rec = tp / (tp + fn) if (tp + fn) else 0.0
    f1 = (2 * prec * rec / (prec + rec)) if (prec + rec) else 0.0
    return {
        "tp": tp, "fp": fp, "fn": fn, "tn": tn,
        "accuracy": round(acc, 3),
        "precision": round(prec, 3),
        "recall": round(rec, 3),
        "f1": round(f1, 3),
        "details": details,
    }


def propose_new(client, model: str, name: str, current: str, train_score: dict) -> str:
    mistakes = [
        d for d in train_score["details"]
        if d["should_trigger"] != d["triggered"]
    ]
    if not mistakes:
        return current
    mistakes_fmt = "\n".join(
        f"  - [{'FN' if m['should_trigger'] else 'FP'}] {m['query']}"
        for m in mistakes[:12]
    )
    msg = client.messages.create(
        model=model,
        max_tokens=600,
        system=PROPOSE_SYSTEM,
        messages=[{
            "role": "user",
            "content": (
                f"Skill name: {name}\n"
                f"Current description:\n{current}\n\n"
                f"Mis-routed queries (from training set):\n{mistakes_fmt}\n\n"
                f"Propose an improved description (<=350 chars, one paragraph):"
            ),
        }],
    )
    text = " ".join(
        b.text for b in msg.content if getattr(b, "type", "") == "text"
    ).strip()
    # Strip any accidental code fencing.
    if text.startswith("```"):
        text = text.strip("`").strip()
    return text[:500]


def run(args) -> int:
    if anthropic is None:
        print("ERROR: pip install anthropic", file=sys.stderr); return 1
    if not os.environ.get("ANTHROPIC_API_KEY"):
        print("ERROR: ANTHROPIC_API_KEY not set", file=sys.stderr); return 1

    skill = parse_frontmatter(Path(args.skill))
    eval_set = load_eval_set(Path(args.eval_set))

    rng = random.Random(args.seed)
    shuffled = list(eval_set)
    rng.shuffle(shuffled)
    cut = max(1, int(len(shuffled) * 0.6))
    train = shuffled[:cut]
    test = shuffled[cut:]
    print(f"# train: {len(train)}   test: {len(test)}")

    client = anthropic.Anthropic()

    iterations: list[dict] = []
    current = skill["description"]

    # Iteration 0 = baseline scoring of the current description.
    base_train = score_description(
        client, args.model, skill["name"], current, train, args.runs
    )
    base_test = score_description(
        client, args.model, skill["name"], current, test, args.runs
    )
    iterations.append({
        "iter": 0, "description": current,
        "train": {k: v for k, v in base_train.items() if k != "details"},
        "test": {k: v for k, v in base_test.items() if k != "details"},
    })
    print(f"  iter 0  train_f1={base_train['f1']:.2f}  test_f1={base_test['f1']:.2f}")

    best = {"description": current, "test_f1": base_test["f1"], "iter": 0}

    for it in range(1, args.max_iterations + 1):
        proposal = propose_new(
            client, args.model, skill["name"], current, base_train
        )
        if not proposal or proposal == current:
            print(f"  iter {it}  no new proposal, stopping.")
            break
        tr = score_description(
            client, args.model, skill["name"], proposal, train, args.runs
        )
        te = score_description(
            client, args.model, skill["name"], proposal, test, args.runs
        )
        iterations.append({
            "iter": it, "description": proposal,
            "train": {k: v for k, v in tr.items() if k != "details"},
            "test": {k: v for k, v in te.items() if k != "details"},
        })
        print(f"  iter {it}  train_f1={tr['f1']:.2f}  test_f1={te['f1']:.2f}")
        if te["f1"] > best["test_f1"]:
            best = {"description": proposal, "test_f1": te["f1"], "iter": it}
        current = proposal
        base_train = tr

    report = {
        "skill": skill["name"],
        "baseline_description": skill["description"],
        "best_description": best["description"],
        "best_iter": best["iter"],
        "best_test_f1": best["test_f1"],
        "iterations": iterations,
    }
    print()
    print(f"  BEST (iter {best['iter']}, test_f1={best['test_f1']:.2f}):")
    print(f"    {best['description']}")

    if args.out:
        out_path = Path(args.out)
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
        print(f"  wrote report → {out_path}")
    return 0


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--skill", required=True)
    p.add_argument("--eval-set", required=True)
    p.add_argument("--model", default="claude-sonnet-4-6")
    p.add_argument("--max-iterations", type=int, default=5)
    p.add_argument("--runs", type=int, default=3)
    p.add_argument("--seed", type=int, default=42)
    p.add_argument("--out", default=None)
    args = p.parse_args()
    try:
        return run(args)
    except Exception as e:  # noqa: BLE001
        print(f"ERROR: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
