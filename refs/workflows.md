# Workflows Reference

> **Purpose**: Detailed workflow specifications for each mode
> **Load**: When §3 Process section is accessed
> **Patterns**: Tool Wrapper + Generator + Inversion + Pipeline

---

## Mode: CREATE (Generator + Inversion)

### Purpose
Generate a new SKILL.md using template-based generation with structured requirement gathering

### Pattern: Inversion (Gather Requirements First)

**GATE: Do NOT start generating until ALL questions answered**

```
## Phase 1 — Problem Discovery (一次问一个问题，等回答)

Q1: "这个Skill为用户解决什么问题？"
   → Wait for answer before Q2

Q2: "主要用户是谁？他们的技术水平如何？"
   → Wait for answer before Q3

Q3: "预期规模是多少？（简单/中等/复杂）"
   → Wait for answer before synthesis

## Phase 2 — Technical Constraints (Phase 1 全部回答完之后)

Q4: "你有什么技术栈要求或偏好？"
   → Wait for answer before Q5

Q5: "有哪些不可妥协的要求？（质量/速度/安全性）"
   → Wait for answer before synthesis
```

### Pattern: Generator (Template-Based Output)

```
## Phase 3 — Synthesis (所有问题都回答完之后)

1. LOAD: 'reference/workflows.md' for skill template structure
2. LOAD: 'reference/tools.md' for tool categories
3. GENERATE: Fill template with collected requirements
4. VERIFY: Check all required sections present
5. PRESENT: Show generated skill structure
6. CONFIRM: "这个结构符合你的需求吗？"
```

### Workflow

```
1. ASK requirements (Inversion)
2. LOAD templates (Tool Wrapper)
3. GENERATE skill structure (Generator)
4. CROSS-VALIDATE (Multi-LLM)
5. VERIFY with lean-orchestrator
6. PRESENT result
```

### Exit Criteria
- SKILL.md created at output_path
- Score ≥ 420 (BRONZE minimum)

---

## Mode: LEAN (Fast Path)

### Purpose
Lean, fast, cost-effective skill evaluation (~1 second)

### Design Principles
- Fast Path: Parse + Heuristic scoring (no LLM)
- LLM on-demand: Multi-LLM only for critical decisions
- Parallel Execution: Independent dimensions run in parallel
- Incremental: Only fix what needs fixing

### Workflow (~1 second)

```
1. FAST_PARSE: YAML, §1.x sections, triggers (heuristic, no LLM)
2. TEXT_SCORE: §1.x quality, domain knowledge, workflow (heuristic, no LLM)
3. RUNTIME_TEST: §2 trigger patterns, mode definitions (no LLM)
4. DECIDE: Compare to threshold
5. ITERATE (if needed): Fast LLM fix for specific issues
6. CERTIFY: Tier determination
```

### Fast Path Thresholds (500-point scale)

| Tier | Parse | Text | Runtime | Total |
|------|-------|------|---------|-------|
| GOLD | 80+ | 280+ | 40+ | 475+ (95%) |
| SILVER | 70+ | 245+ | 35+ | 425+ (85%) |
| BRONZE | 60+ | 210+ | 30+ | 350+ (70%) |

### When to Escalate to Full Eval
- Score near threshold boundary
- High disagreement between heuristics
- Production deployment required
- User explicitly requests full eval

---

## Mode: EVALUATE

### Purpose
Score an existing skill with comprehensive metrics

### Workflow (Multi-LLM)

```
1. ASK: "Path to skill file?"
   → Validate: file exists, readable

2. DELIBERATE: Multiple LLMs analyze independently
   - Parse structure
   - Evaluate text quality
   - Test runtime behavior
   - Assess certification readiness

3. CROSS-VALIDATE: Compare evaluation results
   - Resolve scoring conflicts
   - Calculate confidence interval
   - Flag low-agreement areas

4. EXECUTE: engine/agents/evaluator.sh "$skill_file"

5. COMPUTE METRICS:
   - F1 Score (trigger accuracy)
   - MRR (mean reciprocal rank)
   - Text Score (6 dimensions)
   - Runtime Score
   - Variance Score

6. PRESENT:
   - Score (0-1000)
   - Tier (GOLD/SILVER/BRONZE/FAIL)
   - F1, MRR metrics
   - 3-5 actionable suggestions
   - Confidence level

7. OFFER: "Would you like to optimize/restore/secure this skill?"
```

### Exit Criteria
- Score calculated with F1 ≥ 0.90, MRR ≥ 0.85
- Suggestions generated with multi-LLM consensus
- Confidence level ≥ 0.8

---

## Mode: RESTORE

### Purpose
Fix/repair broken or degraded skills

### Workflow (Multi-LLM)

```
1. ASK: "Path to skill file to restore?"
   → Validate: file exists

2. ANALYZE (Multi-LLM):
   - LLM-1: Identifies parse errors
   - LLM-2: Identifies semantic issues
   - LLM-3: Identifies missing sections
   - Cross-validate findings

3. DIAGNOSE:
   - Parse validation failures
   - Score regression causes
   - Missing critical sections
   - Security vulnerabilities

4. PROPOSE FIXES:
   - Each LLM proposes remediation approach
   - Cross-validate proposed fixes
   - Select best approach by consensus

5. IMPLEMENT: Apply fixes with multi-LLM verification

6. VERIFY: Re-evaluate restored skill
   - Score should improve ≥ 0.5
   - All critical issues resolved

7. PRESENT:
   - Issues found and fixed
   - Score delta (old → new)
   - Remaining warnings
```

### Exit Criteria
- All critical issues resolved
- Score improved ≥ 0.5
- Multi-LLM consensus on restoration

---

## Mode: SECURITY

### Purpose
OWASP AST10 security audit with multi-LLM cross-validation

### Workflow (Multi-LLM)

```
1. ASK: "Path to skill file for security audit?"
   → Validate: file exists

2. ASK: "Audit level (BASIC/FULL)?"
   → Capture: audit_level (default: FULL)

3. OWASP AST10 CHECKLIST (Multi-LLM):

   A. Credential Scan (Multi-LLM):
      - LLM-1: Scan for passwords/secrets
      - LLM-2: Scan for API keys/tokens
      - Cross-validate findings

   B. Input Validation (Multi-LLM):
      - Check YAML frontmatter parsing
      - Verify path handling safety
      - Check injection vectors

   C. Path Traversal (Multi-LLM):
      - LLM-1: Check realpath usage
      - LLM-2: Check file access patterns
      - Cross-validate no traversal

   D. Trigger Sanitization (Multi-LLM):
      - Verify trigger regex validation
      - Check alphanumeric-only enforcement

   E. YAML Parsing Safety
   F. Command Injection Prevention
   G. SQL Injection Prevention
   H. Data Exposure Prevention
   I. Log Security
   J. Error Handling Security

4. CROSS-VALIDATE: All LLMs review findings
   - Resolve conflicts
   - Calculate confidence
   - Flag P0/P1/P2 issues

5. PRESENT:
   - Checklist results (10 items)
   - P0/P1/P2 violations
   - Fix suggestions per violation
   - Overall security tier
```

### Exit Criteria
- All 10 OWASP AST10 items checked
- P0 violations = FAIL
- P1/P2 violations documented with fixes

---

## Mode: OPTIMIZE (Self-Evolution)

### Purpose
9-step optimization loop with multi-LLM deliberation

### 9-Step Workflow

```
═════════════════════════════════════════════════════════════
                    STEP 1: READ (Multi-LLM)
═════════════════════════════════════════════════════════════
1. LOCATE: Find weakest dimension across 7 dimensions
   - System Prompt (20%)
   - Domain Knowledge (20%)
   - Workflow (20%)
   - Error Handling (15%)
   - Examples (15%)
   - Metadata (10%)
   - Long-Context (10%)

2. MULTI-LLM ANALYSIS:
   - Each LLM independently scores each dimension
   - Cross-validate to find true weakest
   - Calculate confidence interval

3. OUTPUT: Weakest dimension + justification

═════════════════════════════════════════════════════════════
                    STEP 2: ANALYZE
═════════════════════════════════════════════════════════════
1. PRIORITIZE: Select improvement strategy
   - Dimensions with score < 6.0 prioritized
   - High-weight dimensions prioritized
   - Tie-breaking by rotation

2. MULTI-LLM DELIBERATION:
   - LLM-1: Proposes targeted fix
   - LLM-2: Proposes alternative fix
   - LLM-3: Proposes third option

3. CROSS-VALIDATE: Select optimal strategy

═════════════════════════════════════════════════════════════
                STEP 3: CURATION (Every 10 Rounds)
═════════════════════════════════════════════════════════════
1. CONSOLIDATE: Review optimization knowledge
   - Remove redundant improvements
   - Preserve essential insights
   - Clean semantic foundation

2. MULTI-LLM REVIEW:
   - Prevent context collapse
   - Maintain optimization momentum

═════════════════════════════════════════════════════════════
                    STEP 4: PLAN
═════════════════════════════════════════════════════════════
1. SELECT: Improvement strategy by dimension
   - System → Rewrite §1.x sections
   - Domain → Add specific data/benchmarks
   - Workflow → Enhance process sections
   - Error → Add failure modes
   - Examples → Add diverse scenarios
   - Metadata → Fix frontmatter
   - LongContext → Add chunking strategy

2. MULTI-LLM VALIDATION: Confirm strategy

═════════════════════════════════════════════════════════════
                STEP 5: IMPLEMENT (Multi-LLM)
═════════════════════════════════════════════════════════════
1. APPLY: Atomic change to skill file

2. MULTI-LLM VERIFICATION:
   - LLM-1: Verifies change applied correctly
   - LLM-2: Checks for regressions
   - LLM-3: Validates syntax

═════════════════════════════════════════════════════════════
                STEP 6: VERIFY (Multi-LLM)
═════════════════════════════════════════════════════════════
1. RE-EVALUATE: Score new version

2. CROSS-VALIDATE:
   - Score improved? → Continue
   - Score regression? → Rollback
   - Low confidence? → HUMAN_REVIEW

═════════════════════════════════════════════════════════════
            STEP 7: HUMAN_REVIEW (If score < 8.0 after 10 rounds)
═════════════════════════════════════════════════════════════
1. TRIGGER: Automatic when score < 8.0 after 10 rounds

2. REQUEST: Expert human review

3. PRESENT: Current state + recommendations

4. RECEIVE: Human feedback

5. INTEGRATE: Apply human suggestions

═════════════════════════════════════════════════════════════
                    STEP 8: LOG
═════════════════════════════════════════════════════════════
1. RECORD: To results.tsv
   - Round number
   - Dimension improved
   - Score delta
   - Confidence level

═════════════════════════════════════════════════════════════
                STEP 9: COMMIT (Every 10 Rounds)
═════════════════════════════════════════════════════════════
1. GIT: Automatic commit

2. MESSAGE: "Optimize: Round N, Delta X"

═════════════════════════════════════════════════════════════
                    EXIT CRITERIA
═════════════════════════════════════════════════════════════
- Delta > 0 in results.tsv
- Score ≥ target tier
- Or: Stuck > 20 rounds → Stop and report
```

---

## Usage

This file is loaded when §3 Workflow section is accessed in SKILL.md.
Load with: `source reference/workflows.md` or include via Markdown reference.
