/**
 * Graph of Skills (GoS) — Core Algorithm Library
 *
 * Implements the graph data structure and traversal algorithms for skill
 * dependency resolution, bundle retrieval, cycle detection, and topological
 * ordering.
 *
 * Research basis:
 *   - SkillNet (arxiv:2603.04448): typed edge model (depend_on, composes, similar_to)
 *   - GoS bundle retrieval: BFS + Personalized PageRank for execution-complete bundles
 *   - SkillX (arxiv:2604.04804): tier-aware graph invariants
 *
 * Spec: refs/skill-graph.md
 * Config: builder/src/config.js (GRAPH_EDGE_TYPES, GRAPH_MAX_TRAVERSAL_DEPTH, etc.)
 *
 * @module builder/src/core/graph
 * @version 3.2.0
 */

'use strict';

const {
  GRAPH_EDGE_TYPES,
  GRAPH_MAX_TRAVERSAL_DEPTH,
  GRAPH_SIMILARITY_MERGE_THRESHOLD,
} = require('../config');

// ---------------------------------------------------------------------------
// §1  In-Memory Graph Structure
// ---------------------------------------------------------------------------

/**
 * Build an in-memory adjacency representation from a registry object.
 *
 * Accepts either a v1.x registry (skills[] only) or a v2.0 registry
 * (skills[] + graph.edges[]).  In v1.x mode the edges are inferred from
 * each skill's YAML-level `graph:` block (if present).
 *
 * @param {Object} registry - Parsed registry.json object
 * @returns {Object} graph - In-memory graph with nodes and adjacency lists
 *
 * graph shape:
 * {
 *   nodes:  Map<skill_id, NodeDescriptor>
 *   adj:    Map<skill_id, Edge[]>          // outgoing edges
 *   radj:   Map<skill_id, Edge[]>          // incoming edges (reverse)
 *   edges:  Edge[]                         // flat list of all edges
 * }
 */
function buildGraph(registry) {
  const nodes = new Map();
  const adj   = new Map();
  const radj  = new Map();
  const edges = [];

  // ── Populate nodes ──────────────────────────────────────────────────────
  if (!registry || !Array.isArray(registry.skills)) {
    return { nodes, adj, radj, edges };
  }

  for (const skill of registry.skills) {
    const id = skill.id || skill.skill_id;
    if (!id) continue;

    nodes.set(id, {
      id,
      name:       skill.name       || '',
      skill_tier: skill.skill_tier || 'functional',
      version:    skill.current_version || skill.version || '1.0.0',
      lean_score: skill.lean_score || 0,
      tier_cert:  skill.certified_tier || 'BRONZE',
      deprecated: skill.deprecated || false,
    });
    adj.set(id, []);
    radj.set(id, []);
  }

  // ── Helper: add a single edge safely ─────────────────────────────────────
  function addEdge(edge) {
    if (!GRAPH_EDGE_TYPES.includes(edge.type)) return;
    // Normalise: similar_to is undirected — store both directions
    const record = {
      from:          edge.from,
      to:            edge.to,
      type:          edge.type,
      weight:        edge.weight        ?? 1.0,
      required:      edge.required      ?? true,
      similarity:    edge.similarity    ?? null,
      auto_inferred: edge.auto_inferred ?? false,
      confidence:    edge.confidence    ?? 1.0,
    };
    edges.push(record);
    if (adj.has(edge.from)) adj.get(edge.from).push(record);
    if (radj.has(edge.to))  radj.get(edge.to).push(record);

    if (edge.type === 'similar_to') {
      const rev = { ...record, from: edge.to, to: edge.from };
      edges.push(rev);
      if (adj.has(edge.to))  adj.get(edge.to).push(rev);
      if (radj.has(edge.from)) radj.get(edge.from).push(rev);
    }
  }

  // ── Load registry v2.0 graph.edges[] ────────────────────────────────────
  if (registry.graph && Array.isArray(registry.graph.edges)) {
    for (const edge of registry.graph.edges) {
      if (nodes.has(edge.from) && nodes.has(edge.to)) {
        addEdge(edge);
      }
    }
  }

  // ── Load graph: blocks from individual skill frontmatter ─────────────────
  // Skills may embed their own graph declarations (e.g. from YAML frontmatter
  // exported alongside the registry).  This is the primary source in v1.x.
  for (const skill of registry.skills) {
    const fromId = skill.id || skill.skill_id;
    if (!fromId || !skill.graph) continue;

    const g = skill.graph;

    // depends_on
    if (Array.isArray(g.depends_on)) {
      for (const dep of g.depends_on) {
        const toId = dep.id || dep.skill_id;
        if (toId && nodes.has(toId)) {
          addEdge({ from: fromId, to: toId, type: 'depends_on',
                    required: dep.required ?? true });
        }
      }
    }

    // composes
    if (Array.isArray(g.composes)) {
      for (const child of g.composes) {
        const toId = child.id || child.skill_id;
        if (toId && nodes.has(toId)) {
          addEdge({ from: fromId, to: toId, type: 'composes' });
        }
      }
    }

    // similar_to
    if (Array.isArray(g.similar_to)) {
      for (const sim of g.similar_to) {
        const toId = sim.id || sim.skill_id;
        if (toId && nodes.has(toId)) {
          addEdge({ from: fromId, to: toId, type: 'similar_to',
                    similarity: sim.similarity ?? 0.5 });
        }
      }
    }
  }

  return { nodes, adj, radj, edges };
}

// ---------------------------------------------------------------------------
// §2  Cycle Detection (DFS — Tarjan's colour algorithm)
// ---------------------------------------------------------------------------

/**
 * Detect cycles in the `depends_on` + `composes` subgraph.
 * Uses the standard three-colour DFS (WHITE / GRAY / BLACK).
 *
 * @param {Object} graph - from buildGraph()
 * @returns {Array<Array<string>>} cycles - each element is a cycle path [id1, id2, ..., id1]
 */
function detectCycles(graph) {
  const { nodes, adj } = graph;
  const WHITE = 0, GRAY = 1, BLACK = 2;
  const colour = new Map();
  const cycles = [];

  for (const id of nodes.keys()) colour.set(id, WHITE);

  function dfs(id, path) {
    colour.set(id, GRAY);
    path.push(id);

    const outEdges = (adj.get(id) || []).filter(
      e => e.type === 'depends_on' || e.type === 'composes'
    );

    for (const edge of outEdges) {
      const nid = edge.to;
      if (colour.get(nid) === GRAY) {
        // Back-edge → cycle found
        const cycleStart = path.indexOf(nid);
        cycles.push([...path.slice(cycleStart), nid]);
      } else if (colour.get(nid) === WHITE) {
        dfs(nid, path);
      }
    }

    path.pop();
    colour.set(id, BLACK);
  }

  for (const id of nodes.keys()) {
    if (colour.get(id) === WHITE) dfs(id, []);
  }

  return cycles;
}

// ---------------------------------------------------------------------------
// §3  Topological Sort (Kahn's algorithm — BFS-based)
// ---------------------------------------------------------------------------

/**
 * Return a topological ordering of a skill set such that every skill
 * appears after all its dependencies.  Only considers `depends_on` and
 * `composes` edges that point to skills in the provided set.
 *
 * PRECONDITION: the subgraph must be acyclic (run detectCycles first).
 *
 * @param {Set<string>}   skillIds - IDs of skills to order
 * @param {Object}        graph    - from buildGraph()
 * @returns {string[]}   ordered IDs, dependencies first
 */
function topologicalSort(skillIds, graph) {
  const { adj } = graph;
  const inDegree = new Map();

  for (const id of skillIds) inDegree.set(id, 0);

  // Count in-degrees for edges within the subset
  for (const id of skillIds) {
    for (const edge of (adj.get(id) || [])) {
      if ((edge.type === 'depends_on' || edge.type === 'composes')
          && skillIds.has(edge.to)) {
        inDegree.set(edge.to, (inDegree.get(edge.to) || 0) + 1);
      }
    }
  }

  const queue = [];
  for (const [id, deg] of inDegree) {
    if (deg === 0) queue.push(id);
  }

  const result = [];
  while (queue.length > 0) {
    const id = queue.shift();
    result.push(id);

    for (const edge of (adj.get(id) || [])) {
      if ((edge.type === 'depends_on' || edge.type === 'composes')
          && skillIds.has(edge.to)) {
        const newDeg = (inDegree.get(edge.to) || 1) - 1;
        inDegree.set(edge.to, newDeg);
        if (newDeg === 0) queue.push(edge.to);
      }
    }
  }

  // If result.length < skillIds.size there is a cycle (should be caught earlier)
  return result;
}

// ---------------------------------------------------------------------------
// §4  Bundle Resolution (BFS + dependency expansion)
// ---------------------------------------------------------------------------

/**
 * Resolve the execution-complete skill bundle for a given seed skill ID.
 * Follows depends_on (required=true), depends_on (required=false, optional),
 * and composes edges up to GRAPH_MAX_TRAVERSAL_DEPTH hops.
 *
 * @param {string}  seedId     - skill_id of the primary matched skill
 * @param {Object}  graph      - from buildGraph()
 * @param {Object}  [options]
 * @param {boolean} [options.includeOptional=true]  - include optional deps
 * @param {number}  [options.maxDepth]              - override max traversal depth
 * @returns {Object} bundle
 *   {
 *     skills: Array<{ id, name, skill_tier, required, depth, bundle_rank }>,
 *     orderedIds: string[],   // topological install order
 *     trimmed: boolean,       // true if token budget forced trimming
 *   }
 */
function resolveBundle(seedId, graph, options = {}) {
  const {
    includeOptional = true,
    maxDepth = GRAPH_MAX_TRAVERSAL_DEPTH,
  } = options;

  const { nodes, adj } = graph;
  const visited   = new Map();  // id → { depth, required, bundle_rank }
  const queue     = [{ id: seedId, depth: 0, required: true, parentRank: 1.0 }];

  while (queue.length > 0) {
    const { id, depth, required: isRequired, parentRank } = queue.shift();

    if (visited.has(id)) continue;
    if (depth > maxDepth) continue;
    if (!nodes.has(id)) continue;

    // Base bundle_rank = parent rank × 0.85 per hop (decay factor)
    const bundle_rank = parentRank * Math.pow(0.85, depth);
    visited.set(id, { depth, required: isRequired, bundle_rank });

    // Expand outgoing dependency/composition edges
    for (const edge of (adj.get(id) || [])) {
      if (visited.has(edge.to)) continue;

      if (edge.type === 'depends_on') {
        const childRequired = isRequired && (edge.required !== false);
        if (!includeOptional && !childRequired) continue;
        queue.push({ id: edge.to, depth: depth + 1,
                     required: childRequired, parentRank: bundle_rank });
      } else if (edge.type === 'composes') {
        // All composed sub-skills are considered required for planning skills
        queue.push({ id: edge.to, depth: depth + 1,
                     required: isRequired, parentRank: bundle_rank });
      }
    }
  }

  // Build enriched skill list
  const skills = [];
  for (const [id, meta] of visited) {
    const node = nodes.get(id);
    if (!node) continue;
    skills.push({
      id,
      name:       node.name,
      skill_tier: node.skill_tier,
      required:   meta.required,
      depth:      meta.depth,
      bundle_rank: meta.bundle_rank,
      lean_score: node.lean_score,
      deprecated: node.deprecated || false,
    });
  }

  // Sort by bundle_rank descending for priority, then topological for install
  const skillIdSet = new Set(skills.map(s => s.id));
  const orderedIds = topologicalSort(skillIdSet, graph);

  return {
    skills,
    orderedIds,
    trimmed: false,
  };
}

// ---------------------------------------------------------------------------
// §5  Similarity Search
// ---------------------------------------------------------------------------

/**
 * Find all skills similar to the given skill (via similar_to edges).
 *
 * @param {string} skillId    - source skill ID
 * @param {Object} graph      - from buildGraph()
 * @param {number} [threshold=0.0] - minimum similarity (0.0–1.0)
 * @returns {Array<{ id, name, similarity }>} sorted by similarity descending
 */
function findSimilarSkills(skillId, graph, threshold = 0.0) {
  const { adj, nodes } = graph;
  const results = [];

  for (const edge of (adj.get(skillId) || [])) {
    if (edge.type !== 'similar_to') continue;
    const sim = edge.similarity ?? 0.5;
    if (sim < threshold) continue;
    const node = nodes.get(edge.to);
    if (!node) continue;
    results.push({ id: edge.to, name: node.name, similarity: sim });
  }

  results.sort((a, b) => b.similarity - a.similarity);
  return results;
}

/**
 * Return all pairs of skills with similarity ≥ threshold (merge candidates).
 *
 * @param {Object} graph
 * @param {number} [threshold=GRAPH_SIMILARITY_MERGE_THRESHOLD]
 * @returns {Array<{ idA, nameA, idB, nameB, similarity }>}
 */
function findMergeCandidates(graph, threshold = GRAPH_SIMILARITY_MERGE_THRESHOLD) {
  const seen = new Set();
  const candidates = [];

  for (const edge of graph.edges) {
    if (edge.type !== 'similar_to') continue;
    const sim = edge.similarity ?? 0.5;
    if (sim < threshold) continue;

    // Deduplicate bidirectional pairs
    const key = [edge.from, edge.to].sort().join('::');
    if (seen.has(key)) continue;
    seen.add(key);

    const nodeA = graph.nodes.get(edge.from);
    const nodeB = graph.nodes.get(edge.to);
    if (!nodeA || !nodeB) continue;

    candidates.push({
      idA:        edge.from,
      nameA:      nodeA.name,
      idB:        edge.to,
      nameB:      nodeB.name,
      similarity: sim,
    });
  }

  candidates.sort((a, b) => b.similarity - a.similarity);
  return candidates;
}

// ---------------------------------------------------------------------------
// §6  Graph Health Checks
// ---------------------------------------------------------------------------

/**
 * Run all graph health checks (GRAPH-001 through GRAPH-008).
 * Mirrors the checks in validate.js but operates on an already-built graph.
 *
 * @param {Object} graph        - from buildGraph()
 * @param {Object} [options]
 * @param {number} [options.similarityMergeThreshold]
 * @returns {Object} report
 *   { errors: Issue[], warnings: Issue[], infos: Issue[], healthy: boolean }
 */
function checkGraphHealth(graph, options = {}) {
  const mergeThreshold = options.similarityMergeThreshold ?? GRAPH_SIMILARITY_MERGE_THRESHOLD;
  const errors   = [];
  const warnings = [];
  const infos    = [];

  const { nodes, adj, edges } = graph;

  // GRAPH-001: dangling edge targets
  for (const edge of edges) {
    if (!nodes.has(edge.from)) {
      errors.push({ code: 'GRAPH-001',
        message: `Edge source "${edge.from}" not found in registry` });
    }
    if (!nodes.has(edge.to)) {
      errors.push({ code: 'GRAPH-001',
        message: `Edge target "${edge.to}" (from "${edge.from}" via ${edge.type}) not found in registry` });
    }
  }

  // GRAPH-002: planning skill missing composes edges
  for (const [id, node] of nodes) {
    if (node.skill_tier === 'planning') {
      const hasComposes = (adj.get(id) || []).some(e => e.type === 'composes');
      if (!hasComposes) {
        warnings.push({ code: 'GRAPH-002',
          message: `"${node.name}" (${id}) is planning tier but has no composes edges` });
      }
    }
  }

  // GRAPH-003: atomic skill has depends_on
  for (const [id, node] of nodes) {
    if (node.skill_tier === 'atomic') {
      const hasDeps = (adj.get(id) || []).some(e => e.type === 'depends_on');
      if (hasDeps) {
        warnings.push({ code: 'GRAPH-003',
          message: `"${node.name}" (${id}) is atomic tier but declares depends_on edges` +
                   ' — atomic skills should be self-contained' });
      }
    }
  }

  // GRAPH-004: merge advisory (similar_to ≥ threshold)
  const mergeCandidates = findMergeCandidates(graph, mergeThreshold);
  for (const pair of mergeCandidates) {
    warnings.push({ code: 'GRAPH-004',
      message: `"${pair.nameA}" and "${pair.nameB}" have similarity ${pair.similarity.toFixed(2)}` +
               ' — consider merging (similarity ≥ ' + mergeThreshold + ')' });
  }

  // GRAPH-005: cycles
  const cycles = detectCycles(graph);
  for (const cycle of cycles) {
    errors.push({ code: 'GRAPH-005',
      message: `Cycle detected: ${cycle.join(' → ')}` });
  }

  // GRAPH-006: isolated nodes (no edges of any type)
  const isolatedNames = [];
  for (const [id, node] of nodes) {
    const outEdges = adj.get(id) || [];
    if (outEdges.length === 0) isolatedNames.push(node.name);
  }
  if (isolatedNames.length > 0) {
    infos.push({ code: 'GRAPH-006',
      message: `${isolatedNames.length} isolated skill(s) with no graph edges: ` +
               `[${isolatedNames.slice(0, 5).join(', ')}${isolatedNames.length > 5 ? ', ...' : ''}]` });
  }

  // GRAPH-007: planning skill composes deprecated sub-skills
  for (const [id, node] of nodes) {
    if (node.skill_tier !== 'planning') continue;
    const composedEdges = (adj.get(id) || []).filter(e => e.type === 'composes');
    const deprecatedTargets = composedEdges
      .map(e => nodes.get(e.to))
      .filter(n => n && n.deprecated)
      .map(n => n.name);
    if (deprecatedTargets.length > 0) {
      warnings.push({ code: 'GRAPH-007',
        message: `"${node.name}" composes deprecated sub-skill(s): [${deprecatedTargets.join(', ')}]` });
    }
  }

  // GRAPH-008: provides type with no consumer
  const providedTypes  = new Map();   // type → Set<skill_id>
  const consumedTypes  = new Set();

  for (const edge of edges) {
    if (edge.type === 'provides') {
      if (!providedTypes.has(edge.to)) providedTypes.set(edge.to, new Set());
      providedTypes.get(edge.to).add(edge.from);
    }
    if (edge.type === 'consumes') consumedTypes.add(edge.to);
  }
  for (const [type, producers] of providedTypes) {
    if (!consumedTypes.has(type)) {
      const producerNames = [...producers]
        .map(id => nodes.get(id)?.name || id)
        .join(', ');
      infos.push({ code: 'GRAPH-008',
        message: `Data type "${type}" is provided by [${producerNames}] but no skill consumes it` });
    }
  }

  return {
    errors,
    warnings,
    infos,
    healthy: errors.length === 0,
    summary: {
      nodeCount:  nodes.size,
      edgeCount:  edges.length,
      errorCount: errors.length,
      warnCount:  warnings.length,
      infoCount:  infos.length,
    },
  };
}

// ---------------------------------------------------------------------------
// §7  D8 LEAN Composability Scoring
// ---------------------------------------------------------------------------

/**
 * Compute the D8 Composability LEAN score (0–20) for a single skill.
 *
 * @param {Object} skillFrontmatter - parsed YAML frontmatter of the skill
 * @param {Object} [graph]          - optional built graph for ID validation
 * @returns {Object} { score, max, checks }
 */
function scoreD8Composability(skillFrontmatter, _graph = null) {
  const checks = {
    graph_block_present:        { points: 5,  earned: 0, detail: '' },
    skill_tier_graph_consistent: { points: 10, earned: 0, detail: '' },
    graph_edge_ids_valid_format: { points: 5,  earned: 0, detail: '' },
  };

  const g = skillFrontmatter.graph;

  // Check 1: graph block present (5 pts)
  if (g && typeof g === 'object' && Object.keys(g).length > 0) {
    checks.graph_block_present.earned = 5;
    checks.graph_block_present.detail = 'graph: block present';
  } else {
    checks.graph_block_present.detail = 'graph: block absent — D8 scoring 0 (no penalty)';
    // No graph block → D8 = 0 (optional dimension, no penalty)
    return { score: 0, max: 20, checks, note: 'graph: block absent' };
  }

  // Check 2: tier consistency (10 pts)
  const tier = skillFrontmatter.skill_tier || 'functional';
  const hasComposes   = Array.isArray(g.composes)   && g.composes.length > 0;
  const hasDepsOn     = Array.isArray(g.depends_on) && g.depends_on.length > 0;
  const hasProvides   = Array.isArray(g.provides)   && g.provides.length > 0;
  const hasConsumes   = Array.isArray(g.consumes)   && g.consumes.length > 0;

  if (tier === 'planning') {
    if (hasComposes) {
      checks.skill_tier_graph_consistent.earned = 10;
      checks.skill_tier_graph_consistent.detail = 'planning + composes: correct';
    } else if (hasDepsOn) {
      checks.skill_tier_graph_consistent.earned = 5;
      checks.skill_tier_graph_consistent.detail = 'planning: has depends_on but missing composes (advisory)';
    } else {
      checks.skill_tier_graph_consistent.earned = 2;
      checks.skill_tier_graph_consistent.detail = 'planning: graph block present but no composes or depends_on';
    }
  } else if (tier === 'functional') {
    if (hasProvides || hasConsumes) {
      checks.skill_tier_graph_consistent.earned = 10;
      checks.skill_tier_graph_consistent.detail = 'functional + provides/consumes: correct';
    } else {
      checks.skill_tier_graph_consistent.earned = 7;
      checks.skill_tier_graph_consistent.detail = 'functional: no provides/consumes (acceptable)';
    }
  } else if (tier === 'atomic') {
    if ((hasProvides || hasConsumes) && !hasDepsOn) {
      checks.skill_tier_graph_consistent.earned = 10;
      checks.skill_tier_graph_consistent.detail = 'atomic + provides/consumes, no depends_on: correct';
    } else if (hasDepsOn) {
      checks.skill_tier_graph_consistent.earned = 4;
      checks.skill_tier_graph_consistent.detail = 'atomic: has depends_on — atomic skills should be self-contained (advisory)';
    } else {
      checks.skill_tier_graph_consistent.earned = 7;
      checks.skill_tier_graph_consistent.detail = 'atomic: graph block present; no provides/consumes (acceptable)';
    }
  }

  // Check 3: edge ID format (5 pts)
  const hexIdPattern = /^[a-f0-9]{12}$/;
  const allIds = [];
  if (Array.isArray(g.depends_on)) {
    allIds.push(...g.depends_on.map(d => d.id || '').filter(Boolean));
  }
  if (Array.isArray(g.composes)) {
    allIds.push(...g.composes.map(c => c.id || '').filter(Boolean));
  }
  if (Array.isArray(g.similar_to)) {
    allIds.push(...g.similar_to.map(s => s.id || '').filter(Boolean));
  }

  if (allIds.length === 0) {
    // No IDs to validate — only provides/consumes declared
    checks.graph_edge_ids_valid_format.earned = 5;
    checks.graph_edge_ids_valid_format.detail = 'no skill ID references to validate (provides/consumes only)';
  } else {
    const invalidIds = allIds.filter(id => !hexIdPattern.test(id));
    if (invalidIds.length === 0) {
      checks.graph_edge_ids_valid_format.earned = 5;
      checks.graph_edge_ids_valid_format.detail = `all ${allIds.length} skill ID(s) match [a-f0-9]{12} format`;
    } else {
      checks.graph_edge_ids_valid_format.earned = 0;
      checks.graph_edge_ids_valid_format.detail = `${invalidIds.length} invalid ID(s): [${invalidIds.slice(0, 3).join(', ')}]`;
    }
  }

  const score = Object.values(checks).reduce((sum, c) => sum + c.earned, 0);
  return { score, max: 20, checks };
}

// ---------------------------------------------------------------------------
// Module exports
// ---------------------------------------------------------------------------

module.exports = {
  buildGraph,
  detectCycles,
  topologicalSort,
  resolveBundle,
  findSimilarSkills,
  findMergeCandidates,
  checkGraphHealth,
  scoreD8Composability,
};
