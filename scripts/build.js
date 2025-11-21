#!/usr/bin/env node

/**
 * Build script for cc-skills plugin
 * Copies source files from src/ to plugin/ directory for distribution
 *
 * Usage: node scripts/build.js
 */

const fs = require('fs');
const path = require('path');

// Color codes for terminal output
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  red: '\x1b[31m',
  blue: '\x1b[34m',
  dim: '\x1b[2m'
};

// Paths
const rootDir = path.resolve(__dirname, '..');
const srcDir = path.join(rootDir, 'src');
const pluginDir = path.join(rootDir, 'plugin');
const srcPluginJsonPath = path.join(rootDir, '.claude-plugin', 'plugin.json');
const destPluginDir = path.join(pluginDir, '.claude-plugin');
const destPluginJsonPath = path.join(destPluginDir, 'plugin.json');

// Counters for stats
const stats = {
  files: 0,
  dirs: 0,
  bytes: 0
};

/**
 * Log with color
 */
function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

/**
 * Recursively copy directory
 */
function copyDir(src, dest) {
  // Create destination directory
  if (!fs.existsSync(dest)) {
    fs.mkdirSync(dest, { recursive: true });
    stats.dirs++;
  }

  // Read source directory
  const entries = fs.readdirSync(src, { withFileTypes: true });

  for (const entry of entries) {
    const srcPath = path.join(src, entry.name);
    const destPath = path.join(dest, entry.name);

    if (entry.isDirectory()) {
      copyDir(srcPath, destPath);
    } else {
      fs.copyFileSync(srcPath, destPath);
      stats.files++;
      stats.bytes += fs.statSync(destPath).size;
    }
  }
}

/**
 * Validate JSON file
 */
function validateJson(filePath, label) {
  try {
    const content = fs.readFileSync(filePath, 'utf8');
    JSON.parse(content);
    log(`✓ ${label} validation passed`, 'green');
    return true;
  } catch (err) {
    log(`✗ ${label} validation failed: ${err.message}`, 'red');
    return false;
  }
}

/**
 * Format bytes to human readable
 */
function formatBytes(bytes) {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
}

/**
 * Main build process
 */
async function build() {
  log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', 'blue');
  log('  cc-skills 플러그인 빌드 시작', 'blue');
  log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n', 'blue');

  try {
    // Step 1: Clean plugin directory (except .gitkeep)
    log('1. plugin/ 디렉토리 초기화 중...', 'dim');
    if (fs.existsSync(pluginDir)) {
      const entries = fs.readdirSync(pluginDir);
      for (const entry of entries) {
        if (entry === '.gitkeep') continue;
        const entryPath = path.join(pluginDir, entry);
        const stat = fs.statSync(entryPath);
        if (stat.isDirectory()) {
          fs.rmSync(entryPath, { recursive: true, force: true });
        } else {
          fs.unlinkSync(entryPath);
        }
      }
      log('   ✓ 기존 파일 정리 완료', 'green');
    } else {
      fs.mkdirSync(pluginDir, { recursive: true });
      log('   ✓ plugin/ 디렉토리 생성', 'green');
    }

    // Step 2: Validate skill-rules.json before copying
    log('\n2. 소스 파일 검증 중...', 'dim');
    const skillRulesPath = path.join(srcDir, 'skills', 'skill-rules.json');
    if (fs.existsSync(skillRulesPath)) {
      if (!validateJson(skillRulesPath, 'skill-rules.json')) {
        throw new Error('skill-rules.json 검증 실패');
      }
    } else {
      log('   ⚠ skill-rules.json 파일 없음 (선택 사항)', 'yellow');
    }

    // Validate plugin.json
    if (!validateJson(srcPluginJsonPath, 'plugin.json')) {
      throw new Error('plugin.json 검증 실패');
    }

    // Step 3: Copy source directories
    log('\n3. 소스 파일 복사 중...', 'dim');

    const copyTasks = [
      { name: 'skills', src: path.join(srcDir, 'skills'), dest: path.join(pluginDir, 'skills') },
      { name: 'commands', src: path.join(srcDir, 'commands'), dest: path.join(pluginDir, 'commands') },
      { name: 'hooks', src: path.join(srcDir, 'hooks'), dest: path.join(pluginDir, 'hooks') },
      { name: 'agents', src: path.join(srcDir, 'agents'), dest: path.join(pluginDir, 'agents') }
    ];

    for (const task of copyTasks) {
      if (fs.existsSync(task.src)) {
        copyDir(task.src, task.dest);
        const count = fs.readdirSync(task.src).length;
        log(`   ✓ ${task.name}/ 복사 완료 (${count}개 항목)`, 'green');
      } else {
        log(`   ⚠ ${task.name}/ 디렉토리 없음`, 'yellow');
      }
    }

    // Step 4: Copy and update plugin.json to .claude-plugin/
    log('\n4. 메타데이터 파일 복사 중...', 'dim');

    // Create .claude-plugin directory in plugin/
    if (!fs.existsSync(destPluginDir)) {
      fs.mkdirSync(destPluginDir, { recursive: true });
    }

    const pluginJsonContent = JSON.parse(fs.readFileSync(srcPluginJsonPath, 'utf8'));

    // Update paths to remove './src/' prefix (agents and hooks paths)
    if (pluginJsonContent.agents) {
      pluginJsonContent.agents = pluginJsonContent.agents.map(path =>
        path.replace('./src/', './')
      );
    }
    if (pluginJsonContent.hooks) {
      pluginJsonContent.hooks = pluginJsonContent.hooks.replace('./src/', './');
    }

    // Write to plugin/.claude-plugin/plugin.json
    fs.writeFileSync(
      destPluginJsonPath,
      JSON.stringify(pluginJsonContent, null, 2) + '\n'
    );
    stats.files++;
    log('   ✓ plugin.json 복사 및 경로 수정 완료 (.claude-plugin/plugin.json)', 'green');

    // Step 5: Copy documentation files (optional)
    log('\n5. 문서 파일 복사 중...', 'dim');
    const docFiles = ['README.md', 'CLAUDE.md'];
    for (const doc of docFiles) {
      const srcPath = path.join(rootDir, doc);
      if (fs.existsSync(srcPath)) {
        fs.copyFileSync(srcPath, path.join(pluginDir, doc));
        stats.files++;
        log(`   ✓ ${doc} 복사 완료`, 'green');
      } else {
        log(`   - ${doc} 없음 (선택 사항)`, 'dim');
      }
    }

    // Step 6: Verify essential files
    log('\n6. 빌드 결과 검증 중...', 'dim');
    const essentialFiles = [
      '.claude-plugin/plugin.json',
      'skills/skill-rules.json',
      'hooks/hooks.json'
    ];

    let validationPassed = true;
    for (const file of essentialFiles) {
      const filePath = path.join(pluginDir, file);
      if (fs.existsSync(filePath)) {
        log(`   ✓ ${file} 존재 확인`, 'green');
      } else {
        log(`   ✗ ${file} 누락`, 'red');
        validationPassed = false;
      }
    }

    if (!validationPassed) {
      throw new Error('필수 파일 검증 실패');
    }

    // Success summary
    log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', 'green');
    log('  빌드 성공!', 'green');
    log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', 'green');
    log(`\n통계:`, 'dim');
    log(`  파일: ${stats.files}개`, 'dim');
    log(`  디렉토리: ${stats.dirs}개`, 'dim');
    log(`  총 크기: ${formatBytes(stats.bytes)}`, 'dim');
    log(`\n배포 디렉토리: ${pluginDir}`, 'dim');
    log('');

    process.exit(0);

  } catch (err) {
    log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', 'red');
    log('  빌드 실패', 'red');
    log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', 'red');
    log(`\n에러: ${err.message}`, 'red');
    if (err.stack) {
      log(`\n${err.stack}`, 'dim');
    }
    log('');
    process.exit(1);
  }
}

// Run build
build();
