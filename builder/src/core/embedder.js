/**
 * Embedder Module
 *
 * Embeds core content into platform templates.
 * Handles template placeholders and platform-specific formatting.
 *
 * @module builder/src/core/embedder
 * @version 3.1.0
 */

const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');
const config = require('../config');

// Canonical platform configurations come from centralized config (SSOT).
// Local alias kept for backward compatibility; do not add platform entries here.
const PLATFORM_CONFIGS = config.PLATFORMS;

// Default configuration
const DEFAULT_CONFIG = PLATFORM_CONFIGS.opencode;

// Template cache: populated lazily on first generateSkillFile() call per platform.
// Avoids repeated synchronous disk reads when building multiple skills in one session.
const _templateCache = new Map();

/**
 * Get platform-specific configuration
 * @param {string} platform - Platform name
 * @returns {Object} Platform configuration
 */
function getPlatformConfig(platform) {
  const platformConfig = config.PLATFORMS[platform.toLowerCase()];
  if (!platformConfig) {
    console.warn(`Unknown platform: ${platform}. Using default configuration.`);
    return DEFAULT_CONFIG;
  }
  return platformConfig;
}

/**
 * Replace placeholders in template with data
 * @param {string} template - Template string
 * @param {Object} data - Data to replace placeholders
 * @param {Object} platformConfig - Platform configuration
 * @param {Object} [options] - Options for replacement
 * @param {boolean} [options.strict=false] - If true, throw error when placeholder is missing
 * @returns {string} Processed template
 * @throws {Error} When strict mode is enabled and placeholder is not found
 */
function replacePlaceholders(template, data, platformConfig, options = {}) {
  const { strict = false } = options;
  let result = template;

  // Replace all placeholders
  result = result.replace(platformConfig.placeholderPattern, (match, key) => {
    const value = data[key];
    if (value === undefined || value === null) {
      if (strict) {
        throw new Error(`[${config.ERROR_CODES.MISSING_PLACEHOLDER}] Placeholder "${key}" not found in data`);
      }
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
 * Format YAML frontmatter for platform.
 * Returns null if the platform does not support YAML frontmatter (e.g. Cursor, MCP).
 *
 * @param {Object} data - Frontmatter data
 * @param {Object} [platformConfig] - Platform configuration (from config.PLATFORMS)
 * @returns {string|null} Formatted frontmatter or null if not supported
 */
function formatFrontmatter(data, platformConfig) {
  // When called without a platform config, default to supporting frontmatter
  if (platformConfig && !platformConfig.supportsFrontmatter) {
    return null;
  }

  // Let yaml.dump errors propagate — callers that require frontmatter (e.g.
  // generateSkillFile) catch and re-wrap as EINVALID_FRONTMATTER with context.
  const yamlContent = yaml.dump(data, {
    lineWidth: -1,   // disable line wrapping so long strings stay on one line
    noRefs: true,    // avoid YAML anchors/aliases (&ref/*ref) — keep output portable
    sortKeys: false, // preserve insertion order for readability
  });
  return `---\n${yamlContent}---\n`;
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
  const platformCfg = DEFAULT_CONFIG;

  // Build CREATE mode section
  const sections = [];

  // Section 1: Workflow
  if (createData.workflow) {
    sections.push(formatSectionHeader('CREATE Mode — Workflow', 2, platformCfg));
    sections.push(extractContent(createData.workflow));
  }

  // Section 2: Elicitation Questions
  if (createData.elicitation) {
    sections.push(formatSectionHeader('CREATE Mode — Requirement Elicitation', 2, platformCfg));
    sections.push(extractContent(createData.elicitation));
  }

  // Section 3: Templates
  if (createData.templates && Object.keys(createData.templates).length > 0) {
    sections.push(formatSectionHeader('CREATE Mode — Templates', 2, platformCfg));
    sections.push(formatTemplates(createData.templates));
  }

  // Section 4: Security Checks
  if (createData.securityChecks) {
    sections.push(formatSectionHeader('CREATE Mode — Security Checks', 2, platformCfg));
    sections.push(formatCodeBlock(
      yaml.dump(createData.securityChecks, { lineWidth: -1 }),
      'yaml',
      platformCfg
    ));
  }

  // Section 5: Configuration
  if (createData.config) {
    sections.push(formatSectionHeader('CREATE Mode — Configuration', 2, platformCfg));
    sections.push(formatCodeBlock(
      yaml.dump(createData.config, { lineWidth: -1 }),
      'yaml',
      platformCfg
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
  const platformCfg = DEFAULT_CONFIG;

  // Build EVALUATE mode section
  const sections = [];

  // Section 1: Overview
  sections.push(formatSectionHeader('EVALUATE Mode — Quality Assessment', 2, platformCfg));
  sections.push('EVALUATE mode provides rigorous, standardized quality assessment for skills.');

  // Section 2: Phases
  if (evaluateData.phases) {
    sections.push(formatSectionHeader('4-Phase Pipeline', 3, platformCfg));
    sections.push(extractContent(evaluateData.phases));
  }

  // Section 3: Rubrics
  if (evaluateData.rubrics) {
    sections.push(formatSectionHeader('Scoring Rubrics', 3, platformCfg));
    sections.push(extractContent(evaluateData.rubrics));
  }

  // Section 4: Certification
  if (evaluateData.certification) {
    sections.push(formatSectionHeader('Certification Tiers', 3, platformCfg));
    sections.push(extractContent(evaluateData.certification));
  }

  // Section 5: Scoring Configuration
  if (evaluateData.scoring) {
    sections.push(formatSectionHeader('Scoring Configuration', 3, platformCfg));
    sections.push(formatCodeBlock(
      yaml.dump(evaluateData.scoring, { lineWidth: -1 }),
      'yaml',
      platformCfg
    ));
  }

  // Section 6: Configuration
  if (evaluateData.config) {
    sections.push(formatSectionHeader('Configuration', 3, platformCfg));
    sections.push(formatCodeBlock(
      yaml.dump(evaluateData.config, { lineWidth: -1 }),
      'yaml',
      platformCfg
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
  const platformCfg = DEFAULT_CONFIG;

  // Build OPTIMIZE mode section
  const sections = [];

  // Section 1: Overview
  sections.push(formatSectionHeader('OPTIMIZE Mode — Continuous Improvement', 2, platformCfg));
  sections.push('OPTIMIZE mode provides automated, iterative skill improvement through systematic optimization.');

  // Section 2: Dimensions
  if (optimizeData.dimensions) {
    sections.push(formatSectionHeader('7-Dimension Analysis', 3, platformCfg));
    sections.push(extractContent(optimizeData.dimensions));
  }

  // Section 3: Strategies
  if (optimizeData.strategies) {
    sections.push(formatSectionHeader('Optimization Strategies', 3, platformCfg));
    sections.push(extractContent(optimizeData.strategies));
  }

  // Section 4: Convergence
  if (optimizeData.convergence) {
    sections.push(formatSectionHeader('Convergence Detection', 3, platformCfg));
    sections.push(extractContent(optimizeData.convergence));
  }

  // Section 5: Loop Configuration
  if (optimizeData.loopConfig) {
    sections.push(formatSectionHeader('9-Step Optimization Loop', 3, platformCfg));
    sections.push(formatCodeBlock(
      yaml.dump(optimizeData.loopConfig, { lineWidth: -1 }),
      'yaml',
      platformCfg
    ));
  }

  // Section 6: Configuration
  if (optimizeData.config) {
    sections.push(formatSectionHeader('Configuration', 3, platformCfg));
    sections.push(formatCodeBlock(
      yaml.dump(optimizeData.config, { lineWidth: -1 }),
      'yaml',
      platformCfg
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
 * Embed shared resources into template.
 *
 * Maps the actual field names returned by reader.js `readSharedResources()`:
 *   { securityPatterns, selfReview, evolution, useToEvolve,
 *     convergence, sessionArtifact, editAudit, skillRegistry }
 *
 * Prior to v3.1.0 this function referenced non-existent keys
 * (security, utils, helpers, config), causing all companion file content
 * to be silently dropped from every platform build output. Fixed in v3.1.0.
 *
 * @param {string} template - Platform template string
 * @param {Object} sharedData - Shared resources data from readSharedResources()
 * @param {Object} [sharedData.securityPatterns] - CWE + OWASP ASI patterns
 * @param {Object} [sharedData.selfReview]       - 3-pass self-review protocol
 * @param {Object} [sharedData.evolution]        - 3-trigger evolution spec
 * @param {Object} [sharedData.useToEvolve]      - UTE 2.0 L1/L2 spec
 * @param {Object} [sharedData.convergence]      - Convergence detection rules
 * @param {Object} [sharedData.sessionArtifact]  - Session artifact schema (COLLECT)
 * @param {Object} [sharedData.editAudit]        - Edit Audit Guard spec
 * @param {Object} [sharedData.skillRegistry]    - Skill Registry spec (SHARE)
 * @returns {string} Template with shared resources embedded
 */
function embedSharedResources(template, sharedData) {
  const platformCfg = DEFAULT_CONFIG;

  // Build shared resources section
  const sections = [];

  // Section 1: Header
  sections.push(formatSectionHeader('Shared Resources', 2, platformCfg));
  sections.push('Common patterns, utilities, and security checks used across all modes.');

  // Map from actual reader.js field names → display labels.
  // Order matters: security and self-review come first as they are referenced
  // by CREATE, EVALUATE, and OPTIMIZE before the collective evolution refs.
  const sectionMap = [
    { key: 'securityPatterns', label: 'Security Patterns (CWE + OWASP ASI)' },
    { key: 'selfReview',       label: 'Self-Review Protocol' },
    { key: 'evolution',        label: 'Evolution Spec' },
    { key: 'useToEvolve',      label: 'Use-to-Evolve (UTE) Spec' },
    { key: 'convergence',      label: 'Convergence Detection' },
    { key: 'sessionArtifact',  label: 'Session Artifact Schema (COLLECT)' },
    { key: 'editAudit',        label: 'Edit Audit Guard' },
    { key: 'skillRegistry',    label: 'Skill Registry (SHARE)' },
  ];

  for (const { key, label } of sectionMap) {
    if (sharedData[key]) {
      sections.push(formatSectionHeader(label, 3, platformCfg));
      sections.push(extractContent(sharedData[key]));
    }
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
  } else if (_templateCache.has(platform)) {
    template = _templateCache.get(platform);
  } else {
    // Try to load platform-specific template (read once, then cache)
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
      console.warn(`Could not load platform template for ${platform} (${error.message}), using default`);
      template = getDefaultTemplate(platform);
    }
    _templateCache.set(platform, template);
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
    const skillVersion = coreData.metadata.version || '3.1.0';
    const extra = coreData.metadata.extra || {};
    const fmData = {
      name: coreData.metadata.name || 'unnamed-skill',
      version: skillVersion,
      description: coreData.metadata.description || '',
      platform: platform,
      created: today,
      updated: today,
      // v3.1.0: three-tier hierarchy (SkillX arxiv:2604.04804)
      // Values: 'planning' | 'functional' | 'atomic' | null (unclassified)
      skill_tier: extra.skill_tier || null,
      // v3.1.0: trigger phrases for skill routing (SkillRouter arxiv:2603.22455)
      // 3–8 EN phrases + 2–5 ZH phrases; decisive routing signal
      triggers: extra.triggers || { en: [], zh: [] },
      interface: {
        modes: extra.modes || coreData.metadata.modes || ['create', 'evaluate', 'optimize'],
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
      // Spread remaining extra fields last (allows overrides)
      ...Object.fromEntries(
        Object.entries(extra).filter(([k]) => !['skill_tier', 'triggers', 'modes'].includes(k))
      ),
    };
    // formatFrontmatter() now throws on yaml.dump failure (no silent null return).
    // Catch and re-wrap with EINVALID_FRONTMATTER + actionable context.
    try {
      frontmatter = formatFrontmatter(fmData, config);
    } catch (fmError) {
      let metadataKeys = '(unavailable)';
      try { metadataKeys = Object.keys(fmData).join(', '); } catch {}
      throw new Error(
        '[EINVALID_FRONTMATTER] frontmatter generation failed for platform "' + platform + '" — ' +
        'ensure all metadata values are YAML-serializable (no circular references, functions, or undefined). ' +
        'Metadata keys present: ' + metadataKeys
      );
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

  const uteSection = `\n---\n\n## §UTE Use-to-Evolve\n\n<!-- Post-invocation hook — auto-managed by skill-writer v3.1.0 -->\n<!-- skill: ${name} | version: ${version} | injected: ${today} -->\n\nAfter each invocation, increment \`use_to_evolve.cumulative_invocations\`.\nRun lightweight LEAN check every 10 invocations; full re-score every 50;\ntier-drift detection every 100.\n\n**Fields managed automatically** (do not edit manually):\n- \`cumulative_invocations\` — incremented each use\n- \`last_ute_check\` — ISO date of last lightweight check\n- \`pending_patches\` — count of queued micro-patches\n- \`total_micro_patches_applied\` — lifetime patch count\n`;

  return content + uteSection;
}

/**
 * Get default template for platform
 * @param {string} platform - Platform name
 * @returns {string} Default template
 */
function getDefaultTemplate(platform) {
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

  // Check for remaining placeholders (use extended pattern to catch {{OUTER-KEY}} and {{outer.key}})
  const placeholderMatches = content.match(/\{\{[\w.-]+\}\}/g);
  if (placeholderMatches) {
    issues.push({
      type: 'warning',
      message: `Unreplaced placeholders found: ${[...new Set(placeholderMatches)].join(', ')}`,
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
 * Returns all occurrences including duplicates (use Set on result to deduplicate).
 * @param {string} template - Template string
 * @param {Object} [platformConfig] - Optional platform config with placeholderPattern
 * @returns {string[]} Array of placeholder names (with duplicates)
 */
function extractPlaceholders(template, platformConfig) {
  const placeholders = [];
  // Use extended pattern by default so {{OUTER-KEY}} and {{outer.key}} are captured
  const sourcePattern = platformConfig && platformConfig.placeholderPattern
    ? platformConfig.placeholderPattern
    : config.PLACEHOLDERS.extended;
  // Clone regex to avoid shared lastIndex state
  const pattern = new RegExp(sourcePattern.source, 'g');
  let match;

  while ((match = pattern.exec(template)) !== null) {
    placeholders.push(match[1]);
  }

  return placeholders;
}

/**
 * Apply platform-specific post-processing transforms.
 *
 * INTENDED USE: External utility for callers that have a pre-built Markdown string
 * and need platform-specific adjustments AFTER all placeholder substitutions are done
 * (e.g., post-processing a skill loaded from disk, or in a custom build pipeline).
 *
 * NOT called by generateSkillFile() — the standard build pipeline delegates all
 * platform-specific formatting to formatSkill() on each platform adapter instead.
 * This function is intentionally exported for programmatic API consumers; it is not
 * dead code, but it also should not be wired into the main build path.
 *
 * @param {string} content - Content to transform (all {{PLACEHOLDER}}s already replaced)
 * @param {string} platform - Target platform name
 * @returns {string} Transformed content
 */
function applyPlatformTransforms(content, platform) {
  const platformConfig = getPlatformConfig(platform);
  let result = content;

  switch (platform.toLowerCase()) {
    case 'cursor':
      // Cursor uses ${KEY} syntax. Convert any remaining {{KEY}} markers that were
      // intentionally left (e.g. UTE snippet placeholders filled at install time).
      // This is safe here because all build-time substitutions are already done.
      result = result.replace(/\{\{([\w.-]+)\}\}/g, '${$1}');
      break;

    case 'openai':
      // OpenAI adapter prefers JSON-embedded frontmatter for API consumption
      if (!platformConfig.supportsFrontmatter) {
        result = convertFrontmatterToJSON(result);
      }
      break;

    case 'gemini':
      result = ensureGeminiFormatting(result);
      break;

    default:
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
  extractPlaceholders,
  formatSectionHeader,
  formatCodeBlock,
  formatFrontmatter,
  validateEmbeddedContent,
  applyPlatformTransforms,

  // Constants (PLATFORM_CONFIGS is an alias to config.PLATFORMS for backward compat)
  PLATFORM_CONFIGS,
  DEFAULT_CONFIG,
};
