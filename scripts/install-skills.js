#!/usr/bin/env node

/**
 * Claude Code Skills 설치 스크립트
 *
 * 사용법:
 *   node scripts/install-skills.js
 *   node scripts/install-skills.js --target global
 *   node scripts/install-skills.js --target workspace
 *   node scripts/install-skills.js --dry-run
 */

const fs = require('fs').promises;
const fsSync = require('fs');
const path = require('path');
const readline = require('readline');
const { execSync } = require('child_process');

// 색상 코드
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  red: '\x1b[31m',
  cyan: '\x1b[36m'
};

// 소스 경로 (플러그인 루트 디렉토리)
const SOURCE_DIR = path.join(__dirname, '..');

// 설치 설정
const config = {
  dryRun: false,
  isGlobal: false, // global 설치 여부
  autoConfirm: false, // --yes 옵션
  customPath: null, // 특정 경로 지정
  targetDir: null,
  backupDir: null,
  stats: {
    copied: [],
    backed: [],
    merged: [],
    created: [],
    errors: []
  },
  operations: [] // 롤백용 작업 기록
};

// =============================================================================
// 유틸리티 함수
// =============================================================================

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

function showProgress(current, total, label) {
  const percent = Math.round((current / total) * 100);
  const filled = Math.round(percent / 5);
  const bar = '█'.repeat(filled) + '░'.repeat(20 - filled);
  process.stdout.write(`\r${colors.cyan}${bar}${colors.reset} ${percent}% ${label}`);
  if (current === total) console.log('');
}

// =============================================================================
// 보안: 경로 검증
// =============================================================================

function validatePath(targetPath) {
  const resolved = path.resolve(targetPath);
  const home = process.env.HOME || process.env.USERPROFILE;
  const cwd = process.cwd();

  // 허용된 기본 경로
  const allowedBases = [
    path.join(home, '.claude'),
    path.join(cwd, '.claude')
  ];

  // customPath가 설정된 경우 해당 경로도 허용
  if (config.customPath) {
    const customBase = path.resolve(config.customPath);
    allowedBases.push(customBase);
  }

  // 경로가 허용된 범위 내인지 확인
  const isAllowed = allowedBases.some(base =>
    resolved === base || resolved.startsWith(base + path.sep)
  );

  if (!isAllowed) {
    throw new Error(`허용되지 않은 경로: ${resolved}\n허용된 경로: ${allowedBases.join(', ')}`);
  }

  // 경로 순회 공격 방지
  if (resolved.includes('..')) {
    throw new Error(`잘못된 경로 패턴: ${resolved}`);
  }

  return resolved;
}

function validateSourcePath(srcPath) {
  const resolved = path.resolve(srcPath);
  const sourceBase = path.resolve(SOURCE_DIR);

  if (!resolved.startsWith(sourceBase)) {
    throw new Error(`소스 경로가 유효하지 않습니다: ${resolved}`);
  }

  return resolved;
}

// =============================================================================
// 대화형 입력
// =============================================================================

async function prompt(question) {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });

  return new Promise((resolve) => {
    rl.question(question, (answer) => {
      rl.close();
      resolve(answer.trim());
    });
  });
}

async function selectTarget() {
  const args = process.argv.slice(2);

  // --dry-run 옵션 확인
  if (args.includes('--dry-run')) {
    config.dryRun = true;
    logInfo('Dry-run 모드: 실제 파일 변경 없음');
  }

  // --yes 옵션 확인 (자동 확인)
  if (args.includes('--yes') || args.includes('-y')) {
    config.autoConfirm = true;
  }

  // --path 옵션 확인 (특정 경로 지정)
  const pathIndex = args.indexOf('--path');
  if (pathIndex !== -1 && args[pathIndex + 1]) {
    const customPath = args[pathIndex + 1];
    const resolved = path.resolve(customPath);

    // 보안 검증
    if (customPath.includes('..') || resolved.includes('..')) {
      throw new Error('경로에 ".."을 포함할 수 없습니다.');
    }

    // 시스템 경로 방지
    const dangerousPaths = ['/', '/etc', '/usr', '/bin', '/sbin', '/var', '/tmp'];
    if (dangerousPaths.some(p => resolved === p || resolved.startsWith(p + '/'))) {
      throw new Error(`시스템 경로는 허용되지 않습니다: ${resolved}`);
    }

    // .claude로 끝나는지 확인 (경고)
    if (!resolved.endsWith('.claude')) {
      logWarning(`경로가 .claude로 끝나지 않습니다: ${resolved}`);
    }

    config.customPath = customPath;
    logInfo(`특정 경로 사용: ${resolved}`);
    return customPath;
  }

  // --target 옵션 확인
  const targetIndex = args.indexOf('--target');
  if (targetIndex !== -1 && args[targetIndex + 1]) {
    const target = args[targetIndex + 1].toLowerCase();
    if (target === 'global') {
      config.isGlobal = true;
      return path.join(process.env.HOME || process.env.USERPROFILE, '.claude');
    }
    if (target === 'workspace') {
      config.isGlobal = false;
      return path.join(process.cwd(), '.claude');
    }
  }

  // 대화형 선택
  console.log('\n' + colors.bright + '📦 Claude Code Skills 설치' + colors.reset);
  console.log('─'.repeat(40));
  console.log('\n설치 위치를 선택하세요:\n');
  console.log('  1. global    - ~/.claude/settings.json (전역 사용자 설정)');
  console.log('  2. workspace - ./.claude/settings.local.json (로컬 프로젝트 설정)\n');

  const choice = await prompt('선택 (1 또는 2): ');

  if (choice === '1' || choice.toLowerCase() === 'global') {
    config.isGlobal = true;
    return path.join(process.env.HOME || process.env.USERPROFILE, '.claude');
  } else if (choice === '2' || choice.toLowerCase() === 'workspace') {
    config.isGlobal = false;
    return path.join(process.cwd(), '.claude');
  } else {
    throw new Error('잘못된 선택입니다.');
  }
}

// =============================================================================
// 파일 시스템 작업
// =============================================================================

async function ensureDir(dir) {
  const validDir = validatePath(dir);

  if (!fsSync.existsSync(validDir)) {
    if (!config.dryRun) {
      await fs.mkdir(validDir, { recursive: true });
      config.operations.push({ type: 'mkdir', path: validDir });
    }
    config.stats.created.push(validDir);
  }
}

async function backupFile(filePath) {
  if (!fsSync.existsSync(filePath)) return false;

  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const relativePath = path.relative(config.targetDir, filePath);
  const backupPath = path.join(config.backupDir, timestamp, relativePath);

  await ensureDir(path.dirname(backupPath));

  if (!config.dryRun) {
    const stat = await fs.stat(filePath);
    if (stat.isDirectory()) {
      // 백업 시에는 소스 경로 검증 생략 (대상 경로를 복사하므로)
      await copyDirRecursive(filePath, backupPath, false, false);
    } else {
      await fs.copyFile(filePath, backupPath);
    }
  }

  config.stats.backed.push(relativePath);
  return true;
}

async function copyDirRecursive(src, dest, track = true, validateSrc = true) {
  if (validateSrc) {
    validateSourcePath(src);
  }
  await ensureDir(dest);

  const entries = await fs.readdir(src, { withFileTypes: true });
  let processed = 0;

  for (const entry of entries) {
    const srcPath = path.join(src, entry.name);
    const destPath = path.join(dest, entry.name);

    // 제외 패턴
    if (entry.name === 'node_modules') continue;
    if (entry.name.endsWith('.old')) continue;
    if (entry.name.startsWith('.')) continue;

    if (entry.isDirectory()) {
      await copyDirRecursive(srcPath, destPath, track, validateSrc);
    } else {
      if (!config.dryRun) {
        await fs.copyFile(srcPath, destPath);
        config.operations.push({ type: 'copy', path: destPath });
      }
      if (track) {
        config.stats.copied.push(path.relative(config.targetDir, destPath));
      }
    }

    processed++;
    if (track && entries.length > 10) {
      showProgress(processed, entries.length, path.basename(src));
    }
  }
}

// =============================================================================
// JSON 병합
// =============================================================================

async function mergeJsonFile(srcPath, destPath, mergeStrategy) {
  let destData = {};

  if (fsSync.existsSync(destPath)) {
    try {
      const content = await fs.readFile(destPath, 'utf8');
      destData = JSON.parse(content);
    } catch (e) {
      logWarning(`기존 파일 파싱 실패: ${destPath}`);
    }
  }

  const srcContent = await fs.readFile(srcPath, 'utf8');
  const srcData = JSON.parse(srcContent);
  const merged = mergeStrategy(destData, srcData);

  if (!config.dryRun) {
    await fs.writeFile(destPath, JSON.stringify(merged, null, 2));
    config.operations.push({ type: 'write', path: destPath, backup: destData });
  }

  config.stats.merged.push(path.basename(destPath));
}

function mergeSkillRules(dest, src) {
  return {
    ...dest,
    version: src.version || dest.version,
    skills: {
      ...(dest.skills || {}),
      ...(src.skills || {})
    }
  };
}

function mergeSettings(dest, src, useAbsolutePaths = false) {
  const result = { ...dest };

  if (src.hooks) {
    let hooks = JSON.parse(JSON.stringify(src.hooks)); // deep copy

    // global 설치 시 hooks 경로를 절대 경로로 변환
    if (useAbsolutePaths) {
      const home = process.env.HOME || process.env.USERPROFILE;
      const absoluteBase = path.join(home, '.claude');

      for (const hookType of Object.keys(hooks)) {
        for (const hookConfig of hooks[hookType]) {
          if (hookConfig.hooks) {
            for (const hook of hookConfig.hooks) {
              if (hook.command) {
                // .claude/hooks/ → ~/.claude/hooks/
                hook.command = hook.command.replace(
                  /\.claude\/hooks\//g,
                  `${absoluteBase}/hooks/`
                );
              }
            }
          }
        }
      }
    }

    result.hooks = {
      ...(dest.hooks || {}),
      ...hooks
    };
  }

  return result;
}

// =============================================================================
// 설치 단계별 함수 (SRP 적용)
// =============================================================================

async function createDirectories() {
  logInfo('폴더 구조 생성 중...');
  const folders = ['skills', 'commands', 'hooks', 'scripts'];

  for (const folder of folders) {
    await ensureDir(path.join(config.targetDir, folder));
  }

  logSuccess('폴더 구조 생성 완료');
}

async function installSkills() {
  const srcSkills = path.join(SOURCE_DIR, 'skills');
  const destSkills = path.join(config.targetDir, 'skills');

  if (!fsSync.existsSync(srcSkills)) return;

  // skill-rules.json 병합
  const srcRules = path.join(srcSkills, 'skill-rules.json');
  const destRules = path.join(destSkills, 'skill-rules.json');

  if (fsSync.existsSync(srcRules)) {
    await backupFile(destRules);
    await mergeJsonFile(srcRules, destRules, mergeSkillRules);
    logSuccess('skill-rules.json 병합 완료');
  }

  // 스킬 폴더들 복사
  const entries = await fs.readdir(srcSkills, { withFileTypes: true });
  const skillDirs = entries.filter(e => e.isDirectory() && !e.name.endsWith('.old'));

  let count = 0;
  for (const entry of skillDirs) {
    const srcSkill = path.join(srcSkills, entry.name);
    const destSkill = path.join(destSkills, entry.name);

    await backupFile(destSkill);
    await copyDirRecursive(srcSkill, destSkill);
    count++;
    showProgress(count, skillDirs.length, `스킬 설치: ${entry.name}`);
  }

  // README.md 복사
  const srcReadme = path.join(srcSkills, 'README.md');
  const destReadme = path.join(destSkills, 'README.md');
  if (fsSync.existsSync(srcReadme) && !config.dryRun) {
    await fs.copyFile(srcReadme, destReadme);
  }

  logSuccess(`${skillDirs.length}개 스킬 설치 완료`);
}

async function installCommands() {
  const srcCommands = path.join(SOURCE_DIR, 'commands');
  const destCommands = path.join(config.targetDir, 'commands');

  if (!fsSync.existsSync(srcCommands)) return;

  const files = await fs.readdir(srcCommands);
  let count = 0;

  for (const file of files) {
    const srcFile = path.join(srcCommands, file);
    const destFile = path.join(destCommands, file);
    const stat = await fs.stat(srcFile);

    if (stat.isFile()) {
      await backupFile(destFile);
      if (!config.dryRun) {
        await fs.copyFile(srcFile, destFile);
        config.operations.push({ type: 'copy', path: destFile });
      }
      config.stats.copied.push(`commands/${file}`);
      count++;
    }
  }

  logSuccess(`${count}개 커맨드 설치 완료`);
}

async function installHooks() {
  const srcHooks = path.join(SOURCE_DIR, 'hooks');
  const destHooks = path.join(config.targetDir, 'hooks');

  if (!fsSync.existsSync(srcHooks)) return;

  const files = await fs.readdir(srcHooks);
  let count = 0;

  for (const file of files) {
    if (file === 'node_modules') continue;

    const srcFile = path.join(srcHooks, file);
    const destFile = path.join(destHooks, file);
    const stat = await fs.stat(srcFile);

    if (stat.isFile()) {
      await backupFile(destFile);
      if (!config.dryRun) {
        await fs.copyFile(srcFile, destFile);
        config.operations.push({ type: 'copy', path: destFile });

        // 실행 권한 설정
        if (file.endsWith('.sh')) {
          await fs.chmod(destFile, '755');
        }
      }
      config.stats.copied.push(`hooks/${file}`);
      count++;
    }
  }

  // npm install 실행
  const packageJson = path.join(destHooks, 'package.json');
  if (fsSync.existsSync(packageJson) && !config.dryRun) {
    logInfo('hooks 의존성 설치 중...');
    try {
      execSync('npm install', { cwd: destHooks, stdio: 'pipe' });
      logSuccess('npm install 완료');
    } catch (e) {
      logError(`npm install 실패: ${e.message}`);
      config.stats.errors.push('npm install failed');
    }
  }

  logSuccess(`${count}개 훅 설치 완료`);
}

async function installScripts() {
  const srcScripts = path.join(SOURCE_DIR, 'scripts');
  const destScripts = path.join(config.targetDir, 'scripts');

  if (!fsSync.existsSync(srcScripts)) return;

  const files = await fs.readdir(srcScripts);
  let count = 0;

  for (const file of files) {
    const srcFile = path.join(srcScripts, file);
    const destFile = path.join(destScripts, file);
    const stat = await fs.stat(srcFile);

    if (stat.isFile()) {
      await backupFile(destFile);
      if (!config.dryRun) {
        await fs.copyFile(srcFile, destFile);
        config.operations.push({ type: 'copy', path: destFile });
      }
      config.stats.copied.push(`scripts/${file}`);
      count++;
    }
  }

  logSuccess(`${count}개 스크립트 설치 완료`);
}

async function installSettings() {
  const srcSettings = path.join(SOURCE_DIR, 'settings.local.json');

  // global: settings.json, workspace: settings.local.json
  const destFileName = config.isGlobal ? 'settings.json' : 'settings.local.json';
  const destSettings = path.join(config.targetDir, destFileName);

  if (!fsSync.existsSync(srcSettings)) return;

  await backupFile(destSettings);

  // global 설치 시 hooks 경로를 절대 경로로 변환
  const useAbsolutePaths = config.isGlobal;
  const settingsMerger = (dest, src) => mergeSettings(dest, src, useAbsolutePaths);

  await mergeJsonFile(srcSettings, destSettings, settingsMerger);

  if (config.isGlobal) {
    logInfo('Global 설치: hooks 경로가 절대 경로로 변환되었습니다');
  }

  logSuccess(`${destFileName} 병합 완료`);
}

// =============================================================================
// 롤백 기능
// =============================================================================

async function rollback() {
  logWarning('설치 롤백 중...');

  for (const op of config.operations.reverse()) {
    try {
      if (op.type === 'copy' || op.type === 'mkdir') {
        if (fsSync.existsSync(op.path)) {
          const stat = await fs.stat(op.path);
          if (stat.isDirectory()) {
            await fs.rm(op.path, { recursive: true });
          } else {
            await fs.unlink(op.path);
          }
        }
      } else if (op.type === 'write' && op.backup) {
        await fs.writeFile(op.path, JSON.stringify(op.backup, null, 2));
      }
    } catch (e) {
      logError(`롤백 실패: ${op.path}`);
    }
  }

  logInfo('롤백 완료');
}

// =============================================================================
// 결과 출력
// =============================================================================

function printSummary() {
  console.log('\n' + colors.bright + '설치 완료!' + colors.reset);
  console.log('─'.repeat(40));

  console.log(`\n${colors.cyan}📊 설치 요약${colors.reset}`);
  console.log(`  • 생성된 폴더: ${config.stats.created.length}개`);
  console.log(`  • 복사된 파일: ${config.stats.copied.length}개`);
  console.log(`  • 백업된 파일: ${config.stats.backed.length}개`);
  console.log(`  • 병합된 파일: ${config.stats.merged.length}개`);

  if (config.stats.errors.length > 0) {
    console.log(`  • ${colors.red}오류: ${config.stats.errors.length}개${colors.reset}`);
  }

  if (config.dryRun) {
    console.log(`\n${colors.yellow}⚠ Dry-run 모드: 실제 변경 없음${colors.reset}`);
  }

  console.log(`\n${colors.cyan}📁 설치 위치${colors.reset}`);
  console.log(`  ${config.targetDir}`);

  if (config.stats.backed.length > 0) {
    console.log(`\n${colors.cyan}💾 백업 위치${colors.reset}`);
    console.log(`  ${config.backupDir}`);
  }

  console.log('\n' + colors.green + '✓ 모든 설치가 완료되었습니다!' + colors.reset + '\n');
}

// =============================================================================
// 메인 함수
// =============================================================================

async function install() {
  // 소스 확인
  if (!fsSync.existsSync(SOURCE_DIR)) {
    throw new Error('소스 .claude 폴더를 찾을 수 없습니다.');
  }

  // 설치 위치 선택 및 검증
  const rawTarget = await selectTarget();
  config.targetDir = validatePath(rawTarget);
  config.backupDir = path.join(config.targetDir, '.backup');

  console.log('\n' + colors.bright + '설치 정보' + colors.reset);
  console.log('─'.repeat(40));
  logInfo(`소스: ${SOURCE_DIR}`);
  logInfo(`대상: ${config.targetDir}`);
  if (config.dryRun) {
    logWarning('Dry-run 모드 활성화');
  }
  console.log('');

  // 확인
  if (!config.autoConfirm) {
    const confirm = await prompt('설치를 진행하시겠습니까? (y/N): ');
    if (confirm.toLowerCase() !== 'y') {
      logInfo('설치가 취소되었습니다.');
      process.exit(0);
    }
  }

  console.log('\n' + colors.bright + '설치 진행 중...' + colors.reset);
  console.log('─'.repeat(40));

  try {
    // 단계별 설치
    await createDirectories();
    await installSkills();
    await installCommands();
    await installHooks();
    await installScripts();
    await installSettings();

    // 결과 출력
    printSummary();
  } catch (error) {
    logError(`설치 중 오류 발생: ${error.message}`);

    // 롤백 시도
    if (config.operations.length > 0 && !config.dryRun) {
      const doRollback = await prompt('롤백을 진행하시겠습니까? (y/N): ');
      if (doRollback.toLowerCase() === 'y') {
        await rollback();
      }
    }

    process.exit(1);
  }
}

// =============================================================================
// 실행
// =============================================================================

install().catch((error) => {
  logError(`치명적 오류: ${error.message}`);
  process.exit(1);
});

// 테스트를 위한 모듈 내보내기
if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    validatePath,
    validateSourcePath,
    mergeSkillRules,
    mergeSettings,
    config
  };
}
