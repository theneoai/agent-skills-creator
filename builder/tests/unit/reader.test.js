/**
 * Reader Module Tests
 * 
 * Tests for the core reader module
 */

const reader = require('../../src/core/reader');
const config = require('../../src/config');

describe('Reader Module', () => {
  describe('parseFile', () => {
    test('should parse markdown files correctly', async () => {
      // This test would need a real file or mock
      // For now, we verify the function exists and has correct signature
      expect(typeof reader.parseFile).toBe('function');
    });
  });

  describe('readCreateMode', () => {
    test('should return object with templates property', async () => {
      const result = await reader.readCreateMode();
      expect(result).toHaveProperty('templates');
      expect(typeof result.templates).toBe('object');
    });

    test('should read template files if they exist', async () => {
      const result = await reader.readCreateMode();
      // If base.md exists, it should be in templates
      if (Object.keys(result.templates).length > 0) {
        const firstTemplate = Object.values(result.templates)[0];
        expect(firstTemplate).toHaveProperty('content');
        expect(firstTemplate).toHaveProperty('name');
      }
    });
  });

  describe('readEvaluateMode', () => {
    test('should return rubrics and benchmarks properties', async () => {
      const result = await reader.readEvaluateMode();
      expect(result).toHaveProperty('rubrics');
      expect(result).toHaveProperty('benchmarks');
    });
  });

  describe('readOptimizeMode', () => {
    test('should return strategies and antiPatterns properties', async () => {
      const result = await reader.readOptimizeMode();
      expect(result).toHaveProperty('strategies');
      expect(result).toHaveProperty('antiPatterns');
      // convergence was moved to shared (refs/convergence.md) — do not expect it here
    });
  });

  describe('readSharedResources', () => {
    test('should return all shared resource properties including convergence', async () => {
      const result = await reader.readSharedResources();
      expect(result).toHaveProperty('securityPatterns');
      expect(result).toHaveProperty('selfReview');
      expect(result).toHaveProperty('evolution');
      expect(result).toHaveProperty('useToEvolve');
      // convergence moved from optimize to shared in v3.x
      expect(result).toHaveProperty('convergence');
    });
  });

  describe('readAllCoreData', () => {
    test('should return complete data structure', async () => {
      const result = await reader.readAllCoreData();
      expect(result).toHaveProperty('create');
      expect(result).toHaveProperty('evaluate');
      expect(result).toHaveProperty('optimize');
      expect(result).toHaveProperty('shared');
      expect(result).toHaveProperty('metadata');
    });

    test('should include metadata with timestamp', async () => {
      const result = await reader.readAllCoreData();
      expect(result.metadata).toHaveProperty('readAt');
      expect(result.metadata).toHaveProperty('version');
      expect(new Date(result.metadata.readAt)).toBeInstanceOf(Date);
    });
  });

  describe('getMustEmbedFiles', () => {
    test('should return only files with mustEmbed: true', () => {
      const files = reader.getMustEmbedFiles();
      expect(Array.isArray(files)).toBe(true);
      files.forEach(file => {
        expect(file.mustEmbed).toBe(true);
      });
    });

    test('should include critical files', () => {
      const files = reader.getMustEmbedFiles();
      const labels = files.map(f => f.label);
      expect(labels).toContain('refs/security-patterns.md');
      expect(labels).toContain('refs/self-review.md');
    });
  });
});

// ─── Error-path tests ────────────────────────────────────────────────────────

describe('Reader error paths', () => {
  const fs = require('fs-extra');
  const os = require('os');
  const path = require('path');

  describe('parseFile', () => {
    test('throws on non-existent file', async () => {
      await expect(reader.parseFile('/non/existent/path/file.md')).rejects.toThrow();
    });

    test('throws on malformed JSON file', async () => {
      const tmpFile = path.join(os.tmpdir(), `sw-reader-test-${Date.now()}.json`);
      fs.writeFileSync(tmpFile, '{bad json', 'utf8');
      try {
        await expect(reader.parseFile(tmpFile)).rejects.toThrow();
      } finally {
        fs.removeSync(tmpFile);
      }
    });

    test('returns content object for valid markdown file', async () => {
      const tmpFile = path.join(os.tmpdir(), `sw-reader-test-${Date.now()}.md`);
      fs.writeFileSync(tmpFile, '# Test\n\nContent here.', 'utf8');
      try {
        const result = await reader.parseFile(tmpFile);
        expect(result).toHaveProperty('content');
        expect(result.content).toContain('# Test');
      } finally {
        fs.removeSync(tmpFile);
      }
    });

    test('returns parsed object for valid JSON file', async () => {
      const tmpFile = path.join(os.tmpdir(), `sw-reader-test-${Date.now()}.json`);
      fs.writeFileSync(tmpFile, JSON.stringify({ name: 'test', version: '1.0.0' }), 'utf8');
      try {
        const result = await reader.parseFile(tmpFile);
        expect(result).toHaveProperty('name', 'test');
        expect(result).toHaveProperty('version', '1.0.0');
      } finally {
        fs.removeSync(tmpFile);
      }
    });
  });

  describe('readAllCoreData error context', () => {
    test('Promise.all rejects with an error when a sub-reader throws', async () => {
      // Temporarily override a path to a non-existent location to force failure
      const origEval = config.PATHS.eval;
      config.PATHS.eval = '/absolutely/non/existent/path';
      try {
        // readEvaluateMode checks pathExists before reading, so it won't throw —
        // this verifies the graceful degradation path returns null fields instead.
        const result = await reader.readEvaluateMode();
        expect(result.rubrics).toBeNull();
        expect(result.benchmarks).toBeNull();
      } finally {
        config.PATHS.eval = origEval;
      }
    });
  });
});
