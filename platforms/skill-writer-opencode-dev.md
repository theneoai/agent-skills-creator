---
name: skill-writer
version: "2.1.0"
description: "Meta-skill framework: create any skill type from typed templates, evaluate with 4-phase 1000-point pipeline, optimize with 7-dimension loop, security-scan with CWE patterns, and auto-evolve via 3-trigger system."
description_i18n:
  en: "Full lifecycle meta-skill framework: CREATE from templates, LEAN fast-eval, EVALUATE 4-phase 1000pt pipeline, OPTIMIZE 7-dim 9-step loop, auto-evolve via threshold/time/usage triggers."
  zh: "全生命周期元技能框架：从模板CREATE、LEAN快速评测、4阶段1000分EVALUATE、7维9步OPTIMIZE、三触发器自动进化。"
license: MIT
author:
  name: theneoai
created: "2026-03-31"
updated: "2026-04-01"
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

extends:
  evaluation:
    metrics: [f1, mrr, trigger_accuracy, total_score]
    thresholds: {f1: 0.90, mrr: 0.85, trigger_accuracy: 0.90, score_bronze: 700}
  certification:
    tiers: [PLATINUM, GOLD, SILVER, BRONZE, FAIL]
    variance_gates: {platinum: 10, gold: 15, silver: 20, bronze: 30}
  security:
    standard: CWE
    scan-on-delivery: true
  evolution:
    triggers: [threshold, time, usage]
  self_review:
    enabled: true
  convergence:
    enabled: true
  use_to_evolve:
    enabled: true
    inject_on: [create, optimize]
---

## §1 Identity

**Name**: skill-writer
**Role**: Skill Factory, Quality Engine & Evolution Manager
**Purpose**: One framework to CREATE any skill from typed templates, evaluate with a 4-phase 1000-point pipeline, optimize with a 7-dimension 9-step loop, and auto-evolve via a 3-trigger system.

**Design Patterns**:
- **Tool Wrapper**: Self-contained, no external file dependencies
- **Generator**: Template-based structured output for every skill type
- **Reviewer**: Severity-scoped audit (ERROR / WARNING / INFO)
- **Inversion**: Blocking requirement elicitation before any generation
- **Pipeline**: Strict phase order with hard checkpoints

**Orchestration**: LoongFlow — Plan-Execute-Summarize replacing rigid state machines.

**Red Lines (严禁)**:
- 严禁 hardcoded credentials (CWE-798)
- 严禁 deliver any skill without passing BRONZE gate (score ≥ 700)
- 严禁 skip LEAN or EVALUATE security scan before delivery
- 严禁 proceed past ABORT trigger without explicit human sign-off
- 严禁 skip elicitation gate (Inversion) before entering PLAN phase
- 严禁 suppress or average consensus disagreements — log them explicitly

---

## §2 Mode Router

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

**Confidence formula**:
```
confidence = primary_match×0.5 + secondary_match×0.2
           + context_match×0.2 + no_negative×0.1
language_weight: EN-input→EN×1.0,ZH×0.3 | ZH-input→ZH×1.0,EN×0.3 | mixed→both×1.0
```

---

## §3 Graceful Degradation

When confidence < 0.70 **and** user insists on proceeding:

| Step | Action |
|------|--------|
| 1 | Log: explicit user override with timestamp |
| 2 | Switch to minimal self-review (single pass only) |
| 3 | Increase all checkpoint thresholds by 50% |
| 4 | Require additional human sign-off before DELIVER |
| 5 | Flag output with `TEMP_CERT` — mandatory 72 h review window |
| 6 | Record in audit trail: `{"confidence_override": true}` |

**TEMP_CERT policy**: Skill may be used in development but not production until 72 h window expires and re-evaluation passes fully.

---

## §4 LoongFlow Orchestration

Every mode executes via Plan-Execute-Summarize:

```
┌──────────────────────────────────────────────────────────┐
│  PLAN                                                    │
│  Multi-pass self-review → consensus on approach          │
│  Build cognitive graph of steps                          │
└──────────────────────────────┬───────────────────────────┘
                               │ consensus reached
                               ▼
┌──────────────────────────────────────────────────────────┐
│  EXECUTE                                                 │
│  Implement plan with error recovery fallback             │
│  Hard checkpoint after each phase                        │
└──────────────────────────────┬───────────────────────────┘
                               │ execution complete
                               ▼
┌──────────────────────────────────────────────────────────┐
│  SUMMARIZE                                               │
│  Cross-validate results against requirements                           │
│  Update evolution memory                                 │
│  Produce consensus matrix                                │
│  Route: CERTIFIED | TEMP_CERT | HUMAN_REVIEW | ABORT     │
└──────────────────────────────────────────────────────────┘
```

---

## §5 CREATE Mode

### Phase Sequence

| # | Phase | Gate |
|---|-------|------|
| 1 | **ELICIT** — Inversion pattern, one question at a time (§7) | All Qs answered |
| 2 | **SELECT TEMPLATE** — match skill type → template selection | Template chosen |
| 3 | **PLAN** — multi-pass self-review | Plan reviewed |
| 4 | **GENERATE** — fill template, no placeholders remain | Draft complete |
| 5 | **SECURITY SCAN** — CWE patterns | No P0 violations |
| 6 | **LEAN EVAL** — fast heuristic check (§6) | Score ≥ 350 (pass lean) |
| 7 | **FULL EVALUATE** — 4-phase pipeline if LEAN uncertain (§8) | Score ≥ 700 BRONZE |
| 8 | **INJECT UTE** — append `§UTE` section, fill placeholders (§15) | UTE section present |
| 9 | **DELIVER** — annotate, certify, write audit entry | CERTIFIED / TEMP_CERT |

### Template Selection

```
"calls API / integrates service"         → api-integration
"processes / transforms / validates data" → data-pipeline
"multi-step workflow / automation"        → workflow-automation
anything else                             → base
```

---

## §6 LEAN Mode (Fast Path ~1s)

**Purpose**: Rapid triage without LLM calls. Use for quick checks or high-volume screening.

### Scoring (500-point heuristic → maps to 1000-point scale)

| Check | Points |
|-------|--------|
| YAML frontmatter present (name, version, interface) | 60 |
| ≥ 3 mode sections (`## §N`) present | 60 |
| "Red Lines" / "严禁" text present | 50 |
| Quality Gates table with numeric thresholds | 60 |
| ≥ 2 code-block usage examples | 50 |
| Trigger keywords (EN + ZH) present for each mode | 60 per mode (max 120) |
| Security Baseline section present | 50 |
| No `{{PLACEHOLDER}}` tokens remaining | 50 |

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

## §7 Inversion — Requirement Elicitation

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
3. "是否需要与其他skill做配对排名？ / Pairwise ranking needed?"

### OPTIMIZE questions (ask all):
1. "请提供当前评测报告（分数 + 最低维度）。 / Provide the current eval report."
2. "已尝试过哪些优化？ / What optimizations were already attempted?"

---

## §8 EVALUATE Mode — 4-Phase Pipeline

**Total: 1000 points**

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
3. Phase 2: Text — 6 sub-dimensions
4. Phase 3: Runtime — benchmark test cases
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

---

## §9 OPTIMIZE Mode — 7-Dimension 9-Step Loop

### 7 Dimensions (with weights)

| Dimension | Weight | What It Covers |
|-----------|--------|----------------|
| System Design | 20% | Identity, architecture, Red Lines |
| Domain Knowledge | 20% | Template accuracy, field specificity |
| Workflow Definition | 20% | Phase sequence, exit criteria, loop gates |
| Error Handling | 15% | Recovery paths, escalation triggers |
| Examples | 15% | Usage examples count, quality, bilingual |
| Metadata | 10% | YAML frontmatter, versioning, tags |
| Long-Context | 10% | Section refs, chunking, cross-reference integrity |

### 9-Step Loop

```
Pre-loop — UTE bootstrap:
  IF skill has no §UTE section → INJECT UTE first (§15)
  ELSE → UPDATE UTE: refresh certified_lean_score to current LEAN score

Round N:
  1. READ    — score all 7 dimensions; identify lowest-scoring
  2. ANALYZE — Propose 3 targeted fixes for weakest dimension
  3. CURATE  — every 10 rounds: consolidate learning, prune stale context
  4. PLAN    — Review and select best fix strategy; log decision
  5. IMPLEMENT — apply atomic change (single dimension focus)
  6. VERIFY  — re-score; if score regressed → rollback; if no improvement → try fix #2
  7. HUMAN_REVIEW — trigger if total_score < 560 after round 10
  8. LOG     — record: round, dimension, delta, confidence, strategy_used
  9. COMMIT  — git commit every 10 rounds; tag with score

Convergence check (every round):
  IF volatility OR plateau OR trend=STABLE → STOP early

Post-loop — UTE update:
  Update use_to_evolve.certified_lean_score with final LEAN score
  Reset use_to_evolve.last_ute_check to today

Max rounds: 20 → if not BRONZE after round 20 → HUMAN_REVIEW
```

---

## §10 Self-Evolution (3-Trigger System)

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

---

## §11 Security

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

### Security Patterns (Regex)

```yaml
CWE-798:
  pattern: '(?i)(password|passwd|pwd|secret|token|key|api_key)\s*[=:]\s*["\'][^"\']{8,}["\']'
  severity: P0
  action: ABORT
  
CWE-89:
  pattern: '(?i)(SELECT|INSERT|UPDATE|DELETE|DROP|UNION).*\+.*\$|\$.*\+.*(SELECT|INSERT|UPDATE|DELETE)'
  severity: P0
  action: ABORT
  
CWE-78:
  pattern: '(?i)(exec|system|subprocess|spawn)\s*\(.*\$|\`.*\$.*\`'
  severity: P0
  action: ABORT
  
CWE-22:
  pattern: '(?i)\.\.[\\/]|\.(htaccess|git|env|config)'
  severity: P1
  action: WARN
```

---

## §12 Self-Review Protocol (Summary)

| Role | Responsibility |
|------|---------------|
| Pass 1 — Generate | Produce initial draft / score / fix proposal |
| Pass 2 — Review | Security + quality audit; severity-tagged issue list (ERROR/WARNING/INFO) |
| Pass 3 — Reconcile | Address all ERRORs, reconcile scores, produce final artifact |

Timeouts: 30 s per LLM, 60 s per phase, 180 s total (6 turns max).
Consensus: UNANIMOUS → proceed; MAJORITY → proceed with notes;
SPLIT → one revision; UNRESOLVED → HUMAN_REVIEW.

---

## §13 Audit Trail

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

## §14 Usage Examples

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

## §15 UTE Injection

**Use-to-Evolve (UTE)** is injected into every skill the framework creates or optimizes.
It makes the target skill self-improving through actual use — no scheduled jobs required.

### Injection Protocol (CREATE Step 8 / OPTIMIZE Pre-loop)

```
1. CHECK   — does skill already have §UTE section?
     YES → UPDATE: refresh certified_lean_score, reset last_ute_check
     NO  → INJECT: proceed below

2. LOAD    — read UTE snippet template

3. FILL PLACEHOLDERS:
     {{SKILL_NAME}}           = skill's `name` YAML field
     2.1.0              = skill's `version` YAML field
     {{FRAMEWORK_VERSION}}    = "2.1.0"
     {{INJECTION_DATE}}       = today ISO-8601
     {{CERTIFIED_LEAN_SCORE}} = LEAN score from Step 6 (or 350 if unknown)

4. APPEND  — add §UTE section after last ## §N section in skill

5. MERGE YAML — add use_to_evolve: block to skill's YAML frontmatter

6. LEAN RE-CHECK — run LEAN eval on injected skill
     IF lean_score regressed > 10 pts → revert injection, log warning

7. LOG — record in audit trail: {"ute_injected": true, "certified_lean_score": N}
```

### What UTE Adds to Target Skills

After injection, every target skill gains:

| Capability | Mechanism |
|-----------|-----------|
| Per-call usage recording | Post-Invocation Hook appended to skill context |
| Implicit feedback detection | Pattern match on user follow-up (correction / rephrasing / approval) |
| Trigger candidate collection | Rephrasing signals logged; count≥3 → micro-patch candidate |
| Lightweight check every 10 calls | Rolling 20-call success rate + trigger accuracy check |
| Full metric recompute every 50 calls | F1 / MRR / trigger_accuracy from usage log |
| Tier drift detection every 100 calls | Estimated LEAN vs certified baseline |
| Autonomous micro-patching | Keyword additions staged + LEAN-validated before apply |
| OPTIMIZE queue | Structural issues written to evolution-queue.jsonl |

### UTE Update (on OPTIMIZE)

When optimizing a skill that already has UTE:

```
1. Load current use_to_evolve.certified_lean_score
2. Load .skill-audit/evolution-queue.jsonl → read queued issues
3. Use queued issues as starting point for dimension analysis (Step 1 READ)
4. After all optimization rounds complete:
     update use_to_evolve.certified_lean_score = final_lean_score
     update use_to_evolve.last_ute_check = today
     clear processed items from evolution-queue.jsonl
```

This closes the feedback loop: UTE collects real-usage signals → queues them →
OPTIMIZE consumes the queue → updates UTE baseline → repeat.

---

## §16 INSTALL Mode

Installs skill-writer (this framework) to one or all supported platforms by fetching
from a URL or using local files. No evaluation or generation — pure deployment.

### Platform Path Map

| Platform | Install Path | Companion Files |
|----------|-------------|-----------------|
| claude   | `~/.claude/skills/skill-writer.md` | refs/, templates/, eval/, optimize/ |
| opencode | `~/.config/opencode/skills/skill-writer.md` | — |
| openclaw | `~/.openclaw/skills/skill-writer.md` | — |
| cursor   | `~/.cursor/skills/skill-writer.md` | — |
| gemini   | `~/.gemini/skills/skill-writer.md` | — |
| openai   | see platform docs | — |
| **all**  | all of the above | — |

### Trigger Patterns

```
"read <URL> and install"           → fetch URL, install to all platforms
"read <URL> and install to claude" → fetch URL, install to named platform only
"install skill-writer"             → install from local clone (all platforms)
"install skill-writer to cursor"   → install from local clone (single platform)
"安装 skill-writer"                → install to all platforms
"从 <URL> 安装"                    → fetch URL, install to all platforms
```

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

---

## §17 Triggers

**CREATE** | **LEAN** | **EVALUATE** | **OPTIMIZE** | **INSTALL**
**创建** | **快评** | **评测** | **优化** | **安装**

---

## §UTE Use-to-Evolve

<!-- Post-invocation protocol — auto-managed by skill-writer v2.1.0 -->
<!-- skill: skill-writer | version: 2.1.0 | injected: 2026-04-05T15:34:56.131Z -->

After each invocation, increment `use_to_evolve.cumulative_invocations`.
Run lightweight LEAN check every 10 invocations; full re-score every 50;
tier-drift detection every 100.

**Fields managed automatically** (do not edit manually):
- `cumulative_invocations` — incremented each use
- `last_ute_check` — ISO date of last lightweight check
- `pending_patches` — count of queued micro-patches
- `total_micro_patches_applied` — lifetime patch count

---

*Generated by skill-writer-builder v2.1.0*  
*For platform: OpenCode*  
*Last updated: 2026-04-05T15:34:56.131Z*


## CREATE Mode — Templates

### workflow-automation Template

# Template: Workflow Automation Skill

> **Type**: workflow-automation
> **Use when**: The skill orchestrates multiple steps, agents, or tools in a defined sequence to complete a multi-stage task.
> **Variables**: Replace every `{{PLACEHOLDER}}` with values from the requirement elicitation phase.

---

## How to fill this template

1. Replace all `{{PLACEHOLDER}}` tokens.
2. Map out every step in the `WORKFLOW_STEPS` table before writing the skill.
3. Define rollback actions for every step that mutates state.
4. Run EVALUATE mode before delivery.

---

```markdown
---
name: {{SKILL_NAME}}
version: "1.0.0"
description: "{{ONE_LINE_DESCRIPTION}} — automates {{WORKFLOW_NAME}} workflow."
description_i18n:
  en: "Automates {{WORKFLOW_NAME}}: {{EN_DESCRIPTION}}"
  zh: "自动化 {{WORKFLOW_NAME}}：{{ZH_DESCRIPTION}}"

license: MIT
author:
  name: {{AUTHOR}}
created: "{{DATE}}"
updated: "{{DATE}}"
type: workflow-automation

tags:
  - workflow
  - automation
  - {{WORKFLOW_DOMAIN}}
  - {{TAG_EXTRA}}

interface:
  input: user-natural-language
  output: workflow-execution-report
  modes: [run, dry-run, status, rollback]

workflow:
  name: "{{WORKFLOW_NAME}}"
  step_count: {{STEP_COUNT}}
  estimated_duration: "{{DURATION}}"   # e.g. "2–5 minutes"
  idempotent: {{true|false}}
  rollback_supported: {{true|false}}

use_to_evolve:
  enabled: true
  injected_by: "skill-writer v2.1.0"
  injected_at: "{{DATE}}"
  check_cadence: {lightweight: 10, full_recompute: 50, tier_drift: 100}
  micro_patch_enabled: true
  feedback_detection: true
  certified_lean_score: null
  last_ute_check: null
  pending_patches: 0
  total_micro_patches_applied: 0
  cumulative_invocations: 0
---

## §1  Identity

**Name**: {{SKILL_NAME}}
**Role**: {{WORKFLOW_NAME}} Orchestration Agent
**Purpose**: {{PURPOSE}}

**Workflow Overview**:
```
START
  │
  ▼
[STEP 1: {{STEP_1_NAME}}] ──── error ──→ ROLLBACK / ABORT
  │ success
  ▼
[STEP 2: {{STEP_2_NAME}}] ──── error ──→ ROLLBACK / ABORT
  │ success
  ▼
[STEP N: {{STEP_N_NAME}}] ──── error ──→ ROLLBACK / ABORT
  │ success
  ▼
END → execution report
```

**Human Checkpoints** (pause and wait for approval before continuing):
- Before Step `{{CHECKPOINT_STEP}}`: "{{CHECKPOINT_REASON}}"
- Before any destructive action

**Red Lines (严禁)**:
- 严禁 skip human checkpoints at destructive steps
- 严禁 execute RUN mode on production environment without explicit confirmation
- 严禁 proceed after 3 consecutive step failures without escalation
- 严禁 rollback without logging the rollback reason and pre-rollback state

---

## §2  Workflow Steps

| Step | Name | Action | Tool / Agent | Rollback Action | Timeout |
|------|------|--------|--------------|-----------------|---------|
| 1 | {{STEP_1_NAME}} | {{STEP_1_ACTION}} | {{STEP_1_TOOL}} | {{STEP_1_ROLLBACK}} | {{TIMEOUT_1}} |
| 2 | {{STEP_2_NAME}} | {{STEP_2_ACTION}} | {{STEP_2_TOOL}} | {{STEP_2_ROLLBACK}} | {{TIMEOUT_2}} |
| 3 | {{STEP_3_NAME}} | {{STEP_3_ACTION}} | {{STEP_3_TOOL}} | {{STEP_3_ROLLBACK}} | {{TIMEOUT_3}} |
| N | {{STEP_N_NAME}} | {{STEP_N_ACTION}} | {{STEP_N_TOOL}} | {{STEP_N_ROLLBACK}} | {{TIMEOUT_N}} |

**Parallel Steps** (can run concurrently): Steps {{PARALLEL_STEPS}}

**Dependencies**:
- Step 2 requires Step 1 output: `{{DEPENDENCY_1}}`
- Step N requires Steps {{DEPENDENCY_N_PREREQS}} complete

---

## §3  RUN Mode

**Triggers**: run, execute, start, begin, go, 运行, 执行, 开始

**Pre-flight Checks** (fail fast before any step):
1. Verify required env vars: `{{ENV_VAR_LIST}}`
2. Verify required permissions: `{{PERMISSION_LIST}}`
3. Verify target environment: `{{ENV_CHECK}}`
4. Confirm with user: "Ready to run {{WORKFLOW_NAME}} on {{TARGET}}. Proceed? [y/n]"

**Execution Loop**:
```
FOR each step in §2:
  1. Log: "Step N/{{STEP_COUNT}}: {{STEP_NAME}} — starting"
  2. Execute step action
  3. Wait for completion or timeout
  4. IF success → log result → continue
  5. IF failure → classify (transient | permanent)
       transient → retry (max 3, backoff 2s/4s/8s)
       permanent → ROLLBACK from current step backward → ABORT
  6. IF checkpoint step → pause → request human approval
```

**Exit Criteria**: All steps complete with success; execution report delivered.

---

## §4  DRY-RUN Mode

**Triggers**: dry-run, preview, simulate, what-would, 预演, 模拟, 预览

**Purpose**: Show exactly what RUN mode would do — without executing any mutations.

**Steps**:
1. Run all pre-flight checks (§3)
2. For each step: log planned action + estimated output (no execution)
3. Identify checkpoints and destructive steps
4. Estimate total duration
5. Report: "DRY-RUN complete — N steps planned, M checkpoints, K destructive steps"

**Exit Criteria**: Full plan presented; user can choose to proceed with RUN.

---

## §5  STATUS Mode

**Triggers**: status, progress, check, where are we, 状态, 进度, 查看

**Output**:
```
Workflow: {{WORKFLOW_NAME}}
Run ID: <uuid>
Status: RUNNING | PAUSED | COMPLETED | FAILED | ROLLED_BACK
Current step: N / {{STEP_COUNT}} ({{STEP_NAME}})
Steps completed: [1 ✓, 2 ✓, ..., N ⟳]
Steps pending: [N+1, ..., {{STEP_COUNT}}]
Errors: <count> | Last error: <message>
Duration so far: <elapsed>
```

---

## §6  ROLLBACK Mode

**Triggers**: rollback, undo, revert, cancel, 回滚, 撤销, 还原

**Pre-conditions**:
- Workflow must be in FAILED or PAUSED state
- Rollback actions defined for completed steps (§2 table)

**Rollback Sequence** (reverse order of completed steps):
```
FOR each completed step (N → 1):
  1. Log: "Rolling back Step N: {{STEP_NAME}}"
  2. Execute rollback action from §2 table
  3. Verify rollback success
  4. IF rollback fails → log as ROLLBACK_PARTIAL → escalate to human
```

**Post-rollback Report**:
```
Rollback completed: <timestamp>
Steps rolled back: N
Steps that could not roll back: M (manual intervention required)
System state: RESTORED | PARTIALLY_RESTORED
```

---

## §7  Quality Gates

| Metric | Threshold |
|--------|-----------|
| F1 | ≥ 0.90 |
| MRR | ≥ 0.85 |
| Trigger Accuracy | ≥ 0.90 |
| Step Success Rate | ≥ 95% (in test runs) |
| Rollback Coverage | 100% of mutating steps have defined rollback |
| Checkpoint Coverage | 100% of destructive steps have human checkpoint |

---

## §8  Security Baseline

- **CWE-78**: Shell commands constructed from validated, whitelisted parameters only
- **CWE-22**: File paths validated — no path traversal (`../`)
- **CWE-798**: No credentials in workflow definition — use env vars
- **Least Privilege**: Each step tool runs with minimal required permissions

---

## §9  Usage Examples

### Full workflow run

**Input**: "run {{WORKFLOW_NAME}} on {{EXAMPLE_TARGET}}"

```
Mode: RUN | Target: {{EXAMPLE_TARGET}} | Steps: {{STEP_COUNT}}
Pre-flight: ✓ env vars | ✓ permissions | ✓ target
Step 1/N: {{STEP_1_NAME}} ✓ (1.2s)
Step 2/N: {{STEP_2_NAME}} ✓ (0.8s)
[CHECKPOINT] Step 3: destructive — awaiting approval...
  User: approved
Step 3/N: {{STEP_3_NAME}} ✓ (2.1s)
...
Workflow COMPLETED | Duration: Xs | Status: ALL STEPS OK
```

### Dry run preview

**Input**: "dry-run {{WORKFLOW_NAME}}"

```
Mode: DRY-RUN
Plan:
  Step 1: [READ]  {{STEP_1_ACTION}} — no mutation
  Step 2: [WRITE] {{STEP_2_ACTION}} — DESTRUCTIVE ⚠
  Step 3: [READ]  {{STEP_3_ACTION}} — no mutation
Checkpoints: 1 | Destructive steps: 1
Estimated duration: {{DURATION}}
Proceed with RUN? [y/n]
```

---

**Triggers**: **run** | **dry-run** | **status** | **rollback** | **运行** | **预演** | **状态** | **回滚**

---

## §UTE Use-to-Evolve

<!-- Post-invocation protocol — auto-managed by skill-writer v2.1.0 -->

After each invocation, increment `use_to_evolve.cumulative_invocations`.
Run lightweight LEAN check every 10 invocations; full re-score every 50;
tier-drift detection every 100.

**Fields managed automatically** (do not edit manually):
- `cumulative_invocations` — incremented each use
- `last_ute_check` — ISO date of last lightweight check
- `pending_patches` — count of queued micro-patches
- `total_micro_patches_applied` — lifetime patch count
```

---

## Checklist before delivery

- [ ] All workflow steps listed with names, actions, tools, and rollback actions
- [ ] Parallel steps identified and dependencies mapped
- [ ] Human checkpoints defined for ALL destructive steps (no exceptions)
- [ ] Retry logic specified: max retries + backoff (1s, 2s, 4s)
- [ ] Rollback sequence covers ALL mutating steps
- [ ] DRY-RUN mode implemented and tested
- [ ] `use_to_evolve:` block present in YAML frontmatter with all 11 fields
- [ ] `## §UTE Use-to-Evolve` section present at end of skill
- [ ] LEAN eval score ≥ 350 and no `{{PLACEHOLDER}}` remaining
- [ ] Full EVALUATE score ≥ 700 (BRONZE) confirmed
- [ ] Security scan P0 clear: CWE-78 (command injection), CWE-798 (credentials)
- [ ] If TEMP_CERT issued: add `TEMP_CERT: true` to YAML, re-evaluate within 72 h


---

### data-pipeline Template

# Template: Data Pipeline Skill

> **Type**: data-pipeline
> **Use when**: The skill ingests, transforms, validates, or exports structured/unstructured data.
> **Variables**: Replace every `{{PLACEHOLDER}}` with values from the requirement elicitation phase.

---

## How to fill this template

1. Replace all `{{PLACEHOLDER}}` tokens.
2. Define schema for `INPUT_SCHEMA` and `OUTPUT_SCHEMA` concretely.
3. Specify every transformation step with input/output types.
4. Run EVALUATE mode before delivery.

---

```markdown
---
name: {{SKILL_NAME}}
version: "1.0.0"
description: "{{ONE_LINE_DESCRIPTION}} — data pipeline for {{DATA_DOMAIN}}."
description_i18n:
  en: "Data pipeline: {{EN_DESCRIPTION}}"
  zh: "数据管道：{{ZH_DESCRIPTION}}"

license: MIT
author:
  name: {{AUTHOR}}
created: "{{DATE}}"
updated: "{{DATE}}"
type: data-pipeline

tags:
  - data
  - pipeline
  - {{DATA_DOMAIN}}
  - {{TAG_EXTRA}}

interface:
  input: {{INPUT_FORMAT}}       # e.g. csv, json, plain-text, multimodal
  output: {{OUTPUT_FORMAT}}     # e.g. json, csv, markdown-table
  modes: [ingest, transform, validate, export]

pipeline:
  input_schema: "{{INPUT_SCHEMA_REF}}"    # path or inline
  output_schema: "{{OUTPUT_SCHEMA_REF}}"
  max_record_count: {{MAX_RECORDS}}       # safety limit
  chunk_size: {{CHUNK_SIZE}}              # for streaming/large files

use_to_evolve:
  enabled: true
  injected_by: "skill-writer v2.1.0"
  injected_at: "{{DATE}}"
  check_cadence: {lightweight: 10, full_recompute: 50, tier_drift: 100}
  micro_patch_enabled: true
  feedback_detection: true
  certified_lean_score: null
  last_ute_check: null
  pending_patches: 0
  total_micro_patches_applied: 0
  cumulative_invocations: 0
---

## §1  Identity

**Name**: {{SKILL_NAME}}
**Role**: {{DATA_DOMAIN}} Data Pipeline Agent
**Purpose**: {{PURPOSE}}

**Pipeline Stages**:
```
[INPUT: {{INPUT_FORMAT}}]
    │
    ▼
[INGEST] → validate format, detect encoding, count records
    │
    ▼
[TRANSFORM] → {{TRANSFORM_STEP_1}} → {{TRANSFORM_STEP_2}}
    │
    ▼
[VALIDATE] → schema check, null/type check, business rules
    │
    ▼
[EXPORT: {{OUTPUT_FORMAT}}]
```

**Red Lines (严禁)**:
- 严禁 process more than `{{MAX_RECORDS}}` records without explicit confirmation
- 严禁 discard records silently — log every dropped record with reason
- 严禁 output data without passing schema validation
- 严禁 skip chunk validation when processing segmented files

---

## §2  Loop — Plan-Execute-Summarize

| Phase | Description | Exit Criteria |
|-------|-------------|---------------|
| 1 INGEST | Load input, detect format, validate encoding | Record count reported |
| 2 CHUNK | Split into chunks of `{{CHUNK_SIZE}}` if > `{{CHUNK_THRESHOLD}}` records | Chunks ready |
| 3 TRANSFORM | Apply transformation rules per §3 | All chunks transformed |
| 4 VALIDATE | Run schema + business rule checks per §4 | Validation report ready |
| 5 EXPORT | Serialize to `{{OUTPUT_FORMAT}}`, write to destination | File/stream complete |
| 6 SUMMARIZE | Counts: input/output/dropped/errors; quality score | Summary delivered |

---

## §3  TRANSFORM Mode

**Triggers**: transform, convert, process, parse, 转换, 处理, 解析

**Transformation Rules**:

| Step | Input Field | Operation | Output Field | Type |
|------|-------------|-----------|--------------|------|
| T1 | `{{FIELD_1}}` | {{OPERATION_1}} | `{{OUT_FIELD_1}}` | {{TYPE_1}} |
| T2 | `{{FIELD_2}}` | {{OPERATION_2}} | `{{OUT_FIELD_2}}` | {{TYPE_2}} |
| T3 | `{{FIELD_3}}` | {{OPERATION_3}} | `{{OUT_FIELD_3}}` | {{TYPE_3}} |

**Null Handling**: `{{NULL_STRATEGY}}` — one of: drop-record | fill-default | pass-through | error

**Encoding**: Normalize all strings to UTF-8. Log non-UTF-8 bytes as warnings.

**Exit Criteria**: All records transformed or quarantined with reason codes.

---

## §4  VALIDATE Mode

**Triggers**: validate, check, verify, 验证, 校验, 检查

**Validation Rules**:

| Rule ID | Field | Check | Severity | Action on Fail |
|---------|-------|-------|----------|----------------|
| V1 | `{{FIELD_1}}` | not null | ERROR | quarantine record |
| V2 | `{{FIELD_2}}` | type = {{TYPE}} | ERROR | quarantine record |
| V3 | `{{FIELD_3}}` | value in {{ALLOWED_VALUES}} | WARNING | flag record |
| V4 | (cross-field) | {{BUSINESS_RULE}} | ERROR | quarantine record |

**Quarantine**: Failed records written to separate quarantine output with rule ID + reason.
**Threshold**: If quarantine rate > `{{MAX_QUARANTINE_PCT}}`% → ABORT and request human review.

**Exit Criteria**: Validation report produced; quarantine rate ≤ `{{MAX_QUARANTINE_PCT}}`%.

---

## §5  INGEST Mode

**Triggers**: ingest, load, import, read, 导入, 加载, 读取

**Supported Formats**: `{{INPUT_FORMAT_LIST}}`  (e.g. CSV, JSON, JSONL, TSV, Parquet)

**Steps**:
1. Detect file format by extension and magic bytes
2. Validate encoding (prefer UTF-8; normalize if needed)
3. Count total records; report to user before proceeding
4. If records > `{{MAX_RECORDS}}` → ask user confirmation before continuing
5. Sample first 5 records → show schema preview → confirm

**Exit Criteria**: Record count confirmed, schema preview approved, chunks queued.

---

## §6  EXPORT Mode

**Triggers**: export, save, write, output, 导出, 保存, 输出

**Output Schema**:
```json
{
  "{{OUT_FIELD_1}}": "{{TYPE_1}}",
  "{{OUT_FIELD_2}}": "{{TYPE_2}}",
  "{{OUT_FIELD_3}}": "{{TYPE_3}}"
}
```

**Output Destination**: `{{OUTPUT_PATH}}` (configurable; default: `./output/{{SKILL_NAME}}_<timestamp>.{{OUTPUT_EXT}}`)

**Summary Footer** (always appended):
```
Pipeline run: <timestamp>
Input records: N | Transformed: N | Validated: N | Quarantined: N | Exported: N
Quarantine rate: X% | Status: PASS/FAIL
```

---

## §7  Quality Gates

| Metric | Threshold |
|--------|-----------|
| F1 | ≥ 0.90 |
| MRR | ≥ 0.85 |
| Trigger Accuracy | ≥ 0.90 |
| Schema Compliance | 100% of exported records match output schema |
| Quarantine Rate | ≤ `{{MAX_QUARANTINE_PCT}}`% |
| Data Loss | 0% (every input record accounted for) |

---

## §8  Security Baseline

- **CWE-89**: Input fields sanitized before any query construction
- **CWE-79**: String fields escaped before Markdown/HTML output
- **CWE-22**: Output path validated — no path traversal (`../`)
- **Data Privacy**: PII fields `{{PII_FIELDS}}` — mask/redact per `{{PRIVACY_POLICY}}`

---

## §9  Usage Examples

### Single file transform

**Input**: "convert {{EXAMPLE_FILE}} from CSV to JSON, apply {{TRANSFORM_STEP_1}}"

```
Mode: TRANSFORM | Records: 1,240 | Chunks: 3
T1: applied to 1,240 records
T2: applied to 1,238 records (2 null → quarantined)
Exported: output/{{SKILL_NAME}}_20260101.json
Summary: Input=1240 Transformed=1238 Quarantined=2 (0.16%) → PASS
```

### Validate only

**Input**: "validate data in {{EXAMPLE_FILE}} against schema"

```
Mode: VALIDATE | Records: 500
V1 PASS: 500/500
V2 PASS: 500/500
V3 WARN: 12 records flagged (2.4%)
V4 FAIL: 3 records quarantined
Quarantine rate: 0.6% ≤ 5% → PASS
```

---

**Triggers**: **transform** | **validate** | **ingest** | **export** | **转换** | **验证** | **导入** | **导出**

---

## §UTE Use-to-Evolve

<!-- Post-invocation protocol — auto-managed by skill-writer v2.1.0 -->

After each invocation, increment `use_to_evolve.cumulative_invocations`.
Run lightweight LEAN check every 10 invocations; full re-score every 50;
tier-drift detection every 100.

**Fields managed automatically** (do not edit manually):
- `cumulative_invocations` — incremented each use
- `last_ute_check` — ISO date of last lightweight check
- `pending_patches` — count of queued micro-patches
- `total_micro_patches_applied` — lifetime patch count
```

---

## Checklist before delivery

- [ ] Input schema and output schema both defined concretely (field names + types)
- [ ] Every transformation step specifies input type → output type
- [ ] Null handling strategy chosen and documented (drop/fill/pass/error)
- [ ] Quarantine threshold set (`MAX_QUARANTINE_PCT`) and enforced
- [ ] Record count safety limit (`MAX_RECORDS`) set with user confirmation gate
- [ ] PII fields identified and masking policy documented
- [ ] `use_to_evolve:` block present in YAML frontmatter with all 11 fields
- [ ] `## §UTE Use-to-Evolve` section present at end of skill
- [ ] LEAN eval score ≥ 350 and no `{{PLACEHOLDER}}` remaining
- [ ] Full EVALUATE score ≥ 700 (BRONZE) confirmed
- [ ] Security scan P0 clear: CWE-89 (query construction), CWE-22 (output path)
- [ ] If TEMP_CERT issued: add `TEMP_CERT: true` to YAML, re-evaluate within 72 h


---

### base Template

# Template: Base Skill

> **Type**: base
> **Use when**: The skill doesn't fit a more specific category (api-integration, data-pipeline, workflow-automation).
> **Variables**: Replace every `{{PLACEHOLDER}}` with values from the requirement elicitation phase (§6 of skill-writer.md).

---

## How to fill this template

1. Replace all `{{PLACEHOLDER}}` tokens with values gathered from §6 questions.
2. Delete any section marked `<!-- OPTIONAL -->` if not applicable.
3. Run the EVALUATE mode (§4) before delivery — minimum F1 ≥ 0.90.

---

```markdown
---
name: {{SKILL_NAME}}
version: "1.0.0"
description: "{{ONE_LINE_DESCRIPTION}}"
description_i18n:
  en: "{{EN_DESCRIPTION}}"
  zh: "{{ZH_DESCRIPTION}}"

license: MIT
author:
  name: {{AUTHOR}}
created: "{{DATE}}"
updated: "{{DATE}}"
type: {{SKILL_TYPE}}          # e.g. assistant, tool-wrapper, analyzer

tags:
  - {{TAG_1}}
  - {{TAG_2}}

interface:
  input: {{INPUT_FORMAT}}     # e.g. user-natural-language, structured-json
  output: {{OUTPUT_FORMAT}}   # e.g. text, json, markdown
  modes: [{{MODE_1}}, {{MODE_2}}]

use_to_evolve:
  enabled: true
  injected_by: "skill-writer v2.1.0"
  injected_at: "{{DATE}}"
  check_cadence: {lightweight: 10, full_recompute: 50, tier_drift: 100}
  micro_patch_enabled: true
  feedback_detection: true
  certified_lean_score: null
  last_ute_check: null
  pending_patches: 0
  total_micro_patches_applied: 0
  cumulative_invocations: 0
---

## §1  Identity

**Name**: {{SKILL_NAME}}
**Role**: {{ROLE_DESCRIPTION}}
**Purpose**: {{PURPOSE}}

**Core Principles**:
- {{PRINCIPLE_1}}
- {{PRINCIPLE_2}}
- {{PRINCIPLE_3}}

**Red Lines (严禁)**:
- 严禁 {{RED_LINE_1}}
- 严禁 {{RED_LINE_2}}

---

## §2  Loop — Plan-Execute-Summarize

| Phase | Name | Description | Exit Criteria |
|-------|------|-------------|---------------|
| 1 | **PARSE** | Extract intent from user input | Intent identified |
| 2 | **PLAN** | Decide approach based on intent | Plan ready |
| 3 | **EXECUTE** | Perform core task | Task complete |
| 4 | **SUMMARIZE** | Validate result against acceptance criteria | Result verified |
| 5 | **DELIVER** | Present output to user | User acknowledged |

---

## §3  {{MODE_1}} Mode

**Triggers**: {{MODE_1_TRIGGER_EN}} | {{MODE_1_TRIGGER_ZH}}

**Input**: {{MODE_1_INPUT}}

**Steps**:
1. {{STEP_1}}
2. {{STEP_2}}
3. {{STEP_3}}

**Output**: {{MODE_1_OUTPUT}}

**Exit Criteria**: {{MODE_1_EXIT}}

---

## §4  {{MODE_2}} Mode   <!-- OPTIONAL: remove if only one mode -->

**Triggers**: {{MODE_2_TRIGGER_EN}} | {{MODE_2_TRIGGER_ZH}}

**Input**: {{MODE_2_INPUT}}

**Steps**:
1. {{STEP_1}}
2. {{STEP_2}}

**Output**: {{MODE_2_OUTPUT}}

**Exit Criteria**: {{MODE_2_EXIT}}

---

## §5  Quality Gates

| Metric | Threshold | Measured By |
|--------|-----------|-------------|
| F1 | ≥ 0.90 | claude/eval/rubrics.md |
| MRR | ≥ 0.85 | claude/eval/rubrics.md |
| Trigger Accuracy | ≥ 0.90 | claude/eval/benchmarks.md |

---

## §6  Security Baseline

Scan before delivery:
- CWE-798: No hardcoded credentials
- CWE-89: No unsanitized SQL
- CWE-79: No unsanitized HTML output
- CWE-94: No eval/exec with user input

---

## §7  Usage Examples

### {{EXAMPLE_1_TITLE}}

**Input**: "{{EXAMPLE_1_INPUT}}"

```
Mode: {{MODE_1}} | Confidence: 0.90 | Language: {{LANG}}
Output: {{EXAMPLE_1_OUTPUT}}
```

### {{EXAMPLE_2_TITLE}}   <!-- OPTIONAL -->

**Input**: "{{EXAMPLE_2_INPUT}}"

```
Mode: {{MODE_2}} | Confidence: 0.88
Output: {{EXAMPLE_2_OUTPUT}}
```

---

**Triggers**: **{{MODE_1_TRIGGER_EN}}** | **{{MODE_1_TRIGGER_ZH}}** | **{{MODE_2_TRIGGER_EN}}** | **{{MODE_2_TRIGGER_ZH}}**

---

## §UTE Use-to-Evolve

<!-- Post-invocation protocol — auto-managed by skill-writer v2.1.0 -->

After each invocation, increment `use_to_evolve.cumulative_invocations`.
Run lightweight LEAN check every 10 invocations; full re-score every 50;
tier-drift detection every 100.

**Fields managed automatically** (do not edit manually):
- `cumulative_invocations` — incremented each use
- `last_ute_check` — ISO date of last lightweight check
- `pending_patches` — count of queued micro-patches
- `total_micro_patches_applied` — lifetime patch count
```

---

## Checklist before delivery

- [ ] All `{{PLACEHOLDER}}` tokens replaced
- [ ] At least 2 usage examples present (EN + ZH triggers shown)
- [ ] Quality gates section complete with numeric thresholds (F1 ≥ 0.90, MRR ≥ 0.85)
- [ ] Security baseline section present with specific field names per CWE
- [ ] Red Lines section present with ≥ 3 specific prohibitions
- [ ] `use_to_evolve:` block present in YAML frontmatter with all 11 fields
- [ ] `## §UTE Use-to-Evolve` section present at end of skill
- [ ] LEAN eval score ≥ 350 (lean_score/500)
- [ ] Full EVALUATE score ≥ 700 (BRONZE) confirmed
- [ ] No P0 CWE violations (see `claude/refs/security-patterns.md`)
- [ ] If confidence < 0.70 on delivery: add `TEMP_CERT: true` to YAML frontmatter
      and schedule 72 h re-evaluation window


---

### api-integration Template

# Template: API Integration Skill

> **Type**: api-integration
> **Use when**: The skill calls one or more external APIs / third-party services.
> **Variables**: Replace every `{{PLACEHOLDER}}` with values from the requirement elicitation phase.

---

## How to fill this template

1. Replace all `{{PLACEHOLDER}}` tokens.
2. Fill in `API_BASE_URL`, `AUTH_METHOD`, `ENDPOINTS` from the target API's documentation.
3. Never hardcode credentials — document the env-var name instead (CWE-798).
4. Run EVALUATE mode before delivery.

---

```markdown
---
name: {{SKILL_NAME}}
version: "1.0.0"
description: "{{ONE_LINE_DESCRIPTION}} — integrates {{API_NAME}} API."
description_i18n:
  en: "Integrates {{API_NAME}}: {{EN_DESCRIPTION}}"
  zh: "集成 {{API_NAME}}：{{ZH_DESCRIPTION}}"

license: MIT
author:
  name: {{AUTHOR}}
created: "{{DATE}}"
updated: "{{DATE}}"
type: api-integration

tags:
  - api
  - {{API_NAME_LOWER}}
  - {{TAG_EXTRA}}

interface:
  input: user-natural-language
  output: {{OUTPUT_FORMAT}}     # e.g. structured-json, text-summary
  modes: [query, batch]         # adjust as needed

api:
  name: {{API_NAME}}
  base_url: "{{API_BASE_URL}}"
  auth_method: {{AUTH_METHOD}}  # bearer-token | api-key-header | oauth2 | none
  auth_env_var: "{{AUTH_ENV_VAR}}"  # e.g. OPENWEATHER_API_KEY
  rate_limit: "{{RATE_LIMIT}}"  # e.g. 60 req/min
  docs_url: "{{API_DOCS_URL}}"

use_to_evolve:
  enabled: true
  injected_by: "skill-writer v2.1.0"
  injected_at: "{{DATE}}"
  check_cadence: {lightweight: 10, full_recompute: 50, tier_drift: 100}
  micro_patch_enabled: true
  feedback_detection: true
  certified_lean_score: null
  last_ute_check: null
  pending_patches: 0
  total_micro_patches_applied: 0
  cumulative_invocations: 0
---

## §1  Identity

**Name**: {{SKILL_NAME}}
**Role**: {{API_NAME}} Integration Agent
**Purpose**: {{PURPOSE}}

**Key Endpoints Used**:
| Endpoint | Method | Purpose |
|----------|--------|---------|
| `{{ENDPOINT_1_PATH}}` | {{HTTP_METHOD}} | {{ENDPOINT_1_PURPOSE}} |
| `{{ENDPOINT_2_PATH}}` | {{HTTP_METHOD}} | {{ENDPOINT_2_PURPOSE}} |

**Authentication**: Reads `{{AUTH_ENV_VAR}}` from environment. NEVER embed credentials in skill.

**Red Lines (严禁)**:
- 严禁 hardcode API keys, tokens, or passwords (CWE-798)
- 严禁 pass raw user input as query parameters without sanitization
- 严禁 expose raw API error messages containing internal details to end-users
- 严禁 retry indefinitely — max 3 retries with exponential backoff

---

## §2  Loop — Plan-Execute-Summarize

| Phase | Description | Exit Criteria |
|-------|-------------|---------------|
| 1 PARSE | Extract query intent + parameters from user input | Parameters identified |
| 2 AUTHENTICATE | Verify `{{AUTH_ENV_VAR}}` is set and valid | Auth confirmed |
| 3 CALL API | Construct request → call `{{API_NAME}}` → handle response | HTTP 2xx received |
| 4 PARSE RESPONSE | Extract relevant fields, map to output schema | Data mapped |
| 5 FORMAT | Apply output format (`{{OUTPUT_FORMAT}}`) | Formatted result ready |
| 6 DELIVER | Return result to user with source attribution | User acknowledged |

**Error Handling**:
- HTTP 4xx → parse error message → surface human-readable version
- HTTP 429 → wait `Retry-After` header seconds → retry (max 3)
- HTTP 5xx → retry with backoff (1s, 2s, 4s) → HUMAN_REVIEW after 3 failures
- Network timeout (>10s) → retry once → surface error

---

## §3  QUERY Mode

**Triggers**: query, fetch, get, retrieve, look up, 查询, 获取, 搜索

**Input**: User's natural language query describing what to retrieve.

**Steps**:
1. Parse user intent → extract key parameters (e.g. location, date, ID)
2. Map parameters to `{{ENDPOINT_1_PATH}}` request schema
3. Call API with `Authorization: {{AUTH_METHOD}} ${{AUTH_ENV_VAR}}`
4. Parse response → extract `{{RESPONSE_FIELDS}}`
5. Format output per `{{OUTPUT_FORMAT}}` schema
6. Attribute source: "Data from {{API_NAME}}"

**Output**:
```
{{SKILL_NAME}} result:
  {{OUTPUT_FIELD_1}}: <value>
  {{OUTPUT_FIELD_2}}: <value>
  source: {{API_NAME}} | retrieved: <timestamp>
```

**Exit Criteria**: Result delivered or error surfaced with actionable message.

---

## §4  BATCH Mode   <!-- remove if not needed -->

**Triggers**: batch, bulk, multiple, list of, 批量, 多个

**Input**: List of query parameters (comma-separated or JSON array).

**Steps**:
1. Parse list → validate item count ≤ `{{BATCH_LIMIT}}`
2. For each item: call QUERY Mode (§3)
3. Collect results → deduplicate → sort
4. Return consolidated report

**Rate Limiting**: Respect `{{RATE_LIMIT}}` — insert delay between calls if needed.

**Exit Criteria**: All items processed; partial failures listed separately.

---

## §5  Quality Gates

| Metric | Threshold |
|--------|-----------|
| F1 | ≥ 0.90 |
| MRR | ≥ 0.85 |
| Trigger Accuracy | ≥ 0.90 |
| API Auth Coverage | 100% of calls authenticated |
| Error Handling Coverage | HTTP 4xx, 429, 5xx, timeout all handled |

---

## §6  Security Baseline

- **CWE-798**: `{{AUTH_ENV_VAR}}` loaded from env, never hardcoded
- **CWE-89**: Query params sanitized before URL construction
- **CWE-79**: API response fields escaped before Markdown/HTML rendering
- **Input Validation**: `{{PARAM_1}}` type-checked as `{{PARAM_1_TYPE}}`

---

## §7  Usage Examples

### Example — single query

**Input**: "{{EXAMPLE_QUERY}}"

```
Mode: QUERY | API: {{API_NAME}} | Language: EN
Endpoint: GET {{ENDPOINT_1_PATH}}?{{PARAM_1}}={{EXAMPLE_VALUE}}
Output:
  {{OUTPUT_FIELD_1}}: {{EXAMPLE_RESULT_1}}
  {{OUTPUT_FIELD_2}}: {{EXAMPLE_RESULT_2}}
  source: {{API_NAME}}
```

### Example — batch query

**Input**: "{{EXAMPLE_BATCH_INPUT}}"

```
Mode: BATCH | items: 3
Results: [item1_result, item2_result, item3_result]
Errors: none
```

---

**Triggers**: **query** | **fetch** | **get** | **retrieve** | **查询** | **获取** | **搜索**

---

## §UTE Use-to-Evolve

<!-- Post-invocation protocol — auto-managed by skill-writer v2.1.0 -->

After each invocation, increment `use_to_evolve.cumulative_invocations`.
Run lightweight LEAN check every 10 invocations; full re-score every 50;
tier-drift detection every 100.

**Fields managed automatically** (do not edit manually):
- `cumulative_invocations` — incremented each use
- `last_ute_check` — ISO date of last lightweight check
- `pending_patches` — count of queued micro-patches
- `total_micro_patches_applied` — lifetime patch count
```

---

## Checklist before delivery

- [ ] `{{AUTH_ENV_VAR}}` documented in Security Baseline — no credential values written
- [ ] All HTTP error codes handled: 4xx, 429, 5xx, timeout
- [ ] Rate limit respected in BATCH mode; BATCH_LIMIT set
- [ ] Response fields sanitized before output (CWE-79)
- [ ] `use_to_evolve:` block present in YAML frontmatter with all 11 fields
- [ ] `## §UTE Use-to-Evolve` section present at end of skill
- [ ] LEAN eval score ≥ 350 and no `{{PLACEHOLDER}}` remaining
- [ ] Full EVALUATE score ≥ 700 (BRONZE) confirmed
- [ ] Security scan P0 clear: CWE-798, CWE-89, CWE-78 (see `claude/refs/security-patterns.md`)
- [ ] If TEMP_CERT issued: add `TEMP_CERT: true` to YAML, re-evaluate within 72 h


## EVALUATE Mode — Quality Assessment

EVALUATE mode provides rigorous, standardized quality assessment for skills.

### Scoring Rubrics

# Evaluation Rubrics

> **Purpose**: 4-phase 1000-point scoring pipeline used by EVALUATE mode.
> **Load**: When §8 (EVALUATE Mode) of `claude/skill-writer.md` is accessed.
> **Main doc**: `claude/skill-writer.md §8`

---

## §1  Pipeline Overview

```
Total: 1000 points

Phase 1 — Parse & Validate   (0–100 pts)   Heuristic, no LLM
Phase 2 — Text Quality       (0–300 pts)   Static analysis, Pass 1
Phase 3 — Runtime Testing    (0–400 pts)   Benchmark tests, Pass 2
Phase 4 — Certification      (0–200 pts)   Variance + security + gates, Pass 3

Variance formula:  variance = | phase2/3 − phase3/4 |
```

---

## §2  Certification Tiers

| Tier | Min Score | Max Variance | Phase 2 Min | Phase 3 Min |
|------|-----------|-------------|------------|------------|
| **PLATINUM** | ≥ 950 | < 10 | ≥ 270 | ≥ 360 |
| **GOLD** | ≥ 900 | < 15 | ≥ 255 | ≥ 340 |
| **SILVER** | ≥ 800 | < 20 | ≥ 225 | ≥ 300 |
| **BRONZE** | ≥ 700 | < 30 | ≥ 195 | ≥ 265 |
| **FAIL** | < 700 | any | — | — |

**Variance interpretation**: High variance means the artifact "looks good on paper but
fails runtime" (Phase2 >> Phase3) or "passes tests but is poorly written" (Phase3 >> Phase2).
Both indicate quality inconsistency and cap the certification tier.

---

## §3  Phase 1 — Parse & Validate (0–100 pts)

Heuristic checks only. Fast, no LLM.

| Check | Points | Notes |
|-------|--------|-------|
| YAML frontmatter present | 10 | Must have at least `name`, `version` |
| `name` field present and non-empty | 5 | |
| `version` field follows semver | 5 | Pattern: `N.N.N` |
| `interface.modes` array present | 5 | |
| `tags` array with ≥ 2 entries | 5 | |
| ≥ 3 `## §N` sections | 10 | Identity, Loop, at least one mode |
| Identity section present (name/role/purpose) | 10 | |
| Red Lines / 严禁 section present | 10 | |
| Quality Gates section with numeric thresholds | 15 | Thresholds must be numbers |
| No `{{PLACEHOLDER}}` tokens remaining | 15 | Any remaining = hard deduction |
| No TODO / FIXME markers | 5 | Advisory |
| File size reasonable (< 500 lines) | 5 | > 500 lines: advisory warning |

**Hard deduction**: If `{{PLACEHOLDER}}` found → Phase1 score capped at 60, WARNING issued.

---

## §4  Phase 2 — Text Quality (0–300 pts)

Static analysis across 6 sub-dimensions. Scored in Pass 1.

| Sub-Dimension | Max | Weight | What to Check |
|---------------|-----|--------|--------------|
| **System Design** | 60 | 20% | Clear identity, role hierarchy, design pattern named |
| **Domain Knowledge** | 60 | 20% | Template-specific accuracy (API fields, pipeline stages, workflow steps) |
| **Workflow Definition** | 60 | 20% | Phase sequence complete, exit criteria per phase, loop gates explicit |
| **Error Handling** | 45 | 15% | Recovery paths named, escalation triggers defined, timeout values set |
| **Examples** | 45 | 15% | ≥ 2 examples, both EN and ZH or bilingual triggers, output shown |
| **Metadata Quality** | 30 | 10% | YAML complete, version semver, author, dates, description bilingual |

### Scoring Rubric per Sub-Dimension

| Score Band | Meaning |
|------------|---------|
| 90–100% | Exceptional: specific, measurable, complete, no vagueness |
| 75–89% | Good: mostly complete, minor gaps in specificity |
| 60–74% | Adequate: structure present but some sections thin or vague |
| 40–59% | Weak: significant gaps, missing key elements |
| 0–39% | Poor: section missing or essentially content-free |

### Pass 1 Scoring Instructions

For each sub-dimension, produce:
```json
{
  "sub_dimension": "<name>",
  "score": 0,
  "max": 60,
  "evidence": "<what was found>",
  "gaps": ["<specific gap 1>", "<specific gap 2>"],
  "severity": "ERROR|WARNING|INFO"
}
```

---

## §5  Phase 3 — Runtime Testing (0–400 pts)

Executed against benchmark test cases (`claude/eval/benchmarks.md`). Scored in Pass 2.

| Test Category | Max | What Is Tested |
|---------------|-----|----------------|
| **Trigger Routing Accuracy** | 120 | Mode router predicts correct mode for positive cases |
| **Bilingual Trigger Coverage** | 80 | Both EN and ZH inputs route correctly |
| **Negative/Edge Cases** | 60 | Ambiguous inputs handled; negatives filtered; fallback activated |
| **Output Contract** | 60 | Each mode's output format matches stated spec |
| **Error Handling Runtime** | 50 | Error cases produce correct recovery output |
| **Security Boundary Tests** | 30 | Injection/traversal inputs rejected gracefully |

### F1 and MRR Computation

```
F1 = 2 × precision × recall / (precision + recall)
  precision = TP / (TP + FP)
  recall    = TP / (TP + FN)

MRR = (1/N) × Σ (1 / rank_of_first_correct_mode)
  rank = 1 if correct mode is top prediction
  rank = 2 if second
  rank = 0 (excluded from sum) if correct mode not in top 3

Trigger accuracy = correct_triggers / total_trigger_test_cases
```

### Phase 3 Score Mapping

```
trigger_routing: correct% × 120
bilingual:       (EN_correct + ZH_correct) / (EN_total + ZH_total) × 80
negative_cases:  correct_negatives / total_negatives × 60
output_contract: correct_format% × 60
error_handling:  correct_recovery% × 50
security_boundary: all_rejected ? 30 : rejected/total × 30
```

### Pass 2 Test Execution

Run each test case and record:
```json
{
  "test_id": "CF-C-01",
  "input": "create a new skill for querying databases",
  "expected_mode": "CREATE",
  "predicted_mode": "CREATE",
  "confidence": 0.92,
  "correct": true,
  "rank": 1
}
```

---

## §6  Phase 4 — Certification (0–200 pts)

Scored in Pass 3 (Reconciliation). Integrates all previous phases.

| Check | Max | How Scored |
|-------|-----|-----------|
| **Variance gate** | 40 | variance<10→40, <15→30, <20→20, <30→10, ≥30→0 |
| **Security scan** | 60 | P0 clear→40, P1 clear→20; P0 violation→0+ABORT; each P1→−10 |
| **F1 gate** | 40 | F1≥0.90→40, ≥0.85→25, ≥0.80→10, <0.80→0 |
| **MRR gate** | 30 | MRR≥0.85→30, ≥0.80→20, ≥0.75→10, <0.75→0 |
| **Consistency** | 30 | All passes agree on tier→30, CLEAR→20, REVISED→10, UNRESOLVED→0 |

**Phase 4 hard rules**:
- P0 security violation → Phase 4 = 0, overall = FAIL, status = ABORT
- F1 < 0.80 → Phase 4 capped at 80 points regardless of other scores
- UNRESOLVED review outcome → Phase 4 capped at 120 points

---

## §7  LEAN Fast Path

Before running Phase 1–4, apply LEAN heuristics (§6 of skill-writer.md).

**Quick-Pass**: If lean_score ≥ 450 (GOLD proxy):
- Run only Phase 1 + security scan
- If Phase 1 ≥ 90 AND security CLEAR → issue LEAN_CERT, skip Phase 2–4
- Schedule full Phase 2–4 within 24 h

**Full Pipeline**: If lean_score 300–449 OR any quick-pass check fails → run all 4 phases.

---

## §8  Evaluation Report Template

```
SKILL EVALUATION REPORT
=======================
Skill:      <name> v<version>
Evaluated:  <ISO-8601>
Evaluator:  skill-writer v2.1.0

PHASE SCORES
  Phase 1 — Parse & Validate:   XX / 100
  Phase 2 — Text Quality:       XX / 300
    System Design:     XX/60   Error Handling: XX/45
    Domain Knowledge:  XX/60   Examples:       XX/45
    Workflow:          XX/60   Metadata:       XX/30
  Phase 3 — Runtime Testing:    XX / 400
    Trigger Routing:   XX/120  Output Contract:   XX/60
    Bilingual:         XX/80   Error Handling RT: XX/50
    Negative/Edge:     XX/60   Security Boundary: XX/30
  Phase 4 — Certification:      XX / 200
    Variance Gate:    XX/40    F1 Gate:    XX/40
    Security Scan:    XX/60    MRR Gate:   XX/30
    Consensus:        XX/30

TOTAL SCORE:     XXX / 1000
VARIANCE:        X.XX  (threshold for tier: <N)
F1:              0.XX  (threshold: ≥ 0.90)  [PASS|FAIL]
MRR:             0.XX  (threshold: ≥ 0.85)  [PASS|FAIL]
TRIGGER ACC:     0.XX  (threshold: ≥ 0.90)  [PASS|FAIL]

SECURITY SCAN
  P0: [CLEAR | VIOLATION: <cwe> at <location>]
  P1: [CLEAR | <count> warnings, −<N> pts]

CONSENSUS MATRIX
  | Dimension       | Pass 1 | Pass 2 | Pass 3 | Consensus   |
  |-----------------|--------|--------|--------|-------------|
  | ...             | ...    | ...    | ...    | ...         |

ISSUES
  ERROR:   <blocking issues — must fix before delivery>
  WARNING: <advisory issues — document or fix>
  INFO:    <informational notes>

CERTIFICATION TIER:  PLATINUM | GOLD | SILVER | BRONZE | FAIL
STATUS:              CERTIFIED | TEMP_CERT | LEAN_CERT | HUMAN_REVIEW | ABORT
NEXT ACTION:         <recommendation>
```


## OPTIMIZE Mode — Continuous Improvement

OPTIMIZE mode provides automated, iterative skill improvement through systematic optimization.

### Optimization Strategies

# Optimization Strategies

> **Purpose**: 7-dimension strategy catalog for the 9-step OPTIMIZE loop.
> **Load**: When §9 (OPTIMIZE Mode) of `claude/skill-writer.md` is accessed.
> **Main doc**: `claude/skill-writer.md §9`

---

## §1  7-Dimension Scoring Reference

The OPTIMIZE loop always targets the **lowest-scoring dimension first**.

| Dim | Name | Weight | What It Covers | Strategy |
|-----|------|--------|---------------|----------|
| D1 | System Design | 20% | Identity, role hierarchy, design patterns, Red Lines | S2 |
| D2 | Domain Knowledge | 20% | Template accuracy, API/schema specificity | S3 |
| D3 | Workflow Definition | 20% | Phase sequence, exit criteria, loop gates | S4 |
| D4 | Error Handling | 15% | Recovery paths, escalation triggers, timeouts | S5 |
| D5 | Examples | 15% | Count, bilingual, output shown, realistic | S1+S3 |
| D6 | Metadata | 10% | YAML completeness, versioning, tags, dates | S6 |
| D7 | Long-Context | 10% | Section cross-refs, chunking, reference integrity | S7 |

**Tie-break**: When two dimensions score equally, prioritize by weight (higher weight first).

---

## §2  The 9-Step Loop

```
Round N (repeat up to 20 rounds, or until convergence):

  Step 1  READ       Score all 7 dimensions. Record to score_history[N].
  Step 2  ANALYZE    Propose 3 targeted fixes for lowest dim.
  Step 3  CURATE     Every 10 rounds: consolidate learning, prune context (§3).
  Step 4  PLAN       Review and select best fix; record decision in dim_history[N].
  Step 5  IMPLEMENT  Apply one atomic change. Single dimension focus. No rewrites.
  Step 6  VERIFY     Re-score. IF regressed → rollback. IF no improvement → try fix #2.
  Step 7  HUMAN_REVIEW  Trigger if total_score < 560 (FAIL×0.8) after round 10.
  Step 8  LOG        Record: round, dimension, delta, confidence, strategy_used.
  Step 9  COMMIT     Git commit every 10 rounds with tag [optimize-round-N score=XXX].

  After every round → check convergence (claude/refs/convergence.md)
    IF converged → STOP → certify at current tier
```

**Rollback rule (Step 6)**: If re-score shows regression > 5 pts → discard change,
restore previous version, try the second-best fix from the review pass list.
If all 3 proposed fixes regress → switch strategy to next-lowest dimension.

---

## §3  Curation Protocol (Every 10 Rounds)

**Purpose**: Prevent context window bloat; refocus on highest-leverage improvements.

```
CURATE:
  1. Summarize: "Rounds 1–10 improved D3 by +38pts, D1 by +12pts, D5 unchanged."
  2. Rank strategies by delta produced: [S4: +38, S2: +12, S1: +0]
  3. Prune: discard individual round details; keep only summary + score_history list
  4. Re-prioritize: next 10 rounds → lead with highest-delta strategy
  5. Reset: clear LLM context for rounds 1–10; load only summary + current skill
  6. Log: {"curation_round": N, "context_reduced_pct": 40, "top_strategy": "S4"}
```

---

## §4  Strategy Catalog

### S1 — Expand Trigger Keywords

**Target dimension**: D5 (Examples), D3 (Workflow) when trigger accuracy < 0.90
**Estimated delta**: +15 to +30 pts

**Steps**:
1. List all current primary/secondary EN and ZH keywords per mode.
2. Find failing benchmark cases — which words appeared in failures?
3. Add 3+ new primary keywords per failing mode.
4. Add ZH equivalents for every EN primary that lacks one.
5. Add 3–5 secondary/context triggers per mode.
6. Add negative patterns for the top 2 misroute pairs.
7. Verify confidence formula weights still sum correctly.

**Example**:
```
Before: CREATE keywords: [create, build, new]
After:  CREATE keywords: [create, build, new, generate, scaffold, develop, make, add]
        ZH: [创建, 新建, 生成, 开发, 构建, 制作, 添加]
```

**Estimated F1 gain**: +0.03–0.06 per 3 new primary keywords.

---

### S2 — Strengthen System Design

**Target dimension**: D1 (System Design)
**Estimated delta**: +10 to +25 pts

**Steps**:
1. Check Identity section: name, role, purpose all present?
2. Check design patterns named (Tool Wrapper, Generator, Reviewer, Inversion, Pipeline)?
3. Check Red Lines section: ≥ 3 specific, measurable prohibitions?
4. If any Red Line is vague ("don't do bad things") → replace with CWE or measurable threshold.
5. Add LoongFlow reference if not present.
6. Verify role hierarchy is explicit (who can override whom).

**Red Line quality check**:
```
BAD:  "严禁 unsafe operations"
GOOD: "严禁 hardcoded credentials (CWE-798) — use env var AUTH_TOKEN"
```

---

### S3 — Deepen Domain Knowledge

**Target dimension**: D2 (Domain Knowledge), D5 (Examples)
**Estimated delta**: +15 to +35 pts

**Steps by skill type**:

**api-integration**:
- List all endpoint paths with HTTP methods and purpose.
- Name the specific auth env var (e.g. `OPENWEATHER_API_KEY`).
- List response fields that will be extracted.
- Add realistic field values in examples.

**data-pipeline**:
- Define input schema with field names and types.
- Define output schema with field names and types.
- Specify null handling strategy explicitly.
- Add quarantine threshold (e.g. ≤ 5%).

**workflow-automation**:
- Fill in the workflow steps table completely (all N steps).
- Add rollback action for each mutating step.
- Mark destructive steps explicitly.
- Add estimated duration per step.

**base**:
- Add domain-specific vocabulary to trigger keywords.
- Replace generic "output" descriptions with typed field lists.

---

### S4 — Tighten Workflow Definition

**Target dimension**: D3 (Workflow Definition)
**Estimated delta**: +20 to +40 pts

**Steps**:
1. For each mode section, check: does it have a Phase/Step table?
2. Add exit criteria per phase if missing:
   ```
   BAD:  "3. Execute the task"
   GOOD: "3. EXECUTE | action: call API | exit: HTTP 2xx received"
   ```
3. Add hard checkpoint markers at destructive or irreversible steps.
4. Define loop exit conditions explicitly (SUCCESS, FAIL, HUMAN_REVIEW).
5. Add parallel step annotations where steps can run concurrently.
6. Verify that every "IF error" path leads somewhere (recovery or escalation).

**Phase table template** (copy per mode):
```markdown
| # | Phase | Description | Exit Criteria |
|---|-------|-------------|---------------|
| 1 | PARSE | ... | ... |
| 2 | PLAN  | ... | ... |
| 3 | EXECUTE | ... | ... |
| 4 | VERIFY | ... | ... |
| 5 | DELIVER | ... | ... |
```

---

### S5 — Harden Error Handling

**Target dimension**: D4 (Error Handling)
**Estimated delta**: +15 to +30 pts

**Steps**:
1. List all failure modes relevant to the skill type.
2. For each failure: specify trigger condition, recovery action, escalation path.
3. Set explicit timeout values (e.g. "API timeout: 10 s → retry once → surface error").
4. Add retry logic with max retries and backoff (exponential: 1s, 2s, 4s).
5. Add error output contract per mode.
6. For workflow skills: define rollback sequence for each step.

**Error catalog by type**:

| Error Type | Recovery Pattern |
|-----------|----------------|
| HTTP 4xx | Parse error → human-readable message |
| HTTP 429 | Read `Retry-After` header → wait → retry (max 3) |
| HTTP 5xx | Backoff retry (1s, 2s, 4s) → HUMAN_REVIEW after 3 fails |
| Timeout | Retry once → if fails again → surface error |
| Validation fail | Quarantine record → continue with remaining |
| Security violation | ABORT immediately → log → notify |
| LLM timeout | Degrade to majority vote or baseline check |

---

### S6 — Complete Metadata

**Target dimension**: D6 (Metadata)
**Estimated delta**: +8 to +15 pts

**Steps**:
1. Verify YAML frontmatter has: `name`, `version`, `description`, `description_i18n` (EN+ZH),
   `license`, `author`, `created`, `updated`, `type`, `tags`, `interface`.
2. Check `version` follows semver: `N.N.N`.
3. Check `tags` has ≥ 3 relevant tags.
4. Check `description_i18n.zh` is a real Chinese translation, not just `"todo"`.
5. Update `updated` date to today.
6. Check `interface.modes` matches actual modes in the skill body.
7. Add `extends` block if skill references rubrics/security:
   ```yaml
   extends:
     evaluation:
       metrics: [f1, mrr]
       thresholds: {f1: 0.90, mrr: 0.85}
     security:
       standard: CWE
       scan-on-delivery: true
   ```

---

### S7 — Fix Long-Context Integrity

**Target dimension**: D7 (Long-Context)
**Estimated delta**: +10 to +20 pts

**Steps**:
1. Scan all `§N` section references in the skill — do they point to real sections?
2. Scan all `claude/refs/`, `claude/eval/`, `claude/templates/` references — do files exist?
3. Add cross-references where a section mentions another without linking.
4. If skill > 400 lines: add a Progressive Disclosure table at the top listing sections
   and which ones are loaded on demand.
5. If any section is a stub (< 3 lines), either fill it or mark as "See: `<ref-file>`".
6. Check chunk integrity: if the skill was processed in chunks, verify all sections merged
   correctly and cross-references are consistent.

**Progressive Disclosure table template**:
```markdown
| Section | Loaded When | Size |
|---------|------------|------|
| §1 Identity | Always | Full |
| §2 Mode Router | Always | Full |
| §3 CREATE | On CREATE trigger | Full |
| §N Details | On demand | Lazy |
| claude/refs/self-review.md | §4 accessed | External |
```

---

### S8 — Full Structural Rebuild

**When to use**: Overall score < 560 after 2 cycles, OR multiple dimensions all < 50%.
Targeted fixes are less efficient than a clean rebuild.

**Steps**:
1. Extract salvageable content: identity description, domain knowledge, any good examples.
2. Select fresh template from `claude/templates/` matching the skill type.
3. Run CREATE mode (§5 of skill-writer.md) with extracted content as pre-filled answers.
4. Port salvaged content into new template draft.
5. Run LEAN eval immediately. If LEAN PASS → full EVALUATE.
6. Version: if original never delivered → keep v1.0.0. If delivered → bump minor: v1.1.0.

**Exit gate**: New skill passes EVALUATE at BRONZE or higher.

---

### S9 — Targeted Metric Boost (Within 0.03 of Threshold)

**When to use**: A single metric barely fails (within 0.03 of threshold). Surgical fix only.

**F1 boost** (F1 between 0.87–0.89):
- Add 2 primary triggers per mode with false negatives (use benchmark failure log).
- Remove 1–2 ambiguous triggers causing false positives.
- Expected gain: +0.01–0.02 F1.

**MRR boost** (MRR between 0.82–0.84):
- Ensure the single most common trigger phrase is the **first** listed primary keyword per mode.
- Reduce number of modes if one mode is essentially never used.
- Expected gain: +0.02–0.04 MRR.

**Trigger accuracy boost** (accuracy 0.87–0.89):
- Add clarification prompts for the 2 most-confused mode pairs.
- Add negative patterns for the most common misroutes.

---

## §5  Strategy Selection Matrix

```
Lowest-scoring dimension → apply strategy
  D1 System Design     → S2
  D2 Domain Knowledge  → S3
  D3 Workflow          → S4
  D4 Error Handling    → S5
  D5 Examples          → S1 (trigger) or S3 (content)
  D6 Metadata          → S6
  D7 Long-Context      → S7
  All < 50%            → S8 (rebuild)
  Single metric fails  → S9 (targeted boost)
```

**Cycle budget**:

| Cycle | Allowed Strategies | Outcome if Still Failing |
|-------|--------------------|--------------------------|
| 1 | S1–S7, S9 | Proceed to Cycle 2 |
| 2 | S1–S7, S9 | Proceed to Cycle 3 |
| 3 | S8 (rebuild) or S9 | If still FAIL → HUMAN_REVIEW |

After 3 cycles at FAIL, or after round 20, stop and escalate.
Log to audit trail: `{"outcome": "HUMAN_REVIEW", "optimize_cycles": 3}`.


### Convergence Detection

# Convergence Detection

> **Purpose**: Three-signal convergence algorithm used to stop optimization loops early.
> **Load**: When §9 (OPTIMIZE Loop) of `claude/skill-writer.md` is accessed.
> **Main doc**: `claude/skill-writer.md §9`

---

## §1  Why Convergence Detection

The 9-step optimization loop (§9 of skill-writer.md) runs up to 20 rounds.
Without convergence detection, it wastes compute on loops where:
- Scores have stabilized (volatility check)
- All easy gains are exhausted (plateau check)
- The strategy is actively making things worse (trend check — DIVERGING)

The loop checks all three signals after every round. **Any convergence signal
triggers early stopping.**

---

## §2  Signal 1 — Volatility Check

**Purpose**: Detect when scores have stabilized (low variance across recent rounds).

**Algorithm**:
```python
def volatility_check(score_history: list[float], window: int = 10) -> bool:
    """
    Returns True (CONVERGED) if the standard deviation of the last `window`
    scores is below the threshold.
    """
    if len(score_history) < window:
        return False  # not enough data yet

    recent = score_history[-window:]
    mean = sum(recent) / len(recent)
    variance = sum((x - mean) ** 2 for x in recent) / len(recent)
    stddev = variance ** 0.5

    # Threshold: 2.0 score points (on 1000-point scale)
    return stddev < 2.0
```

**Interpretation**:
- `stddev < 2.0` → scores are essentially flat → no more gains from current strategy
- Action: **STOP loop**, declare convergence signal = `"volatility"`

---

## §3  Signal 2 — Plateau Check

**Purpose**: Detect when incremental improvements have become negligible.

**Algorithm**:
```python
def plateau_check(score_history: list[float], window: int = 10) -> bool:
    """
    Returns True (CONVERGED) if:
    - More than 70% of round-to-round deltas are below 0.5 pts
    - AND total delta over the window is ≤ 0 (not improving overall)
    """
    if len(score_history) < window:
        return False

    recent = score_history[-window:]
    deltas = [abs(recent[i] - recent[i-1]) for i in range(1, len(recent))]

    small_delta_pct = sum(1 for d in deltas if d < 0.5) / len(deltas)
    total_delta = recent[-1] - recent[0]

    return small_delta_pct > 0.70 and total_delta <= 0
```

**Interpretation**:
- Most rounds produce < 0.5-point gain AND overall trend is flat or negative
- Action: **STOP loop**, declare convergence signal = `"plateau"`

---

## §4  Signal 3 — Trend Check

**Purpose**: Detect whether the optimization trajectory is improving, stable, or diverging.

**Algorithm**:
```python
def trend_check(score_history: list[float]) -> str:
    """
    Returns "IMPROVING", "STABLE", or "DIVERGING".
    Compares the mean of the first half vs the mean of the second half.
    """
    if len(score_history) < 4:
        return "IMPROVING"  # too early to judge

    mid = len(score_history) // 2
    first_half_mean = sum(score_history[:mid]) / mid
    second_half_mean = sum(score_history[mid:]) / (len(score_history) - mid)

    delta = second_half_mean - first_half_mean

    if delta > 5.0:    # ≥5 pts improvement → IMPROVING
        return "IMPROVING"
    elif delta < -5.0: # ≥5 pts degradation → DIVERGING
        return "DIVERGING"
    else:              # within ±5 pts → STABLE
        return "STABLE"
```

**Interpretation and actions**:

| Result | Meaning | Action |
|--------|---------|--------|
| IMPROVING | Current strategy is working | Continue loop |
| STABLE | No clear improvement | Switch to different strategy or stop |
| DIVERGING | Strategy is making things worse | **HALT immediately** → HUMAN_REVIEW |

---

## §5  Combined Convergence Decision

All three signals are checked after every optimization round:

```python
def should_stop(score_history: list[float], current_round: int) -> tuple[bool, str]:
    """
    Returns (stop: bool, reason: str).
    """
    # Hard stop
    if current_round >= 20:
        return True, "max_rounds"

    # Volatility: stop if stable
    if volatility_check(score_history):
        return True, "volatility"

    # Plateau: stop if exhausted
    if plateau_check(score_history):
        return True, "plateau"

    # Trend: stop if diverging
    trend = trend_check(score_history)
    if trend == "STABLE" and current_round >= 5:
        return True, "trend_stable"
    if trend == "DIVERGING":
        return True, "trend_diverging"

    return False, "continue"
```

---

## §6  Post-Convergence Actions

| Signal | Action |
|--------|--------|
| `volatility` | Declare final score; certify at current tier; update audit |
| `plateau` | Try one final alternative strategy; if no improvement → certify |
| `trend_stable` | Certify at current tier; log "plateau reached at round N" |
| `trend_diverging` | **HALT**, roll back to best-score snapshot, escalate HUMAN_REVIEW |
| `max_rounds` | If score ≥ 700 → certify BRONZE; else → HUMAN_REVIEW |

---

## §7  Score History Format

The optimization loop maintains a score history list:

```json
{
  "skill_name": "<name>",
  "optimization_run_id": "<uuid>",
  "score_history": [684, 706, 718, 724, 729, 731, 732, 731, 732, 732],
  "dimension_history": [
    {"round": 1, "lowest_dim": "Workflow Definition", "score": 684, "delta": null},
    {"round": 2, "lowest_dim": "Workflow Definition", "score": 706, "delta": +22},
    {"round": 3, "lowest_dim": "Error Handling",      "score": 718, "delta": +12}
  ],
  "convergence_check": [
    {"round": 9,  "volatility": false, "plateau": false, "trend": "STABLE"},
    {"round": 10", "volatility": true,  "plateau": false, "trend": "STABLE",
     "decision": "STOP", "reason": "volatility"}
  ],
  "final_score": 732,
  "final_tier": "BRONZE",
  "converged_at_round": 10,
  "convergence_signal": "volatility"
}
```

---

## §8  Curation at Round 10

Every 10 rounds, the optimization loop performs a curation step to prevent context bloat:

```
CURATE (round 10, 20):
  1. Summarize all dimension changes so far: which improved, by how much
  2. Identify the top 2 strategies that produced the most delta
  3. Prune: discard individual round details, keep only summary + score_history
  4. Re-prioritize: next 10 rounds focus on top-performing strategy first
  5. Log: {"curation_round": 10, "strategies_pruned": [...], "context_reduced_by": "~40%"}
```

This prevents the LLM context window from filling up with stale round-by-round details
and keeps attention focused on the highest-leverage remaining improvements.


## Shared Resources

Common patterns, utilities, and security checks used across all modes.

### Security Patterns

# Security Patterns Reference

> **Purpose**: CWE regex patterns, severity classification, ABORT protocol, and resume conditions.
> **Load**: When §11 (Security) of `claude/skill-writer.md` is accessed.
> **Main doc**: `claude/skill-writer.md §11`

---

## §1  CWE Pattern Catalog

### P0 Patterns — Immediate ABORT

P0 patterns are non-negotiable. Detection at any phase halts delivery immediately.

#### CWE-798 — Hardcoded Credentials

```
Patterns (case-insensitive):
  sk-[a-zA-Z0-9]{20,}                    # OpenAI / Anthropic API key
  AKIA[0-9A-Z]{16}                        # AWS Access Key ID
  password\s*=\s*["'][^"']{4,}["']        # password = "..."
  api_key\s*=\s*["'][^"']{4,}["']         # api_key = "..."
  secret\s*=\s*["'][^"']{4,}["']          # secret = "..."
  token\s*=\s*["'][^"']{4,}["']           # token = "..."
  Bearer\s+[a-zA-Z0-9\-._~+/]{20,}       # hardcoded Bearer token
  [a-z0-9]{32,}                           # generic long hex secret (heuristic)
```

**False positive mitigation**: Exclude patterns inside:
- Comment blocks starting with `#`, `//`, `<!--`
- Placeholder patterns: `{{...}}`, `<...>`, `YOUR_*`, `REPLACE_*`
- Example/test strings explicitly labelled as such

**Required remediation**: Replace with environment variable reference.
```
# BAD:  api_key = "sk-abc123..."
# GOOD: api_key = os.environ["SERVICE_API_KEY"]
# SKILL DOC: Auth env var: SERVICE_API_KEY
```

---

#### CWE-89 — SQL Injection

```
Patterns (case-insensitive):
  (mysql|psql|sqlite3|db\.query)\s*\(.*\$\{   # template literal in query
  WHERE\s+\w+\s*=\s*['"]?\s*\$\w+             # WHERE col = $var
  SELECT.*\+\s*user_input                       # string concat with user input
  execute\s*\(.*\%s.*%\s*\w+                   # % formatting in SQL
  f["']SELECT.*\{.*\}                           # f-string SQL
  "INSERT INTO.*"\s*\+                          # string concat INSERT
```

**Required remediation**: Use parameterized queries.
```
# BAD:  db.query(f"SELECT * FROM users WHERE id = {user_id}")
# GOOD: db.query("SELECT * FROM users WHERE id = ?", [user_id])
```

---

#### CWE-78 — Command Injection

```
Patterns (case-insensitive):
  eval\s*\$\{                                   # eval with template literal
  exec\s*\(.*user                               # exec() with user-derived input
  system\s*\(.*\$\{                             # system() call
  subprocess\..*shell\s*=\s*True               # shell=True in Python subprocess
  os\.system\s*\(.*\+                           # os.system with concatenation
  `.*\$\{.*\}`                                  # backtick command with var
  child_process\.exec\s*\(.*\+                  # Node.js exec concat
```

**Required remediation**: Use whitelisted argument arrays, never shell=True with user input.
```
# BAD:  subprocess.run(f"convert {user_file}", shell=True)
# GOOD: subprocess.run(["convert", validated_file], shell=False)
```

---

### P1 Patterns — WARNING (score penalty applied)

P1 findings deduct points but do NOT trigger ABORT. They must be documented in the skill's
Security Baseline section or remediated.

#### CWE-22 — Path Traversal (−50 pts)

```
Patterns:
  \.\.\//                                       # ../
  \.\.\\/                                       # ..\
  %2e%2e%2f                                     # URL-encoded ../
  %00                                           # null byte injection
  /etc/passwd                                   # classic target
  open\s*\(.*user                               # open() with user-derived path
```

**Remediation**: Validate and canonicalize paths before use.
```python
safe_dir = os.path.abspath("./output")
requested = os.path.abspath(os.path.join(safe_dir, user_input))
assert requested.startswith(safe_dir), "Path traversal blocked"
```

---

#### CWE-306 — Missing Authentication Check (−30 pts)

```
Heuristic triggers (skill text analysis):
  - Skill performs write / delete / admin operations
  - No mention of auth check, token validation, or permission verification
  - API calls present but no "authenticate" / "verify" / "authorize" mention
```

**Required doc**: Skill Security Baseline must state: "All requests authenticated via
`<method>` before execution."

---

#### CWE-862 — Missing Authorization Check (−30 pts)

```
Heuristic triggers:
  - Skill accesses user-specific data
  - No mention of ownership check or role validation
  - "admin" / "delete" / "modify" operations without permission check
```

**Required doc**: Skill Security Baseline must state: "Authorization: `<role/permission>`
required for `<operation>`."

---

## §2  Severity Classification Summary

| Severity | CWEs | Detection | Action | Delivery |
|----------|------|-----------|--------|---------|
| **P0** | 798, 89, 78 | Regex match | ABORT immediately | BLOCKED |
| **P1** | 22, 306, 862 | Regex + heuristic | Score penalty + WARNING | Allowed with doc |

---

## §3  ABORT Protocol

When any **P0 pattern** is detected:

```
1. DETECT   — Pattern matched at Phase N of evaluation
2. STOP     — Immediately halt current operation; do not proceed to next phase
3. LOG      — Record to .skill-audit/security.jsonl:
               {cwe, pattern, location, severity: "P0", status: "ABORT"}
4. FLAG     — Mark artifact: outcome = "ABORT", tier = "FAIL"
5. NOTIFY   — Present to user:
               "ABORT: CWE-<N> violation detected at <location>.
                Delivery blocked. Human review required before resume."
6. REQUIRE  — No resume without explicit human sign-off (§4)
7. DOCUMENT — Root cause in audit trail for pattern analysis
```

---

## §4  Resume After ABORT

All five conditions must be met before resuming:

| # | Condition | Verified By |
|---|-----------|-------------|
| 1 | Human review completed and documented | Human sign-off in audit entry |
| 2 | Violation root cause identified (which line, which pattern) | Root cause field in audit |
| 3 | Fix applied and verified (no pattern match on re-scan) | Re-scan result: CLEAR |
| 4 | Full security scan run with all-CLEAR result | Security scan log entry |
| 5 | Explicit human sign-off to resume | `{"resume_authorized": true, "authorized_by": "<id>"}` |

**Resume command**: After all 5 conditions met, run EVALUATE mode on the fixed skill.
If EVALUATE passes → normal delivery. ABORT status is cleared from audit log (not deleted,
marked as `"resolved": true`).

---

## §5  Security Scan Report Format

```
SECURITY SCAN REPORT
====================
Skill: <name> v<version>
Scanned: <ISO-8601>
Scanner: skill-writer v2.1.0

P0 FINDINGS (ABORT triggers):
  [NONE | list of findings with location]

P1 FINDINGS (score penalties):
  CWE-22: <location> — path not validated (−50 pts)
  CWE-306: <heuristic trigger> — no auth mention (−30 pts)

SCORE IMPACT: −<N> points total from P1 findings

RESULT: CLEAR | ABORT
```

---

## §6  Security Log Entry

Every scan appends to `.skill-audit/security.jsonl`:

```json
{
  "timestamp": "<ISO-8601>",
  "skill_name": "<name>",
  "skill_version": "<semver>",
  "mode": "<scan_mode>",
  "p0_findings": [],
  "p1_findings": [],
  "score_penalty": 0,
  "result": "CLEAR|ABORT",
  "resume_authorized": false,
  "resolved": false
}
```