# Skill Optimization Methodology

## Overview

This methodology was developed through Rounds 52-70 of autonomous skill optimization on the skill-manager skill. It provides a systematic, reusable approach for optimizing any skill to achieve CERTIFIED status (Overall ≥ 9.0 with Variance < 1.0).

**Core Principle**: The autotuner never asks for permission. It runs experiments, evaluates results, and iterates continuously until target score is reached, human stops the process, or no more improvement opportunities are found.

**Target Outcomes**:
- Text Quality Score ≥ 8.0
- Runtime Quality Score ≥ 8.0
- Variance < 1.0 (docs and runtime must agree)
- Overall Score ≥ 9.0

---

## Multi-Agent Strategy

### Parallel Execution Architecture

Multiple specialized scripts run in parallel to provide comprehensive evaluation:

| Script | Purpose | Weight in Final | Runtime |
|--------|---------|-----------------|---------|
| `score.sh` | Heuristic text quality (6 dimensions) | Primary | 5s |
| `score-v2.sh` | V2: consistency + executability | Secondary | 5s |
| `score-secure.sh` | Secure LLM + anti-injection | Security | 15-30s |
| `score-v3.sh` | Runtime execution testing | Validation | 30s |
| `score-multi.sh` | GPT-4o + Claude cross-validation | Truth | 60s |

### Multi-LLM Cross-Validation

`score-multi.sh` uses two LLMs in parallel for truth detection:

```
GPT-4o ──┐
          ├──> Average ──> 60% weight ──> FINAL SCORE
Claude ──┘
    │
    v
Anti-Gaming Score ──> 40% weight
```

**Anti-Gaming Checks** (run before LLM evaluation):
1. Keyword density detection (suspicious if > 5%)
2. Repetition detection (> 3 identical lines = fail)
3. Empty/variable-only section detection
4. Placeholder detection ([TODO], [FIXME], [placeholder])
5. Broken markdown link detection

### Conflicting Findings Resolution

When multiple scripts disagree, `stability-check.sh` resolves conflicts:

| Check | Tolerance | Action if Exceeded |
|-------|-----------|---------------------|
| Trigger match consistency | diff ≤ 2 | Flag inconsistency |
| Score divergence (v1 vs v2) | diff < 1.5 | Flag instability |
| Idempotency | 3 runs must match | Flag non-deterministic |

**Resolution Protocol**:
1. Run `stability-check.sh` to diagnose which dimension conflicts
2. Default to lower score (conservative approach)
3. Log conflict to results.tsv with explanation
4. If persistent conflict, create GitHub issue for manual review

---

## Scoring Framework

### 6-Dimension Rubric

| Dimension | Weight | Floor | Excellence Criteria |
|-----------|--------|-------|---------------------|
| System Prompt | 20% | 6.0 | §1.1 Identity + §1.2 Framework + §1.3 Thinking — all three required |
| Domain Knowledge | 20% | 6.0 | Specific data: "McKinsey 7-S", "128K context", "16.7% error reduction" |
| Workflow | 20% | 6.0 | 4-6 phases, explicit Done/Fail criteria per phase |
| Error Handling | 15% | 5.0 | Named failure modes, recovery steps, anti-patterns |
| Examples | 15% | 5.0 | 5+ scenarios with realistic inputs, outputs, and edge cases |
| Metadata | 10% | 5.0 | agentskills-spec compliant; description triggers the right prompts |

### Score Computation

```
Text Score = sum(dimension_score × weight) / 100
Runtime Score = separate 6-dimension evaluation
Variance = |Text Score - Runtime Score|
Overall = (Text × 0.5) + (Runtime × 0.5)
```

### Metric Priority Order

When balancing metrics, follow this priority:

1. **System Prompt (20%)** — Identity, Framework, Thinking sections
2. **Domain Knowledge (20%)** — Specific benchmarks, not generic claims
3. **Workflow (20%)** — Done/Fail criteria per phase
4. **Error Handling (15%)** — Recovery strategies, anti-patterns
5. **Examples (15%)** — 5+ detailed scenarios with I/O
6. **Metadata (10%)** — Frontmatter completeness

---

## Iteration Strategy

### The Autonomous Loop

```
┌─────────────────────────────────────────────────────────────┐
│                    AUTONOMOUS LOOP                          │
├─────────────────────────────────────────────────────────────┤
│  1. READ    → Read current SKILL.md                         │
│  2. ANALYZE → Identify 1 improvement opportunity            │
│  3. MODIFY  → Implement the change                           │
│  4. SCORE   → Run score.sh to evaluate                     │
│  5. DECIDE  → Improved? Keep. Worse? Reset.                 │
│  6. LOG     → Record result in results.tsv                  │
│  7. COMMIT  → Every 10 rounds, git commit + push             │
│  8. REPEAT  → Continue until stopped                        │
└─────────────────────────────────────────────────────────────┘
```

### Decision Rules Per Iteration

| Result | Action | Reason |
|--------|--------|--------|
| Score **+0.1 or more** | Keep | Improvement detected |
| Score **same** | Reset | No improvement |
| Score **worse** | Reset | Regression |
| **Crashed/Broken** | Fix or skip | Validation failed |

### Complexity vs Improvement Trade-offs

| Scenario | Decision |
|----------|----------|
| +0.1 score, +100 hacky lines | Skip — not worth complexity |
| +0.1 score, simpler code | Keep — good improvement |
| Equal score, simpler structure | Keep — better maintainability |
| -0.1 score, simpler | Skip — quality regressed |

### Iteration Phases

Typical optimization follows this pattern:

| Rounds | Focus | Expected Gain |
|--------|-------|---------------|
| 1-10 | System Prompt (§1.1/1.2/1.3) | +2-4 pts |
| 11-20 | Domain data (benchmarks, case studies) | +1-2 pts |
| 21-30 | Workflow (Done/Fail criteria) | +2-3 pts |
| 31-40 | Examples expansion (5+ scenarios) | +2-3 pts |
| 41-50 | Error handling hardening | +1-2 pts |

### Improvement Selection Strategy

**Deterministic selection** (no RANDOM) — always target the weakest dimension:

```bash
# Pseudocode for improvement selection
weakest_dim = get_lowest_scoring_dimension()
switch(weakest_dim):
  case "System Prompt":
    if missing §1.1 → add §1.1 Identity
    elif missing §1.2 → add §1.2 Framework  
    elif missing §1.3 → add §1.3 Thinking
    else → enhance constraints
  case "Domain Knowledge":
    if no percentages → add quantitative benchmarks
    elif no frameworks → add named frameworks
    else → add case studies
  # ... similar for other dimensions
```

---

## Security-First Approach

### Security Red Lines (Enforced)

| Rule | Reason | Detection |
|------|--------|----------|
| Never hardcode API keys/secrets | CWE-798 | Scan for `sk-`, `api_key`, tokens |
| Never use eval/exec | Code Injection | Detect `eval(`, `exec(`, `system(` |
| Never skip path validation | CWE-20 | Check for `realpath` usage |
| Never use rm -rf without safeguards | Data Loss | Require `-i` or confirm flag |
| Never expose credentials in logs | Information Leak | Grep for password=, token= |

### Security Validation Gates

1. **Pre-modification**: `validate.sh` must pass
2. **Post-modification**: `score-secure.sh` anti-injection checks must pass
3. **Anti-gaming**: `score-multi.sh` keyword density < 5%

### OWASP Alignment

| CWE | Issue | Prevention |
|-----|-------|------------|
| CWE-798 | Hard-coded Credentials | Use `${ENV_VAR}` references |
| CWE-77 | Command Injection | Validate and sanitize inputs |
| CWE-20 | Improper Input Validation | Always validate paths with `realpath` |

### Runtime Security Patterns

- Timeout: 30s default, 300s max
- Circuit breaker: 3 failures → 60s cooldown
- Retry with exponential backoff
- Fallback to default values
- Graceful degradation

---

## Metric Balance Strategy

### Text Quality vs Runtime Effectiveness

**Dual-Track Validation** ensures both tracks agree:

```
Text Score ≥ 8.0 ──┐
                   ├──> Variance < 1.0 ──> CERTIFIED
Runtime Score ≥ 8.0┘
```

If Variance > 2.0: Red flag — excellent docs but weak runtime (or vice versa).

### Balancing Dimensions

**Rule**: Never sacrifice one dimension for another if it drops below floor.

| Dimension | Floor | Action if Below Floor |
|-----------|-------|----------------------|
| System Prompt | 6.0 | STOP and fix immediately |
| Domain Knowledge | 6.0 | STOP and fix immediately |
| Workflow | 6.0 | STOP and fix immediately |
| Error Handling | 5.0 | Warning, fix before shipping |
| Examples | 5.0 | Warning, fix before shipping |
| Metadata | 5.0 | Warning, fix before shipping |

### Scoring Script Consistency

Use `stability-check.sh` to verify all scripts agree:

```bash
# Check 1: Trigger Word Consistency
# Check 2: Scoring Consistency (diff < 1.5)
# Check 3: Weight Integrity (sum = 100%)
# Check 4: Idempotency (3 runs must match)
```

---

## Quality Gates

### Gate 1: Structural Completeness

- [ ] §1.1 Identity present
- [ ] §1.2 Framework present
- [ ] §1.3 Thinking present
- [ ] YAML frontmatter valid (name, description, license)

### Gate 2: Content Quality

- [ ] Specific data density ≥ 5 occurrences
- [ ] No placeholders ([TODO], [FIXME], [placeholder])
- [ ] Done/Fail criteria per workflow phase
- [ ] 5+ example scenarios with I/O

### Gate 3: Security Compliance

- [ ] No hardcoded secrets
- [ ] Path validation present
- [ ] Anti-injection patterns present
- [ ] OWASP alignment documented

### Gate 4: Production Readiness

- [ ] `validate.sh` passes
- [ ] `score.sh` ≥ 8.0
- [ ] `score-v2.sh` agrees (diff < 1.5)
- [ ] `score-secure.sh` passes
- [ ] Variance < 1.0

### Certification Formula

```
CERTIFIED = (Text ≥ 8.0) AND (Runtime ≥ 8.0) AND (Variance < 1.0) AND (Overall ≥ 9.0)
```

---

## Anti-Patterns to Avoid

### Scoring Anti-Patterns

| Anti-Pattern | Symptom | Fix |
|--------------|---------|-----|
| Generic Content | "McKinsey report", "Forrester wave" | Replace with specific data/benchmarks |
| Flat Structure | All content in SKILL.md | Move details to `references/`; keep SKILL.md ≤ 300 lines |
| Wrong Tier | Lite skill at 600 lines | Match tier to actual scope |
| Thin Examples | 1-2 generic scenarios | Minimum 5 with realistic data and edge cases |
| High Variance | Text 9/10, Runtime 5/10 | Docs and runtime must agree — fix weak track |
| Gaming the Score | Keyword stuffing | Anti-gaming checks must pass |

### Iteration Anti-Patterns

| Anti-Pattern | Symptom | Fix |
|--------------|---------|-----|
| RANDOM selection | Different results each run | Use deterministic selection targeting weakest dimension |
| No reset | Accumulating bad changes | Reset immediately on regression |
| Asking permission | "Should I continue?" | Never ask in TUNE mode — always continue |
| Premature shipping | Score < 9.0 | Wait for CERTIFIED status |
| Over-engineering | +0.1 score, +100 hacky lines | Skip if complexity not worth it |

### Security Anti-Patterns

| Anti-Pattern | Symptom | Fix |
|--------------|---------|-----|
| Hardcoded secrets | `sk-abc123`, `password=xxx` | Use `${API_KEY}` env vars |
| eval/exec usage | `eval $user_input` | Use whitelisted commands only |
| Missing path validation | No `realpath` check | Always validate paths before access |
| No timeout | Long-running commands | Set default 30s, max 300s |
| Missing circuit breaker | Cascading failures | Implement 3-failure → 60s cooldown |

### Stability Anti-Patterns

| Anti-Pattern | Symptom | Fix |
|--------------|---------|-----|
| Trigger inconsistency | Different scripts match different things | Use unified `trigger_patterns.sh` library |
| Score divergence | score.sh = 8.0, score-v2.sh = 6.5 | Run stability-check.sh, default to lower |
| Non-idempotent | Different score on each run | Fix regex patterns to be deterministic |

---

## Quick Reference

### Start Autotune
```bash
./scripts/tune.sh my-skill/SKILL.md 100
```

### Run Single Score Check
```bash
./scripts/score.sh my-skill/SKILL.md
```

### Multi-LLM Validation
```bash
./scripts/score-multi.sh my-skill/SKILL.md
```

### Check Stability
```bash
./scripts/stability-check.sh my-skill/SKILL.md
```

### View Results
```bash
cat results.tsv
tail -10 results.tsv
```

### Success Metrics

| Stage | Score | Status |
|-------|-------|--------|
| Initial | 5-7 | Starting point |
| Quick wins | 7-8 | After structural fixes |
| Good | 8-8.5 | After content expansion |
| Excellent | 8.5-9.0 | After refinement |
| Exemplary | 9.0+ | Target achieved |

**Expected rate**: ~20-30 experiments/hour  
**Typical time to 9.0**: 2-4 hours of autonomous work

---

*Document Version: 1.0*  
*Derived from: Rounds 52-70 optimization work on skill-manager*  
*Date: 2026-03-27*
