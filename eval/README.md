# Evaluation

Two evaluation systems live here; pick the one that matches your goal.

## 1. Real eval pipeline (recommended — matches Anthropic skill-creator)

Runs **real API calls** against the model, not LLM self-scoring. Use this
whenever you want evidence that a skill's description actually routes user
intents correctly — not that a rubric thinks it does.

| Script | Purpose |
|--------|---------|
| `../scripts/run_trigger_eval.py` | Score a skill's description against a trigger-eval set; emit precision / recall / f1. |
| `../scripts/optimize_description.py` | Iteratively improve the description; 60/40 train/test split; picks best by test f1. |
| `../scripts/aggregate_benchmark.py` | Aggregate grader outputs into `benchmark.json` + `benchmark.md`. |
| `../agents/grader.md` | Independent grader prompt (run as subagent to break generator bias). |

Minimum input: an eval set like `trigger-eval.example.json` — a JSON array
of `{query, should_trigger}` pairs with ≥ 10 should-trigger and ≥ 10
should-not-trigger cases.

```bash
export ANTHROPIC_API_KEY=...
python3 scripts/run_trigger_eval.py \
    --skill claude/skill-writer.md \
    --eval-set eval/trigger-eval.example.json \
    --runs 3 --model claude-sonnet-4-6 \
    --out eval/out/trigger-report.json

python3 scripts/optimize_description.py \
    --skill claude/skill-writer.md \
    --eval-set eval/trigger-eval.example.json \
    --model claude-sonnet-4-6 \
    --max-iterations 5 \
    --out eval/out/desc-opt.json
```

The real pipeline is authoritative. It supersedes the rubric below for any
skill that will be shared, published, or relied on in production.

## 2. Rubric pipeline (legacy — LLM self-scoring)

| File | Purpose |
|------|---------|
| `rubrics.md` | 4-phase 1000-point rubric used by `/eval`. |
| `benchmarks.md` | Legacy benchmark harness spec. |

The rubric is useful as a lightweight sanity check during authoring but
does not break generator bias — the same LLM that wrote the skill evaluates
it. Treat rubric scores as advisory; require pipeline #1 before SHARE.
