#!/usr/bin/env node

/**
 * 플러그인 설정 파일 유효성 검사 스크립트
 * - marketplace.json 검증
 * - 모든 plugin.json 파일 검증
 * - 참조 경로 존재 여부 확인
 */

const fs = require('fs');
const path = require('path');

// 색상 출력
const colors = {
  reset: '\x1b[0m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

// 에러 수집
const errors = [];
const warnings = [];

/**
 * JSON 파일 읽기 및 파싱
 */
function readJSON(filePath) {
  try {
    const content = fs.readFileSync(filePath, 'utf8');
    return JSON.parse(content);
  } catch (error) {
    errors.push(`JSON 파싱 실패: ${filePath} - ${error.message}`);
    return null;
  }
}

/**
 * 경로에서 변수 치환
 * ${CLAUDE_PLUGIN_ROOT} -> 프로젝트 루트 경로
 */
function resolvePathVariables(pathStr, rootDir) {
  return pathStr.replace(/\$\{CLAUDE_PLUGIN_ROOT\}/g, rootDir);
}

/**
 * 파일 또는 디렉토리 존재 확인
 */
function checkPathExists(basePath, relativePath, context, rootDir = null) {
  // 변수 치환
  let resolvedPath = relativePath;
  if (rootDir && relativePath.includes('${CLAUDE_PLUGIN_ROOT}')) {
    resolvedPath = resolvePathVariables(relativePath, '.');
  }

  const fullPath = path.resolve(basePath, resolvedPath);

  if (!fs.existsSync(fullPath)) {
    errors.push(`${context}: 경로가 존재하지 않음 - ${relativePath} (${fullPath})`);
    return false;
  }
  return true;
}

/**
 * marketplace.json 검증
 */
function validateMarketplace(filePath, rootDir = process.cwd()) {
  log(`\n[marketplace.json 검증]`, 'cyan');
  log(`파일: ${filePath}`, 'blue');

  const data = readJSON(filePath);
  if (!data) return false;

  // 필수 필드 검증
  const requiredFields = ['name', 'owner', 'metadata', 'plugins'];
  let hasErrors = false;

  for (const field of requiredFields) {
    if (!data[field]) {
      errors.push(`marketplace.json: 필수 필드 누락 - ${field}`);
      hasErrors = true;
    }
  }

  // owner 검증
  if (data.owner && !data.owner.name) {
    errors.push('marketplace.json: owner.name 필드 누락');
    hasErrors = true;
  }

  // metadata 검증
  if (data.metadata) {
    if (!data.metadata.description) {
      warnings.push('marketplace.json: metadata.description 권장');
    }
  }

  // plugins 배열 검증
  if (data.plugins && Array.isArray(data.plugins)) {
    // marketplace.json이 .claude-plugin/marketplace.json에 있다면
    // basePath는 프로젝트 루트 (.claude-plugin의 부모)여야 함
    const marketplaceDir = path.dirname(filePath);
    const basePath = marketplaceDir.endsWith('.claude-plugin')
      ? path.dirname(marketplaceDir)  // .claude-plugin의 부모 = 프로젝트 루트
      : marketplaceDir;

    data.plugins.forEach((plugin, index) => {
      const context = `marketplace.json > plugins[${index}] (${plugin.name || 'unnamed'})`;

      // 필수 필드
      if (!plugin.name) {
        errors.push(`${context}: name 필드 누락`);
        hasErrors = true;
      }

      // source 경로 확인 (첫 번째 플러그인은 "./" 가능)
      if (plugin.source) {
        if (plugin.source !== './') {
          checkPathExists(basePath, plugin.source, context, rootDir);
        }
      }

      // version, description, author 권장
      if (!plugin.version) {
        warnings.push(`${context}: version 필드 권장`);
      }
      if (!plugin.description) {
        warnings.push(`${context}: description 필드 권장`);
      }

      // skills, commands, agents 경로 확인 (첫 번째 플러그인만)
      if (index === 0) {
        ['skills', 'commands', 'agents'].forEach(arrayField => {
          if (plugin[arrayField] && Array.isArray(plugin[arrayField])) {
            plugin[arrayField].forEach((itemPath, itemIndex) => {
              checkPathExists(basePath, itemPath, `${context} > ${arrayField}[${itemIndex}]`, rootDir);
            });
          }
        });
      }
    });
  }

  if (!hasErrors) {
    log('✓ marketplace.json 검증 통과', 'green');
  }

  return !hasErrors;
}

/**
 * plugin.json 검증
 */
function validatePlugin(filePath, rootDir = process.cwd()) {
  const relativePath = path.relative(process.cwd(), filePath);
  log(`\n[plugin.json 검증]`, 'cyan');
  log(`파일: ${relativePath}`, 'blue');

  const data = readJSON(filePath);
  if (!data) return false;

  // 필수 필드 검증
  const requiredFields = ['name', 'version', 'description'];
  let hasErrors = false;

  for (const field of requiredFields) {
    if (!data[field]) {
      errors.push(`${relativePath}: 필수 필드 누락 - ${field}`);
      hasErrors = true;
    }
  }

  // author 검증
  if (data.author) {
    if (!data.author.name) {
      errors.push(`${relativePath}: author.name 필드 누락`);
      hasErrors = true;
    }
  } else {
    warnings.push(`${relativePath}: author 필드 권장`);
  }

  // version 형식 검증 (semver)
  if (data.version && !/^\d+\.\d+\.\d+/.test(data.version)) {
    warnings.push(`${relativePath}: version이 semver 형식을 따르지 않음 (예: 1.0.0)`);
  }

  // 경로 참조 검증
  // plugin.json이 .claude-plugin/plugin.json에 있다면
  // basePath는 plugin source 폴더 (.claude-plugin의 부모)여야 함
  const pluginJsonDir = path.dirname(filePath);
  const basePath = pluginJsonDir.endsWith('.claude-plugin')
    ? path.dirname(pluginJsonDir)  // .claude-plugin의 부모 = plugin source 폴더
    : pluginJsonDir;

  ['skills', 'commands', 'agents'].forEach(arrayField => {
    if (data[arrayField]) {
      if (!Array.isArray(data[arrayField])) {
        errors.push(`${relativePath}: ${arrayField}는 배열이어야 함`);
        hasErrors = true;
        return;
      }

      data[arrayField].forEach((item, index) => {
        // 문자열 경로인 경우
        if (typeof item === 'string') {
          checkPathExists(basePath, item, `${relativePath} > ${arrayField}[${index}]`, rootDir);
        }
        // 객체인 경우 (source 필드 확인)
        else if (typeof item === 'object' && item.source) {
          checkPathExists(basePath, item.source, `${relativePath} > ${arrayField}[${index}]`, rootDir);
        } else {
          errors.push(`${relativePath} > ${arrayField}[${index}]: 유효하지 않은 형식 (문자열 또는 {source: ...} 객체 필요)`);
          hasErrors = true;
        }
      });
    }
  });

  if (!hasErrors) {
    log('✓ plugin.json 검증 통과', 'green');
  }

  return !hasErrors;
}

/**
 * 모든 plugin.json 파일 찾기
 */
function findPluginJsonFiles(rootDir) {
  const pluginFiles = [];

  function walk(dir) {
    const files = fs.readdirSync(dir);

    for (const file of files) {
      const fullPath = path.join(dir, file);
      const stat = fs.statSync(fullPath);

      if (stat.isDirectory()) {
        // node_modules, .git 등 제외
        if (!file.startsWith('.') || file === '.claude-plugin') {
          walk(fullPath);
        }
      } else if (file === 'plugin.json') {
        pluginFiles.push(fullPath);
      }
    }
  }

  walk(rootDir);
  return pluginFiles;
}

/**
 * 메인 실행
 */
function main() {
  log('='.repeat(60), 'cyan');
  log('플러그인 설정 파일 유효성 검사', 'cyan');
  log('='.repeat(60), 'cyan');

  const rootDir = process.cwd();

  // 1. marketplace.json 검증
  const marketplacePath = path.join(rootDir, '.claude-plugin', 'marketplace.json');

  if (fs.existsSync(marketplacePath)) {
    validateMarketplace(marketplacePath, rootDir);
  } else {
    errors.push('marketplace.json 파일을 찾을 수 없음: .claude-plugin/marketplace.json');
  }

  // 2. 모든 plugin.json 파일 검증
  const pluginFiles = findPluginJsonFiles(rootDir);

  log(`\n발견된 plugin.json 파일: ${pluginFiles.length}개`, 'yellow');
  pluginFiles.forEach(file => {
    log(`  - ${path.relative(rootDir, file)}`, 'blue');
  });

  pluginFiles.forEach(file => {
    validatePlugin(file, rootDir);
  });

  // 3. 결과 출력
  log('\n' + '='.repeat(60), 'cyan');
  log('검증 결과', 'cyan');
  log('='.repeat(60), 'cyan');

  if (warnings.length > 0) {
    log(`\n경고 (${warnings.length}개):`, 'yellow');
    warnings.forEach(warning => {
      log(`  ⚠ ${warning}`, 'yellow');
    });
  }

  if (errors.length > 0) {
    log(`\n에러 (${errors.length}개):`, 'red');
    errors.forEach(error => {
      log(`  ✗ ${error}`, 'red');
    });
    log('\n검증 실패!', 'red');
    process.exit(1);
  } else {
    log('\n✓ 모든 검증 통과!', 'green');
    if (warnings.length > 0) {
      log(`  (경고 ${warnings.length}개 - 권장사항)`, 'yellow');
    }
    process.exit(0);
  }
}

// 실행
if (require.main === module) {
  main();
}

module.exports = {
  validateMarketplace,
  validatePlugin,
  findPluginJsonFiles,
};
