# Improvements Reference

> High-impact experiments and optimization strategies. See [SKILL.md §10](../SKILL.md#-10--high-impact-improvements) for priority summary.

---

## High-Impact Experiments

| Idea | Why |
|------|-----|
| Add missing §1.1/1.2/1.3 | System Prompt is 20% weight — e.g., add "Constraints: Never modify §1 frontmatter" |
| Replace generic stakeholder analysis with "RACI matrix" | Domain Knowledge is 20% weight |
| Add "DONE: score ≥ 8.0; FAIL: score < 8.0 or variance > 2.0" | Workflow is 20% weight |
| Expand 2 generic scenarios → 5 with real input/output pairs | Examples are 15% weight |
| Add "Timeout → retry 3× then escalate" | Error Handling is 15% weight |
| Add "McKinsey 7-S framework for organizational analysis" | Domain Knowledge bonus |
| Add "IF timeout THEN retry ELSE continue" decision tree | Workflow bonus |
| Add "Empty input → return {} not error" edge case | Error Handling bonus |

---

## Optimization Strategy

1. **First pass**: Add §1.1 Identity + §1.2 Framework + §1.3 Thinking constraints
2. **Second pass**: Add "128K token context", "16.7% error reduction" benchmarks
3. **Third pass**: Expand 2→5 examples with input/output/verification
4. **Fourth pass**: Align section numbering, fix broken links

---

## Priority Fixes by Dimension

### System Prompt (20% weight)
- Missing §1.1 Identity → Add role, mission, activation keywords
- Missing §1.2 Framework → Add 3-5 core principles
- Missing §1.3 Thinking → Add decision rules, examples of good/bad

### Domain Knowledge (20% weight)
- Generic "stakeholder analysis" → Specific "RACI matrix"
- Generic "industry standards" → Specific "NIST CSF", "OWASP Top 10"
- Add quantified benchmarks: "16.7% error reduction", "128K context"

### Workflow (20% weight)
- No phases → 4-6 phases with names
- No criteria → Add DONE/FAIL per phase
- No escalation → Add "if X then Y" decision tree

### Error Handling (15% weight)
- No error section → Add named failure modes
- No recovery → Add "retry 3× then escalate"
- No anti-patterns → Document what NOT to do

### Examples (15% weight)
- < 5 scenarios → Expand to 5+ with realistic I/O
- Generic inputs → Specific URLs, codes, queries
- No edge cases → Add empty input, invalid input, boundary cases

### Metadata (10% weight)
- Missing frontmatter → Add name, description, license, metadata
- Generic description → Include trigger keywords
- Wrong version → Update to 2.2.0
