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

**Decision Rules** (Enhanced - v2.1):
| Condition | Action | Confidence Threshold |
|-----------|--------|---------------------|
| Primary keyword exact match | → Respective mode | ≥ 0.80 |
| Keyword scoring + context | → Highest score mode | ≥ 0.60 |
| Negative pattern detected | → Exclude mode, re-score | - |
| Multiple modes tie | → Higher priority wins | - |
| Confidence < 0.6 | → Ask user to clarify | < 0.60 |
| Still ambiguous | → Default to EVALUATE | = 0.30 |
| Score < 8.0 after 10 rounds | → HUMAN_REVIEW | Expert human required |
| Score regression during OPTIMIZE | → Auto-rollback | Multi-LLM verified |

---

## §2.1 Invocation

**Activation**: When user wants to manage skills (create/evaluate/restore/secure/optimize)

**Trigger Patterns** (Enhanced - v2.1):

### Primary Triggers

| Mode | Priority | Primary Keywords | Score Weight |
|------|----------|-----------------|--------------|
| CREATE | 1 | "create skill", "build skill", "make skill", "new skill", "develop skill", "add skill" | +3 |
| EVALUATE | 2 | "evaluate skill", "test skill", "score skill", "review skill", "assess skill", "check skill", "validate skill" | +3 |
| RESTORE | 3 | "restore skill", "fix skill", "repair skill", "recover skill", "undo", "rollback skill" | +3 |
| SECURITY | 4 | "security audit", "OWASP", "vulnerability", "CWE", "security check", "penetration test", "security scan" | +3 |
| OPTIMIZE | 5 | "optimize skill", "improve skill", "evolve skill", "enhance skill", "tune skill", "refine skill", "upgrade skill" | +3 |

### Secondary Triggers (Context-Dependent)

| Mode | Context Keywords | Requires Primary |
|------|------------------|-----------------|
| CREATE | "generate", "scaffold", "template", "starter" | Context confirms skill creation |
| EVALUATE | "benchmark", "compare", "grade", "rate", "measure" | Context confirms assessment |
| RESTORE | "broken", "corrupt", "invalid", "error in" | Context confirms damage |
| SECURITY | "injection", "XSS", "CSRF", "exploit", "breach" | Context confirms security |
| OPTIMIZE | "performance", "speed", "efficiency", "clean up", "refactor" | Context confirms improvement |

### Negative Patterns (Anti-Triggers)

| Mode | Negative Patterns | Reason |
|------|-------------------|--------|
| CREATE | "check if skill exists", "skill already exists", "don't create" | False positive prevention |
| EVALUATE | "evaluate this code", "test my function" | Not about skills |
| RESTORE | "restore my file", "recover data" | Not skill-related |
| SECURITY | "secure my password", "make it secure" | Generic security |
| OPTIMIZE | "optimize this algorithm", "improve performance" | Not about skills |

### Disambiguation Rules

```
Rule 1: EXACT MATCH FIRST
  → If input exactly matches a primary keyword, use that mode
  → Example: "create skill" → CREATE (confidence: 0.95)

Rule 2: KEYWORD SCORING
  → Count keyword matches per mode
  → Highest score wins
  → Tie-breaker: use higher priority mode
  → Example: "create and optimize skill" → CREATE (score: create=2, optimize=1)

Rule 3: CONTEXT ANALYSIS
  → If scores tie, analyze surrounding context
  → Check for secondary keywords
  → Example: "build skill that evaluates code" → CREATE (build primary, evaluate is feature not mode)

Rule 4: NEGATIVE FILTER
  → If any negative pattern matches, exclude that mode
  → Re-score remaining modes
  → Example: "don't create skill, just check existing" → EVALUATE

Rule 5: USER CLARIFICATION
  → If confidence < 0.6 after rules 1-4, ask user
  → Present top 2 candidates with reasoning
  → Example: "help with skill" → Ask: "Did you want to CREATE, EVALUATE, or something else?"

Rule 6: DEFAULT FALLBACK
  → If still ambiguous, default to EVALUATE (safest)
  → Confidence: 0.3
```

### Confidence Scoring

```
confidence = (
  primary_match * 0.5 +
  secondary_match * 0.2 +
  context_match * 0.2 +
  no_negative * 0.1
)

Where:
- primary_match: 1 if exact primary keyword, 0.5 if partial, 0 otherwise
- secondary_match: 1 if secondary keyword present, 0 otherwise
- context_match: 1 if context supports, 0 otherwise
- no_negative: 1 if no negative patterns, 0 otherwise
```

### Example Trigger Analysis

| Input | Detected Mode | Confidence | Reasoning |
|-------|---------------|------------|-----------|
| "create a new skill" | CREATE | 0.95 | Exact primary match |
| "optimize my skill" | OPTIMIZE | 0.85 | Primary + context |
| "fix the broken skill" | RESTORE | 0.80 | Primary + secondary context |
| "don't create skill, evaluate it" | EVALUATE | 0.70 | Negative filter applied |
| "skill management" | EVALUATE | 0.60 | Default + context |
| "help with skills" | EVALUATE | 0.30 | Low confidence, ask user |

**Usage**:
```bash
./SKILL.md
# Then answer interactive prompts
```

---

## §2.2 Recognition

**Intent Detection (Multi-LLM)**:
1. Each LLM extracts keywords independently using scoring system above
2. Cross-validate intent detection results (must agree on top 2)
3. If LLMs disagree on top mode, use confidence-weighted selection
4. If confidence < 0.6, ask user to clarify
5. Default to EVALUATE if still ambiguous

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

### Mode: LEAN (Fast Path)

**Purpose**: Lean, fast, cost-effective skill evaluation (~1 second)

**Design Principles**:
- Fast Path: Parse + Heuristic scoring (no LLM)
- LLM on-demand: Multi-LLM only for critical decisions
- Parallel Execution: Independent dimensions run in parallel
- Incremental: Only fix what needs fixing

**Workflow (~1 second)**:
```
1. FAST_PARSE: YAML, §1.x sections, triggers (heuristic, no LLM)
2. TEXT_SCORE: §1.x quality, domain knowledge, workflow (heuristic, no LLM)
3. RUNTIME_TEST: §2 trigger patterns, mode definitions (no LLM)
4. DECIDE: Compare to threshold
5. ITERATE (if needed): Fast LLM fix for specific issues
6. CERTIFY: Tier determination
```

**Fast Path Thresholds (500-point scale)**:
| Tier | Parse | Text | Runtime | Total | 
|------|-------|------|---------|-------|
| GOLD | 80+ | 280+ | 40+ | 475+ | (95%)
| SILVER | 70+ | 245+ | 35+ | 425+ | (85%)
| BRONZE | 60+ | 210+ | 30+ | 350+ | (70%) |

**When to Escalate to Full Eval**:
- Score near threshold boundary
- High disagreement between heuristics
- Production deployment required
- User explicitly requests full eval

**Usage**:
```bash
./scripts/lean-orchestrator.sh <skill_file> [target_tier]
```

**Example**:
```bash
./scripts/lean-orchestrator.sh ./SKILL.md BRONZE
# Output: {"status":"PASS","tier":"SILVER","parse":100,"text":305,"runtime":25,"total":430}
```

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

### 4.1.0 User Scripts

**Quick CLI access to all core functionality:**

| Tool | Path | Purpose | Speed |
|------|------|---------|-------|
| **create-skill** | `scripts/create-skill.sh` | Create new skill from description | ~30s |
| **evaluate-skill** | `scripts/evaluate-skill.sh` | Full evaluation (fast/full) | ~2-10min |
| **lean-orchestrator** | `scripts/lean-orchestrator.sh` | Fast evaluation (~1s) | **~1s** |
| **optimize-skill** | `scripts/optimize-skill.sh` | 9-step self-optimization loop | ~5min |
| **security-audit** | `scripts/security-audit.sh` | OWASP AST10 security check | ~10s |
| **restore-skill** | `scripts/restore-skill.sh` | Fix broken skills | ~20s |
| **quick-score** | `scripts/quick-score.sh` | Fast text scoring (no LLM) | <1s |

**Usage:**
```bash
# Fast path (~1 second)
./scripts/lean-orchestrator.sh ./SKILL.md BRONZE

# Full evaluation (~2 minutes)
./scripts/evaluate-skill.sh ./SKILL.md fast

# Create new skill
./scripts/create-skill.sh "Create a code review skill" ./code-review.md GOLD

# Optimize
./scripts/optimize-skill.sh ./code-review.md 20
```

---

### 4.1.1 ENGINE - Skill Lifecycle Management

#### Core Orchestration

| Tool | Path | Purpose |
|------|------|---------|
| **orchestrator** | `engine/orchestrator.sh` | Main workflow coordinator for CREATE mode |
| **main** | `engine/main.sh` | CLI entry point for engine |
| **bootstrap** | `engine/lib/bootstrap.sh` | Module loading, path init, require() |

#### Agent Tools

| Tool | Path | Purpose |
|------|------|---------|
| **creator** | `engine/agents/creator.sh` | Generate SKILL.md sections via LLM |
| **evaluator** | `engine/agents/evaluator.sh` | Evaluate skills, return score+suggestions |
| **restorer** | `engine/agents/restorer.sh` | Multi-LLM diagnosis and fix verification |
| **security** | `engine/agents/security.sh` | OWASP AST10 10-item security audit |
| **base** | `engine/agents/base.sh` | Agent infrastructure (LLM calls, prompts) |

#### Evolution Pipeline

| Tool | Path | Purpose |
|------|------|---------|
| **engine** | `engine/evolution/engine.sh` | 9-step optimization loop |
| **analyzer** | `engine/evolution/analyzer.sh` | LLM-based usage log analysis |
| **improver** | `engine/evolution/improver.sh` | LLM-based improvement generation |
| **summarizer** | `engine/evolution/summarizer.sh` | LLM-based analysis summarization |
| **rollback** | `engine/evolution/rollback.sh` | Snapshot and rollback management |
| **storage** | `engine/evolution/_storage.sh` | Usage log abstraction layer |

#### State & Concurrency

| Tool | Path | Purpose |
|------|------|---------|
| **state** | `engine/orchestrator/_state.sh` | Global state variables |
| **actions** | `engine/orchestrator/_actions.sh` | Workflow decision logic |
| **parallel** | `engine/orchestrator/_parallel.sh` | Background task execution |
| **concurrency** | `engine/lib/concurrency.sh` | Lock management, with_lock() |

#### Errors & Constants

| Tool | Path | Purpose |
|------|------|---------|
| **errors** | `engine/lib/errors.sh` | Error handling, retry logic |
| **constants** | `engine/lib/constants.sh` | Thresholds, timeouts, tier definitions |
| **integration** | `engine/lib/integration.sh` | eval framework integration |

---

### 4.1.2 EVAL - Skill Evaluation Framework

#### Main Evaluation

| Tool | Path | Purpose |
|------|------|---------|
| **main** | `eval/main.sh` | Unified 4-phase evaluation engine |
| **parse_validate** | `eval/parse/parse_validate.sh` | Phase 1: Format validation |
| **certifier** | `eval/certifier.sh` | Phase 4: Tier determination |

#### Scoring

| Tool | Path | Purpose |
|------|------|---------|
| **text_scorer** | `eval/scorer/text_scorer.sh` | Phase 2: Text quality (350pts) |
| **runtime_tester** | `eval/scorer/runtime_tester.sh` | Phase 3: Runtime behavior (450pts) |
| **runtime_agent** | `eval/scorer/runtime_agent_tester.sh` | LLM-based runtime testing |

#### Analyzers

| Tool | Path | Purpose |
|------|------|---------|
| **trigger_analyzer** | `eval/analyzer/trigger_analyzer.sh` | F1/MRR/trigger accuracy |
| **variance_analyzer** | `eval/analyzer/variance_analyzer.sh` | Text-Runtime variance calculation |
| **dimension_analyzer** | `eval/analyzer/dimension_analyzer.sh` | Per-dimension scoring |

#### Reporting

| Tool | Path | Purpose |
|------|------|---------|
| **json_reporter** | `eval/report/json_reporter.sh` | JSON report generation |
| **html_reporter** | `eval/report/html_reporter.sh` | HTML report with badges |

#### Utilities

| Tool | Path | Purpose |
|------|------|---------|
| **agent_executor** | `eval/lib/agent_executor.sh` | Multi-LLM call orchestration |
| **constants** | `eval/lib/constants.sh` | 1000pts scoring thresholds |
| **utils** | `eval/lib/utils.sh` | Shared utilities |
| **i18n** | `eval/lib/i18n.sh` | Internationalization |

#### Corpus

| Tool | Path | Purpose |
|------|------|---------|
| **corpus_100** | `eval/corpus/corpus_100.json` | 100 test cases (fast eval) |
| **corpus_1000** | `eval/corpus/corpus_1000.json` | 1000 test cases (full eval) |

---

### 4.1.3 Tool Usage Reference

#### Create Skill
```bash
engine/orchestrator.sh "Create a code review skill" ./code-review.md BRONZE
```

#### Evaluate Skill
```bash
eval/main.sh --skill ./SKILL.md --fast
engine/agents/evaluator.sh ./SKILL.md
```

#### Security Audit
```bash
engine/agents/security.sh ./SKILL.md FULL
```

#### Restore Skill
```bash
engine/agents/restorer.sh ./SKILL.md
```

#### Optimize Skill
```bash
engine/evolution/engine.sh ./SKILL.md 20
```

#### Quick Score
```bash
eval/scorer/text_scorer.sh ./SKILL.md
eval/analyzer/trigger_analyzer.sh eval/corpus/corpus_100.json
```

#### Analyze Variance
```bash
eval/analyzer/variance_analyzer.sh 280 360
```

---

### 4.1.4 Multi-LLM Provider Support

**Provider Strength Ranking** (for auto-selection):
| Rank | Provider | Strength | Environment Variable |
|------|----------|----------|----------------------|
| 1 | anthropic | 100 | `ANTHROPIC_API_KEY` |
| 2 | openai | 90 | `OPENAI_API_KEY` |
| 3 | kimi-code | 85 | `KIMI_CODE_API_KEY` |
| 4 | minimax | 80 | `MINIMAX_API_KEY` |
| 5 | kimi | 75 | `KIMI_API_KEY` |

**Auto-Selection**: System automatically detects available providers and selects top 2 for cross-validation. Lean evaluation uses heuristic scoring (~0s, $0) and only invokes LLM deliberation for edge cases or when score is below threshold.

**Cross-Validation**: All critical decisions require 2/3 LLM agreement. Conflicts trigger HUMAN_REVIEW.

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

---

## §6 Self-Evolution (Use-Then-Evolve)

### 6.1 Trigger Mechanisms

**Dual Trigger System**:

| Trigger | Condition | Priority |
|---------|-----------|----------|
| **Threshold** | Score < GOLD (475) | High |
| **Scheduled** | Every 24 hours | Medium |
| **Usage-based** | Trigger F1 < 0.85 OR Task Rate < 0.80 | High |
| **Manual** | `evolve_with_auto` called with force=true | Highest |

**Decision Flow**:
```
check_threshold() → check_scheduled() → check_usage_metrics() → decision
```

### 6.2 Usage Data Collection

**Tracked Events**:

| Event | Fields | Storage |
|-------|--------|---------|
| `trigger` | expected_mode, actual_mode, correct | logs/evolution/usage_<skill>_<date>.jsonl |
| `task` | task_type, completed, rounds | logs/evolution/usage_<skill>_<date>.jsonl |
| `feedback` | rating (1-5), comment | logs/evolution/usage_<skill>_<date>.jsonl |

**Metrics Computed**:
- **Trigger F1**: correct_triggers / total_triggers
- **Task Completion Rate**: completed_tasks / total_tasks
- **Avg Feedback Rating**: mean of all ratings

### 6.3 Usage-Triggered Evolution

**Enhanced 9-Step Loop with Step 0**:

| Step | Name | Description |
|------|------|-------------|
| 0 | **USAGE_ANALYSIS** | Extract patterns from usage data (NEW) |
| 1 | READ | Locate weakest dimension (multi-LLM) |
| 2 | ANALYZE | Prioritize strategy (multi-LLM) |
| 3 | CURATION | Knowledge consolidation + usage learning |
| 4 | PLAN | Select improvement approach |
| 5 | IMPLEMENT | Apply change with rollback |
| 6 | VERIFY | Re-evaluate with multi-LLM |
| 7 | HUMAN_REVIEW | Every 10 rounds if score < SILVER |
| 8 | LOG | Record to results.tsv + track usage |
| 9 | COMMIT | Git commit if needed |

### 6.4 Pattern Learning

**Pattern Types Extracted**:
- `weak_triggers`: Array of `expected->actual` confusion pairs
- `failed_task_types`: Array of task types with low completion

**Knowledge Consolidation**:
- Patterns stored in `logs/evolution/patterns/<skill>_patterns.json`
- Knowledge docs in `logs/evolution/knowledge/<skill>_knowledge.md`

**Improvement Hints**:
- Generated from pattern analysis
- Injected into optimization loop
- Example: "Trigger confusion: OPTIMIZE->EVALUATE. Add disambiguation examples."

### 6.5 Auto-Evolution Command

```bash
# Check if evolution needed (returns JSON decision)
engine/evolution/evolve_decider.sh <skill_file> [force]

# Run auto-evolution with usage learning
engine/evolution/engine.sh <skill_file> auto [force]

# Track usage manually
source engine/evolution/usage_tracker.sh
track_trigger "agent-skill" "OPTIMIZE" "OPTIMIZE"
track_task "agent-skill" "optimization" "true" 3
track_feedback "agent-skill" 5 "Good results"
```

### 6.6 Integration with Lean Eval

Lean evaluation (~0s, $0) runs first:
- If score >= GOLD threshold → skip expensive LLM evolution
- If score < threshold → trigger evolution
- Usage metrics provide additional trigger signals

**Threshold Configuration**:
| Tier | Score | Evolution Trigger |
|------|-------|-------------------|
| GOLD | >= 475 | Usage-based only |
| SILVER | 425-474 | Scheduled + Usage |
| BRONZE | 350-424 | All triggers |
| FAIL | < 350 | Immediate + Force |
