/**
 * Project Configuration - Single Source of Truth
 *
 * Centralizes all path definitions and configuration constants
 * to prevent SSOT (Single Source of Truth) breaks across modules.
 *
 * @module builder/src/config
 * @version 3.1.0
 */

const path = require('path');

// Project root directory
const PROJECT_ROOT = path.resolve(__dirname, '../..');

/**
 * Path configuration
 */
const PATHS = {
  root: PROJECT_ROOT,
  templates: path.join(PROJECT_ROOT, 'templates'),
  refs: path.join(PROJECT_ROOT, 'refs'),
  eval: path.join(PROJECT_ROOT, 'eval'),
  optimize: path.join(PROJECT_ROOT, 'optimize'),
  platforms: path.join(PROJECT_ROOT, 'platforms'),
  skillFramework: path.join(PROJECT_ROOT, 'skill-framework.md'),
};

/**
 * Required companion files configuration
 * Each file can specify whether it needs to be embedded or just validated
 */
const REQUIRED_FILES = [
  // Refs - must be embedded
  { path: path.join(PATHS.refs, 'self-review.md'), label: 'refs/self-review.md', mustEmbed: true },
  { path: path.join(PATHS.refs, 'use-to-evolve.md'), label: 'refs/use-to-evolve.md', mustEmbed: true },
  { path: path.join(PATHS.refs, 'security-patterns.md'), label: 'refs/security-patterns.md', mustEmbed: true },
  { path: path.join(PATHS.refs, 'evolution.md'), label: 'refs/evolution.md', mustEmbed: true },
  { path: path.join(PATHS.refs, 'convergence.md'), label: 'refs/convergence.md', mustEmbed: true },
  // Refs - v3.0 additions (SkillClaw collective evolution)
  { path: path.join(PATHS.refs, 'session-artifact.md'), label: 'refs/session-artifact.md', mustEmbed: true },
  { path: path.join(PATHS.refs, 'edit-audit.md'), label: 'refs/edit-audit.md', mustEmbed: true },
  { path: path.join(PATHS.refs, 'skill-registry.md'), label: 'refs/skill-registry.md', mustEmbed: true },
  // Refs - v3.1.1 additions
  { path: path.join(PATHS.refs, 'progressive-disclosure.md'), label: 'refs/progressive-disclosure.md', mustEmbed: true },
  // Refs - v3.2.0 additions (Graph of Skills)
  { path: path.join(PATHS.refs, 'skill-graph.md'), label: 'refs/skill-graph.md', mustEmbed: true },
  // Eval - must be embedded
  { path: path.join(PATHS.eval, 'rubrics.md'), label: 'eval/rubrics.md', mustEmbed: true },
  { path: path.join(PATHS.eval, 'benchmarks.md'), label: 'eval/benchmarks.md', mustEmbed: true },
  // Optimize - must be embedded
  { path: path.join(PATHS.optimize, 'strategies.md'), label: 'optimize/strategies.md', mustEmbed: true },
  { path: path.join(PATHS.optimize, 'anti-patterns.md'), label: 'optimize/anti-patterns.md', mustEmbed: true },
  // Templates - must be embedded
  { path: path.join(PATHS.templates, 'base.md'), label: 'templates/base.md', mustEmbed: true },
  { path: path.join(PATHS.templates, 'api-integration.md'), label: 'templates/api-integration.md', mustEmbed: true },
  { path: path.join(PATHS.templates, 'data-pipeline.md'), label: 'templates/data-pipeline.md', mustEmbed: true },
  { path: path.join(PATHS.templates, 'workflow-automation.md'), label: 'templates/workflow-automation.md', mustEmbed: true },
  { path: path.join(PATHS.templates, 'use-to-evolve-snippet.md'), label: 'templates/use-to-evolve-snippet.md', mustEmbed: true },
  // Main skill - validate only
  { path: PATHS.skillFramework, label: 'skill-framework.md', mustEmbed: false },
];

/**
 * Required UTE (Use-to-Evolve) fields
 */
const REQUIRED_UTE_FIELDS = [
  'enabled',
  'injected_by',
  'injected_at',
  'check_cadence',
  'micro_patch_enabled',
  'feedback_detection',
  'certified_lean_score',
  'last_ute_check',
  'pending_patches',
  'total_micro_patches_applied',
  'cumulative_invocations',
];

/**
 * Placeholder patterns for template processing
 */
const PLACEHOLDERS = {
  // Extended pattern: supports uppercase, digits, dots, hyphens — {{KEY}}, {{outer.key}}, {{OUTER-KEY}}
  // This is the single canonical pattern used everywhere (replaces the old narrower 'standard' variant).
  extended: /\{\{([\w.-]+)\}\}/g,
  // Cursor pattern: ${KEY} — supports lowercase, digits, underscores, dots, hyphens
  // Must be consistent with cursor.js formatSkill() which converts {{...}} → ${...}
  // using /\{\{([\w.-]+)\}\}/g (extended charset), so the reverse lookup must match.
  cursor: /\$\{([\w.-]+)\}/g,
};

/**
 * Author-time placeholders that are intentionally preserved in generated platform files.
 * These appear in embedded skill templates (base, api-integration, data-pipeline,
 * workflow-automation) as demonstration content for skill authors to fill in.
 * They are NOT build errors — they are "fill me in when you use this template" markers.
 *
 * Validate should ignore these when checking generated skill files.
 */
const AUTHOR_PLACEHOLDERS = new Set([
  // Generic template slots
  'PLACEHOLDER', 'SKILL_NAME', 'WORKFLOW_NAME',
  // Base template — identity
  'ONE_LINE_DESCRIPTION', 'EN_DESCRIPTION', 'ZH_DESCRIPTION',
  'AUTHOR', 'DATE', 'SKILL_TYPE', 'ROLE_DESCRIPTION', 'PURPOSE',
  'PRINCIPLE_1', 'PRINCIPLE_2', 'PRINCIPLE_3',
  'RED_LINE_1', 'RED_LINE_2',
  // Base template — v3.1.0 new fields (skill_tier, triggers, negative boundaries, skill summary)
  'TIER',
  'TRIGGER_PHRASE_EN_1', 'TRIGGER_PHRASE_EN_2', 'TRIGGER_PHRASE_EN_3',
  'TRIGGER_PHRASE_ZH_1', 'TRIGGER_PHRASE_ZH_2',
  'WHAT_IT_DOES', 'CANONICAL_USE_CASE_1', 'CANONICAL_USE_CASE_2',
  'TARGET_USERS', 'OUT_OF_SCOPE_TEASER',
  'ANTI_CASE_1', 'ANTI_CASE_2', 'ANTI_CASE_3',
  'ANTI_TRIGGER_PHRASE_1', 'ANTI_TRIGGER_PHRASE_2',
  'ALTERNATIVE_SKILL_1', 'ANTI_CASE_3_DESCRIPTION',
  // Base template — modes and examples
  'TAG_1', 'TAG_2', 'MODE_1', 'MODE_2',
  'MODE_1_TRIGGER_EN', 'MODE_1_TRIGGER_ZH', 'MODE_2_TRIGGER_EN', 'MODE_2_TRIGGER_ZH',
  'MODE_1_INPUT', 'MODE_1_OUTPUT', 'MODE_1_EXIT',
  'MODE_2_INPUT', 'MODE_2_OUTPUT', 'MODE_2_EXIT',
  'STEP_1', 'STEP_2', 'STEP_3',
  'EXAMPLE_1_TITLE', 'EXAMPLE_1_INPUT', 'EXAMPLE_1_OUTPUT',
  'EXAMPLE_2_TITLE', 'EXAMPLE_2_INPUT', 'EXAMPLE_2_OUTPUT', 'LANG',
  // Base template — security baseline
  'ENV_VAR_NAME', 'TOOLS_USED', 'IRREVERSIBLE_ACTIONS', 'MINIMUM_PERMISSIONS',
  // API integration template
  'API_NAME', 'ENDPOINT_1_PATH', 'AUTH_ENV_VAR', 'PARAM_1',
  'OUTPUT_FIELD_1', 'OUTPUT_FIELD_2', 'TYPE_1', 'TYPE_2', 'TYPE_3',
  // Data pipeline template
  'INPUT_FORMAT', 'OUTPUT_FORMAT', 'DURATION',
  'OUT_FIELD_1', 'OUT_FIELD_2', 'OUT_FIELD_3',
  'TRANSFORM_STEP_1', 'TRANSFORM_STEP_2',
  'EXAMPLE_TARGET', 'EXAMPLE_VALUE',
  'EXAMPLE_RESULT_1', 'EXAMPLE_RESULT_2',
  // Workflow automation template
  'STEP_NAME', 'STEP_1_NAME', 'STEP_2_NAME', 'STEP_3_NAME', 'STEP_N_NAME',
  'STEP_COUNT', 'STEP_1_ACTION', 'STEP_2_ACTION', 'STEP_3_ACTION',
]);

/**
 * Section markers
 */
const SECTIONS = {
  frontmatter: /^---\r?\n([\s\S]*?)\r?\n---/,
  uteSection: /##\s+§UTE/,
  header: /^(#{1,6})\s+(.+)$/,
};

/**
 * Platform configurations
 * Uses PLACEHOLDERS.extended so {{OUTER-KEY}} and {{outer.key}} are matched.
 * Cursor uses its own ${KEY} syntax.
 */
const PLATFORMS = {
  opencode: {
    name: 'opencode',
    placeholderPattern: PLACEHOLDERS.extended,
    sectionPrefix: '##',
    codeBlockLang: 'yaml',
    supportsFrontmatter: true,
    triggerFormat: 'markdown',
  },
  openclaw: {
    name: 'openclaw',
    placeholderPattern: PLACEHOLDERS.extended,
    sectionPrefix: '##',
    codeBlockLang: 'yaml',
    supportsFrontmatter: true,
    triggerFormat: 'markdown',
  },
  claude: {
    name: 'claude',
    placeholderPattern: PLACEHOLDERS.extended,
    sectionPrefix: '##',
    codeBlockLang: 'yaml',
    supportsFrontmatter: true,
    triggerFormat: 'markdown',
  },
  cursor: {
    name: 'cursor',
    placeholderPattern: PLACEHOLDERS.cursor,
    sectionPrefix: '##',
    codeBlockLang: 'yaml',
    supportsFrontmatter: false,
    triggerFormat: 'json',
  },
  openai: {
    name: 'openai',
    placeholderPattern: PLACEHOLDERS.extended,
    sectionPrefix: '##',
    codeBlockLang: 'json',
    supportsFrontmatter: true,
    triggerFormat: 'json',
  },
  gemini: {
    name: 'gemini',
    placeholderPattern: PLACEHOLDERS.extended,
    sectionPrefix: '##',
    codeBlockLang: 'yaml',
    supportsFrontmatter: true,
    triggerFormat: 'markdown',
  },
  mcp: {
    name: 'mcp',
    placeholderPattern: PLACEHOLDERS.extended,
    sectionPrefix: '##',
    codeBlockLang: 'json',
    supportsFrontmatter: false,
    triggerFormat: 'json',
  },
  a2a: {
    name: 'a2a',
    placeholderPattern: PLACEHOLDERS.extended,
    sectionPrefix: '##',
    codeBlockLang: 'json',
    supportsFrontmatter: false,
    triggerFormat: 'json',
  },
};

/**
 * Graph of Skills (GoS) edge type definitions.
 *
 * Each skill can declare typed relationships to other skills via the optional
 * `graph:` YAML frontmatter block.  These types mirror SkillNet (arxiv:2603.04448)
 * Layer 2 relational ontology and are used by:
 *   - builder/src/core/graph.js   — runtime graph construction & traversal
 *   - builder/src/commands/validate.js — GRAPH-001–005 checks
 *   - refs/skill-registry.md §2.0 — registry graph.edges schema
 *   - refs/skill-graph.md         — full GoS specification
 *
 * Research basis:
 *   - SkillNet (arxiv:2603.04448): compose / belong_to / depend_on / similar_to
 *   - Graph of Skills (GoS): Personalized PageRank bundle retrieval
 *   - SkillX (arxiv:2604.04804): planning/functional/atomic tier compatibility
 */
const GRAPH_EDGE_TYPES = ['depends_on', 'composes', 'similar_to', 'uses_resource', 'provides', 'consumes'];

/** Schema version for the graph section of registry.json */
const GRAPH_SCHEMA_VERSION = '2.0';

/** Similarity threshold above which two skills should be flagged as merge candidates */
const GRAPH_SIMILARITY_MERGE_THRESHOLD = 0.95;

/** Maximum BFS/PageRank depth for bundle resolution (prevents runaway traversal) */
const GRAPH_MAX_TRAVERSAL_DEPTH = 6;

/** Required fields in the graph: YAML block when declared */
const REQUIRED_GRAPH_FIELDS = ['depends_on', 'composes', 'similar_to', 'provides', 'consumes'];

/**
 * Unified 8-dimension scoring specification — canonical Single Source of Truth.
 *
 * All three evaluation modes use this schema:
 *   - LEAN    : each dimension scored 0–leanMax → total 520 pts  (heuristic, no LLM)
 *               D8 Composability is optional (20 pts); skills without graph: block score 0 on D8.
 *   - EVALUATE: Phase 2 Text Quality uses D1–D7 dimensions → total 300 pts
 *               Phase 5 (v4.0+) uses D8 → total 100 pts (see eval/rubrics.md §9)
 *               Phase 4 security scan is a *separate* gate on top of the security dimension.
 *   - OPTIMIZE: tracks per-dimension score deltas; weakest dimension drives strategy selection.
 *               S10–S12 are graph-level strategies targeting D8.
 *
 * Correspondence with eval/rubrics.md Phase 2 table (authoritative version synced here):
 *   systemDesign    ↔ "System Design"      (20%, 60 pts)
 *   domainKnowledge ↔ "Domain Knowledge"   (20%, 60 pts)
 *   workflow        ↔ "Workflow Definition" (15%, 45 pts)
 *   errorHandling   ↔ "Error Handling"     (15%, 45 pts)
 *   examples        ↔ "Examples"           (15%, 45 pts)
 *   security        ↔ "Security Baseline"  (10%, 30 pts)
 *   metadata        ↔ "Metadata Quality"   ( 5%, 15 pts)
 *   composability   ↔ "Composability/GoS"  (LEAN: 20 pts optional; EVALUATE Phase 5: 100 pts)
 *
 * NOTE on LEAN vs EVALUATE scoring discrepancy:
 *   LEAN leanMax values do NOT map 1:1 to EVALUATE Phase 2 per-dimension maxes.
 *   LEAN uses absolute point allocations tuned for fast heuristic checks.
 *   EVALUATE Phase 2 uses weight × 300 (e.g. security = 0.10 × 300 = 30 pts).
 *
 *   v3.1.0 LEAN rebalancing (research basis: SkillRouter arxiv:2603.22455):
 *     - systemDesign:    100 → 95  (freed 5 pts to metadata)
 *     - domainKnowledge: 100 → 95  (freed 5 pts to metadata)
 *     - security:         50 → 45  (freed 5 pts to metadata; OWASP ASI heuristics added)
 *     - metadata:         25 → 40  (+15 pts; now includes trigger phrase coverage + negative boundaries)
 *   v3.2.0 LEAN addition (research basis: GoS / SkillNet arxiv:2603.04448):
 *     - composability: 0 → 20 pts (new optional D8; skills without graph: block score 0, no penalty)
 *   Core LEAN total still 500 pts; D8 adds up to 20 bonus pts (max LEAN = 520).
 *   EVALUATE Phase 2 weights unchanged (D8 is Phase 5, not Phase 2).
 *
 * Enforcement level: [ENFORCED] for dimension names & weights; [ASPIRATIONAL] for cross-session aggregation.
 */
const SCORING = {
  lean: {
    maxScore: 500,       // core max (D1–D7); D8 adds up to 20 optional bonus pts
    maxScoreWithD8: 520, // v3.2.0: max when graph: block is present
    dimensions: 7,       // core dimensions (D1–D7); D8 is bonus
    passThreshold: 350,
  },
  evaluate: {
    maxScore: 1000,
    phases: 4,           // v4.0+ will add Phase 5 (+100 pts) for D8 Composability
    bronzeThreshold: 700,
    silverThreshold: 800,
    goldThreshold: 900,
    platinumThreshold: 950,
  },
  varianceGates: {
    platinum: 10,
    gold: 15,
    silver: 20,
    bronze: 30,
  },
  /**
   * Unified 7-dimension schema used across LEAN, EVALUATE, and OPTIMIZE.
   * weight: fraction of total 1000-pt score allocated to this dimension.
   * leanMax: maximum LEAN points for this dimension (sum = 500).
   * leanChecks: what the heuristic checks for in LEAN mode (documentation only).
   * strategies: OPTIMIZE strategy IDs that target this dimension.
   */
  dimensions: {
    systemDesign: {
      label: 'System Design',
      weight: 0.20,
      leanMax: 95,  // v3.1.0: was 100 (5 pts redistributed to metadata)
      leanChecks: ['identity_section_present', 'red_lines_present'],
      strategies: ['S1', 'S2'],
    },
    domainKnowledge: {
      label: 'Domain Knowledge',
      weight: 0.20,
      leanMax: 95,  // v3.1.0: was 100 (5 pts redistributed to metadata)
      leanChecks: ['template_accurately_used', 'field_specificity_visible', 'skill_summary_present'],
      strategies: ['S3', 'S4'],
    },
    workflow: {
      label: 'Workflow',
      weight: 0.15,
      leanMax: 75,
      leanChecks: ['min_3_mode_sections', 'quality_gates_table_present'],
      strategies: ['S5'],
    },
    errorHandling: {
      label: 'Error Handling',
      weight: 0.15,
      leanMax: 75,
      leanChecks: ['error_recovery_section_present', 'escalation_paths_documented'],
      strategies: ['S6'],
    },
    examples: {
      label: 'Examples',
      weight: 0.15,
      leanMax: 75,
      leanChecks: ['min_2_code_block_examples', 'trigger_keywords_en_zh'],
      strategies: ['S7'],
    },
    security: {
      label: 'Security',
      weight: 0.10,
      leanMax: 45,  // v3.1.0: was 50 (5 pts redistributed to metadata; ASI01 check added)
      leanChecks: ['security_baseline_section', 'no_hardcoded_secrets', 'asi01_clear'],
      strategies: ['S8'],
    },
    metadata: {
      label: 'Metadata',
      weight: 0.05,
      leanMax: 40,  // v3.1.0: was 25 (+15 pts; now covers trigger phrases + negative boundaries)
      leanChecks: ['yaml_frontmatter_present', 'trigger_phrases_3_to_8', 'negative_boundaries_section'],
      strategies: ['S9'],
    },
    // D8: Composability — Graph of Skills dimension (v3.2.0)
    // Optional bonus dimension; 0 pts if graph: block absent (no penalty).
    // Research basis: SkillNet (arxiv:2603.04448), GoS bundle retrieval.
    // LEAN: up to 20 bonus pts; EVALUATE Phase 5 (v4.0+): up to 100 pts.
    composability: {
      label: 'Composability',
      weight: 0.00,      // Phase 2 weight = 0; scored in Phase 5 only (v4.0+)
      leanMax: 20,       // optional bonus; skill scores 0 if graph: block absent
      leanChecks: [
        'graph_block_present',          // 5 pts: graph: field exists in frontmatter
        'skill_tier_graph_consistent',  // 10 pts: tier matches graph structure
        'graph_edge_ids_valid_format',  // 5 pts: edge IDs are 12-char hex format
      ],
      strategies: ['S10', 'S11', 'S12'],
    },
  },
  /** Minimum EVALUATE score delta required to declare convergence in OPTIMIZE loop */
  convergenceThreshold: 5,
};

/**
 * Graph-aware OPTIMIZE strategy codes (S10–S12) — canonical reference.
 * Full strategy descriptions live in optimize/strategies.md §4.
 */
const GRAPH_STRATEGIES = {
  S10: { id: 'S10', name: 'Graph Extraction',           dimension: 'composability', estimatedDelta: [15, 40] },
  S11: { id: 'S11', name: 'Coupling Reduction',         dimension: 'composability', estimatedDelta: [10, 30] },
  S12: { id: 'S12', name: 'Similarity Consolidation',   dimension: 'composability', estimatedDelta: [5,  20] },
};

/**
 * Error codes for consistent error handling
 */
const ERROR_CODES = {
  MISSING_PLACEHOLDER: 'EMISSING_PLACEHOLDER',
  INVALID_FRONTMATTER: 'EINVALID_FRONTMATTER',
  MISSING_REQUIRED_FILE: 'EMISSING_REQUIRED_FILE',
  EMBED_FAILED: 'EEMBED_FAILED',
  VALIDATION_FAILED: 'EVALIDATION_FAILED',
};

/**
 * Platforms whose build output is JSON rather than Markdown.
 * Single Source of Truth — consumed by build.js and platforms/index.js.
 * Previously duplicated as local constants in both files; now defined once here.
 */
const JSON_OUTPUT_PLATFORMS = new Set(['openai', 'mcp', 'a2a']);

module.exports = {
  PATHS,
  REQUIRED_FILES,
  REQUIRED_UTE_FIELDS,
  PLACEHOLDERS,
  AUTHOR_PLACEHOLDERS,
  SECTIONS,
  PLATFORMS,
  SCORING,
  ERROR_CODES,
  PROJECT_ROOT,
  JSON_OUTPUT_PLATFORMS,
  // v3.2.0: Graph of Skills exports
  GRAPH_EDGE_TYPES,
  GRAPH_SCHEMA_VERSION,
  GRAPH_SIMILARITY_MERGE_THRESHOLD,
  GRAPH_MAX_TRAVERSAL_DEPTH,
  REQUIRED_GRAPH_FIELDS,
  GRAPH_STRATEGIES,
};
