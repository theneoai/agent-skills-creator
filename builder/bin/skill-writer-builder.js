#!/usr/bin/env node

const { program } = require('commander');
const chalk = require('chalk');
const pkg = require('../package.json');

// Import commands
const build = require('../src/commands/build');
const dev = require('../src/commands/dev');
const { validate } = require('../src/commands/validate');
const inspect = require('../src/commands/inspect');

program
  .name('skill-writer-builder')
  .description('Build tool for skill-writer - embeds core engine into platform-specific skills')
  .version(pkg.version);

// Build command
program
  .command('build')
  .description('Build platform-specific skills from core engine')
  .option('-p, --platform <platform>', 'Target platform (opencode, openclaw, claude, cursor, openai, gemini, mcp)')
  .option('-a, --all', 'Build all platforms')
  .option('-r, --release', 'Release build (optimized)')
  .option('-o, --output <dir>', 'Output directory', 'platforms')
  .option('--dry-run', 'Preview what would be written without writing files')
  .action(async (options) => {
    try {
      await build(options);
    } catch (error) {
      console.error(chalk.red('Build failed:'), error.message);
      process.exit(1);
    }
  });

// Dev command (watch mode)
program
  .command('dev')
  .description('Development mode with file watching')
  .option('-p, --platform <platform>', 'Target platform', 'opencode')
  .action(async (options) => {
    try {
      await dev(options);
    } catch (error) {
      console.error(chalk.red('Dev mode failed:'), error.message);
      process.exit(1);
    }
  });

// Validate command
program
  .command('validate')
  .description('Validate core engine structure and content')
  .action(async () => {
    try {
      const result = await validate();
      // Propagate validation failure to the shell so CI pipelines can detect it
      if (!result.valid) {
        process.exit(1);
      }
    } catch (error) {
      console.error(chalk.red('Validation failed:'), error.message);
      process.exit(1);
    }
  });

// Inspect command
program
  .command('inspect')
  .description('Inspect build output for a platform')
  .option('-p, --platform <platform>', 'Target platform', 'opencode')
  .action(async (options) => {
    try {
      await inspect(options);
    } catch (error) {
      console.error(chalk.red('Inspection failed:'), error.message);
      process.exit(1);
    }
  });

// Parse CLI arguments
program.parse();

// Show help if no command provided
if (!process.argv.slice(2).length) {
  program.outputHelp();
}
