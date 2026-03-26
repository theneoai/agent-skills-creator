# Agent-Skills-Creator Self-Optimization Capability Design

This document defines how agent-skills-creator implements self-optimization, including the self-optimization loop, multi-agent coordination mechanisms, and integration with existing skill-manager scripts.

---

## 1. Self-Optimization Loop

### 1.1 Loop Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      SELF-OPTIMIZATION LOOP                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────┐    ┌──────────────┐    ┌────────────────────┐    │
│  │  READ    │───▶│  IDENTIFY    │───▶│  MAKE IMPROVEMENT  │    │
│  │  State   │    │  Weakest     │    │  Targeted Fix      │    │
│  └──────────┘    │  Dimension   │    └─────────┬──────────┘    │
│                  └──────────────┘              │                 │
│                                                ▼                 │
│  ┌──────────┐    ┌──────────────┐    ┌────────────────────┐    │
│  │  LOG &   │◀───│  VERIFY      │◀───│  APPLY & TEST     │    │
│  │  REPEAT  │    │  Improvement │    │  Change            │    │
│  └──────────┘    └──────────────┘    └────────────────────┘    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2 Six-Dimension Scoring System

Inherited from skill-manager's scoring system:

| Dimension | Weight | Score Range | Core Metrics |
|-----------|--------|-------------|--------------|
| System Prompt | 20% | 0-10 | §1.1 Identity, §1.2 Framework, §1.3 Constraints |
| Domain Knowledge | 20% | 0-10 | Quantitative data, cases, benchmarks, framework references |
| Workflow | 20% | 0-10 | Stage definitions, Done/Fail criteria, decision points |
| Error Handling | 15% | 0-10 | Error scenarios, anti-patterns, recovery strategies, edge cases |
| Examples | 15% | 0-10 | Example count, Input/Output, verification steps |
| Metadata | 10% | 0-10 | name, description, license, version, author |

### 1.3 Loop Execution Flow

#### Step 1: READ — Read Current State

```bash
# Use score.sh to read current score
./scripts/skill-manager/score.sh SKILL.md

# Output example:
#   System Prompt        8/10  (×0.20)
#   Domain Knowledge     6/10  (×0.20)  ⚠generic-content
#   Workflow            7/10  (×0.20)
#   Error Handling      5/10  (×0.15)  ⚠no-recovery
#   Examples            4/10  (×0.15)  ⚠no-examples
#   Metadata           10/10  (×0.10)
#
#   Text Score (heuristic):  6.5/10
```

#### Step 2: IDENTIFY — Identify Weakest Dimension

```bash
# Identify dimensions below threshold
WEAKEST=$(echo "$SCORE_OUTPUT" | grep -E "^  [A-Za-z].* [0-9]+\.[0-9]/10" | \
  awk '{print $1, $2}' | sort -k2 -n | head -1 | awk '{print $1}')
```

Priority rules:
1. Dimensions with score < 6.0 are prioritized
2. High-weight dimensions are prioritized (System Prompt > Domain > Workflow)
3. When multiple dimensions tie, rotate by loop round

#### Step 3: MAKE IMPROVEMENT — Targeted Fix

Call corresponding improvement function based on weakest dimension:

```bash
improve_dimension() {
  local weakest="$1"
  case "$weakest" in
    "System")
      improve_system_prompt
      ;;
    "Domain")
      improve_domain_knowledge
      ;;
    "Workflow")
      improve_workflow
      ;;
    "Error")
      improve_error_handling
      ;;
    "Examples")
      improve_examples
      ;;
    "Metadata")
      improve_metadata
      ;;
  esac
}
```

Specific improvement strategies:

**System Prompt Improvement:**
- Add §1.1 Identity (Role, Expertise, Boundary)
- Add §1.2 Framework (Architecture, Tools, Memory)
- Add §1.3 Constraints (Never, Always rules)

**Domain Knowledge Improvement:**
- Add quantitative metrics (e.g., >95% accuracy, <200ms latency)
- Add industry benchmarks and KPIs
- Add framework references (ReAct, CoT, ToT)

**Workflow Improvement:**
- Add Done/Fail criteria
- Add decision points (if-then-else)
- Structure stage definitions

**Error Handling Improvement:**
- Add error recovery strategies
- Add anti-pattern warnings
- Add edge case analysis

**Examples Improvement:**
- Add Input/Output examples
- Add verification steps
- Add real-world scenario cases

**Metadata Improvement:**
- Fill missing fields
- Normalize version format
- Clean up placeholders

#### Step 4: VERIFY — Verify Improvement

```bash
# Verify improvement effect
NEW_SCORE=$(./scripts/skill-manager/score.sh SKILL.md | grep "Text Score" | awk '{print $4}')

if compare "$NEW_SCORE" ">" "$OLD_SCORE"; then
  STATUS="keep"
else
  STATUS="discard"  # rollback
fi
```

#### Step 5: LOG & REPEAT — Log and Repeat

```bash
# Log to results.tsv
echo -e "$round\t$NEW_SCORE\t$DELTA\t$STATUS\t$WEAKEST\t$IMPROVEMENT" >> results.tsv

# Continue next round or terminate
if compare "$NEW_SCORE" ">=" "9.5"; then
  echo "★★★ EXEMPLARY standard reached"
  break
fi
```

### 1.4 Termination Conditions

Loop terminates when any of the following conditions are met:

| Condition | Description |
|-----------|-------------|
| Score ≥ 9.5 | EXEMPLARY level reached |
| 5 consecutive rounds without improvement | Stuck in local optimum |
| Maximum rounds reached (default 100) | Resource limit |
| All dimensions ≥ 8.0 | CERTIFIED standard reached |

---

## 2. Multi-Agent Coordination

### 2.1 Agent Types

| Agent | Responsibility | Focus Dimension | Output |
|-------|----------------|-----------------|--------|
| **Security Agent** | Security review | Anti-patterns, injection risks, data leakage | Security report |
| **Trigger Agent** | Trigger analysis | Pattern recognition accuracy | Trigger coverage |
| **Runtime Agent** | Runtime verification | Actual execution effect | Runtime score |
| **Quality Agent** | Quality assessment | Six-dimension composite score | Quality report |
| **EdgeCase Agent** | Edge case analysis | Boundary conditions, exception handling | Edge case checklist |

### 2.2 Parallel Execution Architecture

```
                     ┌─────────────────┐
                     │  Orchestrator   │
                     └────────┬────────┘
                              │
           ┌──────────────────┼──────────────────┐
           │                  │                  │
           ▼                  ▼                  ▼
    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
    │  Security   │    │   Trigger   │    │   Runtime   │
    │   Agent     │    │    Agent    │    │    Agent    │
    └──────┬──────┘    └──────┬──────┘    └──────┬──────┘
           │                  │                  │
           ▼                  ▼                  ▼
    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
    │   Quality   │    │  EdgeCase   │    │  (Results   │
    │    Agent    │    │    Agent    │    │  Aggregation│
    └──────┬──────┘    └──────┬──────┘    └─────────────┘
           │                  │
           └────────┬─────────┘
                    ▼
             ┌─────────────┐
             │ Aggregator   │
             └─────────────┘
```

### 2.3 Agent Execution Protocols

#### 2.3.1 Security Agent

```bash
# Security review protocol
security_check() {
  local skill_file="$1"
  
  # Check injection risks
  check_injection_risks "$skill_file"
  
  # Check data exposure
  check_data_exposure "$skill_file"
  
  # Check privilege escalation
  check_privilege_escalation "$skill_file"
  
  # Check path traversal
  check_path_traversal "$skill_file"
  
  # Output security score (0-10)
  echo "SECURITY_SCORE: $score"
}
```

#### 2.3.2 Trigger Agent

```bash
# Trigger analysis protocol
trigger_analysis() {
  local skill_file="$1"
  
  # Parse four-pattern triggers
  parse_triggers "CREATE" "$skill_file"
  parse_triggers "EVALUATE" "$skill_file"
  parse_triggers "RESTORE" "$skill_file"
  parse_triggers "TUNE" "$skill_file"
  
  # Test trigger accuracy
  test_trigger_accuracy "$skill_file"
  
  # Output coverage report
  echo "TRIGGER_COVERAGE: $coverage%"
}
```

#### 2.3.3 Runtime Agent

```bash
# Runtime validation protocol
runtime_validation() {
  local skill_file="$1"
  
  # Identity consistency check
  check_identity_immersion
  
  # Framework execution test
  test_framework_execution
  
  # Measure output actionability
  measure_output_actionability
  
  # Knowledge accuracy verification
  verify_knowledge_accuracy
  
  # Long conversation stability
  test_conversation_stability
  
  # Output runtime score
  echo "RUNTIME_SCORE: $score"
}
```

#### 2.3.4 Quality Agent

```bash
# Quality assessment protocol
quality_assessment() {
  local skill_file="$1"
  
  # Run text scoring
  run_text_scoring
  
  # Run runtime scoring
  run_runtime_scoring
  
  # Calculate variance
  calculate_variance
  
  # Output composite score
  echo "QUALITY_SCORE: $score"
  echo "VARIANCE: $variance"
}
```

#### 2.3.5 EdgeCase Agent

```bash
# Edge case analysis protocol
edge_case_analysis() {
  local skill_file="$1"
  
  # Empty input test
  test_empty_input
  
  # Extreme value test
  test_extreme_values
  
  # Contradictory input test
  test_contradictory_input
  
  # Role confusion test
  test_role_confusion
  
  # Resource limit test ($0 budget, 1 day timeline)
  test_resource_limits
  
  # Output edge case checklist
  echo "EDGE_CASES: $count"
  echo "RESILIENCE_SCORE: $score"
}
```

### 2.4 Result Aggregation Mechanism

#### 2.4.1 Aggregation Algorithm

```bash
aggregate_findings() {
  local security_report="$1"
  local trigger_report="$2"
  local runtime_report="$3"
  local quality_report="$4"
  local edgecase_report="$5"
  
  # Weighted aggregation
  FINAL_SCORE=$(python3 - << PYTHON
security = float("$security_report"['score']) * 0.15
trigger = float("$trigger_report"['coverage']) * 0.15
runtime = float("$runtime_report"['score']) * 0.25
quality = float("$quality_report"['score']) * 0.30
edgecase = float("$edgecase_report"['resilience']) * 0.15
total = security + trigger + runtime + quality + edgecase
print(f"{total:.2f}")
PYTHON
)
  
  echo "AGGREGATED_SCORE: $FINAL_SCORE"
}
```

#### 2.4.2 Priority Matrix

| Issue Type | Priority |处理时限 |
|------------|----------|---------|
| Security vulnerability | P0 | Fix immediately |
| Runtime crash | P1 | Within 24 hours |
| Trigger misalignment > 20% | P2 | Within 48 hours |
| Quality score < 7.0 | P3 | Within 72 hours |
| Edge case failure | P4 | Next iteration |

### 2.5 Conflict Resolution Mechanism

#### 2.5.1 Conflict Types

| Conflict Type | Description | Resolution Strategy |
|---------------|-------------|---------------------|
| Score conflict | Multiple agents score same dimension differently | Take average, higher-weight agent takes precedence |
| Priority conflict | Multiple issues compete for same resource | Sort by P0>P1>P2>P3>P4 |
| Improvement suggestion conflict | Different agents suggest contradictory changes | Security > Runtime > Quality |

#### 2.5.2 Conflict Resolution Algorithm

```bash
resolve_conflict() {
  local agent_a="$1"
  local agent_b="$2"
  local dimension="$3"
  
  # Get scores and suggestions from both agents
  score_a=$(get_agent_score "$agent_a" "$dimension")
  score_b=$(get_agent_score "$agent_b" "$dimension")
  advice_a=$(get_agent_advice "$agent_a" "$dimension")
  advice_b=$(get_agent_advice "$agent_b" "$dimension")
  
  # Higher-weight agent takes precedence
  if [[ "$agent_a" == "Security" ]] || [[ "$agent_b" == "Security" ]]; then
    echo "$advice_a"  # Security suggestion takes precedence
    return
  fi
  
  # Take conservative suggestion (方案 that doesn't introduce new risk)
  if [[ ${#advice_a} -lt ${#advice_b} ]]; then
    echo "$advice_a"
  else
    echo "$advice_b"
  fi
}
```

---

## 3. Integration with Existing Scripts

### 3.1 Script Mapping Table

| Script Path | Function | Usage in Self-Optimization |
|-------------|----------|----------------------------|
| `scripts/skill-manager/score.sh` | Six-dimension text scoring | Loop steps 1, 4: read/verify state |
| `scripts/skill-manager/score-v2.sh` | Improved scoring | Backup scoring engine |
| `scripts/skill-manager/validate.sh` | Format validation | Ensure improvements don't break format |
| `scripts/skill-manager/tune.sh` | AI-driven optimization | Directly execute optimization loop |
| `scripts/skill-manager/feedback.sh` | Production feedback collection | Collect real usage data |
| `scripts/skill-manager/runtime-validate.sh` | Runtime verification | Runtime Agent implementation |
| `scripts/skill-manager/edge-case-check.sh` | Edge case testing | EdgeCase Agent implementation |
| `scripts/skill-manager/certify.sh` | Full certification | Final certification after optimization |
| `scripts/skill-manager/eval.sh` | Dual-track evaluation | Quality Agent implementation |
| `scripts/skill-manager/lib/weights.sh` | Weight constants | Unified weight system |

### 3.2 Integration Workflows

#### 3.2.1 Quick Tune Mode

```bash
# Use tune.sh for quick optimization
./scripts/skill-manager/tune.sh agent-skills-creator/SKILL.md 20

# Output example:
#   Initial: 7.5
#   Round 5: 8.1 (Δ+0.6) [keep] | weakest: Examples
#   Round 10: 8.4 (Δ+0.3) [keep] | weakest: Error Handling
#   ...
#   Final: 9.2
```

#### 3.2.2 Full Optimization Mode

```bash
# 1. Validate current state
./scripts/skill-manager/validate.sh agent-skills-creator/SKILL.md

# 2. Score current quality
./scripts/skill-manager/score.sh agent-skills-creator/SKILL.md

# 3. Runtime verification
./scripts/skill-manager/runtime-validate.sh agent-skills-creator/SKILL.md

# 4. Run optimization loop (max 100 rounds)
./scripts/skill-manager/tune.sh agent-skills-creator/SKILL.md 100

# 5. Edge case check
./scripts/skill-manager/edge-case-check.sh

# 6. Collect feedback
./scripts/skill-manager/feedback.sh

# 7. Final certification
./scripts/skill-manager/certify.sh agent-skills-creator/SKILL.md
```

#### 3.2.3 Multi-Agent Mode

```bash
# Start multi-agent parallel optimization
./scripts/skill-manager/score-multi.sh agent-skills-creator/SKILL.md

# This script will:
# 1. Start multiple scoring instances in parallel
# 2. Aggregate results
# 3. Identify consensus weaknesses
# 4. Generate improvement suggestions
```

### 3.3 Self-Optimization Entry Interface

```bash
# Self-optimization entry function
self_optimize() {
  local skill_file="$1"
  local mode="${2:-standard}"  # quick | standard | deep
  
  echo "Starting self-optimization: $skill_file (mode: $mode)"
  
  # Read current state
  CURRENT_SCORE=$(bash "$SCRIPT_DIR/score.sh" "$skill_file" | grep "Text Score" | awk '{print $4}')
  echo "Current score: $CURRENT_SCORE"
  
  case "$mode" in
    "quick")
      ROUNDS=10
      ;;
    "standard")
      ROUNDS=50
      ;;
    "deep")
      ROUNDS=100
      ;;
  esac
  
  # Execute optimization loop
  bash "$SCRIPT_DIR/tune.sh" "$skill_file" "$ROUNDS"
  
  # Verify results
  NEW_SCORE=$(bash "$SCRIPT_DIR/score.sh" "$skill_file" | grep "Text Score" | awk '{print $4}')
  echo "Post-optimization score: $NEW_SCORE"
  
  # Variance check
  bash "$SCRIPT_DIR/runtime-validate.sh" "$skill_file"
}
```

### 3.4 Automated Scheduling

```bash
# cron scheduling example (run at 3 AM daily)
# 0 3 * * * /path/to/scripts/skill-manager/tune.sh /Users/lucas/.agents/skills/agent-skills-creator/SKILL.md 20 >> /var/log/self-optimize.log 2>&1

# Or use launchd (macOS)
# ~/Library/LaunchAgents/com.agent-skills-creator.optimize.plist
```

---

## 4. Key File Paths

```
agent-skills-creator/
├── SKILL.md                          # Main skill file
├── scripts/
│   └── skill-manager/
│       ├── score.sh                  # Text scoring
│       ├── score-v2.sh               # Improved scoring
│       ├── score-multi.sh            # Multi-agent scoring
│       ├── tune.sh                   # AI optimization loop
│       ├── validate.sh               # Format validation
│       ├── feedback.sh               # Feedback collection
│       ├── runtime-validate.sh        # Runtime verification
│       ├── edge-case-check.sh        # Edge case checking
│       ├── certify.sh                # Full certification
│       ├── eval.sh                   # Dual-track evaluation
│       └── lib/
│           ├── weights.sh            # Weight constants
│           └── trigger_patterns.sh   # Trigger patterns
└── references/
    └── SELF_OPTIMIZATION.md          # This document
```

---

## 5. Scoring and Certification Standards

### 5.1 Scoring Levels

| Level | Score Range | Description |
|-------|-------------|-------------|
| EXEMPLARY ★★★ | ≥ 9.5 | Outstanding, can serve as benchmark |
| EXEMPLARY ✓ | ≥ 9.0 | Excellent, near benchmark |
| CERTIFIED ✓ | ≥ 8.0 | Qualified, production-ready |
| GOOD | ≥ 7.0 | Good, minor improvements needed |
| ACCEPTABLE | ≥ 6.0 | Acceptable, needs improvement |
| BELOW STANDARD | < 6.0 | Below standard, major fixes needed |

### 5.2 Certification Conditions

```
CERTIFIED = Text ≥ 8.0 AND Runtime ≥ 8.0 AND Variance < 1.0
```

### 5.3 Optimization Goals

| Phase | Target Score | Description |
|-------|--------------|-------------|
| Initial | 6.0 - 7.0 | Basic usable |
| First optimization | 8.0 | Reach CERTIFIED |
| Second optimization | 9.0 | Reach EXEMPLARY |
| Final goal | 9.5 | Reach benchmark level |

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-03-27 | Initial version |
