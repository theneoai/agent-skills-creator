# Anti-Patterns Reference

> Detailed anti-patterns, security rules, and edge cases. See [SKILL.md §6](../SKILL.md#-6--anti-patterns) for summary.

---

## Security Red Lines (严禁)

- ❌ **Never** hardcode API keys or secrets in SKILL.md (CWE-798)
- ❌ **Never** use `eval`, `exec`, or dynamic code execution (Code Injection)
- ❌ **Never** expose system paths or credentials in logs
- ❌ **Never** skip input validation on file paths (Path Traversal)
- ❌ **Never** use `rm -rf` without safeguards

## Security Best Practices (安全实践)

- ✅ Validate all file paths with `realpath` before access
- ✅ Use environment variables for secrets: `${API_KEY}` not `sk-abc123`
- ✅ Implement timeout on all external calls (default: 30s)
- ✅ Add circuit breaker: 3 failures → 60s cooldown
- ✅ Sanitize all user inputs before shell interpolation

## OWASP Alignment

- **CWE-798**: Hard-coded Credentials → Use env vars
- **CWE-77**: Command Injection → Validate and sanitize inputs
- **CWE-20**: Improper Input Validation → Always validate paths

---

## Mode Detection Triggers

### CREATE Mode
- write skill, create skill, make skill, build skill, develop skill, generate skill
- new skill, start quick, start standard, start expert
- skill, quick, standard, expert

### EVALUATE Mode
- evaluate skill, test skill, score skill, assess skill, check skill, review skill
- audit skill, certify skill, gap analysis, skill quality, skill score, skill performance

### RESTORE Mode
- restore skill, repair skill, recover skill, fix skill, upgrade skill, heal skill
- improve skill, low score, underperforming skill, broken skill, damaged skill

### TUNE Mode
- optimize skill, tune skill, autotune skill, boost skill, enhance skill
- improve score, skill target, skill score, rounds, autonomous, iteration, experiment

---

## Anti-Pattern Fix Table

| Anti-Pattern | Symptom | Fix |
|--------------|---------|-----|
| Missing System Prompt | No §1.1/§1.2/§1.3 | All three sections are mandatory — add before scoring anything else |
| Generic Content | "McKinsey report", "Forrester wave" | Replace with specific data, company names, benchmarks |
| Flat Structure | All content in SKILL.md | Move details to `references/`; keep SKILL.md as navigation |
| Wrong Tier | Lite skill at 600 lines | Match tier to actual scope — don't over-engineer |
| Thin Examples | 1–2 generic scenarios | Minimum 5 with realistic data and edge cases |
| Unvalidated Delivery | Shipped without evaluation | Always run dual-track check before delivery |
| High Variance | Text 9/10, Runtime 5/10 | Docs and runtime must agree — fix the weak track |
| Autotune Permission | "Should I continue?" | Never ask — always assume "yes" in TUNE mode |

---

## Technical Edge Cases

| Edge Case | Detection | Fix |
|-----------|-----------|-----|
| Empty Skill File | File exists but content < 50 chars | Reject: "Skill content empty or missing" |
| Circular Reference | Skill references itself in triggers | Reject: "Circular reference detected" |
| Version Mismatch | metadata.version not 2.2.0 | Run `validate.sh --migrate` or update version |
| Broken References | references/*.md missing | Create missing files or remove links |
| Hardcoded Secrets | API keys or tokens in content | Replace with `${ENV_VAR}` references |
| Path Traversal | `../` or `..\` in file paths | Reject paths with traversal sequences |
| Concurrent Tune | Two tune processes on same skill | Use file locking: `lsof .tune.lock` |
| Timeout Config | No timeout on external calls | Set default 30s, max 300s |

---

## Runtime-Specific Anti-Patterns

| Symptom | Runtime Detection | Fix |
|---------|-------------------|-----|
| Mode consistently misrouted | Wrong mode activated 40%+ | Refine first-verb matching rules |
| Output not actionable | No specific numbers/timeline | Add quantified next steps |
| Generic responses | No skill-specific data | Research before responding |
| Inconsistent character | Breaks after 3 turns | Add "stay in role" constraint |
| Vague handling | "Do the thing" → generic | Ask clarifying or assume EVALUATE |
