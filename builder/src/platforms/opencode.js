/**
 * OpenCode Platform Adapter
 *
 * Adapts skills to the OpenCode platform format.
 * OpenCode uses standard SKILL.md format with YAML frontmatter.
 *
 * @module builder/src/platforms/opencode
 * @version 2.2.0 - Refactored to use MarkdownAdapter base class
 */

const path = require('path');
const os = require('os');
const { MarkdownAdapter } = require('./MarkdownAdapter');

// ---------------------------------------------------------------------------
// OpenCode-specific constants
// ---------------------------------------------------------------------------

const OPENCODE_SECTIONS = [
  '## §1 Identity',
  '## §2 Mode Router',
  '## §3 Graceful Degradation',
  '## §4 Workflow',
  '## §5 Quality Gates',
  '## §6 Security Baseline',
  '## §7 Error Handling',
  '## §8 Usage Examples',
];

// ---------------------------------------------------------------------------
// Adapter class
// ---------------------------------------------------------------------------

/**
 * OpenCode adapter — extends MarkdownAdapter with platform-specific behaviour:
 *  - Install path: ~/.config/opencode/skills (XDG-compliant)
 *  - Appends **Triggers** block when absent
 *  - Warns about missing recommended sections
 */
class OpenCodeAdapter extends MarkdownAdapter {
  constructor() {
    super({
      name: 'opencode',
      // MarkdownAdapter.getInstallPath() → path.join(homedir, installDir, 'skills')
      // '.config/opencode' produces ~/.config/opencode/skills
      installDir: path.join('.config', 'opencode'),
      sections: OPENCODE_SECTIONS,
      requiredFields: ['name', 'version', 'description'],
    });
  }

  /**
   * Override getInstallPath so the OpenCode XDG path is assembled correctly
   * regardless of how path.join handles the multi-segment installDir.
   * @returns {string}
   */
  getInstallPath() {
    return path.join(os.homedir(), '.config', 'opencode', 'skills');
  }

  /**
   * Format skill content for the OpenCode platform.
   * Delegates header-normalisation and frontmatter validation to the base class,
   * then ensures the **Triggers** block is present at the end.
   *
   * @param {string} skillContent - Raw skill content (must not be mutated)
   * @returns {string} Formatted content for OpenCode
   */
  formatSkill(skillContent) {
    // Base class validates frontmatter and normalises H1 headings
    let formatted = super.formatSkill(skillContent);

    // Warn (don't throw) about missing recommended sections
    const missing = OPENCODE_SECTIONS.filter(sec => {
      const escaped = sec.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      return !new RegExp(`^${escaped}`, 'm').test(formatted);
    });
    if (missing.length > 0) {
      console.warn(`Warning: Missing recommended OpenCode sections: ${missing.join(', ')}`);
    }

    // Append Triggers block if not already present (never mutate the input)
    if (!formatted.includes('**Triggers**:')) {
      formatted += '\n\n---\n\n**Triggers**:\n';
    }

    return formatted;
  }

  /**
   * Generate OpenCode-specific metadata.
   * @param {Object} skillData - Skill data object
   * @returns {Object}
   */
  generateMetadata(skillData) {
    // Delegate entirely to MarkdownAdapter (which already uses the current
    // builder version and deduplicates). Only override 'format' for clarity.
    return {
      ...super.generateMetadata(skillData),
      format: 'SKILL.md',
    };
  }
}

// ---------------------------------------------------------------------------
// Singleton instance
// ---------------------------------------------------------------------------

const opencodeAdapter = new OpenCodeAdapter();

module.exports = {
  name: opencodeAdapter.name,
  outputFormat: opencodeAdapter.outputFormat,
  // Use MarkdownAdapter's template directly — the duplicate hand-written local
  // template object that previously lived here has been removed (ARCH-3 fix).
  template: opencodeAdapter.template,
  formatSkill: opencodeAdapter.formatSkill.bind(opencodeAdapter),
  getInstallPath: opencodeAdapter.getInstallPath.bind(opencodeAdapter),
  generateMetadata: opencodeAdapter.generateMetadata.bind(opencodeAdapter),
  validateSkill: opencodeAdapter.validateSkill.bind(opencodeAdapter),
};
