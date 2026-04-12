/**
 * A2A Platform Adapter
 *
 * Adapts skills to the Agent-to-Agent (A2A) protocol standard.
 * A2A was created by Google (April 2025) and donated to the Linux Foundation's
 * Agentic AI Foundation (AAIF) in June 2025. It standardises agent-to-agent
 * discovery, communication, and task delegation across frameworks.
 *
 * Output format: JSON Agent Card conforming to A2A Agent Card spec v1.0.
 * The Agent Card is the canonical A2A discovery document — it describes what
 * an agent can do, how to reach it, and what input/output modalities it supports.
 *
 * Install path: ~/.a2a/agents/skill-writer/agent-card.json
 *
 * Spec references:
 *   - https://github.com/google-a2a/A2A (Agent Card schema)
 *   - Linux Foundation AAIF: https://www.linuxfoundation.org/press/linux-foundation-announces-the-formation-of-the-agentic-ai-foundation-aaif
 *
 * @module builder/src/platforms/a2a
 * @version 3.1.1 - Initial A2A platform adapter (Agent Card JSON output)
 */

const path = require('path');
const os = require('os');
const { parseFrontmatter } = require('../utils/frontmatter');
const { a2aCompatibility } = require('../utils/metadata-schema');

const name = 'a2a';

/** Output format — A2A uses JSON Agent Cards, not Markdown */
const outputFormat = 'JSON';

/**
 * A2A Agent Card template structure.
 * Fields follow the A2A Agent Card spec v1.0 (AAIF, June 2025).
 */
const template = {
  format: 'json',
  requiredFields: ['name', 'description', 'version', 'skills'],
};

/**
 * Format skill content as an A2A Agent Card.
 *
 * The Agent Card exposes the skill as an A2A-compatible agent with:
 *   - Identity fields (name, description, version, provider)
 *   - Capabilities (streaming, pushNotifications, stateTransitionHistory)
 *   - Skills list (each skill maps to one Skill Writer mode)
 *   - Input/output mode declarations
 *
 * @param {string} skillContent - Raw skill content (Markdown with YAML frontmatter)
 * @returns {string} JSON-formatted A2A Agent Card
 */
function formatSkill(skillContent) {
  if (!skillContent || typeof skillContent !== 'string') {
    throw new Error('Invalid skill content provided');
  }

  // Extract YAML frontmatter
  let skillName = 'skill-writer';
  let skillDescription = '';
  let skillVersion = '1.0.0';
  let skillAuthor = '';
  let skillTier = null;
  const triggers = { en: [], zh: [] };

  const { frontmatterData } = parseFrontmatter(skillContent);
  if (frontmatterData) {
    const fm = frontmatterData;
    if (fm.name) skillName = String(fm.name);
    if (fm.description) skillDescription = String(fm.description);
    if (fm.version) skillVersion = String(fm.version);
    if (fm.author) {
      skillAuthor = typeof fm.author === 'string'
        ? fm.author
        : (fm.author?.name || String(fm.author));
    }
    if (fm.skill_tier) skillTier = String(fm.skill_tier);
    if (fm.triggers?.en && Array.isArray(fm.triggers.en)) triggers.en = fm.triggers.en;
    if (fm.triggers?.zh && Array.isArray(fm.triggers.zh)) triggers.zh = fm.triggers.zh;
  }

  // Build the A2A Agent Card
  const agentCard = {
    // A2A Agent Card schema version
    schema_version: 'a2a/1.0',

    // ── Identity ──────────────────────────────────────────────────────────────
    name: skillName,
    description: skillDescription,
    version: skillVersion,

    // Agent URL — placeholder; replace with actual deployment endpoint
    url: `https://agents.example.com/${skillName}`,

    provider: {
      organization: skillAuthor || 'theneoai',
      url: 'https://github.com/theneoai/skill-writer',
    },

    // ── Capabilities ──────────────────────────────────────────────────────────
    // Declares which A2A protocol features this agent supports
    capabilities: {
      // Agent can stream partial responses (token-by-token)
      streaming: true,
      // Agent can push notifications to calling agents on long tasks
      pushNotifications: false,
      // Agent exposes its internal state transitions (useful for orchestrators)
      stateTransitionHistory: true,
    },

    // ── Input / Output Modes ──────────────────────────────────────────────────
    // Declares what formats this agent accepts and produces
    defaultInputModes: ['text/plain', 'application/json'],
    defaultOutputModes: ['text/plain', 'application/json', 'text/markdown'],

    // ── Skills (A2A skill list) ───────────────────────────────────────────────
    // Each A2A skill maps to one Skill Writer operating mode.
    // A2A skill IDs follow the format: <agent-name>/<skill-id>
    skills: [
      {
        id: `${skillName}/create`,
        name: 'CREATE',
        description: 'Generate a new skill from templates using 8-question elicitation. Produces a LEAN-scored skill file.',
        tags: ['create', 'generate', 'template', 'skill-authoring'],
        examples: [
          'Create a skill that summarises git diffs',
          'Build an API integration skill for GitHub',
          '创建一个代码审查技能',
        ],
        inputModes: ['text/plain'],
        outputModes: ['text/markdown', 'application/json'],
      },
      {
        id: `${skillName}/lean`,
        name: 'LEAN',
        description: 'Fast quality check (500-point heuristic, <5 s). Returns LEAN_CERT when score ≥ 350.',
        tags: ['evaluate', 'quality', 'fast', 'lean'],
        examples: [
          '/lean <skill content>',
          '快评 <技能内容>',
        ],
        inputModes: ['text/plain', 'text/markdown'],
        outputModes: ['application/json'],
      },
      {
        id: `${skillName}/evaluate`,
        name: 'EVALUATE',
        description: 'Full 4-phase 1000-point evaluation pipeline with OWASP Agentic Top 10 security scan.',
        tags: ['evaluate', 'certification', 'security', 'owasp'],
        examples: [
          '/eval <skill content>',
          '评测 <技能内容>',
        ],
        inputModes: ['text/plain', 'text/markdown'],
        outputModes: ['application/json', 'text/markdown'],
      },
      {
        id: `${skillName}/optimize`,
        name: 'OPTIMIZE',
        description: '7-dimension 10-step optimization loop with co-evolutionary VERIFY. Iterates until convergence or 20 rounds.',
        tags: ['optimize', 'improve', 'convergence'],
        examples: [
          '/opt <skill content> <eval report>',
          '优化 <技能> <评测报告>',
        ],
        inputModes: ['text/plain', 'text/markdown'],
        outputModes: ['text/markdown'],
      },
      {
        id: `${skillName}/install`,
        name: 'INSTALL',
        description: 'Deploy a skill to 8 platforms (Claude, OpenCode, OpenClaw, Cursor, Gemini, OpenAI, MCP, A2A).',
        tags: ['install', 'deploy', 'platform'],
        examples: [
          '/install claude',
          '/install --all',
          '安装 cursor',
        ],
        inputModes: ['text/plain'],
        outputModes: ['text/plain'],
      },
      {
        id: `${skillName}/collect`,
        name: 'COLLECT',
        description: 'Record a session artifact for collective skill evolution via SkillClaw/SkillRL pipeline.',
        tags: ['collect', 'evolution', 'session-data'],
        examples: [
          '/collect',
          '采集',
        ],
        inputModes: ['text/plain'],
        outputModes: ['application/json'],
      },
    ],

    // ── Skill Classification (v3.1.0 fields) ─────────────────────────────────
    ...(skillTier && { skill_tier: skillTier }),
    ...(triggers.en.length > 0 && { trigger_phrases: triggers }),

    // ── Security ──────────────────────────────────────────────────────────────
    security: {
      standard: 'CWE + OWASP-ASI01-ASI10',
      scan_on_delivery: true,
      abort_on: ['P0_CWE', 'ASI01'],
    },

    // ── Card Metadata ─────────────────────────────────────────────────────────
    generated_at: new Date().toISOString(),
    generated_by: 'skill-writer-builder',
  };

  return JSON.stringify(agentCard, null, 2);
}

/**
 * Get the installation path for A2A Agent Cards.
 * A2A agents are stored in ~/.a2a/agents/<skill-name>/
 * @returns {string} Installation directory path
 */
function getInstallPath() {
  return path.join(os.homedir(), '.a2a', 'agents');
}

/**
 * Generate A2A-specific metadata.
 * @param {Object} skillData - Skill data object
 * @returns {Object} Platform metadata
 */
function generateMetadata(skillData) {
  return {
    platform: name,
    format: 'A2A Agent Card JSON',
    outputFormat,
    schema_version: 'a2a/1.0',
    version: skillData?.version || '1.0.0',
    created: new Date().toISOString(),
    compatibility: a2aCompatibility(),
    spec: 'https://github.com/google-a2a/A2A',
    governance: 'Linux Foundation AAIF (June 2025)',
  };
}

/**
 * Validate skill structure for A2A Agent Card output.
 *
 * @param {string} skillContent - Skill content (raw Markdown or JSON Agent Card)
 * @returns {Object} Validation result {valid, errors, warnings}
 */
function validateSkill(skillContent) {
  const errors = [];
  const warnings = [];

  const trimmed = skillContent.trim();

  // If content looks like a JSON Agent Card, validate its structure
  if (trimmed.startsWith('{')) {
    let card;
    try {
      card = JSON.parse(trimmed);
    } catch (error) {
      errors.push(`A2A Agent Card is not valid JSON — ${error.message}`);
      return { valid: false, errors, warnings };
    }

    if (!card.schema_version || !card.schema_version.startsWith('a2a/')) {
      errors.push('Missing or invalid schema_version (expected "a2a/1.0")');
    }
    if (!card.name) errors.push('Missing required field: name');
    if (!card.description) errors.push('Missing required field: description');
    if (!card.version) errors.push('Missing required field: version');
    if (!Array.isArray(card.skills) || card.skills.length === 0) {
      errors.push('A2A Agent Card must declare at least one skill');
    }
    if (!card.url) {
      warnings.push('Missing agent URL — replace placeholder before deployment');
    }
    if (!card.capabilities) {
      warnings.push('Missing capabilities block (streaming, pushNotifications, stateTransitionHistory)');
    }

    return { valid: errors.length === 0, errors, warnings };
  }

  // Raw Markdown: check it has enough content to convert
  if (skillContent.length < 100) {
    errors.push('Skill content too short to generate a valid A2A Agent Card');
  }
  if (!skillContent.includes('name:') && !skillContent.includes('description:')) {
    warnings.push('No name or description found; Agent Card will use defaults');
  }

  return { valid: errors.length === 0, errors, warnings };
}

module.exports = {
  name,
  outputFormat,
  template,
  formatSkill,
  getInstallPath,
  generateMetadata,
  validateSkill,
};
