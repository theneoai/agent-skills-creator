# Convergence Detection

> **Purpose**: Three-signal convergence algorithm used to stop optimization loops early.
> **Load**: When §9 (OPTIMIZE Loop) of `claude/skill-writer.md` is accessed.
> **Main doc**: `claude/skill-writer.md §9`

---

> ### Enforcement Level Guide
>
> | Tag | Meaning |
> |-----|---------|
> | `[CORE]` | AI can execute this fully within a single session/prompt |
> | `[EXTENDED]` | Requires external state, code execution, or cross-session persistence that LLMs cannot natively provide |
>
> When you see `[EXTENDED]`, treat the algorithm as **authoritative design intent** but implement
> it via natural-language reasoning rather than literal code execution.

---

## §1  Why Convergence Detection

The 10-step optimization loop (§9 of skill-writer.md) runs up to 20 rounds.
Without convergence detection, it wastes compute on loops where:
- Scores have stabilized (volatility check)
- All easy gains are exhausted (plateau check)
- The strategy is actively making things worse (trend check — DIVERGING)

The loop checks all three signals after every round. **Any convergence signal
triggers early stopping.**

---

## §2  Signal 1 — Volatility Check `[EXTENDED]`

> **Note `[EXTENDED]`**: The Python implementation below is **design documentation**,
> not executable code. AI implements this signal via natural-language reasoning:
> *"If the last N scores differ by less than 2 points, declare convergence."*

**Purpose**: Detect when scores have stabilized (low variance across recent rounds).

**Algorithm** *(reference implementation — not executed by AI)*:
```python
def volatility_check(score_history: list[float], window: int = 10) -> bool:
    """
    Returns True (CONVERGED) if the standard deviation of the last `window`
    scores is below the threshold.
    """
    if len(score_history) < window:
        return False  # not enough data yet

    recent = score_history[-window:]
    mean = sum(recent) / len(recent)
    variance = sum((x - mean) ** 2 for x in recent) / len(recent)
    stddev = variance ** 0.5

    # Threshold: 2.0 score points (on 1000-point scale)
    return stddev < 2.0
```

**Interpretation**:
- `stddev < 2.0` → scores are essentially flat → no more gains from current strategy
- Action: **STOP loop**, declare convergence signal = `"volatility"`

---

## §3  Signal 2 — Plateau Check `[EXTENDED]`

> **Note `[EXTENDED]`**: AI applies this via reasoning:
> *"If >70% of recent round-to-round deltas are <0.5 pts AND total gain is ≤0, declare plateau."*

**Purpose**: Detect when incremental improvements have become negligible.

**Algorithm** *(reference implementation — not executed by AI)*:
```python
def plateau_check(score_history: list[float], window: int = 10) -> bool:
    """
    Returns True (CONVERGED) if:
    - More than 70% of round-to-round deltas are below 0.5 pts
    - AND total delta over the window is ≤ 0 (not improving overall)
    """
    if len(score_history) < window:
        return False

    recent = score_history[-window:]
    deltas = [abs(recent[i] - recent[i-1]) for i in range(1, len(recent))]

    small_delta_pct = sum(1 for d in deltas if d < 0.5) / len(deltas)
    total_delta = recent[-1] - recent[0]

    return small_delta_pct > 0.70 and total_delta <= 0
```

**Interpretation**:
- Most rounds produce < 0.5-point gain AND overall trend is flat or negative
- Action: **STOP loop**, declare convergence signal = `"plateau"`

---

## §4  Signal 3 — Trend Check `[ENFORCED via reasoning]`

> **Note `[ENFORCED via reasoning]`**: AI can compare first-half vs. second-half score means
> by reasoning over the scores listed in the OPTIMIZE loop transcript.
> No external execution required.

**Purpose**: Detect whether the optimization trajectory is improving, stable, or diverging.

**Algorithm** *(reference implementation)*:
```python
def trend_check(score_history: list[float]) -> str:
    """
    Returns "IMPROVING", "STABLE", or "DIVERGING".
    Compares the mean of the first half vs the mean of the second half.
    """
    if len(score_history) < 4:
        return "IMPROVING"  # too early to judge

    mid = len(score_history) // 2
    first_half_mean = sum(score_history[:mid]) / mid
    second_half_mean = sum(score_history[mid:]) / (len(score_history) - mid)

    delta = second_half_mean - first_half_mean

    if delta > 5.0:    # ≥5 pts improvement → IMPROVING
        return "IMPROVING"
    elif delta < -5.0: # ≥5 pts degradation → DIVERGING
        return "DIVERGING"
    else:              # within ±5 pts → STABLE
        return "STABLE"
```

**Interpretation and actions**:

| Result | Meaning | Action |
|--------|---------|--------|
| IMPROVING | Current strategy is working | Continue loop |
| STABLE | No clear improvement | Switch to different strategy or stop |
| DIVERGING | Strategy is making things worse | **HALT immediately** → HUMAN_REVIEW |

---

## §5  Combined Convergence Decision

All three signals are checked after every optimization round:

```python
def should_stop(score_history: list[float], current_round: int) -> tuple[bool, str]:
    """
    Returns (stop: bool, reason: str).
    """
    # Hard stop
    if current_round >= 20:
        return True, "max_rounds"

    # Volatility: stop if stable
    if volatility_check(score_history):
        return True, "volatility"

    # Plateau: stop if exhausted
    if plateau_check(score_history):
        return True, "plateau"

    # Trend: stop if diverging
    trend = trend_check(score_history)
    if trend == "STABLE" and current_round >= 5:
        return True, "trend_stable"
    if trend == "DIVERGING":
        return True, "trend_diverging"

    return False, "continue"
```

---

## §6  Post-Convergence Actions

| Signal | Action |
|--------|--------|
| `volatility` | Declare final score; proceed to Step 10 VERIFY; certify at VERIFY tier |
| `plateau` | Try one final alternative strategy; if no improvement → proceed to Step 10 VERIFY |
| `trend_stable` | Proceed to Step 10 VERIFY; log "plateau reached at round N" |
| `trend_diverging` | **HALT**, roll back to best-score snapshot, escalate HUMAN_REVIEW; skip Step 10 |
| `max_rounds` | If score ≥ 700 → proceed to Step 10 VERIFY; else → HUMAN_REVIEW; skip Step 10 |

**Step 10 VERIFY** (v3.1.0): After any convergence signal (except `trend_diverging` and FAIL),
the loop proceeds to the co-evolutionary independent verification pass. VERIFY resets context
and re-scores the final skill independently to eliminate generator bias. The VERIFY score
(more conservative) becomes the certified score. See `optimize/strategies.md §2 Step 10`.

---

## §7  Score History Format

The optimization loop maintains a score history list:

```json
{
  "skill_name": "<name>",
  "optimization_run_id": "<uuid>",
  "score_history": [684, 706, 718, 724, 729, 731, 732, 731, 732, 732],
  "dimension_history": [
    {"round": 1, "lowest_dim": "Workflow Definition", "score": 684, "delta": null},
    {"round": 2, "lowest_dim": "Workflow Definition", "score": 706, "delta": +22},
    {"round": 3, "lowest_dim": "Error Handling",      "score": 718, "delta": +12}
  ],
  "convergence_check": [
    {"round": 9,  "volatility": false, "plateau": false, "trend": "STABLE"},
    {"round": 10", "volatility": true,  "plateau": false, "trend": "STABLE",
     "decision": "STOP", "reason": "volatility"}
  ],
  "final_score": 732,
  "final_tier": "BRONZE",
  "converged_at_round": 10,
  "convergence_signal": "volatility",
  "verify_score": 728,
  "verify_delta": 4,
  "verify_status": "CONSISTENT",
  "certified_score": 728,
  "tier_history": [
    {"round": 0, "skill_tier": "atomic"},
    {"round": 7, "skill_tier": "functional", "note": "tier promoted — EVALUATE queued"}
  ]
}
```

---

## §8  Curation at Round 10

Every 10 rounds, the 10-step optimization loop performs a curation step to prevent context bloat:

```
CURATE (round 10, 20):
  1. Summarize all dimension changes so far: which improved, by how much
  2. Identify the top 2 strategies that produced the most delta
  3. Prune: discard individual round details, keep only summary + score_history
  4. Re-prioritize: next 10 rounds focus on top-performing strategy first
  5. Log: {"curation_round": 10, "strategies_pruned": [...], "context_reduced_by": "~40%"}
```

This prevents the LLM context window from filling up with stale round-by-round details
and keeps attention focused on the highest-leverage remaining improvements.
