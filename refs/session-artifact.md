# Session Artifact Specification

> **Purpose**: Canonical format for session data recorded by COLLECT mode.
> **Load**: When §17 (COLLECT Mode) of `claude/skill-writer.md` is accessed.
> **Inspired by**: SkillClaw (arxiv:2604.08377) + SkillRL lesson distillation (arxiv:2602.08234)
> **Main doc**: `claude/skill-writer.md §17`
> **Last updated**: 2026-04-11 — Added SkillRL-inspired `lesson_type` + `lesson_summary` fields (§2, §3)

---

> ### Enforcement Level Guide
>
> | Tag | Meaning |
> |-----|---------|
> | `[CORE]` | AI can produce this within a single session |
> | `[EXTENDED]` | Requires external storage, backend, or cross-session state |

---

## §1  Concept

A **Session Artifact** is a structured record of a single skill invocation. The AI
generates it at the end of every session where COLLECT mode is active. Artifacts
accumulate in shared storage and feed the AGGREGATE mode distillation pipeline.

**Key principle** (from SkillClaw): collective evolution — aggregating artifacts from
*many users* across *many sessions* — consistently outperforms single-user optimization.
The Session Artifact is the atomic unit that enables this.

---

## §2  Schema

```json
{
  "schema_version": "1.0",
  "skill_id": "<SHA-256[:12] of skill name>",
  "skill_name": "<name field from YAML frontmatter>",
  "skill_version": "<semver from YAML frontmatter>",
  "session_id": "<ISO-8601-date>-<6-char random>",
  "recorded_at": "<ISO-8601 timestamp>",

  "outcome": "success | failure | partial | ambiguous",
  "trigger_used": "<exact user phrasing that triggered the skill>",
  "mode_invoked": "CREATE | LEAN | EVALUATE | OPTIMIZE | INSTALL | COLLECT",
  "feedback_signal": "approval | correction | rephrasing | abandon | neutral",

  "session_summary": "<8–15 sentence causal-chain summary of this interaction>",
  "prm_signal": "good | ok | poor",

  "notable_patterns": [
    "<pattern observed — e.g. 'user needed ZH trigger', 'output was too verbose'>"
  ],
  "improvement_hints": [
    "<concrete suggestion — e.g. 'add ZH trigger for LEAN mode', 'reduce example verbosity'>"
  ],

  "dimension_observations": {
    "systemDesign":    "strong | adequate | weak | n/a",
    "domainKnowledge": "strong | adequate | weak | n/a",
    "workflow":        "strong | adequate | weak | n/a",
    "errorHandling":   "strong | adequate | weak | n/a",
    "examples":        "strong | adequate | weak | n/a",
    "security":        "strong | adequate | weak | n/a",
    "metadata":        "strong | adequate | weak | n/a"
  },

  "lesson_type": "strategic_pattern | failure_lesson | neutral",
  "lesson_summary": "<≤3 sentences distilling the reusable lesson from this session>"
}
```

---

## §3  Field Definitions

### Identity fields

| Field | Required | Description |
|-------|----------|-------------|
| `schema_version` | ✅ | Always `"1.0"` for this spec revision |
| `skill_id` | ✅ | `SHA-256[:12]` of `skill_name` (deterministic; used for registry lookup) |
| `skill_name` | ✅ | Exact value of `name` from YAML frontmatter |
| `skill_version` | ✅ | Semver string from YAML frontmatter |
| `session_id` | ✅ | `<date>-<random>` ensures no collision; format: `2026-04-11-a3f9c2` |
| `recorded_at` | ✅ | ISO-8601 timestamp when artifact was generated |

### Outcome fields

| Field | Values | Description |
|-------|--------|-------------|
| `outcome` | `success \| failure \| partial \| ambiguous` | Overall session outcome |
| `trigger_used` | string | Verbatim user input that matched the skill's trigger |
| `mode_invoked` | enum | Which of the 5+1 modes ran |
| `feedback_signal` | enum | User feedback observed after skill output |

**`outcome` decision rules** `[CORE]`:

| Condition | Outcome |
|-----------|---------|
| User approved output or proceeded without correction | `success` |
| User corrected output or said it was wrong | `failure` |
| Skill triggered but user needed additional clarification/iteration | `partial` |
| Session ended or topic switched without clear signal | `ambiguous` |

**`feedback_signal` values** (same classification as UTE, §3 of `refs/use-to-evolve.md`):

| Signal | Detection |
|--------|-----------|
| `approval` | "thanks", "好的", "perfect", user proceeds |
| `correction` | "wrong", "不对", user provides alternative |
| `rephrasing` | Same request restated without acceptance |
| `abandon` | Topic switch or session ends immediately |
| `neutral` | No observable follow-up |

### Quality signals

| Field | Values | Description |
|-------|--------|-------------|
| `session_summary` | string (8–15 sentences) | Causal-chain narrative `[CORE]` |
| `prm_signal` | `good \| ok \| poor` | Process Reward Model signal (overall quality of AI execution) `[CORE]` |
| `notable_patterns` | string[] | Observed usage patterns (may be empty) |
| `improvement_hints` | string[] | Concrete improvement suggestions (may be empty) |

**`prm_signal` decision rules**:

| Signal | Condition |
|--------|-----------|
| `good` | Skill triggered cleanly, output met expectations, no corrections |
| `ok` | Skill triggered but required clarification or minor correction |
| `poor` | Skill failed to trigger, produced wrong output, or was abandoned |

### Dimension observations

7-field object mapping each unified dimension (from `builder/src/config.js SCORING.dimensions`)
to a strength rating for this session. Use `"n/a"` when a dimension wasn't exercised.

### SkillRL Lesson Distillation fields `[CORE]`

Inspired by SkillRL (arxiv:2602.08234): distilling raw trajectories into typed lessons yields
10-20% token compression while improving reasoning utility in downstream AGGREGATE pipelines.

| Field | Values | Description |
|-------|--------|-------------|
| `lesson_type` | `strategic_pattern \| failure_lesson \| neutral` | Type of lesson this session contributes |
| `lesson_summary` | string (≤3 sentences) | Distilled, reusable lesson — the "takeaway" |

**`lesson_type` classification rules** `[CORE]`:

| Type | Condition | AGGREGATE Use |
|------|-----------|---------------|
| `strategic_pattern` | `outcome = success` AND `prm_signal = good` | Feeds General Skills (reusable positive patterns) |
| `failure_lesson` | `outcome = failure` OR `feedback_signal = correction` | Feeds Task-Specific warnings (concise failure lessons) |
| `neutral` | `outcome = partial` OR `outcome = ambiguous` | Stored but lower weight in AGGREGATE |

**`lesson_summary` writing rules**:
- For `strategic_pattern`: "What worked well and why. Which workflow step was most effective. What can be reused in similar skills."
- For `failure_lesson`: "What failed. Root cause (design flaw / trigger miss / content gap). How to avoid in future skill iterations."
- For `neutral`: "What happened, what was ambiguous, what additional data would clarify."

**Examples**:
```
# strategic_pattern
"User's request for 'summarize this API doc' triggered correctly on first try. The
Skill Summary paragraph's dense keyword coverage was decisive. The structured output
format (table + bullets) earned immediate user approval. Reuse: lead with domain-rich
Skill Summary + prefer table outputs for comparison tasks."

# failure_lesson  
"Skill failed to trigger on 'check my PR': user expected code-review skill but
weather-api skill triggered instead due to overlapping 'check' keyword. Root cause:
no negative boundaries defined for the weather-api skill. Fix: add 'Do NOT use for
code review' to negative boundaries section."
```

---

## §4  Session Summary Guidelines

The `session_summary` is the highest-signal field for the AGGREGATE pipeline.
Write it as a causal-chain narrative:

```
Good session_summary example:
"User requested creation of a weather API skill in Chinese. The skill triggered
correctly on 'create a weather skill'. Six elicitation questions were asked; user
answered all. Template 'api-integration' was selected. Security scan cleared CWE-798
and CWE-89. LEAN score was 420/500 (GOLD proxy). Full evaluate produced 890/1000
(SILVER, just below GOLD threshold). Main weakness was Error Handling (55/100).
User approved delivery at SILVER tier. Session ended with user requesting OPTIMIZE
on next session. Improvement opportunity: add retry logic to error handling section."
```

**Requirements**:
- 8–15 sentences minimum
- Include: what triggered, what ran, what succeeded/failed, what could improve
- Be specific — "Error Handling was weak" is better than "skill could be improved"
- Note any domain-specific terms the user used that could become trigger keywords

---

## §5  Storage and Lifecycle `[EXTENDED]`

> **`[EXTENDED]`**: Full pipeline requires external storage backend.
> Minimum viable: user exports artifact as JSON and provides it as input to AGGREGATE mode.

### Storage layout (SkillClaw-compatible)

```
storage-root/
└── sessions/                          # Queue directory — one file per artifact
    ├── 2026-04-11-a3f9c2.json
    ├── 2026-04-11-b8e1d4.json
    └── ...
```

### Lifecycle states

| State | Description |
|-------|-------------|
| **queued** | Artifact written to `sessions/`; not yet processed |
| **processing** | AGGREGATE mode is reading this artifact |
| **processed** | Artifact incorporated into a skill evolution; safe to archive |
| **failed** | AGGREGATE failed; artifact remains in queue for retry |

**Queue semantics** (from SkillClaw): artifacts remain in the queue until AGGREGATE
successfully processes them. This guarantees at-least-once delivery even if the
AGGREGATE server restarts mid-cycle.

---

## §6  Minimum Viable Flow (no backend required) `[CORE]`

When no external storage is available, the COLLECT mode outputs a JSON artifact
that the user can:

1. Save locally as `<session_id>.json`
2. Paste into a future AGGREGATE mode session alongside other artifacts
3. Manually push to shared storage via `skillclaw push` (if using SkillClaw backend)

This manual flow degrades gracefully — single-user COLLECT is still valuable for
tracking personal usage patterns over time.

---

## §7  SkillClaw Interoperability

Session Artifacts are designed to be compatible with the SkillClaw evolve server
session format. Key alignment points:

| SkillClaw concept | skill-writer equivalent | Notes |
|-------------------|------------------------|-------|
| Programmatic trajectory | `dimension_observations` | skill-writer maps to 7 unified dimensions |
| LLM session summary | `session_summary` | Same 8–15 sentence causal-chain format |
| PRM score | `prm_signal` (3-level) | Simplified: good/ok/poor vs continuous score |
| Skill reference | `skill_id` + `skill_name` | SHA-256[:12] IDs are compatible |
| Sessions queue | `sessions/` directory | Same storage layout |
