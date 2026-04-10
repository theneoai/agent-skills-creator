/**
 * Validate Command
 *
 * Validates the project structure by checking companion files,
 * template placeholders, and generated skill files.
 *
 * @module builder/src/commands/validate
 * @version 2.1.0 - Updated to use centralized config
 */

const fs = require('fs');
const path = require('path');
const chalk = require('chalk');
const glob = require('glob');
const config = require('../config');

// Use configuration from centralized config
const { PATHS, REQUIRED_FILES, REQUIRED_UTE_FIELDS, PLACEHOLDERS } = config;

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

      const placeholders = content.match(PLACEHOLDERS.standard);

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
 * Validate generated platform skill files
 */
async function validateGeneratedSkills(result) {
  console.log(chalk.cyan('🧪 Validating generated skill files...'));

  let skillFiles;
  try {
    skillFiles = glob.sync(path.join(PATHS.platforms, '*.md'));
  } catch {
    skillFiles = [];
  }

  if (skillFiles.length === 0) {
    addIssue(result, 'warning', 'No generated skill files found in platforms/');
    console.log(chalk.yellow('  ⚠ No skill files found (run build first)\n'));
    return;
  }

  console.log(chalk.gray(`  Found ${skillFiles.length} skill file(s)`));

  for (const filePath of skillFiles) {
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

    // No remaining {{PLACEHOLDER}} tokens
    if (/\{\{[A-Z_0-9]+\}\}/.test(content)) {
      const remaining = (content.match(/\{\{[A-Z_0-9]+\}\}/g) || []);
      const unique = [...new Set(remaining)];
      addIssue(result, 'error', `${fileName}: ${unique.length} unreplaced placeholder(s): ${unique.slice(0, 5).join(', ')}`);
      fileOk = false;
    }

    if (fileOk) {
      console.log(chalk.green(`  ✓ ${fileName}`));
    } else {
      console.log(chalk.red(`  ✗ ${fileName} (see issues above)`));
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
};
