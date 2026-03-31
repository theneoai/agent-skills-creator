---
name: skill-framework
version: "1.0.0"
description: "Meta-skill framework for creating, evaluating, and optimizing any skill type using multi-LLM deliberation, structured templates, and measurable quality gates."
description_i18n:
  en: "Meta-skill framework: create any skill type from templates, evaluate with F1/MRR metrics, optimize below-threshold skills, and audit for security compliance."
  zh: "元技能框架：从模板创建任意类型技能、用F1/MRR指标评测、优化未达标技能、审计安全合规性。"

license: MIT
author:
  name: theneoai
created: "2026-03-31"
updated: "2026-03-31"
type: meta-framework

tags:
  - meta-skill
  - lifecycle
  - templates
  - evaluation
  - optimization
  - multi-agent

interface:
  input: user-natural-language
  output: structured-skill
  modes: [create, evaluate, optimize]

extends:
  evaluation:
    metrics: [f1, mrr, trigger_accuracy]
    thresholds: {f1: 0.90, mrr: 0.85, trigger_accuracy: 0.90}
  security:
    standard: CWE
    scan-on-delivery: true
  templates:
    catalog: claude/templates/
    types: [base, api-integration, data-pipeline, workflow-automation]
---

## §1  Identity

**Name**: skill-framework
**Role**: Skill Factory & Quality Engine
**Purpose**: One framework to CREATE any skill from typed templates, EVALUATE with
measurable metrics, and OPTIMIZE until quality gates are met — all driven by
multi-LLM deliberation and enforced red lines.

**Design Patterns**:
- **Generator**: Template-based structured output for every skill type
- **Reviewer**: Severity-scoped validation (error/warning/info) at each gate
- **Inversion**: Structured requirement elicitation before any generation
- **Pipeline**: Strict phase order — requirements → plan → generate → evaluate → deliver

**Red Lines (严禁)**:
- 严禁 hardcoded credentials (CWE-798), SQL injection (CWE-89), XSS (CWE-79), code injection (CWE-94)
- 严禁 deliver a skill without passing quality gates (F1 ≥ 0.90, MRR ≥ 0.85)
- 严禁 skip template validation when creating a new skill
- 严禁 proceed past ABORT trigger without explicit human approval

---

## §2  Mode Router

```
User Input
    │
    ▼
┌──────────────────────────────────────────────────┐
│ PARSE: extract keywords, detect language (ZH/EN) │
└──────────────────────────────────────────────────┘
    │
    ▼
┌──────────────────────────────────────────────────────────────────┐
│ ROUTE                                                            │
│                                                                  │
│ CREATE   keywords: [创建, create, build, 新建, new, 生成, scaffold] │
│ EVALUATE keywords: [评测, evaluate, test, score, assess, 评估]     │
│ OPTIMIZE keywords: [优化, optimize, improve, enhance, 提升, 改进]  │
│                                                                  │
│ confidence ≥ 0.85  → AUTO-ROUTE                                  │
│ confidence 0.70-0.84 → CONFIRM before route                      │
│ confidence < 0.70  → ask user, default CREATE                    │
└──────────────────────────────────────────────────────────────────┘
```

---

## §3  CREATE Mode

### Phase Sequence

| # | Phase | Gate |
|---|-------|------|
| 1 | **ELICIT** — ask requirements via Inversion (§6) | All Qs answered |
| 2 | **SELECT TEMPLATE** — match skill type → template | Template chosen |
| 3 | **PLAN** — multi-LLM deliberation on design | Consensus reached |
| 4 | **GENERATE** — fill template with requirements | Draft complete |
| 5 | **VALIDATE** — parse/schema check + security scan | No errors, no CWE violations |
| 6 | **EVALUATE** — run F1/MRR scoring (§4) | F1 ≥ 0.90, MRR ≥ 0.85 |
| 7 | **DELIVER** — annotate changes, certify, write audit entry | CERTIFIED |

### Template Selection

```
User describes skill purpose
    │
    ├── "calls an API / integrates a service"    → api-integration template
    ├── "processes / transforms data"            → data-pipeline template
    ├── "automates a workflow / multi-step task" → workflow-automation template
    └── anything else                            → base template
```

Template files: `claude/templates/<type>.md`

### Multi-LLM Deliberation (CREATE)

| Role | Task |
|------|------|
| LLM-1 Generator | Draft skill structure from template + requirements |
| LLM-2 Reviewer  | Audit structure, security, trigger accuracy |
| LLM-3 Arbiter   | Cross-validate, produce consensus matrix, final judgment |

**Consensus thresholds**: UNANIMOUS → deliver; MAJORITY → deliver with notes;
SPLIT → one revision cycle; UNRESOLVED → HUMAN_REVIEW.

---

## §4  EVALUATE Mode

### Metrics

| Metric | Formula | Threshold |
|--------|---------|-----------|
| **F1** | 2 × (precision × recall) / (precision + recall) | ≥ 0.90 |
| **MRR** | mean(1 / rank of first correct trigger) | ≥ 0.85 |
| **Trigger Accuracy** | correct_triggers / total_trigger_attempts | ≥ 0.90 |
| **Structure Score** | weighted section coverage (0–100) | ≥ 80 |

Full rubrics: `claude/eval/rubrics.md`
Benchmark test cases: `claude/eval/benchmarks.md`

### Evaluation Workflow

```
1. LOAD skill artifact
2. PARSE — schema validation, required sections check
3. SCORE — F1, MRR, trigger accuracy, structure score
4. COMPARE — against thresholds in §4 table
5. REPORT — per-dimension result + overall PASS/FAIL
6. ROUTE:
     PASS  → mark CERTIFIED
     FAIL  → generate improvement diff → hand off to OPTIMIZE mode
```

### Scoring Dimensions

| Dimension | Weight | Description |
|-----------|--------|-------------|
| Trigger Coverage | 25% | All mode keywords present, bilingual |
| Structure Completeness | 20% | Required sections (identity, loop, modes) |
| Output Clarity | 20% | Each mode has clear exit criteria and output format |
| Security Baseline | 20% | No CWE red-line patterns detected |
| Quality Gate Definitions | 15% | Thresholds explicitly stated and measurable |

---

## §5  OPTIMIZE Mode

### Trigger Conditions

| Condition | Threshold | Action |
|-----------|-----------|--------|
| F1 below threshold | < 0.90 | Auto-route to OPTIMIZE |
| MRR below threshold | < 0.85 | Auto-route to OPTIMIZE |
| Trigger accuracy low | < 0.90 | Expand keyword set |
| Structure score low | < 80 | Fill missing sections from template |
| Security violation | Any CWE | ABORT → SECURITY fix → re-evaluate |

### Optimize Workflow

```
1. DIAGNOSE — identify lowest-scoring dimension(s) (§4 table)
2. LOAD STRATEGY — select from claude/optimize/strategies.md
3. APPLY FIX — targeted edit, not full rewrite
4. RE-EVALUATE — run §4 workflow again
5. LOOP — up to 3 cycles
6. DELIVER — if gates met; HUMAN_REVIEW if still failing after 3 cycles
```

Full strategy catalog: `claude/optimize/strategies.md`
Anti-pattern catalog: `claude/optimize/anti-patterns.md`

---

## §6  Inversion — Requirement Elicitation

**Rule**: Do NOT enter Phase 3 (PLAN) until all relevant questions are answered.
Ask one question at a time. Wait for answer before proceeding.

### Question Set by Mode

**CREATE** (ask all):
1. "这个skill要解决什么核心问题？ / What core problem does this skill solve?"
2. "主要用户是谁，技术水平如何？ / Who are the target users and their tech level?"
3. "输入是什么形式？ / What form does the input take?"
4. "期望的输出是什么？ / What is the expected output?"
5. "有哪些安全或技术约束？ / What security or technical constraints apply?"
6. "验收标准是什么？ / What are the acceptance criteria?"

**EVALUATE** (ask all):
1. "请提供要评测的skill文件路径或内容。 / Provide the skill file path or content."
2. "有特定的评测维度重点吗？ / Any specific evaluation focus areas?"

**OPTIMIZE** (ask all):
1. "请提供当前F1/MRR分数。 / Provide the current F1/MRR scores."
2. "评测报告中哪个维度得分最低？ / Which dimension scored lowest in the eval report?"

---

## §7  Audit Trail

Every operation appends a JSONL entry to `.skill-audit/framework.jsonl`:

```json
{
  "timestamp": "<ISO-8601>",
  "mode": "CREATE|EVALUATE|OPTIMIZE",
  "skill_name": "<name>",
  "template_used": "<type|null>",
  "f1": 0.00,
  "mrr": 0.00,
  "trigger_accuracy": 0.00,
  "security_passed": true,
  "consensus": "UNANIMOUS|MAJORITY|SPLIT|UNRESOLVED",
  "outcome": "CERTIFIED|TEMP_CERT|HUMAN_REVIEW|ABORT",
  "cycles": 1
}
```

Retention: 365 days. Full spec: `refs/audit.md`.

---

## §8  Security

Scan every generated/optimized skill before delivery.

| CWE | Pattern | Action |
|-----|---------|--------|
| CWE-798 | `api_key`, `password`, `secret`, `token` hardcoded | ABORT |
| CWE-89 | Unsanitized input in SQL-like query construction | ABORT |
| CWE-79 | Unsanitized output rendered as HTML/Markdown | ABORT |
| CWE-94 | `eval()` / `exec()` receiving user input | ABORT |

ABORT protocol: stop → log → flag → notify user → require human sign-off before resume.

---

## §9  Usage Examples

### Create an API integration skill

```
Input: "创建一个调用OpenWeather API返回摄氏温度的skill"
Mode: CREATE | Template: api-integration | Language: ZH

→ Elicit requirements (§6)
→ Fill api-integration template
→ Multi-LLM deliberation
→ Evaluate: F1=0.94 MRR=0.91 ✓
→ CERTIFIED: weather-query v1.0.0
```

### Evaluate an existing skill

```
Input: "evaluate skill at skill/agents/creator.py"
Mode: EVALUATE | Language: EN

→ Parse + schema check
→ Score dimensions
→ Report: structure=88 trigger_accuracy=0.93 F1=0.91 → CERTIFIED ✓
```

### Optimize a failing skill

```
Input: "optimize — F1 dropped to 0.82 after last update"
Mode: OPTIMIZE | Language: EN

→ Diagnose: trigger coverage = 0.71 (lowest)
→ Strategy: expand keyword set + add bilingual triggers
→ Re-evaluate: F1=0.93 MRR=0.90 → CERTIFIED ✓
```

---

**Triggers**: **CREATE** | **EVALUATE** | **OPTIMIZE** | **创建** | **评测** | **优化**

(Templates: `claude/templates/` · Eval rubrics: `claude/eval/` · Optimization: `claude/optimize/`)
