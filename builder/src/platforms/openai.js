/**
 * OpenAI Platform Adapter
 *
 * Adapts skills to the OpenAI platform format.
 * OpenAI uses JSON format for instructions rather than Markdown.
 *
 * outputFormat: 'JSON' — build pipeline writes .json extension for this platform.
 *
 * @module builder/src/platforms/openai
 * @version 3.1.0 - Use shared frontmatter utility and metadata-schema
 */

const path = require('path');
const os = require('os');
const yaml = require('js-yaml');
const { parseFrontmatter } = require('../utils/frontmatter');
const { markdownCompatibility } = require('../utils/metadata-schema');

const name = 'openai';

/** Output format identifier — used by index.js and build.js to determine file extension */
const outputFormat = 'JSON';

const template = {
  // OpenAI uses JSON format
  format: 'json',
  requiredFields: [
    'name',
    'version',
    'description',
    'instructions'
  ]
};

/**
 * Format skill content for OpenAI platform
 * @param {string} skillContent - Raw skill content
 * @returns {string} Formatted skill content (JSON)
 */
function formatSkill(skillContent) {
  if (!skillContent || typeof skillContent !== 'string') {
    throw new Error('Invalid skill content provided');
  }

  // Extract YAML frontmatter using shared utility.
  // Uses canonical FRONTMATTER_REGEX which handles optional trailing newline —
  // fixes silent failure when skill files end with `---` without trailing newline.
  const { frontmatterData, body, raw } = parseFrontmatter(skillContent);
  let metadata = {};
  let content = skillContent;

  if (raw) {
    if (!frontmatterData || typeof frontmatterData !== 'object') {
      throw new Error('Invalid YAML frontmatter: did not parse to an object');
    }
    metadata = frontmatterData;
    content = body;
  }

  // Build OpenAI format
  const openaiSkill = {
    name: metadata.name || 'unnamed-skill',
    version: metadata.version || '1.0.0',
    description: metadata.description || '',
    instructions: content.trim(),
    metadata: {
      platform: name,
      created: new Date().toISOString(),
      ...metadata
    }
  };

  return JSON.stringify(openaiSkill, null, 2);
}

/**
 * Get the installation path for OpenAI skills
 * @returns {string} Installation path
 */
function getInstallPath() {
  const homeDir = os.homedir();
  // OpenAI doesn't have a standard local skill directory
  return path.join(homeDir, '.openai', 'skills');
}

/**
 * Generate platform-specific metadata
 * @param {Object} skillData - Skill data object
 * @returns {Object} Platform metadata
 */
function generateMetadata(skillData) {
  return {
    platform: name,
    format: 'JSON',
    outputFormat,
    version: skillData?.version || '1.0.0',
    created: new Date().toISOString(),
    compatibility: markdownCompatibility('2.2.0'),
  };
}

/**
 * Validate skill structure for OpenAI
 * @param {string} skillContent - Skill content to validate (JSON)
 * @returns {Object} Validation result
 */
function validateSkill(skillContent) {
  const errors = [];
  const warnings = [];

  try {
    const data = JSON.parse(skillContent);
    
    // Check required fields
    template.requiredFields.forEach(field => {
      if (!data[field]) {
        errors.push(`Missing required field: ${field}`);
      }
    });
  } catch (error) {
    errors.push(`Invalid JSON: ${error.message}`);
  }

  return {
    valid: errors.length === 0,
    errors,
    warnings
  };
}

module.exports = {
  name,
  outputFormat,
  template,
  formatSkill,
  getInstallPath,
  generateMetadata,
  validateSkill
};
