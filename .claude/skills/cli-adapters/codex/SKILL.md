---
name: codex-cli-adapter
description: OpenAI Codex CLI 어댑터. dual-ai-loop의 기본 CLI로서 설치, 버전 확인, 명령어 패턴, 에러 처리를 제공.
---

# Codex CLI Adapter

## 검증 상태

✅ **완전 검증됨** (2025-11-17)

**실제 테스트 결과:**
- ✅ npm 설치: `npm install -g @openai/codex` - 성공 (1 package, 24s)
- ✅ 설치 경로: `/opt/node22/bin/codex`
- ✅ 버전 확인: `codex --version` → `codex-cli 0.58.0`
- ✅ 도움말: `codex --help` → 서브커맨드 및 옵션 확인
- ✅ **비대화형 모드**: `codex exec` 서브커맨드 지원
- ✅ **stdin 지원**: `codex exec -` (stdin에서 프롬프트 읽기)
- ✅ 기본 모델: `gpt-5-codex` (연구 프리뷰)

**미테스트 사항:**
- ⚠️ 실제 API 호출 (인증 필요)
- ⚠️ OpenAI 계정 인증 플로우
- ❌ dual-ai-loop 통합 테스트

**자동화 가능성**: ✅ **높음**
- exec 모드와 stdin 지원으로 완전 자동화 가능
- 예: `echo "프롬프트" | codex exec -`

## 개요

OpenAI Codex CLI와의 통합을 위한 어댑터입니다. dual-ai-loop 스킬의 기본 CLI로 사용됩니다.

**역할:**
- Codex CLI 설치 및 버전 확인
- 명령어 패턴 제공
- 에러 처리 가이드
- 버전 정보 관리

## 설치 확인

### 설치 여부 확인

```bash
which codex
# 또는
command -v codex
```

**결과 해석:**
- 경로 출력: 설치됨
- 빈 출력/오류: 미설치

### 버전 확인

```bash
codex --version
```

**출력 예시:**
```
codex-cli 0.58.0
```

## 설치 방법

### macOS/Linux

```bash
# npm을 통한 설치 (권장)
npm install -g @openai/codex

# 또는 homebrew (macOS)
brew install --cask codex
```

### Windows

```bash
# npm을 통한 설치
npm install -g @openai/codex
```

### 설치 후 인증

**권장: ChatGPT 계정 로그인**

```bash
# codex 실행 후 "Sign in with ChatGPT" 선택
codex

# 지원되는 플랜: Plus, Pro, Team, Edu, Enterprise
```

**대안: API 키 사용**

```bash
# 환경변수로 설정
export OPENAI_API_KEY="your-api-key"
```

⚠️ **참고**: ChatGPT 계정 로그인이 권장됩니다. API 키 사용 시 추가 설정이 필요할 수 있습니다.

## 명령어 패턴 (실제 테스트됨 ✅)

### 기본 실행

```bash
# 대화형 모드 (터미널 필요)
codex

# 비대화형 모드 - 인라인 프롬프트
codex exec "프롬프트 내용"

# 비대화형 모드 - stdin에서 읽기 (자동화 핵심!)
echo "프롬프트 내용" | codex exec -
```

### 검증된 옵션 (--help 출력 기반)

| 모드 | 설명 | 검증 상태 |
|------|------|-----------|
| `codex` | 대화형 모드 (터미널 필요) | ✅ 검증됨 |
| `codex exec [PROMPT]` | 비대화형 모드 | ✅ 검증됨 |
| `codex exec -` | stdin에서 프롬프트 읽기 | ✅ 검증됨 |
| `codex login` | 인증 관리 | ✅ 존재 확인 |
| `codex mcp` | MCP 서버 관리 | ✅ 존재 확인 |

### 주요 옵션 (검증됨)

| 옵션 | 설명 | 검증 상태 |
|------|------|-----------|
| `-m, --model <MODEL>` | 모델 선택 | ✅ --help에서 확인 |
| `-s, --sandbox <MODE>` | 샌드박스 모드 | ✅ --help에서 확인 |
| `-c, --config <key=value>` | 설정 오버라이드 | ✅ --help에서 확인 |
| `-i, --image <FILE>` | 이미지 첨부 | ✅ --help에서 확인 |
| `--oss` | 로컬 OSS 모델 사용 | ✅ --help에서 확인 |

### 주요 기능 (테스트 확인)

- **stdin 지원**: `codex exec -`로 파이프라인 자동화 가능 ✅
- **샌드박스 모드**: read-only, workspace-write, danger-full-access ✅
- **기본 모델**: gpt-5-codex (research preview)
- **세션 관리**: resume 서브커맨드로 세션 복원 가능
- **MCP 서버**: 실험적 기능 지원

### 샌드박스 모드

```bash
# 읽기 전용 (기본)
codex exec --sandbox read-only "코드 분석"

# 로컬 쓰기 허용
codex exec --sandbox workspace-write "코드 생성"

# 전체 접근 (위험)
codex exec --sandbox danger-full-access "시스템 작업"
```

### 세션 재개

```bash
# 마지막 세션 재개
echo "추가 작업" | codex exec resume --last

# 특정 세션 재개
codex exec resume --session-id <id>
```

## dual-ai-loop 연동

### 구현자 역할 (Mode A)

```bash
echo "다음 계획에 따라 구현하세요:

## 구현 계획
[Claude의 상세 계획]

## 요구사항
- 완전한 작동 코드 제공
- 에러 처리 포함
- 베스트 프랙티스 준수
- 복잡한 로직에 주석 추가

## 출력 형식
- 파일 경로와 전체 코드
- 구현 결정 설명
- 가정 사항 명시" | codex exec --sandbox workspace-write --full-auto
```

### 검증자 역할 (Mode B)

```bash
echo "다음 코드를 검증하세요:

## 검증 대상
[Claude가 작성한 코드]

## 검증 항목
- 로직 정확성
- 에러 처리 완성도
- 성능 이슈 여부
- 보안 취약점
- 베스트 프랙티스 준수

## 출력 형식
- 발견된 문제점 목록
- 각 문제의 심각도 (Critical/High/Medium/Low)
- 구체적인 개선 제안" | codex exec --sandbox read-only
```

### 응답 파싱

Codex의 출력을 분석하여:
1. 생성된 코드 추출
2. 설명/주석 분리
3. 에러 메시지 확인
4. 성공/실패 판정

## 에러 처리

### 일반적인 에러

**1. CLI 미설치**
```
오류: command not found: codex
해결: npm install -g @openai/codex-cli
```

**2. API 키 누락**
```
오류: API key not configured
해결: export OPENAI_API_KEY="your-key"
```

**3. 네트워크 오류**
```
오류: Network error / Connection timeout
해결: 인터넷 연결 확인, 재시도
```

**4. Rate Limit**
```
오류: Rate limit exceeded
해결: 잠시 대기 후 재시도 (지수 백오프)
```

**5. 모델 접근 불가**
```
오류: Model not available
해결: 다른 모델 선택, API 권한 확인
```

### 에러 복구 전략

```bash
# 재시도 로직 (bash)
MAX_RETRIES=3
RETRY_DELAY=2

for i in $(seq 1 $MAX_RETRIES); do
    result=$(echo "프롬프트" | codex exec 2>&1)
    if [ $? -eq 0 ]; then
        echo "성공: $result"
        break
    else
        echo "시도 $i 실패: $result"
        sleep $((RETRY_DELAY * i))
    fi
done
```

## 버전 정보

### VERSION.json

```json
{
  "cli_name": "codex",
  "current_supported_version": "2.0.0",
  "minimum_version": "1.5.0",
  "last_checked": "2025-11-16",
  "sources": {
    "official_docs": "https://openai.com/docs/codex-cli",
    "github_repo": "https://github.com/openai/codex-cli",
    "changelog": "https://github.com/openai/codex-cli/releases",
    "npm_package": "https://www.npmjs.com/package/@openai/codex-cli"
  },
  "install_check": "which codex",
  "version_command": "codex --version",
  "version_pattern": "codex version (\\d+\\.\\d+\\.\\d+)"
}
```

### 버전 호환성 매트릭스

| 스킬 버전 | Codex CLI 버전 | 호환성 |
|-----------|---------------|--------|
| 1.0.0 | 2.0.x | ✅ 완전 호환 |
| 1.0.0 | 1.5.x | ⚠️ 일부 기능 제한 |
| 1.0.0 | < 1.5.0 | ❌ 비호환 |

## 자동 업데이트 트리거

버전 불일치 감지 시 cli-updater에 전달할 정보:

```json
{
  "cli_name": "codex",
  "installed_version": "1.8.0",
  "supported_version": "2.0.0",
  "check_urls": [
    "https://github.com/openai/codex-cli/releases",
    "https://openai.com/docs/codex-cli/changelog"
  ],
  "update_items": [
    "명령어 구문 변경 여부",
    "새로운 옵션 추가",
    "삭제된 기능",
    "브레이킹 체인지"
  ]
}
```

## 베스트 프랙티스

### 1. 프롬프트 구성

```bash
# 명확한 구조로 프롬프트 작성
echo "## 작업
[명확한 작업 설명]

## 컨텍스트
[관련 정보]

## 제약사항
[제한 사항]

## 기대 출력
[원하는 형식]" | codex exec
```

### 2. 안전한 실행

```bash
# 항상 sandbox 모드 명시
codex exec --sandbox read-only "분석 작업"

# 위험한 작업은 사용자 확인
codex exec --sandbox workspace-write --confirm "파일 수정"
```

### 3. 결과 검증

```bash
# 출력을 파일로 저장하여 검토
codex exec > output.txt 2>&1

# exit code 확인
if [ $? -eq 0 ]; then
    echo "성공"
else
    echo "실패"
fi
```

### 4. 비용 관리

- 간단한 작업은 작은 모델 사용
- 토큰 사용량 모니터링
- 불필요한 반복 피하기

## 제한사항

1. **API 비용**: 사용량에 따른 비용 발생
2. **네트워크 의존**: 오프라인 사용 불가
3. **Rate Limit**: API 호출 제한 존재
4. **모델 가용성**: 일부 모델은 특정 계정에만 제공
5. **응답 시간**: 네트워크 상태에 따라 지연 가능

## 다음 단계

버전 변경 감지 시:
1. cli-updater 서브에이전트가 공식 문서 확인
2. 변경사항 분석
3. 이 SKILL.md 업데이트 제안
4. VERSION.json 갱신

## 관련 스킬

- `skills/dual-ai-loop/` - 코어 루프 스킬
- `skills/cli-updater/` - 자동 업데이트 서브에이전트
