/**
 * Platform Adapter Base Class
 *
 * Shared base class for Markdown-based platform adapters (Claude, Gemini, OpenCode, OpenClaw).
 * Eliminates code duplication between adapters.
 *
 * @module builder/src/platforms/MarkdownAdapter
 * @version 2.2.0
 */

const path = require('path');
const os = require('os');

// Read builder version once so generateMetadata doesn't re-require on every call.
let _builderVersion;
function getBuilderVersion() {
  if (!_builderVersion) {
    try {
      _builderVersion = require('../../package.json').version;
    } catch {
      _builderVersion = '0.0.0';
    }
  }
  return _builderVersion;
}

/**
 * Base class for Markdown-based platform adapters
 */
class MarkdownAdapter {
  /**
   * @param {Object} options - Adapter configuration
   * @param {string} options.name - Platform name
   * @param {string} options.installDir - Installation directory name (e.g., '.claude')
   * @param {string[]} options.sections - Default sections for the platform
   * @param {string[]} options.requiredFields - Required frontmatter fields
   */
  constructor(options) {
    this.name = options.name;
    this.installDir = options.installDir;
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
   * Format skill content for the platform
   * @param {string} skillContent - Raw skill content
   * @returns {string} Formatted skill content
   */
  formatSkill(skillContent) {
    if (!skillContent || typeof skillContent !== 'string') {
      throw new Error('Invalid skill content provided');
    }

    // Validate YAML frontmatter presence
    const frontmatterMatch = skillContent.match(/^---\n([\s\S]*?)\n---/);
    if (!frontmatterMatch) {
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
   * Uses the builder's own package.json version as the highest tested version.
   * @param {Object} skillData - Skill data object
   * @returns {Object} Platform metadata
   */
  generateMetadata(skillData) {
    const builderVersion = getBuilderVersion();
    return {
      platform: this.name,
      format: 'SKILL.md',
      version: skillData?.version || '1.0.0',
      created: new Date().toISOString(),
      compatibility: {
        minVersion: '2.2.0',
        testedVersions: [builderVersion].filter(
          (v, i, arr) => arr.indexOf(v) === i   // deduplicate
        ),
      },
    };
  }

  /**
   * Validate skill structure
   * @param {string} skillContent - Skill content to validate
   * @returns {Object} Validation result
   */
  validateSkill(skillContent) {
    const errors = [];
    const warnings = [];

    // Check YAML frontmatter
    const frontmatterMatch = skillContent.match(/^---\n([\s\S]*?)\n---/);
    if (!frontmatterMatch) {
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
