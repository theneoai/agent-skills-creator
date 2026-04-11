/**
 * Shared Frontmatter Utility
 *
 * Single canonical implementation of YAML frontmatter parsing for all platform
 * adapters. Replaces 5 different ad-hoc regex variants that were scattered across
 * MarkdownAdapter.js, cursor.js, openai.js, mcp.js, and openclaw.js.
 *
 * Before this module, adapters used:
 *   - /^---\n([\s\S]*?)\n---/       (MarkdownAdapter, mcp, openclaw)
 *   - /^---\n([\s\S]*?)\n---\n/     (cursor, openai) — trailing \n required
 *
 * The old trailing-\n variants caused silent failures for skill files ending
 * with `---` without a newline (the regex would not match, leaving YAML
 * frontmatter unconverted in cursor/openai output).
 *
 * The canonical regex uses `\n?` to make the trailing newline optional, fixing
 * the edge case while remaining backward-compatible.
 *
 * @module builder/src/utils/frontmatter
 * @version 3.1.0
 */

const yaml = require('js-yaml');

/**
 * Canonical frontmatter regex.
 *
 * Pattern: `^---\n` … `\n---\n?`
 *   - Anchored at start of string
 *   - Opening `---` followed by newline
 *   - Captures the YAML body ([\s\S]*?) lazily
 *   - Closing `---` preceded by newline, optional trailing newline
 *
 * Score variance: ±0 (deterministic, same skill → same result every run).
 */
const FRONTMATTER_REGEX = /^---\n([\s\S]*?)\n---\n?/;

/**
 * Parse frontmatter from skill content.
 *
 * @param {string} content - Raw skill content
 * @returns {{
 *   frontmatterYaml: string|null,
 *   frontmatterData: Object|null,
 *   body: string,
 *   raw: string|null
 * }}
 */
function parseFrontmatter(content) {
  if (!content || typeof content !== 'string') {
    return { frontmatterYaml: null, frontmatterData: null, body: content || '', raw: null };
  }

  const match = content.match(FRONTMATTER_REGEX);
  if (!match) {
    return { frontmatterYaml: null, frontmatterData: null, body: content, raw: null };
  }

  const frontmatterYaml = match[1];
  const body = content.slice(match[0].length);
  let frontmatterData = null;

  try {
    frontmatterData = yaml.load(frontmatterYaml) || {};
  } catch {
    // Return null frontmatterData; caller decides whether to throw or warn
  }

  return { frontmatterYaml, frontmatterData, body, raw: match[0] };
}

/**
 * Check whether content has valid YAML frontmatter.
 *
 * @param {string} content
 * @returns {boolean}
 */
function hasFrontmatter(content) {
  return FRONTMATTER_REGEX.test(content);
}

/**
 * Strip frontmatter from content, returning only the body.
 *
 * @param {string} content
 * @returns {string} Body without frontmatter
 */
function stripFrontmatter(content) {
  return content.replace(FRONTMATTER_REGEX, '');
}

module.exports = { parseFrontmatter, hasFrontmatter, stripFrontmatter, FRONTMATTER_REGEX };
