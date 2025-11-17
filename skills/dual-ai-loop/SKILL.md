---
name: dual-ai-loop
description: 외부 AI CLI(codex, qwen, copilot, rovo-dev, aider)와 Claude의 협업 루프. 도구와 역할을 선택하여 계획-구현-리뷰 사이클을 실행. 기본값은 codex CLI.
---

# Dual-AI Engineering Loop

## ⚠️ 중요 경고

**검증된 CLI** (2025-11-17):
- ✅ **codex** (기본값) - @openai/codex v0.58.0 (npm 확인됨)
- ✅ **aider** - aider-chat v0.86.1 (PyPI 확인됨)

**미검증 CLI**:
- ⚠️ **copilot** - 존재하나 직접 테스트 안됨
- ❌ **qwen** - PyPI에서 찾을 수 없음, 대안으로 Ollama 사용 권장
- ❌ **rovo-dev** - 존재 여부 불확실

**실제 동작 방식**:
- 이 스킬은 "자동화된 시스템"이 아닙니다
- Claude가 수동으로 Bash 도구를 호출하여 CLI를 실행합니다
- "자동 버전 체크"는 Claude가 수동으로 확인하는 것입니다
- 사용자의 직접적인 개입이 필요합니다

## 개요

두 AI의 강점을 결합하는 엔지니어링 루프입니다. Claude Code와 외부 AI CLI 도구가 협업하여 고품질 코드를 생성합니다.

**핵심 기능:**
- 외부 AI CLI 도구 선택 (검증된 것: codex, aider)
- 역할 교체 가능 (구현자/리뷰어)
- 버전 체크 안내 (수동)
- 반복적 개선 루프

## 시작하기

### Step 1: CLI 도구 선택

사용자에게 질문 (AskUserQuestion):

```
어떤 AI CLI 도구를 사용하시겠습니까?

1. codex (기본값) - ✅ OpenAI Codex CLI (검증됨)
2. aider - ✅ Aider CLI (검증됨)
3. copilot - ⚠️ GitHub Copilot CLI (부분 검증)
4. qwen - ❌ Alibaba Qwen CLI (미검증 - 존재 불확실)
5. rovo-dev - ❌ Atlassian Rovo Dev CLI (미검증)

권장: codex 또는 aider (검증된 CLI)
```

### Step 2: CLI 상태 확인

선택된 CLI의 상태를 확인합니다:

```bash
# 1. 설치 여부 확인
which <cli_name>

# 2. 버전 확인
<cli_name> --version

# 3. 스킬 지원 버전과 비교
# cli-adapters/<cli_name>/VERSION.json 참조
```

**상태별 처리:**

- **미설치**: 설치 가이드 안내 (해당 어댑터 스킬 참조)
- **버전 불일치**: cli-updater 서브에이전트로 업데이트 제안
- **정상**: 루프 진행

### Step 3: 역할 설정

사용자에게 질문 (AskUserQuestion):

```
역할을 어떻게 설정하시겠습니까?

A. Claude = 계획/리뷰, 외부 AI = 구현 (기본값)
   → Claude가 설계하고, 외부 AI가 코드를 작성

B. Claude = 구현, 외부 AI = 검증/리뷰
   → Claude가 코드를 작성하고, 외부 AI가 검증
```

### Step 4: 반복 횟수 설정

사용자에게 질문 (AskUserQuestion):

```
최대 반복 횟수를 설정하세요 (기본값: 3):
```

## 루프 실행

### Mode A: Claude 계획/리뷰, 외부 AI 구현

```
┌─────────────────┐
│ 1. Claude 계획   │ Claude가 상세 구현 계획 수립
└────────┬────────┘
         ▼
┌─────────────────┐
│ 2. 외부 AI 구현  │ 선택된 CLI로 코드 생성
└────────┬────────┘
         ▼
┌─────────────────┐
│ 3. Claude 리뷰   │ 생성된 코드 분석 및 피드백
└────────┬────────┘
         ▼
┌─────────────────┐
│ 4. 품질 충분?    │─── 예 ──→ 완료
└────────┬────────┘
         │ 아니오
         ▼
┌─────────────────┐
│ 5. 피드백 전달   │ 개선 사항을 외부 AI에 전달
└────────┬────────┘
         │
         └──────────→ 2번으로 반복
```

**Phase 1: Claude 계획 수립**

```markdown
## 구현 계획

### 목표
[작업 목표 명시]

### 요구사항
- 기능적 요구사항
- 비기능적 요구사항
- 제약사항

### 구현 전략
1. [단계 1]
2. [단계 2]
3. [단계 3]

### 예상 구조
- 파일 구조
- 주요 함수/클래스
- 데이터 흐름

### 검증 기준
- [ ] 기준 1
- [ ] 기준 2
- [ ] 기준 3
```

**Phase 2: 외부 AI 구현**

선택된 CLI 어댑터의 명령어 패턴 사용:

```bash
# codex 예시
echo "다음 계획에 따라 구현하세요:

[Claude의 계획]

요구사항:
- 완전한 작동 코드 제공
- 에러 처리 포함
- 베스트 프랙티스 준수
- 복잡한 로직에 주석 추가" | codex exec
```

**Phase 3: Claude 리뷰**

```markdown
## 코드 리뷰

### 긍정적 측면
- ✅ [잘된 부분]

### 문제점
- ⚠️ [경고]
- 🔴 [심각한 문제]

### 개선 제안
- 💡 [제안 사항]

### 검증 결과
- [ ] 기준 1: 통과/실패
- [ ] 기준 2: 통과/실패

### 결정
- 충분: 완료
- 부족: 반복 필요
```

### Mode B: Claude 구현, 외부 AI 검증

```
┌─────────────────┐
│ 1. Claude 구현   │ Claude가 코드 작성
└────────┬────────┘
         ▼
┌─────────────────┐
│ 2. 외부 AI 검증  │ 선택된 CLI로 코드 검증
└────────┬────────┘
         ▼
┌─────────────────┐
│ 3. Claude 분석   │ 검증 결과 분석
└────────┬────────┘
         ▼
┌─────────────────┐
│ 4. 품질 충분?    │─── 예 ──→ 완료
└────────┬────────┘
         │ 아니오
         ▼
┌─────────────────┐
│ 5. Claude 개선   │ 피드백 기반 코드 수정
└────────┬────────┘
         │
         └──────────→ 2번으로 반복
```

**Phase 1: Claude 구현**

Claude가 Edit/Write 도구를 사용하여 직접 코드 작성

**Phase 2: 외부 AI 검증**

```bash
# codex 예시
echo "다음 코드를 검증하세요:

[Claude의 코드]

검증 항목:
- 로직 정확성
- 에러 처리
- 성능 이슈
- 보안 취약점
- 베스트 프랙티스 준수" | codex exec
```

**Phase 3: Claude 분석 및 개선**

외부 AI의 피드백을 분석하고, 필요시 코드 수정

## CLI 어댑터 연동

각 CLI의 구체적인 사용법은 해당 어댑터 스킬을 참조합니다:

```
skills/cli-adapters/
├── codex/SKILL.md      # codex CLI 상세 사용법
├── qwen/SKILL.md       # qwen CLI 상세 사용법
├── copilot/SKILL.md    # copilot CLI 상세 사용법
├── rovo-dev/SKILL.md   # rovo-dev CLI 상세 사용법
└── aider/SKILL.md      # aider CLI 상세 사용법
```

### 어댑터 스킬 호출

루프 실행 중 해당 CLI의 어댑터 스킬을 참조하여:
- 정확한 명령어 구문 확인
- 설치 방법 안내
- 버전 호환성 확인
- 에러 처리 방법

## 자동 버전 관리

### 버전 체크 트리거

루프 시작 시 자동으로:
1. 선택된 CLI의 설치 여부 확인
2. 현재 버전과 스킬 지원 버전 비교
3. 불일치 시 업데이트 제안

### cli-updater 서브에이전트

버전 불일치 감지 시:

```
Task 도구로 cli-updater 서브에이전트 실행:
1. 공식 문서/저장소 WebFetch
2. 변경사항 분석
3. 어댑터 스킬 업데이트 제안
4. VERSION.json 갱신
```

## 에러 처리

### CLI 미설치

```
"선택하신 {cli_name} CLI가 설치되어 있지 않습니다.

설치 방법:
[어댑터 스킬의 설치 가이드 참조]

다른 CLI를 선택하시겠습니까?"
```

### CLI 실행 실패

```
"{cli_name} 실행 중 오류가 발생했습니다.

오류: [에러 메시지]

선택 가능한 조치:
1. 재시도
2. 다른 CLI로 전환
3. Claude가 직접 구현/리뷰
```

### 버전 불일치

```
"{cli_name} 버전이 업데이트되었습니다.
현재: {current_version}
스킬 지원: {supported_version}

스킬을 업데이트하시겠습니까?
→ 예: cli-updater 실행
→ 아니오: 현재 상태로 진행 (문제 발생 가능)"
```

## 최종 결과 보고

루프 완료 시:

```markdown
## Dual-AI Loop 완료 보고

### 설정
- CLI: {선택된 CLI}
- 역할: {Mode A/B}
- 반복 횟수: {실제 반복 수} / {최대 설정}

### 결과
- 생성된 파일: [목록]
- 품질 평가: [점수/등급]
- 주요 개선 사항: [목록]

### 히스토리
1. 반복 1: [요약]
2. 반복 2: [요약]
...

### 다음 단계
- [권장 조치]
```

## 사용 예시

### 예시 1: 로그인 기능 구현

```
사용자: "로그인 기능 구현해줘"

Claude:
1. CLI 선택? → codex (기본값)
2. CLI 상태: ✅ 설치됨, v2.0.0
3. 역할: Mode A (Claude 계획, codex 구현)
4. 반복: 3회

[루프 시작]
→ Claude가 JWT 기반 인증 계획 수립
→ codex가 코드 생성
→ Claude가 리뷰: "에러 처리 부족"
→ codex가 수정
→ Claude가 최종 승인
[완료]
```

### 예시 2: 코드 리팩토링

```
사용자: "이 함수 리팩토링해줘"

Claude:
1. CLI 선택? → rovo-dev
2. 역할: Mode B (Claude 구현, rovo-dev 검증)
3. 반복: 2회

[루프 시작]
→ Claude가 리팩토링 수행
→ rovo-dev가 검증: "성능 이슈 발견"
→ Claude가 최적화
→ rovo-dev 승인
[완료]
```

## 제한사항

1. **CLI 도구 의존성**
   - 해당 CLI가 설치되어 있어야 함
   - 일부 CLI는 구독/라이선스 필요

2. **자동화의 한계**
   - 완전 자동이 아닌 반자동 워크플로우
   - 사용자 확인이 필요한 단계 있음

3. **품질 보장 불가**
   - 외부 AI의 결과물 품질이 다양함
   - 최종 검증은 사용자 책임

4. **버전 호환성**
   - CLI 버전 변경 시 스킬 업데이트 필요
   - 자동 업데이트는 제안만 할 뿐 강제하지 않음

## 관련 스킬

- `skills/cli-adapters/codex/` - Codex CLI 어댑터
- `skills/cli-adapters/qwen/` - Qwen CLI 어댑터
- `skills/cli-adapters/copilot/` - Copilot CLI 어댑터
- `skills/cli-adapters/rovo-dev/` - Rovo Dev CLI 어댑터
- `skills/cli-adapters/aider/` - Aider CLI 어댑터
- `skills/cli-updater/` - 자동 버전 업데이트 서브에이전트
