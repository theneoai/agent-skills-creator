# Examples Reference

> Detailed runtime examples for all modes. See [SKILL.md §5](../SKILL.md#-5--examples) for summary.

---

## Example 4: TUNE — Autonomous Optimization

**Input:** `"autotune skills/moderate/SKILL.md --rounds 10"`

**Runtime behavior** (fully autonomous, never asks permission):
```
Loop 10 times:
1. Read SKILL.md → identify 1 improvement
2. Apply change
3. Run ./scripts/score.sh
4. If improved → keep; if worse → git reset --hard HEAD~1
5. Log to results.tsv
6. Continue immediately (no asking)
```

**Output:** `results.tsv` with 10 rounds, final score 9.35/10

---

## Example 5: Edge Case — Vague Request

**Input:** `"help with my skill"`

**Runtime behavior**:
```
Clarifying question: "I can help with your skill. What would you like?
- Create a new skill
- Evaluate an existing skill
- Fix quality issues (restore)
- Optimize for better scores (tune)"
```

---

## Example 6: Edge Case — Wrong Mode Routing

**Input:** `"improve my skill's score"`

**Runtime behavior**:
```
1. First verb: "improve" 
2. Has "score" → route to TUNE (not RESTORE)
3. Execute TUNE autonomous loop
```

---

## Example 7: CREATE — Enterprise Skill

**Input:** `"build a strategic consultant skill, enterprise tier"`

**Runtime behavior:**
```
Mode: CREATE (tier: Enterprise)
1. Confirm: "Strategic consultant, Enterprise: 500-1500 lines, 9-21 files, 5+ capabilities"
2. Design §1.1/1.2/1.3 with full constraints
3. Domain: McKinsey 7-S, SWOT analysis, OKR frameworks
4. Workflow: 6 phases with Done/Fail criteria
5. Examples: 8+ scenarios with enterprise edge cases
6. Validate: ./scripts/score.sh strategic-consultant/SKILL.md
```

**Output:** `skills/strategic-consultant/SKILL.md` (1200+ lines, score 9.2)

---

## Example 8: EVALUATE — Certification Flow

**Input:** `"certify skills/production/SKILL.md"`

**Runtime behavior:**
```
1. Parse intent → EVALUATE mode (certification path)
2. Run: ./scripts/score.sh skills/production/SKILL.md
3. Run: ./scripts/score-v2.sh skills/production/SKILL.md
4. Run: ./scripts/score-secure.sh skills/production/SKILL.md
5. Check thresholds: Text ≥ 8.0, Runtime ≥ 8.0, Variance < 1.0
6. If all pass → CERTIFIED; else → RESTORE or TUNE
```

**Output:**
```
Text Score: 8.4/10
Runtime Score: 8.6/10
Variance: 0.2
Overall: 8.5/10
Status: CERTIFIED ✓
```

---

## Example 9: RESTORE — Quick Fix (< 5 min)

**Input:** `"fix my skill's error handling section"`

**Runtime behavior:**
```
1. Parse intent → RESTORE mode (targeted fix)
2. Score current state: Error Handling dimension only
3. Diagnose: Missing recovery strategies, no anti-patterns section
4. Apply fixes: Add named failure modes, recovery steps
5. Re-evaluate: Error Handling 5→8
```

**Output:**
```
Error Handling: 5/10 → 8/10 (+3)
Target dimension fixed without full restore
```

---

## Example 10: TUNE — Multi-Round Optimization

**Input:** `"tune skills/price-extractor/SKILL.md --target 9.5 --max-rounds 50"`

**Runtime behavior:**
```
Round 1-10: System Prompt improvements (§1.1/1.2/1.3)
Round 11-20: Domain data additions (specific benchmarks)
Round 21-30: Workflow refinement (Done/Fail criteria)
Round 31-40: Examples expansion (5+ scenarios)
Round 41-50: Error handling hardening

After 47 rounds: Score 9.55/10 (target reached)
```

**Output:** `results.tsv` with 47 rounds, final score 9.55/10, 38 keep, 9 discard
