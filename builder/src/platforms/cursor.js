/**
 * Cursor Platform Adapter
 *
 * Adapts skills to the Cursor platform format.
 * Cursor uses ${...} placeholders (instead of {{...}}) and JSON metadata
 * blocks instead of YAML frontmatter.
 *
 * outputFormat: 'HYBRID' — YAML frontmatter is converted to a JSON code block;
 * the body content remains Markdown.
 *
 * @module builder/src/platforms/cursor
 * @version 3.1.0 - Use shared frontmatter utility; fix hardcoded testedVersions ['1.0.0']
 */

const path = require('path');
const os = require('os');
const { hasFrontmatter, parseFrontmatter } = require('../utils/frontmatter');
const { markdownCompatibility } = require('../utils/metadata-schema');

const name = 'cursor';

/** Output format identifier — used by index.js and build.js to determine file extension */
const outputFormat = 'HYBRID';

const template = {
  // Cursor doesn't use YAML frontmatter, uses JSON metadata instead
  metadata: '```json\n{\n  "name": "{{name}}",\n  "version": "{{version}}",\n  "description": "{{description}}",\n  "type": "skill"\n}\n```',
  sections: [
    '## Overview',
    '## Instructions',
    '## Examples'
  ],
  requiredFields: [
    'name',
    'version',
    'description'
  ]
};

/**
 * Format skill content for Cursor platform.
 * 1. Convert {{...}} → ${...} placeholders
 * 2. Convert YAML frontmatter → JSON code block
 *
 * @param {string} skillContent - Raw skill content
 * @returns {string} Formatted skill content
 */
function formatSkill(skillContent) {
  if (!skillContent || typeof skillContent !== 'string') {
    throw new Error('Invalid skill content provided');
  }

  let formatted = skillContent;

  // Convert {{...}} placeholders to ${...} format (extended: supports hyphens and dots)
  formatted = formatted.replace(/\{\{([\w.-]+)\}\}/g, '${$1}');

  // Convert YAML frontmatter to JSON code block using shared utility.
  // Uses canonical FRONTMATTER_REGEX which handles optional trailing newline —
  // fixes silent failure when skill files end with `---` without trailing newline.
  const { frontmatterData, body, raw } = parseFrontmatter(formatted);
  if (raw && frontmatterData) {
    try {
      const jsonContent = JSON.stringify(frontmatterData, null, 2);
      formatted = `\`\`\`json\n${jsonContent}\n\`\`\`\n\n${body}`;
    } catch (error) {
      console.warn('Failed to convert frontmatter to JSON:', error.message);
    }
  }

  return formatted.trim();
}

/**
 * Get the installation path for Cursor skills
 * @returns {string} Installation path
 */
function getInstallPath() {
  return path.join(os.homedir(), '.cursor', 'skills');
}

/**
 * Generate platform-specific metadata.
 * Fixed: no longer hardcodes testedVersions to ['1.0.0'].
 *
 * @param {Object} skillData - Skill data object
 * @returns {Object} Platform metadata
 */
function generateMetadata(skillData) {
  return {
    platform: name,
    format: 'SKILL.md',
    outputFormat,
    version: skillData?.version || '1.0.0',
    created: new Date().toISOString(),
    // markdownCompatibility() reads version from package.json at call-time (not hardcoded)
    compatibility: markdownCompatibility('1.0.0'),
  };
}

/**
 * Validate skill structure for Cursor
 * @param {string} skillContent - Skill content to validate
 * @returns {Object} Validation result
 */
function validateSkill(skillContent) {
  const errors = [];
  const warnings = [];

  // Check for ${...} placeholders
  if (!skillContent.includes('${')) {
    warnings.push('No ${...} placeholders found - may need format conversion');
  }

  // Check for JSON metadata block
  if (!skillContent.match(/^```json\n/)) {
    warnings.push('No JSON metadata block found - Cursor prefers JSON over YAML frontmatter');
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
