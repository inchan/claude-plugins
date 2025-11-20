#!/usr/bin/env node

/**
 * Claude Code Skills 제거 스크립트
 *
 * 사용법:
 *   node scripts/uninstall-skills.js
 *   node scripts/uninstall-skills.js --target global
 *   node scripts/uninstall-skills.js --target workspace
 *   node scripts/uninstall-skills.js --dry-run
 *   node scripts/uninstall-skills.js --restore  # 백업에서 복원
 *   node scripts/uninstall-skills.js --skill <name>  # 특정 스킬만 제거
 */

const fs = require('fs').promises;
const fsSync = require('fs');
const path = require('path');
const readline = require('readline');

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

// 설정
const config = {
  dryRun: false,
  isGlobal: false,
  autoConfirm: false,
  restore: false,
  specificSkill: null,  // 특정 스킬만 제거
  targetDir: null,
  backupDir: null,
  stats: {
    removed: [],
    restored: [],
    cleaned: [],
    errors: []
  }
};

// 제거할 스킬 목록 (install-skills.js와 동기화)
const SKILLS_TO_REMOVE = [
  'agent-workflow-advisor',
  'agent-workflow-manager',
  'agent-workflow-orchestrator',
  'backend-dev-guidelines',
  'cli-adapters',
  'cli-updater',
  'command-creator',
  'dual-ai-loop',
  'dynamic-task-orchestrator',
  'error-tracking',
  'frontend-dev-guidelines',
  'hooks-creator',
  'intelligent-task-router',
  'iterative-quality-enhancer',
  'meta-prompt-generator-v2',
  'parallel-task-executor',
  'prompt-enhancer',
  'reflection-review',
  'route-tester',
  'sequential-task-processor',
  'skill-developer',
  'skill-generator-tool',
  'subagent-creator',
  'web-to-markdown'
];

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

  const allowedBases = [
    path.join(home, '.claude'),
    path.join(cwd, '.claude')
  ];

  const isAllowed = allowedBases.some(base =>
    resolved === base || resolved.startsWith(base + path.sep)
  );

  if (!isAllowed) {
    throw new Error(`허용되지 않은 경로: ${resolved}`);
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

  if (args.includes('--dry-run')) {
    config.dryRun = true;
    logInfo('Dry-run 모드: 실제 파일 변경 없음');
  }

  if (args.includes('--yes') || args.includes('-y')) {
    config.autoConfirm = true;
  }

  if (args.includes('--restore')) {
    config.restore = true;
    logInfo('복원 모드: 백업에서 파일 복원');
  }

  // --skill 옵션 확인
  const skillIndex = args.indexOf('--skill');
  if (skillIndex !== -1 && args[skillIndex + 1]) {
    config.specificSkill = args[skillIndex + 1];
    logInfo(`특정 스킬만 제거: ${config.specificSkill}`);
  }

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

  console.log('\n' + colors.bright + '🗑️  Claude Code Skills 제거' + colors.reset);
  console.log('─'.repeat(40));
  console.log('\n제거 위치를 선택하세요:\n');
  console.log('  1. global    - ~/.claude (전역 사용자 설정)');
  console.log('  2. workspace - ./.claude (로컬 프로젝트 설정)\n');

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

async function removeDir(dirPath) {
  if (!fsSync.existsSync(dirPath)) return false;

  const validPath = validatePath(dirPath);
  const relativePath = path.relative(config.targetDir, validPath);

  if (config.dryRun) {
    logInfo(`[DRY-RUN] 제거 예정: ${relativePath}/`);
  } else {
    await fs.rm(validPath, { recursive: true, force: true });
  }

  config.stats.removed.push(relativePath);
  return true;
}

async function removeFile(filePath) {
  if (!fsSync.existsSync(filePath)) return false;

  const validPath = validatePath(filePath);
  const relativePath = path.relative(config.targetDir, validPath);

  if (config.dryRun) {
    logInfo(`[DRY-RUN] 제거 예정: ${relativePath}`);
  } else {
    await fs.unlink(validPath);
  }

  config.stats.removed.push(relativePath);
  return true;
}

// =============================================================================
// 제거 단계별 함수
// =============================================================================

async function removeSkills() {
  const skillsDir = path.join(config.targetDir, 'skills');

  if (!fsSync.existsSync(skillsDir)) {
    logWarning('skills 폴더가 없습니다.');
    return;
  }

  logInfo('스킬 제거 중...');

  // 특정 스킬만 제거하는 경우
  if (config.specificSkill) {
    const skillPath = path.join(skillsDir, config.specificSkill);
    if (await removeDir(skillPath)) {
      logSuccess(`스킬 '${config.specificSkill}' 제거 완료`);
    } else {
      logWarning(`스킬 '${config.specificSkill}'을 찾을 수 없습니다.`);
    }
    return;
  }

  // 실제 디렉토리에서 스킬 목록 가져오기 (동적 로드)
  let skillsToRemove = SKILLS_TO_REMOVE;
  try {
    const entries = await fs.readdir(skillsDir, { withFileTypes: true });
    const actualSkills = entries
      .filter(e => e.isDirectory() && !e.name.startsWith('.') && !e.name.endsWith('.old'))
      .map(e => e.name);

    // 설치된 스킬과 제거 목록의 교집합
    skillsToRemove = SKILLS_TO_REMOVE.filter(s => actualSkills.includes(s));
  } catch (e) {
    // 폴백: 기본 목록 사용
  }

  let count = 0;
  const total = skillsToRemove.length;

  for (const skillName of skillsToRemove) {
    const skillPath = path.join(skillsDir, skillName);
    if (await removeDir(skillPath)) {
      count++;
    }
    if (total > 5) {
      showProgress(count, total, `스킬 제거: ${skillName}`);
    }
  }

  // skill-rules.json 정리 (빈 객체로)
  const rulesPath = path.join(skillsDir, 'skill-rules.json');
  if (fsSync.existsSync(rulesPath)) {
    if (config.dryRun) {
      logInfo('[DRY-RUN] skill-rules.json 초기화 예정');
    } else {
      const emptyRules = {
        version: '1.0',
        description: 'Skill activation triggers for Claude Code.',
        skills: {}
      };
      await fs.writeFile(rulesPath, JSON.stringify(emptyRules, null, 2));
    }
    config.stats.cleaned.push('skill-rules.json');
  }

  logSuccess(`${count}개 스킬 제거 완료`);
}

async function removeCommands() {
  const commandsDir = path.join(config.targetDir, 'commands');

  if (!fsSync.existsSync(commandsDir)) return;

  logInfo('커맨드 제거 중...');

  const files = await fs.readdir(commandsDir);
  let count = 0;

  for (const file of files) {
    const filePath = path.join(commandsDir, file);
    if (await removeFile(filePath)) {
      count++;
    }
  }

  logSuccess(`${count}개 커맨드 제거 완료`);
}

async function removeHooks() {
  const hooksDir = path.join(config.targetDir, 'hooks');

  if (!fsSync.existsSync(hooksDir)) return;

  logInfo('훅 제거 중...');

  // 전체 hooks 폴더 제거
  if (await removeDir(hooksDir)) {
    logSuccess('훅 폴더 제거 완료');
  }
}

async function removeScripts() {
  const scriptsDir = path.join(config.targetDir, 'scripts');

  if (!fsSync.existsSync(scriptsDir)) return;

  logInfo('스크립트 제거 중...');

  if (await removeDir(scriptsDir)) {
    logSuccess('스크립트 폴더 제거 완료');
  }
}

async function cleanSettings() {
  const settingsFile = config.isGlobal
    ? path.join(config.targetDir, 'settings.json')
    : path.join(config.targetDir, 'settings.local.json');

  if (!fsSync.existsSync(settingsFile)) return;

  logInfo('설정 파일 정리 중...');

  try {
    const content = await fs.readFile(settingsFile, 'utf8');
    const settings = JSON.parse(content);

    // hooks 제거
    if (settings.hooks) {
      delete settings.hooks;
      config.stats.cleaned.push('hooks from settings');
    }

    if (!config.dryRun) {
      await fs.writeFile(settingsFile, JSON.stringify(settings, null, 2));
    }

    logSuccess('설정 파일 정리 완료');
  } catch (e) {
    logWarning(`설정 파일 정리 실패: ${e.message}`);
    config.stats.errors.push('settings cleanup failed');
  }
}

async function restoreFromBackup() {
  const backupDir = path.join(config.targetDir, '.backup');

  if (!fsSync.existsSync(backupDir)) {
    logWarning('백업 폴더가 없습니다.');
    return;
  }

  logInfo('백업 목록 확인 중...');

  const backups = await fs.readdir(backupDir);
  const sortedBackups = backups.sort().reverse();

  if (sortedBackups.length === 0) {
    logWarning('백업이 없습니다.');
    return;
  }

  console.log('\n사용 가능한 백업:');
  sortedBackups.slice(0, 5).forEach((backup, i) => {
    console.log(`  ${i + 1}. ${backup}`);
  });

  const choice = await prompt('\n복원할 백업 번호 (취소: 0): ');
  const index = parseInt(choice) - 1;

  if (index < 0 || index >= sortedBackups.length) {
    logInfo('복원 취소됨');
    return;
  }

  const selectedBackup = sortedBackups[index];
  const backupPath = path.join(backupDir, selectedBackup);

  logInfo(`백업 복원 중: ${selectedBackup}`);

  // 백업 내용을 대상 디렉토리로 복사
  const copyRecursive = async (src, dest) => {
    const entries = await fs.readdir(src, { withFileTypes: true });

    for (const entry of entries) {
      const srcPath = path.join(src, entry.name);
      const destPath = path.join(dest, entry.name);

      // 대상 경로 검증
      try {
        validatePath(destPath);
      } catch (e) {
        logWarning(`경로 검증 실패, 건너뜀: ${destPath}`);
        continue;
      }

      if (entry.isDirectory()) {
        if (!fsSync.existsSync(destPath)) {
          if (config.dryRun) {
            logInfo(`[DRY-RUN] 복원 예정: ${path.relative(config.targetDir, destPath)}/`);
          } else {
            await fs.mkdir(destPath, { recursive: true });
          }
        }
        await copyRecursive(srcPath, destPath);
      } else {
        if (config.dryRun) {
          logInfo(`[DRY-RUN] 복원 예정: ${path.relative(config.targetDir, destPath)}`);
        } else {
          await fs.copyFile(srcPath, destPath);
        }
        config.stats.restored.push(path.relative(config.targetDir, destPath));
      }
    }
  };

  // dry-run에서도 목록 확인을 위해 항상 실행
  await copyRecursive(backupPath, config.targetDir);

  logSuccess(`${config.stats.restored.length}개 파일 복원 완료`);
}

// =============================================================================
// 결과 출력
// =============================================================================

function printSummary() {
  console.log('\n' + colors.bright + '제거 완료!' + colors.reset);
  console.log('─'.repeat(40));

  console.log(`\n${colors.cyan}📊 제거 요약${colors.reset}`);
  console.log(`  • 제거된 항목: ${config.stats.removed.length}개`);
  console.log(`  • 정리된 설정: ${config.stats.cleaned.length}개`);
  console.log(`  • 복원된 파일: ${config.stats.restored.length}개`);

  if (config.stats.errors.length > 0) {
    console.log(`  • ${colors.red}오류: ${config.stats.errors.length}개${colors.reset}`);
  }

  if (config.dryRun) {
    console.log(`\n${colors.yellow}⚠ Dry-run 모드: 실제 변경 없음${colors.reset}`);
  }

  console.log(`\n${colors.cyan}📁 대상 위치${colors.reset}`);
  console.log(`  ${config.targetDir}`);

  console.log('\n' + colors.green + '✓ 모든 제거가 완료되었습니다!' + colors.reset + '\n');
}

// =============================================================================
// 메인 함수
// =============================================================================

async function uninstall() {
  const rawTarget = await selectTarget();
  config.targetDir = validatePath(rawTarget);
  config.backupDir = path.join(config.targetDir, '.backup');

  if (!fsSync.existsSync(config.targetDir)) {
    throw new Error(`대상 폴더가 없습니다: ${config.targetDir}`);
  }

  console.log('\n' + colors.bright + '제거 정보' + colors.reset);
  console.log('─'.repeat(40));
  logInfo(`대상: ${config.targetDir}`);
  if (config.dryRun) {
    logWarning('Dry-run 모드 활성화');
  }
  if (config.restore) {
    logInfo('백업 복원 모드');
  }
  console.log('');

  // 확인
  if (!config.autoConfirm) {
    const action = config.restore ? '복원' : '제거';
    const confirm = await prompt(`${action}를 진행하시겠습니까? (y/N): `);
    if (confirm.toLowerCase() !== 'y') {
      logInfo('작업이 취소되었습니다.');
      process.exit(0);
    }
  }

  console.log('\n' + colors.bright + '작업 진행 중...' + colors.reset);
  console.log('─'.repeat(40));

  try {
    if (config.restore) {
      await restoreFromBackup();
    } else {
      await removeSkills();
      await removeCommands();
      await removeHooks();
      await removeScripts();
      await cleanSettings();
    }

    printSummary();
  } catch (error) {
    logError(`작업 중 오류 발생: ${error.message}`);
    process.exit(1);
  }
}

// =============================================================================
// 실행
// =============================================================================

uninstall().catch((error) => {
  logError(`치명적 오류: ${error.message}`);
  process.exit(1);
});
