# Use-to-Evolve Snippet

> **Purpose**: Copy-paste ready `## Use-to-Evolve` section injected into skills by the framework.
> **Injected by**: `claude/skill-framework.md §15` during CREATE (Step 8) and OPTIMIZE (Step 7).
> **Full spec**: `claude/refs/use-to-evolve.md`

---

## How to inject

1. **Append** the section below verbatim to the target skill file (after the last `## §N` section).
2. **Update** the YAML frontmatter (see the YAML block at the bottom of this file).
3. **Adjust** the `SKILL_NAME`, `VERSION`, and `CERTIFIED_LEAN_SCORE` placeholders.

---

## Section to inject

```markdown
## §UTE  Use-to-Evolve

**Status**: enabled
**Spec**: `claude/refs/use-to-evolve.md`
**Injected**: {{INJECTION_DATE}} by skill-framework v{{FRAMEWORK_VERSION}}

This skill is self-improving. After every invocation the Post-Invocation Hook
fires automatically. Do not skip it.

### Post-Invocation Hook (run at end of EVERY call)

**Step 1 — Record usage** (append to `.skill-audit/usage.jsonl`):
```json
{
  "timestamp": "<now-ISO-8601>",
  "skill_name": "{{SKILL_NAME}}",
  "skill_version": "{{VERSION}}",
  "mode": "<mode that ran>",
  "trigger_matched": <true|false>,
  "trigger_input": "<first 80 chars of user input>",
  "confidence": <0.00–1.00>,
  "success": <true|false>,
  "latency_ms": <elapsed>,
  "feedback_signal": "none|correction|rephrasing|approval|abandon"
}
```

**Step 2 — Detect feedback signal** from user's immediate response:

| Pattern | Signal |
|---------|--------|
| "wrong", "不对", "incorrect", user corrects output | `correction` → `success: false` |
| Same request rephrased within 2 turns | `rephrasing` → add to trigger candidates |
| "thanks", "好的", "perfect", user proceeds | `approval` → `success: true` |
| Session ends or topic switches immediately | `abandon` → `ambiguous` |
| No follow-up | `none` → `neutral` |

If signal = `rephrasing`: extract new phrase → log to `.skill-audit/trigger-candidates.jsonl`
with `count +1`. When any candidate reaches `count ≥ 3` → flag for micro-patch.

**Step 3 — Check triggers** (cadence-gated; check cumulative_invocations):

```
invocations % 10  == 0 → LIGHTWEIGHT CHECK
invocations % 50  == 0 → FULL METRIC RECOMPUTE
invocations % 100 == 0 → TIER DRIFT CHECK
```

**Lightweight check** (last 20 calls):
- rolling_success_rate < 0.80 OR rolling_trigger_acc < 0.85 → see §UTE Trigger Actions
- ≥ 3 consecutive failures → surface warning + queue OPTIMIZE

**Full recompute** (last 50 calls):
- Recompute F1, MRR, trigger_accuracy from usage log
- F1 < 0.90 → queue OPTIMIZE (D3/D5 dimension)
- MRR < 0.85 → queue OPTIMIZE (D3 dimension)
- trigger_accuracy < 0.90 → micro-patch (keyword add) if candidates exist

**Tier drift check** (last 100 calls):
- estimated_lean < {{CERTIFIED_LEAN_SCORE}} − 50 → queue full EVALUATE

### Trigger Actions

| Condition | Action |
|-----------|--------|
| trigger_candidate count ≥ 3 | Micro-patch: add candidate as primary keyword |
| ZH input failure rate > 20% | Micro-patch: add ZH trigger for failing mode |
| rolling_success_rate < 0.80 | Queue OPTIMIZE targeting lowest dimension |
| ≥ 3 consecutive failures | Warn user + queue OPTIMIZE |
| F1 < 0.90 (recompute) | Queue OPTIMIZE |
| tier drift > 50 pts | Queue full EVALUATE |

### Micro-Patch Rules

**Eligible** (apply autonomously after LEAN validation):
- Add trigger keyword (YAML + mode section)
- Add ZH trigger equivalent
- Update `updated` date + bump patch version

**Ineligible** (must queue for OPTIMIZE via skill-framework):
- Structural section changes
- Output contract changes
- Security baseline changes
- Anything touching Red Lines

**Apply at**: start of next session OR when user says "apply UTE patches".
**Safety**: run LEAN eval before and after; rollback if score drops > 10 pts.

### Evolution Queue

Structural issues write to `.skill-audit/evolution-queue.jsonl`:
```json
{
  "timestamp": "<ISO-8601>",
  "skill_name": "{{SKILL_NAME}}",
  "reason": "<trigger condition>",
  "recommended_strategy": "S1|S2|S3|S4|S5",
  "target_dimension": "D1–D7",
  "priority": "high|medium|low"
}
```

Consume the queue by invoking skill-framework OPTIMIZE mode on this skill.
```

---

## YAML frontmatter additions

Add this block to the skill's YAML frontmatter (under `extends:`):

```yaml
use_to_evolve:
  enabled: true
  injected_by: "skill-framework v{{FRAMEWORK_VERSION}}"
  injected_at: "{{INJECTION_DATE}}"
  check_cadence: {lightweight: 10, full_recompute: 50, tier_drift: 100}
  micro_patch_enabled: true
  feedback_detection: true
  certified_lean_score: {{CERTIFIED_LEAN_SCORE}}
  last_ute_check: null
  pending_patches: 0
  total_micro_patches_applied: 0
  cumulative_invocations: 0
```

---

## Placeholders

| Placeholder | Source | Example |
|------------|--------|---------|
| `{{SKILL_NAME}}` | Skill's `name` field | `weather-query` |
| `{{VERSION}}` | Skill's `version` field | `1.0.0` |
| `{{FRAMEWORK_VERSION}}` | skill-framework version | `2.0.0` |
| `{{INJECTION_DATE}}` | Today's ISO-8601 date | `2026-03-31` |
| `{{CERTIFIED_LEAN_SCORE}}` | LEAN score from last EVALUATE | `460` |

---

## Injection Checklist

- [ ] `§UTE` section appended to skill (after last `## §N`)
- [ ] All 4 placeholders filled (SKILL_NAME, VERSION, FRAMEWORK_VERSION, INJECTION_DATE)
- [ ] CERTIFIED_LEAN_SCORE filled from last eval report (or use 350 if unknown)
- [ ] YAML frontmatter `use_to_evolve:` block added
- [ ] `.skill-audit/` directory exists (create if not)
- [ ] LEAN eval re-run after injection to confirm no regression
