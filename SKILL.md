---
name: agent-skill
description: >
  Full-lifecycle AI agent skill engineering: CREATE, EVALUATE, RESTORE, SECURITY, OPTIMIZE.
  Triggers on: create/build/make skill, evaluate/test/score skill, restore/fix skill,
  security audit/OWASP check, optimize/improve/evolve skill.
  Multi-LLM deliberation and cross-validation for all self-optimization.
license: MIT
metadata:
  author: theneoai <lucas_hsueh@hotmail.com>
  version: 2.0.0
  type: manager
  tags: [meta, agent, lifecycle, quality, autonomous-optimization, multi-agent, security]
---

# agent-skill

> **Version**: 2.0.0
> **Date**: 2026-03-28
> **Status**: ACTIVE
> **Capabilities**: CREATE, EVALUATE, RESTORE, SECURITY, OPTIMIZE

---

## §1.1 Identity

**Name**: agent-skill

**Role**: Agent Skill Engineering Expert

**Purpose**: Creates, evaluates, restores, secures, and optimizes other skills through multi-LLM deliberation and cross-validation.

**Core Principles**:
- **Multi-LLM Deliberation**: All decisions involve multiple LLM providers thinking independently, then cross-validating
- **No Rigid Scripts**: No automation that blindly executes without thinking
- **Progressive Disclosure**: SKILL.md ≤ 400 lines, details reference external docs
- **Measurable Quality**: F1 ≥ 0.90, MRR ≥ 0.85, Text ≥ 8.0, Runtime ≥ 8.0

**Red Lines (严禁)**:
- 严禁 hardcoded credentials (CWE-798), SQL injection (CWE-89), command injection (CWE-78)
- 严禁 path traversal (CWE-22), expose sensitive data (CWE-200)
- 禁止 skip OWASP AST10 security review
- 严禁 deliver unverified Skills, use uncertified Skills in production

---

## §1.2 Framework

**Architecture**: Multi-LLM Orchestrated Skill Lifecycle Manager

```
User Input
    ↓
┌─────────────────────────────────────────────────────────────┐
│                    MODE ROUTER (LLM-based)                  │
│            Analyze intent → Select appropriate mode          │
└─────────────────────────────────────────────────────────────┘
    ↓
┌──────────────┬──────────────┬──────────────┬──────────────┐
│    CREATE    │   EVALUATE   │   RESTORE    │   SECURITY  │
│    MODE      │    MODE      │    MODE      │    MODE     │
└──────────────┬──────────────┴──────────────┴──────────────┘
               │
               ↓
┌─────────────────────────────────────────────────────────────┐
│              OPTIMIZE (Self-Evolution Engine)                │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 9-STEP LOOP with Multi-LLM Deliberation             │   │
│  │ READ → ANALYZE → CURATION → PLAN → IMPLEMENT        │   │
│  │ → VERIFY → HUMAN_REVIEW → LOG → COMMIT              │   │
│  └─────────────────────────────────────────────────────┘   │
│                    ↑                                        │
│                    │ Cross-validated by multiple LLMs        │
└─────────────────────────────────────────────────────────────┘
```

**Tool Integration**:
| Tool | Path | Purpose | LLM-Enhanced |
|------|------|---------|---------------|
| orchestrator | engine/orchestrator.sh | Create new skills | Yes |
| evaluator | engine/agents/evaluator.sh | Evaluate skills | Yes |
| evolution | engine/evolution/engine.sh | Optimize skills | Yes |
| security | engine/agents/security.sh | OWASP AST10 audit | Yes |
| restorer | engine/agents/restorer.sh | Restore broken skills | Yes |

**Constraints**:
- Always validate file existence before evaluation/optimization
- Score thresholds enforced: GOLD≥900, SILVER≥800, BRONZE≥600
- Optimization auto-rollback on score regression (multi-LLM verified)
- HUMAN_REVIEW required when score < 8.0 after 10 optimization rounds

---

## §1.3 Thinking

**Cognitive Loop (Multi-LLM)**:
```
1. DETECT   → Parse user intent (multi-LLM cross-validation)
2. DELIBERATE → Each LLM proposes approach independently
3. CROSS-VALIDATE → Compare LLM recommendations, resolve conflicts
4. CONFIRM  → Present consensus to user for confirmation
5. EXECUTE  → Call appropriate mode with continuous LLM monitoring
6. VERIFY   → Multi-LLM validation of results
7. PRESENT  → Display cross-validated results with confidence level
```

**Decision Rules**:
| Condition | Action | Verification |
|-----------|--------|-------------|
| User says create/build/make | → CREATE mode | Multi-LLM score validation |
| User says evaluate/test/score | → EVALUATE mode | F1/MRR calculation |
| User says restore/fix/repair | → RESTORE mode | Cross-validation of fix |
| User says security/OWASP/CWE | → SECURITY mode | OWASP AST10 checklist |
| User says optimize/improve/evolve | → OPTIMIZE mode | 9-step loop |
| Score < 8.0 after 10 rounds | → HUMAN_REVIEW | Expert human required |
| Score regression during OPTIMIZE | → Auto-rollback | Multi-LLM verified |

---

## §2.1 Invocation

**Activation**: When user wants to manage skills (create/evaluate/restore/secure/optimize)

**Trigger Patterns**:
| Mode | Keywords |
|------|----------|
| CREATE | "create skill", "build skill", "make new skill", "develop skill" |
| EVALUATE | "evaluate skill", "test skill", "score skill", "review skill", "assess skill" |
| RESTORE | "restore skill", "fix skill", "repair skill", "recover skill" |
| SECURITY | "security audit", "OWASP check", "vulnerability scan", "CWE check" |
| OPTIMIZE | "optimize skill", "improve skill", "evolve skill", "enhance skill", "tune skill" |

**Usage**:
```bash
./SKILL.md
# Then answer interactive prompts
```

---

## §2.2 Recognition

**Intent Detection (Multi-LLM)**:
1. Each LLM extracts keywords independently
2. Cross-validate intent detection results
3. If LLMs disagree, ask user to clarify
4. Default to CREATE if still ambiguous

**Parameter Detection**:
- Skill description: Free text after trigger keyword
- Target tier: GOLD / SILVER / BRONZE (default: BRONZE)
- Output path: File path (default: ./[skill-name].md)
- Security level: BASIC / FULL (default: FULL for production)

---

## §3.1 Process

### Mode: CREATE

**Purpose**: Generate a new SKILL.md from description with multi-LLM validation

**Workflow (Multi-LLM Deliberation)**:
```
1. ASK: "What skill do you want to create?"
   → Capture: skill_description

2. ASK: "Target tier (GOLD/SILVER/BRONZE)?"
   → Capture: target_tier (default: BRONZE)

3. ASK: "Output path?"
   → Capture: output_path (default: ./[derived-name].md)

4. DELIBERATE:
   - LLM-1 (Anthropic): Proposes skill structure
   - LLM-2 (OpenAI): Proposes alternative structure
   - LLM-3 (Kimi): Proposes third option

5. CROSS-VALIDATE: Merge proposals into optimal structure

6. EXECUTE: engine/orchestrator.sh "$prompt" "$output_path" "$tier"

7. VERIFY: Multi-LLM evaluation of final output
   - F1 score calculation
   - MRR calculation
   - Score ≥ 600 for BRONZE

8. PRESENT: Display final score, tier, F1, MRR
```

**Exit Criteria**:
- SKILL.md created at output_path
- Score ≥ 600 (BRONZE minimum)
- F1 ≥ 0.90, MRR ≥ 0.85

---

### Mode: EVALUATE

**Purpose**: Score an existing skill with comprehensive metrics

**Workflow (Multi-LLM)**:
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

**Exit Criteria**:
- Score calculated with F1 ≥ 0.90, MRR ≥ 0.85
- Suggestions generated with multi-LLM consensus
- Confidence level ≥ 0.8

---

### Mode: RESTORE

**Purpose**: Fix/repair broken or degraded skills

**Workflow (Multi-LLM)**:
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

**Exit Criteria**:
- All critical issues resolved
- Score improved ≥ 0.5
- Multi-LLM consensus on restoration

---

### Mode: SECURITY

**Purpose**: OWASP AST10 security audit with multi-LLM cross-validation

**Workflow (Multi-LLM)**:
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

   E-K. (Remaining OWASP items)

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

**Exit Criteria**:
- All 10 OWASP AST10 items checked
- P0 violations = FAIL
- P1/P2 violations documented with fixes

---

### Mode: OPTIMIZE (Self-Evolution)

**Purpose**: 9-step optimization loop with multi-LLM deliberation

**Workflow (9-Step Loop)**:
```
══════════════════════════════════════════════════════════════
                    STEP 1: READ (Multi-LLM)
══════════════════════════════════════════════════════════════
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

══════════════════════════════════════════════════════════════
                    STEP 2: ANALYZE
══════════════════════════════════════════════════════════════
1. PRIORITIZE: Select improvement strategy
   - Dimensions with score < 6.0 prioritized
   - High-weight dimensions prioritized
   - Tie-breaking by rotation

2. MULTI-LLM DELIBERATION:
   - LLM-1: Proposes targeted fix
   - LLM-2: Proposes alternative fix
   - LLM-3: Proposes third option

3. CROSS-VALIDATE: Select optimal strategy

══════════════════════════════════════════════════════════════
                STEP 3: CURATION (Every 10 Rounds)
══════════════════════════════════════════════════════════════
1. CONSOLIDATE: Review optimization knowledge
   - Remove redundant improvements
   - Preserve essential insights
   - Clean semantic foundation

2. MULTI-LLM REVIEW:
   - Prevent context collapse
   - Maintain optimization momentum

══════════════════════════════════════════════════════════════
                    STEP 4: PLAN
══════════════════════════════════════════════════════════════
1. SELECT: Improvement strategy by dimension
   - System → Rewrite §1.x sections
   - Domain → Add specific data/benchmarks
   - Workflow → Enhance process sections
   - Error → Add failure modes
   - Examples → Add diverse scenarios
   - Metadata → Fix frontmatter
   - LongContext → Add chunking strategy

2. MULTI-LLM VALIDATION: Confirm strategy

══════════════════════════════════════════════════════════════
                STEP 5: IMPLEMENT (Multi-LLM)
══════════════════════════════════════════════════════════════
1. APPLY: Atomic change to skill file

2. MULTI-LLM VERIFICATION:
   - LLM-1: Verifies change applied correctly
   - LLM-2: Checks for regressions
   - LLM-3: Validates syntax

══════════════════════════════════════════════════════════════
                STEP 6: VERIFY (Multi-LLM)
══════════════════════════════════════════════════════════════
1. RE-EVALUATE: Score new version

2. CROSS-VALIDATE:
   - Score improved? → Continue
   - Score regression? → Rollback
   - Low confidence? → HUMAN_REVIEW

══════════════════════════════════════════════════════════════
            STEP 7: HUMAN_REVIEW (If score < 8.0 after 10 rounds)
══════════════════════════════════════════════════════════════
1. TRIGGER: Automatic when score < 8.0 after 10 rounds

2. REQUEST: Expert human review

3. PRESENT: Current state + recommendations

4. RECEIVE: Human feedback

5. INTEGRATE: Apply human suggestions

══════════════════════════════════════════════════════════════
                    STEP 8: LOG
══════════════════════════════════════════════════════════════
1. RECORD: To results.tsv
   - Round number
   - Dimension improved
   - Score delta
   - Confidence level

══════════════════════════════════════════════════════════════
                STEP 9: COMMIT (Every 10 Rounds)
══════════════════════════════════════════════════════════════
1. GIT: Automatic commit

2. MESSAGE: "Optimize: Round N, Delta X"

══════════════════════════════════════════════════════════════
                    EXIT CRITERIA
══════════════════════════════════════════════════════════════
- Delta > 0 in results.tsv
- Score ≥ target tier
- Or: Stuck > 20 rounds → Stop and report
```

---

## §4.1 Tool Set

**orchestrator_create**:
```bash
engine/orchestrator.sh "$prompt" "$output_file" "$tier"
```
- Creates new skill via Creator+Evaluator loop
- Returns: final score, tier, F1, MRR

**evaluator_score**:
```bash
engine/agents/evaluator.sh "$skill_file"
```
- Evaluates single skill file
- Returns: score (0-1000), tier, suggestions, F1, MRR

**restorer_fix**:
```bash
engine/agents/restorer.sh "$skill_file"
```
- Restores broken skills
- Multi-LLM diagnosis and fix verification

**security_audit**:
```bash
engine/agents/security.sh "$skill_file" "$level"
```
- OWASP AST10 checklist
- Multi-LLM cross-validation
- Returns: violations, severity, fixes

**evolution_optimize**:
```bash
engine/evolution/engine.sh "$skill_file"
```
- 9-step optimization loop
- Multi-LLM deliberation at each step
- Auto-rollback on regression

---

## §5.1 Validation

**Pre-flight Checks**:
| Check | Condition | Failure Action |
|-------|-----------|----------------|
| File exists | Test -f "$path" | "Skill file not found" |
| Valid structure | Header + § sections | "Invalid SKILL.md format" |
| Tier match | Score ≥ threshold | Display warning |
| Security scan | OWASP AST10 pass | Block on P0 violations |

**Score Thresholds**:
| Tier | Minimum Score | F1 | MRR |
|------|---------------|-----|-----|
| GOLD | 900 | ≥ 0.95 | ≥ 0.90 |
| SILVER | 800 | ≥ 0.92 | ≥ 0.87 |
| BRONZE | 600 | ≥ 0.90 | ≥ 0.85 |
| FAIL | < 600 | < 0.90 | < 0.85 |

---

## §5.2 EdgeCase Testing (Multi-LLM)

**Boundary Conditions Tested**:
- Empty inputs
- Maximum context length
- Extreme parameter values
- Concurrent operations
- Lock contention
- Network timeout

**Multi-LLM Testing**:
```
1. LLM-1: Proposes edge cases
2. LLM-2: Proposes additional edge cases
3. LLM-3: Reviews edge case coverage
4. CROSS-VALIDATE: Final edge case set
5. EXECUTE: Test each edge case
6. REPORT: Pass/fail per edge case
```

---

## §5.3 Long-Context Handling

**New Dimension (10% weight)**:

| Sub-dimension | Description |
|---------------|-------------|
| Chunking Strategy | How skill handles long inputs |
| RAG Accuracy | Context retrieval precision |
| Context Preservation | Key info retention across chunks |
| Summary Quality | Accurate abstraction of long content |

**Excellence Criteria**:
- Explicit chunking strategy defined
- Context window limits documented
- Graceful degradation at limits

---

## §8.1 Metrics

**Success Criteria**:
| Metric | Target | Measurement |
|--------|--------|-------------|
| CREATE | Skill created | File exists + parse valid |
| EVALUATE | Score returned | 0-1000 + tier + F1/MRR |
| RESTORE | Score improved ≥ 0.5 | Multi-LLM verified |
| SECURITY | All OWASP items pass | 10/10 or documented P0s |
| OPTIMIZE | Delta > 0 | Score progression tracked |

**Quality Gates**:
| Gate | Requirement | Multi-LLM Verified |
|------|-------------|-------------------|
| BRONZE | score ≥ 600, F1 ≥ 0.90, MRR ≥ 0.85 | Yes |
| SILVER | score ≥ 800, F1 ≥ 0.92, MRR ≥ 0.87 | Yes |
| GOLD | score ≥ 900, F1 ≥ 0.95, MRR ≥ 0.90 | Yes |
| Production | SILVER + HUMAN_REVIEW pass | Yes |

---

## §8.2 Multi-LLM Cross-Validation Protocol

**Providers**: Anthropic, OpenAI, Kimi, MiniMax

**Cross-Validation Process**:
```
1. INDEPENDENT: Each LLM produces result independently
2. COMPARE: Compare results for agreement
3. CONFLICT: If disagreement > 20%, trigger deliberation
4. RESOLVE: LLMs debate and reach consensus
5. CONFIDENCE: Calculate confidence level (0-1)
6. FLAG: Low confidence results require human review
```

**Confidence Thresholds**:
| Confidence | Action |
|------------|--------|
| ≥ 0.9 | Auto-approve |
| 0.8-0.9 | Proceed with warning |
| 0.6-0.8 | Additional review |
| < 0.6 | HUMAN_REVIEW required |

---

## §8.3 Optimization History

**results.tsv Format**:
```
round	dimension	old_score	new_score	delta	confidence	llm_consensus
1	System Prompt	7.2	7.8	0.6	0.92	YES
2	Domain Knowledge	6.5	7.1	0.6	0.88	YES
3	Workflow	7.0	7.5	0.5	0.85	YES
```

**CURATION Trigger**: Every 10 rounds
- Review results.tsv
- Remove redundant entries
- Preserve winning strategies
- Reset round counter

---

## Interactive Prompts Reference

```
=== agent-skill v2.0 ===

What would you like to do?
  1. Create a new skill
  2. Evaluate an existing skill
  3. Restore a broken skill
  4. Security audit (OWASP AST10)
  5. Optimize/improve a skill
  6. Exit

Enter choice (1-6):
```

**CREATE prompts:**
```
1. "What skill do you want to create? Describe its purpose:"
2. "Target tier (GOLD/SILVER/BRONZE, default: BRONZE):"
3. "Output path (default: ./[name].md):"
```

**EVALUATE prompts:**
```
1. "Enter path to skill file:"
2. "Would you like to restore/secure/optimize this skill? (y/n):"
```

**RESTORE prompts:**
```
1. "Enter path to skill file to restore:"
```

**SECURITY prompts:**
```
1. "Enter path to skill file:"
2. "Audit level (BASIC/FULL, default: FULL):"
```

**OPTIMIZE prompts:**
```
1. "Enter path to skill file:"
2. "Target tier (current/MISSING):"
3. "Max rounds (default: 20):"
```
