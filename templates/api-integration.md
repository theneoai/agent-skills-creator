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
