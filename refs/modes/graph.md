<!-- Extracted from claude/skill-writer.md §20 — full reference -->

## §20  GRAPH Mode — Skill Graph Management (v3.2.0)

> **GRAPH at a Glance**
>
> **What it does**: Manages the typed relationship graph between skills.
> View the skill dependency graph, check graph health, plan bundles for tasks,
> and resolve installation dependencies.
>
> **Research basis**: typed-dependency Graph of Skills design, GoS bundle retrieval, three-tier skill hierarchy tiers
> **Full spec**: `refs/skill-graph.md`
> **Implementation**: YAML-only MVR `[CORE]`; full graph engine is a v4.0+ target
>
> **When to use**:
> - Before installing a skill that has `graph.depends_on` entries
> - When `/graph check` errors appear (GRAPH-001 to GRAPH-008)
> - To plan the minimum skill set for a complex task
> - After running AGGREGATE to review auto-inferred graph edges

**Trigger**: `/graph [subcommand]` | `技能图` | `依赖图` | `包规划`

### Sub-commands

| Command | Description | Example |
|---------|-------------|---------|
| `/graph view` | ASCII graph of current skill ecosystem | `/graph view` |
| `/graph view [skill]` | Neighborhood graph for one skill | `/graph view api-tester` |
| `/graph check` | Run GRAPH-001–008 health checks | `/graph check` |
| `/graph plan [task]` | Resolve minimum bundle for a task | `/graph plan "test the payment API"` |
| `/graph bundle` | List all pre-defined bundles | `/graph bundle` |
| `/graph diff [v1] [v2]` | Compare graph structure between versions | `/graph diff v3.1.0 v3.2.0` |

### `/graph plan` Workflow

```
/graph plan "test the payment API and generate a coverage report"
     ↓
Step 1: Route to primary skill via Skill Summary heuristic trigger matching
        → primary: api-tester (seed node)
     ↓
Step 2: BFS expansion via YAML-only MVR (§20 GoS MVR); full engine is v4.0+ target
        → Follow depends_on (required=true)  → schema-validator
        → Follow depends_on (required=false) → auth-helper (optional)
        → Match provides → consumes         → report-generator
     ↓
Step 3: Deduplication (similar_to ≥ 0.90 → keep higher-scoring)
     ↓
Step 4: Topological sort (dependencies first)
     ↓
Output:
  Bundle: API Testing Suite
  Install order:
    1. schema-validator  (atomic, required)
    2. auth-helper       (atomic, optional)
    3. api-tester        (functional, entry point)
    4. report-generator  (functional)
  Token estimate: ~3,200 tokens (within budget)
  Run /install --bundle to deploy all at once.
```

### `/graph check` Output Format

```
📊 Graph Health Report — skill-writer registry v2.0
  Nodes: N skills | Edges: M relationships | Bundles: K defined

  ERRORS:   [GRAPH-001] dangling edge, [GRAPH-005] cycle — must fix
  WARNINGS: [GRAPH-002] planning missing composes, [GRAPH-004] merge advisory
  INFO:     [GRAPH-006] isolated nodes, [GRAPH-008] unused provides types

  → Fix ERRORS before /install --bundle
  → Review WARNINGS before publishing to skill registry
```

### GRAPH Mode + D8 Scoring

After running `/graph check`:
- If D8 score is 0 (no `graph:` block): GRAPH mode prompts user to add graph declarations
- If D8 score < 15: GRAPH mode identifies which D8 sub-checks are failing and suggests fixes
- Successful `/graph plan` execution = proof the graph declarations work → D8 boost

### GoS Minimum Viable Runtime (`[CORE]` — no builder required)

> **Context**: The full GoS (Graph of Skills) runtime specified in `refs/skill-graph.md`
> requires the full graph engine (v4.0+ target; not yet shipped). However, the most valuable
> GoS capability — `depends_on` dependency resolution for `/graph plan` and `/install --bundle`
> — can be implemented entirely from YAML frontmatter reading, without any external code.

The following algorithm is the **Minimum Viable GoS Runtime** that the AI executes `[CORE]`:

```
MINIMUM VIABLE GoS (depends_on only):

Input: task description + local skill files with graph: blocks

Step 1 — SEED (find primary skill):
  Run Skill Summary heuristic trigger matching against task description.
  Primary skill = highest-confidence match.

Step 2 — EXPAND (read depends_on chains from YAML only):
  For the primary skill, read its YAML `graph.depends_on` list (if present).
  For each dependency, read THAT skill's `graph.depends_on` list.
  Repeat until no new dependencies found OR depth > 5.
  Collect: required=true deps (mandatory) and required=false deps (optional).

Step 3 — DEDUPLICATE:
  Remove duplicates. If two skills declare similar_to ≥ 0.90, keep higher LEAN score.

Step 4 — TOPOLOGICAL SORT:
  Order: dependencies first, then the skill that depends on them.
  Output: ordered install list.

Step 5 — TOKEN BUDGET CHECK:
  Estimate tokens for all skills (≈ file_size / 4).
  If total > 12,000 tokens: drop optional deps first, warn user.

Output: "Bundle resolved: [list in install order]. Run /install for each."
```

**What this runtime does NOT support** (v4.0+ only):
- `composes` edge traversal (planning skill orchestration)
- `provides/consumes` type matching
- BFS cycle detection (just stops at depth 5)
- Auto-inferred edges from COLLECT artifacts

**When to escalate to full spec**: Any `/graph check` that returns GRAPH-001 (dangling edge)
or GRAPH-003 (cycle detected) requires the full graph engine implementation (v4.0+ target).
For depth-limited linear chains (most real-world cases), the MVR is sufficient.

### Key references

- Full GoS spec: `refs/skill-graph.md`
- Registry v2.0 format: `refs/skill-registry.md §10`
- D8 scoring rules: `eval/rubrics.md §9`
- Graph algorithms: YAML-only MVR `[CORE]` (see GoS MVR section above); full engine v4.0+
- Validation checks: GRAPH-001–008 defined in §20 error table

---

**Triggers**:
**CREATE** | **LEAN** | **EVALUATE** | **OPTIMIZE** | **INSTALL** | **COLLECT** | **GRAPH**
**创建** | **快评** | **评测** | **优化** | **安装** | **采集** | **技能图**

(Templates: `templates/` · UTE snippet: `templates/use-to-evolve-snippet.md` ·
Eval rubrics: `eval/rubrics.md` · Benchmarks: `eval/benchmarks.md` ·
Self-review: `refs/self-review.md` · Security: `refs/security-patterns.md` ·
Evolution: `refs/evolution.md` · UTE spec: `refs/use-to-evolve.md` ·
Convergence: `refs/convergence.md` · Optimize strategies: `optimize/strategies.md` ·
Session artifact: `refs/session-artifact.md` · Edit audit: `refs/edit-audit.md` ·
