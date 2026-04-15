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

# Skill tier (SkillX three-tier hierarchy — arxiv:2604.04804)
skill_tier: {{TIER}}          # planning | functional | atomic
# workflow-automation skills are typically: planning (multi-step orchestration) or functional

tags:
  - workflow
  - automation
  - {{WORKFLOW_DOMAIN}}
  - {{TAG_EXTRA}}

# Trigger phrases (3–8 canonical user phrasings that invoke this skill)
triggers:
  en:
    - "{{TRIGGER_PHRASE_EN_1}}"
    - "{{TRIGGER_PHRASE_EN_2}}"
    - "{{TRIGGER_PHRASE_EN_3}}"
  zh:
    - "{{TRIGGER_PHRASE_ZH_1}}"
    - "{{TRIGGER_PHRASE_ZH_2}}"

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
  injected_by: "skill-writer v3.4.0"
  injected_at: "{{DATE}}"
  check_cadence: {lightweight: 10, full_recompute: 50, tier_drift: 100}
  micro_patch_enabled: true
  feedback_detection: true
  certified_lean_score: null
  last_ute_check: null
  pending_patches: 0
  total_micro_patches_applied: 0
  cumulative_invocations: 0
  generation_method: "auto-generated"   # auto-generated | human-authored | hybrid
  validation_status: "lean-only"        # unvalidated | lean-only | full-eval | pragmatic-verified

# Graph of Skills — optional (v3.2.0, research: SkillNet arxiv:2603.04448)
# graph:
#   composes:                # Sub-skills this planning skill coordinates
#     - id: "{{GRAPH_CHILD_ID}}"
#       name: "{{GRAPH_CHILD_NAME}}"
#   depends_on:
#     - id: "{{GRAPH_DEP_ID}}"
#       name: "{{GRAPH_DEP_NAME}}"
#       required: true
#   provides:
#     - "{{GRAPH_OUTPUT_TYPE}}"   # e.g. "workflow-execution-report"
---

## Skill Summary

<!-- REQUIRED — ≤5 sentences: WHAT / WHEN / WHO / NOT-FOR.
     SkillRouter research: skill body is the decisive routing signal. Write this last.
-->

{{SKILL_NAME}} automates the {{WORKFLOW_NAME}} workflow, orchestrating {{STEP_COUNT}} steps in sequence with error handling, human checkpoints, and rollback support. Use it when {{CANONICAL_USE_CASE_1}} or {{CANONICAL_USE_CASE_2}}. Designed for {{TARGET_USERS}}. This skill does NOT handle {{OUT_OF_SCOPE_TEASER}} — see Negative Boundaries.

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

## §2  Negative Boundaries

<!-- REQUIRED — Provide 3–6 specific anti-cases. -->

**Do NOT use this skill for**:

- **{{ANTI_CASE_1}}**: {{REASON_1}}
  → Recommended alternative: {{ALTERNATIVE_SKILL_1}}
- **{{ANTI_CASE_2}}**: {{REASON_2}}
  → Recommended alternative: {{ALTERNATIVE_SKILL_2}}
- **{{ANTI_CASE_3}}**: {{REASON_3}}
  → Recommended alternative: {{ALTERNATIVE_SKILL_3_OR_ESCALATION}}

**The following trigger phrases should NOT activate this skill**:
- "{{SIMILAR_BUT_DIFFERENT_PHRASE_1}}"
- "{{SIMILAR_BUT_DIFFERENT_PHRASE_2}}"

---

## §3  Workflow Steps

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

## §4  RUN Mode

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

## §5  DRY-RUN Mode

**Triggers**: dry-run, preview, simulate, what-would, 预演, 模拟, 预览

**Purpose**: Show exactly what RUN mode would do — without executing any mutations.

**Steps**:
1. Run all pre-flight checks (§4)
2. For each step: log planned action + estimated output (no execution)
3. Identify checkpoints and destructive steps
4. Estimate total duration
5. Report: "DRY-RUN complete — N steps planned, M checkpoints, K destructive steps"

**Exit Criteria**: Full plan presented; user can choose to proceed with RUN.

---

## §6  STATUS Mode

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

## §7  ROLLBACK Mode

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

## §8  Quality Gates

| Metric | Threshold |
|--------|-----------|
| F1 | ≥ 0.90 |
| MRR | ≥ 0.85 |
| Trigger Accuracy | ≥ 0.90 |
| Step Success Rate | ≥ 95% (in test runs) |
| Rollback Coverage | 100% of mutating steps have defined rollback |
| Checkpoint Coverage | 100% of destructive steps have human checkpoint |

---

## §9  Security Baseline

- **CWE-78**: Shell commands constructed from validated, whitelisted parameters only
- **CWE-22**: File paths validated — no path traversal (`../`)
- **CWE-798**: No credentials in workflow definition — use env vars
- **Least Privilege**: Each step tool runs with minimal required permissions

---

## §10  Usage Examples

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

<!-- Post-invocation protocol — auto-managed by skill-writer v3.4.0 -->

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
- [ ] **Skill Summary** section present (≤5 sentences, dense domain encoding) — **REQUIRED**
- [ ] **Negative Boundaries** section present (§1, ≥ 3 anti-cases) — **REQUIRED**
- [ ] `skill_tier` declared in YAML (planning / functional / atomic)
- [ ] `triggers` list in YAML (3–8 EN phrases + 2–5 ZH phrases)
- [ ] `use_to_evolve:` block present with all 13 fields (including generation_method + validation_status)
- [ ] `generation_method` set: "auto-generated" | "human-authored" | "hybrid"
- [ ] `validation_status` updated after each eval: "lean-only" → "full-eval" → "pragmatic-verified"
- [ ] `## §UTE Use-to-Evolve` section present at end of skill
- [ ] **[OPTIONAL v3.2.0]** If skill composes sub-skills: uncomment and fill `graph: composes:` block (+20 LEAN pts)
- [ ] LEAN eval score ≥ 350 and no `{{PLACEHOLDER}}` remaining
- [ ] Full EVALUATE score ≥ 700 (BRONZE) confirmed
- [ ] Security scan P0 clear: CWE-78 (command injection), CWE-798 (credentials)
- [ ] If TEMP_CERT issued: add `TEMP_CERT: true` to YAML, re-evaluate within 72 h
