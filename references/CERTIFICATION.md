# Certification System

> 4-Tier Certification Model for Agent Skills

---

## Certification Tiers

| Tier | Text Score | Runtime Score | Variance Threshold |
|------|------------|--------------|-------------------|
| **PLATINUM** | ≥ 9.5 | ≥ 9.5 | < 1.0 |
| **GOLD** | ≥ 9.0 | ≥ 9.0 | < 1.5 |
| **SILVER** | ≥ 8.0 | ≥ 8.0 | < 2.0 |
| **BRONZE** | ≥ 7.0 | ≥ 7.0 | < 3.0 |

---

## Certification Formula

```
Text Score ≥ 8.0 AND Runtime Score ≥ 8.0 AND Variance < 2.0 = CERTIFIED
```

**Variance** = |Text Score - Runtime Score|

---

## Certification Process

1. **Parse & Validate** (100pts)
   - YAML frontmatter completeness
   - §1.1/§1.2/§1.3 structure presence
   - Trigger list coverage
   - No placeholder content

2. **Text Score** (350pts)
   - System Prompt (70pts)
   - Domain Knowledge (70pts)
   - Workflow (70pts)
   - Error Handling (55pts)
   - Examples (55pts)
   - Metadata (30pts)

3. **Runtime Score** (450pts)
   - Identity Consistency (80pts)
   - Framework Execution (70pts)
   - Output Actionability (70pts)
   - Knowledge Accuracy (50pts)
   - Conversation Stability (50pts)
   - Trace Compliance (50pts)
   - Long-Document Handling (30pts)
   - Multi-Agent Coordination (25pts)
   - Trigger Accuracy (25pts)

4. **Certification** (100pts)
   - Variance Control (40pts)
   - Tier Determination (30pts)
   - Report Completeness (20pts)
   - Security Gates (10pts)

---

## Security Gates (P0)

Must pass all security checks before certification:

| Check | CWE | Requirement |
|-------|-----|-------------|
| No hardcoded credentials | CWE-798 | API keys, passwords must not be in source |
| No SQL injection | CWE-89 | Parameterized queries only |
| No command injection | CWE-78 | No eval/exec with user input |
| No path traversal | CWE-22 | Use realpath validation |
| No sensitive data in logs | CWE-200 | Redact credentials in output |

---

## Variance Thresholds

| Variance Range | Score | Interpretation |
|---------------|-------|----------------|
| < 30 | 40/40 | Excellent - Text and Runtime aligned |
| < 50 | 30/40 | Good - Minor variance |
| < 70 | 20/40 | Acceptable - Moderate variance |
| < 100 | 10/40 | Poor - Significant variance |
| < 150 | 5/40 | Borderline - High variance |
| ≥ 150 | 0/40 | Unacceptable - Serious mismatch |

---

## Tier Progression

```
NOT CERTIFIED → BRONZE → SILVER → GOLD → PLATINUM
                    ↑
              Target tier for new skills
```

**Recommendation**: Target BRONZE for new skills, aim for SILVER/GOLD through optimization.
