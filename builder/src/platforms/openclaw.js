/**
 * OpenClaw Platform Adapter
 * 
 * Adapts skills to the OpenClaw platform format.
 * OpenClaw uses AgentSkills format with metadata.openclaw section.
 */

const path = require('path');
const os = require('os');

const name = 'openclaw';

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
    '## §11 UTE Injection'
  ],
  requiredFields: [
    'name',
    'version',
    'description',
    'metadata.openclaw'
  ]
};

/**
 * Format skill content for OpenClaw platform
 * @param {string} skillContent - Raw skill content
 * @returns {string} Formatted skill content for OpenClaw
 */
function formatSkill(skillContent) {
  if (!skillContent || typeof skillContent !== 'string') {
    throw new Error('Invalid skill content provided');
  }

  // Parse existing frontmatter
  const frontmatterMatch = skillContent.match(/^---\n([\s\S]*?)\n---/);
  if (!frontmatterMatch) {
    throw new Error('Skill content missing required YAML frontmatter');
  }

  let formattedContent = skillContent;
  const frontmatter = frontmatterMatch[1];

  // Add metadata.openclaw section if not present
  if (!frontmatter.includes('metadata:') || !frontmatter.includes('openclaw:')) {
    const openclawMetadata = `
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
      checkpointInterval: 10`;

    // Insert metadata before closing frontmatter
    formattedContent = skillContent.replace(
      /^---\n([\s\S]*?)\n---/,
      `---\n$1${openclawMetadata}\n---`
    );
  }

  // Ensure LoongFlow orchestration section is present
  if (!formattedContent.includes('## §4 LoongFlow Orchestration')) {
    const loongFlowSection = `

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
│  Cross-validate results against requirements              │
│  Update evolution memory                                 │
│  Produce consensus matrix                                │
│  Route: CERTIFIED | TEMP_CERT | HUMAN_REVIEW | ABORT     │
└──────────────────────────────────────────────────────────┘
\`\`\``;

    // Insert after Mode Router section or at appropriate location
    const modeRouterMatch = formattedContent.match(/(## §2 Mode Router[\s\S]*?)(\n## §|$)/);
    if (modeRouterMatch) {
      formattedContent = formattedContent.replace(
        modeRouterMatch[1],
        modeRouterMatch[1] + loongFlowSection
      );
    }
  }

  // Ensure Self-Review Protocol section is present
  if (!formattedContent.includes('## §9 Self-Review Protocol')) {
    const reviewSection = `

## §9 Self-Review Protocol

| Role | Responsibility |
|------|---------------|
| Pass 1 — Generate | Produce initial draft / score / fix proposal |
| Pass 2 — Review | Security + quality audit; severity-tagged issue list (ERROR/WARNING/INFO) |
| Pass 3 — Reconcile | Address all ERRORs, reconcile scores, produce final artifact |

Timeouts: 30 s per pass, 60 s per phase, 180 s total (6 turns max).
Consensus: CLEAR → proceed; REVISED → proceed with notes;
UNRESOLVED → HUMAN_REVIEW.`;

    // Insert before Usage Examples
    const usageExamplesMatch = formattedContent.match(/(## §8 Usage Examples)/);
    if (usageExamplesMatch) {
      formattedContent = formattedContent.replace(
        usageExamplesMatch[1],
        reviewSection + '\n\n' + usageExamplesMatch[1]
      );
    }
  }

  // Ensure UTE Injection section is present
  if (!formattedContent.includes('## §11 UTE Injection')) {
    const uteSection = `

## §11 UTE Injection

**Use-to-Evolve (UTE)** enables self-improving capabilities through actual usage.

### UTE Capabilities

| Capability | Mechanism |
|-----------|-----------|
| Per-call usage recording | Post-Invocation Hook appended to skill context |
| Implicit feedback detection | Pattern match on user follow-up |
| Trigger candidate collection | Rephrasing signals logged; count≥3 → micro-patch candidate |
| Lightweight check every 10 calls | Rolling 20-call success rate + trigger accuracy check |
| Full metric recompute every 50 calls | F1 / MRR / trigger_accuracy from usage log |
| Tier drift detection every 100 calls | Estimated LEAN vs certified baseline |
| Autonomous micro-patching | Keyword additions staged + LEAN-validated before apply |

### UTE Metadata

\`\`\`yaml
use_to_evolve:
  enabled: true
  certified_lean_score: 0
  last_ute_check: null
  evolution_queue: .skill-audit/evolution-queue.jsonl
\`\`\``;

    formattedContent += uteSection;
  }

  return formattedContent.trim();
}

/**
 * Get the installation path for OpenClaw skills
 * @returns {string} Installation path
 */
function getInstallPath() {
  const homeDir = os.homedir();
  
  // OpenClaw uses .openclaw directory for skills
  const openclawDir = path.join(homeDir, '.openclaw', 'skills');
  
  return openclawDir;
}

/**
 * Generate platform-specific metadata for OpenClaw
 * @param {Object} skillData - Skill data object
 * @returns {Object} Platform metadata
 */
function generateMetadata(skillData) {
  return {
    platform: name,
    format: 'AgentSkills',
    version: skillData.version || '1.0.0',
    created: new Date().toISOString(),
    metadata: {
      openclaw: {
        format: 'agentskills',
        compatibility: ['1.0', '2.0'],
        features: [
          'self-review',
          'self-evolution'
        ],
        runtime: {
          timeout: 30000,
          maxRetries: 3,
          checkpointInterval: 10
        }
      }
    },
    compatibility: {
      minVersion: '1.0.0',
      testedVersions: ['1.0.0', '2.0.0']
    }
  };
}

/**
 * Validate skill structure for OpenClaw
 * @param {string} skillContent - Skill content to validate
 * @returns {Object} Validation result
 */
function validateSkill(skillContent) {
  const errors = [];
  const warnings = [];

  // Check YAML frontmatter
  const frontmatterMatch = skillContent.match(/^---\n([\s\S]*?)\n---/);
  if (!frontmatterMatch) {
    errors.push('Missing YAML frontmatter');
  } else {
    const frontmatter = frontmatterMatch[1];
    
    // Check required fields
    if (!frontmatter.includes('name:')) {
      errors.push('Missing required field: name');
    }
    if (!frontmatter.includes('version:')) {
      errors.push('Missing required field: version');
    }
    if (!frontmatter.includes('description:')) {
      errors.push('Missing required field: description');
    }
    
    // Check for metadata.openclaw
    if (!frontmatter.includes('metadata:') || !frontmatter.includes('openclaw:')) {
      errors.push('Missing required metadata.openclaw section');
    }
  }

  // Check for required sections
  const requiredSections = [
    '## §1 Identity',
    '## §4 LoongFlow Orchestration',
    '## §9 Self-Review Protocol'
  ];
  
  requiredSections.forEach(section => {
    const sectionPattern = new RegExp(`^${section.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}`, 'm');
    if (!sectionPattern.test(skillContent)) {
      errors.push(`Missing required section: ${section}`);
    }
  });

  // Check for optional but recommended sections
  const recommendedSections = [
    '## §11 UTE Injection'
  ];
  
  recommendedSections.forEach(section => {
    const sectionPattern = new RegExp(`^${section.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}`, 'm');
    if (!sectionPattern.test(skillContent)) {
      warnings.push(`Missing recommended section: ${section}`);
    }
  });

  return {
    valid: errors.length === 0,
    errors,
    warnings
  };
}

/**
 * Convert OpenCode format to OpenClaw format
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
  fromOpenCode
};
