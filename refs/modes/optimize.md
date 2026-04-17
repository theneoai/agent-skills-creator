<!-- Extracted from claude/skill-writer.md §10 — full reference -->

# OPTIMIZE Mode

> **For description tuning specifically, prefer
> `scripts/optimize_description.py` over the rubric loop below.** The script
> runs real API calls on a train / test split and selects the best
> description by held-out test f1 — this prevents the common failure mode
> where rubric-driven OPTIMIZE inflates score without improving trigger
> accuracy.
>
> ```bash
> export ANTHROPIC_API_KEY=...
> python3 scripts/optimize_description.py \
>     --skill <skill.md> \
>     --eval-set <trigger-eval.json> \
>     --max-iterations 5 \
>     --out eval/out/desc-opt.json
> ```
>
> The rubric-dimension loop below remains useful for structural issues
> (missing sections, security gaps, workflow incompleteness) but should not
> be the sole signal for description changes.

## §10  OPTIMIZE Mode — 7-Dimension 9-Step Loop (structural)

### Scoring Scale in OPTIMIZE Loop

> **OPTIMIZE uses the LEAN 500-point scale for all re-scoring** (Steps 1 and 6).
> Reason: LEAN is fast and consistent enough for iteration feedback. Full 1000-pt EVALUATE
> runs only at: (a) loop start if no prior EVALUATE exists, and (b) optionally post-convergence.
>
> Conversion: lean_score × 2 = estimated full score. Bronze proxy: lean ≥ 350.
> The VERIFY step (Step 10) also uses LEAN 500-pt scale.

### 7 Dimensions (unified with LEAN and EVALUATE)

These dimensions are identical to the LEAN scoring dimensions and the EVALUATE
sub-dimension schema. See `eval/rubrics.md` (builder/src/config.js is a v4.0+ target) for the canonical spec.

| ID | Dimension | Weight | Strategy | What It Covers |
|----|-----------|--------|----------|----------------|
| D1 | **systemDesign** | 20% | S1, S2 | Identity section, Red Lines, architecture clarity |
| D2 | **domainKnowledge** | 20% | S3, S4 | Template accuracy, field specificity, terminology |
| D3 | **workflow** | 15% | S5 | Phase sequence, exit criteria, loop gates |
| D4 | **errorHandling** | 15% | S6 | Recovery paths, escalation triggers, timeouts |
| D5 | **examples** | 15% | S7 | Usage examples count, quality, bilingual coverage |
| D6 | **security** | 10% | S8 | CWE + ASI scan, Red Lines, auth/authz checks, boundaries |
| D7 | **metadata** | 5% | S9 | YAML frontmatter, trigger phrases, negative boundaries, UTE fields |

### Pre-Loop Strategy Selection

Before starting the loop, display current dimension scores and prompt for strategy:

```
OPTIMIZE pre-loop:
  1. Score all 7 dimensions (LEAN pass)
  2. Display dimension breakdown:
     systemDesign   [NNN/100] ████████░░
     domainKnowledge[NNN/100] ██████████
     workflow       [NNN/100] ████░░░░░░
     errorHandling  [NNN/100] ██████░░░░
     examples       [NNN/100] ████████░░
     security       [NNN/100] ██████████
     metadata       [NNN/100] ███████░░░
     TOTAL          [NNN/500]
  3. Present strategy menu with decision guidance:
     A) Auto       — system picks weakest dimension each round
                     推荐: 首次优化，或不确定选哪个策略时 (Recommended: first time / unsure)
     B) Focus [dim] — concentrate all rounds on one dimension
                     推荐: 某维度得分 < 60% 时集中突破 (Recommended: one dim scoring < 60%)
                     例: B errorHandling / B workflow / B examples
     C) Balanced   — rotate across all dimensions evenly
                     推荐: 各维度分差不超过 15 pt，整体拉升 (Recommended: dims within 15pt of each other)
     D) Security   — security + systemDesign dimensions first
                     推荐: 有 P1/P2 安全警告未解决时 (Recommended: unresolved security warnings)

     > 当前最弱维度 / Weakest dimension: {{WEAKEST_DIM}} ({{WEAKEST_SCORE}}/100)
     > 建议 / Suggestion: {{STRATEGY_RECOMMENDATION}}
     > 例如: 若最弱维度 < 60 → 选 B {{WEAKEST_DIM}} | 若各维度分差 < 15 → 选 C
     >
     > 维度名称 (camelCase 格式，与 B/Focus 命令一致):
     > systemDesign | domainKnowledge | workflow | errorHandling | examples | security | metadata

     [Enter to confirm A / type B/C/D + optional dimension name / /stop to exit]
  4. IF skill has no §UTE section → INJECT UTE first (§15)
     ELSE → UPDATE UTE: refresh certified_lean_score to current LEAN score
  5. Initialize session_best = current_score; cumulative_delta = 0
```

> Type `/stop` at any time to exit the loop early and keep the best version so far.

### 9-Step Loop + VERIFY

```
Round N (max 20):
  [progress] Round N/20 | Score: CUR/500 | Best: BEST/500 | Trend: ▲/▼/─ | Focus: DIMENSION

  1. READ    — score all 7 dimensions; identify lowest-scoring per strategy
  2. ANALYZE — propose 3 targeted fixes for weakest dimension
             → always output: "Auto chose [DIMENSION] ([N]/100 — lowest scoring this round)"
               so the user always sees WHY a dimension was selected
  3. CURATE  — every 10 rounds: consolidate learning, prune stale context
  4. PLAN    — review and select best fix strategy; log decision
  5. IMPLEMENT — apply atomic change (single dimension focus)
  6. RE-SCORE  — re-score:
       delta = new_score − prev_score
       cumulative_delta += delta
       IF delta < −20             → rollback this round's change
       IF cumulative_delta < −40  → rollback to session_best + HUMAN_REVIEW
       IF delta > 0               → update session_best if new_score > session_best
       IF no improvement          → try fix #2
  7. HUMAN_REVIEW — trigger if total_score < 560 after round 10
  8. LOG     — record: round, dimension, delta, confidence, strategy_used
  9. COMMIT  — git commit every 10 rounds; tag with score

  [User can type /stop → exit loop, output session_best version + final report]

  After EVERY round, output this status block:
  ─── Round N complete ────────────────────────────────────
  Score: [PREV] → [NEW] (delta ±N) | Session best: [BEST]/500
  Status: [IMPROVING / STABLE / PLATEAU / VOLATILITY / STOPPED]
    IMPROVING  = keep going; next target: [DIM] ([score]/100)
    STABLE     = diminishing returns — suggest /stop or continue?
    PLATEAU    = no gain in 5 rounds — auto-stopping
    VOLATILITY = score swinging ±30pt — auto-stopping, using session best
  Rounds left: [20-N] | /stop to exit with current best version
  ────────────────────────────────────────────────────────

Convergence check (every round):
  PLATEAU:    no net change in 5 consecutive rounds, OR cumulative_delta < 10 pts total
  VOLATILITY: score swings > ±30 pts round-to-round for 3+ consecutive rounds
  STABLE:     3+ consecutive rounds with delta in [+5, +10] range → diminishing returns
  IF any condition → STOP early; output session_best + convergence reason
  See: refs/convergence.md

Post-loop — Co-Evolutionary VERIFY (Step 10) [NEW in v3.1.0]:
  ┌──────────────────────────────────────────────────────────────────┐
  │ VERIFY — Independent Verification Pass                           │
  │                                                                  │
  │ Design heuristic: co-evolutionary verifier heuristic — using a Surrogate │
  │ Verifier (independent LLM session without inheriting generator   │
  │ biases) increases pass rate from 32% baseline to 75% by round 5. │
  │                                                                  │
  │ Implementation (single-session approximation):                   │
  │ 1. RESET context — explicitly state: "I am now reviewing this    │
  │    skill as a new reader with no knowledge of the optimization   │
  │    history or the AI's prior intentions."                        │
  │ 2. READ the final skill text as a fresh document                 │
  │ 3. SCORE all 7 LEAN dimensions independently (no prior context)  │
  │ 4. COMPARE VERIFY score vs. final OPTIMIZE round score:          │
  │    ├─ delta ≤ 20 pts → scores are consistent → PROCEED          │
  │    ├─ delta 20–50 pts → flag WARNING; report discrepancy         │
  │    └─ delta > 50 pts → score inflation suspected → HUMAN_REVIEW  │
  │ 5. REPORT: "VERIFY SCORE: N/500 | OPTIMIZE SCORE: M/500 |        │
  │    DELTA: ±D | STATUS: CONSISTENT / WARNING / SUSPECT"           │
  │                                                                  │
  │ 📖 VERIFY 评分解读 / How to read VERIFY results:                  │
  │  • VERIFY ≥ OPTIMIZE: unusual; may indicate genuine improvement  │
  │  • VERIFY < OPTIMIZE by ≤20 pts: normal. Independent scoring     │
  │    without context is slightly conservative. Trust VERIFY as     │
  │    the more robust baseline. Both scores indicate real quality.  │
  │  • VERIFY < OPTIMIZE by 20–50 pts: WARNING. OPTIMIZE may have   │
  │    over-tuned for specific phrasing. Review changed sections.    │
  │  • VERIFY < OPTIMIZE by >50 pts: score inflation suspected.      │
  │    OPTIMIZE likely polished surface text without depth. Revert.  │
  │                                                                  │
  │  Use the VERIFY score (not OPTIMIZE score) as the UTE baseline   │
  │  and for registry push decisions. VERIFY is more trustworthy.    │
  └──────────────────────────────────────────────────────────────────┘

Post-loop — UTE update:
  Update use_to_evolve.certified_lean_score with VERIFY score (more conservative)
  Reset use_to_evolve.last_ute_check to today

Post-loop — Final summary output (always show after loop ends):
  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
  OPTIMIZE 完成 / OPTIMIZE Complete
  轮次 / Rounds: [N completed] / 20 max
  起始分 / Starting score: [X]/500
  最终分 / Final score:    [Y]/500  ([+Z] net improvement)
  VERIFY 分 / Verify score: [M]/500  (independent check)
  整体趋势 / Trend: [▲ UP / ─ FLAT / ▼ DOWN]
  收敛原因 / Stop reason: [PLATEAU / VOLATILITY / STABLE / MAX_ROUNDS / USER_STOP]

  下一步 / Next steps:
  • LEAN score [Y] × 2 ≈ estimated EVALUATE score ~[Y×2]
  • Estimated tier: [PLATINUM/GOLD/SILVER/BRONZE/FAIL]
  • Run `/eval` to get authoritative score before registry push
  • Registry push? See §16 for tier thresholds.
  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄

Max rounds: 20 → if not BRONZE after round 20 → HUMAN_REVIEW

OSCILLATION diagnostic (when score fluctuates ±5–15 pts without clear trend):
When VOLATILITY or PLATEAU detected AND score < 350 (FAIL), output structured diagnostic:

  ─── OPTIMIZE Diagnostic ─────────────────────────────────────────
  Rounds completed: N | Score range this session: [LOW]–[HIGH]/500
  Stop reason: VOLATILITY / PLATEAU / MAX_ROUNDS

  Dimension breakdown (current scores vs. what's needed for BRONZE ≥ 350):
    systemDesign    [N]/100  [status: OK / ⚠ NEEDS WORK]
    domainKnowledge [N]/100  [status: OK / ⚠ NEEDS WORK]
    workflow        [N]/100  [status: OK / ⚠ NEEDS WORK]
    errorHandling   [N]/100  [status: OK / ⚠ NEEDS WORK]
    examples        [N]/100  [status: OK / ⚠ NEEDS WORK]
    security        [N]/100  [status: OK / ⚠ NEEDS WORK]
    metadata        [N]/100  [status: OK / ⚠ NEEDS WORK]

  Why oscillation happens:
  - If ≥2 dimensions are ⚠ NEEDS WORK and have competing constraints
    (e.g., adding more examples makes the skill larger, reducing workflow clarity),
    OPTIMIZE cannot improve both simultaneously → score oscillates.

  Recommended manual actions (pick 1-2 per editing session):
  ⚠ [TOP_WEAK_DIM]: [specific suggestion for this dimension]
    Example for errorHandling: "Add a concrete error recovery table with ≥3 rows"
    Example for examples: "Add 2 complete input→output examples in a code block"
    Example for metadata: "Add 3+ Chinese trigger phrases to YAML frontmatter"
  ⚠ [SECOND_WEAK_DIM]: [specific suggestion]

  After manual edits: run /lean to check improvement, then continue /opt
  Or: run /eval for authoritative score to see if you've reached BRONZE
  ─────────────────────────────────────────────────────────────────
```

Strategy catalog: `optimize/strategies.md`
Convergence spec: `refs/convergence.md`

---

### Score Persistence (`.optimize-history.jsonl`)

After each OPTIMIZE session, append one record to `.skill-audit/optimize-history.jsonl`:

```json
{
  "timestamp": "<ISO-8601>",
  "skill_name": "<name>",
  "rounds_completed": 0,
  "start_lean": 0,
  "end_lean": 0,
  "delta": 0,
  "session_best": 0,
  "verify_score": 0,
  "strategy": "A|B|C|D",
  "rollbacks": 0,
  "outcome": "IMPROVED|PLATEAU|VOLATILITY|ROLLBACK"
}
```

> `[CORE]` — Output this record as part of your response.
> `[EXTENDED]` — Auto-write to `.skill-audit/optimize-history.jsonl` with file system access.


---

