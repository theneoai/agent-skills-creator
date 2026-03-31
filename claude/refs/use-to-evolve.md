# Use-to-Evolve (UTE) Specification

> **Purpose**: Protocol for injecting live self-improvement capability into any skill.
> **Load**: When §15 (UTE Injection) of `claude/skill-framework.md` is accessed.
> **Main doc**: `claude/skill-framework.md §15`

---

## §1  Concept

**Use-to-Evolve** (UTE) makes a skill self-improving through actual use.
Every invocation is an observation. Accumulated observations drive micro-patches
that keep the skill accurate — without waiting for a scheduled OPTIMIZE run.

```
User invokes skill
        │
        ▼
  Skill executes normally
        │
        ▼
  POST-INVOCATION HOOK fires (end of every call)
    ├─ Record usage entry (.skill-audit/usage.jsonl)
    ├─ Detect implicit feedback signal
    └─ Check evolution triggers (cadence-gated)
              │
    ┌─────────┴──────────┐
    │ trigger NOT fired  │ trigger fired
    └─────────┬──────────┘       │
              │               ASSESS severity
              ▼                  │
          continue        ┌──────┴──────┐
                      MICRO  |     QUEUE for
                      PATCH  |     OPTIMIZE
                     (minor) |    (structural)
```

**Key constraint**: The skill never self-modifies mid-session.
Patches are proposed and staged; applied at session start or on user confirmation.

---

## §2  Post-Invocation Hook

Every skill with UTE enabled runs this hook at the **end of every invocation**:

### Step 1 — Record Usage

```json
// Append to .skill-audit/usage.jsonl
{
  "timestamp": "<ISO-8601>",
  "skill_name": "<name>",
  "skill_version": "<semver>",
  "mode": "<mode_that_ran>",
  "trigger_matched": true,
  "trigger_input": "<first 80 chars of user input>",
  "trigger_predicted_mode": "<mode>",
  "confidence": 0.00,
  "success": true,
  "latency_ms": 0,
  "feedback_signal": "none|correction|rephrasing|approval|abandon"
}
```

### Step 2 — Detect Feedback Signal

Scan the user's response (if any) immediately after the skill output:

| Signal | Detection Patterns | Classification |
|--------|-------------------|----------------|
| **correction** | "that's wrong", "不对", "incorrect", user provides alternative answer | `failure` |
| **rephrasing** | Same request rephrased within 2 turns without "yes" or acceptance | `trigger_miss` |
| **approval** | "perfect", "thanks", "好的", "correct", user proceeds without correction | `success` |
| **abandon** | Session ends or topic switches within 1 turn of skill output | `ambiguous` |
| **none** | No follow-up signal detected | `neutral` |

**Failure signal action**: mark `success: false`, log `failure_reason: "user_correction"`.
**Trigger miss action**: extract alternative phrasing → add to `ute_trigger_candidates` list.

### Step 3 — Check Evolution Triggers (Cadence-Gated)

```
invocation_count = load_count(skill_name)

IF invocation_count % 10 == 0:     # every 10 calls
    → run LIGHTWEIGHT CHECK (§4)

IF invocation_count % 50 == 0:     # every 50 calls
    → run FULL METRIC RECOMPUTE (§5)

IF invocation_count % 100 == 0:    # every 100 calls
    → run TIER DRIFT CHECK (§6)

ALWAYS:
    → check staleness (days since updated in YAML)
```

---

## §3  Feedback Signal Taxonomy

### Primary Signals (used to update rolling metrics)

| Signal Class | Weight in F1 | Weight in trigger_accuracy |
|-------------|-------------|--------------------------|
| `success` | TP = 1 | 1.0 if trigger_matched else 0.0 |
| `failure` (correction) | FN = 1 | 0.0 |
| `trigger_miss` (rephrasing) | FP = 0.5 (partial) | 0.0 |
| `ambiguous` | excluded from F1 | excluded |
| `neutral` | excluded from F1 | 1.0 if trigger_matched |

### Trigger Candidate Extraction

When signal = `trigger_miss`:
1. Extract the rephrasing that the user used.
2. Compare to existing trigger keywords — find the gap.
3. Add to `.skill-audit/trigger-candidates.jsonl`:
   ```json
   {"skill": "<name>", "candidate": "<new phrase>", "source": "rephrasing", "count": 1}
   ```
4. When `count ≥ 3` for a candidate → promote to Micro-Patch proposal (§7).

---

## §4  Lightweight Check (Every 10 Invocations)

Fast check, no LLM. Uses rolling window of last 20 invocations.

```
rolling_success_rate  = success_count / 20
rolling_trigger_acc   = trigger_matched_count / 20
consecutive_failures  = count of failures in last 5 calls

IF rolling_success_rate < 0.80:
    → flag: "high_failure_rate"
    → check: is the issue trigger routing or output quality?
    → if trigger mismatch > 60% of failures → MICRO-PATCH (keyword add)
    → if output mismatch > 60% → QUEUE for OPTIMIZE (D3 Workflow)

IF rolling_trigger_acc < 0.85:
    → MICRO-PATCH: promote top trigger candidate (count ≥ 3)

IF consecutive_failures ≥ 3:
    → immediate QUEUE for OPTIMIZE, surface to user:
      "⚠️ skill <name> has failed 3 consecutive calls — evolution queued."
```

---

## §5  Full Metric Recompute (Every 50 Invocations)

Uses last 50 invocations. Recomputes F1, MRR, trigger_accuracy from usage log.

```python
def full_metric_recompute(skill_name: str) -> dict:
    entries = load_last_n(skill_name, n=50)

    # F1
    TP = sum(1 for e in entries if e.success and e.trigger_matched)
    FP = sum(1 for e in entries if not e.success and e.trigger_matched)
    FN = sum(1 for e in entries if e.feedback_signal == "correction")
    precision = TP / max(TP + FP, 1)
    recall    = TP / max(TP + FN, 1)
    f1 = 2 * precision * recall / max(precision + recall, 0.001)

    # MRR (approximate from confidence scores)
    mrr = mean(1.0 if e.confidence >= 0.85 else
               0.5 if e.confidence >= 0.70 else 0.0
               for e in entries if e.feedback_signal != "ambiguous")

    # Trigger accuracy
    trigger_acc = sum(e.trigger_matched for e in entries) / len(entries)

    return {"f1": f1, "mrr": mrr, "trigger_accuracy": trigger_acc}
```

Compare computed metrics to thresholds (F1 ≥ 0.90, MRR ≥ 0.85, trigger_acc ≥ 0.90).
On any breach → consult evolution.md §2 decision engine → MICRO-PATCH or QUEUE.

---

## §6  Tier Drift Check (Every 100 Invocations)

Estimate current LEAN score from usage metrics without running a formal eval:

```
estimated_lean_score = (
    (f1 / 1.0)            * 0.30 * 500 +   # proxy for trigger quality
    (mrr / 1.0)           * 0.20 * 500 +   # proxy for routing quality
    (trigger_acc / 1.0)   * 0.25 * 500 +   # direct signal
    (1 - error_rate)      * 0.25 * 500     # reliability signal
)

IF estimated_lean_score < last_certified_lean_score - 50:
    → "Tier drift detected: estimated score dropped >50 pts since last cert"
    → Queue full EVALUATE (not just OPTIMIZE) at next opportunity
```

---

## §7  Micro-Patch Protocol

Micro-patches are **atomic, single-line changes** applied autonomously for minor issues.
They NEVER affect the skill's core logic — only surface-level trigger keywords or metadata.

### Eligible Changes (Micro-Patch)

| Change | Condition | Scope |
|--------|-----------|-------|
| Add trigger keyword | candidate count ≥ 3 AND trigger_acc < 0.90 | YAML + mode trigger list |
| Add ZH trigger | ZH input failure rate > 20% | mode trigger list |
| Update `updated` date | any patch applied | YAML frontmatter only |
| Bump patch version | any patch applied | YAML `version` field |

### Ineligible Changes (Must Queue for OPTIMIZE)

- Structural section changes (add/remove phases)
- Output contract changes
- Security baseline changes
- Any change touching Red Lines
- Any change requiring multi-LLM deliberation

### Patch Application Safety

```
1. PROPOSE   — write proposed diff to .skill-audit/pending-patches.jsonl
2. VALIDATE  — run LEAN eval on patched version (in memory, not committed)
   IF lean_score regresses > 10 pts → DISCARD patch, log reason
   IF lean_score stable or improves → proceed
3. STAGE     — write patch to .skill-audit/staged-patches/
4. APPLY     — apply at START of next session (not during active call)
   OR        — apply immediately if user confirms: "apply pending UTE patches"
5. VERIFY    — re-run LEAN eval on live skill after apply
   IF score drops → ROLLBACK (restore from pre-patch snapshot)
6. LOG       — record in .skill-audit/ute-patches.jsonl
```

### Patch Log Entry

```json
{
  "timestamp": "<ISO-8601>",
  "skill_name": "<name>",
  "patch_type": "add_trigger_keyword|add_zh_trigger|update_metadata",
  "change": {"field": "trigger_keywords.CREATE", "add": "scaffold"},
  "trigger_candidate_count": 4,
  "pre_patch_lean": 420,
  "post_patch_lean": 435,
  "applied": true,
  "rolled_back": false
}
```

---

## §8  UTE YAML Frontmatter

When UTE is injected into a skill, these fields are added to its YAML frontmatter:

```yaml
use_to_evolve:
  enabled: true
  injected_by: skill-framework v2.0.0
  injected_at: "<ISO-8601>"
  check_cadence: {lightweight: 10, full_recompute: 50, tier_drift: 100}
  micro_patch_enabled: true
  feedback_detection: true
  last_ute_check: null
  pending_patches: 0
  total_micro_patches_applied: 0
  cumulative_invocations: 0
```

---

## §9  Safety Constraints

| Constraint | Rule |
|-----------|------|
| No mid-session modification | Stage patches only; never apply during active call |
| Rollback always available | Pre-patch snapshot kept for 30 days |
| Human override | User can disable UTE: set `use_to_evolve.enabled: false` |
| Structural changes blocked | Only trigger keywords and metadata eligible for micro-patch |
| Security scan required | Run P0 security check before applying any patch |
| Patch size limit | Max 5 micro-patches per skill per session |
| Audit trail | Every patch (applied or discarded) logged to `.skill-audit/ute-patches.jsonl` |
