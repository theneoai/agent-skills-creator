# TUNE Mode Reference

> Autonomous skill optimization through iterative experimentation.

---

## § 1 · Autotune Philosophy

**Fully autonomous**: The autotuner never asks for permission. It runs experiments, evaluates results, and iterates continuously until:
- Target score is reached (≥ 9.0 overall)
- Human stops the process
- No more improvement opportunities found

**Inspired by**: AutoML, autoresearch, genetic algorithms — but simplified for skill optimization.

---

## § 2 · The Autonomous Loop

```
┌─────────────────────────────────────────────────────────────┐
│                    AUTONOMOUS LOOP                          │
├─────────────────────────────────────────────────────────────┤
│  1. READ    → Read current SKILL.md                         │
│  2. ANALYZE → Identify 1 improvement opportunity            │
│  3. MODIFY  → Implement the change                          │
│  4. SCORE   → Run score.sh to evaluate                     │
│  5. DECIDE  → Improved? Keep. Worse? Reset.                │
│  6. LOG     → Record result in results.tsv                  │
│  7. COMMIT  → Every 10 rounds, git commit + push            │
│  8. REPEAT  → Continue until stopped                        │
└─────────────────────────────────────────────────────────────┘
```

---

## § 3 · Experiment Protocol

### Before Starting

1. Run baseline score:
   ```bash
   ./scripts/score.sh /path/to/SKILL.md
   ```

2. Create results.tsv:
   ```bash
   echo -e "round\tscore\tdelta\tstatus\tdescription" > results.tsv
   ```

3. Note baseline score

### During Experiment

For each iteration:
1. Read SKILL.md
2. Identify one specific improvement
3. Implement change
4. Run score.sh
5. Compare to previous score
6. Decide: keep or reset
7. Log result
8. Repeat

### After Every 10 Rounds

```bash
git add -A
git commit -m "autotune: round N - score X.XX"
git push
```

---

## § 4 · What Can Be Changed

Everything in SKILL.md is fair game:

| Category | Examples | Impact |
|----------|----------|--------|
| System Prompt | §1.1 Identity, §1.2 Framework, §1.3 Thinking | +2-4 pts |
| Domain Knowledge | Specific data, benchmarks, case studies | +2-4 pts |
| Workflow | Done/Fail criteria, decision trees, phases | +2-4 pts |
| Error Handling | Recovery strategies, anti-patterns, edge cases | +1-2 pts |
| Examples | 5+ detailed scenarios with input/output | +2-3 pts |
| Metadata | Description triggers, frontmatter completeness | +1 pt |

### Constraints

- ✅ Must use opencode to run evaluation
- ✅ Keep SKILL.md ≤ 300 lines (move details to references/)
- ✅ Don't break the skill (validation must pass)
- ❌ Don't modify eval scripts
- ❌ Don't add new dependencies

---

## § 5 · Decision Rules

### After Each Experiment

| Result | Action | Reason |
|--------|--------|--------|
| Score **+0.1 or more** | ✅ Keep | Improvement detected |
| Score **same** | ↩️ Reset | No improvement |
| Score **worse** | ↩️ Reset | Regression |
| **Crashed/Broken** | 🔧 Fix or skip | Validation failed |

### Complexity vs Improvement

| Scenario | Decision |
|----------|----------|
| +0.1 score, +100 hacky lines | Skip — not worth complexity |
| +0.1 score, simpler code | Keep — good improvement |
| Equal score, simpler structure | Keep — better maintainability |
| -0.1 score, simpler | Skip — quality regressed |

---

## § 6 · Improvement Ideas

### High-Impact (Try First)

| Idea | Dimension | Expected Gain |
|------|-----------|---------------|
| Add missing §1.1/1.2/1.3 | System Prompt | +2-4 pts |
| Add specific benchmarks | Domain Knowledge | +1-2 pts |
| Add Done/Fail criteria | Workflow | +2-3 pts |
| Expand to 5+ scenarios | Examples | +2-3 pts |

### Medium-Impact

| Idea | Dimension | Expected Gain |
|------|-----------|---------------|
| Add case studies | Domain Knowledge | +1-2 pts |
| Add decision trees | Workflow | +1-2 pts |
| Add recovery strategies | Error Handling | +1-2 pts |
| Add edge cases | Error Handling | +1 pt |

### Low-Impact (Try Last)

| Idea | Dimension | Expected Gain |
|------|-----------|---------------|
| Improve formatting | All | +0.1-0.3 pts |
| Add synonyms | All | +0.1 pts |
| Reorder sections | All | +0.1 pts |

---

## § 7 · Scoring Deep Dive

### 6 Dimensions Explained

**System Prompt (20%)**:
- §1.1 Identity: Who are you?
- §1.2 Framework: How do you work?
- §1.3 Thinking: How do you decide?

**Domain Knowledge (20%)**:
- Specific data (benchmarks, case studies)
- Named frameworks (McKinsey, TOGAF, etc.)
- Quantified results ("16.7% improvement")

**Workflow (20%)**:
- Clear phases with numbers
- Done criteria per phase
- Fail criteria per phase
- Decision trees (optional)

**Error Handling (15%)**:
- Named failure modes
- Recovery strategies
- Anti-patterns
- Edge cases

**Examples (15%)**:
- 5+ detailed scenarios
- Input → Output → Verification
- Realistic context
- Edge cases included

**Metadata (10%)**:
- Frontmatter completeness
- Description triggers
- Version, author, license

### How score.sh Works

```bash
# score.sh checks:
# 1. Presence of §1.1/1.2/1.3 patterns
# 2. Count of specific data patterns (benchmarks, percentages)
# 3. Workflow structure (phases, done/fail criteria)
# 4. Error handling keywords
# 5. Example sections
# 6. Frontmatter fields
```

---

## § 8 · Results Log Format

### File: `results.tsv`

```
round	score	delta	status	description
1	7.2	0.0	keep	baseline
2	7.8	+0.6	keep	add §1.1 identity section
3	7.9	+0.1	keep	add domain benchmarks
4	7.7	-0.2	discard	remove examples (reverted)
5	8.2	+0.3	keep	expand to 5 scenarios
```

### Analysis Commands

```bash
# View latest results
tail -10 results.tsv

# Find best improvement
sort -t$'\t' -k2 -n results.tsv | tail -5

# Find failures
grep discard results.tsv

# Count experiments
wc -l results.tsv
```

---

## § 9 · Troubleshooting

### Score Not Improving

1. Check if at theoretical maximum (all dimensions at 10)
2. Try different improvement category
3. Check for validation errors
4. Try simplifying instead of adding

### Validation Errors

If `validate.sh` fails after your change:
1. Check frontmatter syntax
2. Ensure required fields present
3. Reset and try different change

### Git Reset Not Working

```bash
# Hard reset to previous state
git reset --hard HEAD~1

# Check status
git status
```

---

## § 10 · Success Metrics

**Target**: ≥ 9.0 overall with variance < 1.0

| Stage | Score | Status |
|-------|-------|--------|
| Initial | 5-7 | Starting point |
| Quick wins | 7-8 | After structural fixes |
| Good | 8-8.5 | After content expansion |
| Excellent | 8.5-9.0 | After refinement |
| Exemplary | 9.0+ | Target achieved |

**Expected rate**: ~20-30 experiments/hour
**Typical time to 9.0**: 2-4 hours of autonomous work

---

## § 11 · Examples

### Example 1: Adding System Prompt

```
BEFORE: No §1.1/1.2/1.3 sections
AFTER: Added all three sections

Result: System Prompt 6→10 (+0.8 weighted)
```

### Example 2: Adding Benchmarks

```
BEFORE: "improves quality significantly"
AFTER: "16.7% error reduction (based on McKinsey study)"

Result: Domain Knowledge 6→8 (+0.4 weighted)
```

### Example 3: Adding Examples

```
BEFORE: 2 brief mentions
AFTER: 5 detailed scenarios with input/output

Result: Examples 5→9 (+0.6 weighted)
```

---

## § 12 · Quick Reference

```bash
# Start autotune
./scripts/tune.sh my-skill/SKILL.md 100

# Run single score check
./scripts/score.sh my-skill/SKILL.md

# View results
cat results.tsv

# Stop at any time
Ctrl+C

# Commit current state
git add -A && git commit -m "message"
```
