/**
 * Canonical Platform Metadata Schema
 *
 * Provides factory functions and type definitions for platform adapter
 * `generateMetadata()` return values. All 7 platform adapters must return
 * an object conforming to PlatformMetadata, using these factories to build
 * the compatibility block.
 *
 * Before this module, each adapter independently constructed its compatibility
 * block with incompatible field names:
 *   - MarkdownAdapter: { minVersion, testedVersions }
 *   - MCP:            { mcp_protocol, clients }
 *   - Cursor:         { minVersion, testedVersions: ['1.0.0'] }  ← hardcoded bug
 *
 * @module builder/src/utils/metadata-schema
 * @version 3.1.0
 *
 * @typedef {Object} MarkdownCompatibility
 * @property {string} minVersion       - Minimum builder version required
 * @property {string[]} testedVersions - Builder versions tested; always includes current
 *
 * @typedef {Object} MCPCompatibility
 * @property {string}   mcp_protocol - MCP protocol version ('1.0')
 * @property {string[]} clients      - Compatible MCP client names
 *
 * @typedef {Object} PlatformMetadata
 * @property {string}                           platform      - Platform name
 * @property {string}                           format        - Output format ('SKILL.md', 'JSON', etc.)
 * @property {string}                           outputFormat  - 'MARKDOWN' | 'JSON' | 'HYBRID'
 * @property {string}                           version       - Skill version
 * @property {string}                           created       - ISO-8601 timestamp
 * @property {MarkdownCompatibility|MCPCompatibility} compatibility - Version info
 */

// Read once at module load — avoids re-require on every generateMetadata() call.
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
 * Build a standard compatibility block for Markdown-based platforms.
 *
 * @param {string} [minVersion='2.2.0'] - Minimum required builder version
 * @returns {MarkdownCompatibility}
 */
function markdownCompatibility(minVersion = '2.2.0') {
  return {
    minVersion,
    testedVersions: [getBuilderVersion()],
  };
}

/**
 * Build an MCP-specific compatibility block.
 *
 * @returns {MCPCompatibility}
 */
function mcpCompatibility() {
  return {
    mcp_protocol: '1.0',
    clients: ['claude-desktop', 'cursor', 'vscode-mcp', 'openai-plugin'],
  };
}

module.exports = { markdownCompatibility, mcpCompatibility, getBuilderVersion };
