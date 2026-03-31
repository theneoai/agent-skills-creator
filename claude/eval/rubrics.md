# Evaluation Rubrics

> **Purpose**: Scoring rubrics used by EVALUATE mode in `claude/skill-framework.md §4`
> **Metrics**: F1, MRR, Trigger Accuracy, Structure Score

---

## Overall Score Calculation

```
Overall Score = weighted_sum(dimension scores)

Dimensions and weights:
  Trigger Coverage    25%  →  TriggerScore (0–100)
  Structure           20%  →  StructureScore (0–100)
  Output Clarity      20%  →  OutputScore (0–100)
  Security Baseline   20%  →  SecurityScore (0–100)
  Quality Gates       15%  →  QualityGateScore (0–100)

Overall = 0.25*T + 0.20*S + 0.20*O + 0.20*Sec + 0.15*Q

Certification tiers:
  GOLD    ≥ 90
  SILVER  ≥ 80
  BRONZE  ≥ 70
  FAIL    < 70
```

---

## Dimension 1 — Trigger Coverage (25%)

**What**: Do trigger keywords cover all modes, in both EN and ZH?

| Check | Points |
|-------|--------|
| Primary EN trigger present for each mode | +10 per mode (max 30) |
| Primary ZH trigger present for each mode | +10 per mode (max 30) |
| Secondary / context triggers present | +5 per mode (max 20) |
| Negative / anti-trigger patterns defined | +10 |
| Confidence scoring formula documented | +10 |

**Score**: sum / max_possible × 100

**F1 Mapping**:
- TriggerScore ≥ 90 → F1 = 0.93–1.00
- TriggerScore 80–89 → F1 = 0.90–0.92
- TriggerScore 70–79 → F1 = 0.85–0.89 (FAIL threshold)
- TriggerScore < 70 → F1 < 0.85 (auto-route to OPTIMIZE)

**MRR Mapping**:
- Primary trigger at rank 1 per mode → MRR = 1.0 for that mode
- Primary trigger at rank 2 → MRR = 0.5
- Primary trigger at rank ≥ 3 → MRR = 0.33

---

## Dimension 2 — Structure Completeness (20%)

**What**: Are all required sections present and non-empty?

### Required Sections Checklist

| Section | Required For | Points |
|---------|-------------|--------|
| `§ Identity` (name, role, purpose) | All types | 15 |
| `§ Loop / Phase sequence` | All types | 10 |
| `§ Mode definitions` (one per mode) | All types | 10 per mode |
| `§ Quality Gates` (thresholds stated) | All types | 15 |
| `§ Security Baseline` | All types | 15 |
| `§ Usage Examples` (≥ 2) | All types | 10 |
| `§ Red Lines` | All types | 10 |
| YAML frontmatter (name, version, tags, interface) | All types | 15 |

**Score**: present_sections / total_required × 100

### Per-Type Additional Checks

| Type | Extra Required Section | Points |
|------|----------------------|--------|
| api-integration | API spec (base_url, auth_method, endpoints) | +10 |
| data-pipeline | Pipeline stages diagram, schema definitions | +10 |
| workflow-automation | Workflow steps table, rollback actions | +10 |

---

## Dimension 3 — Output Clarity (20%)

**What**: Is the output format for each mode clearly defined?

| Check | Points |
|-------|--------|
| Output format specified per mode (e.g. JSON, text, table) | 20 per mode |
| Exit criteria stated per mode | 15 per mode |
| Error output format specified | 15 |
| Example output shown in Usage Examples | 15 |
| Output schema or field list present (data/API types) | 15 |

**Score**: sum / max_possible × 100

---

## Dimension 4 — Security Baseline (20%)

**What**: Does the skill explicitly address the four CWE red lines?

| Check | Points | Auto-fail? |
|-------|--------|-----------|
| CWE-798: no hardcoded credentials, env-var pattern documented | 25 | YES — 0 points if violated |
| CWE-89: input sanitization mentioned for query parameters | 25 | YES |
| CWE-79: output escaping mentioned for rendered content | 25 | NO |
| CWE-94: eval/exec prohibition mentioned or not applicable | 25 | NO |
| Additional CWE coverage (e.g. CWE-22, CWE-78) | +5 each (max 20) | — |

**Score** (base 100):
- All 4 base checks pass → score = 100 − penalties
- Any auto-fail check violated → SecurityScore = 0 → ABORT

**Penalty Table**:

| Finding | Deduction |
|---------|-----------|
| Auto-fail CWE pattern present in skill text | −100 (ABORT) |
| CWE section missing entirely | −40 |
| CWE section present but content is boilerplate only (no specifics) | −15 |
| Specific field names not listed for CWE-89/CWE-79 | −10 |

---

## Dimension 5 — Quality Gate Definitions (15%)

**What**: Are quality thresholds stated explicitly and measurably?

| Check | Points |
|-------|--------|
| F1 threshold stated (numeric) | 20 |
| MRR threshold stated (numeric) | 20 |
| Trigger accuracy threshold stated | 15 |
| Thresholds meet framework minimums (F1 ≥ 0.90, MRR ≥ 0.85) | 20 |
| Measurement method referenced (rubrics, benchmarks) | 15 |
| OPTIMIZE / escalation action on threshold breach documented | 10 |

**Score**: sum / 100

---

## F1 Score Formula

```
For a skill evaluation over a test set:

  For each test case:
    predicted_mode = mode router output
    actual_mode    = ground truth label

  precision = TP / (TP + FP)
  recall    = TP / (TP + FN)
  F1        = 2 * precision * recall / (precision + recall)

  Where TP = correct mode prediction, FP = wrong mode predicted,
        FN = correct mode not predicted
```

---

## MRR Score Formula

```
For N test cases, each with a ranked list of candidate modes:

  MRR = (1/N) * Σ (1 / rank_of_first_correct_mode)

  rank_of_first_correct_mode:
    = 1 if correct mode is top prediction
    = 2 if correct mode is second prediction
    = 0 (excluded) if correct mode not in top-3

  MRR ≥ 0.85 required for CERTIFIED status
```

---

## Trigger Accuracy Formula

```
trigger_accuracy = correct_triggers / total_trigger_attempts

  correct_trigger: user input → correct mode in ≤ 1 clarification turn
  total_trigger_attempts: all test inputs in claude/eval/benchmarks.md

  trigger_accuracy ≥ 0.90 required
```

---

## Evaluation Report Format

```
SKILL EVALUATION REPORT
=======================
Skill: <name> v<version>
Evaluated: <ISO-8601 timestamp>
Evaluator: skill-framework v1.0.0

DIMENSION SCORES
  Trigger Coverage:    XX / 100  (weight 25%)
  Structure:           XX / 100  (weight 20%)
  Output Clarity:      XX / 100  (weight 20%)
  Security Baseline:   XX / 100  (weight 20%)
  Quality Gates:       XX / 100  (weight 15%)

COMPUTED METRICS
  F1:               0.XX  threshold 0.90  [PASS|FAIL]
  MRR:              0.XX  threshold 0.85  [PASS|FAIL]
  Trigger Accuracy: 0.XX  threshold 0.90  [PASS|FAIL]
  Overall Score:    XX    tier [GOLD|SILVER|BRONZE|FAIL]

SECURITY SCAN
  CWE-798: [CLEAR|VIOLATION]
  CWE-89:  [CLEAR|VIOLATION]
  CWE-79:  [CLEAR|VIOLATION]
  CWE-94:  [CLEAR|N/A]

ISSUES
  ERROR:   <list of blocking issues>
  WARNING: <list of advisory issues>
  INFO:    <list of informational notes>

VERDICT
  CERTIFIED | TEMP_CERT | HUMAN_REVIEW | ABORT
  Next action: <recommendation>
```

---

## Quick-Pass Heuristics (Fast Path)

Before full scoring, apply these heuristics. If all pass, confidence in PASS is high:

1. YAML frontmatter present with `name`, `version`, `interface` → +quick_pass
2. At least 3 mode sections (`§N`) → +quick_pass
3. "Red Lines" or "严禁" present → +quick_pass
4. At least 2 code-block examples → +quick_pass
5. "Quality Gates" table with numeric thresholds → +quick_pass

If 5/5 quick_pass → skip detailed scoring, run security scan only.
If < 3/5 quick_pass → run full dimensional scoring.
