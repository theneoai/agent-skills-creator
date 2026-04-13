# Graph of Skills (GoS) Specification

> **Purpose**: Typed directed graph model for skill relationships, bundle retrieval,
> and ecosystem-level composability.
> **Load**: When §18 (GRAPH Mode) of `claude/skill-writer.md` is accessed, or when
> INSTALL mode performs dependency resolution.
> **Research basis**:
>   - SkillNet (arxiv:2603.04448): 3-layer ontology (taxonomy / relations / packages)
>   - GoS bundle retrieval: Personalized PageRank for execution-complete skill bundles
>   - SkillX (arxiv:2604.04804): tier hierarchy (planning / functional / atomic)
>   - SkillClaw (arxiv:2604.08377): collective evolution via artifact aggregation
> **Implementation**: `builder/src/core/graph.js`
> **Schema**: `refs/skill-registry.md §10` (registry v2.0)
> **v3.2.0**: Initial spec — data layer (edges, bundles, bundle retrieval, D8 evaluation)

---

## §1  Why Graph of Skills

Current skill-writer uses a **three-tier hierarchy** (planning → functional → atomic) as
the only structural relationship between skills. This is a taxonomy — it answers
"how complex is this skill?" but cannot answer:

- "What other skills does this skill require to execute?" (dependency completeness)
- "What skill bundle do I need to accomplish this task?" (execution-complete retrieval)
- "Are these two skills functionally equivalent?" (substitution / deduplication)
- "Which skills compose into this planning skill?" (orchestration graph)

GoS adds a **typed directed graph layer** on top of the existing hierarchy, enabling
inference-time bundle retrieval instead of isolated skill loading.

**Key principle** (from GoS research): Retrieve *execution-complete bundles*, not
just semantically relevant individual skills. Standard vector retrieval misses
dependency skills, leading to incomplete or non-executable agent plans.

---

## §2  Graph Data Model

### §2.1  Nodes

Each Skill in the registry is a graph node:

```
Node {
  id:         string       // SHA-256(name)[:12] — deterministic, immutable
  name:       string       // human-readable skill name
  skill_tier: string       // planning | functional | atomic (SkillX)
  version:    string       // semver
  lean_score: int          // last known LEAN score (0–520 with D8)
  tier_cert:  string       // PLATINUM | GOLD | SILVER | BRONZE | FAIL
}
```

### §2.2  Typed Edges

Six edge types (canonical source: `builder/src/config.js GRAPH_EDGE_TYPES`):

```
depends_on(A → B, required: bool)
  A cannot execute correctly without B being available.
  required=true  → B must be installed before A; hard block on install.
  required=false → B enhances A but A degrades gracefully without it.

composes(A → [B, C, D])
  A is a planning skill that orchestrates B, C, D.
  A MUST be skill_tier=planning; B/C/D MUST be functional or atomic.
  Absence of composes edges on a planning skill → GRAPH-002 warning.

similar_to(A ↔ B, similarity: 0.0–1.0)
  A and B are functionally similar; either may substitute in compatible contexts.
  Undirected (bidirectional).
  similarity ≥ 0.95 → GRAPH-004 merge advisory (do not auto-merge).

uses_resource(A → R)
  A reads a companion file R (path relative to installation root).
  Used to track Layer 3 resource dependencies.

provides(A → type: string)
  A outputs a named data type (e.g. "structured-test-report", "validated-api-schema").
  Enables downstream skills to declare consumes matching this type.

consumes(A → type: string)
  A requires an input of the named data type.
  Matched against upstream provides edges to verify data-flow compatibility.
```

### §2.3  Graph Invariants

These properties MUST hold in a valid graph (checked by validate.js GRAPH-001–005):

1. **No dangling edges**: every `depends_on`/`composes` target ID must exist in the registry
2. **No self-loops**: A cannot depend on itself
3. **No cycles**: `depends_on`/`composes` edges must form a DAG (directed acyclic graph)
4. **Tier consistency**:
   - `composes` edge from a non-`planning` skill → GRAPH-002 WARNING
   - `depends_on` on an `atomic` skill → GRAPH-003 WARNING
5. **Merge advisory**: `similar_to` with similarity ≥ 0.95 → GRAPH-004 WARNING

---

## §3  Bundle Retrieval Protocol

### §3.1  Concept

A **Bundle** is the minimum set of skills needed to execute a given task.
Bundle retrieval replaces "find one skill by semantic similarity" with
"find the execution-complete skill set via graph traversal."

### §3.2  Algorithm (Breadth-First + Personalized PageRank)

```
Input:  query task description, registry graph
Output: ordered bundle [skill_id_1, skill_id_2, ...]

Step 1 — SEED
  Use SkillRouter (trigger phrase matching + Skill Summary) to identify
  the primary matching skill(s). These are seed nodes.

Step 2 — EXPAND (BFS traversal, max depth = GRAPH_MAX_TRAVERSAL_DEPTH)
  For each seed node, follow edges:
    depends_on (required=true)  → add target to bundle (mandatory)
    depends_on (required=false) → add target to bundle (optional, lower priority)
    composes   → add ALL children to bundle (planning skill needs its sub-skills)
  Recurse on newly added nodes until no new mandatory deps found or max depth reached.

Step 3 — DEDUPLICATE
  If two skills have similar_to edge with similarity ≥ 0.90:
    Select the one with higher lean_score.
    Remove the other from the bundle (or mark as alternative).

Step 4 — SCORE
  Assign each skill a bundle_rank:
    base_rank = SkillRouter confidence score for this skill + task
    dependency_boost = +0.2 per incoming depends_on edge from other bundle members
    bundle_rank = base_rank + dependency_boost

Step 5 — SORT
  Sort bundle by topological order (dependencies first) for correct install sequence.
  Within same topological level: sort by bundle_rank descending.

Step 6 — TOKEN BUDGET CHECK
  If total estimated tokens > 12,000:
    Drop optional (required=false) deps from lowest bundle_rank first.
    If still over budget: warn user; show trimmed bundle.

Output bundle = sorted list of { skill_id, name, role, required, bundle_rank }
```

### §3.3  Example

```
Task: "test the payment API and generate a coverage report"

Seed: api-tester (skill_id: a1b2c3d4)

BFS expansion:
  api-tester depends_on schema-validator (required: true)   → add
  api-tester depends_on auth-helper      (required: false)  → add (optional)
  api-tester provides "test-results-json"
  report-generator consumes "test-results-json"             → detect, add

Deduplication: none needed

Bundle (topological order):
  1. schema-validator  (tier: atomic,    role: validates API request schema)
  2. auth-helper       (tier: atomic,    role: handles OAuth token refresh) [optional]
  3. api-tester        (tier: functional, role: executes API test suite)
  4. report-generator  (tier: functional, role: generates coverage report)

Token estimate: 4 × ~800 tokens avg = ~3,200 tokens → within budget
```

---

## §4  Progressive Disclosure Layer 0 (Graph Context)

> See refs/progressive-disclosure.md §2 for full layer spec.

Layer 0 is loaded *before* individual skill ADVERTISE stubs when the router
determines that a task likely requires a skill bundle:

```
Layer 0 — GRAPH CONTEXT   ≈ 200 tokens (strict budget)
  Content:
    - Bundle ID (if pre-computed) or task → bundle mapping
    - Names of all bundle skills + their roles (one line each)
    - Invocation order hint (topological)
    - Any required data types that need to flow between skills

  Format example:
  ┌─────────────────────────────────────────────────────┐
  │ Bundle: API Testing Suite (bnd-api-testing)          │
  │ Skills (execute in order):                           │
  │   1. schema-validator  → validates input schema      │
  │   2. api-tester        → executes test suite         │
  │   3. report-generator  → produces coverage report    │
  │ Data flow: api-tester → report-generator             │
  │            via "test-results-json"                   │
  └─────────────────────────────────────────────────────┘

  When loaded: ADVERTISE → LOAD → READ per-skill (existing layers unchanged)
```

**Token budget enforcement**: Layer 0 MUST fit in 200 tokens.
If bundle > 5 skills: show top 5 by bundle_rank; note "N more skills available".

---

## §5  Composability Evaluation (D8)

### §5.1  LEAN D8 Check (0–20 bonus points)

Optional — skills without `graph:` block score 0; no penalty applied.

| Check | Points | Logic |
|-------|--------|-------|
| `graph_block_present` | 5 | `graph:` key exists in YAML frontmatter (any non-empty field) |
| `skill_tier_graph_consistent` | 10 | See tier consistency rules below |
| `graph_edge_ids_valid_format` | 5 | All `depends_on`/`composes`/`similar_to` IDs match `[a-f0-9]{12}` |

**Tier consistency rules for 10-pt check**:

| skill_tier | Expected graph structure | Score |
|------------|--------------------------|-------|
| `planning` | Has `composes` with ≥ 1 entry | 10 pts |
| `planning` | Has `depends_on` but no `composes` | 5 pts (advisory) |
| `functional` | Has `provides` and/or `consumes` | 10 pts |
| `functional` | Has neither `provides` nor `consumes` | 7 pts (acceptable) |
| `atomic` | Has `provides` and/or `consumes`; NO `depends_on` | 10 pts |
| `atomic` | Has `depends_on` | 4 pts (advisory: atomic skills should be self-contained) |

### §5.2  EVALUATE Phase 5 (v4.0+, +100 points)

Phase 5 is not active in v3.x. Defined here for roadmap clarity.

| Sub-dimension | Max | What is checked |
|---------------|-----|----------------|
| Dependency declaration completeness | 30 | Do declared deps cover all skills actually referenced in the body? |
| Interface contract clarity | 25 | Are `provides`/`consumes` types specific (not just "data")? |
| Tier role consistency | 25 | Is the skill's graph role consistent with its skill_tier? |
| Edge quality | 20 | Are similar_to similarities plausible (not all 1.0)? Are IDs valid? |

**Certification threshold adjustment** (when Phase 5 is active):
```
PLATINUM ≥ 1045  (950 + 95% of 100)
GOLD     ≥  990  (900 + 90% of 100)
SILVER   ≥  880  (800 + 80% of 100)
BRONZE   ≥  770  (700 + 70% of 100)
```
90-day grace period: existing certificates remain valid; new EVALUATE runs may optionally
skip Phase 5 with `--skip-phase5` flag during the transition period.

---

## §6  Dependency Resolution in INSTALL Mode

When `/install [skill-name]` is run:

```
Step 0 — READ GRAPH
  Load graph: from registry.json (if registry is configured).
  If no registry: read graph: from skill YAML frontmatter only.

Step 1 — BUILD DEPENDENCY TREE
  DFS from target skill following depends_on edges (required=true only).
  Detect cycles → if cycle found → ABORT with GRAPH-005 error.
  Collect all required skills in topological order (dependencies first).

Step 2 — CHECK INSTALLED
  For each skill in dependency tree:
    Check if already installed in platform skills directory.
    Mark: ✓ installed | ⚠ needs-install | ✗ not-found

Step 3 — DISPLAY MANIFEST
  Show dependency manifest before installing:

  Installing: api-tester v1.2.0 (platform: claude)
  Dependencies:
    ✓ schema-validator v2.0.0   (already installed)
    ⚠ auth-helper v1.0.0        (will install)
    ✗ token-cache v0.9.0        (not in registry — manual install required)

  Proceed? [Y/n]

Step 4 — INSTALL IN ORDER
  Install skills in topological order (dependencies before dependents).
  If any required dependency cannot be installed → ABORT; report blocked skill.

Step 5 — REPORT
  "Installed: api-tester + 1 dependency (schema-validator already present)"
  "Manual action required: token-cache v0.9.0 not found in registry"
```

---

## §7  Graph Health Check (`/graph check`)

Runs the following checks on the current registry graph:

| Check | ID | Severity | Description |
|-------|----|----------|-------------|
| Dangling edge targets | GRAPH-001 | ERROR | Edge points to non-existent skill_id |
| Planning missing composes | GRAPH-002 | WARNING | planning skill has no composes edges |
| Atomic has depends_on | GRAPH-003 | WARNING | atomic skill declares dependencies |
| Merge advisory | GRAPH-004 | WARNING | similar_to similarity ≥ 0.95 |
| Cycle detected | GRAPH-005 | ERROR | Circular dependency in depends_on/composes |
| Isolated nodes | GRAPH-006 | INFO | Skill has no edges of any type |
| Orphan planning | GRAPH-007 | WARNING | planning skill's composes targets are all deprecated |
| Provides/consumes mismatch | GRAPH-008 | INFO | A provides type X but no skill consumes X |

```
/graph check output format:

📊 Graph Health Report
  Nodes: 42 skills
  Edges: 87 typed relationships
  Bundles: 6 defined

  ERRORS (2):
    ✗ GRAPH-001: skill "api-tester" depends_on "7f8a9b0c1d2e" — ID not in registry
    ✗ GRAPH-005: Cycle detected: code-reviewer → lint-checker → code-reviewer

  WARNINGS (3):
    ⚠ GRAPH-002: "task-orchestrator" is planning tier but has no composes edges
    ⚠ GRAPH-004: "api-tester" and "endpoint-caller" have similarity 0.97 — merge candidate
    ⚠ GRAPH-007: "deploy-pipeline" composes ["build-runner"] — build-runner is DEPRECATED

  INFO (5):
    ℹ GRAPH-006: 5 isolated skills (no graph edges): [doc-writer, ...]
    ℹ GRAPH-008: "report-generator" provides "coverage-xml" — no consumer found

  Summary: 2 errors must be fixed before bundle retrieval is reliable.
```

---

## §8  Graph Visualization (`/graph view`)

ASCII art representation for small graphs (≤ 20 skills):

```
/graph view  →  outputs:

Skill Graph (42 nodes, 87 edges)

planning skills:
  ┌─ task-orchestrator
  │   ├─composes──▶ api-tester
  │   ├─composes──▶ data-validator
  │   └─composes──▶ report-generator

functional skills:
  ┌─ api-tester ──depends_on──▶ schema-validator [required]
  │              ──depends_on──▶ auth-helper [optional]
  │              ──provides──▶ "test-results-json"
  │              ──similar_to──▶ endpoint-caller (0.87)
  └─ report-generator ──consumes──▶ "test-results-json"

atomic skills:
  schema-validator  (no deps — correct for atomic)
  auth-helper       (no deps — correct for atomic)
```

For graphs > 20 skills: show subgraph for specified skill only:
```
/graph view api-tester  →  shows neighbors only
```

---

## §9  Relationship to Other Specs

| Spec | Role |
|------|------|
| `refs/skill-registry.md §10` | Registry schema v2.0 (graph storage) |
| `refs/session-artifact.md §8` | bundle_context + graph_signals (edge inference source) |
| `refs/progressive-disclosure.md §2` | Layer 0 Graph Context (bundle-aware loading) |
| `builder/src/core/graph.js` | Runtime implementation (buildGraph, resolveBundle, etc.) |
| `builder/src/commands/validate.js` | GRAPH-001–008 static checks |
| `optimize/strategies.md §4 S10–S12` | Graph-level OPTIMIZE strategies |
| `eval/rubrics.md §5 D8` | D8 Composability scoring (LEAN + Phase 5) |
