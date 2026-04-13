# Session Artifact Specification

> **Purpose**: Canonical format for session data recorded by COLLECT mode.
> **Load**: When §17 (COLLECT Mode) of `claude/skill-writer.md` is accessed.
> **Inspired by**: SkillClaw (arxiv:2604.08377) + SkillRL lesson distillation (arxiv:2602.08234)
> **Main doc**: `claude/skill-writer.md §17`
> **Last updated**: 2026-04-13 — v3.2.0: Added GoS `bundle_context` + `graph_signals` fields (§2, §3, §8)

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
  "lesson_summary": "<≤3 sentences distilling the reusable lesson from this session>",

  "bundle_context": {
    "bundle_id":          "<bnd-xxx | null if single-skill session>",
    "co_invoked_skills":  ["<skill_id_1>", "<skill_id_2>"],
    "invocation_order":   ["<skill_id_1>", "<this_skill_id>", "<skill_id_2>"],
    "data_flow": [
      { "from": "<skill_id>", "to": "<this_skill_id>", "via": "<data_type>" }
    ],
    "bundle_success":          true,
    "missing_dependencies":    []
  },

  "graph_signals": {
    "should_add_edge": [
      { "type": "depends_on", "target": "<skill_id>", "confidence": 0.85 }
    ],
    "should_merge_with":   null,
    "composability_score": null
  }
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

## §8  Graph of Skills Fields (v3.2.0)

> **Research basis**: GoS bundle retrieval, SkillNet (arxiv:2603.04448).
> These fields enable the AGGREGATE pipeline to auto-infer graph edges from collective
> session data. Full spec: `claude/refs/skill-graph.md`

### `bundle_context` fields

| Field | Required | Description |
|-------|----------|-------------|
| `bundle_id` | No | ID from `registry.graph.bundles[]`; `null` for single-skill sessions |
| `co_invoked_skills` | No | skill_ids of other skills used in the same task session |
| `invocation_order` | No | Ordered list of skill_ids in the sequence they were called |
| `data_flow` | No | Observed data passing between skills; used to infer `provides`/`consumes` edges |
| `bundle_success` | No | Whether the multi-skill session achieved its goal |
| `missing_dependencies` | No | Skills that were needed but not installed; each is a string skill_id |

**`co_invoked_skills` recording rule** `[CORE]`:
Populate when the AI identifies that the current task was accomplished using multiple
skills in sequence. If only one skill was used, set `co_invoked_skills: []`.

**`data_flow` recording rule** `[CORE]`:
Record when output from one skill was explicitly used as input to another.
- `from`: the skill_id that produced the output
- `to`: the skill_id that consumed it
- `via`: human-readable name of the data type (e.g. `"validated-api-schema"`)

### `graph_signals` fields

| Field | Required | Description |
|-------|----------|-------------|
| `should_add_edge` | No | Proposed new graph edges inferred from this session |
| `should_merge_with` | No | skill_id of a highly similar skill (if similarity > 0.90 observed) |
| `composability_score` | No | Estimated D8 LEAN score for this invocation (0–20), if graph: block is present |

**`should_add_edge` recording rule** `[CORE]`:
When the AI observes that skill A consistently required skill B, propose:
```json
{ "type": "depends_on", "target": "<skill_B_id>", "confidence": 0.80 }
```
Do NOT add edges with confidence < 0.60.

### AGGREGATE Auto-Inference Rules (from §10.3 of skill-registry.md)

The AGGREGATE pipeline reads `bundle_context` across N artifacts and applies:

```
N ≥ 5 artifacts with same co_invoked pair:
  → If ≥ 80% show skill A + B co-invoked → propose A depends_on B

N ≥ 5 artifacts with same data_flow entry:
  → If ≥ 60% show A.output → B.input → propose A provides X; B consumes X

Any artifact with should_add_edge.confidence ≥ 0.85:
  → Immediately surface to user for confirmation (no minimum count)
```

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
| **v3.2.0 GoS extension** | `bundle_context` + `graph_signals` | Enables graph edge auto-inference |
