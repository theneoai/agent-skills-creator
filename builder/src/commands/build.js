/**
 * Build Command
 *
 * Main build command that generates platform-specific skills from the core engine.
 * Reads core data, embeds it into platform templates, and writes to output directory.
 *
 * @module builder/src/commands/build
 * @version 2.2.0
 */

const fs = require('fs-extra');
const path = require('path');
const chalk = require('chalk');
const { readAllCoreData } = require('../core/reader');
const { generateSkillFile } = require('../core/embedder');
const { getSupportedPlatforms, isSupported } = require('../platforms');
const config = require('../config');
const { getSkillMetadata } = require('../metadata');

// JSON_OUTPUT_PLATFORMS is the canonical SSOT in config — do not redefine here.
const { JSON_OUTPUT_PLATFORMS } = config;

/**
 * Build platform-specific skills from core engine
 *
 * @param {Object} options - Build options
 * @param {string} options.platform - Target platform (or 'all')
 * @param {boolean} options.release - Whether to create a release build
 * @param {string} options.output - Output directory path
 * @returns {Promise<Object>} Build result with statistics
 */
async function build(options) {
  const startTime = Date.now();
  const results = {
    success: [],
    failed: [],
    warnings: [],
    stats: {
      total: 0,
      succeeded: 0,
      failed: 0,
      duration: 0
    }
  };

  // Normalize options
  const buildOptions = {
    platform: options.all ? 'all' : (options.platform || 'all'),
    release: options.release || false,
    output: options.output || 'platforms',
    dryRun: options.dryRun || false,
  };

  // Validate output path — reject null bytes and well-known OS system directories
  // to prevent accidental writes caused by path traversal in the --output option.
  const resolvedOutput = path.resolve(buildOptions.output);
  if (buildOptions.output.includes('\0')) {
    throw new Error('Invalid --output path: null bytes are not allowed');
  }
  const FORBIDDEN_PREFIXES = ['/', '/etc', '/usr', '/bin', '/sbin', '/root', '/boot', '/sys', '/proc'];
  const isForbidden = FORBIDDEN_PREFIXES.some(
    (prefix) => resolvedOutput === prefix || resolvedOutput.startsWith(prefix + path.sep)
  );
  if (isForbidden) {
    throw new Error(
      `Invalid --output path "${resolvedOutput}": writing to system directories is not allowed`
    );
  }

  console.log(chalk.bold.blue('\n🔨 Skill Writer Builder\n'));
  console.log(chalk.gray('Building platform-specific skills from core engine...\n'));

  // Show build configuration
  console.log(chalk.cyan('Configuration:'));
  console.log(`  Platform: ${chalk.yellow(buildOptions.platform)}`);
  console.log(`  Release: ${chalk.yellow(buildOptions.release ? 'yes' : 'no')}`);
  console.log(`  Output: ${chalk.yellow(buildOptions.output)}`);
  if (buildOptions.dryRun) {
    console.log(`  ${chalk.bold.yellow('[DRY RUN]')} No files will be written.\n`);
  } else {
    console.log();
  }

  try {
    // Step 1: Read core data
    console.log(chalk.cyan('📖 Reading core engine data...'));
    const coreData = await readAllCoreData();
    console.log(chalk.green('  ✓ Core data loaded successfully'));

    // P2-2: Version compatibility check — warn if skill-framework.md is newer than the builder.
    // This catches the case where skill-framework.md was updated but the builder was not,
    // which could cause the generated skill files to be missing newly-added sections.
    checkVersionCompatibility(coreData.metadata.version);
    console.log();

    // Step 2: Determine target platforms
    const targetPlatforms = buildOptions.platform === 'all'
      ? getSupportedPlatforms()
      : [buildOptions.platform];

    // Validate platform
    if (buildOptions.platform !== 'all' && !isSupported(buildOptions.platform)) {
      throw new Error(
        `Unsupported platform: ${buildOptions.platform}. ` +
        `Supported platforms: ${getSupportedPlatforms().join(', ')}`
      );
    }

    results.stats.total = targetPlatforms.length;

    // Step 3: Build for each platform
    console.log(chalk.cyan(`🔧 Building for ${targetPlatforms.length} platform(s)...\n`));

    for (const platform of targetPlatforms) {
      const platformStartTime = Date.now();

      try {
        console.log(chalk.cyan(`  Building ${chalk.bold(platform)}...`));

        // Prepare core data with metadata (sourced from shared metadata.js — SSoT)
        const skillMetadata = getSkillMetadata(platform);

        const enrichedCoreData = {
          ...coreData,
          metadata: skillMetadata
        };

        // Generate skill file for platform
        const skillResult = generateSkillFile(platform, enrichedCoreData);

        // Apply platform-specific formatting
        const { formatForPlatform } = require('../platforms');
        skillResult.content = formatForPlatform(platform, skillResult.content);

        // Validate generated content
        if (!skillResult.content || skillResult.content.length === 0) {
          throw new Error('Generated skill content is empty');
        }

        // Determine output path
        // JSON_OUTPUT_PLATFORMS (openai, mcp, a2a) emit .json; all others emit .md
        const outputDir = resolvedOutput;
        const fileExtension = JSON_OUTPUT_PLATFORMS.has(platform) ? 'json' : 'md';
        const outputFile = buildOptions.release
          ? `skill-writer-${platform}.${fileExtension}`
          : `skill-writer-${platform}-dev.${fileExtension}`;
        const outputPath = path.join(outputDir, outputFile);

        if (buildOptions.dryRun) {
          // Dry-run: show what would be written without actually writing
          console.log(chalk.yellow(`    [DRY RUN] Would write: ${path.relative(process.cwd(), outputPath)}`));
          console.log(chalk.gray(`    [DRY RUN] Size: ${formatBytes(skillResult.content.length)}\n`));
        } else {
          // Ensure output directory exists
          await fs.ensureDir(outputDir);
          // Write skill file
          await fs.writeFile(outputPath, skillResult.content, 'utf-8');
        }

        const platformDuration = Date.now() - platformStartTime;

        // Log success
        console.log(chalk.green(`    ✓ ${platform} skill generated`));
        console.log(chalk.gray(`      Output: ${path.relative(process.cwd(), outputPath)}`));
        console.log(chalk.gray(`      Size: ${formatBytes(skillResult.content.length)}`));
        console.log(chalk.gray(`      Duration: ${platformDuration}ms\n`));

        results.success.push({
          platform,
          path: outputPath,
          size: skillResult.content.length,
          duration: platformDuration,
          metadata: skillResult.metadata
        });
        results.stats.succeeded++;

      } catch (error) {
        const platformDuration = Date.now() - platformStartTime;

        console.log(chalk.red(`    ✗ ${platform} failed: ${error.message}\n`));

        results.failed.push({
          platform,
          error: error.message,
          duration: platformDuration
        });
        results.stats.failed++;

        // Continue building other platforms even if one fails
        if (buildOptions.platform !== 'all') {
          throw error; // Re-throw if specific platform was requested
        }
      }
    }

    // Calculate total duration
    results.stats.duration = Date.now() - startTime;

    // Print summary
    printSummary(results);

    // Return results
    return results;

  } catch (error) {
    console.error(chalk.red(`\n✗ Build failed: ${error.message}\n`));

    if (error.stack) {
      console.error(chalk.gray(error.stack));
    }

    throw error;
  }
}

/**
 * Print build summary
 * @param {Object} results - Build results
 */
function printSummary(results) {
  console.log(chalk.bold.blue('\n📊 Build Summary\n'));

  // Success section
  if (results.success.length > 0) {
    console.log(chalk.green(`✓ Successfully built ${results.success.length} skill(s):`));
    results.success.forEach(result => {
      console.log(chalk.green(`  • ${result.platform}`));
      console.log(chalk.gray(`    ${path.relative(process.cwd(), result.path)}`));
    });
    console.log();
  }

  // Failed section
  if (results.failed.length > 0) {
    console.log(chalk.red(`✗ Failed to build ${results.failed.length} skill(s):`));
    results.failed.forEach(result => {
      console.log(chalk.red(`  • ${result.platform}: ${result.error}`));
    });
    console.log();
  }

  // Statistics
  console.log(chalk.cyan('Statistics:'));
  console.log(`  Total platforms: ${results.stats.total}`);
  console.log(`  Succeeded: ${chalk.green(results.stats.succeeded)}`);
  console.log(`  Failed: ${chalk.red(results.stats.failed)}`);
  console.log(`  Duration: ${chalk.yellow(results.stats.duration + 'ms')}`);

  if (results.success.length > 0) {
    const totalSize = results.success.reduce((sum, r) => sum + r.size, 0);
    console.log(`  Total size: ${chalk.yellow(formatBytes(totalSize))}`);
  }

  console.log();

  // Final status
  if (results.stats.failed === 0) {
    console.log(chalk.bold.green('✓ Build completed successfully!\n'));
  } else if (results.stats.succeeded === 0) {
    console.log(chalk.bold.red('✗ Build failed completely\n'));
  } else {
    console.log(chalk.bold.yellow('⚠ Build completed with warnings\n'));
  }
}

/**
 * P2-2: Compare builder version against the version stored in coreData.metadata.
 * The metadata version is the builder package.json version baked in by reader.js.
 * We also compare it against skill-framework.md's frontmatter version when readable.
 *
 * Emits a console warning (not an error) so builds are never blocked by this check.
 * @param {string} builderVersion - builder package.json version (from coreData.metadata.version)
 */
function checkVersionCompatibility(builderVersion) {
  if (!builderVersion) return;

  // Try to read skill-framework.md frontmatter version using shared utility (SSoT)
  try {
    const skillFrameworkContent = require('fs').readFileSync(config.PATHS.skillFramework, 'utf-8');
    const { parseFrontmatter } = require('../utils/frontmatter');
    const { frontmatterData } = parseFrontmatter(skillFrameworkContent);
    const frameworkVersion = frontmatterData && frontmatterData.version
      ? String(frontmatterData.version) : null;
    if (frameworkVersion && semverGt(frameworkVersion, builderVersion)) {
      console.warn(
        chalk.yellow(
          `  ⚠ Version mismatch: skill-framework.md is v${frameworkVersion} but builder is v${builderVersion}.\n` +
          '    Run `git pull` and rebuild to pick up new framework sections.'
        )
      );
    }
  } catch {
    // skill-framework.md may not exist or lack frontmatter — non-fatal, skip silently
  }
}

/**
 * Simple semver "greater-than" comparison (no pre-release support needed here).
 * @param {string} a - version to test
 * @param {string} b - version to compare against
 * @returns {boolean} true if a > b
 */
function semverGt(a, b) {
  // Guard against non-version inputs (e.g. 'unknown', '', null)
  if (!a || !b) return false;
  // Strip pre-release suffixes before comparing (e.g. "3.1.0-rc1" → "3.1.0").
  // Semver strictly says 3.1.0 > 3.1.0-rc1, but for a version-mismatch warning
  // we treat them as equal — the point is to detect a meaningfully newer framework.
  const strip = v => String(v).replace(/-[^.]*$/, '');
  // Reject anything that doesn't look like a version number after stripping
  if (!/^\d+(\.\d+)*$/.test(strip(a)) || !/^\d+(\.\d+)*$/.test(strip(b))) return false;
  const pa = strip(a).split('.').map(n => parseInt(n, 10));
  const pb = strip(b).split('.').map(n => parseInt(n, 10));
  for (let i = 0; i < 3; i++) {
    if ((pa[i] || 0) > (pb[i] || 0)) return true;
    if ((pa[i] || 0) < (pb[i] || 0)) return false;
  }
  return false;
}

/**
 * Format bytes to human-readable string
 * @param {number} bytes - Number of bytes
 * @returns {string} Formatted string
 */
function formatBytes(bytes) {
  if (bytes === 0) return '0 B';

  const units = ['B', 'KB', 'MB', 'GB'];
  const k = 1024;
  const i = Math.floor(Math.log(bytes) / Math.log(k));

  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + units[i];
}

module.exports = build;
