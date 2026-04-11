/**
 * Project Configuration - Single Source of Truth
 * 
 * Centralizes all path definitions and configuration constants
 * to prevent SSOT (Single Source of Truth) breaks across modules.
 * 
 * @module builder/src/config
 * @version 2.1.0
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
   * strategies: OPTIMIZE strategy IDs that target this dimension.
   */
  dimensions: {
    systemDesign: {
      label: 'System Design',
      weight: 0.20,
      leanMax: 100,
      strategies: ['S1', 'S2'],
    },
    domainKnowledge: {
      label: 'Domain Knowledge',
      weight: 0.20,
      leanMax: 100,
      strategies: ['S3', 'S4'],
    },
    workflow: {
      label: 'Workflow',
      weight: 0.15,
      leanMax: 75,
      strategies: ['S5'],
    },
    errorHandling: {
      label: 'Error Handling',
      weight: 0.15,
      leanMax: 75,
      strategies: ['S6'],
    },
    examples: {
      label: 'Examples',
      weight: 0.15,
      leanMax: 75,
      strategies: ['S7'],
    },
    security: {
      label: 'Security',
      weight: 0.10,
      leanMax: 50,
      strategies: ['S8'],
    },
    metadata: {
      label: 'Metadata',
      weight: 0.05,
      leanMax: 25,
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

module.exports = {
  PATHS,
  REQUIRED_FILES,
  REQUIRED_UTE_FIELDS,
  PLACEHOLDERS,
  SECTIONS,
  PLATFORMS,
  SCORING,
  ERROR_CODES,
  PROJECT_ROOT,
};
