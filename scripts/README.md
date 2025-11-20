# Scripts

Claude Code Skills 프로젝트의 유틸리티 스크립트 모음입니다.

## 스크립트 목록

### install-skills.js

현재 프로젝트의 `.claude` 리소스를 global 또는 workspace에 설치합니다.

#### 사용법

```bash
# 대화형 모드
node scripts/install-skills.js

# 직접 지정
node scripts/install-skills.js --target global     # ~/.claude에 설치
node scripts/install-skills.js --target workspace  # ./.claude에 설치

# 미리보기 (실제 변경 없음)
node scripts/install-skills.js --dry-run

# 비대화형 (확인 생략)
node scripts/install-skills.js --target global --yes
node scripts/install-skills.js --target workspace -y --dry-run
```

#### 주요 기능

- **설치 위치 선택**: global (`~/.claude`) 또는 workspace (`./.claude`)
- **백업**: 덮어쓰기 전 기존 파일을 `.backup/` 폴더에 타임스탬프와 함께 저장
- **JSON 병합**: `skill-rules.json`과 설정 파일은 병합 처리
- **npm install**: hooks 의존성 자동 설치
- **롤백**: 설치 실패 시 롤백 옵션 제공
- **Dry-run**: 실제 변경 없이 미리보기

#### 설정 파일 처리

Claude Code 공식 구조에 맞게 설정 파일을 설치합니다:

| 설치 위치 | 설정 파일 | hooks 경로 | 용도 |
|----------|----------|:----------:|------|
| global | `~/.claude/settings.json` | 절대 경로 | 사용자 전역 설정 (모든 프로젝트 적용) |
| workspace | `.claude/settings.local.json` | 상대 경로 | 로컬 프로젝트 설정 (커밋 제외) |

> **Global hooks**: 절대 경로(`/Users/.../~/.claude/hooks/...`)로 변환되어 모든 프로젝트에서 동작합니다.

> **참고**: `.claude/settings.json`은 프로젝트 설정으로 커밋되며, 별도 생성이 필요합니다.

#### 설치 대상

- 24개 스킬 폴더
- 4개 커맨드 파일
- 3개 훅 파일 + package.json
- 2개 스크립트 파일

---

### uninstall-skills.js

설치된 스킬, 커맨드, 훅을 제거하거나 백업에서 복원합니다.

#### 사용법

```bash
# 대화형 모드
node scripts/uninstall-skills.js

# 직접 지정
node scripts/uninstall-skills.js --target global     # ~/.claude에서 제거
node scripts/uninstall-skills.js --target workspace  # ./.claude에서 제거

# 미리보기 (실제 변경 없음)
node scripts/uninstall-skills.js --dry-run

# 백업에서 복원
node scripts/uninstall-skills.js --restore

# 비대화형 (확인 생략)
node scripts/uninstall-skills.js --target global --yes
```

#### 주요 기능

- **제거 위치 선택**: global (`~/.claude`) 또는 workspace (`./.claude`)
- **스킬 제거**: 24개 스킬 폴더 제거
- **커맨드 제거**: commands 폴더 내 파일 제거
- **훅 제거**: hooks 폴더 전체 제거
- **설정 정리**: settings 파일에서 hooks 설정 제거
- **백업 복원**: 이전 백업에서 파일 복원
- **Dry-run**: 실제 변경 없이 미리보기

#### 제거 대상

- 24개 스킬 폴더
- 4개 커맨드 파일
- hooks 폴더 전체
- scripts 폴더
- skill-rules.json (빈 객체로 초기화)

---

### install-skills.test.js

install-skills.js의 단위 테스트입니다.

#### 사용법

```bash
node scripts/install-skills.test.js
```

#### 테스트 내용

- 경로 검증 (validatePath)
- 스킬 규칙 병합 (mergeSkillRules)
- 설정 병합 (mergeSettings)
- 엣지 케이스 처리

---

## 개발 가이드

### 새 스크립트 추가

1. `scripts/` 폴더에 파일 생성
2. 실행 권한 설정: `chmod +x scripts/your-script.js`
3. shebang 추가: `#!/usr/bin/env node`
4. 이 README에 문서화

### 테스트 작성

- 테스트 파일명: `{script-name}.test.js`
- assert 모듈 사용
- 독립적인 테스트 케이스 작성
