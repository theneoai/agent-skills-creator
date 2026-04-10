/**
 * OpenClaw Platform Adapter
 *
 * Adapts skills to the OpenClaw AgentSkills format.
 * OpenClaw requires a `metadata.openclaw` frontmatter block and expects
 * the LoongFlow (§4), Self-Review (§9), and UTE (§11) sections to be present.
 *
 * @module builder/src/platforms/openclaw
 * @version 2.2.0
 */

const path = require('path');
const os = require('os');

const name = 'openclaw';

// ---------------------------------------------------------------------------
// Constants — centralised so they don't scatter across formatSkill / validate
// ---------------------------------------------------------------------------

const OPENCLAW_METADATA = {
  format: 'agentskills',
  compatibility: ['1.0', '2.0'],
  features: ['self-review', 'self-evolution'],
  runtime: { timeout: 30000, maxRetries: 3, checkpointInterval: 10 },
};

/** Sections that OpenClaw mandates in the skill body */
const REQUIRED_SECTIONS = [
  '## §1 Identity',
  '## §4 LoongFlow Orchestration',
  '## §9 Self-Review Protocol',
];

/** Sections that are strongly recommended but not blocking */
const RECOMMENDED_SECTIONS = [
  '## §11 UTE Injection',
];

const LOONGFLOW_BODY = `
## §4 LoongFlow Orchestration

Every mode executes via Plan-Execute-Summarize:

\`\`\`
┌──────────────────────────────────────────────────────────┐
│  PLAN                                                    │
│  Multi-pass self-review → plan reviewed                  │
│  Build cognitive graph of steps                          │
└──────────────────────────────┬───────────────────────────┘
                               │ consensus reached
                               ▼
┌──────────────────────────────────────────────────────────┐
│  EXECUTE                                                 │
│  Implement plan with error recovery fallback             │
│  Hard checkpoint after each phase                        │
└──────────────────────────────┬───────────────────────────┘
                               │ execution complete
                               ▼
┌──────────────────────────────────────────────────────────┐
│  SUMMARIZE                                               │
│  Cross-validate results against requirements             │
│  Update evolution memory                                 │
│  Route: CERTIFIED | TEMP_CERT | HUMAN_REVIEW | ABORT     │
└──────────────────────────────────────────────────────────┘
\`\`\``;

const SELF_REVIEW_BODY = `
## §9 Self-Review Protocol

| Role | Responsibility |
|------|----------------|
| Pass 1 — Generate | Produce initial draft / score / fix proposal |
| Pass 2 — Review | Security + quality audit; severity-tagged issue list (ERROR/WARNING/INFO) |
| Pass 3 — Reconcile | Address all ERRORs, reconcile scores, produce final artifact |

Timeouts: 30 s per pass, 60 s per phase, 180 s total (6 turns max).
Consensus: CLEAR → proceed; REVISED → proceed with notes;
UNRESOLVED → HUMAN_REVIEW.`;

const UTE_BODY = `
## §11 UTE Injection

**Use-to-Evolve (UTE)** enables self-improving capabilities through actual usage.

| Capability | Mechanism |
|-----------|-----------|
| Per-call usage recording | Post-Invocation Hook appended to skill context |
| Implicit feedback detection | Pattern match on user follow-up |
| Trigger candidate collection | Rephrasing signals logged; count≥3 → micro-patch candidate |
| Lightweight check every 10 calls | Rolling 20-call success rate + trigger accuracy check |
| Full metric recompute every 50 calls | F1 / MRR / trigger_accuracy from usage log |
| Tier drift detection every 100 calls | Estimated LEAN vs certified baseline |
| Autonomous micro-patching | Keyword additions staged + LEAN-validated before apply |

\`\`\`yaml
use_to_evolve:
  enabled: true
  certified_lean_score: 0
  last_ute_check: null
\`\`\``;

// ---------------------------------------------------------------------------
// Template definition
// ---------------------------------------------------------------------------

const template = {
  frontmatter: `---
name: {{name}}
version: {{version}}
description: {{description}}
license: {{license}}
author: {{author}}
tags: {{tags}}
interface:
  mode:
    type: enum
    values: {{modes}}
    default: {{defaultMode}}
    description: Operating mode for the skill
metadata:
  openclaw:
    format: agentskills
    compatibility: ["1.0", "2.0"]
    features:
      - self-review
      - self-evolution
    runtime:
      timeout: 30000
      maxRetries: 3
      checkpointInterval: 10
---`,
  sections: [
    '## §1 Identity',
    '## §2 Mode Router',
    '## §3 Graceful Degradation',
    '## §4 LoongFlow Orchestration',
    '## §5 Workflow',
    '## §6 Quality Gates',
    '## §7 Security Baseline',
    '## §8 Error Handling',
    '## §9 Self-Review Protocol',
    '## §10 Usage Examples',
    '## §11 UTE Injection',
  ],
  requiredFields: ['name', 'version', 'description', 'metadata.openclaw'],
};

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/**
 * Check whether a section heading is present in the content.
 * @param {string} content
 * @param {string} sectionHeading - e.g. '## §4 LoongFlow Orchestration'
 */
function hasSection(content, sectionHeading) {
  const escaped = sectionHeading.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  return new RegExp(`^${escaped}`, 'm').test(content);
}

/**
 * Inject `metadata.openclaw` into frontmatter if not already present.
 */
function ensureOpenClawMetadata(content) {
  const frontmatterMatch = content.match(/^---\n([\s\S]*?)\n---/);
  if (!frontmatterMatch) return content;

  const fm = frontmatterMatch[1];
  if (fm.includes('metadata:') && fm.includes('openclaw:')) return content;

  const metaBlock = [
    'metadata:',
    '  openclaw:',
    `    format: ${OPENCLAW_METADATA.format}`,
    `    compatibility: ${JSON.stringify(OPENCLAW_METADATA.compatibility)}`,
    '    features:',
    ...OPENCLAW_METADATA.features.map(f => `      - ${f}`),
    '    runtime:',
    `      timeout: ${OPENCLAW_METADATA.runtime.timeout}`,
    `      maxRetries: ${OPENCLAW_METADATA.runtime.maxRetries}`,
    `      checkpointInterval: ${OPENCLAW_METADATA.runtime.checkpointInterval}`,
  ].join('\n');

  return content.replace(/^---\n([\s\S]*?)\n---/, `---\n$1\n${metaBlock}\n---`);
}

/**
 * Inject a section body after the Mode Router section (§2), or append to end.
 * @param {string} content
 * @param {string} sectionBody - Full section text (starts with `\n## §N …`)
 * @param {string} insertAfter - Heading to insert after (e.g. '## §2 Mode Router')
 */
function injectSection(content, sectionBody, insertAfter) {
  if (insertAfter) {
    const escaped = insertAfter.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const afterPattern = new RegExp(`(${escaped}[\\s\\S]*?)(\n## §|$)`);
    const match = content.match(afterPattern);
    if (match) {
      return content.replace(match[1], match[1] + sectionBody);
    }
  }
  return content + sectionBody;
}

// ---------------------------------------------------------------------------
// Adapter interface
// ---------------------------------------------------------------------------

/**
 * Format skill content for the OpenClaw platform.
 * Ensures:
 *   1. `metadata.openclaw` block in frontmatter
 *   2. §4 LoongFlow Orchestration section
 *   3. §9 Self-Review Protocol section
 *   4. §11 UTE Injection section (recommended)
 *
 * @param {string} skillContent - Raw skill content (Markdown with YAML frontmatter)
 * @returns {string} Formatted content for OpenClaw
 */
function formatSkill(skillContent) {
  if (!skillContent || typeof skillContent !== 'string') {
    throw new Error('Invalid skill content provided');
  }

  const frontmatterMatch = skillContent.match(/^---\n([\s\S]*?)\n---/);
  if (!frontmatterMatch) {
    throw new Error('Skill content missing required YAML frontmatter');
  }

  let content = skillContent;

  // 1. Ensure metadata.openclaw is in frontmatter
  content = ensureOpenClawMetadata(content);

  // 2. Inject LoongFlow section if missing
  if (!hasSection(content, '## §4 LoongFlow Orchestration')) {
    content = injectSection(content, LOONGFLOW_BODY, '## §2 Mode Router');
  }

  // 3. Inject Self-Review section if missing
  if (!hasSection(content, '## §9 Self-Review Protocol')) {
    content = injectSection(content, SELF_REVIEW_BODY, '## §8 Error Handling');
  }

  // 4. Inject UTE section if missing (recommended, not mandatory)
  if (!hasSection(content, '## §11 UTE Injection')) {
    content = content + UTE_BODY;
  }

  return content.trim();
}

/**
 * Get the installation path for OpenClaw skills.
 * @returns {string} Installation path
 */
function getInstallPath() {
  return path.join(os.homedir(), '.openclaw', 'skills');
}

/**
 * Generate OpenClaw-specific metadata.
 * @param {Object} skillData - Skill data object
 * @returns {Object} Platform metadata
 */
function generateMetadata(skillData) {
  return {
    platform: name,
    format: 'AgentSkills',
    version: skillData?.version || '1.0.0',
    created: new Date().toISOString(),
    metadata: { openclaw: OPENCLAW_METADATA },
    compatibility: { minVersion: '1.0.0', testedVersions: ['1.0.0', '2.0.0', '2.2.0'] },
  };
}

/**
 * Validate skill structure for OpenClaw.
 * @param {string} skillContent - Skill content to validate
 * @returns {{ valid: boolean, errors: string[], warnings: string[] }}
 */
function validateSkill(skillContent) {
  const errors = [];
  const warnings = [];

  const frontmatterMatch = skillContent.match(/^---\n([\s\S]*?)\n---/);
  if (!frontmatterMatch) {
    errors.push('Missing YAML frontmatter');
  } else {
    const fm = frontmatterMatch[1];
    if (!fm.includes('name:')) errors.push('Missing required field: name');
    if (!fm.includes('version:')) errors.push('Missing required field: version');
    if (!fm.includes('description:')) errors.push('Missing required field: description');
    if (!fm.includes('metadata:') || !fm.includes('openclaw:')) {
      errors.push('Missing required metadata.openclaw section');
    }
  }

  REQUIRED_SECTIONS.forEach(section => {
    if (!hasSection(skillContent, section)) {
      errors.push(`Missing required section: ${section}`);
    }
  });

  RECOMMENDED_SECTIONS.forEach(section => {
    if (!hasSection(skillContent, section)) {
      warnings.push(`Missing recommended section: ${section}`);
    }
  });

  return { valid: errors.length === 0, errors, warnings };
}

/**
 * Convert an OpenCode-formatted skill to OpenClaw format.
 * @param {string} opencodeContent - OpenCode formatted skill
 * @returns {string} OpenClaw formatted skill
 */
function fromOpenCode(opencodeContent) {
  return formatSkill(opencodeContent);
}

module.exports = {
  name,
  template,
  formatSkill,
  getInstallPath,
  generateMetadata,
  validateSkill,
  fromOpenCode,
  // Export constants for testing
  REQUIRED_SECTIONS,
  RECOMMENDED_SECTIONS,
  OPENCLAW_METADATA,
};
