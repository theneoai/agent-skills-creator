// Main entry point for skill-writer-builder

const reader = require('./core/reader');
const embedder = require('./core/embedder');
const platforms = require('./platforms');
// v3.2.0: Graph of Skills algorithm library
const graph = require('./core/graph');

module.exports = {
  // Core modules
  reader,
  embedder,
  platforms,
  // v3.2.0: GoS graph algorithms
  graph,

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
  },

  // v3.2.0: graph-specific convenience functions
  graph: {
    ...graph,
    // Alias for quick bundle resolution from registry JSON object
    planBundle(seedSkillId, registryObject, options = {}) {
      const g = graph.buildGraph(registryObject);
      const bundle = graph.resolveBundle(seedSkillId, g, options);
      const health = graph.checkGraphHealth(g);
      return { bundle, health };
    },
  },
};
