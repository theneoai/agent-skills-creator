/**
 * Embedder Module
 * 
 * Embeds core content into platform templates.
 * Handles template placeholders and platform-specific formatting.
 * 
 * @module builder/src/core/embedder
 * @version 1.0.0
 */

const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');

// Platform-specific formatting configurations
const PLATFORM_CONFIGS = {
  opencode: {
    placeholderPattern: /\{\{(\w+)\}\}/g,
    sectionPrefix: '##',
    codeBlockLang: 'yaml',
    supportsFrontmatter: true,
    triggerFormat: 'markdown',
  },
  openclaw: {
    placeholderPattern: /\{\{(\w+)\}\}/g,
    sectionPrefix: '##',
    codeBlockLang: 'yaml',
    supportsFrontmatter: true,
    triggerFormat: 'markdown',
  },
  claude: {
    placeholderPattern: /\{\{(\w+)\}\}/g,
    sectionPrefix: '##',
    codeBlockLang: 'yaml',
    supportsFrontmatter: true,
    triggerFormat: 'markdown',
  },
  cursor: {
    placeholderPattern: /\$\{(\w+)\}/g,
    sectionPrefix: '##',
    codeBlockLang: 'yaml',
    supportsFrontmatter: false,
    triggerFormat: 'json',
  },
  openai: {
    placeholderPattern: /\{\{(\w+)\}\}/g,
    sectionPrefix: '##',
    codeBlockLang: 'json',
    supportsFrontmatter: true,
    triggerFormat: 'json',
  },
  gemini: {
    placeholderPattern: /\{\{(\w+)\}\}/g,
    sectionPrefix: '##',
    codeBlockLang: 'yaml',
    supportsFrontmatter: true,
    triggerFormat: 'markdown',
  },
};

// Default configuration
const DEFAULT_CONFIG = PLATFORM_CONFIGS.opencode;

/**
 * Get platform-specific configuration
 * @param {string} platform - Platform name
 * @returns {Object} Platform configuration
 */
function getPlatformConfig(platform) {
  const config = PLATFORM_CONFIGS[platform.toLowerCase()];
  if (!config) {
    console.warn(`Unknown platform: ${platform}. Using default configuration.`);
    return DEFAULT_CONFIG;
  }
  return config;
}

/**
 * Replace placeholders in template with data
 * @param {string} template - Template string
 * @param {Object} data - Data to replace placeholders
 * @param {Object} config - Platform configuration
 * @returns {string} Processed template
 */
function replacePlaceholders(template, data, config) {
  let result = template;
  
  // Replace all placeholders
  result = result.replace(config.placeholderPattern, (match, key) => {
    const value = data[key];
    if (value === undefined || value === null) {
      console.warn(`Placeholder ${key} not found in data`);
      return match; // Keep original placeholder
    }
    return String(value);
  });
  
  return result;
}

/**
 * Format section header for platform
 * @param {string} title - Section title
 * @param {number} level - Header level (1-6)
 * @param {Object} config - Platform configuration
 * @returns {string} Formatted header
 */
function formatSectionHeader(title, level, config) {
  const prefix = config.sectionPrefix.charAt(0).repeat(level);
  return `${prefix} ${title}`;
}

/**
 * Format code block for platform
 * @param {string} content - Code content
 * @param {string} language - Programming language
 * @param {Object} config - Platform configuration
 * @returns {string} Formatted code block
 */
function formatCodeBlock(content, language, config) {
  const lang = language || config.codeBlockLang;
  return `\`\`\`${lang}\n${content}\n\`\`\``;
}

/**
 * Format YAML frontmatter for platform
 * @param {Object} data - Frontmatter data
 * @param {Object} config - Platform configuration
 * @returns {string|null} Formatted frontmatter or null if not supported
 */
function formatFrontmatter(data, config) {
  if (!config.supportsFrontmatter) {
    return null;
  }
  
  try {
    const yamlContent = yaml.dump(data, {
      lineWidth: -1,
      noRefs: true,
      sortKeys: false,
    });
    return `---\n${yamlContent}---\n`;
  } catch (error) {
    console.error('Error formatting frontmatter:', error.message);
    return null;
  }
}

/**
 * Extract content from file object or return as-is if string
 * @param {Object|string} data - File data object or string
 * @returns {string} Content string
 */
function extractContent(data) {
  if (typeof data === 'string') {
    return data;
  }
  if (data && typeof data === 'object') {
    // If it has a content property (from parseFile), return that
    if (data.content !== undefined) {
      return data.content;
    }
    // Otherwise, stringify the object
    return yaml.dump(data, { lineWidth: -1 });
  }
  return String(data || '');
}

/**
 * Format templates object into readable content
 * @param {Object} templates - Templates object from reader
 * @returns {string} Formatted templates content
 */
function formatTemplates(templates) {
  if (!templates || Object.keys(templates).length === 0) {
    return '';
  }

  const sections = [];
  
  for (const [name, templateData] of Object.entries(templates)) {
    const content = extractContent(templateData);
    sections.push(`### ${name} Template\n\n${content}`);
  }
  
  return sections.join('\n\n---\n\n');
}

/**
 * Embed CREATE mode into template
 * 
 * @param {string} template - Platform template string
 * @param {Object} createData - CREATE mode data
 * @param {string} createData.workflow - Workflow documentation
 * @param {string} createData.elicitation - Elicitation questions
 * @param {string} createData.templates - Available templates info
 * @param {Object} createData.securityChecks - Security check patterns
 * @param {Object} createData.config - CREATE mode configuration
 * @returns {string} Template with CREATE mode embedded
 */
function embedCreateMode(template, createData) {
  const config = DEFAULT_CONFIG;
  
  // Build CREATE mode section
  const sections = [];
  
  // Section 1: Workflow
  if (createData.workflow) {
    sections.push(formatSectionHeader('CREATE Mode — Workflow', 2, config));
    sections.push(extractContent(createData.workflow));
  }
  
  // Section 2: Elicitation Questions
  if (createData.elicitation) {
    sections.push(formatSectionHeader('CREATE Mode — Requirement Elicitation', 2, config));
    sections.push(extractContent(createData.elicitation));
  }
  
  // Section 3: Templates
  if (createData.templates && Object.keys(createData.templates).length > 0) {
    sections.push(formatSectionHeader('CREATE Mode — Templates', 2, config));
    sections.push(formatTemplates(createData.templates));
  }
  
  // Section 4: Security Checks
  if (createData.securityChecks) {
    sections.push(formatSectionHeader('CREATE Mode — Security Checks', 2, config));
    sections.push(formatCodeBlock(
      yaml.dump(createData.securityChecks, { lineWidth: -1 }),
      'yaml',
      config
    ));
  }
  
  // Section 5: Configuration
  if (createData.config) {
    sections.push(formatSectionHeader('CREATE Mode — Configuration', 2, config));
    sections.push(formatCodeBlock(
      yaml.dump(createData.config, { lineWidth: -1 }),
      'yaml',
      config
    ));
  }
  
  const createContent = sections.join('\n\n');
  
  // Replace CREATE_MODE placeholder or append
  if (template.includes('{{CREATE_MODE}}')) {
    return template.replace('{{CREATE_MODE}}', createContent);
  }
  
  // If no placeholder, append to end
  return `${template}\n\n${createContent}`;
}

/**
 * Embed EVALUATE mode into template
 * 
 * @param {string} template - Platform template string
 * @param {Object} evaluateData - EVALUATE mode data
 * @param {string} evaluateData.phases - Phase documentation
 * @param {string} evaluateData.rubrics - Scoring rubrics
 * @param {string} evaluateData.certification - Certification tiers
 * @param {Object} evaluateData.scoring - Scoring configuration
 * @param {Object} evaluateData.config - EVALUATE mode configuration
 * @returns {string} Template with EVALUATE mode embedded
 */
function embedEvaluateMode(template, evaluateData) {
  const config = DEFAULT_CONFIG;
  
  // Build EVALUATE mode section
  const sections = [];
  
  // Section 1: Overview
  sections.push(formatSectionHeader('EVALUATE Mode — Quality Assessment', 2, config));
  sections.push('EVALUATE mode provides rigorous, standardized quality assessment for skills.');
  
  // Section 2: Phases
  if (evaluateData.phases) {
    sections.push(formatSectionHeader('4-Phase Pipeline', 3, config));
    sections.push(extractContent(evaluateData.phases));
  }
  
  // Section 3: Rubrics
  if (evaluateData.rubrics) {
    sections.push(formatSectionHeader('Scoring Rubrics', 3, config));
    sections.push(extractContent(evaluateData.rubrics));
  }
  
  // Section 4: Certification
  if (evaluateData.certification) {
    sections.push(formatSectionHeader('Certification Tiers', 3, config));
    sections.push(extractContent(evaluateData.certification));
  }
  
  // Section 5: Scoring Configuration
  if (evaluateData.scoring) {
    sections.push(formatSectionHeader('Scoring Configuration', 3, config));
    sections.push(formatCodeBlock(
      yaml.dump(evaluateData.scoring, { lineWidth: -1 }),
      'yaml',
      config
    ));
  }
  
  // Section 6: Configuration
  if (evaluateData.config) {
    sections.push(formatSectionHeader('Configuration', 3, config));
    sections.push(formatCodeBlock(
      yaml.dump(evaluateData.config, { lineWidth: -1 }),
      'yaml',
      config
    ));
  }
  
  const evaluateContent = sections.join('\n\n');
  
  // Replace EVALUATE_MODE placeholder or append
  if (template.includes('{{EVALUATE_MODE}}')) {
    return template.replace('{{EVALUATE_MODE}}', evaluateContent);
  }
  
  // If no placeholder, append to end
  return `${template}\n\n${evaluateContent}`;
}

/**
 * Embed OPTIMIZE mode into template
 * 
 * @param {string} template - Platform template string
 * @param {Object} optimizeData - OPTIMIZE mode data
 * @param {string} optimizeData.dimensions - Dimension documentation
 * @param {string} optimizeData.strategies - Optimization strategies
 * @param {string} optimizeData.convergence - Convergence rules
 * @param {Object} optimizeData.loopConfig - Loop configuration
 * @param {Object} optimizeData.config - OPTIMIZE mode configuration
 * @returns {string} Template with OPTIMIZE mode embedded
 */
function embedOptimizeMode(template, optimizeData) {
  const config = DEFAULT_CONFIG;
  
  // Build OPTIMIZE mode section
  const sections = [];
  
  // Section 1: Overview
  sections.push(formatSectionHeader('OPTIMIZE Mode — Continuous Improvement', 2, config));
  sections.push('OPTIMIZE mode provides automated, iterative skill improvement through systematic optimization.');
  
  // Section 2: Dimensions
  if (optimizeData.dimensions) {
    sections.push(formatSectionHeader('7-Dimension Analysis', 3, config));
    sections.push(extractContent(optimizeData.dimensions));
  }
  
  // Section 3: Strategies
  if (optimizeData.strategies) {
    sections.push(formatSectionHeader('Optimization Strategies', 3, config));
    sections.push(extractContent(optimizeData.strategies));
  }
  
  // Section 4: Convergence
  if (optimizeData.convergence) {
    sections.push(formatSectionHeader('Convergence Detection', 3, config));
    sections.push(extractContent(optimizeData.convergence));
  }
  
  // Section 5: Loop Configuration
  if (optimizeData.loopConfig) {
    sections.push(formatSectionHeader('9-Step Optimization Loop', 3, config));
    sections.push(formatCodeBlock(
      yaml.dump(optimizeData.loopConfig, { lineWidth: -1 }),
      'yaml',
      config
    ));
  }
  
  // Section 6: Configuration
  if (optimizeData.config) {
    sections.push(formatSectionHeader('Configuration', 3, config));
    sections.push(formatCodeBlock(
      yaml.dump(optimizeData.config, { lineWidth: -1 }),
      'yaml',
      config
    ));
  }
  
  const optimizeContent = sections.join('\n\n');
  
  // Replace OPTIMIZE_MODE placeholder or append
  if (template.includes('{{OPTIMIZE_MODE}}')) {
    return template.replace('{{OPTIMIZE_MODE}}', optimizeContent);
  }
  
  // If no placeholder, append to end
  return `${template}\n\n${optimizeContent}`;
}

/**
 * Embed shared resources into template
 * 
 * @param {string} template - Platform template string
 * @param {Object} sharedData - Shared resources data
 * @param {Object} sharedData.security - Security patterns (CWE, etc.)
 * @param {Object} sharedData.utils - Utility functions
 * @param {Object} sharedData.helpers - Helper patterns
 * @param {Object} sharedData.config - Shared configuration
 * @returns {string} Template with shared resources embedded
 */
function embedSharedResources(template, sharedData) {
  const config = DEFAULT_CONFIG;
  
  // Build shared resources section
  const sections = [];
  
  // Section 1: Header
  sections.push(formatSectionHeader('Shared Resources', 2, config));
  sections.push('Common patterns, utilities, and security checks used across all modes.');
  
  // Section 2: Security Patterns
  if (sharedData.security) {
    sections.push(formatSectionHeader('Security Patterns', 3, config));
    sections.push(extractContent(sharedData.security));
  }
  
  // Section 3: Utilities
  if (sharedData.utils) {
    sections.push(formatSectionHeader('Utility Functions', 3, config));
    sections.push(formatCodeBlock(
      extractContent(sharedData.utils),
      'yaml',
      config
    ));
  }
  
  // Section 4: Helpers
  if (sharedData.helpers) {
    sections.push(formatSectionHeader('Helper Patterns', 3, config));
    sections.push(formatCodeBlock(
      yaml.dump(sharedData.helpers, { lineWidth: -1 }),
      'yaml',
      config
    ));
  }
  
  // Section 5: Configuration
  if (sharedData.config) {
    sections.push(formatSectionHeader('Shared Configuration', 3, config));
    sections.push(formatCodeBlock(
      yaml.dump(sharedData.config, { lineWidth: -1 }),
      'yaml',
      config
    ));
  }
  
  const sharedContent = sections.join('\n\n');
  
  // Replace SHARED_RESOURCES placeholder or append
  if (template.includes('{{SHARED_RESOURCES}}')) {
    return template.replace('{{SHARED_RESOURCES}}', sharedContent);
  }
  
  // If no placeholder, append to end
  return `${template}\n\n${sharedContent}`;
}

/**
 * Generate complete skill file for a platform
 * 
 * @param {string} platform - Target platform (opencode, openclaw, claude, cursor, openai, gemini)
 * @param {Object} coreData - Core engine data
 * @param {Object} coreData.metadata - Skill metadata
 * @param {Object} coreData.create - CREATE mode data
 * @param {Object} coreData.evaluate - EVALUATE mode data
 * @param {Object} coreData.optimize - OPTIMIZE mode data
 * @param {Object} coreData.shared - Shared resources data
 * @param {string} [coreData.template] - Optional custom template
 * @returns {Object} Generated skill file with content and metadata
 */
function generateSkillFile(platform, coreData) {
  const config = getPlatformConfig(platform);

  // Validate required data
  if (!coreData || typeof coreData !== 'object') {
    throw new Error('coreData is required and must be an object');
  }

  // Start with platform-specific template, custom template, or default template
  let template;
  if (coreData.template) {
    template = coreData.template;
  } else {
    // Try to load platform-specific template
    const platformTemplatePath = path.join(__dirname, '../../templates', `${platform}.md`);
    const platformTemplateJsonPath = path.join(__dirname, '../../templates', `${platform}.json`);

    try {
      if (platform === 'openai' && fs.existsSync(platformTemplateJsonPath)) {
        template = fs.readFileSync(platformTemplateJsonPath, 'utf-8');
      } else if (fs.existsSync(platformTemplatePath)) {
        template = fs.readFileSync(platformTemplatePath, 'utf-8');
      } else {
        template = getDefaultTemplate(platform);
      }
    } catch (error) {
      console.warn(`Could not load platform template for ${platform}, using default`);
      template = getDefaultTemplate(platform);
    }
  }
  
  // Replace metadata placeholders
  if (coreData.metadata) {
    template = replacePlaceholders(template, coreData.metadata, config);
  }
  
  // Embed CREATE mode
  if (coreData.create) {
    template = embedCreateMode(template, coreData.create);
  }
  
  // Embed EVALUATE mode
  if (coreData.evaluate) {
    template = embedEvaluateMode(template, coreData.evaluate);
  }
  
  // Embed OPTIMIZE mode
  if (coreData.optimize) {
    template = embedOptimizeMode(template, coreData.optimize);
  }
  
  // Embed shared resources
  if (coreData.shared) {
    template = embedSharedResources(template, coreData.shared);
  }

  // Check if template already has frontmatter
  const hasFrontmatter = template.trim().startsWith('---');

  // Generate frontmatter if supported and not already present
  let frontmatter = '';
  if (config.supportsFrontmatter && coreData.metadata && !hasFrontmatter) {
    const today = new Date().toISOString().split('T')[0];
    const skillVersion = coreData.metadata.version || '2.0.0';
    const fmData = {
      name: coreData.metadata.name || 'unnamed-skill',
      version: skillVersion,
      description: coreData.metadata.description || '',
      platform: platform,
      created: today,
      updated: today,
      interface: {
        modes: (coreData.metadata.extra && coreData.metadata.extra.modes) ||
               coreData.metadata.modes || ['create', 'evaluate', 'optimize'],
      },
      use_to_evolve: {
        enabled: true,
        injected_by: `skill-writer v${skillVersion}`,
        injected_at: today,
        check_cadence: { lightweight: 10, full_recompute: 50, tier_drift: 100 },
        micro_patch_enabled: true,
        feedback_detection: true,
        certified_lean_score: null,
        last_ute_check: null,
        pending_patches: 0,
        total_micro_patches_applied: 0,
        cumulative_invocations: 0,
      },
      generated_at: new Date().toISOString(),
      ...(coreData.metadata.extra || {}),
    };
    frontmatter = formatFrontmatter(fmData, config);
    if (!frontmatter) {
      console.warn(`Warning: formatFrontmatter returned null for platform "${platform}", output will lack frontmatter`);
      frontmatter = '';
    }
  }

  // Combine frontmatter and content, then inject §UTE section
  const combined = frontmatter + template;
  const finalContent = injectUTESection(combined, coreData.metadata);

  // Return result with metadata
  return {
    platform: platform,
    content: finalContent,
    metadata: {
      generated_at: new Date().toISOString(),
      platform: platform,
      has_create: !!coreData.create,
      has_evaluate: !!coreData.evaluate,
      has_optimize: !!coreData.optimize,
      has_shared: !!coreData.shared,
      content_length: finalContent.length,
    },
  };
}

/**
 * Inject §UTE Use-to-Evolve section if not already present in content
 * @param {string} content - Skill content
 * @param {Object} [metadata] - Skill metadata
 * @returns {string} Content with §UTE section appended
 */
function injectUTESection(content, metadata) {
  if (/##\s+§UTE\b/i.test(content)) {
    return content; // already present
  }

  const name = (metadata && metadata.name) || 'this-skill';
  const version = (metadata && metadata.version) || '2.1.0';
  const today = new Date().toISOString().split('T')[0];

  const uteSection = `\n---\n\n## §UTE Use-to-Evolve\n\n<!-- Post-invocation hook — auto-managed by skill-writer v2.1.0 -->\n<!-- skill: ${name} | version: ${version} | injected: ${today} -->\n\nAfter each invocation, increment \`use_to_evolve.cumulative_invocations\`.\nRun lightweight LEAN check every 10 invocations; full re-score every 50;\ntier-drift detection every 100.\n\n**Fields managed automatically** (do not edit manually):\n- \`cumulative_invocations\` — incremented each use\n- \`last_ute_check\` — ISO date of last lightweight check\n- \`pending_patches\` — count of queued micro-patches\n- \`total_micro_patches_applied\` — lifetime patch count\n`;

  return content + uteSection;
}

/**
 * Get default template for platform
 * @param {string} platform - Platform name
 * @returns {string} Default template
 */
function getDefaultTemplate(platform) {
  const config = getPlatformConfig(platform);
  
  // Default template structure
  return `# {{TITLE}}

> **Type**: {{TYPE}}
> **Platform**: ${platform}
> **Version**: {{VERSION}}

---

## Overview

{{DESCRIPTION}}

---

{{CREATE_MODE}}

---

{{EVALUATE_MODE}}

---

{{OPTIMIZE_MODE}}

---

{{SHARED_RESOURCES}}

---

## Triggers

{{TRIGGERS}}

---

*Generated by skill-writer-builder v2.1.0*
`;
}

/**
 * Validate embedded content
 * @param {string} content - Content to validate
 * @returns {Object} Validation result
 */
function validateEmbeddedContent(content) {
  const issues = [];
  
  // Check for remaining placeholders
  const placeholderMatches = content.match(/\{\{\w+\}\}/g);
  if (placeholderMatches) {
    issues.push({
      type: 'warning',
      message: `Unreplaced placeholders found: ${placeholderMatches.join(', ')}`,
    });
  }
  
  // Check for empty sections
  const emptySectionMatches = content.match(/##\s+\w+\s*\n\s*(?=##|$)/g);
  if (emptySectionMatches) {
    issues.push({
      type: 'warning',
      message: 'Empty sections detected',
      sections: emptySectionMatches,
    });
  }
  
  // Check for balanced code blocks
  const codeBlockOpens = (content.match(/```/g) || []).length;
  if (codeBlockOpens % 2 !== 0) {
    issues.push({
      type: 'error',
      message: 'Unbalanced code blocks detected',
    });
  }
  
  return {
    valid: issues.filter(i => i.type === 'error').length === 0,
    issues: issues,
  };
}

/**
 * Extract placeholders from template
 * @param {string} template - Template string
 * @returns {string[]} Array of placeholder names
 */
function extractPlaceholders(template) {
  const placeholders = new Set();
  const pattern = /\{\{(\w+)\}\}/g;
  let match;
  
  while ((match = pattern.exec(template)) !== null) {
    placeholders.add(match[1]);
  }
  
  return Array.from(placeholders);
}

/**
 * Apply platform-specific transformations
 * @param {string} content - Content to transform
 * @param {string} platform - Target platform
 * @returns {string} Transformed content
 */
function applyPlatformTransforms(content, platform) {
  const config = getPlatformConfig(platform);
  let result = content;
  
  // Platform-specific transformations
  switch (platform.toLowerCase()) {
    case 'cursor':
      // Convert placeholders to ${...} format
      result = result.replace(/\{\{(\w+)\}\}/g, '${$1}');
      break;
      
    case 'openai':
      // Convert frontmatter to JSON if not supported
      if (!config.supportsFrontmatter) {
        result = convertFrontmatterToJSON(result);
      }
      break;
      
    case 'gemini':
      // Ensure proper formatting for Gemini
      result = ensureGeminiFormatting(result);
      break;
      
    default:
      // No transformation needed
      break;
  }
  
  return result;
}

/**
 * Convert YAML frontmatter to JSON
 * @param {string} content - Content with frontmatter
 * @returns {string} Content with JSON frontmatter
 */
function convertFrontmatterToJSON(content) {
  const frontmatterMatch = content.match(/^---\n([\s\S]*?)\n---\n/);
  if (frontmatterMatch) {
    try {
      const yamlData = yaml.load(frontmatterMatch[1]);
      const jsonContent = JSON.stringify(yamlData, null, 2);
      return content.replace(frontmatterMatch[0], `\`\`\`json\n${jsonContent}\n\`\`\`\n\n`);
    } catch (error) {
      console.warn('Failed to convert frontmatter to JSON:', error.message);
    }
  }
  return content;
}

/**
 * Ensure proper formatting for Gemini
 * @param {string} content - Content to format
 * @returns {string} Formatted content
 */
function ensureGeminiFormatting(content) {
  // Ensure proper header hierarchy
  let result = content;
  
  // Ensure there's only one H1
  const h1Matches = result.match(/^#\s+.+$/gm);
  if (h1Matches && h1Matches.length > 1) {
    // Convert additional H1s to H2s
    let count = 0;
    result = result.replace(/^#\s+(.+)$/gm, (match, title) => {
      count++;
      return count === 1 ? match : `## ${title}`;
    });
  }
  
  return result;
}

// Export all functions
module.exports = {
  // Main embedding functions
  embedCreateMode,
  embedEvaluateMode,
  embedOptimizeMode,
  embedSharedResources,
  generateSkillFile,
  injectUTESection,

  // Utility functions
  getPlatformConfig,
  replacePlaceholders,
  formatSectionHeader,
  formatCodeBlock,
  formatFrontmatter,
  
  // Constants
  PLATFORM_CONFIGS,
  DEFAULT_CONFIG,
};
