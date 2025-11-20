#!/usr/bin/env node

/**
 * Claude Code Hooks 설치 스크립트
 *
 * 사용법:
 *   node scripts/install-hooks.js
 *   node scripts/install-hooks.js --yes
 *   node scripts/install-hooks.js --dry-run
 *   node scripts/install-hooks.js --force
 *   node scripts/install-hooks.js --merge
 */

const fs = require('fs').promises;
const fsSync = require('fs');
const path = require('path');
const readline = require('readline');
const { execSync } = require('child_process');

// ============================================================================
// Constants and Configuration
// ============================================================================

const VERSION = '1.0.0';

const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  red: '\x1b[31m',
  cyan: '\x1b[36m',
  gray: '\x1b[90m'
};

const config = {
  dryRun: false,
  autoConfirm: false,
  force: false,
  merge: true,
  sourceDir: path.join(__dirname, '..', 'hooks'),
  targetDir: null,
  settingsFile: null,
  stats: {
    copied: [],
    skipped: [],
    backed: [],
    errors: []
  },
  operations: []
};

// ============================================================================
// Utility Functions
// ============================================================================

function log(message, color = '') {
  console.log(`${color}${message}${colors.reset}`);
}

function logSuccess(message) {
  log(`✓ ${message}`, colors.green);
}

function logInfo(message) {
  log(`ℹ ${message}`, colors.blue);
}

function logWarning(message) {
  log(`⚠ ${message}`, colors.yellow);
}

function logError(message) {
  log(`✗ ${message}`, colors.red);
}

function logSection(message) {
  console.log('');
  log(message, colors.bright + colors.cyan);
  log('━'.repeat(50), colors.gray);
}

function getHomeDir() {
  return process.env.HOME || process.env.USERPROFILE || '';
}

function getTimestamp() {
  const now = new Date();
  return now.toISOString().replace(/[:.]/g, '-').split('.')[0];
}

function ask(question) {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });

  return new Promise(resolve => {
    rl.question(question, answer => {
      rl.close();
      resolve(answer);
    });
  });
}

async function ensureDirectory(dir) {
  try {
    await fs.mkdir(dir, { recursive: true });
    return true;
  } catch (err) {
    logError(`Failed to create directory: ${dir}`);
    logError(err.message);
    return false;
  }
}

// ============================================================================
// Hook File Detection
// ============================================================================

const HOOK_DEFINITIONS = {
  'skill-activation-prompt.ts': {
    type: 'UserPromptSubmit',
    matcher: '',
    command: 'npx tsx ~/.claude/hooks/skill-activation-prompt.ts'
  },
  'meta-prompt-logger.js': {
    type: 'UserPromptSubmit',
    matcher: '',
    command: 'node ~/.claude/hooks/meta-prompt-logger.js'
  },
  'post-tool-use-tracker.sh': {
    type: 'PostToolUse',
    matcher: 'Edit|Write',
    command: 'bash ~/.claude/hooks/post-tool-use-tracker.sh'
  },
  'stop-hook-lint-and-translate.sh': {
    type: 'Stop',
    matcher: '',
    command: 'bash ~/.claude/hooks/stop-hook-lint-and-translate.sh'
  }
};

async function discoverHooks() {
  const files = await fs.readdir(config.sourceDir);
  const hooks = [];

  for (const file of files) {
    // Skip non-hook files
    if (file === 'node_modules' || file === 'package.json' ||
        file === 'package-lock.json' || file === 'tsconfig.json' ||
        file === 'hooks.json' || file === 'README.md') {
      continue;
    }

    // Only process .sh, .ts, .js files
    if (!/\.(sh|ts|js)$/.test(file)) {
      continue;
    }

    const filePath = path.join(config.sourceDir, file);
    const stat = await fs.stat(filePath);

    if (stat.isFile()) {
      const hookDef = HOOK_DEFINITIONS[file];
      hooks.push({
        file,
        path: filePath,
        type: hookDef?.type || 'Unknown',
        matcher: hookDef?.matcher || '',
        command: hookDef?.command || ''
      });
    }
  }

  return hooks;
}

// ============================================================================
// Settings.json Management
// ============================================================================

async function loadSettings() {
  try {
    if (!fsSync.existsSync(config.settingsFile)) {
      return { hooks: {} };
    }

    const content = await fs.readFile(config.settingsFile, 'utf-8');
    return JSON.parse(content);
  } catch (err) {
    logError(`Failed to parse ${config.settingsFile}`);
    throw err;
  }
}

async function backupSettings() {
  if (!fsSync.existsSync(config.settingsFile)) {
    return null;
  }

  const timestamp = getTimestamp();
  const backupFile = `${config.settingsFile}.backup.${timestamp}`;

  try {
    await fs.copyFile(config.settingsFile, backupFile);
    config.operations.push({ type: 'backup', file: backupFile });
    return backupFile;
  } catch (err) {
    logError(`Failed to create backup: ${err.message}`);
    throw err;
  }
}

function mergeHooks(existing, newHooks) {
  const merged = { ...existing };

  // Group new hooks by type
  const hooksByType = {};
  for (const hook of newHooks) {
    if (!hooksByType[hook.type]) {
      hooksByType[hook.type] = [];
    }
    hooksByType[hook.type].push({
      matcher: hook.matcher,
      hooks: [{
        type: 'command',
        command: hook.command
      }]
    });
  }

  // Merge each type
  for (const [type, hooks] of Object.entries(hooksByType)) {
    if (config.merge && merged[type]) {
      // Merge mode: combine with existing
      merged[type] = [...merged[type], ...hooks];
    } else {
      // Replace mode: overwrite
      merged[type] = hooks;
    }
  }

  return merged;
}

async function saveSettings(settings) {
  const content = JSON.stringify(settings, null, 2);

  if (config.dryRun) {
    logInfo('[DRY RUN] Would save settings.json');
    return;
  }

  try {
    await fs.writeFile(config.settingsFile, content, 'utf-8');
    config.operations.push({ type: 'settings', file: config.settingsFile });
  } catch (err) {
    logError(`Failed to save settings: ${err.message}`);
    throw err;
  }
}

// ============================================================================
// Hook Installation
// ============================================================================

async function copyHookFile(hook) {
  const targetPath = path.join(config.targetDir, hook.file);

  // Check if file exists
  if (fsSync.existsSync(targetPath) && !config.force) {
    logWarning(`File already exists: ${hook.file}`);
    if (!config.autoConfirm) {
      const answer = await ask(`  Overwrite? (y/N): `);
      if (answer.toLowerCase() !== 'y') {
        config.stats.skipped.push(hook.file);
        return false;
      }
    }

    // Backup existing file
    const backupPath = `${targetPath}.backup.${getTimestamp()}`;
    await fs.copyFile(targetPath, backupPath);
    config.stats.backed.push(path.basename(backupPath));
    config.operations.push({ type: 'backup', file: backupPath });
  }

  if (config.dryRun) {
    logInfo(`[DRY RUN] Would copy: ${hook.file}`);
    return true;
  }

  try {
    // Copy file
    await fs.copyFile(hook.path, targetPath);

    // Set executable permission for shell scripts
    if (hook.file.endsWith('.sh')) {
      await fs.chmod(targetPath, 0o755);
    }

    config.stats.copied.push(hook.file);
    config.operations.push({ type: 'copy', file: targetPath });
    return true;
  } catch (err) {
    logError(`Failed to copy ${hook.file}: ${err.message}`);
    config.stats.errors.push({ file: hook.file, error: err.message });
    return false;
  }
}

async function installDependencies() {
  const packageJsonPath = path.join(config.sourceDir, 'package.json');

  if (!fsSync.existsSync(packageJsonPath)) {
    return;
  }

  logSection('Installing Dependencies');
  logInfo('Found package.json in hooks/');

  // Copy package.json
  const targetPackageJson = path.join(config.targetDir, 'package.json');
  if (config.dryRun) {
    logInfo('[DRY RUN] Would copy package.json and run npm install');
    return;
  }

  try {
    await fs.copyFile(packageJsonPath, targetPackageJson);

    // Run npm install
    logInfo('Running npm install...');
    execSync('npm install', {
      cwd: config.targetDir,
      stdio: 'inherit'
    });

    logSuccess('Dependencies installed');
  } catch (err) {
    logError(`Failed to install dependencies: ${err.message}`);
  }
}

// ============================================================================
// Verification
// ============================================================================

async function verifyInstallation(hooks) {
  logSection('Verifying Installation');

  let allGood = true;

  for (const hook of hooks) {
    const targetPath = path.join(config.targetDir, hook.file);

    // Check file exists
    if (!fsSync.existsSync(targetPath)) {
      logError(`Missing: ${hook.file}`);
      allGood = false;
      continue;
    }

    // Check permissions for shell scripts
    if (hook.file.endsWith('.sh')) {
      try {
        const stats = await fs.stat(targetPath);
        const isExecutable = (stats.mode & 0o111) !== 0;
        if (!isExecutable) {
          logWarning(`Not executable: ${hook.file}`);
        }
      } catch (err) {
        // Ignore stat errors
      }
    }
  }

  // Verify settings.json
  try {
    const settings = await loadSettings();
    if (!settings.hooks || Object.keys(settings.hooks).length === 0) {
      logWarning('No hooks configured in settings.json');
      allGood = false;
    }
  } catch (err) {
    logError('Failed to verify settings.json');
    allGood = false;
  }

  if (allGood) {
    logSuccess('All checks passed');
  }

  return allGood;
}

// ============================================================================
// Main Installation Logic
// ============================================================================

async function install() {
  // Header
  console.log('');
  log('🎣 Claude Code Hooks Installer', colors.bright + colors.cyan);
  log(`   Version ${VERSION}`, colors.gray);
  log('━'.repeat(50), colors.gray);
  console.log('');

  // Set paths
  const homeDir = getHomeDir();
  config.targetDir = path.join(homeDir, '.claude', 'hooks');
  config.settingsFile = path.join(homeDir, '.claude', 'settings.json');

  // Discover hooks
  logSection('Discovering Hooks');
  logInfo(`Source: ${config.sourceDir}`);
  logInfo(`Target: ${config.targetDir}`);
  console.log('');

  const hooks = await discoverHooks();

  if (hooks.length === 0) {
    logError('No hooks found to install');
    process.exit(1);
  }

  logInfo(`Found ${hooks.length} hook file(s):`);
  for (const hook of hooks) {
    const typeInfo = hook.type !== 'Unknown' ? ` (${hook.type})` : '';
    log(`  ✓ ${hook.file}${typeInfo}`, colors.green);
  }

  // Check settings.json
  console.log('');
  logInfo('Checking settings.json...');
  if (fsSync.existsSync(config.settingsFile)) {
    logInfo('File exists, will merge hooks section');
  } else {
    logInfo('File does not exist, will create new');
  }

  // Confirm installation
  if (!config.autoConfirm && !config.dryRun) {
    console.log('');
    const answer = await ask('Proceed with installation? (y/N): ');
    if (answer.toLowerCase() !== 'y') {
      logWarning('Installation cancelled');
      process.exit(0);
    }
  }

  // Create backup
  if (fsSync.existsSync(config.settingsFile)) {
    console.log('');
    logSection('Creating Backup');
    const backupFile = await backupSettings();
    if (backupFile) {
      logSuccess(`Backup created: ${path.basename(backupFile)}`);
    }
  }

  // Ensure target directory exists
  console.log('');
  logSection('Preparing Target Directory');
  const dirCreated = await ensureDirectory(config.targetDir);
  if (!dirCreated) {
    logError('Failed to create target directory');
    process.exit(1);
  }
  logSuccess(`Directory ready: ${config.targetDir}`);

  // Copy hook files
  console.log('');
  logSection('Copying Hook Files');
  for (const hook of hooks) {
    const success = await copyHookFile(hook);
    if (success) {
      const executable = hook.file.endsWith('.sh') ? ' (chmod +x)' : '';
      logSuccess(`Copied ${hook.file}${executable}`);
    }
  }

  // Install dependencies
  await installDependencies();

  // Update settings.json
  console.log('');
  logSection('Updating settings.json');
  try {
    const settings = await loadSettings();
    const merged = mergeHooks(settings.hooks || {}, hooks);
    settings.hooks = merged;

    await saveSettings(settings);

    const hookTypes = new Set(hooks.map(h => h.type).filter(t => t !== 'Unknown'));
    logSuccess(`Registered ${hookTypes.size} hook type(s)`);
    for (const type of hookTypes) {
      logInfo(`  → ${type}`);
    }
  } catch (err) {
    logError('Failed to update settings.json');
    throw err;
  }

  // Verify installation
  if (!config.dryRun) {
    console.log('');
    await verifyInstallation(hooks);
  }

  // Summary
  console.log('');
  log('━'.repeat(50), colors.gray);
  log('✅ Installation Complete!', colors.bright + colors.green);
  log('━'.repeat(50), colors.gray);
  console.log('');

  logInfo('Summary:');
  log(`  📁 Files copied: ${config.stats.copied.length}`, colors.cyan);
  if (config.stats.backed.length > 0) {
    log(`  💾 Files backed up: ${config.stats.backed.length}`, colors.cyan);
  }
  if (config.stats.skipped.length > 0) {
    log(`  ⏭️  Files skipped: ${config.stats.skipped.length}`, colors.yellow);
  }
  if (config.stats.errors.length > 0) {
    log(`  ❌ Errors: ${config.stats.errors.length}`, colors.red);
  }

  if (!config.dryRun) {
    console.log('');
    logInfo('Next steps:');
    console.log('  1. Restart Claude Code (if running)');
    console.log('  2. Test hooks with: /hooks');
    console.log('  3. View installed hooks: ls ~/.claude/hooks/');
  }

  console.log('');
  log('━'.repeat(50), colors.gray);
  console.log('');
}

// ============================================================================
// CLI Argument Parsing
// ============================================================================

function parseArgs() {
  const args = process.argv.slice(2);

  for (const arg of args) {
    switch (arg) {
      case '--yes':
      case '-y':
        config.autoConfirm = true;
        break;
      case '--dry-run':
        config.dryRun = true;
        logWarning('DRY RUN MODE - No changes will be made');
        break;
      case '--force':
      case '-f':
        config.force = true;
        break;
      case '--replace':
        config.merge = false;
        break;
      case '--merge':
        config.merge = true;
        break;
      case '--help':
      case '-h':
        console.log(`
Claude Code Hooks Installer v${VERSION}

Usage:
  node scripts/install-hooks.js [options]

Options:
  --yes, -y        Auto-confirm all prompts
  --dry-run        Simulate installation without making changes
  --force, -f      Overwrite existing files without asking
  --merge          Merge with existing hooks (default)
  --replace        Replace all existing hooks
  --help, -h       Show this help message

Examples:
  node scripts/install-hooks.js
  node scripts/install-hooks.js --yes --force
  node scripts/install-hooks.js --dry-run
`);
        process.exit(0);
      default:
        if (arg.startsWith('--')) {
          logError(`Unknown option: ${arg}`);
          logInfo('Use --help for usage information');
          process.exit(1);
        }
    }
  }
}

// ============================================================================
// Main Entry Point
// ============================================================================

async function main() {
  try {
    parseArgs();
    await install();
  } catch (err) {
    console.log('');
    log('━'.repeat(50), colors.gray);
    logError('Installation Failed');
    log('━'.repeat(50), colors.gray);
    console.log('');
    logError(err.message);

    if (err.stack) {
      console.log('');
      log('Stack trace:', colors.gray);
      console.log(err.stack);
    }

    process.exit(1);
  }
}

// Run if executed directly
if (require.main === module) {
  main();
}

module.exports = { install, discoverHooks, mergeHooks };
