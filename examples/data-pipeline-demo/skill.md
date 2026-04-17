---
name: csv-to-json-validator
version: "1.0.0"
spec_version: "1.0"
description: "Validates a CSV file against a declared schema and emits a JSON array with explicit error reporting."
description_i18n:
  en: "Validates CSV rows against a field-typed schema; emits JSON + an error report. Stops on hard errors, warns on soft ones."
  zh: "按声明的 schema 验证 CSV 数据行；输出 JSON 数组与错误报告，遇硬错误停止、软错误警告。"

license: MIT
author:
  name: skill-writer-examples
created: "2026-04-17"
updated: "2026-04-17"
type: data-pipeline

skill_tier: functional

tags:
  - data-pipeline
  - csv
  - json
  - validation
  - schema

triggers:
  en:
    - "validate csv against schema"
    - "convert csv to json with validation"
    - "csv schema check"
    - "load csv and emit json"
  zh:
    - "校验 csv"
    - "csv 转 json"
    - "csv 按 schema 检查"

interface:
  input: csv-file + schema-declaration
  output: json-array + validation-report

extends:
  evaluation:
    metrics: [trigger_accuracy, output_schema_conformance, error_recall]
    thresholds: {trigger_accuracy: 0.90, output_schema_conformance: 1.0, error_recall: 0.95}
  production:
    cost_budget_usd: 0.04
    est_tokens_p50: 2400
    est_tokens_p95: 6800
    latency_budget_ms: 10000
    est_p95_ms: 7200

generation_method: "human-authored"
validation_status: "full-eval"

---

# csv-to-json-validator

## §1  Identity

**Role**: Data-pipeline skill that validates CSV input against a declared schema and produces a structured JSON array, preserving every row-level error.

**Red Lines**:
- MUST NOT silently drop rows. Every rejection emits an error record.
- MUST NOT infer types from data. The schema is authoritative.
- MUST NOT write anywhere other than the declared output path.

## §2  Skill Summary

WHAT: CSV → JSON with per-row validation against a typed schema.
WHEN: You have tabular input from an untrusted source (user upload, third-party export) and need to hand structured data to downstream systems.
WHO: Data engineers, backend developers, data-QA.
NOT-FOR: Free-text/unstructured text (use a parser). Binary formats. Streaming use-cases > 10 MB (this skill is bounded to in-memory).

## §3  Negative Boundaries

- Do NOT use for Excel (.xlsx) → use a dedicated xlsx reader upstream.
- Do NOT use for JSON Lines or NDJSON → input format is canonical CSV only.
- Do NOT use for "best-effort" parsing with type coercion → schema mismatches must fail loudly.

## §4  Mode Router

| User says...                            | Mode          |
|-----------------------------------------|---------------|
| "validate this csv", "check schema"     | VALIDATE-ONLY |
| "convert csv to json", "csv → json"     | CONVERT       |
| "validate and convert"                  | FULL (default)|

## §5  Workflow (FULL mode)

```
1. PARSE
   - Read input CSV (UTF-8, RFC 4180).
   - Reject if file size > 10 MB → ABORT with MaxSizeExceeded.
2. LOAD SCHEMA
   - Schema is a YAML or JSON object mapping column → type + constraints.
   - Supported types: string, int, float, bool, iso-date, email, url, enum.
3. VALIDATE ROWS (per row)
   - For each column:
     a. Check type.
     b. Check required/nullable.
     c. Check constraints (min, max, regex, enum values).
   - Collect all errors for the row (don't short-circuit).
   - If the row has ≥ 1 hard error, record it in `errors` and continue.
4. EMIT
   - JSON array of validated rows (in source order).
   - Separate `errors` array of {row_index, column, code, message}.
   - Summary: {total_rows, valid_rows, invalid_rows, column_coverage}.
5. EXIT
   - Exit 0 if invalid_rows == 0, else exit 1 (for script consumers).
```

## §6  Error Handling

| Condition                       | Action                                        |
|---------------------------------|-----------------------------------------------|
| File > 10 MB                    | ABORT; MaxSizeExceeded                        |
| Non-UTF-8 / not valid CSV       | ABORT; FormatError                            |
| Schema unparseable              | ABORT; SchemaError                            |
| Schema column missing from CSV  | WARN; continue with null                      |
| CSV column not in schema        | WARN; drop from output (report in summary)    |
| Row-level type mismatch         | RECORD in errors[]; do not include in output  |
| Duplicate column name in CSV    | ABORT; AmbiguousHeader                        |

## §7  Example — bilingual

**User (EN)**: "Validate orders.csv against orders-schema.yaml and emit JSON."

**Output** (example):

```json
{
  "summary": {"total_rows": 1000, "valid_rows": 987, "invalid_rows": 13},
  "data": [
    {"order_id": "ORD-001", "amount": 49.99, "email": "alice@example.com"},
    ...
  ],
  "errors": [
    {"row_index": 42, "column": "amount", "code": "NOT_FLOAT", "message": "'N/A' is not a valid float"},
    {"row_index": 88, "column": "email", "code": "INVALID_EMAIL", "message": "'not-an-email' failed RFC 5322 pattern"}
  ]
}
```

**User (ZH)**: "按 orders-schema.yaml 校验 orders.csv 并输出 JSON。"

(输出结构同上；message 字段可按 language 切换到中文。)

## §8  Security Baseline

Detected patterns (OWASP Agentic Top 10):

- **ASI02 Prompt Injection (input)**: CSV cells may contain `=SUM(...)` formula-injection payloads; emit data as JSON strings, never as formulas.
- **ASI07 Sensitive Info Disclosure**: Never log full row contents at INFO level; redact fields matching PII regex.
- **CWE-22 Path Traversal**: Reject input paths containing `..` or absolute paths outside the declared workspace.

## §9  Tests (benchmark cases)

1. Valid 10-row CSV → all rows pass, 0 errors.
2. 5 of 10 rows have wrong type in 1 column → 5 errors collected, 5 valid rows in output.
3. Missing required column → WARN + continue with null.
4. Formula injection (`=CMD("rm -rf ~")`) → emitted as literal string, no evaluation.
5. 20 MB file → ABORT immediately before parsing.

## §10  Provenance

`generation_method: human-authored` · `validation_status: full-eval` · authored as a reference example for `examples/data-pipeline-demo/`.
