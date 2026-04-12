/**
 * Inspect Command
 *
 * Inspects built output for a specific platform.
 * Provides detailed analysis of the skill file including statistics,
 * section breakdown, and issue detection.
 *
 * @module builder/src/commands/inspect
 * @version 1.0.0
 */

const fs = require('fs');
const path = require('path');
const chalk = require('chalk');
const { getPlatform, getSupportedPlatforms } = require('../platforms');
const config = require('../config');

/**
 * Format file size in human-readable format
 * @param {number} bytes - Size in bytes
 * @returns {string} Formatted size
 */
function formatFileSize(bytes) {
  const units = ['B', 'KB', 'MB', 'GB'];
  let size = bytes;
  let unitIndex = 0;

  while (size >= 1024 && unitIndex < units.length - 1) {
    size /= 1024;
    unitIndex++;
  }

  return `${size.toFixed(2)} ${units[unitIndex]}`;
}

/**
 * Count lines in content
 * @param {string} content - File content
 * @returns {number} Line count
 */
function countLines(content) {
  return content.split('\n').length;
}

/**
 * Count words in content
 * @param {string} content - File content
 * @returns {number} Word count
 */
function countWords(content) {
  return content.trim().split(/\s+/).length;
}

/**
 * Extract sections from markdown content
 * @param {string} content - File content
 * @returns {Array<{level: number, title: string, line: number}>} Sections
 */
function extractSections(content) {
  const sections = [];
  const lines = content.split('\n');

  for (let i = 0; i < lines.length; i++) {
    const match = lines[i].match(/^(#{1,6})\s+(.+)$/);
    if (match) {
      sections.push({
        level: match[1].length,
        title: match[2].trim(),
        line: i + 1
      });
    }
  }

  return sections;
}

/**
 * Check for placeholders in content
 * Uses config.PLACEHOLDERS.extended to catch all placeholder formats
 * ({{KEY}}, {{OUTER-KEY}}, {{outer.key}}, ${KEY})
 * @param {string} content - File content
 * @returns {Array<{placeholder: string, line: number}>} Placeholders found
 */
function findPlaceholders(content) {
  const placeholders = [];
  const lines = content.split('\n');
  // Use a Set to deduplicate by "line:placeholder" key so a pattern that appears
  // in both extended ({{K}}) and cursor (${K}) scans is never double-reported.
  const seen = new Set();

  for (let i = 0; i < lines.length; i++) {
    const extendedPattern = new RegExp(config.PLACEHOLDERS.extended.source, 'g');
    const cursorPattern = new RegExp(config.PLACEHOLDERS.cursor.source, 'g');
    let match;

    while ((match = extendedPattern.exec(lines[i])) !== null) {
      const key = `${i + 1}:${match[0]}`;
      if (!seen.has(key)) {
        seen.add(key);
        placeholders.push({ placeholder: match[0], name: match[1], line: i + 1 });
      }
    }
    while ((match = cursorPattern.exec(lines[i])) !== null) {
      const key = `${i + 1}:${match[0]}`;
      if (!seen.has(key)) {
        seen.add(key);
        placeholders.push({ placeholder: match[0], name: match[1], line: i + 1 });
      }
    }
  }

  return placeholders;
}

/**
 * Check for empty sections in content
 * @param {string} content - File content
 * @returns {Array<{title: string, line: number}>} Empty sections
 */
function findEmptySections(content) {
  const emptySections = [];
  const lines = content.split('\n');

  for (let i = 0; i < lines.length; i++) {
    const match = lines[i].match(/^(#{1,6})\s+(.+)$/);
    if (match) {
      const title = match[2].trim();
      // Check next few lines for content
      let hasContent = false;
      for (let j = i + 1; j < Math.min(i + 10, lines.length); j++) {
        const line = lines[j].trim();
        if (line && !line.match(/^#{1,6}\s/)) {
          hasContent = true;
          break;
        }
        if (line.match(/^#{1,6}\s/)) {
          break;
        }
      }

      if (!hasContent) {
        emptySections.push({
          title: title,
          line: i + 1
        });
      }
    }
  }

  return emptySections;
}

/**
 * Check for unbalanced code blocks
 * @param {string} content - File content
 * @returns {boolean} True if code blocks are unbalanced
 */
function hasUnbalancedCodeBlocks(content) {
  const codeBlockOpens = (content.match(/```/g) || []).length;
  return codeBlockOpens % 2 !== 0;
}

/**
 * Extract frontmatter from content
 * @param {string} content - File content
 * @returns {Object|null} Frontmatter data or null
 */
function extractFrontmatter(content) {
  const match = content.match(/^---\n([\s\S]*?)\n---\n/);
  if (match) {
    try {
      const yaml = require('js-yaml');
      return yaml.load(match[1]);
    } catch (error) {
      return null;
    }
  }
  return null;
}

/** Platforms that emit JSON — kept in sync with build.js JSON_OUTPUT_PLATFORMS */
const JSON_PLATFORMS = new Set(['openai', 'mcp']);

/**
 * Get built skill file path for platform
 * Uses config.PATHS.platforms as the canonical output directory (SSOT).
 * @param {string} platform - Platform name
 * @returns {string|null} File path or null if not found
 */
function getBuiltSkillPath(platform) {
  const ext = JSON_PLATFORMS.has(platform) ? 'json' : 'md';
  const platformsDir = config.PATHS.platforms;

  const possiblePaths = [
    // Primary: canonical build output under config.PATHS.platforms
    path.join(platformsDir, `skill-writer-${platform}-dev.${ext}`),
    path.join(platformsDir, `skill-writer-${platform}.${ext}`),
    path.join(platformsDir, platform, 'skill-writer.md'),
    path.join(platformsDir, platform, 'skill.md'),
  ];

  for (const filePath of possiblePaths) {
    if (fs.existsSync(filePath)) {
      return filePath;
    }
  }

  return null;
}

/**
 * Display file statistics
 * @param {string} content - File content
 * @param {string} filePath - File path
 */
function displayStatistics(content, filePath) {
  const stats = {
    size: formatFileSize(Buffer.byteLength(content, 'utf8')),
    lines: countLines(content),
    words: countWords(content),
    characters: content.length
  };

  console.log(chalk.bold('\n📊 File Statistics'));
  console.log(chalk.gray('─'.repeat(50)));
  console.log(`  ${chalk.cyan('Path:')}        ${filePath}`);
  console.log(`  ${chalk.cyan('Size:')}        ${stats.size}`);
  console.log(`  ${chalk.cyan('Lines:')}       ${stats.lines.toLocaleString()}`);
  console.log(`  ${chalk.cyan('Words:')}       ${stats.words.toLocaleString()}`);
  console.log(`  ${chalk.cyan('Characters:')}  ${stats.characters.toLocaleString()}`);
}

/**
 * Display section breakdown
 * @param {Array} sections - Sections array
 */
function displaySectionBreakdown(sections) {
  console.log(chalk.bold('\n📑 Section Breakdown'));
  console.log(chalk.gray('─'.repeat(50)));

  if (sections.length === 0) {
    console.log(chalk.yellow('  No sections found'));
    return;
  }

  const maxTitleLength = Math.max(...sections.map(s => s.title.length));

  sections.forEach(section => {
    const indent = '  '.repeat(section.level - 1);
    const title = section.title.padEnd(maxTitleLength);
    const lineInfo = chalk.gray(`(line ${section.line})`);
    console.log(`${indent}${chalk.green('●')} ${title} ${lineInfo}`);
  });

  console.log(chalk.gray(`\n  Total sections: ${sections.length}`));
}

/**
 * Display frontmatter information
 * @param {Object|null} frontmatter - Frontmatter data
 */
function displayFrontmatter(frontmatter) {
  console.log(chalk.bold('\n📋 Frontmatter'));
  console.log(chalk.gray('─'.repeat(50)));

  if (!frontmatter) {
    console.log(chalk.yellow('  No frontmatter found'));
    return;
  }

  Object.entries(frontmatter).forEach(([key, value]) => {
    let displayValue = value;
    if (typeof value === 'object') {
      displayValue = JSON.stringify(value);
    }
    console.log(`  ${chalk.cyan(key)}: ${displayValue}`);
  });
}

/**
 * Display issues found in the skill file
 * @param {Object} issues - Issues object
 */
function displayIssues(issues) {
  console.log(chalk.bold('\n🔍 Issues'));
  console.log(chalk.gray('─'.repeat(50)));

  const hasIssues =
    issues.placeholders.length > 0 ||
    issues.emptySections.length > 0 ||
    issues.unbalancedCodeBlocks;

  if (!hasIssues) {
    console.log(chalk.green('  ✓ No issues found'));
    return;
  }

  // Placeholders
  if (issues.placeholders.length > 0) {
    console.log(chalk.yellow(`\n  ⚠ Unreplaced Placeholders (${issues.placeholders.length}):`));
    issues.placeholders.forEach(issue => {
      console.log(`    ${chalk.red(issue.placeholder)} at line ${issue.line}`);
    });
  }

  // Empty sections
  if (issues.emptySections.length > 0) {
    console.log(chalk.yellow(`\n  ⚠ Empty Sections (${issues.emptySections.length}):`));
    issues.emptySections.forEach(section => {
      console.log(`    "${section.title}" at line ${section.line}`);
    });
  }

  // Unbalanced code blocks
  if (issues.unbalancedCodeBlocks) {
    console.log(chalk.red('\n  ✗ Unbalanced Code Blocks:'));
    console.log('    Code block delimiters (```) are not properly paired');
  }
}

/**
 * Display platform information
 * @param {string} platform - Platform name
 */
function displayPlatformInfo(platform) {
  console.log(chalk.bold('\n🖥️  Platform Information'));
  console.log(chalk.gray('─'.repeat(50)));

  try {
    const platformInfo = getPlatform(platform);
    console.log(`  ${chalk.cyan('Name:')}       ${platformInfo.name || platform}`);
    console.log(`  ${chalk.cyan('Template:')}   ${platformInfo.template || 'default'}`);

    try {
      const installPath = platformInfo.getInstallPath();
      console.log(`  ${chalk.cyan('Install:')}    ${installPath}`);
    } catch (error) {
      console.log(`  ${chalk.cyan('Install:')}    ${chalk.gray('Not configured')}`);
    }
  } catch (error) {
    console.log(chalk.yellow(`  Platform info unavailable: ${error.message}`));
  }
}

/**
 * Main inspect function
 * @param {Object} options - Command options
 * @param {string} options.platform - Platform to inspect
 */
async function inspect(options) {
  const platform = options.platform || 'opencode';

  // Validate platform
  const supportedPlatforms = getSupportedPlatforms();
  if (!supportedPlatforms.includes(platform)) {
    console.error(chalk.red(`Error: Unsupported platform "${platform}"`));
    console.error(chalk.gray(`Supported platforms: ${supportedPlatforms.join(', ')}`));
    process.exit(1);
  }

  console.log(chalk.bold.blue(`\n🔎 Inspecting ${platform} build output...\n`));

  // Find built skill file
  const filePath = getBuiltSkillPath(platform);

  if (!filePath) {
    console.error(chalk.red(`Error: No built skill file found for platform "${platform}"`));
    console.error(chalk.gray('Run "swb build --platform ' + platform + '" first'));
    process.exit(1);
  }

  // Read file content
  let content;
  try {
    content = fs.readFileSync(filePath, 'utf8');
  } catch (error) {
    console.error(chalk.red(`Error reading file: ${error.message}`));
    process.exit(1);
  }

  // Analyze content
  const sections = extractSections(content);
  const frontmatter = extractFrontmatter(content);

  const issues = {
    placeholders: findPlaceholders(content),
    emptySections: findEmptySections(content),
    unbalancedCodeBlocks: hasUnbalancedCodeBlocks(content)
  };

  // Display results
  displayStatistics(content, filePath);
  displayPlatformInfo(platform);
  displayFrontmatter(frontmatter);
  displaySectionBreakdown(sections);
  displayIssues(issues);

  // Summary
  console.log(chalk.bold('\n📈 Summary'));
  console.log(chalk.gray('─'.repeat(50)));

  const totalIssues =
    issues.placeholders.length +
    issues.emptySections.length +
    (issues.unbalancedCodeBlocks ? 1 : 0);

  if (totalIssues === 0) {
    console.log(chalk.green('  ✓ Skill file looks good!'));
  } else {
    console.log(chalk.yellow(`  ⚠ Found ${totalIssues} issue(s) to review`));
  }

  console.log('');

  // Return inspection results for programmatic use
  return {
    platform,
    filePath,
    statistics: {
      size: Buffer.byteLength(content, 'utf8'),
      lines: countLines(content),
      words: countWords(content),
      characters: content.length
    },
    sections,
    frontmatter,
    issues,
    summary: {
      totalIssues,
      hasPlaceholders: issues.placeholders.length > 0,
      hasEmptySections: issues.emptySections.length > 0,
      hasUnbalancedCodeBlocks: issues.unbalancedCodeBlocks
    }
  };
}

module.exports = inspect;
