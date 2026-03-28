# Metrics System

> 6-Dimension Scoring Rubric for Text Quality Assessment

---

## Dimension Weights

| Dimension | Weight | Floor | Max Score |
|-----------|--------|-------|-----------|
| System Prompt | 20% | 6.0 | 10 |
| Domain Knowledge | 20% | 6.0 | 10 |
| Workflow | 20% | 6.0 | 10 |
| Error Handling | 15% | 5.0 | 10 |
| Examples | 15% | 5.0 | 10 |
| Metadata | 10% | 5.0 | 10 |

---

## Excellence Criteria

### System Prompt (20%)

**Required Elements**:
- §1.1 Identity - Role definition
- §1.2 Framework - Decision framework
- §1.3 Thinking - Thinking patterns

**Excellence**: All three sections present with explicit constraints and red lines.

### Domain Knowledge (20%)

**Required Elements**:
- Specific data (benchmarks, percentages)
- Named frameworks (McKinsey 7-S, TOGAF, etc.)
- Quantified results ("16.7% error reduction")

**Excellence**: ≥10 specific data points, ≥3 named frameworks.

### Workflow (20%)

**Required Elements**:
- 4-6 distinct phases
- Done criteria per phase
- Fail criteria per phase

**Excellence**: Decision trees, conditional logic, explicit transitions.

### Error Handling (15%)

**Required Elements**:
- ≥5 named failure modes
- Recovery strategies
- Anti-patterns documented

**Excellence**: Edge cases addressed, circuit breakers, fallback logic.

### Examples (15%)

**Required Elements**:
- ≥5 scenarios with input/output/verification
- Realistic contexts
- Edge cases included

**Excellence**: Diverse scenarios, multi-turn conversations, boundary conditions.

### Metadata (10%)

**Required Elements**:
- agentskills-spec compliant
- Description triggers correct behavior
- Version, author, license present

**Excellence**: Comprehensive triggers, proper categorization.

---

## Scoring Levels

| Score | Level | Description |
|-------|-------|-------------|
| 9-10 | Exemplary | Exceeds expectations, innovative approach |
| 7-8 | Proficient | Meets all requirements, solid execution |
| 5-6 | Developing | Missing some elements, needs improvement |
| 3-4 | Beginner | Significant gaps, basic structure only |
| 0-2 | Inadequate | Missing critical elements |

---

## Composite Score Calculation

```
Text Score = (System × 0.20) + (Domain × 0.20) + (Workflow × 0.20) 
           + (Error × 0.15) + (Examples × 0.15) + (Metadata × 0.10)
```

**Certification Threshold**: Text Score ≥ 8.0
