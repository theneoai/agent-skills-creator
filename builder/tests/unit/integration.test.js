/**
 * Build Pipeline Integration Tests
 *
 * End-to-end tests for the full reader → embedder → adapter pipeline.
 * These tests exercise real source files from the project root, so they
 * serve both as regression guards and living documentation of the expected
 * build contract.
 */

const path = require('path');
const { readAllCoreData } = require('../../src/core/reader');
const { generateSkillFile, validateEmbeddedContent } = require('../../src/core/embedder');
const platforms = require('../../src/platforms');

// Shared metadata injected into every generateSkillFile call (mirrors build.js)
const TEST_METADATA = {
  TITLE: 'Skill Writer',
  TYPE: 'Meta-Skill',
  VERSION: '2.2.0',
  DESCRIPTION: 'Integration test build',
  TRIGGERS: '- test trigger',
  name: 'skill-writer',
  version: '2.2.0',
  description: 'Integration test build',
  author: 'test',
  license: 'MIT',
  tags: ['meta-skill'],
  modes: ['create', 'lean', 'evaluate', 'optimize', 'install'],
  defaultMode: 'create',
  extra: { modes: ['create', 'lean', 'evaluate', 'optimize', 'install'] },
  p0_count: 0,
  p1_count: 0,
  p2_count: 0,
  p3_count: 0,
  generated_at: new Date().toISOString(),
};

// Markdown platforms that emit .md output
const MD_PLATFORMS = ['opencode', 'openclaw', 'claude', 'cursor', 'gemini'];
// JSON platforms that emit JSON output
const JSON_PLATFORMS = ['openai', 'mcp'];

describe('Reader — readAllCoreData()', () => {
  let coreData;

  beforeAll(async () => {
    coreData = await readAllCoreData();
  }, 30000);

  test('returns all top-level keys', () => {
    expect(coreData).toHaveProperty('create');
    expect(coreData).toHaveProperty('evaluate');
    expect(coreData).toHaveProperty('optimize');
    expect(coreData).toHaveProperty('shared');
    expect(coreData).toHaveProperty('metadata');
  });

  test('create.templates is populated', () => {
    expect(typeof coreData.create.templates).toBe('object');
    expect(Object.keys(coreData.create.templates).length).toBeGreaterThan(0);
  });

  test('evaluate.rubrics has content', () => {
    expect(coreData.evaluate.rubrics).not.toBeNull();
    expect(coreData.evaluate.rubrics.content.length).toBeGreaterThan(100);
  });

  test('optimize.strategies has content', () => {
    expect(coreData.optimize.strategies).not.toBeNull();
    expect(coreData.optimize.strategies.content.length).toBeGreaterThan(100);
  });

  test('shared.securityPatterns has content', () => {
    expect(coreData.shared.securityPatterns).not.toBeNull();
    expect(coreData.shared.securityPatterns.content.length).toBeGreaterThan(100);
  });

  test('metadata.version matches package.json', () => {
    const pkg = require('../../package.json');
    expect(coreData.metadata.version).toBe(pkg.version);
  });
});

describe('generateSkillFile() — core pipeline', () => {
  let coreData;

  beforeAll(async () => {
    coreData = await readAllCoreData();
  }, 30000);

  test('returns content and metadata for all platforms', () => {
    for (const platform of [...MD_PLATFORMS, ...JSON_PLATFORMS]) {
      const result = generateSkillFile(platform, { ...coreData, metadata: TEST_METADATA });
      expect(result).toHaveProperty('content');
      expect(result).toHaveProperty('metadata');
      expect(typeof result.content).toBe('string');
      expect(result.content.length).toBeGreaterThan(0);
    }
  });

  test('throws when coreData is null', () => {
    expect(() => generateSkillFile('claude', null)).toThrow();
  });

  test('throws when coreData is not an object', () => {
    expect(() => generateSkillFile('claude', 'string')).toThrow();
  });
});

describe('Full pipeline — Markdown platforms', () => {
  let coreData;

  beforeAll(async () => {
    coreData = await readAllCoreData();
  }, 30000);

  for (const platform of MD_PLATFORMS) {
    describe(`${platform}`, () => {
      let rawResult;
      let formattedContent;

      beforeAll(() => {
        rawResult = generateSkillFile(platform, { ...coreData, metadata: TEST_METADATA });
        formattedContent = platforms.formatForPlatform(platform, rawResult.content);
      });

      test('formatForPlatform returns a non-empty string', () => {
        expect(typeof formattedContent).toBe('string');
        expect(formattedContent.length).toBeGreaterThan(500);
      });

      test('validateEmbeddedContent reports no errors', () => {
        const validation = validateEmbeddedContent(formattedContent);
        const errors = validation.issues.filter(i => i.type === 'error');
        expect(errors).toHaveLength(0);
      });

      test('adapter validateSkill reports no errors', () => {
        const adapter = platforms.getPlatform(platform);
        const result = adapter.validateSkill(formattedContent);
        expect(result.errors).toHaveLength(0);
      });
    });
  }
});

describe('Full pipeline — JSON platforms', () => {
  let coreData;

  beforeAll(async () => {
    coreData = await readAllCoreData();
  }, 30000);

  for (const platform of JSON_PLATFORMS) {
    describe(`${platform}`, () => {
      let rawResult;
      let formattedContent;

      beforeAll(() => {
        rawResult = generateSkillFile(platform, { ...coreData, metadata: TEST_METADATA });
        formattedContent = platforms.formatForPlatform(platform, rawResult.content);
      });

      test('formatForPlatform returns valid JSON', () => {
        expect(() => JSON.parse(formattedContent)).not.toThrow();
      });

      test('adapter validateSkill reports no errors', () => {
        const adapter = platforms.getPlatform(platform);
        const result = adapter.validateSkill(formattedContent);
        expect(result.errors).toHaveLength(0);
      });

      test('parsed JSON has a name field', () => {
        const obj = JSON.parse(formattedContent);
        expect(obj.name).toBeDefined();
        expect(typeof obj.name).toBe('string');
      });
    });
  }
});

describe('Shared resources — content present in build output (BUG-1 regression guard)', () => {
  // This test suite guards against the BUG-1 regression where embedSharedResources()
  // used wrong field names and silently dropped all 8 companion files from every build.
  let coreData;

  beforeAll(async () => {
    coreData = await readAllCoreData();
  }, 30000);

  test('readAllCoreData includes all 8 companion resource fields', () => {
    const shared = coreData.shared;
    const expectedFields = [
      'securityPatterns', 'selfReview', 'evolution', 'useToEvolve',
      'convergence', 'sessionArtifact', 'editAudit', 'skillRegistry',
    ];
    expectedFields.forEach(field => {
      expect(shared[field]).toBeTruthy();
      expect(typeof shared[field].content).toBe('string');
      expect(shared[field].content.length).toBeGreaterThan(50);
    });
  });

  // Verify that the claude platform build output contains content from key companion files.
  // Security patterns content is a known string present in refs/security-patterns.md.
  test('claude build output contains security patterns content', () => {
    const result = generateSkillFile('claude', { ...coreData, metadata: TEST_METADATA });
    const formattedContent = platforms.formatForPlatform('claude', result.content);
    // Content from security-patterns.md should be embedded
    expect(formattedContent.toLowerCase()).toMatch(/cwe|owasp|security/);
  });

  test('claude build output contains self-review content', () => {
    const result = generateSkillFile('claude', { ...coreData, metadata: TEST_METADATA });
    const formattedContent = platforms.formatForPlatform('claude', result.content);
    // Content from self-review.md should be embedded
    expect(formattedContent.toLowerCase()).toMatch(/self.?review|loongflow|critique/i);
  });

  test('openai JSON build output contains embedded instructions with companion content', () => {
    const result = generateSkillFile('openai', { ...coreData, metadata: TEST_METADATA });
    const formattedContent = platforms.formatForPlatform('openai', result.content);
    const obj = JSON.parse(formattedContent);
    // The instructions field should have substantial content (companion files embedded)
    expect(obj.instructions.length).toBeGreaterThan(1000);
  });
});
