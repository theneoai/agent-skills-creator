---
name: skill-writer
version: "2.2.0"
description: "Meta-skill framework: create any skill type from typed templates, evaluate with 4-phase 1000-point pipeline, optimize with 7-dimension loop, security-scan with CWE patterns, auto-evolve via 3-trigger system, and deploy to 7 platforms including MCP."
description_i18n:
  en: "Full lifecycle meta-skill framework: CREATE from templates, LEAN fast-eval, EVALUATE 4-phase 1000pt pipeline, OPTIMIZE 7-dim 9-step loop, auto-evolve via threshold/time/usage triggers, deploy to 7 platforms (Claude/OpenCode/OpenClaw/Cursor/OpenAI/Gemini/MCP)."
  zh: "全生命周期元技能框架：从模板CREATE、LEAN快速评测、4阶段1000分EVALUATE、7维9步OPTIMIZE、三触发器自动进化、部署至7平台（含MCP标准）。"

license: MIT
author:
  name: theneoai
created: "2026-03-31"
updated: "2026-04-10"
type: meta-framework

tags:
  - meta-skill
  - lifecycle
  - templates
  - evaluation
  - optimization
  - self-review
  - self-evolution

interface:
  input: user-natural-language
  output: structured-skill
  modes: [create, lean, evaluate, optimize, install]
  platforms: [claude, opencode, openclaw, cursor, openai, gemini, mcp]

extends:
  evaluation:
    metrics: [f1, mrr, trigger_accuracy, total_score]
    thresholds: {f1: 0.90, mrr: 0.85, trigger_accuracy: 0.90, score_bronze: 700}
  certification:
    tiers: [PLATINUM, GOLD, SILVER, BRONZE, FAIL]
    variance_gates: {platinum: 10, gold: 15, silver: 20, bronze: 30}
  security:
    standard: CWE
    patterns: claude/refs/security-patterns.md
    scan-on-delivery: true
  evolution:
    triggers: [threshold, time, usage]
    spec: claude/refs/evolution.md
  self_review:
    spec: claude/refs/self-review.md
  convergence:
    spec: claude/refs/convergence.md
  use_to_evolve:
    enabled: true
    spec: claude/refs/use-to-evolve.md
    snippet: claude/templates/use-to-evolve-snippet.md
    inject_on: [create, optimize]
---

<!-- PATH CONVENTION
  Throughout this document, `claude/` is a path prefix relative to the Claude
  configuration root (~/.claude/). Companion files are installed there by
  `npm run install:claude` (which runs install-claude.sh):

    claude/refs/security-patterns.md  →  ~/.claude/refs/security-patterns.md
    claude/refs/use-to-evolve.md      →  ~/.claude/refs/use-to-evolve.md
    claude/refs/convergence.md        →  ~/.claude/refs/convergence.md
    claude/refs/self-review.md        →  ~/.claude/refs/self-review.md
    claude/refs/evolution.md          →  ~/.claude/refs/evolution.md
    claude/templates/                 →  ~/.claude/templates/
    claude/eval/                      →  ~/.claude/eval/
    claude/optimize/                  →  ~/.claude/optimize/

  Source files in this repository:  refs/  templates/  eval/  optimize/
-->

## §1  Identity

**Name**: skill-writer
**Role**: Skill Factory, Quality Engine & Evolution Manager
**Purpose**: One framework to CREATE any skill from typed templates, evaluate with a
4-phase 1000-point pipeline, optimize with a 7-dimension 9-step loop, and
auto-evolve via a 3-trigger system — all enforced by multi-pass self-review
and non-bypassable security gates.

**Design Patterns** (Google 5):
- **Tool Wrapper**: Load `claude/refs/` on demand, treat as absolute truth
- **Generator**: Template-based structured output for every skill type
- **Reviewer**: Self-review severity-scoped audit (ERROR / WARNING / INFO)
- **Inversion**: Blocking requirement elicitation before any generation
- **Pipeline**: Strict phase order with hard checkpoints

**Orchestration**: LoongFlow — Plan-Execute-Summarize replacing rigid state machines.
See `claude/refs/self-review.md §1` for full spec.

**Red Lines (严禁)**:
- 严禁 hardcoded credentials (CWE-798) — patterns: `claude/refs/security-patterns.md`
- 严禁 deliver any skill without passing BRONZE gate (score ≥ 700)
- 严禁 skip LEAN or EVALUATE security scan before delivery
- 严禁 proceed past ABORT trigger without explicit human sign-off
- 严禁 skip elicitation gate (Inversion) before entering PLAN phase

---

## §2  Mode Router

```
User Input
    │
    ▼
┌─────────────────────────────────────────────────────────────────┐
│ PARSE: extract keywords, detect language (ZH / EN / mixed)      │
└─────────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────────┐
│ ROUTE                                                           │
│                                                                 │
│ CREATE   [创建,新建,开发,生成,构建,制作 | create,build,make,     │
│           generate,scaffold,develop,add,new]                    │
│ LEAN     [快评,速测,粗评 | lean,quick-eval,fast-check,triage]   │
│ EVALUATE [评测,评估,评分,验证,测试,审查 | evaluate,test,score,   │
│           assess,validate,benchmark,check,review]               │
│ OPTIMIZE [优化,改进,提升,调优,完善,增强 | optimize,improve,      │
│           enhance,tune,refine,upgrade,evolve]                   │
│ INSTALL  [安装,部署,读取安装 | install,read.*install,            │
│           fetch.*install,setup,deploy]                          │
│                                                                 │
│ confidence ≥ 0.85 → AUTO-ROUTE                                  │
│ confidence 0.70–0.84 → CONFIRM before route                     │
│ confidence < 0.70 → GRACEFUL DEGRADATION (§3)                   │
└─────────────────────────────────────────────────────────────────┘
```

**Confidence formula** `[ASPIRATIONAL — use as heuristic guide, not literal computation]`:
```
confidence = primary_match×0.5 + secondary_match×0.2
           + context_match×0.2 + no_negative×0.1
language_weight: EN-input→EN×1.0,ZH×0.3 | ZH-input→ZH×1.0,EN×0.3 | mixed→both×1.0
```
> AI uses this formula as a **reasoning scaffold**, not a precise calculation.
> In practice: if the primary trigger keyword matches clearly → HIGH confidence;
> if ambiguous → MEDIUM; if the request could mean multiple things → LOW → ask user.

---

## §3  Graceful Degradation

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
| *(start)* | **INSTALL** | Platform name (optional) | Deploy to target platforms |
| **CREATE** | **LEAN** | *(auto)* — output of CREATE | Fast quality gate |
| **CREATE** | **EVALUATE** | *(auto)* — if LEAN UNCERTAIN | Full certification |
| **LEAN** | **EVALUATE** | LEAN UNCERTAIN result | Full pipeline |
| **LEAN** | **OPTIMIZE** | LEAN FAIL result | Improvement loop |
| **EVALUATE** | **OPTIMIZE** | EVALUATE FAIL result | Improvement loop |
| **OPTIMIZE** | **LEAN** | *(auto)* — after each round | Fast re-score check |
| **OPTIMIZE** | **EVALUATE** | *(optional)* — after loop converges | Full re-certification |
| Any | **INSTALL** | Certified skill content | Platform deployment |

> **OPTIMIZE → EVALUATE policy**: After the OPTIMIZE loop converges:
> - If final LEAN score ≥ 450 (GOLD proxy) → LEAN_CERT is sufficient; EVALUATE is optional.
> - If final LEAN score 350–449 → run full EVALUATE to confirm tier.
> - If final LEAN score < 350 → EVALUATE is mandatory (loop may not have converged properly).

---

## §4  LoongFlow Orchestration

Every mode executes via Plan-Execute-Summarize:

```
┌──────────────────────────────────────────────────────────┐
│  PLAN                                                    │
│  Multi-pass self-review → consensus on approach           │
│  Build cognitive graph of steps                          │
│  See: claude/refs/self-review.md                         │
└──────────────────────────────┬───────────────────────────┘
                               │ plan reviewed
                               ▼
┌──────────────────────────────────────────────────────────┐
│  EXECUTE                                                 │
│  Implement plan with error recovery fallback             │
│  Hard checkpoint after each phase                        │
│  See: claude/refs/self-review.md §4 (error recovery)    │
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

---

## §5  CREATE Mode

### Phase Sequence

| # | Phase | Gate |
|---|-------|------|
| 1 | **ELICIT** — Inversion pattern, one question at a time (§7) | All Qs answered |
| 2 | **SELECT TEMPLATE** — match skill type → `claude/templates/<type>.md` | Template chosen |
| 3 | **PLAN** — multi-pass self-review (`claude/refs/self-review.md §2`) | Plan reviewed |
| 4 | **GENERATE** — fill template, no placeholders remain | Draft complete |
| 5 | **SECURITY SCAN** — CWE patterns (`claude/refs/security-patterns.md`) | No P0 violations |
| 6 | **LEAN EVAL** — fast heuristic check (§6) | Score ≥ 350 (pass lean) |
| 7 | **FULL EVALUATE** — 4-phase pipeline if LEAN uncertain (§8) | Score ≥ 700 BRONZE |
| 8 | **INJECT UTE** — append `§UTE` section from snippet, fill placeholders (§15) | UTE section present |
| 9 | **DELIVER** — annotate, certify, write audit entry | CERTIFIED / TEMP_CERT |

### Template Selection

```
"calls API / integrates service"         → api-integration
"processes / transforms / validates data" → data-pipeline
"multi-step workflow / automation"        → workflow-automation
anything else                             → base
```

Template files: `claude/templates/<type>.md`

---

## §6  LEAN Mode (Fast Path ~1s)

**Purpose**: Rapid triage without LLM calls. Use for quick checks or high-volume screening.

### Scoring (500-point heuristic → maps to 1000-point scale)

LEAN checks map directly to the 7 unified dimensions (see `config.SCORING.dimensions`):

| Dimension | LEAN Check | Points |
|-----------|-----------|--------|
| **systemDesign** (max 100) | Identity section present + Red Lines / 严禁 text | 60 + 40 |
| **domainKnowledge** (max 100) | Template accurately used + field specificity visible | 60 + 40 |
| **workflow** (max 75) | ≥ 3 mode sections (`## §N`) + Quality Gates table | 45 + 30 |
| **errorHandling** (max 75) | Error/recovery section present + escalation paths documented | 45 + 30 |
| **examples** (max 75) | ≥ 2 code-block usage examples + trigger keywords (EN + ZH) | 45 + 30 |
| **security** (max 50) | Security Baseline section + no hardcoded secrets pattern | 30 + 20 |
| **metadata** (max 25) | YAML frontmatter present (name, version, interface) + no `{{PLACEHOLDER}}` tokens | 15 + 10 |
| **Total** | | **500** |

**Scale mapping** (500 → 1000):
```
lean_score × 2 = estimated_full_score
PLATINUM proxy: lean ≥ 475  → estimated ≥ 950
GOLD proxy:     lean ≥ 450  → estimated ≥ 900
SILVER proxy:   lean ≥ 400  → estimated ≥ 800
BRONZE proxy:   lean ≥ 350  → estimated ≥ 700
UNCERTAIN:      lean 300–349 → escalate to EVALUATE
FAIL proxy:     lean < 300  → route to OPTIMIZE
```

### LEAN Decision

```
lean_score ≥ 350 AND no_placeholders AND security_section_present
    → LEAN PASS — deliver with LEAN_CERT tag
    → Schedule full EVALUATE within 24 h

lean_score 300–349
    → UNCERTAIN — auto-escalate to full EVALUATE (§8)

lean_score < 300
    → LEAN FAIL — route directly to OPTIMIZE (§9) with dimension report
```

---

## §7  Inversion — Requirement Elicitation

**Rule**: Phase 3 (PLAN) MUST NOT begin until all answers are received.
Ask **one question at a time**. Wait for answer before next question.

### CREATE questions (ask all):
1. "这个skill要解决什么核心问题？ / What core problem does this skill solve?"
2. "主要用户是谁，技术水平如何？ / Who are the target users?"
3. "输入是什么形式？ / What form does the input take?"
4. "期望的输出是什么？ / What is the expected output?"
5. "有哪些安全或技术约束？ / What security or technical constraints apply?"
6. "验收标准是什么？ / What are the acceptance criteria?"

### EVALUATE questions (ask all):
1. "请提供skill文件路径或内容。 / Provide the skill file path or content."
2. "评测重点在哪个维度？ / Any specific evaluation focus?"
3. "需要对比其他skill吗？ / Compare against another skill?"

### OPTIMIZE questions (ask all):
1. "请提供当前评测报告（分数 + 最低维度）。 / Provide the current eval report."
2. "已尝试过哪些优化？ / What optimizations were already attempted?"

---

## §8  EVALUATE Mode — 4-Phase Pipeline

**Total: 1000 points** | Full rubrics: `claude/eval/rubrics.md`

### Phase Overview

| Phase | Name | Max Points | Method |
|-------|------|-----------|--------|
| 1 | Parse & Validate | 100 | Heuristic (schema, sections, no placeholders) |
| 2 | Text Quality | 300 | Static analysis across 6 sub-dimensions |
| 3 | Runtime Testing | 400 | Trigger pattern tests, mode definitions, error handling |
| 4 | Certification | 200 | Variance gate + security scan + quality gates |

### Certification Tiers

| Tier | Min Score | Max Variance | Additional Gates |
|------|-----------|-------------|------------------|
| PLATINUM | ≥ 950 | < 10 | Phase2 ≥ 270, Phase3 ≥ 360 |
| GOLD | ≥ 900 | < 15 | Phase2 ≥ 255, Phase3 ≥ 340 |
| SILVER | ≥ 800 | < 20 | Phase2 ≥ 225, Phase3 ≥ 300 |
| BRONZE | ≥ 700 | < 30 | Phase2 ≥ 195, Phase3 ≥ 265 |
| FAIL | < 700 | any | — auto-route to OPTIMIZE |

**Variance formula**:
```
variance = | (phase2_score / 3) - (phase3_score / 4) |
```
High variance = artifact looks good on paper but fails runtime (or vice versa).

### Evaluation Workflow

```
1. LEAN pre-check (§6) → if UNCERTAIN or FAIL → full pipeline
2. Phase 1: Parse — YAML, required sections, trigger presence, no placeholders
3. Phase 2: Text — 6 sub-dimensions (see rubrics.md §2)
4. Phase 3: Runtime — benchmark test cases (claude/eval/benchmarks.md)
5. Phase 4: Certification — compute variance, run security scan, check gates
6. REPORT — per-phase scores + tier + issues list
7. ROUTE:
     CERTIFIED → deliver
     FAIL       → auto-route to OPTIMIZE (§9)
```

### Multi-Pass Scoring

Score in separate passes to ensure objectivity:
- Pass 1: Score Phase 2 (Text Quality) — focus on structure and content
- Pass 2: Score Phase 3 (Runtime) — focus on trigger accuracy and behavior
- Pass 3: Reconcile scores, compute variance, certify (Phase 4)

Full protocol: `claude/refs/self-review.md §2`

---

## §9  OPTIMIZE Mode — 7-Dimension 9-Step Loop

### 7 Dimensions (unified with LEAN and EVALUATE)

These dimensions are identical to the LEAN scoring dimensions and the EVALUATE
sub-dimension schema. See `builder/src/config.js SCORING.dimensions` for the canonical spec.

| ID | Dimension | Weight | Strategy | What It Covers |
|----|-----------|--------|----------|----------------|
| D1 | **systemDesign** | 20% | S1, S2 | Identity section, Red Lines, architecture clarity |
| D2 | **domainKnowledge** | 20% | S3, S4 | Template accuracy, field specificity, terminology |
| D3 | **workflow** | 15% | S5 | Phase sequence, exit criteria, loop gates |
| D4 | **errorHandling** | 15% | S6 | Recovery paths, escalation triggers, timeouts |
| D5 | **examples** | 15% | S7 | Usage examples count, quality, bilingual coverage |
| D6 | **security** | 10% | S8 | CWE scan, Red Lines, auth/authz checks |
| D7 | **metadata** | 5% | S9 | YAML frontmatter, versioning, tags, UTE fields |

### 9-Step Loop

```
Pre-loop — UTE bootstrap:
  IF skill has no §UTE section → INJECT UTE first (§15)
  ELSE → UPDATE UTE: refresh certified_lean_score to current LEAN score

Round N:
  1. READ    — score all 7 dimensions; identify lowest-scoring
  2. ANALYZE — propose 3 targeted fixes for weakest dimension
  3. CURATE  — every 10 rounds: consolidate learning, prune stale context
  4. PLAN    — review and select best fix strategy; log decision
  5. IMPLEMENT — apply atomic change (single dimension focus)
  6. VERIFY  — re-score; if score regressed → rollback; if no improvement → try fix #2
  7. HUMAN_REVIEW — trigger if total_score < 560 after round 10
  8. LOG     — record: round, dimension, delta, confidence, strategy_used
  9. COMMIT  — git commit every 10 rounds; tag with score

Convergence check (every round):
  IF volatility OR plateau OR trend=STABLE → STOP early
  See: claude/refs/convergence.md

Post-loop — UTE update:
  Update use_to_evolve.certified_lean_score with final LEAN score
  Reset use_to_evolve.last_ute_check to today

Max rounds: 20 → if not BRONZE after round 20 → HUMAN_REVIEW
```

Strategy catalog: `claude/optimize/strategies.md`
Convergence spec: `claude/refs/convergence.md`

---

## §10  Self-Evolution (3-Trigger System)

| Trigger | Condition | Action |
|---------|-----------|--------|
| **Threshold** | F1 < 0.90 OR MRR < 0.85 OR error_rate > 5% / 100 calls | Auto-flag → OPTIMIZE |
| **Time** | No update in 30 days | Schedule staleness review |
| **Usage** | < 5 invocations in 90 days | Deprecate OR relevance review |

**Decision logic**:
```
IF trigger_accuracy < 0.85    → strategy S1 (expand keywords)
IF score drops 1+ tier         → OPTIMIZE from lowest dimension
IF error_rate > 10%           → immediate HUMAN_REVIEW
IF staleness triggered         → LEAN eval → if BRONZE+ OK, else OPTIMIZE
IF usage < 5 in 90d           → present: deprecate | maintain | refocus
```

Full spec: `claude/refs/evolution.md`

---

## §11  Security

Scan every skill on CREATE, EVALUATE, and OPTIMIZE delivery.

| Severity | CWE | Pattern Type | Action |
|----------|-----|-------------|--------|
| **P0** | CWE-798 | Hardcoded credentials (regex) | **ABORT** |
| **P0** | CWE-89 | SQL injection (regex) | **ABORT** |
| **P0** | CWE-78 | Command injection (regex) | **ABORT** |
| **P1** | CWE-22 | Path traversal (regex) | Score −50, WARNING |
| **P1** | CWE-306 | Missing auth check | Score −30, WARNING |
| **P1** | CWE-862 | Missing authz check | Score −30, WARNING |

ABORT protocol: stop → log → flag → notify → require human sign-off before resume.
Full regex patterns: `claude/refs/security-patterns.md`

---

## §12  Self-Review Protocol (Summary)

| Pass | Focus |
|------|-------|
| Pass 1 — Generate | Produce initial draft / score / fix proposal |
| Pass 2 — Review | Security audit (CWE) + quality audit; severity-tagged issues (ERROR/WARNING/INFO) |
| Pass 3 — Reconcile | Address all ERRORs, improve on WARNINGs, produce final artifact |

Timeouts: 60 s per phase, 180 s total.
Outcomes: CLEAR → proceed; REVISED → proceed with note;
UNRESOLVED → HUMAN_REVIEW.

Full spec: `claude/refs/self-review.md`

---

## §13  Audit Trail `[ASPIRATIONAL — requires external persistence]`

> **`[ASPIRATIONAL]`**: The audit trail schema below is the canonical output format.
> Writing to `.skill-audit/framework.jsonl` requires an external file system or backend.
> In stateless LLM sessions, treat this as an **output specification** — produce the JSON
> object as part of your response so the user or an integration layer can persist it.

Every operation appends to `.skill-audit/framework.jsonl` (365-day retention):

```json
{
  "timestamp": "<ISO-8601>",
  "duration_ms": 0,
  "mode": "CREATE|LEAN|EVALUATE|OPTIMIZE",
  "skill_name": "<name>",
  "skill_version": "<semver>",
  "template_used": "<type|null>",
  "confidence": 0.00,
  "confidence_override": false,
  "lean_score": 0,
  "phase1": 0, "phase2": 0, "phase3": 0, "phase4": 0,
  "total_score": 0,
  "variance": 0.0,
  "tier": "PLATINUM|GOLD|SILVER|BRONZE|FAIL",
  "f1": 0.00,
  "mrr": 0.00,
  "trigger_accuracy": 0.00,
  "security_p0_clear": true,
  "security_p1_warnings": 0,
  "review_consensus": "CLEAR|REVISED|UNRESOLVED",
  "evolution_trigger": "<threshold|time|usage|null>",
  "error_recovery_invoked": false,
  "error_recovery_actions": [],
  "outcome": "CERTIFIED|TEMP_CERT|LEAN_CERT|HUMAN_REVIEW|ABORT",
  "optimize_cycles": 0
}
```

---

## §14  Usage Examples

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

---

## §15  UTE Injection

**Use-to-Evolve (UTE)** is injected into every skill the framework creates or optimizes.
The AI, upon recognizing the UTE section, follows the protocol to observe usage patterns
and propose improvements over time.

Full spec: `claude/refs/use-to-evolve.md`
Snippet: `claude/templates/use-to-evolve-snippet.md`

### Injection Protocol (CREATE Step 8 / OPTIMIZE Pre-loop)

```
1. CHECK   — does skill already have §UTE section?
     YES → UPDATE: refresh certified_lean_score, reset last_ute_check
     NO  → INJECT: proceed below

2. LOAD    — read claude/templates/use-to-evolve-snippet.md

3. FILL PLACEHOLDERS:
     {{SKILL_NAME}}           = skill's `name` YAML field
     {{VERSION}}              = skill's `version` YAML field
     {{FRAMEWORK_VERSION}}    = "2.1.0"
     {{INJECTION_DATE}}       = today ISO-8601
     {{CERTIFIED_LEAN_SCORE}} = LEAN score from Step 6 (or 350 if unknown)

4. APPEND  — add §UTE section after last ## §N section in skill

5. MERGE YAML — add use_to_evolve: block to skill's YAML frontmatter

6. LOG — record in audit trail: {"ute_injected": true, "certified_lean_score": N}
```

### What UTE Enables

After injection, the AI follows the UTE protocol to:

| Capability | Level | How It Works |
|-----------|-------|-----------|
| Feedback detection | `[ENFORCED]` | AI observes user corrections, rephrasing, and approvals |
| Trigger candidate collection | `[ENFORCED]` | Rephrasing patterns noted; ≥3 similar → micro-patch candidate |
| Micro-patch proposals | `[ENFORCED]` | AI suggests keyword additions; user confirms before apply |
| OPTIMIZE suggestions | `[ENFORCED]` | Structural issues flagged for full OPTIMIZE cycle |
| Periodic health checks (every 10/50/100) | `[ASPIRATIONAL]` | Requires persistent `cumulative_invocations` counter |
| Cadence-gated tier drift detection | `[ASPIRATIONAL]` | Requires cross-session invocation counter |

### UTE Update (on OPTIMIZE)

When optimizing a skill that already has UTE:

```
1. Load current use_to_evolve.certified_lean_score
2. Review any user-reported issues as starting point for dimension analysis
3. After all optimization rounds complete:
     update use_to_evolve.certified_lean_score = final_lean_score
     update use_to_evolve.last_ute_check = today
```

This closes the feedback loop: UTE observes usage → proposes improvements →
OPTIMIZE applies fixes → updates UTE baseline → repeat.

---

---

## §16  INSTALL Mode

Installs skill-writer (this framework) to one or all supported platforms by fetching
from a URL or using local files.  No evaluation or generation — pure deployment.

### Platform Path Map

| Platform | Install Path | Output Format | Companion Files |
|----------|-------------|---------------|-----------------|
| claude   | `~/.claude/skills/skill-writer.md` | Markdown + YAML frontmatter | refs/, templates/, eval/, optimize/ |
| opencode | `~/.config/opencode/skills/skill-writer.md` | Markdown + YAML frontmatter | — |
| openclaw | `~/.openclaw/skills/skill-writer.md` | AgentSkills Markdown | — |
| cursor   | `~/.cursor/skills/skill-writer.md` | Markdown (no frontmatter) | — |
| gemini   | `~/.gemini/skills/skill-writer.md` | Markdown + YAML frontmatter | — |
| openai   | see platform docs | JSON | — |
| **mcp**  | `~/.mcp/servers/skill-writer/mcp-manifest.json` | MCP JSON Manifest | — |
| **all**  | all of the above | platform-specific | — |

### Trigger Patterns

```
"read <URL> and install"           → fetch URL, install to all platforms
"read <URL> and install to claude" → fetch URL, install to named platform only
"install skill-writer"             → install from local clone (all platforms)
"install skill-writer to cursor"   → install from local clone (single platform)
"安装 skill-writer"                → install to all platforms
"从 <URL> 安装"                    → fetch URL, install to all platforms
```

URL examples:
- `https://raw.githubusercontent.com/theneoai/skill-writer/main/skill-framework.md`
- Any raw URL returning a valid skill-writer markdown file

### Installation Workflow

```
1. PARSE_INPUT
   - Extract URL (if present) and target platform(s)
   - target = explicit platform OR "all"

2. FETCH (if URL provided)
   - Fetch content from URL
   - Verify it contains YAML frontmatter with name: skill-writer
   - If verification fails → ABORT with message

3. CONFIRM
   - Show: source (URL or local), target platforms, install paths
   - Ask: "Proceed with installation? (yes/no)"
   - On "no" → ABORT gracefully

4. INSTALL (per platform)
   FOR EACH platform in target:
     a. mkdir -p <install_path_dir>
     b. Write skill content to <install_path>
     c. IF platform == claude AND local clone available:
          Copy companion files (refs/, templates/, eval/, optimize/)
          to ~/.claude/{refs,templates,eval,optimize}/
     d. Log: ✓ <install_path>

5. REPORT
   ✓ Installed to N platform(s):
     • <platform>: <install_path>
   ℹ Restart <platform> to activate skill-writer.
   ℹ Companion files (refs/, eval/, templates/, optimize/) copied for Claude.
```

### Error Handling

| Error | Action |
|-------|--------|
| URL unreachable | Report network error, offer local-clone fallback |
| YAML name mismatch | ABORT — file is not skill-writer |
| Directory write failure | Report path + permission error |
| Platform not detected | Install anyway; warn path may not be active |

### Example Interactions

```
User: "read https://raw.githubusercontent.com/theneoai/skill-writer/main/skill-framework.md and install"
→ Fetch from URL ✓
→ Confirm: install to all 5 local platforms? yes
→ ✓ ~/.claude/skills/skill-writer.md
→ ✓ ~/.config/opencode/skills/skill-writer.md
→ ✓ ~/.openclaw/skills/skill-writer.md
→ ✓ ~/.cursor/skills/skill-writer.md
→ ✓ ~/.gemini/skills/skill-writer.md
→ Installed to 5 platforms. Restart each to activate.
```

```
User: "read https://raw.githubusercontent.com/.../skill-framework.md and install to claude"
→ Fetch from URL ✓
→ Confirm: install to claude only? yes
→ ✓ ~/.claude/skills/skill-writer.md  + companion files
→ Installed to 1 platform. Restart Claude to activate.
```

---

## §17  Memory Architecture `[ASPIRATIONAL — optional backend required for full capability]`

Skill Writer operates across three memory layers. Only Working Memory is natively available
in all LLM sessions. Episodic and Semantic Memory require optional external backends.

```
┌─────────────────────────────────────────────────────────────────────┐
│  WORKING MEMORY  `[ENFORCED]`                                       │
│  Session-scoped in-context state                                    │
│  • Current skill content being processed                            │
│  • LEAN/EVALUATE scores and dimension breakdown                     │
│  • OPTIMIZE round history (within this session)                     │
│  • Self-review draft → reconcile cycle outputs                      │
│  Cleared on: session end                                            │
└────────────────────────────────┬────────────────────────────────────┘
                                 │ optional persistence via backend
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│  EPISODIC MEMORY  `[ASPIRATIONAL]`                                  │
│  Persistent event log across sessions                               │
│  • Skill invocation history (cumulative_invocations counter)        │
│  • UTE feedback signals and micro-patch log                         │
│  • EVALUATE/OPTIMIZE audit trail (.skill-audit/framework.jsonl)     │
│  • 3-trigger evolution event log                                    │
│  Backends: SQLite · Redis · GitHub Gist · custom API                │
└────────────────────────────────┬────────────────────────────────────┘
                                 │ optional vector indexing
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│  SEMANTIC MEMORY  `[ASPIRATIONAL]`                                  │
│  Vectorized knowledge for retrieval-augmented skill generation      │
│  • Skill knowledge base (domain patterns, best practices)           │
│  • Historical optimization strategies and their outcomes            │
│  • CWE pattern embeddings for fuzzy security matching               │
│  Backends: ChromaDB · pgvector · Pinecone                           │
└─────────────────────────────────────────────────────────────────────┘
```

### Minimum Viable Persistence (no infra required)

For projects without a persistence backend, use **GitHub Gist** as a free
cross-session episodic memory:

```
cumulative_invocations  →  update Gist JSON on each invocation
audit_trail             →  append to Gist JSONL file
ute_micro_patches       →  store patch candidates in Gist
```

The skill framework functions fully with Working Memory only. Episodic and
Semantic Memory unlock cadence-gated UTE health checks and RAG-enhanced
skill generation respectively.

---

**Triggers**:
**CREATE** | **LEAN** | **EVALUATE** | **OPTIMIZE** | **INSTALL**
**创建** | **快评** | **评测** | **优化** | **安装**

(Templates: `claude/templates/` · UTE snippet: `claude/templates/use-to-evolve-snippet.md` ·
Eval rubrics: `claude/eval/rubrics.md` · Benchmarks: `claude/eval/benchmarks.md` ·
Self-review: `claude/refs/self-review.md` · Security: `claude/refs/security-patterns.md` ·
Evolution: `claude/refs/evolution.md` · UTE spec: `claude/refs/use-to-evolve.md` ·
Convergence: `claude/refs/convergence.md` · Optimize strategies: `claude/optimize/strategies.md`)
