---
name: skill-writer
version: "3.5.1"
description: "Meta-skill framework: CREATE from templates, LEAN/EVALUATE/OPTIMIZE lifecycle, GRAPH mode for GoS bundle retrieval, COLLECT for collective skill evolution, Edit Audit Guard, Skill Registry v2.0 + Skill Summary heuristic weighted ranking, three-tier Hook routing layer (AGENTS.md + UserPromptSubmit Hook + triggers), Trigger Discovery pipeline, UTE 2.0 two-tier self-improvement, GEPA reflective evolutionary optimizer (S17), statistical multi-run EVALUATE (S18), GitHub Gist zero-infra UTE backend, and deploy to 8 platforms including MCP."
description_i18n:
  en: "Full lifecycle meta-skill framework: CREATE from templates (3-tier hierarchy, negative boundaries, Skill Summary, optional graph: block), LEAN fast-eval (500pt triage), EVALUATE 4-phase 1000pt pipeline + OWASP Agentic Top 10, OPTIMIZE 8-dim loop + S10/S11/S12 graph strategies + co-evolutionary VERIFY, GEPA reflective evolutionary optimizer (S17, scripts/run_gepa_optimize.py), statistical multi-run EVALUATE (S18, scripts/run_multi_eval.py), GitHub Gist zero-infra UTE backend (scripts/ute_gist_backend.py), GRAPH mode (GoS bundle retrieval, health checks, dependency resolution), COLLECT with bundle context for collective evolution, skill registry v2.0 + SHARE, three-tier Hook routing (AGENTS.md + UserPromptSubmit Hook + trigger phrases), Trigger Discovery pipeline (AGGREGATE Rule 4), UTE 2.0 L1/L2, deploy to 8 platforms."
  zh: "全生命周期元技能框架：支持可选graph:块的三层层级结构+负向边界+检索优化摘要的CREATE、LEAN快速评测（500分分诊）、OWASP Agentic Top 10安全检测的4阶段EVALUATE、含S10/S11/S12图策略+协同进化VERIFY的OPTIMIZE、GEPA反射进化优化器（S17，scripts/run_gepa_optimize.py）、统计多轮评测（S18，scripts/run_multi_eval.py）、GitHub Gist零基础设施UTE后端（scripts/ute_gist_backend.py）、GoS包检索+健康检查+依赖解析的GRAPH模式、含包上下文的COLLECT、技能注册表v2.0+共享、三层Hook路由（AGENTS.md+UserPromptSubmit Hook+触发词短语）、触发词发现流水线（AGGREGATE规则4）、UTE 2.0双层自进化、部署至8平台。"

license: MIT
author:
  name: theneoai
created: "2026-03-31"
updated: "2026-04-22"
type: meta-framework
skill_tier: planning

tags:
  - meta-skill
  - lifecycle
  - templates
  - evaluation
  - optimization
  - self-review
  - self-evolution

triggers:
  en:
    - "create a skill"
    - "evaluate this skill"
    - "optimize this skill"
    - "lean eval"
    - "install skill-writer"
    - "graph view"
    - "share my skill"
    - "collect session"
    - "benchmark"
    - "run benchmark"
    - "A/B test this skill"
    - "compose skills"
    - "grasp plan"
    - "build skill graph"
  zh:
    - "创建技能"
    - "评测技能"
    - "优化技能"
    - "安装skill-writer"
    - "技能图"
    - "基准测试"
    - "对比测试"
    - "技能合成"
    - "组合技能"

interface:
  input: user-natural-language
  output: structured-skill
  modes: [create, lean, evaluate, optimize, install, share, collect, graph, benchmark, compose]
  platforms: [claude, opencode, openclaw]

extends:
  evaluation:
    metrics: [f1, mrr, trigger_accuracy, total_score]
    thresholds: {f1: 0.90, mrr: 0.85, trigger_accuracy: 0.90, score_bronze: 700}
  certification:
    tiers: [PLATINUM, GOLD, SILVER, BRONZE, FAIL]
    variance_gates: {platinum: 10, gold: 15, silver: 20, bronze: 30}
  security:
    standard: CWE
    patterns: refs/security-patterns.md
    scan-on-delivery: true
  evolution:
    triggers: [threshold, time, usage]
    spec: refs/evolution.md
  self_review:
    spec: refs/self-review.md
  convergence:
    spec: refs/convergence.md

use_to_evolve:
  enabled: true
  injected_by: "skill-writer v3.4.0"
  injected_at: "2026-04-14"
  check_cadence: {lightweight: 10, full_recompute: 50, tier_drift: 100}
  micro_patch_enabled: true
  feedback_detection: true
  certified_lean_score: null
  last_ute_check: null
  pending_patches: 0
  total_micro_patches_applied: 0
  cumulative_invocations: 0
  generation_method: "human-authored"   # auto-generated | human-authored | hybrid
  validation_status: "full-eval"        # unvalidated | lean-only | full-eval | pragmatic-verified

lifecycle_status: "active"              # active | maintenance | deprecated | archived
deprecated_at: null
deprecation_reason: null
replacement_skill: null
---

<!-- PATH CONVENTION (Claude)
  Companion files are installed to ~/.claude/ by running: ./claude/install.sh
    refs/        →  ~/.claude/refs/         (on-demand specs incl. refs/modes/)
    templates/   →  ~/.claude/templates/
    eval/        →  ~/.claude/eval/         (incl. trigger-eval.example.json)
    optimize/    →  ~/.claude/optimize/
    scripts/     →  ~/.claude/scripts/      (real eval pipeline — see below)
    agents/      →  ~/.claude/agents/       (grader subagent prompt)

  Real eval pipeline (Bash-callable from any LLM session with tool access):
    scripts/run_trigger_eval.py       — trigger-accuracy eval (precision/recall/f1)
    scripts/optimize_description.py   — iterative description optimizer (60/40 train/test)
    scripts/run_benchmark.py          — parallel A/B benchmark (with-skill vs. baseline)
    scripts/aggregate_benchmark.py    — aggregate grader outputs to benchmark.json
    scripts/run_gepa_optimize.py      — GEPA reflective evolutionary optimizer (S17) [NEW v3.5.1]
    scripts/run_multi_eval.py         — statistical multi-run EVALUATE w/ CI (S18) [NEW v3.5.1]
    scripts/ute_gist_backend.py       — GitHub Gist zero-infra UTE L2 backend [NEW v3.5.1]
    scripts/skill_graph.py            — GoS typed DAG model + gRaSP precondition-effect layer [NEW v3.5.1]
    scripts/run_grasp_compose.py      — gRaSP 4-stage skill composition pipeline [NEW v3.5.1]
    scripts/emit_spec_pure.py         — emit agentskills.io v1.0 spec-pure frontmatter
    agents/grader.md                  — independent-grader prompt (spawn as subagent)
-->

## Skill Summary

skill-writer is a full-lifecycle meta-skill framework for AI assistants: it CREATEs
skills from typed templates, evaluates quality with a 1000-point pipeline, optimizes
through up to 20 iterative rounds, and self-evolves via the UTE protocol. Use it when
you need to create, certify, improve, or deploy a reusable AI skill for Claude,
OpenCode, or OpenClaw. Designed for developers and AI power users who want structured,
certifiable skill artifacts — not ad-hoc prompts. This skill does NOT handle one-off
questions, direct API calls, or non-skill automation tasks — see Negative Boundaries.

---

## §0  Quick Start — 5 Common Workflows

> **New here?** Pick your scenario below and follow the steps. Full documentation starts at §1.

| Goal | Command (EN) | 中文命令 (ZH) | Duration |
|------|-------------|--------------|----------|
| Create a new skill | `/create` + one-sentence description | `/创建` + 一句描述 | 2–5 min |
| Fast quality check | `/lean` + skill content | `/快评` + 技能内容 | <5s |
| Full certification | `/eval` + skill content | `/评测` + 技能内容 | ~60s |
| **High-confidence cert** | **`run_multi_eval.py --runs 3`** | **统计多轮评测** | **~3 min** |
| **Empirical A/B test** | **`/benchmark`** + skill + eval prompts | **`/基准测试`** + 技能 + 测试用例 | **2–10 min** |
| Improve an existing skill | `/opt` + skill + eval report | `/优化` + 技能 + 评测报告 | 5–20 min |
| **GEPA deep optimization** | **`run_gepa_optimize.py --skill <f>`** | **反射进化优化** | **10–30 min** |
| Deploy to platforms | `/install [platform]` | `/安装 [平台]` | <30s |
| Record session data | `/collect` | `/采集` | ~10s |
| **UTE cross-session tracking** | **`ute_gist_backend.py record`** | **跨会话追踪** | **<5s** |
| **gRaSP skill composition** | **`run_grasp_compose.py --objective "..."`** | **技能合成** | **~30s** |

> **双语支持 / Bilingual**: All 8 modes work in English and Chinese. The router auto-detects
> your language — use `/eval` or `评测`, `create a skill` or `创建新技能`, interchangeably.
> Cursor exception: use keyword phrases, not `/commands` (IDE intercepts `/` key).
> See §3 Mode Router for the full keyword list in both languages.

### Workflow F — "I want to empirically validate my skill (not just score it)"
1. Run `/benchmark` and provide 3–10 test prompts with expected behaviors
2. Two parallel subagents run (with-skill vs. baseline) — independent Grader evaluates blind
3. Review `delta_pass_rate` and `token_overhead_pct` — check for non-discriminating assertions
4. If BENCHMARK_FAIL: run `/opt --from-benchmark` to fix empirically failing dimensions
5. Re-run `/benchmark compare v_before v_after` to confirm improvement
6. Only proceed to SHARE when `delta_pass_rate ≥ 0.15`

> Full spec: [`refs/modes/benchmark.md`](../refs/modes/benchmark.md)

### Workflow A — "I want to create a new skill"
1. Type `/create` followed by a one-sentence description of what the skill should do
2. Answer the 8 elicitation questions (§8) one at a time
3. Receive the completed skill file with a LEAN score attached
4. LEAN ≥ 350 → ready to use immediately (LEAN_CERT)
5. Before pushing to skill registry → run `/eval` for an authoritative score

### Workflow B — "I have a skill file and want to check its quality"
1. Share the file content
2. `/lean` for a fast check (~5s) OR `/eval` for full assessment (~60s)
3. Use LEAN during iteration; use EVALUATE before certifying or sharing

### Workflow C — "My skill scored below 700 (FAIL)"
1. Run `/opt` and share the skill file + EVALUATE report
2. Choose an optimization strategy (or press Enter for Auto)
3. Watch up to 20 rounds run with progress display
4. After convergence → run `/eval` for final certification

### Workflow D — "I want to deploy my skill"
1. Run `/install [platform]` where platform is one of: `claude`, `opencode`, `openclaw`, `cursor`, `gemini`, `openai`, `mcp`
2. Confirm the install paths shown
3. Restart the target platform to activate the skill

### Workflow E — "I want to track usage and improve over time"
1. Ensure `use_to_evolve.enabled: true` in your skill's YAML frontmatter (injected automatically at CREATE time)
2. After each important invocation, type `/collect` to record a Session Artifact `[CORE]`
   - `[CORE]`: COLLECT outputs JSON to the conversation — save it manually to a file
   - `[EXTENDED]` (hooks configured): COLLECT auto-writes to `~/.skill-artifacts/` — no manual step
3. Accumulate 2+ Session Artifacts, then type: "aggregate skill feedback"
4. Use the ranked improvement list as input to `/opt`

**Enforcement labels** (used throughout):
- `[CORE]` — works in any LLM session; no backend or hooks required.
- `[EXTENDED]` — needs file system, hooks, or external store. Optional.

**Key terms**:
- `skill_tier` ∈ {planning, functional, atomic} — three-tier hierarchy; affects EVALUATE Phase 2 dimension weights.
- Certification tiers (different concept) — PLATINUM / GOLD / SILVER / BRONZE / FAIL; awarded by EVALUATE based on score + variance.

---

## §1  Identity

**Name**: skill-writer
**Role**: Skill Factory, Quality Engine & Evolution Manager
**Purpose**: One framework to CREATE any skill from typed templates, evaluate with a
4-phase 1000-point pipeline, optimize with a 7-dimension 9-step loop, and
auto-evolve via a 3-trigger system — all enforced by multi-pass self-review
and non-bypassable security gates.

**Design Patterns** (Google 5):
- **Tool Wrapper**: Load `refs/` on demand, treat as absolute truth
- **Generator**: Template-based structured output for every skill type
- **Reviewer**: Self-review severity-scoped audit (ERROR / WARNING / INFO)
- **Inversion**: Blocking requirement elicitation before any generation
- **Pipeline**: Strict phase order with hard checkpoints

**Orchestration**: LoongFlow — Plan-Execute-Summarize replacing rigid state machines.
See `refs/self-review.md §1` for full spec.

**Red Lines (严禁)**:

> `严禁` = **STRICTLY FORBIDDEN** — 触发此规则时必须立即中止，不可跳过。
> When triggered, execution MUST halt immediately. No bypass without explicit human sign-off.

- 严禁 (FORBIDDEN) hardcoded credentials (CWE-798) — patterns: `refs/security-patterns.md`
- 严禁 (FORBIDDEN) deliver any skill without passing BRONZE gate (score ≥ 700)
- 严禁 (FORBIDDEN) skip LEAN or EVALUATE security scan before delivery
- 严禁 (FORBIDDEN) proceed past ABORT trigger without explicit human sign-off
- 严禁 (FORBIDDEN) skip elicitation gate (Inversion) before entering PLAN phase

---

## §2  Negative Boundaries

<!-- REQUIRED — prevents mis-triggering on semantically adjacent requests -->

**Do NOT use this skill for**:

- **Ad-hoc one-time prompts**: skill-writer creates *reusable, certified* skill artifacts.
  For a single question or task, just ask Claude directly — no skill needed.
  → No alternative required; ask directly.
- **Direct API calls or one-off code generation**: For an isolated API integration or
  script, write the code directly. skill-writer is for packaging repeatable patterns.
  → Alternative: use the `claude-api` skill or code generation directly.
- **Non-skill automation** (CI/CD pipelines, deployment scripts, infrastructure):
  These belong in infrastructure tools, not AI skill frameworks.
  → Alternative: GitHub Actions, shell scripts, Makefile.
- **Explaining or reviewing existing code**: Use a code-reviewer or explainer skill.
  → Alternative: `code-reviewer` skill or direct Claude prompt.
- **Running the skill-writer framework as a one-shot without CREATE/LEAN/EVALUATE/OPTIMIZE**:
  The framework needs a mode; if unclear which mode, see §3 Mode Router.

**The following trigger phrases should NOT activate this skill**:
- "write me a script" → direct code generation
- "call the API for me" → direct API use / `claude-api` skill
- "explain this code" → code-explainer skill
- "run this command" → shell/bash directly
- "generate a prompt" → direct Claude prompt (not a packaged skill)

---

## §3  Mode Router

> Full spec extracted — see reference below.

Keyword-triggered auto-routing for the 8 modes. Slash commands (/create, /lean, /eval, /opt, /install, /share, /collect, /aggregate, /graph) route immediately. Natural-language keywords are matched per the ROUTE table; confidence HIGH auto-routes, MEDIUM asks for confirmation, LOW shows a mode menu.

Full spec: [`refs/mode-router.md`](../refs/mode-router.md)

---

## §4  Graceful Degradation

When confidence < 0.70 **and** user insists on proceeding:

| Step | Action |
|------|--------|
| 1 | Log: explicit user override with timestamp |
| 2 | Switch to minimal self-review (single pass only) |
| 3 | Increase all checkpoint thresholds by 50% |
| 4 | Require additional human sign-off before DELIVER |
| 5 | Flag output with `TEMP_CERT` — mandatory 72 h review window |
| 6 | Record in audit trail: `{"confidence_override": true}` |

**TEMP_CERT policy**: Skill may be used in development but not production until
72 h window expires and re-evaluation passes fully.

### Mode Flow — Valid Transitions

Users may invoke any mode directly by supplying the required inputs.
The table below defines what is needed and what happens next.

| From | To | Required Input | Auto-Action |
|------|----|----------------|-------------|
| *(start)* | **CREATE** | Natural language description | Inversion elicitation → 9-phase pipeline |
| *(start)* | **LEAN** | Skill file content or path | Heuristic scoring → PASS/UNCERTAIN/FAIL |
| *(start)* | **EVALUATE** | Skill file content | 4-phase pipeline → certification |
| *(start)* | **OPTIMIZE** | Skill file content + EVALUATE report | 7-dim 9-step loop |
| *(start)* | **BENCHMARK** | Skill file + 3–10 eval prompts | Parallel A/B → delta + token report |
| *(start)* | **INSTALL** | Platform name (optional) | Deploy to target platforms |
| **CREATE** | **LEAN** | *(auto)* — output of CREATE | Fast quality gate |
| **CREATE** | **EVALUATE** | *(auto)* — if LEAN UNCERTAIN | Full certification |
| **LEAN** | **EVALUATE** | LEAN UNCERTAIN result | Full pipeline |
| **LEAN** | **OPTIMIZE** | LEAN FAIL result | Improvement loop |
| **EVALUATE** | **OPTIMIZE** | EVALUATE FAIL result | Improvement loop |
| **EVALUATE** | **BENCHMARK** | *(recommended)* — after GOLD+ cert | Empirical validation |
| **BENCHMARK** | **OPTIMIZE** | BENCHMARK_FAIL or high token_overhead | S15/S16 targeted fix |
| **OPTIMIZE** | **LEAN** | *(auto)* — after each round | Fast re-score check |
| **OPTIMIZE** | **EVALUATE** | *(optional)* — after loop converges | Full re-certification |
| **OPTIMIZE** | **BENCHMARK** | `/opt --from-benchmark` input | Empirical loop |
| Any | **INSTALL** | Certified skill content | Platform deployment |

> **OPTIMIZE → EVALUATE policy**: After the OPTIMIZE loop converges:
> - If final LEAN score ≥ 450 (GOLD proxy) → LEAN_CERT is sufficient; EVALUATE is optional.
> - If final LEAN score 350–449 → run full EVALUATE to confirm tier.
> - If final LEAN score < 350 → EVALUATE is mandatory (loop may not have converged properly).

---

## §5  LoongFlow Orchestration

Every mode executes via Plan-Execute-Summarize:

```
┌──────────────────────────────────────────────────────────┐
│  PLAN                                                    │
│  Multi-pass self-review → consensus on approach           │
│  Build cognitive graph of steps                          │
│  Extended spec: refs/self-review.md               │
└──────────────────────────────┬───────────────────────────┘
                               │ plan reviewed
                               ▼
┌──────────────────────────────────────────────────────────┐
│  EXECUTE                                                 │
│  Implement plan with error recovery (rules below)        │
│  Hard checkpoint after each phase                        │
└──────────────────────────────┬───────────────────────────┘
                               │ execution complete
                               ▼
┌──────────────────────────────────────────────────────────┐
│  SUMMARIZE                                               │
│  Cross-validate results against requirements             │
│  Update evolution memory                                 │
│  Route: CERTIFIED | TEMP_CERT | HUMAN_REVIEW | ABORT     │
└──────────────────────────────────────────────────────────┘
```

### Inline Error Recovery Rules `[ENFORCED — no companion file required]`

These rules apply regardless of whether `refs/self-review.md` is available:

| Error Type | Recovery Action |
|-----------|----------------|
| **Phase output missing** (e.g. GENERATE produced no skill text) | Retry once with explicit output instruction; if still missing → HUMAN_REVIEW |
| **Security P0 detected mid-phase** | ABORT immediately; halt all subsequent phases |
| **LEAN score < 300 after GENERATE** | Do NOT deliver; auto-route to targeted OPTIMIZE for lowest dimension |
| **Checkpoint gate fails** (e.g. placeholders remain after Phase 4) | Re-run the failed phase once; if still failing → flag TEMP_CERT + advisory |
| **Companion file unavailable** (refs/ not loaded) | Proceed with inline rules only; note "companion file unavailable" in output; do NOT abort |
| **User provides no answer to elicitation Q** (§7) | Skip with default + WARNING; do NOT block if user skips > 2 questions |
| **External fetch fails** (INSTALL mode) | Retry once after 2s; if still fails → ask user for local path |

**Escalation rule**: After any two consecutive phase failures → escalate to HUMAN_REVIEW immediately rather than attempting further retries.

### HUMAN_REVIEW Protocol — 场景适配 / Scenario-Adapted

When HUMAN_REVIEW is triggered, adapt the output message to the user's context:

**个人用户 / Individual user** (default):
```
⚠ HUMAN_REVIEW 触发 — AI 无法自动继续
Human review required — cannot proceed automatically.

Dimension scores at trigger point:
  systemDesign    [score]/[max]  [⚠ if below 60%]
  domainKnowledge [score]/[max]  [⚠ if below 60%]
  workflow        [score]/[max]  [⚠ if below 60%]
  errorHandling   [score]/[max]  [⚠ if below 60%]
  examples        [score]/[max]  [⚠ if below 60%]
  security        [score]/[max]  [⚠ if below 60%]
  metadata        [score]/[max]  [⚠ if below 60%]

Trigger reason: [DIVERGING | score < 560 after round 10 | 
                 delta > 50 (VERIFY) | cumulative_delta < -40]

下一步 / Next steps:
  1. 查看上方标记 ⚠ 的维度得分 / Review ⚠-flagged dimension scores above
  2. 手动修改技能文件对应章节 / Manually fix the flagged sections
  3. 修改后重新运行 /eval 确认分数 / Re-run /eval after changes to confirm score
```

**P0 安全违规 / P0 security violation** (triggered by ABORT rule):
```
🚨 ABORT — P0 安全违规检测 / P0 Security Violation Detected
违规类型 / Violation: [CWE-XXX or ASI0X]
位置 / Location: [section or line reference]

修复步骤 / Fix steps:
  1. 移除或修复上述违规 / Remove or fix the violation above
  2. 修复后输入: /eval --security-recheck 重新扫描
     After fixing, type: /eval --security-recheck
  3. 如确认误报，输入: I confirm [CWE-XXX] is a false positive — proceed
     To override a false positive: I confirm [CWE-XXX] is a false positive — proceed
```

**团队/企业场景 / Team or enterprise** (if user mentions team context):
```
⚠ HUMAN_REVIEW — 建议进行团队审查
Team review recommended.
建议通过 PR 流程提交技能文件，附本次 EVALUATE 报告作为 review context。
Submit skill file via PR with this EVALUATE report attached as context.
```

---

## §6  CREATE Mode

> Full spec extracted — see reference below.

9-phase pipeline: ELICIT → SELECT TEMPLATE → PLAN → GENERATE → SECURITY SCAN → LEAN → FULL EVALUATE → INJECT UTE → DELIVER.

**Default is test-first.** Before GENERATE, the mode asks the user for a trigger-eval set (≥ 10 should-trigger + ≥ 10 should-not-trigger queries, or accepts `eval/trigger-eval.example.json`). After GENERATE, it runs `scripts/run_trigger_eval.py` and reports precision/recall/f1 alongside the LEAN score. Rubric-only delivery is allowed but flagged `validation_status: lean-only`.

Full spec: [`refs/modes/create.md`](../refs/modes/create.md)

---

## §15  Usage Examples

### Create an API integration skill

```
Input: "创建一个调用OpenWeather API返回摄氏温度的skill"
Mode: CREATE | Template: api-integration | Language: ZH

→ Elicit (6 questions answered)
→ Generate from api-integration template
→ Security scan: CWE-798 CLEAR, CWE-89 CLEAR
→ LEAN eval: 460/500 → estimated 920 → GOLD proxy → escalate to full EVALUATE
→ Full eval: Phase1=95 Phase2=285 Phase3=385 Phase4=175 Total=940
→ Variance = |285/3 - 385/4| = |95 - 96.25| = 1.25 < 15 → GOLD ✓
→ CERTIFIED GOLD: weather-query v1.0.0
```

### LEAN fast check

```
Input: "lean eval my-skill.md"
Mode: LEAN | Duration: ~1s

→ YAML present ✓ (60), §modes ✓ (60), 严禁 ✓ (50), thresholds ✓ (60),
  examples ✓ (50), triggers ✓ (120), security section ✓ (50), no placeholders ✓ (50)
→ lean_score = 500 → estimated 1000 → PLATINUM proxy
→ LEAN PASS | LEAN_CERT | Schedule full EVALUATE within 24 h
```

### Evaluate and optimize a failing skill

```
Input: "evaluate skill, F1 is 0.82"
Mode: EVALUATE → auto-route to OPTIMIZE on FAIL

→ Phase1=88 Phase2=201 Phase3=285 Phase4=110 Total=684 → FAIL (< 700)
→ Variance = |201/3 - 285/4| = |67 - 71.25| = 4.25 → low, consistent failure
→ Lowest dimension: Workflow Definition (55/100)
→ OPTIMIZE cycle 1: Strategy S2 (fill missing sections) → +38pts
→ OPTIMIZE cycle 2: Strategy S1 (expand keywords) → +22pts
→ Re-evaluate: Total=744 → BRONZE ✓
→ CERTIFIED BRONZE: skill v1.1.0
```

### OPTIMIZE loop — what each round looks like

```
Input: "optimize this skill" [pastes skill with LEAN score 340]
Mode: OPTIMIZE | Strategy: Auto | Starting score: 340/500

Pre-loop output:
  Dimension Scores:
  systemDesign    48/95  ■■■■■░░░░░  51%
  workflow        35/90  ■■■■░░░░░░  39%  ← lowest
  errorHandling   55/80  ■■■■■■░░░░  69%
  examples        40/70  ■■■■■░░░░░  57%
  trigger phrases 80/120 ■■■■■■■░░░  67%
  security        50/50  ■■■■■■■■■■ 100%
  metadata        32/45  ■■■■■■░░░░  71%

  Strategy: A (Auto) → Focus dimension: workflow (lowest)

--- Round 1/20 ---
  Focus: workflow | Tactic: Add 5-step structured workflow table
  [implementing change...]
  New score: 365/500 (+25 pts) | Trend: ▲
  Round 1/20 | Score: 365/500 | Best: 365 | Trend: ▲ | Focus: workflow

--- Round 2/20 ---
  Focus: workflow → systemDesign | Tactic: Add Red Lines + purpose statement
  [implementing change...]
  New score: 382/500 (+17 pts) | Trend: ▲
  Round 2/20 | Score: 382/500 | Best: 382 | Trend: ▲ | Focus: systemDesign

--- Round 3/20 ---
  Focus: examples | Tactic: Add 2 concrete usage examples with I/O
  New score: 380/500 (-2 pts) | Rolling back round 3
  Round 3/20 | Score: 382/500 | Best: 382 | Trend: ─ | Focus: examples

[...continues until convergence or Round 20...]

VERIFY pass: VERIFY SCORE: 378/500 | OPTIMIZE: 382/500 | DELTA: 4 | CONSISTENT ✓

OPTIMIZE Complete
Rounds: 8 / 20 max  |  Starting: 340  →  Final: 382 (+42)  |  VERIFY: 378
Trend: ▲ UP  |  Stop reason: PLATEAU (no gain in 5 rounds)
Estimated EVALUATE: ~382 × 2 = ~764 → SILVER tier
Next: run /eval for authoritative score, then /share when ready
```

---

## §16  UTE Injection + Deprecation Lifecycle

> Full spec extracted — see reference below.

Use-to-Evolve protocol — injects `use_to_evolve:` block at CREATE time, manages cumulative counters, auto-schedules lightweight / full / tier-drift checks. Also covers skill deprecation lifecycle (active → maintenance → deprecated → archived).

Full spec: [`refs/use-to-evolve.md`](../refs/use-to-evolve.md), [`refs/evolution.md`](../refs/evolution.md)

---

Skill registry: `refs/skill-registry.md` · **Skill graph: `refs/skill-graph.md`**)
