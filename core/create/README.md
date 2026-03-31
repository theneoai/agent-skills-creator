# CREATE Mode Documentation

> **Purpose**: CREATE mode is the skill generation engine of the skill-framework. It transforms natural language requirements into production-ready, certified skills through a rigorous 7-step workflow.
> **Version**: 2.0.0
> **Last Updated**: 2026-03-31

---

## Table of Contents

1. [Workflow Overview](#workflow-overview)
2. [Input/Output Specifications](#inputoutput-specifications)
3. [Template Selection Logic](#template-selection-logic)
4. [Inversion Pattern Questions](#inversion-pattern-questions)
5. [Security Checks](#security-checks)
6. [Error Handling](#error-handling)
7. [Example Workflow](#example-workflow)

---

## Workflow Overview

CREATE mode follows a strict 7-step pipeline with hard gates between phases. No phase may be skipped or bypassed.

```
User Input (Natural Language)
    │
    ▼
┌─────────────────────────────────────────────────────────────────┐
│ 1. PARSE                                                        │
│    • Extract keywords from user request                         │
│    • Detect language (ZH / EN / mixed)                          │
│    • Identify intent: CREATE vs LEAN vs EVALUATE vs OPTIMIZE    │
│    • Confidence threshold: ≥ 0.70 to proceed                    │
└─────────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. SELECT TEMPLATE                                              │
│    • Match keywords to template type                            │
│    • Available: api-integration, data-pipeline,                 │
│                 workflow-automation, base                       │
│    • Load template: templates/<type>.md                         │
└─────────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. ELICIT (Inversion Pattern)                                   │
│    • Ask 6 requirement questions ONE AT A TIME                  │
│    • Gate: ALL questions must be answered before proceeding     │
│    • No PLAN phase until elicitation complete                   │
└─────────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. GENERATE                                                     │
│    • Fill template with elicited requirements                   │
│    • Generate YAML frontmatter                                  │
│    • Create all required sections (§1, §2, §3...)               │
│    • Gate: NO placeholders ({{PLACEHOLDER}}) may remain         │
└─────────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────────┐
│ 5. SECURITY SCAN                                                │
│    • Run CWE pattern detection                                  │
│    • P0 violations → ABORT immediately                          │
│    • P1 findings → score penalty + WARNING                      │
│    • Gate: All P0 must be CLEAR                                 │
└─────────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────────┐
│ 6. LEAN EVAL                                                    │
│    • Fast heuristic check (~1s)                                 │
│    • 500-point scale, mapped to 1000-point scale                │
│    • Gate: lean_score ≥ 350 (BRONZE proxy)                      │
│    • Uncertain (300-349) → escalate to full EVALUATE            │
└─────────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────────┐
│ 7. DELIVER                                                      │
│    • Annotate with metadata (version, tier, timestamp)          │
│    • Certify: CERTIFIED / TEMP_CERT / LEAN_CERT                 │
│    • Write audit entry to .skill-audit/framework.jsonl          │
│    • Return generated skill file path                           │
└─────────────────────────────────────────────────────────────────┘
```

### Phase Gates Summary

| Phase | Gate Condition | Failure Action |
|-------|---------------|----------------|
| PARSE | Confidence ≥ 0.70 | Graceful degradation (single-LLM, +50% thresholds) |
| SELECT TEMPLATE | Template file exists | Error: "Template not found" |
| ELICIT | All 6 questions answered | Cannot proceed to PLAN |
| GENERATE | No placeholders remain | Return to GENERATE with missing fields list |
| SECURITY SCAN | No P0 violations | ABORT → require human sign-off |
| LEAN EVAL | Score ≥ 350 | Route to OPTIMIZE if < 300, EVALUATE if 300-349 |
| DELIVER | All prior gates passed | Output certified skill file |

---

## Input/Output Specifications

### Input Format

CREATE mode accepts natural language input describing the desired skill.

**Input Schema:**
```yaml
input_type: natural_language
required_fields:
  - description: "What the skill should do"
optional_fields:
  - language: "ZH | EN | auto-detect"
  - template_hint: "api-integration | data-pipeline | workflow-automation | base"
  - priority: "speed | quality | balanced"
```

**Example Inputs:**
```
"创建一个调用OpenWeather API返回摄氏温度的skill"
"Create a skill that validates JSON against a schema"
"Build a workflow automation skill for CI/CD pipeline notifications"
```

### Output Format

CREATE mode produces a certified skill file following the skill-framework specification.

**Output Schema:**
```yaml
output_type: structured_skill_file
file_extension: .md
required_sections:
  - yaml_frontmatter: "Metadata (name, version, interface, etc.)"
  - identity: "§1 — Name, role, purpose, design patterns"
  - workflow: "§2+ — Mode definitions, phases, gates"
  - quality_gates: "Thresholds and acceptance criteria"
  - security_baseline: "Security considerations"
  - examples: "Usage examples (minimum 2)"
  - triggers: "Keywords for mode routing (EN + ZH)"

certification_metadata:
  - certified_at: "ISO-8601 timestamp"
  - certified_by: "skill-framework v2.0.0"
  - lean_score: "0-500"
  - estimated_full_score: "0-1000"
  - tier: "PLATINUM | GOLD | SILVER | BRONZE | FAIL"
  - security_status: "CLEAR | WARNING | ABORT"
```

**Output Location:**
- Default: `skills/<skill-name>-v<version>.md`
- Audit log: `.skill-audit/framework.jsonl`

---

## Template Selection Logic

Templates provide the structural foundation for generated skills. Selection is keyword-based with a fallback to the base template.

### Selection Decision Tree

```
User Request Keywords
    │
    ├── Contains: "API", "integrate", "service", "call", "endpoint",
    │             "REST", "GraphQL", "webhook", "fetch", "request"
    │   └── TEMPLATE: api-integration
    │       File: templates/api-integration.md
    │
    ├── Contains: "data", "pipeline", "transform", "validate", "process",
    │             "ETL", "parse", "clean", "filter", "schema"
    │   └── TEMPLATE: data-pipeline
    │       File: templates/data-pipeline.md
    │
    ├── Contains: "workflow", "automation", "orchestrate", "sequence",
    │             "multi-step", "chain", "schedule", "trigger", "CI/CD"
    │   └── TEMPLATE: workflow-automation
    │       File: templates/workflow-automation.md
    │
    └── Default / No specific keywords
        └── TEMPLATE: base
            File: templates/base.md
```

### Template Descriptions

| Template | Purpose | Key Sections |
|----------|---------|--------------|
| **api-integration** | Skills that call external APIs or services | Authentication, rate limiting, error handling, response parsing |
| **data-pipeline** | Skills that process, transform, or validate data | Input validation, transformation rules, output schema, error recovery |
| **workflow-automation** | Multi-step automated workflows | Step definitions, dependencies, state management, rollback |
| **base** | Generic skill structure | Minimal viable sections, extensible for custom needs |

### Template Override

Users may explicitly specify a template using the `template_hint` field:

```yaml
input: "Create a weather lookup skill"
template_hint: "api-integration"  # Forces api-integration template
```

If the specified template does not exist, CREATE mode returns an error and lists available templates.

---

## Inversion Pattern Questions

The Inversion Pattern ensures complete requirement elicitation BEFORE any generation begins. This prevents scope creep, missing features, and security gaps.

### Rule

**Phase 3 (ELICIT) MUST NOT begin until all 6 questions are answered.**

Ask **one question at a time**. Wait for the user's answer before asking the next question.

### The 6 Questions

| # | Question (ZH) | Question (EN) | Purpose |
|---|---------------|---------------|---------|
| 1 | 这个skill要解决什么核心问题？ | What core problem does this skill solve? | Defines purpose and scope |
| 2 | 主要用户是谁，技术水平如何？ | Who are the target users and what is their technical level? | Determines complexity and documentation depth |
| 3 | 输入是什么形式？ | What form does the input take? | Defines input schema and validation |
| 4 | 期望的输出是什么？ | What is the expected output? | Defines output schema and format |
| 5 | 有哪些安全或技术约束？ | What security or technical constraints apply? | Identifies security requirements and limitations |
| 6 | 验收标准是什么？ | What are the acceptance criteria? | Defines success metrics and test cases |

### Question Flow

```
Start Elicit Phase
    │
    ▼
Ask Q1 → Wait for answer → Validate answer
    │
    ▼
Ask Q2 → Wait for answer → Validate answer
    │
    ▼
Ask Q3 → Wait for answer → Validate answer
    │
    ▼
Ask Q4 → Wait for answer → Validate answer
    │
    ▼
Ask Q5 → Wait for answer → Validate answer
    │
    ▼
Ask Q6 → Wait for answer → Validate answer
    │
    ▼
All questions answered ✓
    │
    ▼
Proceed to GENERATE phase
```

### Validation Rules

Each answer is validated for:
- **Completeness**: Does it address the question?
- **Clarity**: Is it unambiguous?
- **Feasibility**: Is it technically achievable?
- **Security**: Does it introduce risks?

If an answer is insufficient, ask a follow-up question before proceeding.

---

## Security Checks

Security scanning is mandatory at the GENERATE phase gate. All skills are scanned for Common Weakness Enumeration (CWE) patterns before delivery.

### P0 Severity — Immediate ABORT

P0 findings are non-negotiable and block delivery immediately.

#### CWE-798: Hardcoded Credentials

**Description**: Detection of hardcoded passwords, API keys, tokens, or secrets in skill code or documentation.

**Patterns Detected:**
```regex
# OpenAI / Anthropic API keys
sk-[a-zA-Z0-9]{20,}

# AWS Access Key ID
AKIA[0-9A-Z]{16}

# Password assignments
password\s*=\s*["'][^"']{4,}["']

# API key assignments
api_key\s*=\s*["'][^"']{4,}["']

# Secret assignments
secret\s*=\s*["'][^"']{4,}["']

# Token assignments
token\s*=\s*["'][^"']{4,}["']

# Hardcoded Bearer tokens
Bearer\s+[a-zA-Z0-9\-._~+/]{20,}

# Generic hex secrets (heuristic)
[a-z0-9]{32,}
```

**Action:** ABORT immediately

**Remediation:**
```python
# BAD
api_key = "sk-abc123..."

# GOOD
api_key = os.environ["SERVICE_API_KEY"]

# SKILL DOC must include:
# Auth env var: SERVICE_API_KEY
```

---

#### CWE-89: SQL Injection

**Description**: Detection of SQL injection vulnerabilities through unsanitized user input in queries.

**Patterns Detected:**
```regex
# Template literals in database queries
(mysql|psql|sqlite3|db\.query)\s*\(.*\$\{

# Unparameterized WHERE clauses
WHERE\s+\w+\s*=\s*['"]?\s*\$\w+

# String concatenation in SQL
SELECT.*\+\s*user_input

# Percent formatting in SQL
execute\s*\(.*\%s.*%\s*\w+

# f-string SQL
f["']SELECT.*\{.*\}

# String concatenation INSERT
"INSERT INTO.*"\s*\+
```

**Action:** ABORT immediately

**Remediation:**
```python
# BAD
db.query(f"SELECT * FROM users WHERE id = {user_id}")

# GOOD
db.query("SELECT * FROM users WHERE id = ?", [user_id])
```

---

#### CWE-78: Command Injection

**Description**: Detection of command injection vulnerabilities through unsanitized user input in system commands.

**Patterns Detected:**
```regex
# eval with template literals
eval\s*\$\{

# exec with user input
exec\s*\(.*user

# system calls with variables
system\s*\(.*\$\{

# Python subprocess with shell=True
subprocess\..*shell\s*=\s*True

# os.system with concatenation
os\.system\s*\(.*\+

# Backtick commands with variables
`.*\$\{.*\}`

# Node.js exec with concatenation
child_process\.exec\s*\(.*\+
```

**Action:** ABORT immediately

**Remediation:**
```python
# BAD
subprocess.run(f"convert {user_file}", shell=True)

# GOOD
subprocess.run(["convert", validated_file], shell=False)
```

---

### P1 Severity — WARNING (Score Penalty)

P1 findings deduct points from the final score but do NOT block delivery. They must be documented in the skill's Security Baseline section.

#### CWE-22: Path Traversal (−50 points)

**Description**: Detection of path traversal vulnerabilities allowing access to files outside intended directories.

**Patterns Detected:**
```regex
\.\.\/           # ../
\.\.\\/          # ..\
%2e%2e%2f        # URL-encoded ../
%00              # Null byte injection
/etc/passwd      # Classic target
open\s*\(.*user  # open() with user-derived path
```

**Remediation:**
```python
safe_dir = os.path.abspath("./output")
requested = os.path.abspath(os.path.join(safe_dir, user_input))
assert requested.startswith(safe_dir), "Path traversal blocked"
```

---

### Security Scan Report

After scanning, a report is generated:

```
SECURITY SCAN REPORT
====================
Skill: <name> v<version>
Scanned: <ISO-8601>
Scanner: skill-framework v2.0.0

P0 FINDINGS (ABORT triggers):
  [NONE | list of findings with location]

P1 FINDINGS (score penalties):
  CWE-22: <location> — path not validated (−50 pts)

SCORE IMPACT: −<N> points total from P1 findings

RESULT: CLEAR | ABORT
```

### ABORT Protocol

When any P0 pattern is detected:

1. **DETECT** — Pattern matched during security scan
2. **STOP** — Immediately halt CREATE workflow
3. **LOG** — Record to `.skill-audit/security.jsonl`
4. **FLAG** — Mark outcome as "ABORT", tier as "FAIL"
5. **NOTIFY** — Present ABORT message to user with location
6. **REQUIRE** — Human sign-off required before resume
7. **DOCUMENT** — Root cause in audit trail

**Resume Conditions:**
- Human review completed and documented
- Root cause identified
- Fix applied and verified (re-scan CLEAR)
- Full security scan with all-CLEAR result
- Explicit human sign-off to resume

---

## Error Handling

### Error Types and Responses

| Error | Phase | Response | Recovery |
|-------|-------|----------|----------|
| Low confidence (< 0.70) | PARSE | Graceful degradation | Single-LLM mode, +50% thresholds |
| Template not found | SELECT | Error message | List available templates |
| Incomplete elicitation | ELICIT | Cannot proceed | Continue asking questions |
| Placeholders remain | GENERATE | Return to GENERATE | List missing fields |
| P0 security violation | SECURITY SCAN | ABORT | Human review required |
| Lean score < 300 | LEAN EVAL | Route to OPTIMIZE | Auto-start optimization |
| Lean score 300-349 | LEAN EVAL | Escalate to EVALUATE | Full evaluation pipeline |

### Recovery Actions

**Graceful Degradation (Low Confidence):**
- Switch to single-LLM deliberation
- Increase checkpoint thresholds by 50%
- Require additional human sign-off before DELIVER
- Flag output with `TEMP_CERT`
- Mandatory 72-hour review window

**ABORT Recovery:**
- Fix identified security violation
- Re-run SECURITY SCAN
- Re-run LEAN EVAL
- Proceed to DELIVER if all gates pass

---

## Example Workflow

### Input
```
"创建一个调用OpenWeather API返回摄氏温度的skill"
```

### Execution Trace

```
[1. PARSE]
  Language: ZH
  Intent: CREATE
  Keywords: ["API", "调用", "返回", "温度"]
  Confidence: 0.94 ✓

[2. SELECT TEMPLATE]
  Keywords match: api-integration
  Template: templates/api-integration.md ✓

[3. ELICIT]
  Q1: 这个skill要解决什么核心问题？
      → "查询指定城市的当前天气温度"
  Q2: 主要用户是谁，技术水平如何？
      → "开发人员，熟悉API调用"
  Q3: 输入是什么形式？
      → "城市名称（字符串）"
  Q4: 期望的输出是什么？
      → "摄氏温度（数字）和单位"
  Q5: 有哪些安全或技术约束？
      → "需要API key， rate limit 60/min"
  Q6: 验收标准是什么？
      → "输入'Beijing'返回温度数值，错误时返回友好提示"
  All questions answered ✓

[4. GENERATE]
  Filled template: api-integration
  Sections generated: §1-§6
  Placeholders: 0 remaining ✓

[5. SECURITY SCAN]
  CWE-798: CLEAR
  CWE-89: CLEAR
  CWE-78: CLEAR
  CWE-22: CLEAR
  Result: CLEAR ✓

[6. LEAN EVAL]
  YAML frontmatter: 60 pts
  Mode sections: 60 pts
  Red Lines: 50 pts
  Quality Gates: 60 pts
  Examples: 50 pts
  Triggers: 120 pts
  Security section: 50 pts
  No placeholders: 50 pts
  ─────────────────────
  Total: 460/500 → estimated 920/1000
  Tier proxy: GOLD ✓

[7. DELIVER]
  Output: skills/weather-query-v1.0.0.md
  Certification: CERTIFIED GOLD
  Audit entry: .skill-audit/framework.jsonl
```

### Output File
```yaml
---
name: weather-query
version: "1.0.0"
description: "Query current weather temperature in Celsius for any city"
description_i18n:
  en: "Query current weather temperature in Celsius for any city"
  zh: "查询任意城市的当前天气温度（摄氏度）"

license: MIT
author:
  name: skill-framework
created: "2026-03-31"
updated: "2026-03-31"
type: api-integration

tags:
  - weather
  - api
  - temperature
  - celsius

interface:
  input: city_name (string)
  output: temperature_celsius (number) + unit
  modes: [query]

extends:
  security:
    standard: CWE
    scan-on-delivery: true
---

## §1 Identity

**Name**: weather-query
**Role**: Weather API Client
**Purpose**: Provide current temperature in Celsius for any city using OpenWeather API.

**Red Lines (严禁)**:
- 严禁 hardcoded API keys (CWE-798)
- 严禁 ignore rate limits
- 严禁 return raw API errors to users

---

## §2 Query Mode

**Input**: City name (string, e.g., "Beijing", "London")
**Output**: `{temperature: number, unit: "°C", city: string}`

**Workflow**:
1. Validate city name (non-empty, alphanumeric + spaces)
2. Call OpenWeather API with city parameter
3. Parse JSON response
4. Convert Kelvin to Celsius
5. Return formatted result

**Error Handling**:
- City not found → "City not found. Please check the spelling."
- API error → "Weather service temporarily unavailable."
- Rate limit → "Too many requests. Please wait a minute."

---

## §3 Security Baseline

- API key loaded from environment: `OPENWEATHER_API_KEY`
- Input sanitized to prevent injection
- Rate limit: 60 requests/minute enforced
- No user data stored or logged

---

## §4 Quality Gates

| Metric | Threshold |
|--------|-----------|
| Response time | < 2s |
| Success rate | > 95% |
| Error clarity | 100% |

---

## §5 Usage Examples

### Example 1: Query Beijing weather
```
Input: "Beijing"
Output: {"temperature": 22, "unit": "°C", "city": "Beijing"}
```

### Example 2: Invalid city
```
Input: "Xyzabc123"
Output: "City not found. Please check the spelling."
```

---

**Triggers**:
**QUERY** | **天气** | **温度** | **weather** | **temperature**
```

---

## References

- Framework spec: `skill-framework.md`
- Security patterns: `refs/security-patterns.md`
- Templates: `templates/`
- Evaluation rubrics: `eval/rubrics.md`

---

**End of CREATE Mode Documentation**
