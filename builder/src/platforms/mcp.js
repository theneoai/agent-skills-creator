/**
 * MCP Platform Adapter
 *
 * Adapts skills to the Model Context Protocol (MCP) standard.
 * MCP is an emerging industry standard for AI tool/skill interoperability,
 * supported by Claude Desktop, Cursor, VS Code, and other MCP-compatible clients.
 *
 * Output format: JSON manifest (mcp-manifest.json) conforming to MCP schema v1.0.
 *
 * MCP Server Cards (2026 roadmap):
 *   Exposes a `.well-known/mcp-server-card.json` file at the install location so that
 *   MCP-compatible registries and discovery agents can passively enumerate available
 *   skills without prior knowledge of the server URL. generateServerCard() produces
 *   this companion document alongside the main manifest.
 *
 * @module builder/src/platforms/mcp
 * @version 3.1.1 - Added MCP Server Cards (generateServerCard) for passive registry discovery
 * @see https://modelcontextprotocol.io
 */

const path = require('path');
const os = require('os');
const config = require('../config');
const { parseFrontmatter } = require('../utils/frontmatter');
const { mcpCompatibility } = require('../utils/metadata-schema');

// Computed once from config so it stays in sync with the registry (no circular dep).
const SUPPORTED_PLATFORMS = Object.keys(config.PLATFORMS);

const name = 'mcp';

/** Output format identifier — used by index.js and build.js to determine file extension */
const outputFormat = 'JSON';

const template = {
  /**
   * MCP uses JSON manifests, not YAML frontmatter.
   * The manifest declares available tools/skills and their input schemas.
   */
  manifest: {
    schema_version: '1.0',
    name: '{{SKILL_NAME}}',
    description: '{{SKILL_DESCRIPTION}}',
    version: '{{VERSION}}',
    author: '{{AUTHOR}}',
    tools: [
      {
        name: 'invoke',
        description: 'Invoke the skill in a specific mode',
        input_schema: {
          type: 'object',
          properties: {
            mode: {
              type: 'string',
              enum: ['CREATE', 'LEAN', 'EVALUATE', 'OPTIMIZE', 'INSTALL'],
              description: 'Operating mode',
            },
            input: {
              type: 'string',
              description: 'Skill content or description to process',
            },
            options: {
              type: 'object',
              description: 'Mode-specific options',
              properties: {
                platform: {
                  type: 'string',
                  enum: SUPPORTED_PLATFORMS,
                  description: 'Target platform (used with INSTALL mode)',
                },
                strict: {
                  type: 'boolean',
                  description: 'Enable strict validation (throws on missing placeholders)',
                  default: false,
                },
              },
            },
          },
          required: ['mode', 'input'],
        },
      },
      {
        name: 'evaluate',
        description: 'Run the 4-phase 1000-point evaluation pipeline on a skill',
        input_schema: {
          type: 'object',
          properties: {
            skill_content: {
              type: 'string',
              description: 'Full skill file content to evaluate',
            },
            fast: {
              type: 'boolean',
              description: 'Run LEAN (fast) evaluation instead of full EVALUATE',
              default: false,
            },
          },
          required: ['skill_content'],
        },
      },
      {
        name: 'optimize',
        description: 'Run the 7-dimension 10-step OPTIMIZE loop on a skill (includes co-evolutionary VERIFY at Step 10)',
        input_schema: {
          type: 'object',
          properties: {
            skill_content: {
              type: 'string',
              description: 'Full skill file content to optimize',
            },
            max_rounds: {
              type: 'integer',
              description: 'Maximum optimization rounds (default: 20)',
              default: 20,
              minimum: 1,
              maximum: 50,
            },
          },
          required: ['skill_content'],
        },
      },
    ],
    resources: [
      {
        uri: 'skill://framework',
        name: 'Skill Framework',
        description: 'The core skill-writer framework specification',
        mime_type: 'text/markdown',
      },
    ],
  },
  sections: [],
  requiredFields: ['name', 'description', 'version'],
};

/**
 * Format skill content for MCP.
 * MCP uses a JSON manifest rather than Markdown, so this function
 * converts the skill's YAML frontmatter + content into an MCP manifest.
 *
 * @param {string} skillContent - Raw skill content (Markdown with YAML frontmatter)
 * @returns {string} JSON-formatted MCP manifest
 */
function formatSkill(skillContent) {
  if (!skillContent || typeof skillContent !== 'string') {
    throw new Error('Invalid skill content provided');
  }

  // Extract YAML frontmatter if present
  let skillName = 'unnamed-skill';
  let skillDescription = '';
  let skillVersion = '1.0.0';
  let skillAuthor = '';
  let skillTier = null;
  const skillTriggers = { en: [], zh: [] };

  // Parse YAML frontmatter using shared utility (handles optional trailing newline —
  // fixes silent failure when skill files end with `---` without trailing newline).
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
    if (fm.triggers?.en && Array.isArray(fm.triggers.en)) skillTriggers.en = fm.triggers.en;
    if (fm.triggers?.zh && Array.isArray(fm.triggers.zh)) skillTriggers.zh = fm.triggers.zh;
  }

  // Fallback: extract metadata from inline body patterns when there is no
  // YAML frontmatter (e.g. MCP default template output or Cursor-style content).
  if (!skillName || skillName === 'unnamed-skill') {
    const inlineName = skillContent.match(/^#\s+(.+)$/m);
    if (inlineName) skillName = inlineName[1].trim().toLowerCase().replace(/\s+/g, '-');
  }
  if (!skillDescription) {
    // Look for a blockquote description (> **Description**: ...) or first prose paragraph
    const blockDesc = skillContent.match(/^>\s+\*\*Description\*\*:\s*(.+)$/m) ||
                      skillContent.match(/^>\s+(.+)$/m);
    if (blockDesc) {
      skillDescription = blockDesc[1].replace(/\*\*/g, '').trim();
    } else {
      // Use the first non-empty, non-heading, non-blockquote paragraph
      const firstPara = skillContent
        .split('\n')
        .filter(l => l.trim() && !l.startsWith('#') && !l.startsWith('>') && !l.startsWith('-') && !l.startsWith('`'))
        .find(l => l.trim().length > 10);
      if (firstPara) skillDescription = firstPara.trim().slice(0, 200);
    }
  }

  // Build MCP manifest with extracted metadata
  const manifest = {
    schema_version: '1.0',
    name: skillName,
    description: skillDescription,
    version: skillVersion,
    author: skillAuthor,
    generated_by: 'skill-writer-builder',
    // v3.1.0: include skill classification fields
    ...(skillTier && { skill_tier: skillTier }),
    ...(skillTriggers.en.length > 0 && { triggers: skillTriggers }),
    tools: template.manifest.tools,
    resources: template.manifest.resources,
    // Embed a compact summary of available modes
    capabilities: {
      modes: ['CREATE', 'LEAN', 'EVALUATE', 'OPTIMIZE', 'INSTALL'],
      platforms: SUPPORTED_PLATFORMS,
      self_evolution: true,
      // v3.1.0: security baseline now includes OWASP Agentic Skills Top 10 checks
      security_baseline: 'CWE + OWASP-ASI01-ASI10',
    },
  };

  return JSON.stringify(manifest, null, 2);
}

/**
 * Get the installation path for MCP skills.
 * MCP server manifests are typically stored in ~/.mcp/servers/
 * @returns {string} Installation path
 */
function getInstallPath() {
  return path.join(os.homedir(), '.mcp', 'servers');
}

/**
 * Generate MCP-specific metadata
 * @param {Object} skillData - Skill data object
 * @returns {Object} Platform metadata
 */
function generateMetadata(skillData) {
  return {
    platform: name,
    format: 'MCP JSON Manifest',
    outputFormat,
    schema_version: '1.0',
    version: skillData?.version || '1.0.0',
    created: new Date().toISOString(),
    compatibility: mcpCompatibility(),
  };
}

/**
 * Validate skill structure for MCP output.
 * Since MCP output is JSON, validation checks JSON structure.
 *
 * @param {string} skillContent - Skill content (may be raw Markdown or JSON manifest)
 * @returns {Object} Validation result
 */
function validateSkill(skillContent) {
  const errors = [];
  const warnings = [];

  // If the content looks like JSON (MCP manifest), validate its structure
  const trimmed = skillContent.trim();
  if (trimmed.startsWith('{')) {
    try {
      const manifest = JSON.parse(trimmed);

      if (!manifest.schema_version) errors.push('Missing field: schema_version');
      if (!manifest.name) errors.push('Missing field: name');
      if (!manifest.description) errors.push('Missing field: description');
      if (!manifest.version) errors.push('Missing field: version');
      if (!Array.isArray(manifest.tools) || manifest.tools.length === 0) {
        errors.push('MCP manifest must declare at least one tool');
      }
      if (!manifest.capabilities) {
        warnings.push('Missing capabilities block (recommended for discoverability)');
      }
    } catch {
      errors.push('MCP manifest is not valid JSON');
    }
    return { valid: errors.length === 0, errors, warnings };
  }

  // If raw Markdown: check it has enough content to convert
  if (skillContent.length < 100) {
    errors.push('Skill content too short to generate a valid MCP manifest');
  }
  if (!skillContent.includes('name:') && !skillContent.includes('description:')) {
    warnings.push('No name or description found; MCP manifest will use defaults');
  }

  return { valid: errors.length === 0, errors, warnings };
}

/**
 * Generate an MCP Server Card for passive registry discovery.
 *
 * Server Cards are exposed at `.well-known/mcp-server-card.json` (relative to the
 * MCP server install directory) so MCP registries and discovery agents can enumerate
 * available skills without prior knowledge of the server URL.
 *
 * Spec: MCP 2026 Roadmap — "MCP Server Cards" feature
 * Install path: ~/.mcp/servers/skill-writer/.well-known/mcp-server-card.json
 *
 * @param {Object} manifest - Parsed MCP manifest object (output of formatSkill, then JSON.parse)
 * @returns {string} JSON-formatted Server Card
 */
function generateServerCard(manifest) {
  if (!manifest || typeof manifest !== 'object') {
    throw new Error('generateServerCard requires a parsed manifest object');
  }

  const serverCard = {
    // Server Card schema version (MCP 2026 draft)
    card_schema_version: '2026-draft',

    // Identity fields — mirror the manifest
    name: manifest.name || 'unnamed-skill',
    description: manifest.description || '',
    version: manifest.version || '1.0.0',
    author: manifest.author || '',

    // Discovery metadata
    provider: {
      name: manifest.author || 'theneoai',
      url: 'https://github.com/theneoai/skill-writer',
    },

    // Capability summary used by registries for search/filter
    capabilities: {
      modes: manifest.capabilities?.modes || ['CREATE', 'LEAN', 'EVALUATE', 'OPTIMIZE', 'INSTALL'],
      platforms: manifest.capabilities?.platforms || SUPPORTED_PLATFORMS,
      self_evolution: manifest.capabilities?.self_evolution ?? true,
      security_baseline: manifest.capabilities?.security_baseline || 'CWE + OWASP-ASI01-ASI10',
    },

    // Tool summary (names + descriptions only — omit full input schemas for compactness)
    tools: (manifest.tools || []).map(t => ({
      name: t.name,
      description: t.description,
    })),

    // Skill classification (v3.1.0 fields)
    ...(manifest.skill_tier && { skill_tier: manifest.skill_tier }),
    ...(manifest.triggers && { triggers: manifest.triggers }),

    // Card metadata
    generated_at: new Date().toISOString(),
    generated_by: 'skill-writer-builder',
  };

  return JSON.stringify(serverCard, null, 2);
}

/**
 * Get the .well-known Server Card install path.
 * Returned path is the full file path where the card should be written.
 *
 * @param {string} skillName - Skill directory name (default: 'skill-writer')
 * @returns {string} Full path to the server card file
 */
function getServerCardPath(skillName = 'skill-writer') {
  return path.join(os.homedir(), '.mcp', 'servers', skillName, '.well-known', 'mcp-server-card.json');
}

module.exports = {
  name,
  outputFormat,
  template,
  formatSkill,
  getInstallPath,
  generateMetadata,
  validateSkill,
  generateServerCard,
  getServerCardPath,
};
