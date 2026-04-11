/**
 * Gemini Platform Adapter
 * 
 * Adapts skills to the Gemini platform format.
 * Gemini uses standard Markdown with YAML frontmatter.
 * 
 * @version 2.1.0 - Refactored to use MarkdownAdapter base class
 */

const { MarkdownAdapter } = require('./MarkdownAdapter');

// Create Gemini adapter instance
const geminiAdapter = new MarkdownAdapter({
  name: 'gemini',
  installDir: '.gemini',
  sections: [
    '## Overview',
    '## Usage',
    '## Examples',
  ],
  requiredFields: ['name', 'version', 'description'],
});

// Export the adapter interface
module.exports = {
  name: geminiAdapter.name,
  outputFormat: geminiAdapter.outputFormat,
  template: geminiAdapter.template,
  formatSkill: geminiAdapter.formatSkill.bind(geminiAdapter),
  getInstallPath: geminiAdapter.getInstallPath.bind(geminiAdapter),
  generateMetadata: geminiAdapter.generateMetadata.bind(geminiAdapter),
  validateSkill: geminiAdapter.validateSkill.bind(geminiAdapter),
};
