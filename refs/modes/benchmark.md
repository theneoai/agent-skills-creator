# BENCHMARK Mode

> **Version**: v3.5.0
> **Purpose**: Empirical skill validation via parallel A/B subagents — measures real
> performance delta (with-skill vs. baseline), token cost, and latency per test case.
> **Inspired by**: anthropic/skill-creator Benchmark mode (parallel Executor/Grader/Comparator
> architecture). This is skill-writer's equivalent, adapted for the full 8-platform ecosystem.
> **Load**: When user types `benchmark`, `run benchmark`, `A/B test`, `基准测试`, or `对比测试`.
> **Requires**: User-provided eval prompts (≥ 3 test cases). ANTHROPIC_API_KEY optional
> (needed for real parallel subagent execution; falls back to simulated mode).

---

## Why BENCHMARK?

EVALUATE scores are theoretical — the same LLM that generated the skill judges it,
creating generator bias. BENCHMARK eliminates this by running **two independent agents
in the same turn**:

- **Agent A (with-skill)**: Receives skill body in system prompt + user prompt
- **Agent B (baseline)**: Receives only the user prompt — no skill content

An independent **Grader** (`agents/grader.md`) evaluates both outputs blind
(it never sees which agent had the skill). The **delta** tells you what the skill
actually buys vs. a capable model without guidance.

> **Key insight (from skill-creator design)**: A skill that triples token cost but
> only improves pass rate by 5% is a different trade-off than one that cuts 20 tokens
> and doubles pass rate. BENCHMARK surfaces both numbers — EVALUATE shows neither.

---

## Modes

| Sub-mode | Trigger | Description |
|----------|---------|-------------|
| **QUICK** | `benchmark quick` / `快速基准` | 3–5 test cases, parallel A/B, no variance analysis |
| **FULL** | `benchmark` / `run benchmark` | 5–20 cases, statistical analysis, non-discriminating detection |
| **COMPARE** | `benchmark compare v1 v2` | A/B between two skill versions (no baseline) |
| **REPORT** | `benchmark report` | Re-analyze existing `benchmark.json` without re-running |

---

## Workflow (FULL mode — 7 steps)

```
Step 1  COLLECT EVAL PROMPTS
        User provides ≥ 3 test cases. Each case:
          - prompt: the user message to test
          - assertions: 1–3 expected behaviors (observable in output)
          - type: should-trigger | should-not-trigger | behavioral

Step 2  VALIDATE TEST QUALITY
        Before running: check for non-discriminating assertions (see §5).
        Warn if > 30% of assertions are likely non-discriminating.
        Suggest improvements before proceeding.

Step 3  PARALLEL A/B EXECUTION
        For each test case, spawn two subagents concurrently:
          Agent A (with-skill):   system_prompt = skill body; user_prompt = case.prompt
          Agent B (baseline):     system_prompt = empty / default; user_prompt = case.prompt
        Record for each:
          - output text
          - elapsed_ms (wall time from spawn to first token complete)
          - tokens_in / tokens_out (from API usage field)

Step 4  BLIND GRADING
        Pass each {with_skill_output, baseline_output, assertions} to Grader agent.
        Grader sees NEITHER the skill body NOR which output is A or B.
        Grader returns: {verdict: pass|partial|fail, assertion_results[], notes}
        for EACH output independently.

Step 5  COMPUTE METRICS
        per_case_results: array of {test_id, with_skill, baseline, delta}
        aggregate:
          pass_rate        = with_skill passes / total cases
          baseline_rate    = baseline passes / total cases
          delta_pass_rate  = pass_rate - baseline_rate
          avg_tokens_with  = mean(tokens_in + tokens_out) for Agent A
          avg_tokens_base  = mean(tokens_in + tokens_out) for Agent B
          token_overhead   = avg_tokens_with - avg_tokens_base
          avg_latency_with = mean(elapsed_ms) for Agent A
          avg_latency_base = mean(elapsed_ms) for Agent B
          variance         = stdev(per_case_delta_scores)

Step 6  NON-DISCRIMINATING DETECTION
        For each assertion, check if it passed in BOTH with-skill AND baseline runs.
        non_discriminating_rate = count(both_pass) / total_assertions
        If non_discriminating_rate > 0.40:
          WARNING: "X% of assertions pass regardless of skill — evals may not
          measure skill impact. Consider assertions that are specific to skill behavior."
        Flag individual assertions: {id, text, discriminating: false}

Step 7  REPORT + PERSIST
        Output benchmark report (see §4 Report Format).
        Write to: benchmarks/<ISO-timestamp>/benchmark.json  [EXTENDED]
        [CORE]: display JSON in conversation; ask user to save.
```

---

## Simulated Mode `[CORE]` — No API Key Required

When `ANTHROPIC_API_KEY` is unavailable, BENCHMARK falls back to **Simulated Mode**:

- Agent A (with-skill): AI predicts what a model following the skill instructions
  would output for each test case.
- Agent B (baseline): AI predicts what a model without the skill would output.
- Grader: runs in the same context but instructed to grade without referencing the skill.

Simulated mode still catches non-discriminating assertions and measures structural delta,
but token/latency data is estimated rather than measured. Reports are labeled
`"mode": "simulated"` to distinguish from real parallel execution.

> **When to use real mode**: Production certification, SHARE gate validation, or
> when the skill's behavior depends on external API calls or tool use.

---

## §4  Report Format

```json
{
  "skill": "<name>",
  "skill_version": "<semver>",
  "benchmark_version": "3.5.0",
  "timestamp": "<ISO-8601>",
  "mode": "real | simulated",
  "model": "claude-sonnet-4-6",

  "summary": {
    "total_cases": 10,
    "pass_rate": 0.80,
    "baseline_pass_rate": 0.55,
    "delta_pass_rate": 0.25,
    "avg_tokens_with_skill": 1840,
    "avg_tokens_baseline": 920,
    "token_overhead": 920,
    "token_overhead_pct": 100,
    "avg_latency_with_ms": 3200,
    "avg_latency_base_ms": 1800,
    "latency_overhead_ms": 1400,
    "non_discriminating_rate": 0.15,
    "variance": 0.12
  },

  "verdict": "BENCHMARK_PASS | BENCHMARK_MARGINAL | BENCHMARK_FAIL",
  "verdict_reason": "<human-readable explanation>",

  "per_case": [
    {
      "test_id": "tc-001",
      "prompt": "<user message>",
      "type": "should-trigger",
      "assertions": [
        {"id": "a1", "text": "...", "with_skill_pass": true,  "baseline_pass": false, "discriminating": true},
        {"id": "a2", "text": "...", "with_skill_pass": true,  "baseline_pass": true,  "discriminating": false}
      ],
      "with_skill": {
        "verdict": "pass",
        "tokens_in": 1200, "tokens_out": 340,
        "elapsed_ms": 3100
      },
      "baseline": {
        "verdict": "fail",
        "tokens_in": 280, "tokens_out": 410,
        "elapsed_ms": 1700
      },
      "delta": "POSITIVE"
    }
  ],

  "analysis": {
    "non_discriminating_assertions": [
      {"id": "a2", "text": "...", "note": "Passes in both — not measuring skill impact"}
    ],
    "high_variance_cases": [],
    "top_failure_modes": ["error_handling section not followed", "ZH trigger not matched"],
    "recommendations": [
      "Assertion a2 is non-discriminating — replace with skill-specific behavior check",
      "Case tc-007 baseline outperformed with-skill — possible token bloat in skill body"
    ]
  }
}
```

---

## §5  Verdict Thresholds

| Verdict | Condition | Meaning |
|---------|-----------|---------|
| **BENCHMARK_PASS** | delta_pass_rate ≥ 0.15 AND pass_rate ≥ 0.70 | Skill demonstrably improves outcomes |
| **BENCHMARK_MARGINAL** | 0.05 ≤ delta_pass_rate < 0.15 OR pass_rate 0.50–0.69 | Skill helps but impact is small; consider OPTIMIZE |
| **BENCHMARK_FAIL** | delta_pass_rate < 0.05 OR pass_rate < 0.50 | Skill provides no reliable benefit; do not SHARE |

> **Note**: A skill can score GOLD in EVALUATE (920/1000) but BENCHMARK_FAIL if its
> structured output doesn't actually improve real task completion. BENCHMARK_PASS is
> the stronger certification for production deployment.

### Token / Latency Trade-off Advisory

After computing delta, display trade-off assessment:

| delta_pass_rate | token_overhead_pct | Assessment |
|-----------------|-------------------|------------|
| ≥ 0.20 | ≤ 50% | ✅ HIGH VALUE — strong gain, low cost |
| ≥ 0.20 | 51–150% | ⚠ FAIR VALUE — strong gain, moderate cost |
| ≥ 0.20 | > 150% | ⚠ REVIEW — strong gain but high token cost; consider slimming skill |
| 0.05–0.19 | ≤ 50% | ✅ ACCEPTABLE — modest gain, low cost |
| 0.05–0.19 | > 50% | ⚠ MARGINAL — modest gain doesn't justify token overhead |
| < 0.05 | any | ❌ NOT WORTH IT — skill not earning its token cost |

---

## §6  Non-Discriminating Assertion Detection

An assertion is **non-discriminating** when it passes in ≥ 90% of both with-skill
and baseline runs — meaning it measures model capability, not skill impact.

**Common non-discriminating assertion patterns** (warn the user):
- "The response is in English" — baseline model already does this
- "The response is not empty" — trivially true
- "The response mentions the topic" — generic capability
- "The output is grammatically correct" — not skill-specific

**How to fix**: Replace with assertions specific to the skill's instructions:
- "The response uses the exact section headers defined in the skill's §3 Workflow"
- "The response includes a LEAN score formatted as `XXX/500`"
- "The response lists exactly 3 anti-cases as required by the skill's template"

---

## §7  COMPARE Sub-mode (Two Skill Versions)

`benchmark compare v1 v2` runs A/B between two versions of the same skill:

```
Agent A: skill v1 body in system prompt
Agent B: skill v2 body in system prompt
Grader: blind comparison — which output better satisfies the assertions?
```

Output includes:
- `version_a_pass_rate` vs `version_b_pass_rate`
- `winner`: "v1" | "v2" | "equivalent" (delta < 5%)
- `winner_reason`: which assertions flipped

Use after OPTIMIZE to confirm the new version is actually better before updating
`validation_status` to `full-eval`.

---

## §8  Integration with EVALUATE and OPTIMIZE

**After EVALUATE (recommended flow)**:
```
/eval         → theoretical score (1000-pt)
/benchmark    → empirical score (real A/B delta)
```
Both scores shown in SHARE report:
```
THEORETICAL:  920/1000 → GOLD        (structural quality)
BENCHMARK:    +0.25 delta, 80% pass  → BENCHMARK_PASS  (empirical utility)
```

**Before OPTIMIZE (feed failures)**:
```
/benchmark   → identify top_failure_modes
/opt --from-benchmark   → OPTIMIZE targets the empirically failing dimensions
                          (not just theoretically weak ones)
```

This ensures OPTIMIZE fixes real failures, not rubric gaps.

---

## §9  Triggers (EN/ZH)

```yaml
triggers:
  en:
    - "benchmark"
    - "run benchmark"
    - "A/B test this skill"
    - "empirical test"
    - "compare skill vs baseline"
    - "benchmark quick"
    - "benchmark compare"
  zh:
    - "基准测试"
    - "对比测试"
    - "A/B测试技能"
    - "实证测试"
    - "技能基准"
```

---

## §10  Relation to skill-creator's Benchmark

| Feature | skill-writer BENCHMARK | skill-creator Benchmark |
|---------|----------------------|------------------------|
| Parallel A/B | ✅ (real + simulated fallback) | ✅ (real only) |
| Independent Grader | ✅ grader.md subagent | ✅ Grader agent |
| Token tracking | ✅ tokens_in/out per case | ✅ |
| Latency tracking | ✅ elapsed_ms per case | ✅ |
| Non-discriminating detection | ✅ §6 | ✅ Analyzer checks |
| Cross-platform | ✅ 8 platforms | Claude Code only |
| Simulated fallback (no API key) | ✅ `[CORE]` | ❌ requires API |
| Version comparison | ✅ COMPARE sub-mode | ✅ Comparator agent |
| Variance analysis | ✅ stdev across cases | ✅ |
| Benchmark JSON persistence | ✅ `[EXTENDED]` / display `[CORE]` | ✅ always persists |
| OPTIMIZE integration | ✅ `--from-benchmark` flag | ✅ Analyzer → Improve |
