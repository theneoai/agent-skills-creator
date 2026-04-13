# Evaluation Rubrics

> **Purpose**: 4-phase 1000-point scoring pipeline used by EVALUATE mode.
> **Load**: When §8 (EVALUATE Mode) of `claude/skill-writer.md` is accessed.
> **Main doc**: `claude/skill-writer.md §8`
> **SSOT**: `builder/src/config.js SCORING` — canonical dimension weights and thresholds
> **Note on LEAN vs EVALUATE**: LEAN (§6 skill-framework.md) is a 500-pt heuristic pre-check.
> EVALUATE is the full 1000-pt pipeline. They share dimension names but NOT point allocations.
> LEAN leanMax ≠ EVALUATE Phase 2 per-dimension max. See config.js comment for full explanation.
> **v3.2.0**: Added D8 Composability (LEAN bonus 0–20 pts; EVALUATE Phase 5 defined for v4.0+).
> D8 is optional — absence does NOT penalise a skill. Adds up to 20 bonus pts to LEAN (max 520).

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
| `triggers` field present (EN ≥ 3, ZH ≥ 2) | 5 | v3.1.0: trigger phrase coverage required |
| `skill_tier` declared (planning/functional/atomic) | 5 | v3.1.0: SkillX three-tier hierarchy |
| ≥ 3 `## §N` sections | 10 | Identity, Loop, at least one mode |
| Identity section present (name/role/purpose) | 10 | |
| Red Lines / 严禁 section present | 10 | |
| **Negative Boundaries section** present | 10 | v3.1.0: "Do NOT use for" with ≥ 3 anti-cases |
| Quality Gates section with numeric thresholds | 10 | Thresholds must be numbers |
| No `{{PLACEHOLDER}}` tokens remaining | 5 | Any remaining = hard deduction |
| No TODO / FIXME markers | 5 | Advisory |

> **v3.1.0 Phase 1 changes**: Added `triggers`, `skill_tier`, and **Negative Boundaries** checks
> (+15 pts new; Quality Gates reduced from 15→10; no-placeholders reduced from 15→5; file-size
> advisory removed). Total still 100 pts.

**Hard deduction**: If `{{PLACEHOLDER}}` found → Phase1 score capped at 70, WARNING issued.
**Hard deduction**: If Negative Boundaries section missing → Phase1 deduct 10 pts, P2 advisory added.

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
| **Security Baseline** | 30 | 10% | Security section present, CWE reference, OWASP ASI01-ASI10 status documented, no hardcoded-credential patterns |
| **Metadata Quality** | 15 | 5% | YAML complete (incl. `skill_tier`, `triggers`), version semver, author, dates, description bilingual |

> **v3.2.0 note**: Phase 2 dimensions are unchanged. D8 Composability is scored in LEAN (bonus)
> and in EVALUATE Phase 5 (v4.0+). See §9 below for D8 specification.

> **Note on Security dimension (v3.1.0)**: Phase 4 runs automated CWE + OWASP ASI pattern scan.
> Phase 2 checks whether security *documentation* is adequate (Security Baseline section, OWASP
> ASI status comments). Phase 4 runs pattern scan against actual skill content. Both deductions
> applied independently. Full patterns: `claude/refs/security-patterns.md §5 OWASP Agentic Top 10`.

> **Note on Metadata dimension (v3.1.0)**: `skill_tier` and `triggers` are now required YAML
> fields. Phase 2 Metadata checks for their presence and completeness. Missing `skill_tier` or
> `triggers.en` (< 3 phrases) → deduct up to 8 pts from Metadata.

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

## §7  Score Reliability & Variance Guide

> **Why this matters**: skill-writer's 1000-point pipeline is LLM-executed. The same skill
> evaluated twice may produce different scores. This section documents expected variance ranges
> per phase and gives guidance on how to interpret scores with appropriate confidence.

### Phase-Level Reliability

| Phase | Method | Expected Variance | Reliability |
|-------|--------|-------------------|-------------|
| **Phase 1** (0–100) | Structural / regex checks | ± 0–5 pts | High — mostly deterministic |
| **Phase 2** (0–300) | LLM text quality judgment | ± 15–30 pts | Medium — rubric-guided but subjective |
| **Phase 3** (0–400) | LLM trigger + behavior simulation | ± 20–40 pts | Medium-Low — depends on test input interpretation |
| **Phase 4** (0–200) | Formula-based (variance gate, F1, MRR) | ± 5–10 pts | High — formula-driven, low LLM judgment |
| **Total** (0–1000) | Composite | ± 30–60 pts | See tier interpretation below |

### Tier Confidence Interpretation

Given ±30–60 pt total variance, use these **confidence-adjusted tier boundaries**:

| Displayed Score | Confident Tier | Plausible Range |
|-----------------|----------------|-----------------|
| ≥ 980 | PLATINUM (certain) | 950–1000 |
| 930–979 | PLATINUM (likely) / GOLD (possible) | Use 2-run average |
| 900–929 | GOLD (likely) | ± boundary — re-run to confirm |
| 830–899 | GOLD/SILVER boundary | Re-run recommended |
| 800–829 | SILVER (likely) | ± boundary — re-run to confirm |
| 730–799 | SILVER/BRONZE boundary | Re-run recommended |
| 700–729 | BRONZE (likely) | ± boundary — re-run to confirm |
| 660–699 | BRONZE/FAIL boundary | **Always re-run before acting** |
| < 660 | FAIL (certain) | Optimize before re-evaluating |

### When to Re-Evaluate for Confidence

**Single run is sufficient when**:
- Score ≥ 960 or ≤ 640 (well within a tier)
- Phase 4 security scan result is deterministic (P0 violation or CLEAR)

**Run twice and average when**:
- Score falls within ±30 pts of any tier boundary
- Phase 3 Trigger Routing accuracy < 85% (ambiguous routing behavior)
- Variance gate result changes tier (e.g., variance = 18–22 near SILVER/BRONZE cut)

**Run three times and take median when**:
- Score is 660–740 (FAIL/BRONZE boundary — consequential decision)
- Upgrading a skill for production deployment
- OPTIMIZE loop converged but tier is disputed

### Phase 2 Sub-Dimension Variance

Phase 2 has the highest LLM-judgment component. Sub-dimensions ranked by stability:

| Sub-Dimension | Stability | Note |
|---------------|-----------|------|
| **Metadata Quality** | High ± 2 pts | Mostly YAML presence checks |
| **Security Baseline** | High ± 3 pts | Pattern-matching dominant |
| **Examples** | Medium ± 5 pts | Count is static; quality is LLM |
| **System Design** | Medium ± 8 pts | Structural clarity judgment |
| **Workflow Definition** | Medium ± 8 pts | Phase completeness judgment |
| **Error Handling** | Low ± 12 pts | Adequacy is highly subjective |
| **Domain Knowledge** | Low ± 15 pts | Content accuracy varies most |

### Reducing Score Variance

To get more reliable scores from a single run:

1. **Provide context**: Tell the evaluator which template type was used (api-integration /
   data-pipeline / workflow-automation / base). This anchors Domain Knowledge scoring.
2. **Supply test inputs**: For Phase 3, provide 3 concrete trigger test cases with expected
   modes. This converts heuristic routing tests to deterministic pass/fail.
3. **Use LEAN as floor**: Run LEAN first for `[STATIC]` checks (335 pts max, zero variance).
   If LEAN static score < 270, full EVALUATE will almost certainly FAIL — optimize first.

---

## §8  Tier-Specific Evaluation Weight Adjustments

> **Rationale**: The default Phase 2 sub-dimension weights (§4) are calibrated for
> `functional` tier skills — the most common case. However, `planning` and `atomic` tier
> skills have fundamentally different quality signals. Applying the same weights to all
> three tiers systematically under-scores or over-scores the wrong dimensions.
>
> Research basis: SkillX (arxiv:2604.04804) — three-tier hierarchy (Planning / Functional /
> Atomic) has distinct quality criteria at each level.

### How to Apply Tier Adjustments

1. Read the `skill_tier` field from YAML frontmatter.
2. If `skill_tier` is absent or `functional` → use **default weights** (§4).
3. If `skill_tier` is `planning` or `atomic` → replace Phase 2 sub-dimension weights
   with the tier-specific table below before scoring.
4. Phase 1, Phase 3, and Phase 4 weights are **not changed** by tier.

### Tier: `planning` — Phase 2 Weight Overrides

Planning skills organize tasks and decompose work. Evaluate **how well they orchestrate**,
not low-level execution detail.

| Sub-Dimension | Default Weight | Planning Weight | Max (300 pts) | Change |
|---------------|---------------|----------------|--------------|--------|
| **System Design** | 20% (60 pts) | **30%** (90 pts) | 90 | ↑ Hierarchy clarity is paramount |
| **Workflow Definition** | 15% (45 pts) | **25%** (75 pts) | 75 | ↑ Decomposition quality is core value |
| **Domain Knowledge** | 20% (60 pts) | **20%** (60 pts) | 60 | = Same — domain accuracy still matters |
| **Error Handling** | 15% (45 pts) | **10%** (30 pts) | 30 | ↓ Delegation patterns replace recovery |
| **Examples** | 15% (45 pts) | **10%** (30 pts) | 30 | ↓ Composition examples over edge cases |
| **Security Baseline** | 10% (30 pts) | **5%** (15 pts) | 15 | ↓ Orchestration less attack-surface exposed |
| **Metadata Quality** | 5% (15 pts) | **0%** (0 pts) | 0 | ↓ Subsumed into System Design score |
| **Total** | 100% (300 pts) | **100%** (300 pts) | 300 | |

**Planning-specific scoring notes**:
- System Design: check for clear sub-skill decomposition (`depends_on`, delegation diagram, or explicit sub-task list)
- Workflow: check that each step names its expected output and handoff condition — not just "do X"
- Error Handling: check for delegation fallback patterns (which sub-skill handles failure) rather than try/catch

### Tier: `atomic` — Phase 2 Weight Overrides

Atomic skills are execution-oriented primitives. Evaluate **precision, constraints, and
safety** — not high-level architecture.

| Sub-Dimension | Default Weight | Atomic Weight | Max (300 pts) | Change |
|---------------|---------------|--------------|--------------|--------|
| **System Design** | 20% (60 pts) | **10%** (30 pts) | 30 | ↓ Simple identity, minimal architecture needed |
| **Workflow Definition** | 15% (45 pts) | **15%** (45 pts) | 45 | = Same — step clarity still critical |
| **Domain Knowledge** | 20% (60 pts) | **15%** (45 pts) | 45 | ↓ Narrower scope reduces domain breadth req |
| **Error Handling** | 15% (45 pts) | **25%** (75 pts) | 75 | ↑ Atomic ops must handle failure precisely |
| **Examples** | 15% (45 pts) | **20%** (60 pts) | 60 | ↑ Usage patterns and constraints are core |
| **Security Baseline** | 10% (30 pts) | **15%** (45 pts) | 45 | ↑ Atomic ops have highest injection surface |
| **Metadata Quality** | 5% (15 pts) | **0%** (0 pts) | 0 | ↓ Trigger precision scored in Phase 3 instead |
| **Total** | 100% (300 pts) | **100%** (300 pts) | 300 | |

**Atomic-specific scoring notes**:
- Error Handling: every input boundary case must be explicitly named (null, empty, out-of-range, adversarial)
- Examples: must include at least one negative example showing what the skill rejects
- Security: check that all external inputs are validated before use; no implicit trust of upstream data

### Tier-Adjusted Certification Thresholds

Phase 2 minimum thresholds (used in tier certification) adjust proportionally:

| Tier (skill_tier) | PLATINUM Phase2 Min | GOLD Phase2 Min | SILVER Phase2 Min | BRONZE Phase2 Min |
|-------------------|--------------------|-----------------|--------------------|-------------------|
| `functional` (default) | 270 | 255 | 225 | 195 |
| `planning` | 265 | 250 | 218 | 188 |
| `atomic` | 275 | 260 | 230 | 200 |

> `atomic` has slightly higher Phase 2 thresholds because atomic skills have a narrower
> scope — the precision bar is higher for a small, focused primitive than a broad planner.

---

## §9  D8 Composability — LEAN Bonus Dimension (v3.2.0)

> **Research basis**: SkillNet (arxiv:2603.04448), GoS bundle retrieval.
> **Implementation**: `builder/src/core/graph.js scoreD8Composability()`
> **Full spec**: `claude/refs/skill-graph.md §5`

D8 is an **optional bonus dimension**. Skills without a `graph:` YAML block
score **0 on D8 with no penalty** — their LEAN score is still out of 500.
Skills with a `graph:` block earn up to 20 bonus points (LEAN max = 520).

### D8 LEAN Scoring (0–20 bonus points)

| Check ID | Points | Condition |
|----------|--------|-----------|
| `[D8-STATIC] graph_block_present` | 5 | `graph:` key exists in YAML frontmatter with ≥ 1 non-empty field |
| `[D8-STATIC] skill_tier_graph_consistent` | 10 | Tier matches graph structure (see table below) |
| `[D8-STATIC] graph_edge_ids_valid_format` | 5 | All `depends_on`/`composes`/`similar_to` IDs match `[a-f0-9]{12}` |

**Tier consistency scoring** (10-pt check):

| skill_tier | Expected graph structure | Score |
|------------|--------------------------|-------|
| `planning` | Has `composes` with ≥ 1 entry | 10 |
| `planning` | Has `depends_on` only (no composes) | 5 (advisory) |
| `functional` | Has `provides` and/or `consumes` | 10 |
| `functional` | No `provides`/`consumes` | 7 (acceptable) |
| `atomic` | Has `provides`/`consumes`; NO `depends_on` | 10 |
| `atomic` | Has `depends_on` declared | 4 (advisory: atomic should be self-contained) |

**Scoring mechanics**:
- LEAN score with D8: reported as `XXX/520` (or `XXX/500 + X D8 bonus`)
- LEAN pass threshold remains 350/500 (D8 bonus does NOT lower this threshold)
- Near a LEAN tier boundary? Declare `graph:` block to earn bonus pts rather than improving other dims

### D8 EVALUATE Phase 5 (v4.0+ — not active in v3.x)

Phase 5 adds 100 pts when active. Certification thresholds scale proportionally (see refs/skill-graph.md §5.2).

| Sub-dimension | Max | What is checked |
|---------------|-----|----------------|
| Dependency declaration completeness | 30 | Declared deps cover all skills referenced in body |
| Interface contract clarity | 25 | `provides`/`consumes` types are specific (not generic "data") |
| Tier role consistency | 25 | Skill's graph role matches skill_tier declaration |
| Edge quality | 20 | similar_to similarities plausible; IDs valid and resolvable |

---

## §10  LEAN Fast Path

Before running Phase 1–4, apply LEAN heuristics (§6 of skill-writer.md).

**Quick-Pass**: If lean_score ≥ 450 (GOLD proxy):
- Run only Phase 1 + security scan
- If Phase 1 ≥ 90 AND security CLEAR → issue LEAN_CERT, skip Phase 2–4
- Schedule full Phase 2–4 within 24 h

**Full Pipeline**: If lean_score 300–449 OR any quick-pass check fails → run all 4 phases.

---

## §11  Evaluation Report Template

```
SKILL EVALUATION REPORT
=======================
Skill:      <name> v<version>
Evaluated:  <ISO-8601>
Evaluator:  skill-writer v3.1.0
Skill Tier: <planning | functional | atomic>   (Phase 2 weights adjusted per rubrics.md §8)

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

TOTAL SCORE:     XXX / 1000   (+ XXX D8 bonus / 20 if graph: declared)
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

D8 COMPOSABILITY   (LEAN bonus — optional)
  graph_block_present:         X/5   [graph: block absent → 0 pts, no penalty]
  skill_tier_graph_consistent: X/10
  graph_edge_ids_valid:        X/5
  D8 TOTAL:                    X/20

CERTIFICATION TIER:  PLATINUM | GOLD | SILVER | BRONZE | FAIL
STATUS:              CERTIFIED | TEMP_CERT | LEAN_CERT | HUMAN_REVIEW | ABORT
NEXT ACTION:         <recommendation>
```
