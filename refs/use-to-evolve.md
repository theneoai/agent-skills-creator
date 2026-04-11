# Use-to-Evolve (UTE) Specification

> **Purpose**: Protocol for injecting self-improvement capability into any skill.
> **Load**: When §15 (UTE Injection) of `claude/skill-writer.md` is accessed.
> **Main doc**: `claude/skill-writer.md §15`

---

> ### Enforcement Level Summary
>
> | Component | Level | Reason |
> |-----------|-------|--------|
> | Feedback signal detection (correction / approval) | `[ENFORCED]` | Observable within a single turn |
> | Trigger miss detection (user rephrasing) | `[ENFORCED]` | Observable within session |
> | Micro-patch proposal & user confirmation | `[ENFORCED]` | Single-session action |
> | LEAN score after micro-patch | `[ENFORCED]` | Computed in same session |
> | `cumulative_invocations` counter | `[ASPIRATIONAL]` | Resets across LLM sessions |
> | Cadence checks (every 10/50/100 calls) | `[ASPIRATIONAL]` | Requires persistent counter |
> | `last_ute_check` / `pending_patches` fields | `[ASPIRATIONAL]` | Cross-session state |
> | Audit trail in `.skill-audit/` | `[ASPIRATIONAL]` | Requires external file system |
>
> **Workaround for `[ASPIRATIONAL]` items**: Treat each invocation as potentially the
> Nth invocation. Run a lightweight check every invocation if session context is fresh.
> For true cadence gating, connect an optional persistence backend (see §5).

---

## §1  Concept

**Use-to-Evolve** (UTE) makes a skill self-improving through actual use.
The AI, upon recognizing a `use_to_evolve:` block in a skill's YAML frontmatter,
follows this protocol to observe usage patterns and propose improvements.

```
User invokes skill
        │
        ▼
  Skill executes normally
        │
        ▼
  AI observes outcome
    ├─ Note feedback signal (correction / approval / none)
    ├─ Track trigger misses (user rephrased request)
    └─ Periodically assess skill health
              │
    ┌─────────┴──────────┐
    │ no action needed   │ improvement identified
    └─────────┬──────────┘       │
              │             ASSESS severity
              ▼                  │
          continue        ┌──────┴──────┐
                      MICRO  |     SUGGEST
                      PATCH  |     OPTIMIZE
                     (minor) |    (structural)
```

**Key constraint**: The skill never self-modifies mid-session.
Patches are proposed to the user; applied only on confirmation.

---

## §2  YAML Frontmatter Block

Every skill with UTE enabled **must** include a `use_to_evolve:` block in its YAML frontmatter with all 11 fields:

```yaml
use_to_evolve:
  enabled: true                          # (bool) UTE active
  injected_by: "skill-writer v2.0.0"    # (string) injector version
  injected_at: "2026-04-01"             # (ISO-8601) injection date
  check_cadence:                         # (dict) invocation thresholds
    lightweight: 10                      #   lightweight check every N invocations
    full_recompute: 50                   #   full metric recompute every N
    tier_drift: 100                      #   tier drift check every N
  micro_patch_enabled: true             # (bool) allow trigger keyword patches
  feedback_detection: true              # (bool) detect user feedback signals
  certified_lean_score: 390             # (int) baseline LEAN score for drift detection
  last_ute_check: null                  # (ISO-8601 | null) when last check ran
  pending_patches: 0                    # (int) staged but unapplied patches
  total_micro_patches_applied: 0        # (int) cumulative patches applied
  cumulative_invocations: 0             # (int) total invocations (cadence counter)
```

> **Note**: Phase 4 certification checks that all 11 fields are present. Missing any field fails the UTE injection check (−60 points).

---

## §3  Feedback Signal Detection

When the AI observes user responses after skill output, it classifies the feedback:

| Signal | What the AI Looks For | Classification |
|--------|----------------------|----------------|
| **correction** | "that's wrong", "不对", user provides alternative | `failure` |
| **rephrasing** | Same request rephrased without acceptance | `trigger_miss` |
| **approval** | "thanks", "perfect", "好的", user proceeds normally | `success` |
| **abandon** | Topic switches or session ends immediately | `ambiguous` |
| **none** | No follow-up signal | `neutral` |

**On correction**: Note that the skill produced incorrect output — indicates need for OPTIMIZE.
**On rephrasing**: Note the alternative phrasing as a trigger keyword candidate.
**On repeated pattern** (≥3 similar corrections): Propose a micro-patch or suggest OPTIMIZE.

---

## §4  Cadence-Gated Health Checks

The AI performs periodic assessments based on approximate invocation counts:

### Every ~10 invocations: Lightweight Check
- Review recent interactions: Are users getting what they need?
- Note recurring trigger misses or corrections
- If repeated failures detected → propose micro-patch or suggest OPTIMIZE

### Every ~50 invocations: Quality Assessment
- Estimate overall skill health: trigger accuracy, output quality, user satisfaction
- Compare against quality thresholds (F1 ≥ 0.90, MRR ≥ 0.85, trigger_accuracy ≥ 0.90)
- On any threshold concern → suggest running EVALUATE or OPTIMIZE

### Every ~100 invocations: Tier Drift Check
- Estimate whether skill quality has drifted from its certified baseline
- If significant drift detected (estimated score drop > 50 pts) → suggest full EVALUATE

---

## §5  Micro-Patch Protocol

Micro-patches are **atomic, minor changes** proposed for surface-level improvements.
They NEVER affect the skill's core logic — only trigger keywords or metadata.

### Eligible Changes (Micro-Patch)

| Change | Condition | Scope |
|--------|-----------|-------|
| Add trigger keyword | ≥3 users rephrased with same term | YAML + mode trigger list |
| Add ZH trigger | ZH input frequently unrecognized | Mode trigger list |
| Update `updated` date | Any patch applied | YAML frontmatter only |
| Bump patch version | Any patch applied | YAML `version` field |

### Ineligible Changes (Must OPTIMIZE)

- Structural section changes (add/remove phases)
- Output contract changes
- Security baseline changes
- Any change touching Red Lines

### Patch Application

1. **PROPOSE** — AI describes the patch and reason to the user
2. **CONFIRM** — User approves or rejects
3. **APPLY** — AI applies the change
4. **VERIFY** — Run LEAN eval on patched version; rollback if score drops > 10 pts

---

## §6  Safety Constraints

| Constraint | Rule |
|-----------|------|
| No mid-session modification | Propose patches; never apply during active task |
| User confirmation required | All patches require explicit user approval |
| Rollback always available | Pre-patch version can be restored |
| Structural changes blocked | Only trigger keywords and metadata eligible |
| Security scan required | Check for P0 patterns before applying any patch |
| Patch size limit | Max 5 micro-patches per skill per session |
| Edit guard integration | All UTE patches are MICRO class; structural changes escalate to OPTIMIZE (see `refs/edit-audit.md`) |

---

## §7  UTE 2.0 — Two-Tier Architecture

UTE operates at two tiers. Both tiers share the same feedback signals and micro-patch
protocol; they differ in *scope* (single-user vs. multi-user) and *persistence requirements*.

### L1: Single-User UTE (current)

- **Scope**: One user, one session, one skill
- **Enforcement**: `[ENFORCED]` — runs fully within a single LLM session
- **Trigger source**: Feedback signals observed in the current conversation
- **Output**: Micro-patch proposals (keywords/metadata) or OPTIMIZE queue entries
- **State**: Session-local only; no cross-session persistence required

This is the complete implementation described in §1–§6 above.

### L2: Collective UTE `[ASPIRATIONAL — requires external tooling]`

> **`[ASPIRATIONAL]`**: L2 requires external storage and the COLLECT + AGGREGATE pipeline.
> See `refs/session-artifact.md` and `skill-framework.md §17` for full spec.

- **Scope**: Multiple users, multiple sessions, one skill (or skill cluster)
- **Enforcement**: `[ASPIRATIONAL]` — requires Session Artifact storage and AGGREGATE pipeline
- **Trigger source**: Aggregated patterns from N session artifacts
- **Output**: Evidence-backed evolution proposals (stronger signal than single-session L1)
- **State**: Persistent storage (`sessions/` directory in shared storage backend)

**Key insight** (from SkillClaw research): L2 collective evolution produces measurably better
skills than L1 single-user optimization — not because of bigger models, but because broader
usage data reveals blind spots that single-user testing misses.

### Relationship between tiers

```
Single user interacts with skill
         │
         ▼
L1 UTE fires (every session)
   ├─ Detect feedback signals
   ├─ Propose micro-patches
   └─ Generate Session Artifact (if COLLECT mode active)
         │
         ▼ (optional, requires backend)
L2 Collective pipeline
   ├─ Session Artifact → sessions/ queue
   ├─ AGGREGATE (Summarize → Aggregate → Execute)
   └─ Cross-user evolution proposals → stronger OPTIMIZE suggestions
```

### L2 Minimum Viable Flow (no backend required)

Even without an external backend, L2 benefits are accessible manually:

1. User runs COLLECT mode after each session → downloads Session Artifact JSON
2. After N sessions (or across multiple users sharing artifacts): paste artifacts into AGGREGATE mode
3. AGGREGATE synthesizes cross-session patterns into ranked improvement list
4. Apply improvements via standard OPTIMIZE mode

This manual flow degrades gracefully to near-L2 quality with zero infrastructure cost.
