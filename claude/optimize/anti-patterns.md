# Anti-Patterns Catalog

> **Purpose**: Common mistakes that degrade skill quality, trigger failures, or create security issues.
> **Load**: During OPTIMIZE mode and during LLM-2 Reviewer deliberation.
> **Format**: Each anti-pattern has a symptom, root cause, and specific fix.

---

## Category A — Trigger Anti-Patterns

### A1 — Trigger Monoculture

**Symptom**: Only one primary keyword per mode; trigger accuracy < 0.90.

**Root Cause**: Skill was written for the author's vocabulary, not the user's.

**Fix**: Add 5+ synonyms per mode. Use the benchmark failure log to find actual user phrasings.

**Example**:
```
BAD:  CREATE keywords: [create]
GOOD: CREATE keywords: [create, build, make, generate, new, scaffold, develop, add]
               ZH:     [创建, 新建, 构建, 生成, 开发, 制作]
```

---

### A2 — Missing ZH Triggers

**Symptom**: ZH-language inputs always fail or route incorrectly.

**Root Cause**: Only English keywords defined; language weight rules not applied.

**Fix**: Add a ZH equivalent for every EN primary trigger. Reference `refs/triggers.md §1`.

---

### A3 — Overlapping Triggers

**Symptom**: Two modes share the same keyword; wrong mode selected for ambiguous inputs.

**Root Cause**: Generic words like "fix" assigned to multiple modes.

**Fix**: Add negative patterns. Example: "fix" in OPTIMIZE context must NOT match RESTORE
unless the word "restore" or "rollback" also appears.

---

### A4 — Anchoring to Examples

**Symptom**: Skill only works when the user's input closely mirrors the usage examples.

**Root Cause**: Triggers derived from example sentences rather than intent vocabulary.

**Fix**: Enumerate abstract trigger words (verbs of intent), not just example phrases.

---

### A5 — No Confidence Fallback

**Symptom**: Low-confidence inputs produce silent wrong-mode execution.

**Root Cause**: No confidence threshold check; no "ask user" path.

**Fix**: Add confidence routing:
```
confidence ≥ 0.85 → auto-route
confidence 0.70–0.84 → confirm before route
confidence < 0.70 → ask user which mode
```

---

## Category B — Structure Anti-Patterns

### B1 — Wall of Text Identity Section

**Symptom**: `§ Identity` is a paragraph of prose with no scannable structure.

**Root Cause**: Free-form writing instead of structured sections.

**Fix**: Break into: Name, Role, Purpose, Core Principles (bulleted), Red Lines (严禁 list).

---

### B2 — Mode-Free Skill

**Symptom**: Skill performs one action but has no defined modes; any input triggers the same behavior.

**Root Cause**: Skill was scoped to a single use case; no routing needed (author thought).

**Fix**: Even single-purpose skills need at least one named mode with trigger keywords and exit criteria.
If truly single-mode, define it as `default` mode with explicit triggers.

---

### B3 — Underdefined Loop

**Symptom**: `§ Loop` section exists but phases have no exit criteria; skill can loop indefinitely.

**Root Cause**: Loop phases listed as bullet points without gates.

**Fix**: Add exit criteria column to phase table. Define what constitutes phase completion.

---

### B4 — Missing Red Lines

**Symptom**: No "严禁" section; skill allows dangerous operations without explicit prohibition.

**Root Cause**: Author assumed constraints were obvious.

**Fix**: Add `§ Red Lines (严禁)` with at minimum 3 explicit prohibitions relevant to the skill domain.

---

### B5 — Version Freeze

**Symptom**: Skill's `updated` date never changes; version stays at `1.0.0` despite multiple edits.

**Root Cause**: Version not incremented during OPTIMIZE cycles.

**Fix**: Follow semver:
- patch (x.x.N): trigger keyword additions, wording clarifications
- minor (x.N.0): new mode added, schema change
- major (N.0.0): complete rebuild or breaking interface change

---

## Category C — Output Anti-Patterns

### C1 — Format Ambiguity

**Symptom**: Different runs of the same skill produce inconsistent output formats (sometimes JSON, sometimes prose).

**Root Cause**: Output format not specified per mode.

**Fix**: Add explicit `**Output**:` block per mode with field names and types. Use a code block to show the schema.

---

### C2 — Missing Exit Criteria

**Symptom**: It's unclear when a mode is "done"; skill keeps refining indefinitely.

**Root Cause**: No definition of done for the mode.

**Fix**: Add `**Exit Criteria**:` per mode. Must be a verifiable condition, not a vague statement.

```
BAD:  Exit when the skill is good enough.
GOOD: Exit when: F1 ≥ 0.90 AND security scan clean AND user acknowledged output.
```

---

### C3 — Error Swallowing

**Symptom**: API failures, validation errors, or pipeline exceptions disappear silently; user sees no feedback.

**Root Cause**: No error-handling section in the skill; errors not surfaced in output contract.

**Fix**: Add error output contract per mode:
```
**Error Output**:
  code: <HTTP status or error enum>
  message: <human-readable description>
  action: <what user should do next>
```

---

### C4 — Over-verbose Output

**Symptom**: Every invocation returns megabytes of raw data; user is overwhelmed.

**Root Cause**: Skill returns the entire API response or full dataset without summarization.

**Fix**: Define output fields explicitly. Return only the fields listed in the output schema.
Offer a "verbose" flag if raw data is sometimes needed.

---

## Category D — Security Anti-Patterns

### D1 — Inline Credentials (CWE-798)

**Symptom**: Skill text contains `api_key = "sk-..."` or `password = "..."`.

**Root Cause**: Author included example credentials or forgot to parameterize.

**Fix** (ABORT path):
1. Remove credential value immediately.
2. Replace with env-var reference: `os.environ["SERVICE_API_KEY"]`.
3. Document the env-var name in the Security Baseline section.
4. Run security scan to confirm clear.

---

### D2 — Pass-Through User Input to Queries (CWE-89)

**Symptom**: User input directly concatenated into a query string, file path, or shell command.

**Root Cause**: No input validation layer between user input and query construction.

**Fix**:
- Use parameterized queries / prepared statements.
- Whitelist input values where possible.
- For file paths: validate against allowed directory; reject `..`.
- Document in Security Baseline: "Field `X` is parameterized before use in query."

---

### D3 — Raw API Error Exposure (CWE-209)

**Symptom**: Skill surfaces full API error stack traces or internal error messages to users.

**Root Cause**: Error from external service returned verbatim.

**Fix**: Catch external errors. Return a human-readable message. Log the raw error internally.
```
User sees: "Weather service is temporarily unavailable. Please try again."
Log records: {"error": "HTTP 503 from api.openweather.com at /data/2.5/weather"}
```

---

### D4 — Unlimited Batch / No Rate Guard (CWE-400 Resource Exhaustion)

**Symptom**: Batch mode accepts arbitrarily large inputs; can be used to exhaust API quota or memory.

**Root Cause**: No limit on batch size or item count.

**Fix**: Set `BATCH_LIMIT` constant. Reject inputs exceeding it. Document the limit in the skill.

---

### D5 — Unchecked Path Traversal (CWE-22)

**Symptom**: Skill writes to or reads from a file path constructed from user input; allows `../../etc/passwd`.

**Root Cause**: No path validation before file operations.

**Fix**:
```python
import os
safe_dir = os.path.abspath("./output")
requested = os.path.abspath(os.path.join(safe_dir, user_filename))
if not requested.startswith(safe_dir):
    raise ValueError("Path traversal detected")
```
Document this check in the Security Baseline section.

---

## Category E — Quality Gate Anti-Patterns

### E1 — Threshold-Free Quality Section

**Symptom**: `§ Quality Gates` section exists but contains only "high quality output expected" or similar prose.

**Root Cause**: Author did not know the thresholds or did not want to commit to them.

**Fix**: Replace prose with the standard threshold table. Thresholds must be numeric.
Minimum: F1 ≥ 0.90, MRR ≥ 0.85, Trigger Accuracy ≥ 0.90.

---

### E2 — Unmeasurable Acceptance Criteria

**Symptom**: Acceptance criteria written as "user is satisfied" or "output looks good."

**Root Cause**: Requirements gathering skipped or rushed (Inversion pattern not applied).

**Fix**: Return to requirement elicitation (§6 of skill-framework.md). Extract measurable criteria:
```
BAD:  "The skill should return good weather data."
GOOD: "The skill returns temperature ±1°C of ground truth for 90% of test locations."
```

---

### E3 — TEMP_CERT Debt Accumulation

**Symptom**: Multiple skills in the system have `TEMP_CERT` status; 72-hour review windows lapsed.

**Root Cause**: TEMP_CERT was used as a permanent workaround instead of a temporary flag.

**Fix**:
1. List all TEMP_CERT skills from `.skill-audit/framework.jsonl`.
2. For each: run EVALUATE → if still failing, run OPTIMIZE.
3. Do not issue new TEMP_CERTs until backlog is cleared.

---

## Anti-Pattern Severity Table

| ID | Category | Severity | Auto-route to |
|----|----------|----------|---------------|
| A1–A5 | Triggers | WARNING | S1 (Expand Keywords) |
| B1–B5 | Structure | WARNING | S2 (Fill Sections) |
| C1–C4 | Output | WARNING | S3 (Clarify Output) |
| D1 | Security | **ERROR** (ABORT) | S4 (Security Harden) |
| D2 | Security | **ERROR** (ABORT) | S4 |
| D3–D5 | Security | WARNING | S4 |
| E1–E3 | Quality Gates | WARNING | S5 (Add Thresholds) |

**ERROR = ABORT**: Skill must not be delivered. Fix required before any further evaluation.
