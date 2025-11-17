---
name: cli-updater
description: CLI 도구의 버전 변경을 감지하고 관련 어댑터 스킬 및 문서를 자동으로 업데이트하는 서브에이전트.
---

# CLI Auto-Updater

## 개요

CLI 도구의 버전 변경을 감지하고, 관련 어댑터 스킬을 자동으로 업데이트하는 서브에이전트입니다.

**핵심 기능:**
- 설치된 CLI 버전과 스킬 지원 버전 비교
- 공식 문서/저장소에서 변경사항 수집
- 어댑터 스킬(SKILL.md) 업데이트 제안
- VERSION.json 갱신

## 실행 트리거

### 1. dual-ai-loop 실행 시 (자동)

```
dual-ai-loop 시작
  ↓
CLI 상태 확인
  ↓
버전 불일치 감지
  ↓
사용자 확인: "스킬 업데이트하시겠습니까?"
  ↓
cli-updater 서브에이전트 실행
```

### 2. 정기적 체크 (선택)

사용자가 설정한 주기로 모든 CLI 버전 확인

### 3. 수동 호출

사용자가 직접 업데이트 요청

## 업데이트 워크플로우

### Step 1: 버전 정보 수집

```bash
# 설치된 버전 확인
INSTALLED_VERSION=$(<cli_name> --version)

# 스킬 지원 버전 확인
SUPPORTED_VERSION=$(cat cli-adapters/<cli_name>/VERSION.json | jq -r '.current_supported_version')

# 비교
if [ "$INSTALLED_VERSION" != "$SUPPORTED_VERSION" ]; then
    echo "업데이트 필요"
fi
```

### Step 2: 공식 소스 확인

VERSION.json의 sources를 사용하여:

```
WebFetch 도구로 다음 URL 확인:
1. official_docs - 공식 문서
2. github_repo/releases - 릴리스 노트
3. changelog - 변경 로그
4. npm_package/pypi - 패키지 정보
```

### Step 3: 변경사항 분석

수집된 정보에서 추출:

```markdown
## 변경사항 분석

### 버전 차이
- 설치됨: 2.1.0
- 스킬 지원: 2.0.0

### 주요 변경사항
1. 새로운 기능
   - [기능 A 추가]
   - [기능 B 추가]

2. 명령어 변경
   - [구문 변경 사항]
   - [새 옵션 추가]

3. 삭제된 기능
   - [제거된 기능]

4. 브레이킹 체인지
   - [호환성 깨지는 변경]

### 영향도 평가
- 높음: 브레이킹 체인지 존재
- 중간: 새 기능/옵션 추가
- 낮음: 버그 수정/성능 개선
```

### Step 4: 스킬 업데이트 제안

```markdown
## SKILL.md 업데이트 제안

### 추가할 내용
1. 명령어 패턴 섹션에 새 옵션 추가
2. 설치 방법 업데이트 (필요시)
3. 에러 처리 섹션 갱신
4. 제한사항 업데이트

### 수정할 내용
1. 기존 명령어 구문 변경
2. 버전 정보 갱신
3. 호환성 매트릭스 업데이트

### 제거할 내용
1. 삭제된 기능 관련 문서
```

### Step 5: VERSION.json 갱신

```json
{
  "current_supported_version": "2.1.0",  // 업데이트
  "last_checked": "2025-11-16",          // 현재 날짜
  "last_updated": "2025-11-16",          // 현재 날짜
  "breaking_changes": {
    "2.1.0": [
      "새로 추가된 브레이킹 체인지"
    ]
  }
}
```

### Step 6: 사용자 확인 및 적용

```
## 업데이트 요약

CLI: codex
버전: 2.0.0 → 2.1.0

변경사항:
- 새 옵션: --streaming
- 구문 변경: exec → run
- 제거됨: --legacy-mode

다음 파일을 업데이트하시겠습니까?
1. cli-adapters/codex/SKILL.md
2. cli-adapters/codex/VERSION.json

[예/아니오]
```

## 상세 워크플로우

### WebFetch 패턴

**GitHub Releases 확인:**

```
WebFetch URL: https://github.com/<owner>/<repo>/releases
프롬프트: "최신 릴리스 노트에서 다음을 추출:
1. 버전 번호
2. 주요 변경사항
3. 브레이킹 체인지
4. 새로운 기능
5. 삭제된 기능"
```

**공식 문서 확인:**

```
WebFetch URL: <official_docs>
프롬프트: "CLI 사용법에서 다음을 확인:
1. 현재 명령어 구문
2. 사용 가능한 옵션
3. 설치 방법
4. 요구사항"
```

**Changelog 확인:**

```
WebFetch URL: <changelog_url>
프롬프트: "최근 버전 변경 로그에서:
1. 버전별 변경사항
2. 마이그레이션 가이드
3. 호환성 정보"
```

### Edit 패턴

**SKILL.md 업데이트:**

```
Read: cli-adapters/<cli_name>/SKILL.md

Edit:
- old_string: "이전 명령어 구문"
- new_string: "새로운 명령어 구문"

Edit:
- old_string: "버전 정보 섹션"
- new_string: "업데이트된 버전 정보"
```

**VERSION.json 업데이트:**

```
Read: cli-adapters/<cli_name>/VERSION.json

Edit:
- old_string: '"current_supported_version": "2.0.0"'
- new_string: '"current_supported_version": "2.1.0"'

Edit:
- old_string: '"last_checked": "2025-11-15"'
- new_string: '"last_checked": "2025-11-16"'
```

## 에러 처리

### 소스 접근 실패

```
오류: WebFetch 실패

대응:
1. 다른 소스 URL 시도
2. 캐시된 정보 사용
3. 수동 확인 안내
```

### 변경사항 파싱 실패

```
오류: 변경 로그 형식 인식 불가

대응:
1. 사용자에게 URL 직접 확인 요청
2. 주요 변경사항만 추출
3. 부분 업데이트 진행
```

### 파일 수정 충돌

```
오류: SKILL.md 수정 충돌

대응:
1. 변경사항 백업
2. 수동 편집 가이드 제공
3. 충돌 부분 표시
```

## 보고서 형식

### 업데이트 완료 보고서

```markdown
# CLI Updater 보고서

## 요약
- CLI: codex
- 이전 버전: 2.0.0
- 새 버전: 2.1.0
- 업데이트 일시: 2025-11-16

## 수행된 작업
1. ✅ VERSION.json 갱신
2. ✅ SKILL.md 명령어 섹션 업데이트
3. ✅ 에러 처리 섹션 추가
4. ⚠️ 브레이킹 체인지 문서화

## 주의사항
- exec 명령어가 run으로 변경됨
- dual-ai-loop에서 명령어 패턴 확인 필요

## 다음 단계
1. 업데이트된 스킬 테스트
2. dual-ai-loop 호환성 확인
3. 관련 문서 검토
```

### 업데이트 불필요 보고서

```markdown
# CLI Updater 보고서

## 요약
- CLI: codex
- 설치 버전: 2.0.0
- 지원 버전: 2.0.0
- 상태: ✅ 최신

## 다음 체크
- 예정일: 2025-11-23 (7일 후)
```

## 지원되는 CLI

현재 지원되는 CLI 어댑터:

1. **codex** (기본)
   - 소스: GitHub, npm
   - 패턴: 릴리스 노트 기반

2. **qwen**
   - 소스: GitHub, PyPI
   - 패턴: 릴리스 노트 기반

3. **copilot**
   - 소스: GitHub Extension
   - 패턴: Extension 버전 기반

4. **rovo-dev**
   - 소스: Atlassian Developer
   - 패턴: 공식 문서 기반

5. **aider**
   - 소스: GitHub, PyPI
   - 패턴: 릴리스 노트 기반

## 설정

### 자동 체크 주기

```json
// VERSION.json 내
{
  "update_check_interval_days": 7,
  "auto_update_enabled": false
}
```

### 알림 설정

- **critical**: 브레이킹 체인지 즉시 알림
- **high**: 주요 기능 변경 알림
- **medium**: 새 기능 추가 알림
- **low**: 버그 수정만

## 제한사항

1. **소스 의존성**
   - 공식 문서/저장소 접근 필요
   - URL 변경 시 수동 업데이트 필요

2. **파싱 한계**
   - 비정형 변경 로그는 분석 어려움
   - 모든 변경사항을 자동 감지하지 못할 수 있음

3. **자동화 한계**
   - 복잡한 변경은 수동 검토 필요
   - 의미적 변경은 감지 어려움

4. **네트워크 의존**
   - 오프라인에서 사용 불가
   - 소스 사이트 다운 시 실패

## 베스트 프랙티스

1. **정기적 체크**: 주 1회 버전 확인
2. **변경 로그 검토**: 자동 분석 후 수동 확인
3. **테스트**: 업데이트 후 실제 실행 테스트
4. **백업**: 변경 전 기존 파일 백업
5. **문서화**: 모든 업데이트 이력 기록

## 관련 스킬

- `skills/dual-ai-loop/` - 코어 루프 스킬
- `skills/cli-adapters/*/` - 각 CLI 어댑터 스킬
