/**
 * Platform Adapter Base Class
 *
 * Shared base class for Markdown-based platform adapters (Claude, Gemini, OpenCode, OpenClaw).
 * Eliminates code duplication between adapters.
 *
 * Uses the shared frontmatter utility (utils/frontmatter.js) to ensure consistent
 * YAML frontmatter parsing across all adapters — replaces the duplicate ad-hoc regexes
 * that previously lived in each adapter file.
 *
 * @module builder/src/platforms/MarkdownAdapter
 * @version 3.1.0 - Use shared frontmatter utility; add outputFormat property
 */

const path = require('path');
const os = require('os');
const { hasFrontmatter } = require('../utils/frontmatter');
const { markdownCompatibility, getBuilderVersion } = require('../utils/metadata-schema');

/**
 * Base class for Markdown-based platform adapters
 */
class MarkdownAdapter {
  /**
   * @param {Object} options - Adapter configuration
   * @param {string} options.name          - Platform name
   * @param {string} options.installDir    - Installation directory name (e.g. '.claude')
   * @param {string} [options.outputFormat='MARKDOWN'] - 'MARKDOWN' | 'JSON' | 'HYBRID'
   * @param {string[]} [options.sections]  - Default sections for the platform
   * @param {string[]} [options.requiredFields] - Required frontmatter fields
   */
  constructor(options) {
    this.name = options.name;
    this.installDir = options.installDir;
    /** Output format used by build pipeline to choose file extension and adapter pathway */
    this.outputFormat = options.outputFormat || 'MARKDOWN';
    this.sections = options.sections || [
      '## Overview',
      '## Usage',
      '## Examples',
    ];
    this.requiredFields = options.requiredFields || ['name', 'version', 'description'];
  }

  /**
   * Get the template configuration
   * @returns {Object} Template configuration
   */
  get template() {
    return {
      frontmatter: `---
name: {{name}}
version: {{version}}
description: {{description}}
type: skill
author: {{author}}
tags: {{tags}}
---`,
      sections: this.sections,
      requiredFields: this.requiredFields,
    };
  }

  /**
   * Format skill content for the platform.
   * Uses shared hasFrontmatter() — canonical regex handles optional trailing newline.
   *
   * @param {string} skillContent - Raw skill content
   * @returns {string} Formatted skill content
   */
  formatSkill(skillContent) {
    if (!skillContent || typeof skillContent !== 'string') {
      throw new Error('Invalid skill content provided');
    }

    // Validate YAML frontmatter presence using shared utility
    if (!hasFrontmatter(skillContent)) {
      throw new Error('Skill content missing required YAML frontmatter');
    }

    // Platform-specific formatting adjustments
    let formatted = skillContent;

    // Ensure proper header hierarchy (single H1 preferred)
    const h1Matches = formatted.match(/^#\s+.+$/gm);
    if (h1Matches && h1Matches.length > 1) {
      let count = 0;
      formatted = formatted.replace(/^#\s+(.+)$/gm, (match, title) => {
        count++;
        return count === 1 ? match : `## ${title}`;
      });
    }

    return formatted.trim();
  }

  /**
   * Get the installation path for skills
   * @returns {string} Installation path
   */
  getInstallPath() {
    const homeDir = os.homedir();
    return path.join(homeDir, this.installDir, 'skills');
  }

  /**
   * Generate platform-specific metadata.
   * Uses metadata-schema.js for the compatibility block — ensures consistent
   * structure and reads the builder version dynamically (not hardcoded).
   *
   * @param {Object} skillData - Skill data object
   * @returns {Object} Platform metadata
   */
  generateMetadata(skillData) {
    return {
      platform: this.name,
      format: 'SKILL.md',
      outputFormat: this.outputFormat,
      version: skillData?.version || '1.0.0',
      created: new Date().toISOString(),
      compatibility: markdownCompatibility('2.2.0'),
    };
  }

  /**
   * Validate skill structure.
   * Uses shared hasFrontmatter() — canonical regex handles optional trailing newline.
   *
   * @param {string} skillContent - Skill content to validate
   * @returns {Object} Validation result
   */
  validateSkill(skillContent) {
    const errors = [];
    const warnings = [];

    // Check YAML frontmatter using shared utility
    if (!hasFrontmatter(skillContent)) {
      errors.push('Missing YAML frontmatter');
    }

    // Check required fields
    for (const field of this.requiredFields) {
      const fieldPattern = new RegExp(`^${field}:`, 'm');
      if (!fieldPattern.test(skillContent)) {
        errors.push(`Missing required field: ${field}`);
      }
    }

    // Check for sections
    for (const section of this.sections) {
      const sectionName = section.replace(/^##\s+/, '');
      const sectionPattern = new RegExp(`^##\\s+${sectionName}$`, 'm');
      if (!sectionPattern.test(skillContent)) {
        warnings.push(`Missing recommended section: ${sectionName}`);
      }
    }

    return {
      valid: errors.length === 0,
      errors,
      warnings,
    };
  }
}

module.exports = { MarkdownAdapter };
