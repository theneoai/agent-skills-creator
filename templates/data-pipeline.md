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
