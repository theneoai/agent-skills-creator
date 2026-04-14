/**
 * Config Module Tests
 *
 * Tests for the centralized configuration module
 */

const path = require('path');
const config = require('../../src/config');

describe('Config Module', () => {
  describe('PATHS', () => {
    test('should export PATHS object with all required paths', () => {
      expect(config.PATHS).toBeDefined();
      expect(config.PATHS.root).toBeDefined();
      expect(config.PATHS.templates).toBeDefined();
      expect(config.PATHS.refs).toBeDefined();
      expect(config.PATHS.eval).toBeDefined();
      expect(config.PATHS.optimize).toBeDefined();
      expect(config.PATHS.platforms).toBeDefined();
      expect(config.PATHS.skillFramework).toBeDefined();
    });

    test('paths should be absolute', () => {
      expect(path.isAbsolute(config.PATHS.root)).toBe(true);
      expect(path.isAbsolute(config.PATHS.templates)).toBe(true);
      expect(path.isAbsolute(config.PATHS.refs)).toBe(true);
      expect(path.isAbsolute(config.PATHS.eval)).toBe(true);
      expect(path.isAbsolute(config.PATHS.optimize)).toBe(true);
      expect(path.isAbsolute(config.PATHS.platforms)).toBe(true);
    });

    test('sub-paths should be children of root', () => {
      expect(config.PATHS.templates.startsWith(config.PATHS.root)).toBe(true);
      expect(config.PATHS.refs.startsWith(config.PATHS.root)).toBe(true);
    });
  });

  describe('REQUIRED_FILES', () => {
    test('should export REQUIRED_FILES array', () => {
      expect(Array.isArray(config.REQUIRED_FILES)).toBe(true);
      expect(config.REQUIRED_FILES.length).toBeGreaterThan(0);
    });

    test('each file should have path, label, and mustEmbed properties', () => {
      config.REQUIRED_FILES.forEach(file => {
        expect(file.path).toBeDefined();
        expect(file.label).toBeDefined();
        expect(typeof file.mustEmbed).toBe('boolean');
      });
    });

    test('should include all critical companion files', () => {
      const labels = config.REQUIRED_FILES.map(f => f.label);
      expect(labels).toContain('refs/self-review.md');
      expect(labels).toContain('refs/security-patterns.md');
      expect(labels).toContain('eval/rubrics.md');
      expect(labels).toContain('optimize/strategies.md');
      // v3.0 additions
      expect(labels).toContain('refs/session-artifact.md');
      expect(labels).toContain('refs/edit-audit.md');
      expect(labels).toContain('refs/skill-registry.md');
    });

    test('all file paths should be absolute', () => {
      config.REQUIRED_FILES.forEach(file => {
        expect(path.isAbsolute(file.path)).toBe(true);
      });
    });
  });

  describe('REQUIRED_UTE_FIELDS', () => {
    test('should export REQUIRED_UTE_FIELDS array', () => {
      expect(Array.isArray(config.REQUIRED_UTE_FIELDS)).toBe(true);
      expect(config.REQUIRED_UTE_FIELDS).toContain('enabled');
      expect(config.REQUIRED_UTE_FIELDS).toContain('injected_by');
      expect(config.REQUIRED_UTE_FIELDS).toContain('cumulative_invocations');
    });

    test('should have 11 required UTE fields', () => {
      expect(config.REQUIRED_UTE_FIELDS.length).toBe(11);
    });
  });

  describe('AUTHOR_PLACEHOLDERS', () => {
    test('should export AUTHOR_PLACEHOLDERS as a Set', () => {
      expect(config.AUTHOR_PLACEHOLDERS).toBeInstanceOf(Set);
      expect(config.AUTHOR_PLACEHOLDERS.size).toBeGreaterThan(0);
    });

    test('should contain known author-time template placeholders', () => {
      expect(config.AUTHOR_PLACEHOLDERS.has('PLACEHOLDER')).toBe(true);
      expect(config.AUTHOR_PLACEHOLDERS.has('SKILL_NAME')).toBe(true);
      expect(config.AUTHOR_PLACEHOLDERS.has('STEP_1_NAME')).toBe(true);
      expect(config.AUTHOR_PLACEHOLDERS.has('WORKFLOW_NAME')).toBe(true);
    });

    test('should NOT contain build-time placeholders', () => {
      expect(config.AUTHOR_PLACEHOLDERS.has('FRAMEWORK_VERSION')).toBe(false);
      expect(config.AUTHOR_PLACEHOLDERS.has('INJECTION_DATE')).toBe(false);
      expect(config.AUTHOR_PLACEHOLDERS.has('BUILD_DATE')).toBe(false);
    });
  });

  describe('PLACEHOLDERS', () => {
    test('should export PLACEHOLDERS with extended and cursor patterns (standard merged into extended)', () => {
      // PLACEHOLDERS.standard was removed — extended is a strict superset and the canonical pattern.
      expect(config.PLACEHOLDERS.standard).toBeUndefined();
      expect(config.PLACEHOLDERS.extended).toBeInstanceOf(RegExp);
      expect(config.PLACEHOLDERS.cursor).toBeInstanceOf(RegExp);
    });

    test('extended pattern should match {{KEY}} format (uppercase — formerly "standard")', () => {
      expect('{{NAME}}'.match(config.PLACEHOLDERS.extended)).not.toBeNull();
      expect('{{VERSION}}'.match(config.PLACEHOLDERS.extended)).not.toBeNull();
      expect('not a placeholder'.match(config.PLACEHOLDERS.extended)).toBeNull();
    });

    test('extended pattern should also match {{OUTER-KEY}} and {{outer.key}}', () => {
      expect('{{OUTER-KEY}}'.match(config.PLACEHOLDERS.extended)).not.toBeNull();
      expect('{{outer.key}}'.match(config.PLACEHOLDERS.extended)).not.toBeNull();
      expect('{{KEY}}'.match(config.PLACEHOLDERS.extended)).not.toBeNull();
    });

    test('cursor pattern should match ${KEY} format', () => {
      expect('${NAME}'.match(config.PLACEHOLDERS.cursor)).not.toBeNull();
      expect('{{NAME}}'.match(config.PLACEHOLDERS.cursor)).toBeNull();
    });
  });

  describe('PLATFORMS', () => {
    test('should export all 7 platform configs (including mcp)', () => {
      expect(config.PLATFORMS.opencode).toBeDefined();
      expect(config.PLATFORMS.openclaw).toBeDefined();
      expect(config.PLATFORMS.claude).toBeDefined();
      expect(config.PLATFORMS.cursor).toBeDefined();
      expect(config.PLATFORMS.openai).toBeDefined();
      expect(config.PLATFORMS.gemini).toBeDefined();
      expect(config.PLATFORMS.mcp).toBeDefined();
    });

    test('each platform should have required properties', () => {
      Object.values(config.PLATFORMS).forEach(platform => {
        expect(platform.name).toBeDefined();
        expect(platform.placeholderPattern).toBeInstanceOf(RegExp);
        expect(typeof platform.supportsFrontmatter).toBe('boolean');
        expect(platform.sectionPrefix).toBeDefined();
      });
    });

    test('non-cursor platforms should use extended placeholder pattern', () => {
      const nonCursorPlatforms = ['opencode', 'openclaw', 'claude', 'openai', 'gemini', 'mcp'];
      nonCursorPlatforms.forEach(name => {
        const pattern = config.PLATFORMS[name].placeholderPattern;
        // Extended pattern matches hyphens and dots
        expect('{{OUTER-KEY}}'.match(pattern)).not.toBeNull();
      });
    });

    test('cursor platform should use ${} placeholder pattern', () => {
      const pattern = config.PLATFORMS.cursor.placeholderPattern;
      expect('${KEY}'.match(pattern)).not.toBeNull();
      expect('{{KEY}}'.match(pattern)).toBeNull();
    });

    test('mcp platform should not support frontmatter (uses JSON manifest)', () => {
      expect(config.PLATFORMS.mcp.supportsFrontmatter).toBe(false);
    });
  });

  describe('SCORING', () => {
    test('should export lean scoring configuration', () => {
      expect(config.SCORING.lean.maxScore).toBe(500);
      expect(config.SCORING.lean.dimensions).toBe(7);
      expect(config.SCORING.lean.passThreshold).toBe(350);
    });

    test('should export evaluate scoring configuration', () => {
      expect(config.SCORING.evaluate.maxScore).toBe(1000);
      expect(config.SCORING.evaluate.bronzeThreshold).toBe(700);
      expect(config.SCORING.evaluate.platinumThreshold).toBe(950);
    });

    test('should export variance gates', () => {
      expect(config.SCORING.varianceGates.platinum).toBe(10);
      expect(config.SCORING.varianceGates.gold).toBe(15);
    });

    test('should export unified 8-dimension schema (7 core + D8 composability)', () => {
      expect(config.SCORING.dimensions).toBeDefined();
      const dims = Object.keys(config.SCORING.dimensions);
      // v3.2.0: 8 dimensions — 7 core (D1-D7) + D8 Composability (GoS bonus)
      expect(dims).toHaveLength(8);
      expect(dims).toContain('systemDesign');
      expect(dims).toContain('domainKnowledge');
      expect(dims).toContain('workflow');
      expect(dims).toContain('errorHandling');
      expect(dims).toContain('examples');
      expect(dims).toContain('security');
      expect(dims).toContain('metadata');
      expect(dims).toContain('composability');
    });

    test('dimension weights should sum to 1.0', () => {
      const totalWeight = Object.values(config.SCORING.dimensions)
        .reduce((sum, d) => sum + d.weight, 0);
      expect(totalWeight).toBeCloseTo(1.0, 5);
    });

    test('core dimension leanMax scores (D1-D7) should sum to 500', () => {
      // v3.2.0: D8 composability adds up to 20 bonus pts; core D1-D7 still sum to 500.
      const coreDims = Object.entries(config.SCORING.dimensions)
        .filter(([key]) => key !== 'composability');
      const totalLean = coreDims.reduce((sum, [, d]) => sum + d.leanMax, 0);
      expect(totalLean).toBe(500);
    });

    test('D8 composability leanMax should be 20 (bonus dimension)', () => {
      const d8 = config.SCORING.dimensions.composability;
      expect(d8).toBeDefined();
      expect(d8.leanMax).toBe(20);
      expect(d8.weight).toBe(0.00); // Phase 2 weight 0; scored in Phase 5 (v4.0+)
    });

    test('each dimension should have label, weight, leanMax, strategies', () => {
      Object.entries(config.SCORING.dimensions).forEach(([key, dim]) => {
        expect(typeof dim.label).toBe('string');
        expect(typeof dim.weight).toBe('number');
        expect(typeof dim.leanMax).toBe('number');
        expect(Array.isArray(dim.strategies)).toBe(true);
      });
    });

    test('should export convergence threshold', () => {
      expect(typeof config.SCORING.convergenceThreshold).toBe('number');
      expect(config.SCORING.convergenceThreshold).toBeGreaterThan(0);
    });
  });

  describe('ERROR_CODES', () => {
    test('should export error codes', () => {
      expect(config.ERROR_CODES.MISSING_PLACEHOLDER).toBe('EMISSING_PLACEHOLDER');
      expect(config.ERROR_CODES.EMBED_FAILED).toBe('EEMBED_FAILED');
      expect(config.ERROR_CODES.VALIDATION_FAILED).toBe('EVALIDATION_FAILED');
    });
  });

  describe('JSON_OUTPUT_PLATFORMS (SSOT)', () => {
    test('should export JSON_OUTPUT_PLATFORMS as a Set', () => {
      expect(config.JSON_OUTPUT_PLATFORMS).toBeInstanceOf(Set);
    });

    test('should contain openai, mcp, and a2a', () => {
      expect(config.JSON_OUTPUT_PLATFORMS.has('openai')).toBe(true);
      expect(config.JSON_OUTPUT_PLATFORMS.has('mcp')).toBe(true);
      expect(config.JSON_OUTPUT_PLATFORMS.has('a2a')).toBe(true);
    });

    test('should contain exactly 3 platforms', () => {
      expect(config.JSON_OUTPUT_PLATFORMS.size).toBe(3);
    });

    test('should NOT contain markdown platforms', () => {
      expect(config.JSON_OUTPUT_PLATFORMS.has('claude')).toBe(false);
      expect(config.JSON_OUTPUT_PLATFORMS.has('opencode')).toBe(false);
      expect(config.JSON_OUTPUT_PLATFORMS.has('openclaw')).toBe(false);
      expect(config.JSON_OUTPUT_PLATFORMS.has('cursor')).toBe(false);
      expect(config.JSON_OUTPUT_PLATFORMS.has('gemini')).toBe(false);
    });
  });
});
