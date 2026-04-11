/**
 * Frontmatter Utility Tests
 *
 * Tests for the shared frontmatter parsing utility (BUG-2 regression guard).
 * Verifies that parseFrontmatter(), hasFrontmatter(), stripFrontmatter(), and
 * the canonical FRONTMATTER_REGEX handle edge cases correctly — including the
 * optional trailing newline that caused silent failures in cursor/openai adapters.
 */

const {
  parseFrontmatter,
  hasFrontmatter,
  stripFrontmatter,
  FRONTMATTER_REGEX,
} = require('../../src/utils/frontmatter');

// ─── Test fixtures ───────────────────────��────────────────────���───────────────

const WITH_TRAILING_NL = `---
name: test-skill
version: 1.0.0
description: A test skill
---

## Body

Content here.
`;

const WITHOUT_TRAILING_NL = `---
name: test-skill
version: 1.0.0
description: A test skill
---
## Body

Content here.`;

const NO_FRONTMATTER = `# Just a heading

No YAML here.`;

// Note: needs an empty line between delimiters so the regex finds '\n---'
const EMPTY_FRONTMATTER = `---

---

Body content.`;

const NESTED_YAML = `---
name: nested-skill
version: 2.0.0
description: A skill with nested YAML
metadata:
  openclaw:
    format: agentskills
    compatibility: ["1.0", "2.0"]
---

Body here.
`;

// ─── FRONTMATTER_REGEX ───────────────────────────────────────────────────��───

describe('FRONTMATTER_REGEX', () => {
  test('should match frontmatter WITH trailing newline', () => {
    expect(FRONTMATTER_REGEX.test(WITH_TRAILING_NL)).toBe(true);
  });

  test('should match frontmatter WITHOUT trailing newline', () => {
    expect(FRONTMATTER_REGEX.test(WITHOUT_TRAILING_NL)).toBe(true);
  });

  test('should NOT match content with no frontmatter', () => {
    expect(FRONTMATTER_REGEX.test(NO_FRONTMATTER)).toBe(false);
  });

  test('captured group [1] should be the YAML body (without --- delimiters)', () => {
    const match = WITH_TRAILING_NL.match(FRONTMATTER_REGEX);
    expect(match).not.toBeNull();
    expect(match[1]).toContain('name: test-skill');
    expect(match[1]).not.toContain('---');
  });
});

// ─── hasFrontmatter ───────────────────────────────────────────────────────────

describe('hasFrontmatter()', () => {
  test('returns true for content with frontmatter (trailing newline)', () => {
    expect(hasFrontmatter(WITH_TRAILING_NL)).toBe(true);
  });

  test('returns true for content with frontmatter (no trailing newline)', () => {
    expect(hasFrontmatter(WITHOUT_TRAILING_NL)).toBe(true);
  });

  test('returns false for content without frontmatter', () => {
    expect(hasFrontmatter(NO_FRONTMATTER)).toBe(false);
  });

  test('returns false for empty string', () => {
    expect(hasFrontmatter('')).toBe(false);
  });

  test('returns false for null/undefined', () => {
    expect(hasFrontmatter(null)).toBe(false);
    expect(hasFrontmatter(undefined)).toBe(false);
  });
});

// ─── parseFrontmatter ─────────────────────────────���────────────────────────���──

describe('parseFrontmatter()', () => {
  test('returns correct fields for content with trailing newline', () => {
    const result = parseFrontmatter(WITH_TRAILING_NL);
    expect(result.frontmatterYaml).toBeTruthy();
    expect(result.frontmatterYaml).toContain('name: test-skill');
    expect(result.raw).toBeTruthy();
    expect(result.body).not.toContain('name: test-skill');
  });

  test('returns correct fields for content WITHOUT trailing newline (BUG-2 case)', () => {
    const result = parseFrontmatter(WITHOUT_TRAILING_NL);
    expect(result.frontmatterYaml).toBeTruthy();
    expect(result.frontmatterYaml).toContain('name: test-skill');
    expect(result.body).toContain('## Body');
  });

  test('parses nested YAML into frontmatterData object', () => {
    const result = parseFrontmatter(NESTED_YAML);
    expect(result.frontmatterData).toBeTruthy();
    expect(result.frontmatterData.name).toBe('nested-skill');
    expect(result.frontmatterData.metadata).toBeDefined();
    expect(result.frontmatterData.metadata.openclaw).toBeDefined();
  });

  test('returns null fields when no frontmatter present', () => {
    const result = parseFrontmatter(NO_FRONTMATTER);
    expect(result.frontmatterYaml).toBeNull();
    expect(result.frontmatterData).toBeNull();
    expect(result.raw).toBeNull();
    expect(result.body).toBe(NO_FRONTMATTER);
  });

  test('body does not include --- delimiters', () => {
    const result = parseFrontmatter(WITH_TRAILING_NL);
    expect(result.body).not.toMatch(/^---/m);
  });

  test('body starts with content after frontmatter (trailing-NL variant)', () => {
    const result = parseFrontmatter(WITH_TRAILING_NL);
    expect(result.body.trim()).toMatch(/^## Body/);
  });

  test('handles empty frontmatter gracefully', () => {
    const result = parseFrontmatter(EMPTY_FRONTMATTER);
    expect(result.frontmatterYaml).toBeDefined();
    expect(result.frontmatterData).toEqual({});
  });

  test('handles null/undefined input gracefully', () => {
    const nullResult = parseFrontmatter(null);
    expect(nullResult.frontmatterYaml).toBeNull();

    const undefResult = parseFrontmatter(undefined);
    expect(undefResult.frontmatterYaml).toBeNull();
  });
});

// ─── stripFrontmatter ─────────────────────────────────────────────────────────

describe('stripFrontmatter()', () => {
  test('removes frontmatter from content with trailing newline', () => {
    const stripped = stripFrontmatter(WITH_TRAILING_NL);
    expect(stripped).not.toContain('name: test-skill');
    expect(stripped).toContain('## Body');
  });

  test('removes frontmatter from content without trailing newline (BUG-2 case)', () => {
    const stripped = stripFrontmatter(WITHOUT_TRAILING_NL);
    expect(stripped).not.toContain('name: test-skill');
    expect(stripped).toContain('## Body');
  });

  test('returns content unchanged when no frontmatter present', () => {
    const stripped = stripFrontmatter(NO_FRONTMATTER);
    expect(stripped).toBe(NO_FRONTMATTER);
  });

  test('stripped result should not start with ---', () => {
    const stripped = stripFrontmatter(WITH_TRAILING_NL);
    expect(stripped.trimStart()).not.toMatch(/^---/);
  });
});

// ─── Round-trip consistency ─────────────────────────��─────────────────────────

describe('round-trip: raw should reconstruct original frontmatter block', () => {
  test('raw + body reconstructs original content (trailing-NL variant)', () => {
    const result = parseFrontmatter(WITH_TRAILING_NL);
    const reconstructed = result.raw + result.body;
    expect(reconstructed).toBe(WITH_TRAILING_NL);
  });

  test('raw + body reconstructs original content (no trailing-NL variant)', () => {
    const result = parseFrontmatter(WITHOUT_TRAILING_NL);
    const reconstructed = result.raw + result.body;
    expect(reconstructed).toBe(WITHOUT_TRAILING_NL);
  });
});
