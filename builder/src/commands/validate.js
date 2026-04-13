/**
 * Validate Command
 *
 * Validates the project structure by checking companion files,
 * template placeholders, and generated skill files.
 *
 * Also enforces agentskills.io SKILL.md specification compliance:
 *   - Skill name: [a-z0-9-] only, max 64 chars, no leading/trailing/consecutive hyphens
 *   - Description: max 1024 characters
 *   - Content: warn if > 500 lines (Progressive Disclosure best practice)
 *
 * @module builder/src/commands/validate
 * @version 3.1.1 - Added agentskills.io SKILL.md spec compliance checks
 */

const fs = require('fs');
const path = require('path');
const chalk = require('chalk');
const glob = require('glob');
const yaml = require('js-yaml');
const config = require('../config');

// Use configuration from centralized config
const { PATHS, REQUIRED_FILES, REQUIRED_UTE_FIELDS, PLACEHOLDERS, AUTHOR_PLACEHOLDERS } = config;

// agentskills.io SKILL.md specification constraints
const SKILLMD_SPEC = {
  namePattern: /^[a-z0-9][a-z0-9-]*[a-z0-9]$|^[a-z0-9]$/,   // no leading/trailing hyphens
  nameMaxLen: 64,
  descMaxLen: 1024,
  contentMaxLines: 500,  // warn (not error) above this threshold
};

/**
 * Main validate function
 * @returns {Promise<Object>} Validation result
 */
async function validate() {
  console.log(chalk.blue.bold('\n🔍 Validating Project Structure\n'));

  const result = {
    valid: true,
    errors: 0,
    warnings: 0,
    issues: [],
  };

  await validateRequiredFiles(result);
  await validateTemplates(result);
  await validateGeneratedSkills(result);
  await validateSkillMdSpec(result);

  printSummary(result);
  return result;
}

/**
 * Check required companion files are present
 */
async function validateRequiredFiles(result) {
  console.log(chalk.cyan('📋 Checking required files...'));

  for (const file of REQUIRED_FILES) {
    try {
      await fs.promises.access(file.path, fs.constants.F_OK);
      console.log(chalk.green(`  ✓ ${file.label}`));
    } catch {
      addIssue(result, 'error', `Missing required file: ${file.label}`);
      console.log(chalk.red(`  ✗ ${file.label} (missing)`));
    }
  }

  console.log('');
}

/**
 * Validate templates have placeholders
 */
async function validateTemplates(result) {
  console.log(chalk.cyan('🎨 Validating templates...'));

  const templatePattern = path.join(PATHS.templates, '*.md');
  const templateFiles = glob.sync(templatePattern);

  if (templateFiles.length === 0) {
    addIssue(result, 'warning', 'No template files found');
    console.log('');
    return;
  }

  console.log(chalk.gray(`  Found ${templateFiles.length} template file(s)`));

  for (const filePath of templateFiles) {
    const relativePath = path.relative(PATHS.root, filePath);

    try {
      const content = await fs.promises.readFile(filePath, 'utf8');

      if (!content.trim()) {
        addIssue(result, 'warning', `Empty template file: ${relativePath}`);
        console.log(chalk.yellow(`  ⚠ ${relativePath} (empty)`));
        continue;
      }

      const placeholders = content.match(PLACEHOLDERS.extended);

      if (!placeholders || placeholders.length === 0) {
        // use-to-evolve-snippet.md legitimately has placeholders, others may not
        console.log(chalk.green(`  ✓ ${relativePath}`));
      } else {
        const uniquePlaceholders = [...new Set(placeholders)];
        console.log(chalk.green(`  ✓ ${relativePath} (${uniquePlaceholders.length} placeholders)`));
      }

      // {{PLACEHOLDER}} is intentional in templates — it marks spots where skill authors
      // should insert content. Flag as warning (informational), not error.
      if (content.includes('{{PLACEHOLDER}}')) {
        addIssue(result, 'warning', `Template uses {{PLACEHOLDER}} marker (intentional — replace when using): ${relativePath}`);
        console.log(chalk.yellow(`  ⚠ ${relativePath} (contains {{PLACEHOLDER}} markers — expected for templates)`));
      }
    } catch (error) {
      addIssue(result, 'error', `Cannot read template ${relativePath}: ${error.message}`);
      console.log(chalk.red(`  ✗ ${relativePath} (read error)`));
    }
  }

  console.log('');
}

/**
 * Validate generated platform skill files (both Markdown and JSON outputs).
 */
async function validateGeneratedSkills(result) {
  console.log(chalk.cyan('🧪 Validating generated skill files...'));

  let mdFiles = [];
  let jsonFiles = [];
  try {
    mdFiles = glob.sync(path.join(PATHS.platforms, '*.md'));
    jsonFiles = glob.sync(path.join(PATHS.platforms, '*.json'));
  } catch {
    // glob errors treated as empty
  }

  const allFiles = [...mdFiles, ...jsonFiles];

  if (allFiles.length === 0) {
    addIssue(result, 'warning', 'No generated skill files found in platforms/');
    console.log(chalk.yellow('  ⚠ No skill files found (run build first)\n'));
    return;
  }

  console.log(chalk.gray(`  Found ${mdFiles.length} .md and ${jsonFiles.length} .json file(s)`));

  // --- Markdown skill files ---
  for (const filePath of mdFiles) {
    const fileName = path.basename(filePath);
    let content;

    try {
      content = await fs.promises.readFile(filePath, 'utf8');
    } catch (error) {
      addIssue(result, 'error', `Cannot read ${fileName}: ${error.message}`);
      continue;
    }

    let fileOk = true;

    // Check §N section count (≥3)
    const sectionMatches = content.match(/^##\s+§\d+\s+\S/gm) || [];
    if (sectionMatches.length < 3) {
      addIssue(result, 'error', `${fileName}: fewer than 3 §N sections (found ${sectionMatches.length})`);
      fileOk = false;
    }

    // Check Red Lines / 严禁
    if (!/严禁|Red Lines/i.test(content)) {
      addIssue(result, 'error', `${fileName}: missing Red Lines (严禁) section`);
      fileOk = false;
    }

    // Check use_to_evolve block and all 11 required fields
    if (!content.includes('use_to_evolve:')) {
      addIssue(result, 'error', `${fileName}: missing use_to_evolve: YAML block`);
      fileOk = false;
    } else {
      for (const field of REQUIRED_UTE_FIELDS) {
        if (!content.includes(`${field}:`)) {
          addIssue(result, 'error', `${fileName}: use_to_evolve missing field '${field}'`);
          fileOk = false;
        }
      }
    }

    // Check §UTE body section
    if (!/##\s+§UTE\b/i.test(content)) {
      addIssue(result, 'error', `${fileName}: missing ## §UTE Use-to-Evolve body section`);
      fileOk = false;
    }

    // No remaining build-time {{PLACEHOLDER}} tokens.
    // Strip fenced code blocks and inline code spans first — those embed template
    // content for skill authors (e.g. {{SKILL_NAME}} in UTE snippets, {{STEP_1_NAME}}
    // in workflow diagrams) which are intentional "fill-me-in" markers, not build errors.
    // Also filter against AUTHOR_PLACEHOLDERS whitelist for any remaining prose occurrences.
    // Extended pattern covers hyphens/dots ({{OUTER-KEY}}, {{outer.key}}) in addition to standard.
    const stripped = content
      .replace(/```[\s\S]*?```/g, '')    // strip fenced code blocks
      .replace(/`[^`\n]+`/g, '');        // strip inline code spans
    const remaining = (stripped.match(/\{\{[\w.-]+\}\}/g) || [])
      .filter(match => {
        const key = match.slice(2, -2); // strip {{ and }}
        return !AUTHOR_PLACEHOLDERS.has(key);
      });
    const uniqueBuildTime = [...new Set(remaining)];
    if (uniqueBuildTime.length > 0) {
      addIssue(result, 'error', `${fileName}: ${uniqueBuildTime.length} unreplaced build-time placeholder(s): ${uniqueBuildTime.slice(0, 5).join(', ')}`);
      fileOk = false;
    }

    // Secondary check — warn when known author placeholders appear in PROSE text
    // (outside code blocks).  Author placeholders are intentional inside fenced code
    // examples but suspicious in prose — they indicate template content bleeding into
    // documentation sections rather than example blocks.
    // Note: may produce false positives if documentation deliberately uses placeholder
    // examples in prose (e.g. "use {{SKILL_NAME}} in your config").  Treat as info-level.
    const proseAuthorPlaceholders = (stripped.match(/\{\{[\w.-]+\}\}/g) || [])
      .filter(match => AUTHOR_PLACEHOLDERS.has(match.slice(2, -2)));
    if (proseAuthorPlaceholders.length > 0) {
      const unique = [...new Set(proseAuthorPlaceholders)];

      // Collect line numbers where each placeholder appears outside code blocks
      const lines = content.split('\n');
      let inFenced = false;
      const hitLines = [];
      lines.forEach((line, idx) => {
        if (/^```/.test(line)) { inFenced = !inFenced; return; }
        if (!inFenced && unique.some(ph => line.includes(ph))) {
          hitLines.push(idx + 1);
        }
      });
      const lineRef = hitLines.length > 0
        ? ` (line${hitLines.length > 1 ? 's' : ''} ${hitLines.slice(0, 5).join(', ')})`
        : '';

      addIssue(result, 'warning',
        `${fileName}: ${unique.length} author placeholder(s) found in prose text${lineRef} ` +
        `(expected only inside code blocks): ${unique.slice(0, 3).join(', ')}`
      );
    }

    if (fileOk) {
      console.log(chalk.green(`  ✓ ${fileName}`));
    } else {
      console.log(chalk.red(`  ✗ ${fileName} (see issues above)`));
    }
  }

  // --- JSON output files (mcp, openai, a2a) ---
  for (const filePath of jsonFiles) {
    const fileName = path.basename(filePath);
    let raw;

    try {
      raw = await fs.promises.readFile(filePath, 'utf8');
    } catch (error) {
      addIssue(result, 'error', `Cannot read ${fileName}: ${error.message}`);
      continue;
    }

    let fileOk = true;

    // Must be valid JSON
    let parsed;
    try {
      parsed = JSON.parse(raw);
    } catch (error) {
      addIssue(result, 'error', `${fileName}: invalid JSON — ${error.message}`);
      fileOk = false;
      console.log(chalk.red(`  ✗ ${fileName} (invalid JSON)`));
      continue;
    }

    // MCP manifest checks
    // Use /-mcp[.-]/ to match both skill-writer-mcp.json and skill-writer-mcp-dev.json
    if (/-mcp[.-]/.test(fileName)) {
      if (!parsed.schema_version) {
        addIssue(result, 'error', `${fileName}: MCP manifest missing schema_version`);
        fileOk = false;
      }
      if (!parsed.name) {
        addIssue(result, 'error', `${fileName}: MCP manifest missing name`);
        fileOk = false;
      }
      if (!Array.isArray(parsed.tools) || parsed.tools.length === 0) {
        addIssue(result, 'error', `${fileName}: MCP manifest must declare at least one tool`);
        fileOk = false;
      }
      if (!parsed.capabilities) {
        addIssue(result, 'warning', `${fileName}: MCP manifest missing capabilities block`);
      }
    }

    // OpenAI JSON checks
    // Use /-openai[.-]/ to match both skill-writer-openai.json and skill-writer-openai-dev.json
    if (/-openai[.-]/.test(fileName)) {
      if (!parsed.name) {
        addIssue(result, 'error', `${fileName}: OpenAI manifest missing name`);
        fileOk = false;
      }
      if (!parsed.instructions) {
        addIssue(result, 'error', `${fileName}: OpenAI manifest missing instructions`);
        fileOk = false;
      }
    }

    // A2A Agent Card checks
    // Use /-a2a[.-]/ to match both skill-writer-a2a.json and skill-writer-a2a-dev.json
    if (/-a2a[.-]/.test(fileName)) {
      if (!parsed.schema_version || !parsed.schema_version.startsWith('a2a/')) {
        addIssue(result, 'error', `${fileName}: A2A Agent Card missing or invalid schema_version (expected "a2a/1.0")`);
        fileOk = false;
      }
      if (!parsed.name) {
        addIssue(result, 'error', `${fileName}: A2A Agent Card missing name`);
        fileOk = false;
      }
      if (!Array.isArray(parsed.skills) || parsed.skills.length === 0) {
        addIssue(result, 'error', `${fileName}: A2A Agent Card must declare at least one skill`);
        fileOk = false;
      }
      if (!parsed.capabilities) {
        addIssue(result, 'warning', `${fileName}: A2A Agent Card missing capabilities block`);
      }
    }

    if (fileOk) {
      console.log(chalk.green(`  ✓ ${fileName}`));
    } else {
      console.log(chalk.red(`  ✗ ${fileName} (see issues above)`));
    }
  }

  console.log('');
}

/**
 * Validate generated skill files against the agentskills.io SKILL.md specification.
 * Checks: skill name format, description length, content line count.
 * Spec source: https://agentskills.io/specification (December 2025)
 */
async function validateSkillMdSpec(result) {
  console.log(chalk.cyan('📐 Checking agentskills.io SKILL.md spec compliance...'));

  let mdFiles = [];
  try {
    mdFiles = glob.sync(path.join(PATHS.platforms, '*.md'));
  } catch {
    // No files — already reported by validateGeneratedSkills
  }

  if (mdFiles.length === 0) {
    console.log(chalk.gray('  (no .md skill files to check)\n'));
    return;
  }

  for (const filePath of mdFiles) {
    const fileName = path.basename(filePath);
    let content;
    try {
      content = await fs.promises.readFile(filePath, 'utf8');
    } catch (error) {
      addIssue(result, 'error', `${fileName}: cannot read for spec compliance check — ${error.message}`);
      continue;
    }

    // Track spec issues added for this file specifically
    const issuesBefore = result.issues.length;

    // Extract YAML frontmatter — use \r?\n to handle both Unix and Windows line endings
    let fm = null;
    const fmMatch = content.match(/^---\r?\n([\s\S]*?)\r?\n---/);
    if (fmMatch) {
      try {
        fm = yaml.load(fmMatch[1]);
      } catch {
        // frontmatter parse error already caught by validateGeneratedSkills
      }
    }

    // ── 1. Skill name validation ─────────────────────────────────────────────
    // namePattern catches: non-[a-z0-9-] chars, leading/trailing hyphens.
    // Consecutive hyphens (e.g. "bad--name") pass namePattern and require a
    // separate /--/ check — namePattern alone does NOT catch them.
    const skillName = fm?.name ? String(fm.name) : null;
    if (skillName) {
      if (skillName.length > SKILLMD_SPEC.nameMaxLen) {
        addIssue(result, 'error',
          `${fileName}: skill name "${skillName}" exceeds ${SKILLMD_SPEC.nameMaxLen}-char limit ` +
          `(${skillName.length} chars) — agentskills.io spec §2.1`);
      }
      // Checks: invalid chars, leading hyphen, trailing hyphen
      if (!SKILLMD_SPEC.namePattern.test(skillName)) {
        addIssue(result, 'error',
          `${fileName}: skill name "${skillName}" violates naming convention — ` +
          'must match [a-z0-9-] only, no leading/trailing hyphens — agentskills.io spec §2.1');
      }
      // Separate check: consecutive hyphens (allowed by namePattern, forbidden by spec)
      if (/--/.test(skillName)) {
        addIssue(result, 'error',
          `${fileName}: skill name "${skillName}" contains consecutive hyphens — agentskills.io spec §2.1`);
      }
    }

    // ── 2. Description length ────────────────────────────────────────────────
    const desc = fm?.description ? String(fm.description) : null;
    if (desc && desc.length > SKILLMD_SPEC.descMaxLen) {
      addIssue(result, 'error',
        `${fileName}: description exceeds ${SKILLMD_SPEC.descMaxLen}-char limit ` +
        `(${desc.length} chars) — agentskills.io spec §2.2`);
    }

    // ── 3. Content line count ────────────────────────────────────────────────
    // Thresholds match refs/progressive-disclosure.md §3:
    //   >500  lines → WARNING  (acceptable but monitor token usage)
    //   >1000 lines → ERROR    (likely contains embedded reference content)
    const lineCount = content.split('\n').length;
    if (lineCount > 1000) {
      addIssue(result, 'error',
        `${fileName}: ${lineCount} lines is excessive — skill likely contains embedded reference content ` +
        'that belongs in Layer 3 companion files — refs/progressive-disclosure.md §3');
    } else if (lineCount > SKILLMD_SPEC.contentMaxLines) {
      addIssue(result, 'warning',
        `${fileName}: ${lineCount} lines exceeds recommended ${SKILLMD_SPEC.contentMaxLines}-line limit ` +
        '— consider Progressive Disclosure pattern (refs/progressive-disclosure.md §3)');
    }

    const newIssues = result.issues.slice(issuesBefore);
    const newErrors = newIssues.filter(i => i.type === 'error').length;
    const newWarnings = newIssues.filter(i => i.type === 'warning').length;
    if (newIssues.length === 0) {
      console.log(chalk.green(`  ✓ ${fileName} (spec compliant)`));
    } else if (newErrors > 0) {
      console.log(chalk.red(`  ✗ ${fileName} (${newErrors} error(s), ${newWarnings} warning(s))`));
    } else {
      console.log(chalk.yellow(`  ⚠ ${fileName} (${newWarnings} warning(s))`));
    }
  }

  console.log('');
}

function addIssue(result, type, message) {
  result.issues.push({ type, message, timestamp: new Date().toISOString() });
  if (type === 'error') {
    result.errors++;
    result.valid = false;
  } else {
    result.warnings++;
  }
}

function printSummary(result) {
  console.log(chalk.blue.bold('━'.repeat(50)));
  console.log(chalk.bold('📊 Validation Summary\n'));

  if (result.valid && result.warnings === 0) {
    console.log(chalk.green.bold('✅ All checks passed!'));
  } else if (result.valid) {
    console.log(chalk.yellow.bold('⚠️  Validation passed with warnings'));
  } else {
    console.log(chalk.red.bold('❌ Validation failed'));
  }

  console.log(chalk.gray(`\n  Errors:   ${result.errors > 0 ? chalk.red(result.errors) : chalk.green(result.errors)}`));
  console.log(chalk.gray(`  Warnings: ${result.warnings > 0 ? chalk.yellow(result.warnings) : chalk.green(result.warnings)}`));

  if (result.issues.length > 0) {
    console.log(chalk.bold('\n📋 Issues:\n'));
    result.issues.forEach((issue) => {
      const color = issue.type === 'error' ? chalk.red : chalk.yellow;
      const icon = issue.type === 'error' ? '✗' : '⚠';
      console.log(color(`  ${icon} ${issue.message}`));
    });
  }

  console.log(chalk.blue.bold('\n' + '━'.repeat(50) + '\n'));
}

module.exports = {
  validate,
  validateRequiredFiles,
  validateTemplates,
  validateGeneratedSkills,
  validateSkillMdSpec,
  SKILLMD_SPEC,
};
