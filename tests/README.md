# 테스트 스크립트

## 개요

플러그인 설정 파일(`marketplace.json`, `plugin.json`)의 유효성을 검사하는 테스트 스크립트입니다.

## 스크립트

### validate-plugin-configs.js

모든 `marketplace.json`과 `plugin.json` 파일을 찾아서 유효성을 검증합니다.

#### 검증 항목

**marketplace.json:**

- 필수 필드 검증: `name`, `owner`, `metadata`, `plugins`
- `owner.name` 필드 존재 확인
- `plugins` 배열의 각 항목 검증
  - `name` 필드 필수
  - `version`, `description`, `author` 권장
  - `source` 경로 존재 확인
  - 통합 플러그인의 경우 `skills`, `commands`, `agents` 경로 존재 확인

**plugin.json:**

- 필수 필드 검증: `name`, `version`, `description`
- `author` 필드 권장 (있는 경우 `author.name` 필수)
- `version` semver 형식 권장 (예: `1.0.0`)
- `skills`, `commands`, `agents` 배열 검증
  - 문자열 경로 또는 `{source: ...}` 객체 형식
  - 모든 참조 경로 존재 확인

#### 실행 방법

```bash
# 프로젝트 루트에서 실행
node tests/validate-plugin-configs.js

# 또는 실행 권한이 있는 경우
./tests/validate-plugin-configs.js
```

#### 출력 예시

**성공:**

```
============================================================
플러그인 설정 파일 유효성 검사
============================================================

[marketplace.json 검증]
파일: /path/to/.claude-plugin/marketplace.json
✓ marketplace.json 검증 통과

발견된 plugin.json 파일: 4개
  - plugins/doc-tools/.claude-plugin/plugin.json
  - plugins/outsourcing/.claude-plugin/plugin.json
  - plugins/search/.claude-plugin/plugin.json
  - plugins/tdd/.claude-plugin/plugin.json

[plugin.json 검증]
파일: plugins/doc-tools/.claude-plugin/plugin.json
✓ plugin.json 검증 통과

...

============================================================
검증 결과
============================================================

✓ 모든 검증 통과!
```

**실패:**

```
============================================================
검증 결과
============================================================

경고 (2개):
  ⚠ marketplace.json > plugins[1] (tdd): version 필드 권장
  ⚠ plugins/tdd/.claude-plugin/plugin.json: author 필드 권장

에러 (1개):
  ✗ plugins/tdd/.claude-plugin/plugin.json > commands[0]: 경로가 존재하지 않음 - ./../../commands/tdd-team.md

검증 실패!
```

#### Exit Code

- `0`: 모든 검증 통과 (경고만 있는 경우 포함)
- `1`: 에러 발견

## ${CLAUDE_PLUGIN_ROOT} 변수

경로 지정 시 `${CLAUDE_PLUGIN_ROOT}` 변수를 사용하면 프로젝트 루트를 명확하게 참조할 수 있습니다.

### 사용 예시

**marketplace.json:**
```json
{
  "plugins": [
    {
      "name": "my-plugin",
      "source": "./",
      "commands": [
        "${CLAUDE_PLUGIN_ROOT}/commands/my-command.md"
      ],
      "agents": [
        "${CLAUDE_PLUGIN_ROOT}/agents/my-agent.md"
      ]
    }
  ]
}
```

### 장점

1. **명확성**: 프로젝트 루트 기준 경로를 명시적으로 표현
2. **가독성**: 상대 경로 (`../../`) 대신 절대적 위치 표현
3. **오류 방지**: 복잡한 상대 경로 계산 실수 방지

### 경로 기준점 정리

**상대 경로 기준:**
- `marketplace.json`: `.claude-plugin/` 폴더의 **부모** (프로젝트 루트)
- `plugin.json`: `.claude-plugin/` 폴더의 **부모** (plugin source 폴더)

**예시:**
```
프로젝트 구조:
  cc-plugins/                          # 프로젝트 루트
  ├── .claude-plugin/
  │   └── marketplace.json
  ├── plugins/
  │   └── my-plugin/                   # plugin source 폴더
  │       └── .claude-plugin/
  │           └── plugin.json
  ├── commands/
  │   └── my-command.md
  └── agents/
      └── my-agent.md

marketplace.json (source: "./"):
  - ${CLAUDE_PLUGIN_ROOT}/commands/my-command.md
  - 또는: ./commands/my-command.md (프로젝트 루트 기준)

plugin.json (plugins/my-plugin/):
  - ./../../commands/my-command.md (plugin source 폴더 기준)
  - 권장: ${CLAUDE_PLUGIN_ROOT}/commands/my-command.md (더 명확)
```

## 프로그래밍 방식 사용

스크립트를 모듈로 import하여 사용할 수 있습니다:

```javascript
const {
  validateMarketplace,
  validatePlugin,
  findPluginJsonFiles,
} = require('./tests/validate-plugin-configs.js');

// marketplace.json 검증
const isValid = validateMarketplace('/path/to/marketplace.json');

// 특정 plugin.json 검증
validatePlugin('/path/to/plugin.json');

// 모든 plugin.json 파일 찾기
const files = findPluginJsonFiles('/project/root');
```

## CI/CD 통합

GitHub Actions 등 CI/CD 파이프라인에서 사용할 수 있습니다:

```yaml
- name: Validate plugin configs
  run: node tests/validate-plugin-configs.js
```

## 현재 발견된 이슈

테스트 실행 결과, 다음 이슈들이 발견되었습니다:

### 경로 오류 ✓ (해결됨)

`plugins/` 아래의 `plugin.json` 파일들의 상대 경로는 정확합니다:

- 현재: `./../../commands/xxx.md` (2단계 위) - 올바름
- 기준: plugin.json이 위치한 `.claude-plugin/` 폴더의 부모(plugin source 폴더)
- validate-plugin-configs.js로 검증됨 ✓

### marketplace.json의 plugins 참조 ✓ (정확함)

- `marketplace.json`의 `plugins[0]` (cc-plugins): `source: "./"` (프로젝트 루트 기준)
- `marketplace.json`의 `plugins[1-4]` (tdd, search, doc-tools, outsourcing): `source: "./plugins/xxx"` (프로젝트 루트 기준)
- validate-plugin-configs.js로 검증됨 ✓

## 권장사항

1. **경로 일관성**: 모든 상대 경로를 프로젝트 루트 기준으로 통일
2. **파일명 일치**: 참조하는 파일명과 실제 파일명 일치
3. **버전 관리**: 모든 플러그인에 명시적인 버전 지정
4. **메타데이터 완성**: description, author 필드 추가

## 변경 이력

- **2025-12-01**: `${CLAUDE_PLUGIN_ROOT}` 변수 지원 추가, 모든 검증 통과
- **2025-12-01**: 경로 기준점 수정 (plugin source 폴더 기준)
- **2025-12-01**: 초기 작성 및 validate-plugin-configs.js 생성
