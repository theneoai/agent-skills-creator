<!-- Extracted from claude/skill-writer.md §9 — full reference -->

## §9  EVALUATE Mode — 4-Phase Pipeline

**Total: 1000 points** (+ up to 20 bonus from Behavioral Verifier) | Full rubrics: `eval/rubrics.md`

### Phase Overview

| Phase | Name | Max Points | Method |
|-------|------|-----------|--------|
| 1 | Parse & Validate | 100 | Heuristic (schema, sections, no placeholders, `generation_method` advisory) |
| 2 | Text Quality | 300 | Static analysis across 7 sub-dimensions (see table below) |
| 3 | Runtime Testing | 400 | Trigger pattern tests, mode definitions, error handling |
| 4 | Certification | 200 | Variance gate + security scan + quality gates + Behavioral Verifier (+20 bonus) |
| Pragmatic Test | Optional | N/A | User-provided real task samples → `pragmatic_success_rate` |

**Behavioral Verifier** (Phase 4 sub-step, v3.4.0): Auto-generates 3 positive + 2 negative test cases
from the skill's own Skill Summary, executes them, and reports a `behavioral_pass_rate`. Adds up to
20 bonus pts to Phase 4. Addresses generator bias per co-evolutionary verifier heuristic.

**Pragmatic Test** (`/eval --pragmatic`): Executes the skill against 3–5 user-provided real task
samples and produces a `pragmatic_success_rate` independent of the theoretical score. Blocks SHARE
push if `pragmatic_success_rate < 60%`. Full spec: `eval/rubrics.md §6.5`.

### Phase 2 Sub-Dimensions (300 points total)

Phase 2 scores across 7 content quality dimensions with tier-adjusted weights.
**If your Phase 2 score is low**, run `/eval` and ask "show my Phase 2 breakdown by dimension" to see which one is dragging your score.

| Dimension | planning | functional | atomic | What it checks |
|-----------|----------|------------|--------|----------------|
| systemDesign | 30% | 20% | 15% | Clarity of architecture, role definition, purpose |
| domainKnowledge | 20% | 20% | 15% | Depth and accuracy of domain-specific content |
| workflow | 25% | 20% | 15% | Step sequence, gates, rollback actions |
| errorHandling | 10% | 15% | 25% | Recovery paths, escalation rules |
| examples | 5% | 15% | 20% | Usage coverage, realistic I/O |
| security | 5% | 5% | 5% | CWE + OWASP ASI baseline |
| metadata | 5% | 5% | 5% | YAML triggers, negative boundaries, versions |

> To understand which dimension is low: after receiving your EVALUATE score, ask:
> "What are my Phase 2 sub-dimension scores?" — the framework outputs per-dimension totals.
> Use these to target your next OPTIMIZE run (`/opt` + skill + "focus on [dimension]`).

### Certification Tiers

| Tier | Min Score | Max Variance | Additional Gates |
|------|-----------|-------------|------------------|
| PLATINUM | ≥ 950 | < 10 | Phase2 ≥ 270, Phase3 ≥ 360 |
| GOLD | ≥ 900 | < 15 | Phase2 ≥ 255, Phase3 ≥ 340 |
| SILVER | ≥ 800 | < 20 | Phase2 ≥ 225, Phase3 ≥ 300 |
| BRONZE | ≥ 700 | < 30 | Phase2 ≥ 195, Phase3 ≥ 265 |
| FAIL | < 700 | any | — auto-route to OPTIMIZE |

**Variance formula**:
```
variance = | (phase2_score / 3) - (phase3_score / 4) |
```
> **Why divide by 3 and 4?** This normalizes both scores to "points per point available":
> Phase 2 max = 300, so dividing by 3 gives a value in the 0–100 range.
> Phase 3 max = 400, so dividing by 4 also gives 0–100 range.
> The formula then measures the gap between text quality density and runtime density.
> A skill scoring 270/300 on text (90%) but 280/400 on runtime (70%) has variance = |90 − 70| = 20.

High variance = artifact looks good on paper but fails runtime (or vice versa).

### Evaluation Workflow

```
1. LEAN pre-check (§7) → if UNCERTAIN or FAIL → full pipeline
2. READ skill_tier from YAML frontmatter (planning | functional | atomic)
   READ generation_method + validation_status (advisory — emit INFO if absent)
   → If skill_tier present: apply tier-adjusted Phase 2 weights (eval/rubrics.md §8)
   → If absent or 'functional': use default Phase 2 weights (rubrics.md §4)
3. Phase 1: Parse — YAML, required sections, trigger presence, no placeholders
4. Phase 2: Text — 7 sub-dimensions with tier-adjusted weights
5. Phase 3: Runtime — benchmark test cases (eval/benchmarks.md)
6. Phase 4: Certification — compute variance, run security scan, check tier-adjusted gates
   Phase 4 Behavioral Verifier — auto-generate 5 test cases, execute, report pass_rate (+20 bonus)
7. Pragmatic Test (if --pragmatic flag OR auto-triggered when validation_status == "lean-only" pre-SHARE):
   → User provides 3–5 real task samples → execute → report pragmatic_success_rate
   → Update validation_status to "pragmatic-verified" if pass_rate ≥ 60%
8. UPDATE labels: set validation_status = "full-eval" (or "pragmatic-verified" if pragmatic passed)
9. REPORT — per-phase scores + tier + behavioral verifier + pragmatic result + issues list
10. ROUTE:
      CERTIFIED → deliver; update validation_status in skill YAML
      FAIL       → auto-route to OPTIMIZE (§9)
```

### Multi-Pass Scoring

Score in separate passes to ensure objectivity:
- Pass 1: Score Phase 2 (Text Quality) — focus on structure and content
- Pass 2: Score Phase 3 (Runtime) — focus on trigger accuracy and behavior
- Pass 3: Reconcile scores, compute variance, certify (Phase 4)

Full protocol: `refs/self-review.md §2`

---

### Statistical Multi-Run Evaluation (`--multi-run`) `[AVAILABLE]`

> **When to use**: Targeting PLATINUM/GOLD certification, or when a single /eval
> run places you within 30 pts of a tier boundary. The standard 4-phase pipeline
> has inherent LLM-judge variance of ±20–40 pts in Phase 3 — a ±30 pt swing can
> change the certification tier.

**Activation**:
```bash
# Via script (recommended for production certification):
python3 scripts/run_multi_eval.py --skill my-skill.md --runs 3

# Inline in session (natural language):
"run /eval 3 times and give me the median score with confidence interval"
```

**What the multi-run mode adds**:

| Metric | Standard /eval | Multi-run (N=3) |
|--------|---------------|-----------------|
| Score | Single run | Median of N runs |
| Variance | Unknown | CI = max–min spread |
| Per-dim reliability | Unknown | CV% per dimension |
| Borderline detection | No | Flags if within 30/1000 pts of tier |
| Cost | 1 API call | N API calls (~$0.02–0.05) |

**Interpreting results**:

```
multi-eval-report.md output example:

  Median score : 478/700  (CI: ±12 pts)
  Est. EVALUATE: ~683/1000 → BRONZE
  Borderline   : NO  (nearest boundary: SILVER at 560/700, dist=82 pts)
  High-variance: d3_workflow (CI=28 pts) ← fix this dimension

  Recommendation: CERTIFIED BRONZE (statistical confidence: CI=24 pts)
```

**Decision rules**:

| CI width (700-pt scale) | Action |
|-------------------------|--------|
| ≤ 20 pts | Safe to certify at median tier |
| 20–40 pts | Certify at median tier, note uncertainty in registry |
| > 40 pts | Fix high-CV dimensions first, then re-run |
| Score within 21/700 of tier boundary | Run 1 additional pass; use conservative (lower) tier |

> Script: `scripts/run_multi_eval.py` — full spec in `scripts/run_multi_eval.py` docstring

---

