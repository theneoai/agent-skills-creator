// Main entry point for skill-writer-builder

const reader = require('./core/reader');
const embedder = require('./core/embedder');
const platforms = require('./platforms');

module.exports = {
  // Core modules
  reader,
  embedder,
  platforms,
  
  // Convenience functions
  async build(platform, options = {}) {
    const build = require('./commands/build');
    return build({ platform, ...options });
  },
  
  async validate() {
    const { validate } = require('./commands/validate');
    return validate();
  },
  
  async inspect(platform) {
    const inspect = require('./commands/inspect');
    return inspect({ platform });
  }
};
