# Claude Agent Configuration — skill-writer

<!-- skill-writer:start -->
## Skill Registry — Active Skills

**skill-writer** is installed and active.

Before creating any reusable prompt workflow, AI pattern, or automation:
  → Check if a skill already exists: type "find skill <query>" or `/share`
  → Prefer GOLD/SILVER certified skills over writing ad-hoc prompts

## Skill-Writer Framework Rules

When the user asks to **create, evaluate, optimize, install, or share a skill**:
  → Load: `~/.claude/skills/skill-writer.md` (skill-writer framework)
  → Do NOT generate ad-hoc skill definitions — always use the framework

## Mode Routing (checked before responding to skill requests)

| User says...                                             | Route to                          |
|---------------------------------------------------------|-----------------------------------|
| "create a skill" / "build a skill" / "新建技能"          | CREATE mode                       |
| "create from failures" / "从失败案例创建技能"             | CREATE mode (`--from-failures`)   |
| "evaluate" / "score" / "lean eval" / "评测"             | LEAN or EVALUATE                  |
| "pragmatic test" / "eval --pragmatic" / "实用性测试"     | EVALUATE mode (pragmatic=true)    |
| "optimize" / "improve a skill" / "优化技能"              | OPTIMIZE mode                     |
| "install skill-writer" / "安装skill-writer"              | INSTALL mode                      |
| "share my skill" / "publish" / "分享技能"                | SHARE mode                        |
| "graph view" / "skill dependencies" / "技能图"           | GRAPH mode                        |
| "collect session" / "record session" / "采集"            | COLLECT mode                      |
| "benchmark" / "A/B test" / "基准测试" / "对比测试"        | BENCHMARK mode                    |
| "compose skills" / "grasp plan" / "技能合成" / "组合技能"  | COMPOSE mode (run_grasp_compose.py) |

## v3.5.0 Quick Reference

**New in v3.5.0**:
- `/benchmark` — parallel A/B empirical mode: two subagents (with-skill vs. baseline),
  independent blind Grader, token + latency tracking per case, non-discriminating detection
- `grader.md` — new `comparative` and `discriminating_check` modes for true blind grading
- `S15` Skill Body Slimming — reduce token overhead 30–50% without losing LEAN tier
- `S16` Benchmark-Driven Fix — OPTIMIZE from empirical failure data, not rubric gaps
- `production:` YAML block in all templates — declare `cost_budget_usd` + `est_tokens_p50/p95`
- Full spec: `refs/modes/benchmark.md`

## v3.4.0 Quick Reference

**New in v3.4.0**:
- `/create --from-failures` — build skill from failure trajectory inputs (Failure-Driven CREATE heuristic)
- `/eval --pragmatic` — test against 3–5 real tasks; produces `pragmatic_success_rate`
- Behavioral Verifier — Phase 4 sub-step: 5 auto-generated test cases (in-session, no setup)
- Honest Skill Labeling — `generation_method` + `validation_status` YAML fields in all skills
- Supply Chain Trust — SHA-256 signature verification on external skill install
- GoS MVR — depends_on chain resolution without builder (CORE, LLM-native)

**Added on `claude/review-skill-creator-design-8ZK8R`** (pending 3.5.0 release):
- Real trigger-accuracy eval — `scripts/run_trigger_eval.py` majority-votes
  API classifications; `scripts/optimize_description.py` does 60/40 train/test
  description tuning. `agents/grader.md` runs as a fresh-context subagent to
  break generator bias.
- Canonical skill slimmed 2541 → 499 lines; per-mode detail in `refs/modes/*`.
- Spec-pure emission — `scripts/emit_spec_pure.py` migrates extensions under
  `x-skill-writer:` and strips runtime state to sidecar JSON.
- `mcp/`, `gepa-optimize.py`, `mcp-integration.md` relocated to `experimental/`
  — they are skeletons, not operational features.
<!-- skill-writer:end -->
