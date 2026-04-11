/**
 * Claude Platform Adapter
 *
 * Adapts skills to the Claude platform format.
 * Claude uses SKILL.md format with YAML frontmatter.
 *
 * @version 3.1.0 - Added skill_tier, triggers (en/zh) to requiredFields per v3.1.0 spec
 */

const { MarkdownAdapter } = require('./MarkdownAdapter');

// Create Claude adapter instance
const claudeAdapter = new MarkdownAdapter({
  name: 'claude',
  installDir: '.claude',
  sections: [
    '## Overview',
    '## Usage',
    '## Examples',
    '## Configuration',
  ],
  // v3.1.0: skill_tier and triggers are now required YAML fields per base.md template.
  // triggers.en must have ≥ 3 phrases (Phase 1 check); skill_tier must be
  // one of: planning | functional | atomic (SkillX three-tier hierarchy).
  requiredFields: ['name', 'version', 'description', 'skill_tier', 'triggers'],
});

// Export the adapter interface
module.exports = {
  name: claudeAdapter.name,
  outputFormat: claudeAdapter.outputFormat,
  template: claudeAdapter.template,
  formatSkill: claudeAdapter.formatSkill.bind(claudeAdapter),
  getInstallPath: claudeAdapter.getInstallPath.bind(claudeAdapter),
  generateMetadata: claudeAdapter.generateMetadata.bind(claudeAdapter),
  validateSkill: claudeAdapter.validateSkill.bind(claudeAdapter),
};
