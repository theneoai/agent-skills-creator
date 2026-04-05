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
