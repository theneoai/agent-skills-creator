# Optimization Strategies

> **Purpose**: Strategy catalog used by OPTIMIZE mode in `claude/skill-framework.md §5`
> **Load**: When a skill fails one or more quality gates (F1 < 0.90, MRR < 0.85, or trigger_accuracy < 0.90)
> **Usage**: Match the lowest-scoring dimension → apply the corresponding strategy

---

## Strategy Selection Matrix

```
Lowest-scoring dimension → apply strategy
  Trigger Coverage    < 80  → S1: Expand Keyword Set
  Structure Score     < 80  → S2: Fill Missing Sections
  Output Clarity      < 80  → S3: Clarify Output Contracts
  Security Baseline   < 80  → S4: Harden Security Baseline
  Quality Gates       < 80  → S5: Add Measurable Thresholds
  All dimensions fail       → S6: Full Structural Rebuild
  Single metric barely fails → S7: Targeted Metric Boost
```

Apply strategies in order: fix lowest-scoring dimension first, re-evaluate, then proceed to next.
Max 3 optimization cycles before escalating to HUMAN_REVIEW.

---

## S1 — Expand Keyword Set

**Trigger**: Trigger Coverage < 80 OR trigger_accuracy < 0.90

**Symptoms**:
- Users report the skill routes to the wrong mode
- Many benchmark cases in `claude/eval/benchmarks.md` predict wrong mode
- MRR low because correct mode ranks 2nd or 3rd

**Strategy**:

1. **Audit existing triggers**: List all current primary/secondary EN and ZH keywords.
2. **Gap analysis**: Compare against failing benchmark cases — what words appeared in failures?
3. **Expand primary triggers**: Add 2–3 new primary keywords per failing mode.
4. **Add ZH triggers**: If any mode has EN triggers but no ZH equivalent, add them.
5. **Add secondary/context triggers**: Add 3–5 contextual phrases that co-occur with the mode.
6. **Add negative patterns**: If false positives exist, add negative keywords to exclude.
7. **Update confidence formula**: Verify weights still sum correctly.

**Example**:
```
Before:  CREATE keywords: [create, build, new]
After:   CREATE keywords: [create, build, new, generate, scaffold, develop, make, add]
         ZH: [创建, 新建, 生成, 开发, 构建, 制作]
```

**Exit Gate**: trigger_accuracy ≥ 0.90 on benchmarks after expansion.

---

## S2 — Fill Missing Sections

**Trigger**: Structure Score < 80

**Symptoms**:
- EVALUATE report lists missing required sections
- Skill lacks `§ Quality Gates`, `§ Security Baseline`, or `§ Usage Examples`
- YAML frontmatter incomplete

**Strategy**:

1. **Run structural checklist** from `claude/eval/rubrics.md §2`.
2. **Identify every missing section** with a point value.
3. **Prioritize**: Fill highest-point missing sections first.
4. **Use template as reference**: Copy the corresponding section from `claude/templates/<type>.md`.
5. **Customize**: Replace template placeholders with skill-specific content.
6. **Verify no duplicate sections**: Merge if a section exists partially.

**Section Priority Order** (by point value):
1. YAML frontmatter (15 pts) — if incomplete
2. `§ Identity` (15 pts)
3. `§ Quality Gates` (15 pts)
4. `§ Security Baseline` (15 pts)
5. `§ Loop / Phase sequence` (10 pts)
6. `§ Usage Examples` (10 pts)
7. `§ Red Lines` (10 pts)

**Exit Gate**: Structure Score ≥ 80 after additions.

---

## S3 — Clarify Output Contracts

**Trigger**: Output Clarity < 80

**Symptoms**:
- Exit criteria not stated for one or more modes
- Output format not specified (missing schema, field list, or example)
- Users report unpredictable skill output

**Strategy**:

1. **Audit each mode section** — check for:
   - Output format explicitly named (JSON / text / markdown-table / etc.)
   - Exit criteria with measurable condition
   - At least one example output block
2. **Add output block per mode**:
   ```
   **Output**:
   ​```
   field_1: <type and description>
   field_2: <type and description>
   ​```
   ```
3. **Add exit criteria** per mode: "Exit when: <condition>."
4. **Update Usage Examples** — add at least one example per missing mode.
5. **For API/data types**: Add JSON schema fragment or table of fields.

**Exit Gate**: Output Clarity ≥ 80; each mode has output format + exit criteria + example.

---

## S4 — Harden Security Baseline

**Trigger**: Security Baseline < 80 OR any CWE violation (ABORT)

**ABORT path** (CWE violation detected):
1. STOP — do not deliver skill.
2. LOG violation to `.skill-audit/framework.jsonl`.
3. IDENTIFY: which CWE, which line/pattern, which field.
4. FIX:
   - CWE-798: Replace hardcoded value with `os.environ.get("VAR_NAME")` or document env-var name.
   - CWE-89: Add sanitization note; specify which fields must be parameterized.
   - CWE-79: Add escaping note; specify output context (HTML, Markdown).
   - CWE-94: Remove eval/exec; replace with safe alternative or restrict to trusted input.
5. RESCAN — run security scan again before resuming.
6. REQUIRE human sign-off if scan was triggered by ABORT.

**Non-ABORT path** (security section boilerplate, not enough specificity):
1. Add CWE section with specific field names:
   ```
   - CWE-798: `AUTH_TOKEN` loaded from env var `SERVICE_API_KEY` — never inline
   - CWE-89: Fields `user_id`, `query_term` parameterized before SQL construction
   ```
2. Add input validation rules for user-facing fields.
3. Add output escaping rules for rendered fields.

**Exit Gate**: SecurityScore = 100 (all auto-fail checks clear, specific field names listed).

---

## S5 — Add Measurable Thresholds

**Trigger**: Quality Gates score < 80

**Symptoms**:
- No numeric F1/MRR thresholds in skill
- Thresholds below framework minimums (F1 < 0.90, MRR < 0.85)
- No reference to measurement method

**Strategy**:

1. **Add / update Quality Gates table**:
   ```markdown
   | Metric | Threshold | Measured By |
   |--------|-----------|-------------|
   | F1 | ≥ 0.90 | claude/eval/rubrics.md |
   | MRR | ≥ 0.85 | claude/eval/rubrics.md |
   | Trigger Accuracy | ≥ 0.90 | claude/eval/benchmarks.md |
   ```
2. **Add OPTIMIZE trigger** — what happens when threshold is missed:
   ```
   IF F1 < 0.90 → auto-route to OPTIMIZE, strategy S1 (trigger expansion)
   ```
3. **Add certification tiers** referencing `claude/eval/rubrics.md`.

**Exit Gate**: QualityGateScore = 100; all thresholds ≥ minimums, measurement method cited.

---

## S6 — Full Structural Rebuild

**Trigger**: Overall Score < 70 (FAIL tier) after two optimization cycles

**When to use**: The skill is so incomplete or incorrect that targeted fixes are less efficient than
rebuilding from the appropriate template.

**Strategy**:

1. **Extract salvageable content**: Identity description, domain knowledge, any examples.
2. **Select fresh template** from `claude/templates/` matching the skill type.
3. **Run CREATE mode** (§3 of skill-framework.md) with the extracted content as pre-filled answers.
4. **Port salvaged content** into new template draft.
5. **Run EVALUATE** immediately after generation.
6. **Do not increment version** if the original was never delivered — treat as v1.0.0.

**Exit Gate**: New skill passes EVALUATE with F1 ≥ 0.90.

---

## S7 — Targeted Metric Boost

**Trigger**: A single metric just barely fails (within 0.03 of threshold).

**When to use**: Quick fix to cross the threshold — avoid heavy-handed changes.

**F1 boost** (F1 between 0.87–0.89):
- Add 2 primary triggers per mode that showed false negatives.
- Remove ambiguous triggers causing false positives.
- Estimated F1 gain per fix: +0.01–0.02.

**MRR boost** (MRR between 0.82–0.84):
- Ensure the single most common trigger phrase is listed as the first primary keyword.
- Reduce number of modes if one mode is essentially never used (raises MRR of remaining modes).

**Trigger accuracy boost** (accuracy between 0.87–0.89):
- Add clarification prompts for the 2–3 most-confused mode pairs.
- Add negative patterns for the most common misroutes.

**Exit Gate**: Metric crosses threshold; no other metric degraded by > 0.02.

---

## Cycle Budget

| Cycle | Allowed Strategies | Outcome if Still Failing |
|-------|--------------------|--------------------------|
| 1 | S1, S2, S3, S4, S5, S7 | Proceed to Cycle 2 |
| 2 | S1–S7 | Proceed to Cycle 3 |
| 3 | S6 (rebuild) or S7 (targeted) | If still failing → HUMAN_REVIEW |

After 3 cycles without passing all gates, log to audit trail with status `HUMAN_REVIEW`
and present the evaluation report to the user with specific failing dimensions.
