# 새 CLI 어댑터 추가 가이드

이 문서는 dual-ai-loop에 새로운 AI CLI 도구를 추가하는 방법을 설명합니다.

---

## 요약

새 CLI를 추가하려면:

1. `skills/cli-adapters/{cli-name}/` 디렉토리 생성
2. `SKILL.md` 작성 (템플릿 참조)
3. `VERSION.json` 작성 (스키마 준수)
4. `cli-registry.json`에 등록
5. 검증 스크립트 실행

---

## Step 1: 디렉토리 구조 생성

```bash
mkdir -p skills/cli-adapters/{new-cli-name}
```

**예시:** `cursor` CLI를 추가하는 경우
```bash
mkdir -p skills/cli-adapters/cursor
```

---

## Step 2: VERSION.json 작성

**필수 필드 포함:**

```json
{
  "cli_name": "cursor",
  "display_name": "Cursor AI CLI",
  "current_supported_version": "1.0.0",
  "minimum_version": "0.9.0",
  "last_checked": "2025-11-17",
  "last_updated": "2025-11-17",
  "verification_level": {
    "package_exists": true,
    "installation_tested": false,
    "commands_verified": false,
    "dual_ai_loop_tested": false
  },
  "verified": "partial",
  "cli_type": "hybrid",
  "automation": {
    "support_level": "full",
    "non_interactive_mode": {
      "supported": true,
      "command_pattern": "cursor --prompt <text>",
      "example": "cursor --prompt 'Write hello world'"
    },
    "stdin_support": {
      "supported": true,
      "command_pattern": "echo <text> | cursor --stdin",
      "example": "echo 'Write hello world' | cursor --stdin"
    },
    "auto_approval_mode": {
      "supported": false,
      "flag": null
    }
  },
  "sources": {
    "primary": "https://cursor.sh",
    "github_repo": "https://github.com/getcursor/cursor",
    "npm_package": null
  },
  "install_methods": {
    "download": "https://cursor.sh/download",
    "brew": "brew install --cask cursor"
  },
  "verification": {
    "install_check": "which cursor || command -v cursor",
    "version_command": "cursor --version",
    "auth_check": "cursor auth status",
    "health_check": "cursor --help"
  },
  "authentication": {
    "required": true,
    "methods": ["cursor_account", "api_key"],
    "env_vars": ["CURSOR_API_KEY"],
    "login_command": "cursor auth login",
    "status_check_command": "cursor auth status"
  },
  "requirements": {
    "os": ["linux", "macos", "windows"],
    "min_ram": "4GB"
  },
  "rate_limits": null,
  "notes": {
    "info": "Cursor는 VS Code 포크 기반 AI IDE"
  },
  "warnings": [
    "실제 테스트되지 않음",
    "패키지 매니저로 설치 불가능할 수 있음"
  ]
}
```

**스키마 참조:** `VERSION_SCHEMA.json`

---

## Step 3: SKILL.md 작성

**템플릿:**

```markdown
---
name: {cli-name}-cli-adapter
description: {CLI 설명}. dual-ai-loop 통합용 어댑터.
---

# {Display Name} Adapter

## 검증 상태

{✅ 완전 검증됨 | ⚠️ 부분 검증됨 | ❌ 미검증} (날짜)

**확인된 사항:**
- [ ] 패키지/설치 파일 존재
- [ ] 설치 테스트
- [ ] 명령어 검증
- [ ] 자동화 지원 확인

**미확인 사항:**
- [ ] 실제 API 호출
- [ ] dual-ai-loop 통합 테스트

## 개요

{CLI 설명 및 주요 기능}

## 설치 확인

```bash
which {cli-command}
{cli-command} --version
```

## 설치 방법

```bash
# 설치 명령어
{install command}
```

## 인증 설정

```bash
# 인증 방법
{auth commands}
```

## 명령어 패턴

### 기본 실행

```bash
# 대화형 모드
{cli-command}

# 비대화형 모드
{cli-command} --prompt "text"

# stdin 모드
echo "text" | {cli-command} --stdin
```

## dual-ai-loop 연동

### 구현자 역할

```bash
{cli-command} --prompt "구현 요청: [Claude의 계획]"
```

### 검증자 역할

```bash
{cli-command} --prompt "코드 검증: [Claude의 코드]"
```

## 버전 정보

**최신 버전**: X.Y.Z
**최소 버전**: X.Y.Z

## 제한사항

- {제한사항 1}
- {제한사항 2}

## 참고

- {추가 정보}
```

---

## Step 4: cli-registry.json에 등록

`skills/cli-adapters/cli-registry.json` 파일 수정:

```json
{
  "adapters": {
    "existing-cli": { ... },

    "cursor": {
      "enabled": true,
      "display_name": "Cursor AI CLI",
      "adapter_path": "cli-adapters/cursor",
      "verification_status": "partial",
      "automation_support": "full",
      "tags": ["cursor", "ide", "vscode"]
    }
  }
}
```

**필수 필드:**
- `enabled`: CLI 활성화 여부
- `display_name`: 사용자에게 표시될 이름
- `adapter_path`: 어댑터 디렉토리 경로
- `verification_status`: none/partial/full
- `automation_support`: none/limited/full
- `tags`: 검색용 태그

---

## Step 5: 검증

### 수동 검증

```bash
# 1. 파일 존재 확인
ls -la skills/cli-adapters/cursor/
# SKILL.md, VERSION.json 존재해야 함

# 2. JSON 유효성 검사
jq . skills/cli-adapters/cursor/VERSION.json

# 3. 레지스트리 확인
jq '.adapters.cursor' skills/cli-adapters/cli-registry.json
```

### 자동 검증 (권장)

```bash
./skills/cli-adapters/validate-adapter.sh cursor
```

---

## Step 6: dual-ai-loop 업데이트

현재는 수동 업데이트가 필요합니다:

1. `skills/dual-ai-loop/SKILL.md`의 CLI 목록에 추가
2. `skills/cli-adapters/AUTH_SETUP.md`에 인증 방법 추가
3. `skills/cli-adapters/PREREQUISITES.md`에 실행 조건 추가
4. `skills/cli-adapters/setup-cli.sh`에 설치 함수 추가

**향후 개선**: 레지스트리에서 자동으로 목록을 생성하도록 변경 예정

---

## 체크리스트

새 CLI 추가 시 확인사항:

- [ ] `skills/cli-adapters/{name}/` 디렉토리 생성
- [ ] `VERSION.json` 작성 (스키마 준수)
- [ ] `SKILL.md` 작성 (템플릿 사용)
- [ ] `cli-registry.json`에 등록
- [ ] JSON 유효성 검사
- [ ] 실제 설치 테스트 (가능한 경우)
- [ ] 명령어 검증 (가능한 경우)
- [ ] AUTH_SETUP.md 업데이트
- [ ] PREREQUISITES.md 업데이트
- [ ] setup-cli.sh 업데이트 (선택)
- [ ] PR 생성

---

## 예시: Gemini CLI 추가

```bash
# 1. 디렉토리 생성
mkdir -p skills/cli-adapters/gemini

# 2. VERSION.json 작성
cat > skills/cli-adapters/gemini/VERSION.json << 'EOF'
{
  "cli_name": "gemini",
  "display_name": "Google Gemini CLI",
  ...
}
EOF

# 3. SKILL.md 작성
cat > skills/cli-adapters/gemini/SKILL.md << 'EOF'
---
name: gemini-cli-adapter
...
---
EOF

# 4. 레지스트리에 등록
# cli-registry.json 편집

# 5. 검증
jq . skills/cli-adapters/gemini/VERSION.json
```

---

## FAQ

### Q: CLI가 패키지 매니저로 설치되지 않는 경우?

A: `install_methods`에 다운로드 링크나 수동 설치 방법을 명시하세요.

```json
"install_methods": {
  "manual": "Download from https://example.com/download",
  "script": "curl -fsSL https://example.com/install.sh | bash"
}
```

### Q: 비대화형 모드가 없는 경우?

A: `automation.support_level`을 `"limited"` 또는 `"none"`으로 설정하고, `automation.non_interactive_mode.supported`를 `false`로 설정하세요.

### Q: 여러 인증 방법이 있는 경우?

A: `authentication.methods` 배열에 모두 나열하세요.

```json
"authentication": {
  "methods": ["oauth", "api_key", "service_account"]
}
```

---

## 관련 파일

- `VERSION_SCHEMA.json` - VERSION.json 스키마 정의
- `cli-registry.json` - CLI 레지스트리
- `AUTH_SETUP.md` - 인증 설정 가이드
- `PREREQUISITES.md` - 실행 필수 조건
- `setup-cli.sh` - 설치 자동화 스크립트
