# Self-Evolution Specification

> **Purpose**: 5-trigger evolution system, decision thresholds, and continuous improvement logic.
> **Load**: When §10 (Self-Evolution) of `claude/skill-writer.md` is accessed.
> **Main doc**: `claude/skill-writer.md §10`
> **v3.1.0**: Added Trigger 4 (OWASP Pattern Violation) and Trigger 5 (Skill Tier Drift)

---

> ### Enforcement Level Guide
>
> | Tag | Meaning |
> |-----|---------|
> | `[CORE]` | Executes fully within a single session; no external persistence required |
> | `[EXTENDED]` | Requires cross-session audit logs, persistent counters, or external schedulers |
> | `[ENFORCED — needs external trigger]` | Logic is clear and executable, but activation depends on external cron/scheduler |
>
> **For `[EXTENDED]` items**: AI applies the described logic where possible within the
> current session; cross-session tracking requires an optional external backend
> (see §4 of this document).

---

## §1  Five-Trigger System

Skills are monitored continuously. Any of five independent triggers can initiate evolution.

### Trigger 1 — Threshold-Based (Quality Degradation)

| Metric | Threshold | Action |
|--------|-----------|--------|
| F1 score | < 0.90 | Auto-flag → queue for OPTIMIZE |
| MRR score | < 0.85 | Auto-flag → queue for OPTIMIZE |
| Trigger accuracy | < 0.90 | Strategy S1 (keyword expansion) |
| Error rate | > 5% per 100 calls | Flag for immediate review |
| Error rate | > 10% per 100 calls | Immediate HUMAN_REVIEW escalation |
| Tier downgrade | Drops 1+ tier | Investigate root cause → OPTIMIZE |

**Detection method** `[EXTENDED]`: Score tracked in `.skill-audit/framework.jsonl`.
Check after every invocation. Compare rolling 30-invocation average.
> **`[EXTENDED]`**: Persistent `.skill-audit/` log and rolling 30-invocation counter require
> external storage. LLM sessions are stateless — cross-session tracking needs an optional backend.

---

### Trigger 2 — Time-Based (Staleness Prevention) `[ENFORCED — needs external trigger]`

| Condition | Threshold | Action |
|-----------|-----------|--------|
| No update to skill | 30 days | Schedule staleness LEAN eval |
| No update after staleness eval | 60 days total | Auto-route to OPTIMIZE |
| No update after OPTIMIZE | 90 days total | HUMAN_REVIEW: deprecate? |

**Detection method**: Compare `updated` field in YAML frontmatter to current date.
Run daily cron check (or on each invocation if cron unavailable).
> **`[ENFORCED — needs external trigger]`**: The comparison logic is straightforward and
> AI-executable (current date vs. frontmatter `updated` field). The 30-day *automatic* trigger
> requires an external scheduler; on-invocation checks are fully `[CORE]`.

---

### Trigger 3 — Usage-Based (Relevance Check) `[EXTENDED]`


| Condition | Threshold | Action |
|-----------|-----------|--------|
| Invocations | < 5 in 90 days | Present: deprecate \| maintain \| refocus |
| Invocations | 0 in 60 days | Auto-deprecate candidate (pending human confirmation) |
| Invocations | < 10 in 90 days AND tier < SILVER | Deprecate or refocus |

**Metrics tracked** `[EXTENDED]` (in `.skill-audit/usage.jsonl`):
```json
{
  "skill_name": "<name>",
  "period_days": 90,
  "invocation_count": 0,
  "success_count": 0,
  "failure_count": 0,
  "avg_latency_ms": 0,
  "trigger_accuracy": 0.00,
  "last_invoked": "<ISO-8601>"
}
```

---

### Trigger 4 — OWASP Pattern Violation `[CORE]`

> v3.1.0: New trigger. Security scan results now feed directly into evolution decisions.
> Full patterns: `claude/refs/security-patterns.md §5`

| Condition | Severity | Action |
|-----------|----------|--------|
| P0 violation found (CWE-798/89/78) | CRITICAL | ABORT delivery → HUMAN_REVIEW immediately |
| ASI01 prompt injection pattern detected | P1 ERROR | Flag → queue OPTIMIZE with strategy S8 |
| ASI02 unvalidated tool chaining detected | P1 WARNING | Flag → queue OPTIMIZE with strategy S8 |
| ASI05 unconstrained irreversible action | P1 WARNING | Flag → queue OPTIMIZE with strategy S8 |
| P1 violation added since last version | WARNING | Re-run security scan before next delivery |

**Detection method** `[CORE]`: Triggered by security scan in Phase 4 of EVALUATE,
or by the ASI01-ASI10 heuristic checks in LEAN. Any P0/P1 finding fires this trigger
regardless of current tier or score.

---

### Trigger 5 — Skill Tier Drift `[CORE]`

> v3.1.0: New trigger. `skill_tier` (planning/functional/atomic) changes must be validated.
> Research basis: SkillX arxiv:2604.04804 — tier misclassification degrades composability in multi-tier pipelines.

| Condition | Action |
|-----------|--------|
| `skill_tier` changed from previous version | Force full EVALUATE (not just LEAN) |
| `skill_tier` not declared in YAML frontmatter | Phase 1 deduction; warn + add field |
| `skill_tier` = "planning" but no sub-skill references | Advisory: verify tier is correct |
| `skill_tier` = "atomic" but skill calls external tools | Advisory: verify tier is correct |

**Detection method** `[CORE]`: Compare `skill_tier` in current YAML frontmatter
against registry history (§3 of refs/skill-registry.md). If changed → fire trigger.
Within a single session: any edit to `skill_tier` field fires this trigger immediately.

---

## §2  Decision Engine

When a trigger fires, the decision engine determines the right action:

```
TRIGGER FIRED
    │
    ▼
┌──────────────────────────────────────────────────────────────────┐
│ ASSESS current state                                             │
│   current_tier = PLATINUM | GOLD | SILVER | BRONZE | FAIL        │
│   current_score = last total_score from audit log               │
│   lowest_dimension = from last EVALUATE report                  │
└──────────────────────────────────────────────────────────────────┘
    │
    ▼
┌──────────────────────────────────────────────────────────────────┐
│ DECIDE action                                                    │
│                                                                  │
│ score ≥ 900 (GOLD+) AND trigger = time/usage                    │
│   → LEAN eval only; if still GOLD+ → no change needed           │
│                                                                  │
│ score 700–899 (BRONZE–SILVER) AND F1/MRR below threshold        │
│   → OPTIMIZE targeting lowest_dimension (S1–S5)                 │
│                                                                  │
│ score < 700 (FAIL) OR error_rate > 10%                          │
│   → HUMAN_REVIEW immediately                                    │
│                                                                  │
│ trigger_accuracy < 0.85                                          │
│   → Strategy S1 (keyword expansion) only                        │
│                                                                  │
│ tier dropped 1+ level since last check                          │
│   → Full EVALUATE → diagnose root cause → OPTIMIZE             │
│                                                                  │
│ usage < 5 in 90d                                                 │
│   → Present options to user: [deprecate | maintain | refocus]   │
│                                                                  │
│ P0 security violation found (Trigger 4)                         │
│   → ABORT → HUMAN_REVIEW immediately; do NOT run OPTIMIZE       │
│                                                                  │
│ P1 security violation found (Trigger 4)                         │
│   → OPTIMIZE with S8 (Security Baseline) first                  │
│                                                                  │
│ skill_tier changed (Trigger 5)                                   │
│   → Force full EVALUATE; log tier change in registry history     │
└──────────────────────────────────────────────────────────────────┘
```

---

## §3  Usage Metrics Collection

Track per-skill on every invocation:

```python
# Pseudocode for usage tracking
def track_invocation(skill_name, mode, success, latency_ms, trigger_matched):
    entry = {
        "timestamp": now_iso(),
        "skill_name": skill_name,
        "mode": mode,
        "success": success,
        "latency_ms": latency_ms,
        "trigger_matched": trigger_matched
    }
    append(".skill-audit/usage.jsonl", entry)

# Compute rolling metrics (last 90 days)
def compute_rolling_metrics(skill_name):
    entries = load_entries(skill_name, days=90)
    return {
        "invocation_count": len(entries),
        "success_count": sum(e.success for e in entries),
        "failure_count": sum(not e.success for e in entries),
        "error_rate": failure_count / max(invocation_count, 1),
        "avg_latency_ms": mean(e.latency_ms for e in entries),
        "trigger_accuracy": sum(e.trigger_matched for e in entries) / invocation_count
    }
```

---

## §4  Evolution Cycle Log

Each evolution cycle appends to `.skill-audit/evolution.jsonl`:

```json
{
  "timestamp": "<ISO-8601>",
  "skill_name": "<name>",
  "trigger_type": "threshold|time|usage|owasp_scan|tier_drift",
  "trigger_detail": "<specific condition>",
  "pre_evolution_score": 0,
  "pre_evolution_tier": "<tier>",
  "post_evolution_score": 0,
  "post_evolution_tier": "<tier>",
  "optimize_cycles": 0,
  "strategies_applied": ["S1", "S2"],
  "converged": false,
  "convergence_signal": "volatility|plateau|trend|max_rounds",
  "outcome": "IMPROVED|STABLE|DEGRADED|HUMAN_REVIEW"
}
```

---

## §5  Interaction with Convergence

Before starting a new OPTIMIZE cycle, check convergence signals
(see `claude/refs/convergence.md`):

```
IF volatility_check PASSES (stddev < threshold)
    → STABLE: skip OPTIMIZE, mark as "no improvement expected"

IF plateau_check PASSES (>70% deltas < 0.5)
    → PLATEAUED: one more targeted cycle, then escalate

IF trend_check = IMPROVING
    → CONTINUE: current strategy working, keep going

IF trend_check = DIVERGING
    → HALT: strategies are making things worse; HUMAN_REVIEW
```

---

## §7  Live Feedback Loop (UTE Tier)

UTE (Use-to-Evolve) is a **Tier 0** evolution layer that fires before the 3-trigger system.
It collects real usage signals inline — no batch jobs, no scheduled checks required.

```
Invocation N
    │
    ▼
UTE Post-Hook fires (inline)
    ├─ Record usage entry
    ├─ Detect feedback signal
    └─ Cadence check
          │
   ┌──────┴───────┐
   │ micro-patch  │ structural issue
   │ candidate    │ → evolution-queue.jsonl
   └──────┬───────┘
          │
   Staged patch
   (applied next session)
          │
          ▼
   Tier 0 metrics feed into
   3-Trigger System (§1–§2)
```

**Relationship to 3-Trigger System**:

| Tier | System | Fires When | Scope |
|------|--------|-----------|-------|
| 0 | UTE | Every invocation | Micro-patches (triggers, metadata) |
| 1 | Threshold | F1/MRR breach | OPTIMIZE cycles |
| 2 | Time | 30-day staleness | LEAN → OPTIMIZE |
| 3 | Usage | 90-day inactivity | Deprecation review |
| 4 | OWASP Scan | P0/P1 pattern found | Security remediation (S8 or ABORT) |
| 5 | Tier Drift | skill_tier changed | Force full EVALUATE |

**Data flow**: UTE usage.jsonl → Tier 1 threshold check reads this same file.
`compute_rolling_metrics()` in §3 works identically whether data came from
UTE hooks or manual invocations. No separate data source needed.

**Queue consumption**: When Tier 1 fires an OPTIMIZE cycle, it reads
`.skill-audit/evolution-queue.jsonl` written by UTE as the starting point
for dimension analysis (§2 decision engine). This means UTE-collected signals
directly influence which strategy is applied first — closing the feedback loop.

Full UTE spec: `claude/refs/use-to-evolve.md`

---

## §6  Staleness Review Workflow

When time-based trigger fires (30 days no update):

```
1. Run LEAN eval → record lean_score
2. IF lean_score ≥ 450 (GOLD proxy):
     → Mark "staleness_review: PASS" in audit
     → Reset staleness timer (next check in 30 days)
3. IF lean_score 350–449:
     → Run full EVALUATE
     → IF CERTIFIED ≥ SILVER → staleness PASS, reset timer
     → IF BRONZE or FAIL → auto-route to OPTIMIZE
4. IF lean_score < 350:
     → Flag: "STALE — immediate OPTIMIZE recommended"
     → Notify user with current score + lowest dimension
```
