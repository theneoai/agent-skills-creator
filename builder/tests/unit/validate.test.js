/**
 * Validate Command Tests
 *
 * Tests for the validate command
 */

const fs = require('fs');
const path = require('path');
const os = require('os');
const {
  validate,
  validateRequiredFiles,
  validateTemplates,
  validateGeneratedSkills,
  validateSkillMdSpec,
  SKILLMD_SPEC,
} = require('../../src/commands/validate');
const config = require('../../src/config');

// Helper: create a temp directory with a mock .md skill file
function makeTempSkill(content, fileName = 'skill-writer-test.md') {
  const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'sw-validate-'));
  const filePath = path.join(tmpDir, fileName);
  fs.writeFileSync(filePath, content, 'utf8');
  return { tmpDir, filePath };
}

function makeResult() {
  return { valid: true, errors: 0, warnings: 0, issues: [] };
}

describe('Validate Command', () => {
  describe('validate', () => {
    test('should return validation result object', async () => {
      const result = await validate();
      expect(result).toHaveProperty('valid');
      expect(result).toHaveProperty('errors');
      expect(result).toHaveProperty('warnings');
      expect(result).toHaveProperty('issues');
      expect(Array.isArray(result.issues)).toBe(true);
    });

    test('should count errors and warnings', async () => {
      const result = await validate();
      expect(typeof result.errors).toBe('number');
      expect(typeof result.warnings).toBe('number');
      expect(result.errors).toBeGreaterThanOrEqual(0);
      expect(result.warnings).toBeGreaterThanOrEqual(0);
    });
  });

  describe('validateRequiredFiles', () => {
    test('should check all required files exist', async () => {
      const result = makeResult();
      await validateRequiredFiles(result);
      expect(result.issues.length).toBeGreaterThanOrEqual(0);
    });
  });

  describe('validateTemplates', () => {
    test('should check template placeholders', async () => {
      const result = makeResult();
      await validateTemplates(result);
      expect(result).toBeDefined();
    });
  });

  describe('validateGeneratedSkills', () => {
    test('should validate generated skill files', async () => {
      const result = makeResult();
      await validateGeneratedSkills(result);
      expect(result).toBeDefined();
    });
  });

  describe('SKILLMD_SPEC constants', () => {
    test('should export namePattern, nameMaxLen, descMaxLen, contentMaxLines', () => {
      expect(SKILLMD_SPEC.namePattern).toBeInstanceOf(RegExp);
      expect(SKILLMD_SPEC.nameMaxLen).toBe(64);
      expect(SKILLMD_SPEC.descMaxLen).toBe(1024);
      expect(SKILLMD_SPEC.contentMaxLines).toBe(500);
    });

    test('namePattern should accept valid names', () => {
      expect(SKILLMD_SPEC.namePattern.test('skill-writer')).toBe(true);
      expect(SKILLMD_SPEC.namePattern.test('api-tester')).toBe(true);
      expect(SKILLMD_SPEC.namePattern.test('a')).toBe(true);
      expect(SKILLMD_SPEC.namePattern.test('my-skill-v2')).toBe(true);
    });

    test('namePattern should reject invalid names', () => {
      expect(SKILLMD_SPEC.namePattern.test('-leading-hyphen')).toBe(false);
      expect(SKILLMD_SPEC.namePattern.test('trailing-hyphen-')).toBe(false);
      expect(SKILLMD_SPEC.namePattern.test('UPPERCASE')).toBe(false);
      expect(SKILLMD_SPEC.namePattern.test('has space')).toBe(false);
      expect(SKILLMD_SPEC.namePattern.test('under_score')).toBe(false);
    });
  });

  describe('validateSkillMdSpec', () => {
    // Override PATHS.platforms to point at our temp dir
    const origPlatforms = config.PATHS.platforms;

    afterEach(() => {
      config.PATHS.platforms = origPlatforms;
    });

    function makeValidFrontmatter(overrides = {}) {
      const name = overrides.name || 'my-skill';
      const desc = overrides.desc || 'A valid one-line description.';
      return `---\nname: ${name}\nversion: "1.0.0"\ndescription: "${desc}"\n---\n\n## §1 Overview\n\nContent here.\n`;
    }

    test('should pass for a spec-compliant skill file', async () => {
      const { tmpDir } = makeTempSkill(makeValidFrontmatter());
      config.PATHS.platforms = tmpDir;
      const result = makeResult();
      await validateSkillMdSpec(result);
      expect(result.errors).toBe(0);
      expect(result.warnings).toBe(0);
    });

    test('should error when skill name exceeds 64 chars', async () => {
      const longName = 'a'.repeat(65);
      const { tmpDir } = makeTempSkill(makeValidFrontmatter({ name: longName }));
      config.PATHS.platforms = tmpDir;
      const result = makeResult();
      await validateSkillMdSpec(result);
      expect(result.errors).toBeGreaterThan(0);
      expect(result.issues.some(i => i.message.includes('exceeds') && i.message.includes('char limit'))).toBe(true);
    });

    test('should error when skill name has leading hyphen', async () => {
      const { tmpDir } = makeTempSkill(makeValidFrontmatter({ name: '-bad-name' }));
      config.PATHS.platforms = tmpDir;
      const result = makeResult();
      await validateSkillMdSpec(result);
      expect(result.errors).toBeGreaterThan(0);
      expect(result.issues.some(i => i.message.includes('naming convention'))).toBe(true);
    });

    test('should error when skill name has consecutive hyphens', async () => {
      const { tmpDir } = makeTempSkill(makeValidFrontmatter({ name: 'bad--name' }));
      config.PATHS.platforms = tmpDir;
      const result = makeResult();
      await validateSkillMdSpec(result);
      expect(result.errors).toBeGreaterThan(0);
      expect(result.issues.some(i => i.message.includes('consecutive hyphens'))).toBe(true);
    });

    test('should error when description exceeds 1024 chars', async () => {
      const longDesc = 'x'.repeat(1025);
      const { tmpDir } = makeTempSkill(makeValidFrontmatter({ desc: longDesc }));
      config.PATHS.platforms = tmpDir;
      const result = makeResult();
      await validateSkillMdSpec(result);
      expect(result.errors).toBeGreaterThan(0);
      expect(result.issues.some(i => i.message.includes('description exceeds'))).toBe(true);
    });

    test('should warn when content exceeds 500 lines', async () => {
      const manyLines = makeValidFrontmatter() + '\n'.repeat(502);
      const { tmpDir } = makeTempSkill(manyLines);
      config.PATHS.platforms = tmpDir;
      const result = makeResult();
      await validateSkillMdSpec(result);
      expect(result.warnings).toBeGreaterThan(0);
      expect(result.issues.some(i => i.type === 'warning' && i.message.includes('lines exceeds'))).toBe(true);
    });

    test('should error when content exceeds 1000 lines', async () => {
      const manyLines = makeValidFrontmatter() + '\n'.repeat(1002);
      const { tmpDir } = makeTempSkill(manyLines);
      config.PATHS.platforms = tmpDir;
      const result = makeResult();
      await validateSkillMdSpec(result);
      expect(result.errors).toBeGreaterThan(0);
      expect(result.issues.some(i => i.type === 'error' && i.message.includes('excessive'))).toBe(true);
    });

    test('should parse frontmatter with Windows CRLF line endings', async () => {
      const crlfContent = '---\r\nname: my-skill\r\nversion: "1.0.0"\r\ndescription: "A valid description."\r\n---\r\n\r\n## §1 Overview\r\n';
      const { tmpDir } = makeTempSkill(crlfContent);
      config.PATHS.platforms = tmpDir;
      const result = makeResult();
      await validateSkillMdSpec(result);
      // Should correctly parse frontmatter and find no errors
      expect(result.errors).toBe(0);
    });

    test('should handle empty platforms directory gracefully', async () => {
      const emptyDir = fs.mkdtempSync(path.join(os.tmpdir(), 'sw-empty-'));
      config.PATHS.platforms = emptyDir;
      const result = makeResult();
      await expect(validateSkillMdSpec(result)).resolves.not.toThrow();
    });
  });
});
