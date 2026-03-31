# OPTIMIZE Mode Documentation

> **Purpose**: OPTIMIZE mode provides automated, iterative skill improvement through a 7-dimension 9-step optimization loop. It continuously refines skills until they reach convergence or maximum rounds, with intelligent escalation for complex cases.
> **Version**: 2.0.0
> **Last Updated**: 2026-03-31

---

## Table of Contents

1. [Overview](#overview)
2. [7-Dimension Analysis Framework](#7-dimension-analysis-framework)
3. [9-Step Optimization Loop](#9-step-optimization-loop)
4. [Convergence Detection](#convergence-detection)
5. [Max Rounds & Escalation](#max-rounds--escalation)
6. [Usage Examples](#usage-examples)
7. [Output Format](#output-format)
8. [Integration](#integration)

---

## Overview

OPTIMIZE mode is the continuous improvement engine of the skill-framework. It transforms underperforming or evolving skills into higher-quality versions through systematic, measurable iteration.

### Key Features

- **7-dimension analysis** with weighted scoring
- **9-step optimization loop** with hard gates
- **Convergence detection** to prevent infinite loops
- **Intelligent escalation** for complex optimization cases
- **20-round default maximum** with configurable limits
- **Full audit trail** of all changes and improvements

### Optimization Philosophy

```
┌─────────────────────────────────────────────────────────────────┐
│                  OPTIMIZATION PRINCIPLES                        │
├─────────────────────────────────────────────────────────────────┤
│ • Measurable: Every change must improve a quantifiable metric   │
│ • Bounded: Maximum rounds prevent infinite loops                │
│ • Convergent: Detects when improvements plateau                 │
│ • Safe: All changes are reversible with full audit trail        │
│ • Transparent: Human review gates for significant changes       │
└─────────────────────────────────────────────────────────────────┘
```

### When to Use OPTIMIZE Mode

| Scenario | Action |
|----------|--------|
| EVALUATE score < 700 (FAIL tier) | **Required**: Auto-triggered optimization |
| EVALUATE score 700-799 (BRONZE tier) | **Recommended**: Address flagged issues |
| EVALUATE score 800-899 (SILVER tier) | **Optional**: Target specific improvements |
| Feature evolution | **Use case**: Add new capabilities to existing skill |
| Bug fixes | **Use case**: Fix issues discovered in production |
| Performance tuning | **Use case**: Improve response time, reduce tokens |

---

## 7-Dimension Analysis Framework

OPTIMIZE mode analyzes skills across 7 dimensions, each with a specific weight reflecting its importance to overall skill quality.

### Dimension Weights

```
┌─────────────────────────────────────────────────────────────────┐
│                    DIMENSION WEIGHTS                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   System Design        ████████████████████████████    20%     │
│   Domain Knowledge     ████████████████████████        18%     │
│   Workflow Definition  ██████████████████████          16%     │
│   Error Handling       ████████████████████            14%     │
│   Examples             ██████████████████              12%     │
│   Metadata             ████████████████                10%     │
│   Long-Context         ██████████████                   10%     │
│                                                                 │
│   Total: 100%                                                   │
└─────────────────────────────────────────────────────────────────┘
```

### Dimension Details

#### 1. System Design (20% weight)

Evaluates architectural quality and design patterns.

| Sub-criterion | Weight | Optimization Target |
|---------------|--------|---------------------|
| Component boundaries | 6% | Clear, well-defined interfaces |
| Single responsibility | 6% | Each component has one purpose |
| Design patterns | 4% | Appropriate pattern usage |
| Scalability | 4% | Performance at scale addressed |

**Improvement Strategies:**
- Refactor mixed-responsibility components
- Add interface specifications
- Document design pattern rationale
- Include performance benchmarks

**Scoring:**
- 90-100%: Excellent architecture
- 75-89%: Good with minor issues
- 60-74%: Adequate, needs refinement
- 45-59%: Poor, significant rework needed
- < 45%: Critical, complete redesign required

---

#### 2. Domain Knowledge (18% weight)

Assesses depth and accuracy of domain expertise.

| Sub-criterion | Weight | Optimization Target |
|---------------|--------|---------------------|
| Terminology accuracy | 7% | Correct, consistent domain terms |
| Best practices | 6% | Industry standards referenced |
| Edge cases | 5% | Domain-specific scenarios covered |

**Improvement Strategies:**
- Add domain glossary
- Reference authoritative sources
- Expand edge case documentation
- Include domain expert review

**Scoring:**
- 90-100%: Expert-level knowledge
- 75-89%: Solid with minor gaps
- 60-74%: Basic, some inaccuracies
- 45-59%: Limited, notable gaps
- < 45%: Incorrect or missing

---

#### 3. Workflow Definition (16% weight)

Evaluates clarity and completeness of workflows.

| Sub-criterion | Weight | Optimization Target |
|---------------|--------|---------------------|
| Step sequence | 6% | Clear, logical ordering |
| Decision points | 5% | All branches documented |
| State transitions | 5% | State changes explicit |

**Improvement Strategies:**
- Add workflow diagrams
- Document all decision branches
- Clarify state transitions
- Include rollback procedures

**Scoring:**
- 90-100%: Crystal clear, all paths covered
- 75-89%: Good, minor path gaps
- 60-74%: Adequate, some ambiguity
- 45-59%: Unclear, missing steps
- < 45%: No coherent workflow

---

#### 4. Error Handling (14% weight)

Assesses robustness of error handling strategy.

| Sub-criterion | Weight | Optimization Target |
|---------------|--------|---------------------|
| Error categories | 5% | Input, runtime, external covered |
| Recovery strategies | 5% | Clear recovery for each error |
| User messages | 4% | Actionable, clear messages |

**Improvement Strategies:**
- Expand error category coverage
- Add recovery procedures
- Improve error message clarity
- Include error examples

**Scoring:**
- 90-100%: Comprehensive handling
- 75-89%: Good coverage, minor gaps
- 60-74%: Basic, some cases missing
- 45-59%: Limited, major gaps
- < 45%: No error handling

---

#### 5. Examples (12% weight)

Evaluates quality and coverage of usage examples.

| Sub-criterion | Weight | Optimization Target |
|---------------|--------|---------------------|
| Quantity | 4% | Minimum 2, bonus for 4+ |
| Coverage | 4% | Happy path + edge cases |
| Clarity | 4% | Easy to understand |

**Improvement Strategies:**
- Add more examples (target: 4+)
- Cover edge cases and errors
- Simplify complex examples
- Add step-by-step explanations

**Scoring:**
- 90-100%: Excellent, comprehensive
- 75-89%: Good, minor gaps
- 60-74%: Adequate (2+ examples)
- 45-59%: Poor, unclear or few
- < 45%: No examples or single

---

#### 6. Metadata (10% weight)

Assesses completeness and accuracy of metadata.

| Sub-criterion | Weight | Optimization Target |
|---------------|--------|---------------------|
| Versioning | 3% | Semantic versioning, changelog |
| Authorship | 3% | Author, license, dates |
| Tags | 2% | Relevant, comprehensive |
| Interface spec | 2% | Clear input/output definitions |

**Improvement Strategies:**
- Add semantic versioning
- Complete authorship fields
- Expand tag coverage
- Clarify interface specifications

**Scoring:**
- 90-100%: Complete metadata
- 75-89%: Good, minor omissions
- 60-74%: Adequate, some missing
- 45-59%: Poor, major omissions
- < 45%: Minimal or incorrect

---

#### 7. Long-Context (10% weight)

Evaluates skill performance with extended context windows.

| Sub-criterion | Weight | Optimization Target |
|---------------|--------|---------------------|
| Context efficiency | 4% | Minimal token usage |
| Information density | 3% | High signal-to-noise ratio |
| Progressive disclosure | 3% | Layered information presentation |

**Improvement Strategies:**
- Compress redundant content
- Use progressive disclosure patterns
- Add context management strategies
- Optimize for token limits

**Scoring:**
- 90-100%: Highly efficient
- 75-89%: Good efficiency
- 60-74%: Adequate, some bloat
- 45-59%: Inefficient, verbose
- < 45%: Critical bloat issues

---

### Dimension Score Calculation

```
Dimension Score = (Raw Score / Max Score) × Weight × 100

Overall Score = Σ(Dimension Scores)

Example:
  System Design:    (85/100) × 0.20 × 100 = 17.0
  Domain Knowledge: (90/100) × 0.18 × 100 = 16.2
  Workflow:         (75/100) × 0.16 × 100 = 12.0
  Error Handling:   (80/100) × 0.14 × 100 = 11.2
  Examples:         (70/100) × 0.12 × 100 = 8.4
  Metadata:         (95/100) × 0.10 × 100 = 9.5
  Long-Context:     (85/100) × 0.10 × 100 = 8.5
  ─────────────────────────────────────────────
  Total:                                    82.8/100
```

---

## 9-Step Optimization Loop

The optimization loop iteratively improves skills through 9 sequential steps. Each iteration is called a "round."

```
┌─────────────────────────────────────────────────────────────────┐
│                     OPTIMIZATION LOOP                           │
│                    (One Round = 9 Steps)                        │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ STEP 1: READ                                                    │
│ ├─ Load skill file from disk                                    │
│ ├─ Parse YAML frontmatter                                       │
│ ├─ Extract all sections and content                             │
│ └─ Load previous optimization history (if any)                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ STEP 2: ANALYZE                                                 │
│ ├─ Score all 7 dimensions                                       │
│ ├─ Identify improvement opportunities                           │
│ ├─ Calculate current overall score                              │
│ └─ Determine target score (based on tier goal)                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ STEP 3: CURATE                                                  │
│ ├─ Rank improvement opportunities by impact                     │
│ ├─ Filter out low-impact changes (< 2 point gain)               │
│ ├─ Prioritize high-weight dimensions                            │
│ └─ Select top N improvements for this round                     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ STEP 4: PLAN                                                    │
│ ├─ Generate specific change proposals                           │
│ ├─ Estimate impact of each change                               │
│ ├─ Check for conflicts between proposals                        │
│ └─ Create ordered implementation plan                           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ STEP 5: IMPLEMENT                                               │
│ ├─ Apply planned changes to skill file                          │
│ ├─ Maintain YAML frontmatter validity                           │
│ ├─ Preserve section structure                                   │
│ └─ Generate diff of changes                                     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ STEP 6: VERIFY                                                  │
│ ├─ Re-score all 7 dimensions                                    │
│ ├─ Calculate new overall score                                  │
│ ├─ Validate YAML syntax                                         │
│ └─ Check for regressions                                        │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ STEP 7: HUMAN_REVIEW                                            │
│ ├─ Present changes to human (if significant)                    │
│ ├─ Wait for approval/rejection                                  │
│ ├─ Apply feedback if rejected                                   │
│ └─ Gate: Major changes require sign-off                         │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ STEP 8: LOG                                                     │
│ ├─ Record round results to optimization log                     │
│ ├─ Store before/after diff                                      │
│ ├─ Update convergence metrics                                   │
│ └─ Write audit entry                                            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ STEP 9: COMMIT                                                  │
│ ├─ Check convergence criteria                                   │
│ ├─ Check max rounds limit                                       │
│ ├─ Decision: Continue, Converge, or Escalate                    │
│ └─ If Continue: Loop back to READ                               │
└─────────────────────────────────────────────────────────────────┘
```

### Step Gates Summary

| Step | Purpose | Gate Condition | Failure Action |
|------|---------|----------------|----------------|
| READ | Load skill | File exists and readable | Abort with error |
| ANALYZE | Score dimensions | All 7 dimensions scored | Retry with fallback scorer |
| CURATE | Prioritize | At least 1 improvement found | Escalate if none found |
| PLAN | Create proposals | Valid plan generated | Revise plan |
| IMPLEMENT | Apply changes | Changes applied successfully | Rollback and retry |
| VERIFY | Validate | Score improved or maintained | Rollback if regression |
| HUMAN_REVIEW | Approval | Approved or minor changes | Revise based on feedback |
| LOG | Record | Log entry written | Warning, continue |
| COMMIT | Decide next | Convergence or max rounds | Loop or exit |

### Round Completion Criteria

A round completes successfully when:
1. All 9 steps executed without hard failures
2. Score maintained or improved (no regression)
3. Changes logged to audit trail
4. Next action determined (continue/converge/escalate)

---

## Convergence Detection

OPTIMIZE mode detects four convergence states to determine when to stop iterating.

### Convergence States

```
┌─────────────────────────────────────────────────────────────────┐
│                  CONVERGENCE STATES                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌────────┐ │
│  │  VOLATILE   │  │  PLATEAU    │  │ IMPROVING   │  │DIVERGE │ │
│  │    ↕↕↕      │  │    ───      │  │    ↑↑↑      │  │  ↓↓↓   │ │
│  │  Unstable   │  │  Stalled    │  │  Progress   │  │Worsening│ │
│  └─────────────┘  └─────────────┘  └─────────────┘  └────────┘ │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

#### 1. VOLATILE (Oscillating)

**Definition**: Score fluctuates significantly between rounds without clear trend.

**Detection Criteria:**
```
VOLATILE when:
  - Score variance across last 3 rounds > 15%
  - No consistent direction (up/down/up or down/up/down)
  - Peak-to-trough difference > 20 points
```

**Example Pattern:**
```
Round 1: 72.5
Round 2: 68.3  (↓ -4.2)
Round 3: 74.1  (↑ +5.8)
Round 4: 69.7  (↓ -4.4)
→ VOLATILE detected
```

**Action:**
- Pause optimization
- Analyze conflicting changes
- Apply constraint: Only allow additive improvements
- Require human review before continuing

---

#### 2. PLATEAU (Stalled)

**Definition**: Score stops improving despite continued iterations.

**Detection Criteria:**
```
PLATEAU when:
  - No improvement for 3 consecutive rounds
  - Score change < 2 points per round
  - At least 5 rounds completed
```

**Example Pattern:**
```
Round 5:  82.3
Round 6:  82.5  (↑ +0.2)
Round 7:  82.4  (↓ -0.1)
Round 8:  82.6  (↑ +0.2)
→ PLATEAU detected
```

**Action:**
- Mark as converged
- Generate plateau report
- Suggest: Higher-impact changes or manual intervention
- Exit optimization loop

---

#### 3. IMPROVING (Progress)

**Definition**: Score consistently increases with meaningful gains.

**Detection Criteria:**
```
IMPROVING when:
  - Average gain per round > 3 points
  - At least 2 of last 3 rounds show improvement
  - No regression > 5 points
```

**Example Pattern:**
```
Round 2: 65.2
Round 3: 71.8  (↑ +6.6)
Round 4: 76.3  (↑ +4.5)
Round 5: 81.2  (↑ +4.9)
→ IMPROVING (continue)
```

**Action:**
- Continue optimization
- Maintain current strategy
- Monitor for plateau or volatility

---

#### 4. DIVERGING (Worsening)

**Definition**: Score consistently decreases, indicating counterproductive changes.

**Detection Criteria:**
```
DIVERGING when:
  - 2 consecutive rounds with regression > 5 points
  - Overall trend negative over last 3 rounds
  - Score below starting point
```

**Example Pattern:**
```
Round 3: 78.5
Round 4: 72.1  (↓ -6.4)
Round 5: 66.8  (↓ -5.3)
→ DIVERGING detected
```

**Action:**
- Immediate rollback to last known good state
- Halt optimization
- Escalate to human with divergence report
- Require root cause analysis before resume

---

### Convergence Decision Matrix

| State | Score Trend | Action | Continue? |
|-------|-------------|--------|-----------|
| **VOLATILE** | Oscillating | Apply constraints, human review | Conditional |
| **PLATEAU** | Flat | Mark converged, exit | No |
| **IMPROVING** | Rising | Continue optimization | Yes |
| **DIVERGING** | Falling | Rollback, escalate | No |

---

## Max Rounds & Escalation

OPTIMIZE mode has built-in limits to prevent infinite loops and resource exhaustion.

### Default Maximum Rounds

```
┌─────────────────────────────────────────────────────────────────┐
│                    ROUND LIMITS                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Default Maximum:        20 rounds                             │
│  Minimum Allowed:        5 rounds                              │
│  Maximum Allowed:        100 rounds                            │
│  Hard System Limit:      1000 rounds                           │
│                                                                 │
│  Round Duration Target:  < 30 seconds                          │
│  Total Duration Target:  < 10 minutes (20 rounds)              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Round Limit Configuration

```yaml
# Configuration options
optimization:
  max_rounds: 20              # Default
  min_rounds: 3               # Minimum before early convergence
  convergence_threshold: 2.0  # Points improvement to continue
  plateau_rounds: 3           # Rounds without improvement = plateau
```

### Early Exit Conditions

Optimization may exit before max rounds:

| Condition | Exit Round | Status |
|-----------|------------|--------|
| Target tier reached | Any | SUCCESS |
| PLATEAU detected | ≥ 5 | CONVERGED |
| DIVERGING detected | Any | FAILED |
| VOLATILE (unresolved) | ≥ 10 | ESCALATED |
| Human abort signal | Any | ABORTED |

---

### Escalation Triggers

Escalation occurs when optimization cannot proceed automatically.

#### Escalation Levels

**Level 1: Automated Retry**
- Trigger: Transient failure (network, parsing)
- Action: Retry with exponential backoff
- Human involvement: None

**Level 2: Constraint Adjustment**
- Trigger: VOLATILE state detected
- Action: Tighten change constraints, require additive-only
- Human involvement: Optional review

**Level 3: Human Review Required**
- Trigger: Max rounds reached without convergence
- Action: Pause, present full report
- Human involvement: Required approval to continue

**Level 4: Expert Escalation**
- Trigger: DIVERGING state, or Level 3 unresolved
- Action: Halt optimization, generate diagnostic report
- Human involvement: Expert analysis required

---

#### Escalation Report Format

```yaml
escalation:
  level: 3
  trigger: "Max rounds reached without convergence"
  rounds_completed: 20
  current_score: 78.5
  target_score: 85.0
  convergence_state: "PLATEAU"
  
  dimension_scores:
    system_design: 82
    domain_knowledge: 85
    workflow_definition: 76
    error_handling: 71
    examples: 80
    metadata: 88
    long_context: 75
  
  improvement_history:
    - round: 1, score: 65.2, change: +0.0
    - round: 2, score: 71.8, change: +6.6
    - round: 3, score: 76.3, change: +4.5
    # ... rounds 4-20
    - round: 20, score: 78.5, change: +0.1
  
  recommendations:
    - "Focus on Error Handling dimension (lowest score)"
    - "Add comprehensive error recovery examples"
    - "Consider manual rewrite of workflow section"
  
  options:
    - "Continue with 10 more rounds"
    - "Accept current score (78.5)"
    - "Manual optimization with guidance"
    - "Abandon and revert to original"
```

---

## Usage Examples

### Example 1: Basic Optimization

Optimize a skill that failed evaluation:

```bash
# CLI usage
skill-framework optimize --file skills/my-skill.md --target-tier SILVER

# Programmatic usage
from skill_framework import optimize

result = optimize(
    "skills/my-skill.md",
    target_tier="SILVER",
    max_rounds=20
)

print(f"Starting score: {result.initial_score}")
print(f"Final score: {result.final_score}")
print(f"Rounds: {result.rounds_completed}")
print(f"Convergence: {result.convergence_state}")
```

**Output:**
```json
{
  "skill": "my-skill",
  "version": "1.0.0",
  "optimization_id": "opt-20260331-001",
  "started_at": "2026-03-31T10:00:00Z",
  "completed_at": "2026-03-31T10:05:23Z",
  "initial_score": 65.2,
  "final_score": 82.5,
  "target_score": 80.0,
  "target_tier": "SILVER",
  "rounds_completed": 8,
  "max_rounds": 20,
  "convergence_state": "PLATEAU",
  "converged": true,
  "success": true,
  "dimension_improvements": {
    "system_design": {"before": 58, "after": 82, "delta": +24},
    "domain_knowledge": {"before": 72, "after": 85, "delta": +13},
    "workflow_definition": {"before": 65, "after": 78, "delta": +13},
    "error_handling": {"before": 45, "after": 71, "delta": +26},
    "examples": {"before": 80, "after": 85, "delta": +5},
    "metadata": {"before": 85, "after": 88, "delta": +3},
    "long_context": {"before": 70, "after": 75, "delta": +5}
  },
  "rounds": [
    {
      "round": 1,
      "step": "COMMIT",
      "score": 65.2,
      "change": 0.0,
      "changes": ["Initial analysis"],
      "convergence": "IMPROVING"
    },
    {
      "round": 2,
      "step": "COMMIT",
      "score": 71.8,
      "change": +6.6,
      "changes": ["Added error handling section", "Expanded examples"],
      "convergence": "IMPROVING"
    }
    // ... rounds 3-8
  ]
}
```

---

### Example 2: Optimization with Constraints

Optimize with specific constraints:

```bash
skill-framework optimize \
  --file skills/my-skill.md \
  --target-tier GOLD \
  --max-rounds 15 \
  --focus-dimensions "error_handling,examples" \
  --min-improvement 3.0
```

**Parameters:**
- `--target-tier GOLD`: Target 90+ score
- `--max-rounds 15`: Stop after 15 rounds
- `--focus-dimensions`: Only optimize specified dimensions
- `--min-improvement 3.0`: Stop if round improvement < 3 points

---

### Example 3: Resume Interrupted Optimization

Resume optimization from a previous run:

```bash
skill-framework optimize \
  --file skills/my-skill.md \
  --resume opt-20260331-001 \
  --additional-rounds 10
```

---

### Example 4: Dry Run (Preview Changes)

Preview what changes would be made without applying them:

```bash
skill-framework optimize \
  --file skills/my-skill.md \
  --dry-run \
  --rounds 3
```

**Output:**
```
DRY RUN: Optimization Preview
=============================

Round 1 Proposed Changes:
  1. [Error Handling] Add recovery strategy for timeout errors
     Estimated impact: +4.5 points
  2. [Examples] Add edge case example for null input
     Estimated impact: +2.0 points
  3. [Metadata] Update version to 1.0.1
     Estimated impact: +0.5 points

Estimated final score: 72.2 (+7.0)
No changes applied (dry run mode)
```

---

### Example 5: Batch Optimization

Optimize multiple skills:

```bash
skill-framework optimize \
  --batch "skills/*.md" \
  --min-tier SILVER \
  --parallel 4 \
  --output optimization-report.json
```

**Output:**
```json
{
  "optimized_at": "2026-03-31T10:30:00Z",
  "total_skills": 10,
  "successful": 8,
  "failed": 1,
  "converged": 7,
  "escalated": 1,
  "results": [
    {
      "skill": "skill-a",
      "initial_score": 65.2,
      "final_score": 82.5,
      "rounds": 8,
      "status": "CONVERGED"
    },
    {
      "skill": "skill-b",
      "initial_score": 71.0,
      "final_score": 88.3,
      "rounds": 12,
      "status": "CONVERGED"
    }
    // ... more results
  ]
}
```

---

### Example 6: CI/CD Integration

Use in a GitHub Actions workflow:

```yaml
name: Skill Optimization

on:
  schedule:
    - cron: '0 2 * * 0'  # Weekly on Sunday at 2 AM
  workflow_dispatch:
    inputs:
      target_tier:
        description: 'Target tier'
        default: 'SILVER'
        type: choice
        options:
          - BRONZE
          - SILVER
          - GOLD
          - PLATINUM

jobs:
  optimize:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Evaluate Current Skills
        id: evaluate
        run: |
          skill-framework evaluate \
            --batch skills/*.md \
            --output evaluation.json
      
      - name: Identify Skills Needing Optimization
        id: identify
        run: |
          # Extract skills below target tier
          jq -r '.skills[] | select(.tier != "${{ github.event.inputs.target_tier }}") | .file' \
            evaluation.json > skills-to-optimize.txt
      
      - name: Optimize Skills
        if: steps.identify.outputs.count > 0
        run: |
          while read skill; do
            skill-framework optimize \
              --file "$skill" \
              --target-tier ${{ github.event.inputs.target_tier }} \
              --max-rounds 20
          done < skills-to-optimize.txt
      
      - name: Create Pull Request
        uses: peter-evans/create-pull-request@v5
        with:
          title: 'Auto-optimize skills to ${{ github.event.inputs.target_tier }}'
          body: 'Automated optimization results attached'
```

---

## Output Format

OPTIMIZE mode produces comprehensive output documenting the entire optimization process.

### JSON Output Schema

```json
{
  "optimization_version": "2.0.0",
  "optimization_id": "opt-20260331-001",
  "started_at": "2026-03-31T10:00:00Z",
  "completed_at": "2026-03-31T10:05:23Z",
  "skill": {
    "name": "my-skill",
    "version": "1.0.0",
    "file_path": "skills/my-skill.md",
    "file_hash_before": "sha256:abc123...",
    "file_hash_after": "sha256:def456..."
  },
  "configuration": {
    "target_tier": "SILVER",
    "target_score": 80.0,
    "max_rounds": 20,
    "min_improvement": 2.0,
    "plateau_rounds": 3,
    "focus_dimensions": null
  },
  "summary": {
    "initial_score": 65.2,
    "final_score": 82.5,
    "total_improvement": 17.3,
    "rounds_completed": 8,
    "convergence_state": "PLATEAU",
    "success": true,
    "target_reached": true,
    "escalated": false
  },
  "dimensions": {
    "system_design": {
      "weight": 0.20,
      "initial_score": 58,
      "final_score": 82,
      "improvement": 24,
      "improvement_pct": 41.4
    },
    "domain_knowledge": {
      "weight": 0.18,
      "initial_score": 72,
      "final_score": 85,
      "improvement": 13,
      "improvement_pct": 18.1
    },
    "workflow_definition": {
      "weight": 0.16,
      "initial_score": 65,
      "final_score": 78,
      "improvement": 13,
      "improvement_pct": 20.0
    },
    "error_handling": {
      "weight": 0.14,
      "initial_score": 45,
      "final_score": 71,
      "improvement": 26,
      "improvement_pct": 57.8
    },
    "examples": {
      "weight": 0.12,
      "initial_score": 80,
      "final_score": 85,
      "improvement": 5,
      "improvement_pct": 6.3
    },
    "metadata": {
      "weight": 0.10,
      "initial_score": 85,
      "final_score": 88,
      "improvement": 3,
      "improvement_pct": 3.5
    },
    "long_context": {
      "weight": 0.10,
      "initial_score": 70,
      "final_score": 75,
      "improvement": 5,
      "improvement_pct": 7.1
    }
  },
  "rounds": [
    {
      "round": 1,
      "started_at": "2026-03-31T10:00:00Z",
      "completed_at": "2026-03-31T10:00:45Z",
      "steps": {
        "READ": {"status": "success", "duration_ms": 120},
        "ANALYZE": {"status": "success", "duration_ms": 850},
        "CURATE": {"status": "success", "duration_ms": 340},
        "PLAN": {"status": "success", "duration_ms": 520},
        "IMPLEMENT": {"status": "success", "duration_ms": 0, "note": "No changes in round 1"},
        "VERIFY": {"status": "success", "duration_ms": 840},
        "HUMAN_REVIEW": {"status": "skipped", "note": "No changes to review"},
        "LOG": {"status": "success", "duration_ms": 45},
        "COMMIT": {"status": "success", "decision": "CONTINUE"}
      },
      "score_before": 65.2,
      "score_after": 65.2,
      "score_change": 0.0,
      "changes": [],
      "convergence": "IMPROVING",
      "notes": "Initial analysis round"
    },
    {
      "round": 2,
      "started_at": "2026-03-31T10:00:45Z",
      "completed_at": "2026-03-31T10:01:52Z",
      "steps": {
        "READ": {"status": "success", "duration_ms": 115},
        "ANALYZE": {"status": "success", "duration_ms": 820},
        "CURATE": {"status": "success", "duration_ms": 310},
        "PLAN": {"status": "success", "duration_ms": 480},
        "IMPLEMENT": {"status": "success", "duration_ms": 1250, "changes_count": 3},
        "VERIFY": {"status": "success", "duration_ms": 890},
        "HUMAN_REVIEW": {"status": "approved", "duration_ms": 0, "note": "Auto-approved (minor changes)"},
        "LOG": {"status": "success", "duration_ms": 52},
        "COMMIT": {"status": "success", "decision": "CONTINUE"}
      },
      "score_before": 65.2,
      "score_after": 71.8,
      "score_change": 6.6,
      "changes": [
        {
          "dimension": "error_handling",
          "type": "add_section",
          "description": "Added comprehensive error handling section with recovery strategies",
          "location": "§3 Error Handling",
          "impact": +15.0
        },
        {
          "dimension": "examples",
          "type": "add_example",
          "description": "Added error recovery example",
          "location": "§5 Examples",
          "impact": +2.0
        },
        {
          "dimension": "examples",
          "type": "add_example",
          "description": "Added edge case example for invalid input",
          "location": "§5 Examples",
          "impact": +2.0
        }
      ],
      "convergence": "IMPROVING",
      "notes": "Significant improvement in error handling"
    }
    // ... rounds 3-8
  ],
  "audit_log": {
    "log_file": ".skill-audit/optimization.jsonl",
    "entries": 8,
    "first_entry": "2026-03-31T10:00:00Z",
    "last_entry": "2026-03-31T10:05:23Z"
  },
  "recommendations": [
    {
      "priority": "HIGH",
      "dimension": "error_handling",
      "message": "Continue improving error handling - highest impact dimension",
      "potential_gain": "+10 points to reach GOLD"
    },
    {
      "priority": "MEDIUM",
      "dimension": "workflow_definition",
      "message": "Add workflow diagram for clarity",
      "potential_gain": "+5 points"
    }
  ],
  "next_steps": {
    "target_tier": "GOLD",
    "score_needed": 7.5,
    "estimated_rounds": 3,
    "suggested_focus": ["error_handling", "workflow_definition"]
  }
}
```

---

### Markdown Report Format

```markdown
# Optimization Report: my-skill v1.0.0

**Optimization ID**: opt-20260331-001  
**Started**: 2026-03-31T10:00:00Z  
**Completed**: 2026-03-31T10:05:23Z  
**Duration**: 5m 23s  

---

## Summary

| Metric | Value |
|--------|-------|
| Initial Score | 65.2 / 100 |
| Final Score | 82.5 / 100 |
| Improvement | +17.3 (+26.5%) |
| Target Tier | SILVER (80.0) |
| Target Reached | ✅ Yes |
| Rounds Completed | 8 / 20 |
| Convergence State | PLATEAU |

---

## Dimension Improvements

| Dimension | Weight | Initial | Final | Change | Change % |
|-----------|--------|---------|-------|--------|----------|
| System Design | 20% | 58 | 82 | +24 | +41.4% |
| Domain Knowledge | 18% | 72 | 85 | +13 | +18.1% |
| Workflow Definition | 16% | 65 | 78 | +13 | +20.0% |
| Error Handling | 14% | 45 | 71 | +26 | +57.8% |
| Examples | 12% | 80 | 85 | +5 | +6.3% |
| Metadata | 10% | 85 | 88 | +3 | +3.5% |
| Long-Context | 10% | 70 | 75 | +5 | +7.1% |

---

## Round History

### Round 1 — Analysis
- **Score**: 65.2 → 65.2 (+0.0)
- **Convergence**: IMPROVING
- **Changes**: None (initial analysis)

### Round 2 — Error Handling Focus
- **Score**: 65.2 → 71.8 (+6.6)
- **Convergence**: IMPROVING
- **Changes**:
  1. Added comprehensive error handling section (+15.0)
  2. Added error recovery example (+2.0)
  3. Added edge case example (+2.0)

### Round 3 — Workflow Improvements
- **Score**: 71.8 → 76.3 (+4.5)
- **Convergence**: IMPROVING
- **Changes**:
  1. Clarified step sequences (+3.0)
  2. Added decision branch documentation (+1.5)

### Round 4-7 — Continued Improvements
[Additional rounds...]

### Round 8 — Plateau Detected
- **Score**: 82.4 → 82.5 (+0.1)
- **Convergence**: PLATEAU
- **Changes**: Minor metadata updates
- **Action**: Optimization converged

---

## Recommendations for Next Tier (GOLD)

### HIGH Priority
1. **Error Handling** (+10 points potential)
   - Add timeout recovery strategies
   - Document retry logic

### MEDIUM Priority
2. **Workflow Definition** (+5 points potential)
   - Add visual workflow diagram
   - Document state transitions

**Estimated rounds to GOLD**: 3  
**Score needed**: 7.5 points

---

## Audit Trail

- **Log File**: `.skill-audit/optimization.jsonl`
- **Entries**: 8 rounds
- **Backup**: `skills/my-skill.md.bak.20260331`

To revert changes:
```bash
cp skills/my-skill.md.bak.20260331 skills/my-skill.md
```
```

---

## Integration

### As a Library

```python
from skill_framework.optimize import optimize_skill, OptimizationConfig

config = OptimizationConfig(
    target_tier="SILVER",
    max_rounds=20,
    min_improvement=2.0,
    focus_dimensions=None,  # Optimize all dimensions
    human_review_threshold=10.0  # Changes > 10 points need review
)

result = optimize_skill("path/to/skill.md", config)

if result.success:
    print(f"Optimized from {result.initial_score} to {result.final_score}")
    print(f"Convergence: {result.convergence_state}")
    
    # Access round-by-round details
    for round_data in result.rounds:
        print(f"Round {round_data.round}: {round_data.score_change:+.1f} points")
else:
    print(f"Optimization failed: {result.error_message}")
    if result.escalation:
        print(f"Escalation level: {result.escalation.level}")
```

### As a CLI Tool

```bash
# Basic optimization
skill-framework optimize -f skill.md

# With target tier
skill-framework optimize -f skill.md --target-tier GOLD

# With constraints
skill-framework optimize \
  -f skill.md \
  --max-rounds 15 \
  --focus-dimensions "error_handling,examples"

# Dry run (preview only)
skill-framework optimize -f skill.md --dry-run

# Resume previous optimization
skill-framework optimize -f skill.md --resume opt-20260331-001

# Batch optimization
skill-framework optimize -b "skills/*.md" --parallel 4
```

### Webhook Integration

```bash
# Trigger optimization via webhook
curl -X POST https://api.skill-framework.dev/optimize \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "skill_url": "https://raw.githubusercontent.com/user/repo/main/skill.md",
    "callback_url": "https://my-app.com/webhooks/optimization",
    "config": {
      "target_tier": "SILVER",
      "max_rounds": 20
    }
  }'
```

---

## Configuration File

Create `.skill-optimize.yaml` for project-wide defaults:

```yaml
# .skill-optimize.yaml
optimization:
  default_max_rounds: 20
  default_target_tier: SILVER
  min_improvement: 2.0
  plateau_rounds: 3
  human_review_threshold: 10.0
  
  dimension_weights:
    system_design: 0.20
    domain_knowledge: 0.18
    workflow_definition: 0.16
    error_handling: 0.14
    examples: 0.12
    metadata: 0.10
    long_context: 0.10
  
  convergence:
    volatile_threshold: 0.15
    plateau_threshold: 2.0
    diverging_threshold: -5.0
  
  escalation:
    level1_retries: 3
    level2_constraints: true
    level3_human_review: true
    level4_expert: true
```

---

## References

- **Framework Specification**: `../skill-framework.md`
- **CREATE Mode**: `../create/README.md`
- **EVALUATE Mode**: `../evaluate/README.md`
- **Dimension Definitions**: `dimensions.yaml`
- **Optimization Strategies**: `strategies.yaml`
- **Convergence Rules**: `convergence.yaml`

---

**End of OPTIMIZE Mode Documentation**
