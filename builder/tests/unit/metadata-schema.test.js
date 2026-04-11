/**
 * Metadata Schema Utility Tests
 *
 * Tests for the shared metadata schema factory functions.
 * Verifies that markdownCompatibility() and mcpCompatibility() produce
 * well-structured objects, and that getBuilderVersion() returns the live
 * package.json version rather than a hardcoded string (BUG-3 regression guard).
 */

const {
  markdownCompatibility,
  mcpCompatibility,
  getBuilderVersion,
} = require('../../src/utils/metadata-schema');

const pkg = require('../../package.json');

// ─── getBuilderVersion ────────────────────────────────────────────────────────

describe('getBuilderVersion()', () => {
  test('returns a non-empty string', () => {
    const version = getBuilderVersion();
    expect(typeof version).toBe('string');
    expect(version.length).toBeGreaterThan(0);
  });

  test('matches the version in package.json (not hardcoded)', () => {
    expect(getBuilderVersion()).toBe(pkg.version);
  });

  test('looks like a semver string (x.y.z)', () => {
    expect(getBuilderVersion()).toMatch(/^\d+\.\d+\.\d+/);
  });
});

// ─── markdownCompatibility ────────────────────────────────────────────────────

describe('markdownCompatibility()', () => {
  test('returns an object with minVersion and testedVersions', () => {
    const result = markdownCompatibility('2.2.0');
    expect(result).toHaveProperty('minVersion');
    expect(result).toHaveProperty('testedVersions');
  });

  test('minVersion equals the argument passed in', () => {
    expect(markdownCompatibility('2.2.0').minVersion).toBe('2.2.0');
    expect(markdownCompatibility('1.0.0').minVersion).toBe('1.0.0');
  });

  test('testedVersions is an array', () => {
    expect(Array.isArray(markdownCompatibility('2.2.0').testedVersions)).toBe(true);
  });

  test('testedVersions contains the current package.json version (BUG-3 guard)', () => {
    // This is the critical fix for cursor.js hardcoding ['1.0.0']
    const result = markdownCompatibility('1.0.0');
    expect(result.testedVersions).toContain(pkg.version);
  });

  test('testedVersions does NOT hardcode 1.0.0 unless that is the actual version', () => {
    if (pkg.version !== '1.0.0') {
      const result = markdownCompatibility('1.0.0');
      // The tested version should be the live version, not the old hardcoded value
      expect(result.testedVersions).not.toEqual(['1.0.0']);
    }
  });

  test('uses default minVersion when called without argument', () => {
    const result = markdownCompatibility();
    expect(result.minVersion).toBeDefined();
    expect(typeof result.minVersion).toBe('string');
  });
});

// ─── mcpCompatibility ─────────────────────────────────────────────────────────

describe('mcpCompatibility()', () => {
  test('returns an object with mcp_protocol', () => {
    const result = mcpCompatibility();
    expect(result).toHaveProperty('mcp_protocol');
  });

  test('mcp_protocol is a string', () => {
    expect(typeof mcpCompatibility().mcp_protocol).toBe('string');
  });

  test('returns a clients array', () => {
    const result = mcpCompatibility();
    expect(result).toHaveProperty('clients');
    expect(Array.isArray(result.clients)).toBe(true);
    expect(result.clients.length).toBeGreaterThan(0);
  });

  test('clients list includes claude-desktop', () => {
    expect(mcpCompatibility().clients).toContain('claude-desktop');
  });
});

// ─── Schema consistency ───────────────────────────────────────────────────────

describe('schema consistency across adapters', () => {
  test('markdownCompatibility result is serialisable to JSON', () => {
    const result = markdownCompatibility('2.2.0');
    expect(() => JSON.stringify(result)).not.toThrow();
  });

  test('mcpCompatibility result is serialisable to JSON', () => {
    const result = mcpCompatibility();
    expect(() => JSON.stringify(result)).not.toThrow();
  });

  test('two calls to markdownCompatibility with same args produce identical output', () => {
    const a = markdownCompatibility('2.2.0');
    const b = markdownCompatibility('2.2.0');
    expect(JSON.stringify(a)).toBe(JSON.stringify(b));
  });
});
