/**
 * Skill Metadata - Single Source of Truth
 *
 * Centralizes the skill-writer meta-skill's own build-time metadata so that
 * both the `build` and `dev` commands always emit identical, version-consistent
 * frontmatter.  Previously each command maintained its own copy, which led to
 * version drift (dev hard-coded '1.0.0') and missing platform/mode entries.
 *
 * @module builder/src/metadata
 * @version 3.1.0
 */

const { getSupportedPlatforms } = require('./platforms');

/**
 * Generate skill-writer's own metadata object.
 * Version is read at call-time from builder/package.json (the authoritative
 * version source), so it is always current without manual updates.
 *
 * @param {string} platform - Target platform name (embedded in metadata.platform)
 * @returns {Object} Metadata suitable for the `metadata` key in enrichedCoreData
 */
function getSkillMetadata(platform) {
  const pkgVersion = require('../package.json').version;
  const supportedPlatforms = getSupportedPlatforms();

  return {
    TITLE: 'Skill Writer',
    TYPE: 'Meta-Skill',
    VERSION: pkgVersion,
    DESCRIPTION:
      'A meta-skill for creating, evaluating, and optimizing other skills through natural language interaction.',
    TRIGGERS: `
**CREATE Mode:**
- "create a [type] skill"
- "help me write a skill for [purpose]"
- "I need a skill that [description]"

**EVALUATE Mode:**
- "evaluate this skill"
- "check the quality of my skill"
- "certify my skill"

**OPTIMIZE Mode:**
- "optimize this skill"
- "improve my skill"
- "make this skill better"

**INSTALL Mode:**
- "install skill-writer"
- "install skill-writer to [platform]"
- "安装 skill-writer"`,
    name: 'skill-writer',
    version: pkgVersion,
    description:
      'Meta-skill for creating, evaluating, and optimizing skills (supports MCP, Claude, OpenCode, OpenClaw, Cursor, OpenAI, Gemini)',
    author: 'skill-writer-builder',
    license: 'MIT',
    tags: [
      'meta-skill',
      'skill-creation',
      'skill-evaluation',
      'skill-optimization',
      'mcp',
    ],
    modes: ['create', 'lean', 'evaluate', 'optimize', 'install', 'collect'],
    defaultMode: 'create',
    platform,
    extra: {
      modes: ['create', 'lean', 'evaluate', 'optimize', 'install', 'collect'],
      platforms: supportedPlatforms,
    },
    // Security scan summary counts (0 = clean baseline)
    p0_count: 0,
    p1_count: 0,
    p2_count: 0,
    p3_count: 0,
    generated_at: new Date().toISOString(),
  };
}

module.exports = { getSkillMetadata };
