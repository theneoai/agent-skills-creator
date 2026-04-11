/**
 * Platform Adapter Tests
 *
 * Tests for the platform adapter layer including the MarkdownAdapter base class,
 * the MCP adapter, and the platform registry.
 */

const { MarkdownAdapter } = require('../../src/platforms/MarkdownAdapter');
const mcp = require('../../src/platforms/mcp');
const platforms = require('../../src/platforms');

// Minimal valid skill content (YAML frontmatter + body)
const VALID_SKILL = `---
name: test-skill
version: 1.0.0
description: A test skill
---

## §1 Identity

This is a test skill.

## §2 Mode Router

Routes to appropriate mode.

## §3 Examples

Example usage here.
`;

describe('MarkdownAdapter Base Class', () => {
  let adapter;

  beforeEach(() => {
    adapter = new MarkdownAdapter({
      name: 'test-platform',
      installDir: '.test-platform',
      sections: ['## Overview', '## Usage'],
      requiredFields: ['name', 'version'],
    });
  });

  test('should set name from options', () => {
    expect(adapter.name).toBe('test-platform');
  });

  test('should generate correct install path', () => {
    const installPath = adapter.getInstallPath();
    expect(installPath).toContain('.test-platform');
    expect(installPath).toContain('skills');
  });

  test('formatSkill should accept valid YAML frontmatter content', () => {
    const result = adapter.formatSkill(VALID_SKILL);
    expect(result).toContain('test-skill');
    expect(typeof result).toBe('string');
  });

  test('formatSkill should throw on missing frontmatter', () => {
    expect(() => adapter.formatSkill('# No frontmatter\n\nContent')).toThrow();
  });

  test('formatSkill should throw on empty input', () => {
    expect(() => adapter.formatSkill('')).toThrow();
    expect(() => adapter.formatSkill(null)).toThrow();
  });

  test('formatSkill should normalise extra H1 headings to H2', () => {
    const multiH1 = `---
name: test
version: 1.0.0
description: test
---

# First H1

# Second H1 — should become H2
`;
    const result = adapter.formatSkill(multiH1);
    const h1Count = (result.match(/^# /gm) || []).length;
    expect(h1Count).toBe(1);
  });

  test('validateSkill should report errors for missing required fields', () => {
    const noVersion = VALID_SKILL.replace('version: 1.0.0\n', '');
    const result = adapter.validateSkill(noVersion);
    expect(result.valid).toBe(false);
    expect(result.errors.some(e => e.includes('version'))).toBe(true);
  });

  test('validateSkill should warn about missing recommended sections', () => {
    const result = adapter.validateSkill(VALID_SKILL);
    // VALID_SKILL doesn't have "## Overview" or "## Usage" so warnings expected
    expect(result.warnings.length).toBeGreaterThan(0);
  });

  test('generateMetadata should return platform name', () => {
    const meta = adapter.generateMetadata({ version: '2.0.0' });
    expect(meta.platform).toBe('test-platform');
  });

  test('template getter should return sections and requiredFields', () => {
    const tmpl = adapter.template;
    expect(tmpl.sections).toContain('## Overview');
    expect(tmpl.requiredFields).toContain('name');
  });
});

describe('Claude Adapter (extends MarkdownAdapter)', () => {
  const claude = require('../../src/platforms/claude');

  test('should have name = claude', () => {
    expect(claude.name).toBe('claude');
  });

  test('should expose all required adapter methods', () => {
    expect(typeof claude.formatSkill).toBe('function');
    expect(typeof claude.getInstallPath).toBe('function');
    expect(typeof claude.generateMetadata).toBe('function');
    expect(typeof claude.validateSkill).toBe('function');
  });

  test('install path should reference .claude', () => {
    expect(claude.getInstallPath()).toContain('.claude');
  });
});

describe('Gemini Adapter (extends MarkdownAdapter)', () => {
  const gemini = require('../../src/platforms/gemini');

  test('should have name = gemini', () => {
    expect(gemini.name).toBe('gemini');
  });

  test('install path should reference .gemini', () => {
    expect(gemini.getInstallPath()).toContain('.gemini');
  });
});

describe('MCP Adapter', () => {
  test('should have name = mcp', () => {
    expect(mcp.name).toBe('mcp');
  });

  test('install path should reference .mcp/servers', () => {
    const installPath = mcp.getInstallPath();
    expect(installPath).toContain('.mcp');
    expect(installPath).toContain('servers');
  });

  test('formatSkill should return valid JSON', () => {
    const result = mcp.formatSkill(VALID_SKILL);
    expect(() => JSON.parse(result)).not.toThrow();
  });

  test('formatSkill should extract name from frontmatter', () => {
    const result = mcp.formatSkill(VALID_SKILL);
    const manifest = JSON.parse(result);
    expect(manifest.name).toBe('test-skill');
  });

  test('formatSkill should include schema_version', () => {
    const result = mcp.formatSkill(VALID_SKILL);
    const manifest = JSON.parse(result);
    expect(manifest.schema_version).toBe('1.0');
  });

  test('formatSkill should declare at least one tool', () => {
    const result = mcp.formatSkill(VALID_SKILL);
    const manifest = JSON.parse(result);
    expect(Array.isArray(manifest.tools)).toBe(true);
    expect(manifest.tools.length).toBeGreaterThan(0);
  });

  test('formatSkill should include capabilities block', () => {
    const result = mcp.formatSkill(VALID_SKILL);
    const manifest = JSON.parse(result);
    expect(manifest.capabilities).toBeDefined();
    expect(manifest.capabilities.self_evolution).toBe(true);
  });

  test('validateSkill should pass valid JSON manifest', () => {
    const formatted = mcp.formatSkill(VALID_SKILL);
    const result = mcp.validateSkill(formatted);
    expect(result.valid).toBe(true);
    expect(result.errors).toHaveLength(0);
  });

  test('validateSkill should fail on invalid JSON', () => {
    const result = mcp.validateSkill('{broken json');
    expect(result.valid).toBe(false);
  });

  test('generateMetadata should include MCP protocol version', () => {
    const meta = mcp.generateMetadata({ version: '1.0.0' });
    expect(meta.compatibility.mcp_protocol).toBe('1.0');
  });

  test('formatSkill should throw on empty input', () => {
    expect(() => mcp.formatSkill('')).toThrow();
    expect(() => mcp.formatSkill(null)).toThrow();
  });
});

describe('OpenCode Adapter (extends MarkdownAdapter)', () => {
  const opencode = require('../../src/platforms/opencode');

  test('should have name = opencode', () => {
    expect(opencode.name).toBe('opencode');
  });

  test('should expose all required adapter methods', () => {
    expect(typeof opencode.formatSkill).toBe('function');
    expect(typeof opencode.getInstallPath).toBe('function');
    expect(typeof opencode.generateMetadata).toBe('function');
    expect(typeof opencode.validateSkill).toBe('function');
  });

  test('install path should reference .config/opencode/skills', () => {
    const p = opencode.getInstallPath();
    expect(p).toContain('.config');
    expect(p).toContain('opencode');
    expect(p).toContain('skills');
  });

  test('formatSkill should accept valid content and return string', () => {
    const result = opencode.formatSkill(VALID_SKILL);
    expect(typeof result).toBe('string');
    expect(result.length).toBeGreaterThan(0);
  });

  test('formatSkill should append **Triggers** block when absent', () => {
    const result = opencode.formatSkill(VALID_SKILL);
    expect(result).toContain('**Triggers**:');
  });

  test('formatSkill should not duplicate **Triggers** block when already present', () => {
    const withTriggers = VALID_SKILL + '\n\n**Triggers**:\n- test trigger\n';
    const result = opencode.formatSkill(withTriggers);
    const count = (result.match(/\*\*Triggers\*\*:/g) || []).length;
    expect(count).toBe(1);
  });

  test('formatSkill should throw on missing frontmatter', () => {
    expect(() => opencode.formatSkill('# No frontmatter\n\nContent')).toThrow();
  });

  test('formatSkill should not mutate the input string', () => {
    const original = VALID_SKILL;
    const copy = String(original);
    opencode.formatSkill(original);
    expect(original).toBe(copy);
  });

  test('generateMetadata should include testedVersions array', () => {
    const meta = opencode.generateMetadata({ version: '2.0.0' });
    expect(meta.platform).toBe('opencode');
    expect(Array.isArray(meta.compatibility.testedVersions)).toBe(true);
    expect(meta.compatibility.testedVersions.length).toBeGreaterThan(0);
  });

  test('validateSkill should pass valid content', () => {
    const result = opencode.validateSkill(VALID_SKILL);
    expect(result.valid).toBe(true);
    expect(result.errors).toHaveLength(0);
  });

  test('validateSkill should fail on missing frontmatter', () => {
    const result = opencode.validateSkill('# No frontmatter\n\nContent');
    expect(result.valid).toBe(false);
    expect(result.errors.some(e => /frontmatter/i.test(e))).toBe(true);
  });
});

describe('OpenClaw Adapter', () => {
  const openclaw = require('../../src/platforms/openclaw');

  test('should have name = openclaw', () => {
    expect(openclaw.name).toBe('openclaw');
  });

  test('install path should reference .openclaw/skills', () => {
    const p = openclaw.getInstallPath();
    expect(p).toContain('.openclaw');
    expect(p).toContain('skills');
  });

  test('formatSkill should inject metadata.openclaw into frontmatter', () => {
    const result = openclaw.formatSkill(VALID_SKILL);
    expect(result).toContain('openclaw:');
  });

  test('formatSkill should inject LoongFlow section when absent', () => {
    const result = openclaw.formatSkill(VALID_SKILL);
    expect(result).toContain('LoongFlow');
  });

  test('formatSkill should inject Self-Review section when absent', () => {
    const result = openclaw.formatSkill(VALID_SKILL);
    expect(result).toContain('Self-Review Protocol');
  });

  test('formatSkill should inject UTE section when absent', () => {
    const result = openclaw.formatSkill(VALID_SKILL);
    expect(result).toContain('UTE Injection');
  });

  test('formatSkill should not duplicate sections already present', () => {
    // Run formatSkill twice — idempotent
    const once = openclaw.formatSkill(VALID_SKILL);
    const twice = openclaw.formatSkill(once);
    const loongFlowCount = (twice.match(/LoongFlow/g) || []).length;
    // Should appear the same number of times as after first pass
    expect((once.match(/LoongFlow/g) || []).length).toBe(loongFlowCount);
  });

  test('formatSkill should throw on missing frontmatter', () => {
    expect(() => openclaw.formatSkill('# No frontmatter\n\nContent')).toThrow();
  });

  test('validateSkill should report error for missing metadata.openclaw', () => {
    const result = openclaw.validateSkill(VALID_SKILL);
    // VALID_SKILL has no openclaw metadata block → should be an error
    expect(result.errors.some(e => /openclaw/i.test(e))).toBe(true);
  });

  test('validateSkill passes after formatSkill enriches the content', () => {
    const enriched = openclaw.formatSkill(VALID_SKILL);
    const result = openclaw.validateSkill(enriched);
    expect(result.valid).toBe(true);
    expect(result.errors).toHaveLength(0);
  });

  test('fromOpenCode should convert opencode content to openclaw format', () => {
    const result = openclaw.fromOpenCode(VALID_SKILL);
    expect(result).toContain('openclaw:');
  });

  test('generateMetadata should reference openclaw format', () => {
    const meta = openclaw.generateMetadata({ version: '1.0.0' });
    expect(meta.platform).toBe('openclaw');
    expect(meta.format).toBe('AgentSkills');
  });
});

describe('Cursor Adapter', () => {
  const cursor = require('../../src/platforms/cursor');

  test('should have name = cursor', () => {
    expect(cursor.name).toBe('cursor');
  });

  test('install path should reference .cursor/skills', () => {
    const p = cursor.getInstallPath();
    expect(p).toContain('.cursor');
    expect(p).toContain('skills');
  });

  test('formatSkill should convert {{KEY}} placeholders to ${KEY}', () => {
    const content = `---
name: test
version: 1.0.0
description: test
---
Hello {{NAME}}, version {{VERSION}}`;
    const result = cursor.formatSkill(content);
    expect(result).not.toContain('{{NAME}}');
    expect(result).not.toContain('{{VERSION}}');
    expect(result).toContain('${NAME}');
    expect(result).toContain('${VERSION}');
  });

  test('formatSkill should convert YAML frontmatter to JSON code block', () => {
    const result = cursor.formatSkill(VALID_SKILL);
    expect(result).toContain('```json');
    expect(result).not.toMatch(/^---/);
  });

  test('formatSkill should produce valid JSON in the code block', () => {
    const result = cursor.formatSkill(VALID_SKILL);
    const jsonBlock = result.match(/```json\n([\s\S]*?)\n```/);
    expect(jsonBlock).not.toBeNull();
    expect(() => JSON.parse(jsonBlock[1])).not.toThrow();
  });

  test('formatSkill should return string for valid input', () => {
    const result = cursor.formatSkill(VALID_SKILL);
    expect(typeof result).toBe('string');
    expect(result.length).toBeGreaterThan(0);
  });

  test('formatSkill should throw on empty input', () => {
    expect(() => cursor.formatSkill('')).toThrow();
    expect(() => cursor.formatSkill(null)).toThrow();
  });

  test('validateSkill should warn if no ${} placeholders', () => {
    const noPlaceholders = `---
name: test
version: 1.0.0
description: test
---
No placeholders here.`;
    // After formatSkill converts frontmatter → JSON block, there are no ${}
    // validateSkill checks the RAW content — content without ${} gets a warning
    const result = cursor.validateSkill(noPlaceholders);
    expect(result.valid).toBe(true); // no errors, only warnings
    expect(result.warnings.length).toBeGreaterThan(0);
  });

  test('generateMetadata should return cursor platform name', () => {
    const meta = cursor.generateMetadata({ version: '1.0.0' });
    expect(meta.platform).toBe('cursor');
  });
});

describe('OpenAI Adapter', () => {
  const openai = require('../../src/platforms/openai');

  test('should have name = openai', () => {
    expect(openai.name).toBe('openai');
  });

  test('install path should reference .openai/skills', () => {
    const p = openai.getInstallPath();
    expect(p).toContain('.openai');
    expect(p).toContain('skills');
  });

  test('formatSkill should return valid JSON string', () => {
    const result = openai.formatSkill(VALID_SKILL);
    expect(() => JSON.parse(result)).not.toThrow();
  });

  test('formatSkill should extract name from frontmatter', () => {
    const result = openai.formatSkill(VALID_SKILL);
    const obj = JSON.parse(result);
    expect(obj.name).toBe('test-skill');
  });

  test('formatSkill should extract description from frontmatter', () => {
    const result = openai.formatSkill(VALID_SKILL);
    const obj = JSON.parse(result);
    expect(obj.description).toBe('A test skill');
  });

  test('formatSkill should include instructions field with skill body', () => {
    const result = openai.formatSkill(VALID_SKILL);
    const obj = JSON.parse(result);
    expect(typeof obj.instructions).toBe('string');
    expect(obj.instructions.length).toBeGreaterThan(0);
  });

  test('formatSkill should include metadata.platform = openai', () => {
    const result = openai.formatSkill(VALID_SKILL);
    const obj = JSON.parse(result);
    expect(obj.metadata.platform).toBe('openai');
  });

  test('formatSkill should throw on empty input', () => {
    expect(() => openai.formatSkill('')).toThrow();
    expect(() => openai.formatSkill(null)).toThrow();
  });

  test('validateSkill should pass valid JSON', () => {
    const formatted = openai.formatSkill(VALID_SKILL);
    const result = openai.validateSkill(formatted);
    expect(result.valid).toBe(true);
    expect(result.errors).toHaveLength(0);
  });

  test('validateSkill should fail on invalid JSON', () => {
    const result = openai.validateSkill('{broken json');
    expect(result.valid).toBe(false);
    expect(result.errors.some(e => /JSON/i.test(e))).toBe(true);
  });

  test('validateSkill should fail when required fields are missing', () => {
    const incomplete = JSON.stringify({ name: 'test' });
    const result = openai.validateSkill(incomplete);
    expect(result.valid).toBe(false);
  });

  test('generateMetadata should return openai platform name', () => {
    const meta = openai.generateMetadata({ version: '1.0.0' });
    expect(meta.platform).toBe('openai');
    expect(meta.format).toBe('JSON');
  });
});

describe('outputFormat — all adapters expose the property', () => {
  const adapterModules = {
    claude:    require('../../src/platforms/claude'),
    gemini:    require('../../src/platforms/gemini'),
    opencode:  require('../../src/platforms/opencode'),
    openclaw:  require('../../src/platforms/openclaw'),
    cursor:    require('../../src/platforms/cursor'),
    openai:    require('../../src/platforms/openai'),
    mcp:       require('../../src/platforms/mcp'),
  };

  const VALID_OUTPUT_FORMATS = new Set(['MARKDOWN', 'HYBRID', 'JSON']);

  test.each(Object.entries(adapterModules))(
    '%s adapter should have a valid outputFormat string',
    (name, adapter) => {
      expect(typeof adapter.outputFormat).toBe('string');
      expect(VALID_OUTPUT_FORMATS.has(adapter.outputFormat)).toBe(true);
    }
  );

  test('MARKDOWN adapters: claude, gemini, opencode, openclaw', () => {
    expect(adapterModules.claude.outputFormat).toBe('MARKDOWN');
    expect(adapterModules.gemini.outputFormat).toBe('MARKDOWN');
    expect(adapterModules.opencode.outputFormat).toBe('MARKDOWN');
    expect(adapterModules.openclaw.outputFormat).toBe('MARKDOWN');
  });

  test('HYBRID adapter: cursor', () => {
    expect(adapterModules.cursor.outputFormat).toBe('HYBRID');
  });

  test('JSON adapters: openai, mcp', () => {
    expect(adapterModules.openai.outputFormat).toBe('JSON');
    expect(adapterModules.mcp.outputFormat).toBe('JSON');
  });
});

describe('generateMetadata schema consistency', () => {
  const adapterModules = {
    claude:    require('../../src/platforms/claude'),
    gemini:    require('../../src/platforms/gemini'),
    opencode:  require('../../src/platforms/opencode'),
    openclaw:  require('../../src/platforms/openclaw'),
    cursor:    require('../../src/platforms/cursor'),
    openai:    require('../../src/platforms/openai'),
    mcp:       require('../../src/platforms/mcp'),
  };

  test.each(Object.entries(adapterModules))(
    '%s generateMetadata should include platform and compatibility fields',
    (name, adapter) => {
      const meta = adapter.generateMetadata({ version: '1.0.0' });
      expect(meta.platform).toBe(name);
      expect(meta.compatibility).toBeDefined();
    }
  );

  test('MARKDOWN adapters should include testedVersions in compatibility', () => {
    const markdownAdapters = ['claude', 'gemini', 'opencode', 'openclaw', 'cursor'];
    markdownAdapters.forEach(name => {
      const meta = adapterModules[name].generateMetadata({ version: '1.0.0' });
      expect(Array.isArray(meta.compatibility.testedVersions)).toBe(true);
      expect(meta.compatibility.testedVersions.length).toBeGreaterThan(0);
    });
  });

  test('cursor testedVersions should reflect current package.json version (not hardcoded 1.0.0)', () => {
    const pkg = require('../../package.json');
    const meta = adapterModules.cursor.generateMetadata({ version: '1.0.0' });
    expect(meta.compatibility.testedVersions).toContain(pkg.version);
  });

  test('MCP adapter compatibility should include mcp_protocol', () => {
    const meta = adapterModules.mcp.generateMetadata({ version: '1.0.0' });
    expect(meta.compatibility.mcp_protocol).toBeDefined();
    expect(typeof meta.compatibility.mcp_protocol).toBe('string');
  });
});

describe('Platform Registry', () => {
  test('should support all 7 platforms including mcp', () => {
    const supported = platforms.getSupportedPlatforms();
    expect(supported).toContain('opencode');
    expect(supported).toContain('openclaw');
    expect(supported).toContain('claude');
    expect(supported).toContain('cursor');
    expect(supported).toContain('openai');
    expect(supported).toContain('gemini');
    expect(supported).toContain('mcp');
    expect(supported).toHaveLength(7);
  });

  test('getPlatform should return adapter for valid platform', () => {
    const adapter = platforms.getPlatform('mcp');
    expect(adapter).toBeDefined();
    expect(adapter.name).toBe('mcp');
  });

  test('getPlatform should throw for unknown platform', () => {
    expect(() => platforms.getPlatform('unknown-platform')).toThrow();
  });

  test('isSupported should return true for known platforms', () => {
    expect(platforms.isSupported('mcp')).toBe(true);
    expect(platforms.isSupported('claude')).toBe(true);
  });

  test('isSupported should return false for unknown platforms', () => {
    expect(platforms.isSupported('unknown')).toBe(false);
  });

  test('all adapters should expose the standard interface', () => {
    const required = ['name', 'formatSkill', 'getInstallPath', 'generateMetadata', 'validateSkill'];
    platforms.getSupportedPlatforms().forEach(name => {
      const adapter = platforms.getPlatform(name);
      required.forEach(method => {
        expect(adapter[method]).toBeDefined();
      });
    });
  });

  test('formatForPlatform should format skill for mcp as JSON', () => {
    const result = platforms.formatForPlatform('mcp', VALID_SKILL);
    expect(() => JSON.parse(result)).not.toThrow();
  });

  test('getAllPlatformInfo should return info for all platforms', () => {
    const info = platforms.getAllPlatformInfo();
    expect(Object.keys(info)).toHaveLength(7);
    expect(info.mcp).toBeDefined();
    expect(info.mcp.name).toBe('mcp');
  });
});
