# Progressive Disclosure Reference

> **Purpose**: Defines the four-layer loading pattern for skill content, optimizing token
> usage and LLM reasoning quality across platforms.
> **Load**: When §12 (INSTALL), §2 (Mode Router), or §18 (GRAPH) of `claude/skill-writer.md` is accessed.
> **Main doc**: `claude/skill-writer.md §12`
> **Last updated**: 2026-04-13 — v3.2.0: Added Layer 0 Graph Context (GoS bundle-aware loading)

---

## §1  Why Progressive Disclosure?

LLM reasoning quality degrades significantly around **3,000 tokens** — well below most
context window limits (agentskills.io specification, 2025; Lakera prompt engineering
research, 2026). Loading every skill in full at startup saturates the effective context
budget before the user's task is even considered.

Progressive Disclosure solves this with a **four-layer architecture** (v3.2.0): skills
are loaded only as far as needed for the current task, keeping token consumption
proportional to what the agent actually requires.  Layer 0 (Graph Context) is new in
v3.2.0 — it provides bundle-level awareness before individual skills are loaded.

---

## §2  Four-Layer Architecture (v3.2.0)

```
Layer 0 — GRAPH CONTEXT  ≈ 200 tokens  Loaded when task matches a known bundle
                                        (v3.2.0; only when registry has graph data)
Layer 1 — ADVERTISE      ≈ 100 tokens  Always loaded (system prompt injection)
Layer 2 — LOAD           < 5,000 tokens Loaded when task matches skill domain
Layer 3 — READ RESOURCES   as needed   Fetched only when skill invokes them
```

### Layer 0: GRAPH CONTEXT (v3.2.0)

**Content**: Bundle summary — ordered list of skills, their roles, and data-flow between them.
**When loaded**: The router determines the task likely requires ≥ 2 skills AND the registry
has `graph:` data (schema v2.0+).
**Token budget**: ≤ 200 tokens (strict limit — enforced by `resolveBundle()` in graph.js).
**Source**: `registry.json graph.bundles[]` + computed from `graph.edges[]`.

Layer 0 precedes Layer 1 — it gives the LLM structural context about the skill ecosystem
*before* individual skill names are loaded.

Example Layer 0 output (≤ 200 tokens):
```
Bundle: API Testing Suite
Skills (execute in order):
  1. schema-validator  → validates input schema     [atomic]
  2. api-tester        → executes test suite         [functional, entry point]
  3. report-generator  → produces coverage report    [functional]
Data flow: api-tester → report-generator via "test-results-json"
```

**When Layer 0 is NOT loaded**:
- Single-skill tasks (no bundle context needed)
- Registry has no `graph:` data (v1.x registry)
- Task does not match any known bundle

**Platform support**: Layer 0 is injected as a prefix to the system prompt alongside
Layer 1 ADVERTISE stubs. Platforms that don't support dynamic system prompt injection
(e.g. Cursor) receive Layer 0 as part of the first user message instead.

---

### Layer 1: ADVERTISE

**Content**: Skill name + one-line description only.
**When loaded**: Every session, injected into the system prompt by the platform.
**Token budget**: ~100 tokens per skill (strict limit).
**Source**: YAML frontmatter `name` + `description` fields.

Example (advertise stub):
```
skill: skill-writer
description: Meta-skill framework — CREATE, LEAN, EVALUATE, OPTIMIZE, INSTALL, COLLECT.
```

**Platform mapping**:
- Claude / OpenCode: Injected from YAML frontmatter automatically when skill is enabled
- Cursor: Listed in `.cursorrules` short form
- MCP: Listed in the `tools[].description` field of the Server Card

### Layer 2: LOAD

**Content**: Full skill body — all mode sections, examples, workflow tables.
**When loaded**: The platform identifies a matching user intent via trigger phrases.
**Token budget**: < 5,000 tokens recommended; warn if skill body exceeds 500 lines.
**Source**: Complete skill `.md` file (after YAML frontmatter).

Trigger matching criteria:
- Exact keyword match against `triggers.en` or `triggers.zh` YAML fields
- Semantic match by platform-native routing (SkillRouter 91.7% cross-encoder accuracy)
- Explicit user invocation (`/create`, `评测`, etc.)

**What belongs in Layer 2**:
- All §N mode sections
- Workflow tables and state machines
- Examples (minimum 2, maximum ~10)
- Security baseline and Red Lines
- Error handling and escalation paths

**What does NOT belong in Layer 2** (move to Layer 3):
- Large rubric tables (eval/rubrics.md)
- Full pattern catalogs (refs/security-patterns.md)
- Historical benchmark data (eval/benchmarks.md)
- Template source files (templates/*.md)

### Layer 3: READ RESOURCES

**Content**: Companion reference files, embedded only when the specific sub-mode is invoked.
**When loaded**: On-demand, referenced by path from within the skill body.
**Token budget**: No hard limit; load only what the current invocation requires.

Resource loading triggers:
| Sub-mode | Resources loaded |
|----------|-----------------|
| EVALUATE (full) | eval/rubrics.md, refs/security-patterns.md |
| OPTIMIZE | optimize/strategies.md, refs/convergence.md |
| COLLECT | refs/session-artifact.md |
| CREATE | templates/base.md (or template-specific file) |
| SHARE | refs/skill-registry.md |
| Any | refs/use-to-evolve.md (UTE cadence check) |
| **GRAPH** (v3.2.0) | **refs/skill-graph.md** (graph spec + health check rules) |

---

## §3  Skill File Compliance Rules

### Line Count

| Threshold | Action |
|-----------|--------|
| ≤ 300 lines | Optimal — full Layer 2 fits within 5,000-token budget |
| 301–500 lines | Acceptable — monitor token usage, consider splitting resources |
| > 500 lines | `WARNING` from `validate.js` — move large sections to Layer 3 resources |
| > 1,000 lines | `ERROR` recommendation — skill likely contains embedded reference content |

### Skill Name (agentskills.io §2.1)

- Characters: `[a-z0-9-]` only
- Length: ≤ 64 characters
- No leading, trailing, or consecutive hyphens
- Examples: `skill-writer`, `api-tester`, `code-reviewer-v2`

### Description (agentskills.io §2.2)

- Max length: **1,024 characters** (enforced by `validate.js`)
- Should be usable as a Layer 1 advertise stub — concise, domain-specific
- Must not contain newlines (single-paragraph prose)

---

## §4  Implementation Checklist

For skill authors generating skills with Skill Writer:

- [ ] `name` in frontmatter matches `[a-z0-9-]`, ≤ 64 chars
- [ ] `description` in frontmatter is ≤ 1,024 chars and single-paragraph
- [ ] Skill body (Layer 2) is ≤ 500 lines
- [ ] Large reference tables moved to Layer 3 companion files (refs/, eval/)
- [ ] `triggers.en` has 3–8 canonical phrases (Layer 1 → Layer 2 routing)
- [ ] `triggers.zh` has 2–5 canonical phrases (bilingual routing)
- [ ] `## Negative Boundaries` section present (prevents mis-triggering)

For Skill Writer builds (`npm run build`):

- [ ] `validate.js` emits WARNING for skills >500 lines
- [ ] MCP Server Card generated at `.well-known/mcp-server-card.json` (Layer 1 for MCP)
- [ ] MCP manifest `tools[].description` used as advertise stub

---

## §5  Relationship to Other Specs

| Spec | Layer | Role |
|------|-------|------|
| **refs/skill-graph.md** (v3.2.0) | **0** | **GoS spec; loaded by GRAPH mode and bundle-aware routing** |
| **registry.json graph section** (v3.2.0) | **0** | **Bundle data source for Layer 0 context** |
| agentskills.io SKILL.md | 1 + 2 | Name/description constraints; 500-line limit |
| refs/self-review.md | 2 | Self-review protocol runs in-layer |
| refs/security-patterns.md | 3 | Loaded by EVALUATE security gate only |
| refs/evolution.md | 3 | Loaded by UTE cadence check |
| refs/convergence.md | 3 | Loaded by OPTIMIZE convergence detection |
| eval/rubrics.md | 3 | Loaded by EVALUATE Phase 1–4 |
| templates/*.md | 3 | Loaded by CREATE mode template injection |
| refs/skill-registry.md | 3 | Loaded by SHARE/INSTALL mode only |
