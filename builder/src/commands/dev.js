/**
 * Dev Command
 *
 * Development mode with file watching for the skill-writer-builder.
 * Watches source directories (refs/, templates/, eval/, optimize/) and
 * automatically rebuilds when files change.
 *
 * @module builder/src/commands/dev
 * @version 2.2.0
 */

const chokidar = require('chokidar');
const chalk = require('chalk');
const path = require('path');
const { readAllCoreData } = require('../core/reader');
const { generateSkillFile } = require('../core/embedder');
const { getPlatform, isSupported, getSupportedPlatforms } = require('../platforms');
const fs = require('fs-extra');
const config = require('../config');
const { getSkillMetadata } = require('../metadata');

// JSON_OUTPUT_PLATFORMS is the canonical SSOT in config — do not redefine here.
const { JSON_OUTPUT_PLATFORMS } = config;

// Source directories to watch — use PATHS from config (SSoT) instead of a
// hard-coded nonexistent 'builder/core/' path.
const WATCH_DIRS = [
  config.PATHS.refs,
  config.PATHS.templates,
  config.PATHS.eval,
  config.PATHS.optimize,
];

// Debounce timeout in milliseconds
const DEBOUNCE_MS = 300;

/**
 * Format timestamp for display
 * @returns {string} Formatted timestamp
 */
function getTimestamp() {
  const now = new Date();
  return now.toLocaleTimeString('en-US', {
    hour12: false,
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit'
  });
}

/**
 * Log a message with timestamp
 * @param {string} message - Message to log
 * @param {string} type - Message type (info, success, error, warning)
 */
function log(message, type = 'info') {
  const timestamp = chalk.gray(`[${getTimestamp()}]`);
  let coloredMessage;

  switch (type) {
    case 'success':
      coloredMessage = chalk.green(message);
      break;
    case 'error':
      coloredMessage = chalk.red(message);
      break;
    case 'warning':
      coloredMessage = chalk.yellow(message);
      break;
    case 'change':
      coloredMessage = chalk.cyan(message);
      break;
    default:
      coloredMessage = chalk.white(message);
  }

  console.log(`${timestamp} ${coloredMessage}`);
}

/**
 * Build skill for specified platform
 * @param {string} platform - Target platform
 * @returns {Promise<Object>} Build result
 */
async function buildForPlatform(platform) {
  const startTime = Date.now();

  try {
    // Read all core data
    const coreData = await readAllCoreData();

    // Prepare enriched core data (metadata sourced from shared metadata.js — SSoT).
    // Spread coreData directly so all reader.js fields (securityPatterns, selfReview,
    // evolution, useToEvolve, convergence, sessionArtifact, editAudit, skillRegistry,
    // progressiveDisclosure, rubrics, benchmarks, strategies, antiPatterns, templates)
    // are passed through unchanged — matching exactly what build.js does.
    const enrichedCoreData = {
      ...coreData,
      metadata: getSkillMetadata(platform),
    };

    // Generate skill file
    const result = generateSkillFile(platform, enrichedCoreData);

    // Get platform install path
    const platformAdapter = getPlatform(platform);
    const outputDir = platformAdapter.getInstallPath();

    // Ensure output directory exists
    await fs.ensureDir(outputDir);

    // Write output file — use .json for JSON platforms (openai, mcp, a2a), .md for all others
    const fileExtension = JSON_OUTPUT_PLATFORMS.has(platform) ? 'json' : 'md';
    const outputFile = path.join(outputDir, `skill-writer.${fileExtension}`);
    await fs.writeFile(outputFile, result.content, 'utf8');

    const duration = Date.now() - startTime;

    return {
      success: true,
      platform,
      outputFile,
      duration,
      contentLength: result.content.length
    };
  } catch (error) {
    return {
      success: false,
      platform,
      error: error.message,
      stack: error.stack
    };
  }
}

/**
 * Handle file change event
 * @param {string} platform - Target platform
 * @param {string} eventType - Type of change (change, add, unlink)
 * @param {string} filePath - Path to changed file
 * @param {Function} rebuildFn - Rebuild function
 */
async function handleFileChange(platform, eventType, filePath, rebuildFn) {
  const relativePath = path.relative(config.PATHS.root, filePath);
  const eventLabels = {
    change: chalk.yellow('modified'),
    add: chalk.green('added'),
    unlink: chalk.red('removed')
  };

  log(`File ${eventLabels[eventType] || eventType}: ${chalk.gray(relativePath)}`, 'change');

  // Trigger rebuild
  await rebuildFn(platform);
}

/**
 * Perform rebuild
 * @param {string} platform - Target platform
 */
async function performRebuild(platform) {
  log(`Rebuilding for ${chalk.cyan(platform)}...`);

  const result = await buildForPlatform(platform);

  if (result.success) {
    log(
      `Build ${chalk.green('successful')} in ${chalk.gray(result.duration + 'ms')} ` +
      `(${chalk.gray(result.contentLength + ' bytes')} written to ${chalk.gray(result.outputFile)})`,
      'success'
    );
  } else {
    log(`Build ${chalk.red('failed')}: ${result.error}`, 'error');
    if (result.stack) {
      console.error(chalk.gray(result.stack));
    }
  }
}

/**
 * Development mode with file watching
 *
 * @param {Object} options - Command options
 * @param {string} options.platform - Target platform to watch
 * @returns {Promise<void>}
 */
async function dev(options) {
  const platform = options.platform || 'opencode';

  // Validate platform
  if (!isSupported(platform)) {
    throw new Error(
      `Unsupported platform: ${platform}. ` +
      `Supported platforms: ${getSupportedPlatforms().join(', ')}`
    );
  }

  log(chalk.bold(`Starting development mode for ${chalk.cyan(platform)}`));
  log(`Watching: ${WATCH_DIRS.map(d => chalk.gray(path.relative(config.PATHS.root, d))).join(', ')}`);
  log(`Press ${chalk.gray('Ctrl+C')} to stop\n`);

  // Perform initial build
  await performRebuild(platform);

  // Create debounced rebuild function
  let debounceTimer = null;

  const debouncedRebuild = (targetPlatform) => {
    if (debounceTimer) {
      clearTimeout(debounceTimer);
    }

    debounceTimer = setTimeout(() => {
      performRebuild(targetPlatform).catch((err) => {
        log(`Unhandled rebuild error: ${err.message}`, 'error');
      });
    }, DEBOUNCE_MS);
  };

  // Initialize file watcher — watch all actual source directories
  const watcher = chokidar.watch(WATCH_DIRS, {
    ignored: [
      /(^|[\/\\])\../,  // dotfiles
      '**/node_modules/**',
      '**/*.tmp',
      '**/*.temp'
    ],
    persistent: true,
    ignoreInitial: true,
    awaitWriteFinish: {
      stabilityThreshold: 100,
      pollInterval: 100
    }
  });

  // Handle file change events
  watcher
    .on('change', (filePath) => {
      handleFileChange(platform, 'change', filePath, debouncedRebuild);
    })
    .on('add', (filePath) => {
      handleFileChange(platform, 'add', filePath, debouncedRebuild);
    })
    .on('unlink', (filePath) => {
      handleFileChange(platform, 'unlink', filePath, debouncedRebuild);
    })
    .on('error', (error) => {
      log(`Watcher error: ${error.message}`, 'error');
    })
    .on('ready', () => {
      log(`Watcher ready. ${chalk.gray('Watching for changes...')}`);
    });

  // Handle process termination
  process.on('SIGINT', () => {
    log('\nStopping watcher...', 'info');
    watcher.close().then(() => {
      log('Watcher stopped. Goodbye!', 'info');
      process.exit(0);
    }).catch((err) => {
      log(`Error stopping watcher: ${err.message}`, 'error');
      process.exit(1);
    });
  });

  process.on('SIGTERM', () => {
    watcher.close().then(() => {
      process.exit(0);
    }).catch(() => {
      process.exit(1);
    });
  });

  // Keep the process running
  return new Promise(() => {});
}

module.exports = dev;
