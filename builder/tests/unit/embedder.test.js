/**
 * Embedder Module Tests
 *
 * Tests for the embedder module including strict mode, extended regex,
 * and platform config resolution.
 */

const embedder = require('../../src/core/embedder');
const config = require('../../src/config');

describe('Embedder Module', () => {
  describe('getPlatformConfig', () => {
    test('should return config for all known platforms', () => {
      const platforms = ['opencode', 'openclaw', 'claude', 'cursor', 'openai', 'gemini', 'mcp'];
      platforms.forEach(name => {
        const cfg = embedder.getPlatformConfig(name);
        expect(cfg).toBeDefined();
        expect(cfg.name).toBe(name);
      });
    });

    test('should return default config for unknown platforms', () => {
      const unknown = embedder.getPlatformConfig('unknown');
      expect(unknown).toBeDefined();
      expect(unknown.name).toBe('opencode'); // Default falls back to opencode
    });

    test('should be case insensitive', () => {
      const lower = embedder.getPlatformConfig('claude');
      const upper = embedder.getPlatformConfig('CLAUDE');
      expect(lower.name).toBe(upper.name);
    });

    test('should reference config.PLATFORMS (no duplication)', () => {
      // Verify embedder uses canonical config — not a private copy
      const fromEmbedder = embedder.getPlatformConfig('opencode');
      const fromConfig = config.PLATFORMS.opencode;
      expect(fromEmbedder).toBe(fromConfig);
    });
  });

  describe('replacePlaceholders', () => {
    // PLACEHOLDERS.standard was merged into extended (extended is a strict superset).
    const standardConfig = { placeholderPattern: config.PLACEHOLDERS.extended };
    const extendedConfig = { placeholderPattern: config.PLACEHOLDERS.extended };
    const cursorConfig = { placeholderPattern: config.PLACEHOLDERS.cursor };

    test('should replace standard placeholders with data values', () => {
      const template = 'Hello {{NAME}}, version {{VERSION}}';
      const data = { NAME: 'Test', VERSION: '1.0.0' };
      const result = embedder.replacePlaceholders(template, data, standardConfig);
      expect(result).toBe('Hello Test, version 1.0.0');
    });

    test('should replace extended placeholders ({{OUTER-KEY}}, {{outer.key}})', () => {
      const template = 'key={{OUTER-KEY}} dot={{outer.key}}';
      const data = { 'OUTER-KEY': 'value1', 'outer.key': 'value2' };
      const result = embedder.replacePlaceholders(template, data, extendedConfig);
      expect(result).toBe('key=value1 dot=value2');
    });

    test('should replace cursor-style placeholders', () => {
      const template = 'Hello ${NAME}';
      const data = { NAME: 'World' };
      const result = embedder.replacePlaceholders(template, data, cursorConfig);
      expect(result).toBe('Hello World');
    });

    test('should keep original placeholder when value missing (non-strict)', () => {
      const template = 'Hello {{NAME}}, missing {{MISSING}}';
      const data = { NAME: 'Test' };
      const result = embedder.replacePlaceholders(template, data, standardConfig);
      expect(result).toBe('Hello Test, missing {{MISSING}}');
    });

    test('should throw error in strict mode when placeholder missing', () => {
      const template = 'Hello {{NAME}}, missing {{MISSING}}';
      const data = { NAME: 'Test' };
      expect(() => {
        embedder.replacePlaceholders(template, data, standardConfig, { strict: true });
      }).toThrow(config.ERROR_CODES.MISSING_PLACEHOLDER);
    });

    test('should include placeholder key in strict-mode error message', () => {
      const template = 'Missing {{MISSING_KEY}}';
      const data = {};
      expect(() => {
        embedder.replacePlaceholders(template, data, standardConfig, { strict: true });
      }).toThrow('MISSING_KEY');
    });

    test('should treat null values as missing in strict mode', () => {
      const template = 'Value: {{NULL_VAL}}';
      const data = { NULL_VAL: null };
      expect(() => {
        embedder.replacePlaceholders(template, data, standardConfig, { strict: true });
      }).toThrow(config.ERROR_CODES.MISSING_PLACEHOLDER);
    });

    test('should allow empty string values (not missing)', () => {
      const template = 'Value: {{EMPTY}}';
      const data = { EMPTY: '' };
      const result = embedder.replacePlaceholders(template, data, standardConfig, { strict: true });
      expect(result).toBe('Value: ');
    });

    test('should default to non-strict mode', () => {
      const template = 'Missing {{MISSING}}';
      const data = {};
      expect(() => {
        embedder.replacePlaceholders(template, data, standardConfig);
      }).not.toThrow();
    });
  });

  describe('extractPlaceholders', () => {
    test('should extract all placeholder occurrences including duplicates', () => {
      const template = '{{NAME}} {{VERSION}} {{NAME}}';
      const result = embedder.extractPlaceholders(template);
      expect(result).toContain('NAME');
      expect(result).toContain('VERSION');
      expect(result.length).toBe(3); // Includes duplicates
    });

    test('should return empty array when no placeholders present', () => {
      const template = 'No placeholders here';
      const result = embedder.extractPlaceholders(template);
      expect(result).toEqual([]);
    });

    test('should accept optional platformConfig with custom pattern', () => {
      const template = '${KEY1} ${KEY2}';
      const cursorConfig = { placeholderPattern: config.PLACEHOLDERS.cursor };
      const result = embedder.extractPlaceholders(template, cursorConfig);
      expect(result).toContain('KEY1');
      expect(result).toContain('KEY2');
      expect(result.length).toBe(2);
    });

    test('should use extended pattern by default (catches {{OUTER-KEY}})', () => {
      const template = '{{OUTER-KEY}} {{outer.key}} {{NORMAL}}';
      const result = embedder.extractPlaceholders(template);
      expect(result).toContain('OUTER-KEY');
      expect(result).toContain('outer.key');
      expect(result).toContain('NORMAL');
    });

    test('deduplicated set from result should have unique names', () => {
      const template = '{{NAME}} {{NAME}} {{OTHER}}';
      const result = embedder.extractPlaceholders(template);
      const unique = [...new Set(result)];
      expect(unique).toHaveLength(2);
      expect(unique).toContain('NAME');
      expect(unique).toContain('OTHER');
    });
  });

  describe('formatFrontmatter', () => {
    test('should format object as YAML frontmatter', () => {
      const data = { name: 'test-skill', version: '1.0.0' };
      const platformConfig = config.PLATFORMS.opencode;
      const result = embedder.formatFrontmatter(data, platformConfig);
      expect(result).toContain('---');
      expect(result).toContain('name: test-skill');
      expect(result).toContain('version: 1.0.0');
    });

    test('should return null when platform does not support frontmatter', () => {
      const data = { name: 'test' };
      const cursorConfig = config.PLATFORMS.cursor;
      const result = embedder.formatFrontmatter(data, cursorConfig);
      expect(result).toBeNull();
    });

    test('should handle empty object', () => {
      const result = embedder.formatFrontmatter({}, config.PLATFORMS.opencode);
      expect(result).toContain('---');
    });
  });

  describe('injectUTESection', () => {
    test('should inject §UTE section when absent', () => {
      const content = '# Skill\n\nSome content';
      const result = embedder.injectUTESection(content, { name: 'test', version: '1.0.0' });
      expect(result).toContain('§UTE Use-to-Evolve');
      expect(result).toContain('cumulative_invocations');
    });

    test('should not duplicate §UTE section if already present', () => {
      const content = '# Skill\n\n## §UTE Use-to-Evolve\n\nAlready here';
      const result = embedder.injectUTESection(content, { name: 'test' });
      const count = (result.match(/§UTE/g) || []).length;
      expect(count).toBe(1);
    });
  });

  describe('embedSharedResources — correct field names (BUG-1 regression guard)', () => {
    // This block tests that embedSharedResources() maps the ACTUAL keys returned by
    // readSharedResources() (reader.js), not the old wrong keys (security/utils/helpers/config).
    // Signature: embedSharedResources(template: string, sharedData: object): string

    test('embedSharedResources should be exported', () => {
      expect(typeof embedder.embedSharedResources).toBe('function');
    });

    test('should embed content when sharedData uses the correct field names', () => {
      const template = '# Skill\n\nBody content here.\n';
      const sharedData = {
        securityPatterns: { content: '# Security Patterns\n\nContent here.' },
        selfReview:       { content: '# Self-Review\n\nContent here.' },
        evolution:        { content: '# Evolution\n\nContent here.' },
        useToEvolve:      { content: '# UTE\n\nContent here.' },
        convergence:      { content: '# Convergence\n\nContent here.' },
        sessionArtifact:  { content: '# Session Artifact\n\nContent here.' },
        editAudit:        { content: '# Edit Audit\n\nContent here.' },
        skillRegistry:    { content: '# Skill Registry\n\nContent here.' },
      };
      const result = embedder.embedSharedResources(template, sharedData);
      // All 8 companion files should appear in output
      expect(result).toContain('Security Patterns');
      expect(result).toContain('Self-Review');
      expect(result).toContain('Evolution');
      expect(result).toContain('Session Artifact');
      expect(result).toContain('Edit Audit');
      expect(result).toContain('Skill Registry');
    });

    test('should NOT silently drop all content when old wrong keys are used', () => {
      // Confirm that the old wrong keys (security, utils, helpers, config) do NOT
      // accidentally produce content — this guards against the BUG-1 regression.
      const template = '# Skill\n\nBody.\n';
      const oldWrongData = {
        security: { content: 'old security content' },
        utils:    { content: 'old utils content' },
        helpers:  { content: 'old helpers content' },
        config:   { content: 'old config content' },
      };
      const result = embedder.embedSharedResources(template, oldWrongData);
      // Old wrong keys should produce NO section content from sectionMap
      expect(result).not.toContain('old security content');
      expect(result).not.toContain('old utils content');
    });

    test('should gracefully skip keys whose value is falsy', () => {
      const template = '# Skill\n\nBody.\n';
      const partialData = {
        securityPatterns: { content: '# Security\n\nHere.' },
        selfReview:       null,
        evolution:        undefined,
      };
      expect(() => embedder.embedSharedResources(template, partialData)).not.toThrow();
      const result = embedder.embedSharedResources(template, partialData);
      expect(result).toContain('Security');
    });
  });

  describe('validateEmbeddedContent', () => {
    test('should detect unbalanced code blocks', () => {
      const content = '# Title\n\n```\nopened but not closed';
      const result = embedder.validateEmbeddedContent(content);
      expect(result.valid).toBe(false);
      expect(result.issues.some(i => i.type === 'error')).toBe(true);
    });

    test('should pass clean content', () => {
      const content = '# Title\n\n```js\nconst x = 1;\n```\n\nDone.';
      const result = embedder.validateEmbeddedContent(content);
      expect(result.valid).toBe(true);
    });

    test('should warn on remaining placeholders', () => {
      const content = 'Value: {{UNREPLACED}}';
      const result = embedder.validateEmbeddedContent(content);
      expect(result.issues.some(i => i.type === 'warning')).toBe(true);
    });
  });

  // ── generateSkillFile error paths ─────────────────────────────────────────

  describe('generateSkillFile — EINVALID_FRONTMATTER (P0-1 regression guard)', () => {
    // NOTE: The throw is only reached when the template does NOT already have frontmatter
    // (all platform templates start with `---`, so we must supply a custom template without
    // frontmatter to force the generation code path and exercise the throw).
    const NO_FM_TEMPLATE = '# {{TITLE}}\n\nBody content here.\n';

    test('throws EINVALID_FRONTMATTER when metadata contains a circular reference', () => {
      // A circular reference causes yaml.dump() to throw, which makes formatFrontmatter()
      // return null, which should now throw (hard error) instead of silently producing
      // a skill file with missing frontmatter.
      const circular = {};
      circular.self = circular;

      const coreData = {
        template: NO_FM_TEMPLATE,
        metadata: {
          name: 'test-skill',
          version: '1.0.0',
          description: 'test',
          extra: { bad: circular }, // yaml.dump will throw on this
        },
      };

      expect(() => embedder.generateSkillFile('opencode', coreData))
        .toThrow('EINVALID_FRONTMATTER');
    });

    test('EINVALID_FRONTMATTER error message includes the platform name and metadata keys', () => {
      const circular = {};
      circular.ref = circular;
      const coreData = {
        template: NO_FM_TEMPLATE,
        metadata: { name: 'x', version: '1.0.0', extra: { x: circular } },
      };
      let message = '';
      try {
        embedder.generateSkillFile('gemini', coreData);
      } catch (e) {
        message = e.message;
      }
      expect(message).toContain('gemini');
      expect(message).toContain('Metadata keys present');
    });

    test('does NOT throw for platforms that do not require frontmatter (cursor)', () => {
      // cursor has supportsFrontmatter: false — the frontmatter code path is skipped entirely,
      // so even a circular reference in extra cannot trigger EINVALID_FRONTMATTER here.
      const circular = {};
      circular.ref = circular;
      const coreData = {
        template: NO_FM_TEMPLATE,
        metadata: { name: 'test-skill', version: '1.0.0', extra: { x: circular } },
      };
      expect(() => embedder.generateSkillFile('cursor', coreData)).not.toThrow();
    });
  });
});
