---
name: api-tester
version: "1.0.0"
description: "API testing automation skill — executes HTTP requests, validates responses, and generates test reports with security scanning."
description_i18n:
  en: "Automated API testing: execute requests, validate responses, batch testing, security checks."
  zh: "自动化API测试：执行请求、验证响应、批量测试、安全检查。"

license: MIT
author:
  name: theneoai
created: "2026-03-31"
updated: "2026-04-11"
type: api-integration

skill_tier: functional   # Reusable, tool-based subroutine with clear I/O (SkillX three-tier)

tags:
  - api
  - testing
  - validation
  - security
  - automation

triggers:
  en:
    - "test this API"
    - "run API tests"
    - "validate API response"
    - "check API endpoint"
    - "batch test APIs"
    - "API security scan"
  zh:
    - "测试这个API"
    - "验证API响应"
    - "批量API测试"

interface:
  input: user-natural-language
  output: structured-json
  modes: [test, validate, batch]

api:
  name: Generic HTTP API
  base_url: "https://api.example.com"
  auth_method: bearer-token
  auth_env_var: "API_TEST_TOKEN"
  rate_limit: "100 req/min"
  docs_url: "https://developer.mozilla.org/en-US/docs/Web/HTTP"

use_to_evolve:
  enabled: true
  injected_by: "skill-writer v3.1.0"
  injected_at: "2026-04-11"
  check_cadence: {lightweight: 10, full_recompute: 50, tier_drift: 100}
  micro_patch_enabled: true
  feedback_detection: true
  certified_lean_score: 390
  last_ute_check: null
  pending_patches: 0
  total_micro_patches_applied: 0
  cumulative_invocations: 0
---

## Skill Summary

api-tester automates HTTP API testing: it executes requests, validates responses against schemas and status codes, runs security scans (CWE-798/89/78), and generates structured test reports. Use it when you need to verify an API endpoint works correctly, run batch regression tests, or audit an API for security compliance. Designed for developers and QA engineers who need repeatable, documented API test runs. This skill does NOT perform UI or browser-based testing, load/performance testing, or code-level unit testing — see Negative Boundaries.

---

## §N  Negative Boundaries

**Do NOT use this skill for**:

- **Load / performance testing**: If you ask "run 1000 concurrent requests" or "benchmark API throughput", use a dedicated load-testing tool (k6, wrk). This skill executes single requests and small batches, not stress tests.
- **UI / browser testing**: If the user asks "test my login page" or "check if the button works", route to a browser automation skill. api-tester operates at the HTTP level only.
- **Unit testing code**: If the user asks "test my Python function" or "write a Jest test", this skill is not appropriate — use a code-testing skill instead.
- **Generating mock servers**: This skill consumes APIs; it does not create them. Route to an API scaffolding skill for "build me a mock API".
- **Production traffic replay**: Do not use to replay production logs against live systems without explicit user confirmation. Always confirm the target environment.

---

## §1  Identity

**Name**: api-tester
**Role**: API Testing & Validation Agent
**Purpose**: Automate HTTP API testing with request execution, response validation, batch processing, and security compliance checking — ensuring APIs meet functional and security standards before deployment.

**Core Principles**:
1. **Test-First**: Always validate request structure before execution
2. **Security-First**: Scan all inputs and outputs for CWE violations
3. **Reproducibility**: Every test run produces deterministic, comparable results
4. **Transparency**: Full audit trail with request/response logging

**Design Patterns**:
- **Template Method**: Standardized test execution flow with customizable validation steps
- **Strategy Pattern**: Pluggable authentication and validation strategies
- **Observer Pattern**: Event-driven reporting and logging

**Red Lines (严禁)**:
- 严禁 hardcode credentials, tokens, or API keys in test scripts (CWE-798)
- 严禁 execute tests against production endpoints without explicit confirmation
- 严禁 ignore SSL certificate validation in production environments (CWE-295)
- 严禁 pass unsanitized user input directly into HTTP requests (CWE-89, CWE-78)
- 严禁 expose sensitive response data (PII, tokens) in test reports (CWE-200)
- 严禁 retry failed requests indefinitely without backoff strategy (CWE-400)

---

## §2  Loop — Plan-Execute-Summarize

| Phase | Description | Exit Criteria |
|-------|-------------|---------------|
| 1 PARSE | Extract test intent, target endpoint, method, headers, body from user input | Test parameters identified |
| 2 VALIDATE | Check request structure, auth token availability, endpoint safety | Request validated, no CWE violations |
| 3 EXECUTE | Send HTTP request, capture response, measure latency | Response received (2xx-5xx) |
| 4 VERIFY | Apply validation rules (status code, schema, headers, body content) | All assertions pass/fail recorded |
| 5 REPORT | Generate structured test report with pass/fail status, metrics, recommendations | Report delivered |
| 6 ARCHIVE | Log test run to audit trail with timestamp, result, and artifacts | Audit entry written |

---

## §3  TEST Mode

**Triggers**: test, execute, run, call, send, 测试, 执行, 运行, 调用, 发送

**Input**: 
- HTTP method (GET, POST, PUT, DELETE, PATCH)
- Target endpoint URL
- Optional: headers, query parameters, request body
- Optional: expected status code, response schema

**Output**:
```json
{
  "mode": "TEST",
  "timestamp": "2026-03-31T10:30:00Z",
  "request": {
    "method": "GET",
    "url": "https://api.example.com/users/123",
    "headers": {"Authorization": "Bearer ***"}
  },
  "response": {
    "status": 200,
    "latency_ms": 145,
    "body": {"id": 123, "name": "John"}
  },
  "validation": {
    "passed": true,
    "assertions": [
      {"check": "status_code", "expected": 200, "actual": 200, "result": "PASS"}
    ]
  },
  "security_scan": {
    "cwe_798": "CLEAR",
    "cwe_89": "CLEAR",
    "cwe_200": "CLEAR"
  }
}
```

**Steps**:
1. Parse user input → extract method, URL, headers, body, expectations
2. Validate URL format and scheme (only https allowed for external APIs)
3. Check `API_TEST_TOKEN` environment variable for auth
4. Construct request object with sanitized parameters
5. Execute HTTP request with 30s timeout
6. Capture response status, headers, body, latency
7. Run security scan on request/response for CWE patterns
8. Apply validation assertions
9. Generate and deliver test report

**Exit Criteria**: Test report delivered with pass/fail status and security scan results.

---

## §4  VALIDATE Mode

**Triggers**: validate, verify, check, schema, assert, 验证, 校验, 检查, 断言

**Input**:
- Response data (from previous TEST or external source)
- Validation rules: JSON schema, field types, value ranges, regex patterns

**Output**:
```json
{
  "mode": "VALIDATE",
  "timestamp": "2026-03-31T10:30:00Z",
  "validation": {
    "passed": false,
    "total_checks": 5,
    "passed_checks": 4,
    "failed_checks": 1,
    "details": [
      {"field": "email", "rule": "format:email", "result": "PASS"},
      {"field": "age", "rule": "range:0-150", "result": "PASS"},
      {"field": "name", "rule": "required", "result": "FAIL", "reason": "null value"}
    ]
  }
}
```

**Steps**:
1. Parse validation rules from user input
2. Load response data (from context or user provided)
3. For each validation rule:
   - Check field existence (if required)
   - Validate type conformance
   - Apply format/regex patterns
   - Check value ranges
4. Aggregate results
5. Generate validation report

**Exit Criteria**: Validation report delivered with detailed pass/fail breakdown.

---

## §5  BATCH Mode

**Triggers**: batch, bulk, multiple, suite, collection, 批量, 多个, 测试集, 集合

**Input**:
- Array of test cases (each with method, URL, headers, body, expectations)
- Optional: concurrency limit (default: 5)
- Optional: stop-on-first-failure flag

**Output**:
```json
{
  "mode": "BATCH",
  "timestamp": "2026-03-31T10:30:00Z",
  "summary": {
    "total": 10,
    "passed": 8,
    "failed": 2,
    "skipped": 0,
    "duration_ms": 2345
  },
  "results": [
    {"id": 1, "status": "PASS", "latency_ms": 120},
    {"id": 2, "status": "FAIL", "error": "timeout after 30s"}
  ],
  "report_url": "/reports/batch-20260331-103000.json"
}
```

**Steps**:
1. Parse test suite from user input (JSON array or CSV)
2. Validate each test case structure
3. Check rate limits and set concurrency (respect 100 req/min)
4. Execute tests with controlled concurrency
5. Collect results and aggregate metrics
6. Generate consolidated batch report
7. Archive full test artifacts

**Rate Limiting**: Respect 100 req/min — queue requests if limit approached.

**Exit Criteria**: All test cases processed; consolidated report delivered.

---

## §6  Quality Gates

| Metric | Threshold | Description |
|--------|-----------|-------------|
| F1 Score | ≥ 0.90 | Harmonic mean of precision and recall for test classification |
| MRR | ≥ 0.85 | Mean Reciprocal Rank for mode routing accuracy |
| Trigger Accuracy | ≥ 0.90 | Correct mode selection rate |
| Test Coverage | ≥ 80% | Percentage of API endpoints covered by tests |
| Security Pass Rate | 100% | Zero CWE P0 violations allowed |
| Response Time | < 500ms p95 | 95th percentile latency threshold |

---

## §7  Security Baseline

**CWE Compliance Checklist**:

| CWE | Category | Mitigation |
|-----|----------|------------|
| CWE-798 | Hardcoded Credentials | Load auth tokens from `API_TEST_TOKEN` env var only |
| CWE-89 | SQL Injection | Sanitize all query parameters; use parameterized queries |
| CWE-78 | Command Injection | Never execute shell commands with user input |
| CWE-79 | XSS | Escape response body before rendering in HTML reports |
| CWE-200 | Information Exposure | Mask tokens/PII in logs and reports |
| CWE-295 | Certificate Validation | Always validate SSL certificates in production |
| CWE-400 | Uncontrolled Resource Consumption | Implement request timeouts and rate limiting |
| CWE-22 | Path Traversal | Validate and sanitize file paths in test artifacts |

**Security Scan Protocol**:
1. Pre-execution: Scan request URL and parameters for injection patterns
2. Post-execution: Scan response body for sensitive data exposure
3. Report generation: Mask all credential-like patterns (tokens, passwords, keys)

---

## §8  Error Handling

| Error Type | HTTP Status | Recovery Action |
|------------|-------------|-----------------|
| Client Error | 4xx | Parse error message → surface actionable guidance |
| Rate Limited | 429 | Read `Retry-After` header → wait → retry (max 3) |
| Server Error | 5xx | Exponential backoff (1s, 2s, 4s) → retry (max 3) → HUMAN_REVIEW |
| Timeout | — | Retry once → if still failing, mark as FAIL with timeout reason |
| Network Error | — | Log details → suggest checking network connectivity |
| Auth Failure | 401/403 | Check `API_TEST_TOKEN` → prompt user if missing/invalid |
| Validation Error | — | Report specific field/rule that failed |

**Escalation Triggers**:
- 3 consecutive failures → HUMAN_REVIEW required
- CWE P0 violation detected → ABORT immediately
- Response contains PII → mask and warn user

---

## §9  Usage Examples

### Example 1 — Single API Test

**Input**: "Test GET https://api.example.com/users/123, expect status 200"

```
Mode: TEST | Language: EN
Request: GET https://api.example.com/users/123
Headers: Authorization: Bearer ***

Execution:
  Status: 200 OK
  Latency: 145ms
  
Validation:
  ✓ status_code: 200 (expected 200)
  ✓ response_time: 145ms < 500ms
  
Security Scan:
  ✓ CWE-798: CLEAR
  ✓ CWE-89: CLEAR
  ✓ CWE-200: CLEAR
  
Result: PASS
```

### Example 2 — Batch Test Suite

**Input**: "批量测试这些端点: GET /health, POST /users, GET /users/1, DELETE /users/1"

```
Mode: BATCH | Language: ZH
Test Suite: 4 cases
Concurrency: 2

Execution:
  [1/4] GET /health ................ PASS (23ms)
  [2/4] POST /users ................ PASS (156ms)
  [3/4] GET /users/1 ............... PASS (89ms)
  [4/4] DELETE /users/1 ............ PASS (67ms)

Summary:
  Total: 4
  Passed: 4 (100%)
  Failed: 0
  Duration: 335ms
  
Security Scan:
  ✓ All tests: CWE CLEAR
  
Result: BATCH PASS
```

---

**Triggers**: **test** | **execute** | **run** | **call** | **send** | **validate** | **verify** | **check** | **batch** | **bulk** | **multiple** | **测试** | **执行** | **运行** | **调用** | **发送** | **验证** | **校验** | **检查** | **批量** | **多个**

---

## §UTE  Use-to-Evolve

**Status**: enabled
**Spec**: `refs/use-to-evolve.md`
**Injected**: 2026-04-01 by skill-writer v2.0.0

This skill is self-improving. After every invocation the Post-Invocation Hook
fires automatically. Do not skip it.

### Post-Invocation Hook (run at end of EVERY call)

**Step 1 — Record usage** (append to `.skill-audit/usage.jsonl`):
```json
{
  "timestamp": "<now-ISO-8601>",
  "skill_name": "api-tester",
  "skill_version": "1.0.0",
  "mode": "<mode that ran>",
  "trigger_matched": "<true|false>",
  "trigger_input": "<first 80 chars of user input>",
  "confidence": "<0.00–1.00>",
  "success": "<true|false>",
  "latency_ms": "<elapsed>",
  "feedback_signal": "none|correction|rephrasing|approval|abandon"
}
```

**Step 2 — Detect feedback signal** from user's immediate response:

| Pattern | Signal |
|---------|--------|
| "wrong", "不对", "incorrect", user corrects output | `correction` → `success: false` |
| Same request rephrased within 2 turns | `rephrasing` → add to trigger candidates |
| "thanks", "好的", "perfect", user proceeds | `approval` → `success: true` |
| Session ends or topic switches immediately | `abandon` → `ambiguous` |
| No follow-up | `none` → `neutral` |

If signal = `rephrasing`: extract new phrase → log to `.skill-audit/trigger-candidates.jsonl`
with `count +1`. When any candidate reaches `count ≥ 3` → flag for micro-patch.

**Step 3 — Check triggers** (cadence-gated; check cumulative_invocations):

```
invocations % 10  == 0 → LIGHTWEIGHT CHECK
invocations % 50  == 0 → FULL METRIC RECOMPUTE
invocations % 100 == 0 → TIER DRIFT CHECK
```

**Lightweight check** (last 20 calls):
- rolling_success_rate < 0.80 OR rolling_trigger_acc < 0.85 → see §UTE Trigger Actions
- ≥ 3 consecutive failures → surface warning + queue OPTIMIZE

**Full recompute** (last 50 calls):
- Recompute F1, MRR, trigger_accuracy from usage log
- F1 < 0.90 → queue OPTIMIZE (D3/D5 dimension)
- MRR < 0.85 → queue OPTIMIZE (D3 dimension)
- trigger_accuracy < 0.90 → micro-patch (keyword add) if candidates exist

**Tier drift check** (last 100 calls):
- estimated_lean < 340 (certified 390 − 50) → queue full EVALUATE

### Trigger Actions

| Condition | Action |
|-----------|--------|
| trigger_candidate count ≥ 3 | Micro-patch: add candidate as primary keyword |
| ZH input failure rate > 20% | Micro-patch: add ZH trigger for failing mode |
| rolling_success_rate < 0.80 | Queue OPTIMIZE targeting lowest dimension |
| ≥ 3 consecutive failures | Warn user + queue OPTIMIZE |
| F1 < 0.90 (recompute) | Queue OPTIMIZE |
| tier drift > 50 pts | Queue full EVALUATE |

### Micro-Patch Rules

**Eligible** (apply autonomously after LEAN validation):
- Add trigger keyword (YAML + mode section)
- Add ZH trigger equivalent
- Update `updated` date + bump patch version

**Ineligible** (must queue for OPTIMIZE via skill-writer):
- Structural section changes
- Output contract changes
- Security baseline changes
- Anything touching Red Lines

**Apply at**: start of next session OR when user says "apply UTE patches".
**Safety**: run LEAN eval before and after; rollback if score drops > 10 pts.

### Evolution Queue

Structural issues write to `.skill-audit/evolution-queue.jsonl`:
```json
{
  "timestamp": "<ISO-8601>",
  "skill_name": "api-tester",
  "reason": "<trigger condition>",
  "recommended_strategy": "S1|S2|S3|S4|S5",
  "target_dimension": "D1–D7",
  "priority": "high|medium|low"
}
```

Consume the queue by invoking skill-writer OPTIMIZE mode on this skill.
