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
  // Standard pattern: {{KEY}}
  standard: /\{\{([A-Z_0-9]+)\}\}/g,
  // Extended pattern: supports dots and hyphens {{outer.key}} or {{OUTER-KEY}}
  extended: /\{\{([\w.-]+)\}\}/g,
  // Cursor pattern: ${KEY}
  cursor: /\$\{([A-Z_0-9]+)\}/g,
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
  frontmatter: /^---\n([\s\S]*?)\n---/,
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
};

/**
 * Unified 7-dimension scoring specification — canonical Single Source of Truth.
 *
 * All three evaluation modes use this schema:
 *   - LEAN    : each dimension scored 0–leanMax → total 500 pts  (heuristic, no LLM)
 *   - EVALUATE: Phase 2 Text Quality uses these 7 dimensions → total 300 pts
 *               (weight × 300 = per-dimension max in Phase 2)
 *               Phase 4 security scan is a *separate* gate on top of the security dimension.
 *   - OPTIMIZE: tracks per-dimension score deltas; weakest dimension drives strategy selection.
 *
 * Correspondence with eval/rubrics.md Phase 2 table (authoritative version synced here):
 *   systemDesign    ↔ "System Design"      (20%, 60 pts)
 *   domainKnowledge ↔ "Domain Knowledge"   (20%, 60 pts)
 *   workflow        ↔ "Workflow Definition" (15%, 45 pts)
 *   errorHandling   ↔ "Error Handling"     (15%, 45 pts)
 *   examples        ↔ "Examples"           (15%, 45 pts)
 *   security        ↔ "Security Baseline"  (10%, 30 pts)
 *   metadata        ↔ "Metadata Quality"   ( 5%, 15 pts)
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
 *   Total LEAN still = 500 pts. EVALUATE Phase 2 weights unchanged.
 *
 * Enforcement level: [ENFORCED] for dimension names & weights; [ASPIRATIONAL] for cross-session aggregation.
 */
const SCORING = {
  lean: {
    maxScore: 500,
    dimensions: 7,
    passThreshold: 350,
  },
  evaluate: {
    maxScore: 1000,
    phases: 4,
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
  },
  /** Minimum EVALUATE score delta required to declare convergence in OPTIMIZE loop */
  convergenceThreshold: 5,
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
const JSON_OUTPUT_PLATFORMS = new Set(['openai', 'mcp']);

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
};
