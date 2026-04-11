# Edit Audit Guard

> **Purpose**: Prevent destructive rewrites during OPTIMIZE and UTE micro-patch cycles.
> **Load**: When §9 (OPTIMIZE) or §15 (UTE Injection) of `claude/skill-writer.md` is accessed.
> **Inspired by**: SkillClaw's "rewrite-like" rejection rule (50%+ section modifications blocked).
> **Enforcement**: `[ENFORCED]` — AI applies this via content comparison reasoning within a session.

---

## §1  Why Edit Guards

Without limits, OPTIMIZE can drift into destroying what works:

- A skill scoring SILVER (800) may have excellent Error Handling (90/100) and weak Examples (55/100)
- Unconstrained OPTIMIZE might rewrite Error Handling to "fix" Examples — net result: degradation
- SkillClaw data shows "rewrite-like" improvements (>50% modification) destabilize skill quality

**The guard enforces surgical edits** — change the minimum to achieve the target improvement.

---

## §2  Change-Size Classification

After each OPTIMIZE round, classify the change against the *previous* version:

| Class | Change Fraction | Rule |
|-------|----------------|------|
| **MICRO** | ≤ 5% | Eligible for UTE micro-patch (keyword/metadata only) |
| **MINOR** | 6–30% | Allowed — standard targeted optimization |
| **MAJOR** | 31–50% | Allowed with warning — requires explicit confirmation |
| **REWRITE** | > 50% | **Blocked** — redirect to CREATE new skill instead |

---

## §3  Change Fraction Estimation `[ENFORCED via reasoning]`

The AI estimates change fraction by comparing the *before* and *after* skill content.
No code execution is needed — use structural reasoning:

```
MEASURE change fraction:

1. Count total §-sections in original skill.
2. For each §-section, judge: UNCHANGED | LIGHTLY_MODIFIED | HEAVILY_MODIFIED | ADDED | REMOVED
   - LIGHTLY_MODIFIED:   minor wording, added ≤2 sentences, fix typo
   - HEAVILY_MODIFIED:   restructured, ≥30% of section content changed
   - ADDED or REMOVED:   entire section added or removed

3. changed_sections = count of (HEAVILY_MODIFIED + ADDED + REMOVED)
4. total_sections   = max(original_count, new_count)
5. change_fraction  = changed_sections / total_sections

EXAMPLE:
  Original: 12 sections
  After:    12 sections, of which 7 are HEAVILY_MODIFIED or ADDED/REMOVED
  Fraction: 7/12 = 58% → REWRITE class → BLOCKED
```

---

## §4  Guard Actions by Class

### MICRO (≤ 5%)
- Continue without restriction
- UTE micro-patch eligible: keyword add, ZH trigger, metadata update
- No special logging required

### MINOR (6–30%)
- Continue without restriction
- Log dimension targeted and expected delta

### MAJOR (31–50%)

Before applying:
1. Display warning: "⚠ MAJOR change detected (~X%). Confirm to proceed."
2. List which sections will change significantly
3. Require explicit user confirmation: "yes" / "proceed" / "apply"
4. If user does not confirm → rollback proposal, switch to alternative strategy

### REWRITE (> 50%) — BLOCKED

```
REWRITE GUARD TRIGGERED

The proposed change modifies > 50% of the skill's content.
This exceeds the edit guard threshold and is blocked to prevent skill drift.

Current skill: <name> v<version>
Estimated change fraction: ~X%
Sections significantly affected: [list]

Options:
  1. [OPTIMIZE with constraint] Target only the lowest-scoring dimension (<dim>)
     and limit changes to that section only.
  2. [CREATE new skill] Use the improved version as the basis for a new skill
     (preserves the original; no destructive overwrite).
  3. [Override — EXPERT MODE] Proceed anyway. Requires explicit: "override edit guard"
     This option is logged and flags the skill for mandatory re-evaluation.

Which option do you choose?
```

---

## §5  Exemptions

The following changes are ALWAYS allowed regardless of fraction:

| Change | Reason |
|--------|--------|
| YAML frontmatter updates (version, dates, UTE fields) | Metadata — never affects skill logic |
| Adding new §N sections | Additive — doesn't break existing behavior |
| Correcting P0 security violations (CWE-798, CWE-89, CWE-78) | Safety override — always apply |
| Fixing factual errors in examples | Correctness override |

---

## §6  Override Logging

When the user invokes "override edit guard", record:

```json
{
  "timestamp": "<ISO-8601>",
  "skill_name": "<name>",
  "skill_version": "<before-version>",
  "edit_class": "REWRITE",
  "change_fraction_estimated": 0.62,
  "override_reason": "user explicit",
  "requires_reeval": true,
  "flag": "MANDATORY_REEVALUATION_BEFORE_PRODUCTION"
}
```

After an override, the skill MUST pass full EVALUATE (not just LEAN) before delivery.

---

## §7  Integration with OPTIMIZE Loop

In the 9-step loop (§9 of skill-framework.md), the edit guard runs at **Step 5** (IMPLEMENT):

```
Step 5 — IMPLEMENT (with edit guard):
  a. Generate the proposed change for target dimension
  b. Estimate change fraction
  c. IF REWRITE class → apply REWRITE guard (§4 above), do NOT apply change
  d. IF MAJOR class → display warning, await confirmation
  e. IF MINOR or MICRO → apply change
  f. Continue to Step 6 (VERIFY)
```

---

## §8  Integration with UTE Micro-Patch

UTE micro-patches are always MICRO class by definition:
- Add/modify trigger keywords → MICRO
- Add ZH equivalent trigger → MICRO
- Update metadata fields → MICRO

If a UTE analysis reveals a need for MINOR or larger changes, it must escalate
to full OPTIMIZE mode — not apply the change itself.

```
UTE Escalation Paths:
  MICRO issues  → apply as micro-patch (§5 of refs/use-to-evolve.md)
  MINOR issues  → queue in .skill-audit/evolution-queue.jsonl for OPTIMIZE
  MAJOR issues  → queue + notify user immediately
  REWRITE       → notify user; suggest CREATE new skill
```
