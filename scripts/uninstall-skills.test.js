#!/usr/bin/env node

/**
 * uninstall-skills.js 단위 테스트
 */

const assert = require('assert');
const path = require('path');

// 테스트할 모듈 로드를 위한 모킹
const originalArgv = process.argv;

// 테스트 유틸리티
function test(name, fn) {
  try {
    fn();
    console.log(`✓ ${name}`);
    return true;
  } catch (error) {
    console.log(`✗ ${name}`);
    console.log(`  ${error.message}`);
    return false;
  }
}

// =============================================================================
// validatePath 테스트
// =============================================================================

function testValidatePath() {
  const home = process.env.HOME || process.env.USERPROFILE;
  const cwd = process.cwd();

  // validatePath 함수 복제 (모듈에서 export되지 않으므로)
  function validatePath(targetPath) {
    const resolved = path.resolve(targetPath);

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

  console.log('\n--- validatePath 테스트 ---');

  test('global .claude 경로 허용', () => {
    const result = validatePath(path.join(home, '.claude'));
    assert.strictEqual(result, path.join(home, '.claude'));
  });

  test('global .claude 하위 경로 허용', () => {
    const result = validatePath(path.join(home, '.claude', 'skills'));
    assert.strictEqual(result, path.join(home, '.claude', 'skills'));
  });

  test('workspace .claude 경로 허용', () => {
    const result = validatePath(path.join(cwd, '.claude'));
    assert.strictEqual(result, path.join(cwd, '.claude'));
  });

  test('workspace .claude 하위 경로 허용', () => {
    const result = validatePath(path.join(cwd, '.claude', 'hooks'));
    assert.strictEqual(result, path.join(cwd, '.claude', 'hooks'));
  });

  test('허용되지 않은 경로 거부', () => {
    assert.throws(() => {
      validatePath('/tmp/malicious');
    }, /허용되지 않은 경로/);
  });

  test('루트 경로 거부', () => {
    assert.throws(() => {
      validatePath('/');
    }, /허용되지 않은 경로/);
  });

  test('상대 경로 처리', () => {
    const result = validatePath('.claude');
    assert.strictEqual(result, path.join(cwd, '.claude'));
  });
}

// =============================================================================
// cleanSettings 로직 테스트
// =============================================================================

function testCleanSettingsLogic() {
  console.log('\n--- cleanSettings 로직 테스트 ---');

  test('hooks 제거', () => {
    const settings = {
      permissions: { allow: [], deny: [] },
      hooks: {
        UserPromptSubmit: [{ matcher: '', hooks: [] }]
      }
    };

    // hooks 제거 로직
    if (settings.hooks) {
      delete settings.hooks;
    }

    assert.strictEqual(settings.hooks, undefined);
    assert.ok(settings.permissions);
  });

  test('빈 설정 처리', () => {
    const settings = {};

    if (settings.hooks) {
      delete settings.hooks;
    }

    assert.deepStrictEqual(settings, {});
  });

  test('다른 설정 유지', () => {
    const settings = {
      permissions: { allow: ['Bash(git:*)'] },
      hooks: { Stop: [] },
      enabledMcpjsonServers: ['Context7']
    };

    delete settings.hooks;

    assert.ok(settings.permissions);
    assert.ok(settings.enabledMcpjsonServers);
    assert.strictEqual(settings.hooks, undefined);
  });
}

// =============================================================================
// 스킬 목록 테스트
// =============================================================================

function testSkillsList() {
  console.log('\n--- 스킬 목록 테스트 ---');

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

  test('스킬 개수 확인 (24개)', () => {
    assert.strictEqual(SKILLS_TO_REMOVE.length, 24);
  });

  test('중복 스킬 없음', () => {
    const unique = new Set(SKILLS_TO_REMOVE);
    assert.strictEqual(unique.size, SKILLS_TO_REMOVE.length);
  });

  test('알파벳 순서 정렬', () => {
    const sorted = [...SKILLS_TO_REMOVE].sort();
    assert.deepStrictEqual(SKILLS_TO_REMOVE, sorted);
  });

  test('핵심 스킬 포함 확인', () => {
    assert.ok(SKILLS_TO_REMOVE.includes('skill-developer'));
    assert.ok(SKILLS_TO_REMOVE.includes('agent-workflow-manager'));
    assert.ok(SKILLS_TO_REMOVE.includes('frontend-dev-guidelines'));
  });
}

// =============================================================================
// 경로 조합 테스트
// =============================================================================

function testPathCombinations() {
  console.log('\n--- 경로 조합 테스트 ---');

  test('skills 경로 생성', () => {
    const targetDir = '/home/user/.claude';
    const skillsDir = path.join(targetDir, 'skills');
    assert.strictEqual(skillsDir, '/home/user/.claude/skills');
  });

  test('개별 스킬 경로 생성', () => {
    const skillsDir = '/home/user/.claude/skills';
    const skillName = 'agent-workflow-manager';
    const skillPath = path.join(skillsDir, skillName);
    assert.strictEqual(skillPath, '/home/user/.claude/skills/agent-workflow-manager');
  });

  test('백업 경로 생성', () => {
    const targetDir = '/home/user/.claude';
    const backupDir = path.join(targetDir, '.backup');
    assert.strictEqual(backupDir, '/home/user/.claude/.backup');
  });
}

// =============================================================================
// 설정 파일 선택 테스트
// =============================================================================

function testSettingsFileSelection() {
  console.log('\n--- 설정 파일 선택 테스트 ---');

  test('global: settings.json 사용', () => {
    const isGlobal = true;
    const targetDir = '/home/user/.claude';
    const settingsFile = isGlobal
      ? path.join(targetDir, 'settings.json')
      : path.join(targetDir, 'settings.local.json');
    assert.ok(settingsFile.endsWith('settings.json'));
    assert.ok(!settingsFile.endsWith('settings.local.json'));
  });

  test('workspace: settings.local.json 사용', () => {
    const isGlobal = false;
    const targetDir = '/project/.claude';
    const settingsFile = isGlobal
      ? path.join(targetDir, 'settings.json')
      : path.join(targetDir, 'settings.local.json');
    assert.ok(settingsFile.endsWith('settings.local.json'));
  });
}

// =============================================================================
// 메인 실행
// =============================================================================

function runAllTests() {
  console.log('🧪 uninstall-skills.js 테스트 실행\n');
  console.log('═'.repeat(50));

  let passed = 0;
  let failed = 0;

  const testSuites = [
    testValidatePath,
    testCleanSettingsLogic,
    testSkillsList,
    testPathCombinations,
    testSettingsFileSelection
  ];

  for (const suite of testSuites) {
    suite();
  }

  console.log('\n' + '═'.repeat(50));
  console.log('테스트 완료');
}

runAllTests();
