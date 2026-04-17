# Subagent Prompts

Prompt contracts for subagents invoked by `scripts/` and the `/eval` /
`/opt` modes. Each file is a standalone prompt — load it as a system prompt
when spawning a subagent.

| File | Purpose | Invoked by |
|------|---------|-----------|
| `grader.md` | Independent grader — returns structured verdicts for one test case | `scripts/run_trigger_eval.py`, `scripts/aggregate_benchmark.py`, `/eval` Phase 4 |

## Design principle

Subagents run in fresh context — they cannot see the generator's chain of
thought. This is the only mechanism in skill-writer that actually breaks
generator bias. Any prompt that is invoked through the Task tool (Claude
Code) or a fresh API call belongs in this directory.

Do **not** import this directory into the main skill body — it would defeat
the isolation guarantee.
