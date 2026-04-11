/**
 * Platform Registry
 * 
 * Central registry for all platform adapters.
 * Provides unified interface for platform-specific operations.
 */

const fs = require('fs');
const path = require('path');

// Platform adapter modules
const opencode = require('./opencode');
const openclaw = require('./openclaw');
const claude = require('./claude');
const cursor = require('./cursor');
const openai = require('./openai');
const gemini = require('./gemini');
const mcp = require('./mcp');

/**
 * Registry of all supported platforms
 */
const platforms = {
  opencode,
  openclaw,
  claude,
  cursor,
  openai,
  gemini,
  mcp,
};

/**
 * Get a platform adapter by name
 * @param {string} platformName - Name of the platform
 * @returns {Object} Platform adapter
 * @throws {Error} If platform is not supported
 */
function getPlatform(platformName) {
  const platform = platforms[platformName.toLowerCase()];
  if (!platform) {
    throw new Error(
      `Unsupported platform: ${platformName}. ` +
      `Supported platforms: ${getSupportedPlatforms().join(', ')}`
    );
  }
  return platform;
}

/**
 * Get list of supported platform names
 * @returns {string[]} Array of platform names
 */
function getSupportedPlatforms() {
  return Object.keys(platforms);
}

/**
 * Check if a platform is supported
 * @param {string} platformName - Name of the platform
 * @returns {boolean} True if platform is supported
 */
function isSupported(platformName) {
  return platformName.toLowerCase() in platforms;
}

/**
 * Format skill for a specific platform
 * @param {string} platformName - Target platform name
 * @param {string} skillContent - Raw skill content
 * @returns {string} Formatted skill content
 */
function formatForPlatform(platformName, skillContent) {
  const platform = getPlatform(platformName);
  return platform.formatSkill(skillContent);
}

/**
 * Get installation path for a platform
 * @param {string} platformName - Platform name
 * @returns {string} Installation path
 */
function getInstallPath(platformName) {
  const platform = getPlatform(platformName);
  return platform.getInstallPath();
}

/**
 * Validate skill for a specific platform
 * @param {string} platformName - Platform name
 * @param {string} skillContent - Skill content to validate
 * @returns {Object} Validation result
 */
function validateForPlatform(platformName, skillContent) {
  const platform = getPlatform(platformName);
  return platform.validateSkill(skillContent);
}

/**
 * Generate platform-specific metadata
 * @param {string} platformName - Platform name
 * @param {Object} skillData - Skill data
 * @returns {Object} Platform metadata
 */
function generateMetadata(platformName, skillData) {
  const platform = getPlatform(platformName);
  return platform.generateMetadata(skillData);
}

/** Platforms that emit JSON output rather than Markdown */
const JSON_PLATFORMS = new Set(['openai', 'mcp']);

/**
 * Install skill to platform-specific location
 * @param {string} platformName - Target platform
 * @param {string} skillContent - Skill content
 * @param {string} skillName - Name of the skill (for filename)
 * @returns {Object} Installation result
 */
function installSkill(platformName, skillContent, skillName) {
  const platform = getPlatform(platformName);
  const installDir = platform.getInstallPath();
  const ext = JSON_PLATFORMS.has(platformName.toLowerCase()) ? 'json' : 'md';
  const filename = `${skillName}.${ext}`;
  const fullPath = path.join(installDir, filename);

  // Ensure install directory exists
  if (!fs.existsSync(installDir)) {
    fs.mkdirSync(installDir, { recursive: true });
  }

  // Format skill for platform
  const formattedContent = platform.formatSkill(skillContent);

  // Validate before installation
  const validation = platform.validateSkill(formattedContent);
  if (!validation.valid) {
    return {
      success: false,
      error: 'Validation failed',
      details: validation.errors,
      path: null
    };
  }

  // Write skill file
  try {
    fs.writeFileSync(fullPath, formattedContent, 'utf8');
    return {
      success: true,
      path: fullPath,
      platform: platformName,
      warnings: validation.warnings
    };
  } catch (error) {
    return {
      success: false,
      error: error.message,
      path: null
    };
  }
}

/**
 * Convert skill between platforms
 * @param {string} sourcePlatform - Source platform name
 * @param {string} targetPlatform - Target platform name
 * @param {string} skillContent - Skill content
 * @returns {string} Converted skill content
 */
function convertBetweenPlatforms(sourcePlatform, targetPlatform, skillContent) {
  const source = getPlatform(sourcePlatform);
  const target = getPlatform(targetPlatform);

  // If source has a specific export method for target, use it
  if (sourcePlatform === 'opencode' && targetPlatform === 'openclaw' && target.fromOpenCode) {
    return target.fromOpenCode(skillContent);
  }

  // Generic conversion: just format for target
  return target.formatSkill(skillContent);
}

/**
 * Get platform information
 * @param {string} platformName - Platform name
 * @returns {Object} Platform information
 */
function getPlatformInfo(platformName) {
  const platform = getPlatform(platformName);
  return {
    name: platform.name,
    template: platform.template,
    installPath: platform.getInstallPath()
  };
}

/**
 * Get all platform information
 * @returns {Object} Map of platform names to info
 */
function getAllPlatformInfo() {
  const info = {};
  for (const [name, platform] of Object.entries(platforms)) {
    info[name] = {
      name: platform.name,
      installPath: platform.getInstallPath()
    };
  }
  return info;
}

module.exports = {
  // Platform adapters
  opencode,
  openclaw,
  claude,
  cursor,
  openai,
  gemini,
  mcp,

  // Registry functions
  getPlatform,
  getSupportedPlatforms,
  isSupported,

  // Utility functions
  formatForPlatform,
  getInstallPath,
  validateForPlatform,
  generateMetadata,
  installSkill,
  convertBetweenPlatforms,
  getPlatformInfo,
  getAllPlatformInfo
};
