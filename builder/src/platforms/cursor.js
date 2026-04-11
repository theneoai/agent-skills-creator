/**
 * Cursor Platform Adapter
 * 
 * Adapts skills to the Cursor platform format.
 * Cursor uses a different format with ${...} placeholders instead of {{...}}.
 */

const path = require('path');
const os = require('os');

const name = 'cursor';

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
 * Format skill content for Cursor platform
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

  // Convert YAML frontmatter to JSON code block (Cursor doesn't support YAML frontmatter)
  const frontmatterMatch = formatted.match(/^---\n([\s\S]*?)\n---\n/);
  if (frontmatterMatch) {
    try {
      const yaml = require('js-yaml');
      const yamlData = yaml.load(frontmatterMatch[1]);
      const jsonContent = JSON.stringify(yamlData, null, 2);
      formatted = formatted.replace(frontmatterMatch[0], `\`\`\`json\n${jsonContent}\n\`\`\`\n\n`);
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
  const homeDir = os.homedir();
  // Cursor uses .cursor directory
  return path.join(homeDir, '.cursor', 'skills');
}

/**
 * Generate platform-specific metadata
 * @param {Object} skillData - Skill data object
 * @returns {Object} Platform metadata
 */
function generateMetadata(skillData) {
  return {
    platform: name,
    format: 'SKILL.md',
    version: skillData.version || '1.0.0',
    created: new Date().toISOString(),
    compatibility: {
      minVersion: '1.0.0',
      testedVersions: ['1.0.0']
    }
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
  template,
  formatSkill,
  getInstallPath,
  generateMetadata,
  validateSkill
};
