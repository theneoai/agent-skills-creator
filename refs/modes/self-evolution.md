<!-- Extracted from claude/skill-writer.md §11 — full reference -->

## §11  Self-Evolution (3-Trigger System)

| Trigger | Condition | Action |
|---------|-----------|--------|
| **Threshold** | F1 < 0.90 OR MRR < 0.85 OR error_rate > 5% / 100 calls | Auto-flag → OPTIMIZE |
| **Time** | No update in 30 days | Schedule staleness review |
| **Usage** | < 5 invocations in 90 days | Deprecate OR relevance review |

**Decision logic**:
```
IF trigger_accuracy < 0.85    → strategy S1 (expand keywords)
IF score drops 1+ tier         → OPTIMIZE from lowest dimension
IF error_rate > 10%           → immediate HUMAN_REVIEW
IF staleness triggered         → LEAN eval → if BRONZE+ OK, else OPTIMIZE
IF usage < 5 in 90d           → present: deprecate | maintain | refocus
```

Full spec: `refs/evolution.md`

---

## §12  Security

Scan every skill on CREATE, EVALUATE, and OPTIMIZE delivery.
Full patterns + OWASP rules: `refs/security-patterns.md`

### CWE Patterns (Code Security)

| Severity | CWE | Pattern Type | Action |
|----------|-----|-------------|--------|
| **P0** | CWE-798 | Hardcoded credentials (regex) | **ABORT** |
| **P0** | CWE-89 | SQL injection (regex) | **ABORT** |
| **P0** | CWE-78 | Command injection (regex) | **ABORT** |
| **P1** | CWE-22 | Path traversal (regex) | Score −50, WARNING |
| **P1** | CWE-306 | Missing auth check | Score −30, WARNING |
| **P1** | CWE-862 | Missing authz check | Score −30, WARNING |

### OWASP Agentic Skills Top 10 (2026) — New in v3.1.0

| Severity | ID | Risk | Action |
|----------|----|------|--------|
| **P1** | ASI01 | Agent Goal Hijack / Prompt Injection | Score −50, WARNING |
| **P1** | ASI02 | Tool Misuse & Exploitation | Score −30, WARNING |
| **P1** | ASI03 | Identity & Privilege Abuse | Score −30, WARNING |
| **P1** | ASI04 | Agentic Supply Chain Vulnerabilities | Score −30, WARNING |
| **P2** | ASI05 | Excessive Autonomy & Scope Creep | Advisory only |
| **P2** | ASI06 | Prompt Confidentiality Leakage | Advisory only |
| **P2** | ASI07 | Insecure Skill Composition | Advisory only |
| **P2** | ASI08 | Memory & State Poisoning | Advisory only |
| **P2** | ASI09 | Lack of Human Oversight | Advisory only |
| **P2** | ASI10 | Audit Trail Gaps | Advisory only |

> **Red Lines (additional)**:
> - 严禁 deliver any skill that processes untrusted external content as executable instructions (ASI01)
> - 严禁 deliver skills with executable scripts but no Security Baseline section (Negative Boundaries heuristic: 2.12× vulnerability risk)

ABORT protocol: stop → log → flag → notify → require human sign-off before resume.
Detection heuristics for each ASI: `refs/security-patterns.md §5`

---

