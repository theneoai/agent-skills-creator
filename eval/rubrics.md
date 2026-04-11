# Evaluation Rubrics

> **Purpose**: 4-phase 1000-point scoring pipeline used by EVALUATE mode.
> **Load**: When §8 (EVALUATE Mode) of `claude/skill-writer.md` is accessed.
> **Main doc**: `claude/skill-writer.md §8`

---

## §1  Pipeline Overview

```
Total: 1000 points

Phase 1 — Parse & Validate   (0–100 pts)   Heuristic, no LLM
Phase 2 — Text Quality       (0–300 pts)   Static analysis, Pass 1
Phase 3 — Runtime Testing    (0–400 pts)   Benchmark tests, Pass 2
Phase 4 — Certification      (0–200 pts)   Variance + security + gates, Pass 3

Variance formula:  variance = | phase2/3 − phase3/4 |
```

---

## §2  Certification Tiers

| Tier | Min Score | Max Variance | Phase 2 Min | Phase 3 Min |
|------|-----------|-------------|------------|------------|
| **PLATINUM** | ≥ 950 | < 10 | ≥ 270 | ≥ 360 |
| **GOLD** | ≥ 900 | < 15 | ≥ 255 | ≥ 340 |
| **SILVER** | ≥ 800 | < 20 | ≥ 225 | ≥ 300 |
| **BRONZE** | ≥ 700 | < 30 | ≥ 195 | ≥ 265 |
| **FAIL** | < 700 | any | — | — |

**Variance interpretation**: High variance means the artifact "looks good on paper but
fails runtime" (Phase2 >> Phase3) or "passes tests but is poorly written" (Phase3 >> Phase2).
Both indicate quality inconsistency and cap the certification tier.

---

## §3  Phase 1 — Parse & Validate (0–100 pts)

Heuristic checks only. Fast, no LLM.

| Check | Points | Notes |
|-------|--------|-------|
| YAML frontmatter present | 10 | Must have at least `name`, `version` |
| `name` field present and non-empty | 5 | |
| `version` field follows semver | 5 | Pattern: `N.N.N` |
| `interface.modes` array present | 5 | |
| `tags` array with ≥ 2 entries | 5 | |
| ≥ 3 `## §N` sections | 10 | Identity, Loop, at least one mode |
| Identity section present (name/role/purpose) | 10 | |
| Red Lines / 严禁 section present | 10 | |
| Quality Gates section with numeric thresholds | 15 | Thresholds must be numbers |
| No `{{PLACEHOLDER}}` tokens remaining | 15 | Any remaining = hard deduction |
| No TODO / FIXME markers | 5 | Advisory |
| File size reasonable (< 500 lines) | 5 | > 500 lines: advisory warning |

**Hard deduction**: If `{{PLACEHOLDER}}` found → Phase1 score capped at 60, WARNING issued.

---

## §4  Phase 2 — Text Quality (0–300 pts)

Static analysis across **7 sub-dimensions** (canonical schema: `builder/src/config.js SCORING.dimensions`).
Scored in Pass 1.

| Sub-Dimension | Max | Weight | What to Check |
|---------------|-----|--------|--------------|
| **System Design** | 60 | 20% | Clear identity, role hierarchy, design pattern named |
| **Domain Knowledge** | 60 | 20% | Template-specific accuracy (API fields, pipeline stages, workflow steps) |
| **Workflow Definition** | 45 | 15% | Phase sequence complete, exit criteria per phase, loop gates explicit |
| **Error Handling** | 45 | 15% | Recovery paths named, escalation triggers defined, timeout values set |
| **Examples** | 45 | 15% | ≥ 2 examples, both EN and ZH or bilingual triggers, output shown |
| **Security Baseline** | 30 | 10% | Security section present, CWE reference, no hardcoded-credential patterns in text |
| **Metadata Quality** | 15 | 5% | YAML complete, version semver, author, dates, description bilingual |

> **Note on Security dimension**: Phase 4 (Certification) additionally runs an automated CWE pattern
> scan. Phase 2 checks whether security *documentation* in the skill text is adequate; Phase 4
> checks the generated skill content itself. Both deductions are applied independently.

### Scoring Rubric per Sub-Dimension

| Score Band | Meaning |
|------------|---------|
| 90–100% | Exceptional: specific, measurable, complete, no vagueness |
| 75–89% | Good: mostly complete, minor gaps in specificity |
| 60–74% | Adequate: structure present but some sections thin or vague |
| 40–59% | Weak: significant gaps, missing key elements |
| 0–39% | Poor: section missing or essentially content-free |

### Pass 1 Scoring Instructions

For each sub-dimension, produce:
```json
{
  "sub_dimension": "<name>",
  "score": 0,
  "max": 60,
  "evidence": "<what was found>",
  "gaps": ["<specific gap 1>", "<specific gap 2>"],
  "severity": "ERROR|WARNING|INFO"
}
```

---

## §5  Phase 3 — Runtime Testing (0–400 pts)

Executed against benchmark test cases (`claude/eval/benchmarks.md`). Scored in Pass 2.

| Test Category | Max | What Is Tested |
|---------------|-----|----------------|
| **Trigger Routing Accuracy** | 120 | Mode router predicts correct mode for positive cases |
| **Bilingual Trigger Coverage** | 80 | Both EN and ZH inputs route correctly |
| **Negative/Edge Cases** | 60 | Ambiguous inputs handled; negatives filtered; fallback activated |
| **Output Contract** | 60 | Each mode's output format matches stated spec |
| **Error Handling Runtime** | 50 | Error cases produce correct recovery output |
| **Security Boundary Tests** | 30 | Injection/traversal inputs rejected gracefully |

### F1 and MRR Computation

```
F1 = 2 × precision × recall / (precision + recall)
  precision = TP / (TP + FP)
  recall    = TP / (TP + FN)

MRR = (1/N) × Σ (1 / rank_of_first_correct_mode)
  rank = 1 if correct mode is top prediction
  rank = 2 if second
  rank = 0 (excluded from sum) if correct mode not in top 3

Trigger accuracy = correct_triggers / total_trigger_test_cases
```

### Phase 3 Score Mapping

```
trigger_routing: correct% × 120
bilingual:       (EN_correct + ZH_correct) / (EN_total + ZH_total) × 80
negative_cases:  correct_negatives / total_negatives × 60
output_contract: correct_format% × 60
error_handling:  correct_recovery% × 50
security_boundary: all_rejected ? 30 : rejected/total × 30
```

### Pass 2 Test Execution

Run each test case and record:
```json
{
  "test_id": "CF-C-01",
  "input": "create a new skill for querying databases",
  "expected_mode": "CREATE",
  "predicted_mode": "CREATE",
  "confidence": 0.92,
  "correct": true,
  "rank": 1
}
```

---

## §6  Phase 4 — Certification (0–200 pts)

Scored in Pass 3 (Reconciliation). Integrates all previous phases.

| Check | Max | How Scored |
|-------|-----|-----------|
| **Variance gate** | 40 | variance<10→40, <15→30, <20→20, <30→10, ≥30→0 |
| **Security scan** | 60 | P0 clear→40, P1 clear→20; P0 violation→0+ABORT; each P1→−10 |
| **F1 gate** | 40 | F1≥0.90→40, ≥0.85→25, ≥0.80→10, <0.80→0 |
| **MRR gate** | 30 | MRR≥0.85→30, ≥0.80→20, ≥0.75→10, <0.75→0 |
| **Consistency** | 30 | All passes agree on tier→30, CLEAR→20, REVISED→10, UNRESOLVED→0 |

**Phase 4 hard rules**:
- P0 security violation → Phase 4 = 0, overall = FAIL, status = ABORT
- F1 < 0.80 → Phase 4 capped at 80 points regardless of other scores
- UNRESOLVED review outcome → Phase 4 capped at 120 points

---

## §7  LEAN Fast Path

Before running Phase 1–4, apply LEAN heuristics (§6 of skill-writer.md).

**Quick-Pass**: If lean_score ≥ 450 (GOLD proxy):
- Run only Phase 1 + security scan
- If Phase 1 ≥ 90 AND security CLEAR → issue LEAN_CERT, skip Phase 2–4
- Schedule full Phase 2–4 within 24 h

**Full Pipeline**: If lean_score 300–449 OR any quick-pass check fails → run all 4 phases.

---

## §8  Evaluation Report Template

```
SKILL EVALUATION REPORT
=======================
Skill:      <name> v<version>
Evaluated:  <ISO-8601>
Evaluator:  skill-writer v2.1.0

PHASE SCORES
  Phase 1 — Parse & Validate:   XX / 100
  Phase 2 — Text Quality:       XX / 300
    System Design:     XX/60   Error Handling: XX/45
    Domain Knowledge:  XX/60   Examples:       XX/45
    Workflow:          XX/60   Metadata:       XX/30
  Phase 3 — Runtime Testing:    XX / 400
    Trigger Routing:   XX/120  Output Contract:   XX/60
    Bilingual:         XX/80   Error Handling RT: XX/50
    Negative/Edge:     XX/60   Security Boundary: XX/30
  Phase 4 — Certification:      XX / 200
    Variance Gate:    XX/40    F1 Gate:    XX/40
    Security Scan:    XX/60    MRR Gate:   XX/30
    Consensus:        XX/30

TOTAL SCORE:     XXX / 1000
VARIANCE:        X.XX  (threshold for tier: <N)
F1:              0.XX  (threshold: ≥ 0.90)  [PASS|FAIL]
MRR:             0.XX  (threshold: ≥ 0.85)  [PASS|FAIL]
TRIGGER ACC:     0.XX  (threshold: ≥ 0.90)  [PASS|FAIL]

SECURITY SCAN
  P0: [CLEAR | VIOLATION: <cwe> at <location>]
  P1: [CLEAR | <count> warnings, −<N> pts]

CONSENSUS MATRIX
  | Dimension       | Pass 1 | Pass 2 | Pass 3 | Consensus   |
  |-----------------|--------|--------|--------|-------------|
  | ...             | ...    | ...    | ...    | ...         |

ISSUES
  ERROR:   <blocking issues — must fix before delivery>
  WARNING: <advisory issues — document or fix>
  INFO:    <informational notes>

CERTIFICATION TIER:  PLATINUM | GOLD | SILVER | BRONZE | FAIL
STATUS:              CERTIFIED | TEMP_CERT | LEAN_CERT | HUMAN_REVIEW | ABORT
NEXT ACTION:         <recommendation>
```
