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
