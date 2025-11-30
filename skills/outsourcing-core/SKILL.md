---
name: outsourcing-core
description: 로컬 AI CLI에 작업을 아웃소싱할 때 자동 활성화. Use when the task is complex, requires specialized AI capabilities, or benefits from distributing work to different AI models
---

# Outsourcing Core Skill

## 목적

복잡하거나 특화된 AI 능력이 필요한 작업을 로컬 AI CLI(claude, gemini, codex, qwen)에 위임하는 스킬입니다.

## 핵심 지침

### 1. 자동 활성화 조건

**v0.1.0 (현재)**:
- 사용자가 `/outsource` 커맨드를 직접 호출할 때만 활성화

**v0.2.0 이후 (계획)**:
- 작업이 특정 AI CLI의 전문 분야에 해당 (키워드 기반 분석)
- 현재 Claude가 처리하기 어려운 작업 (복잡도 계산)
- 병렬 처리가 필요한 대규모 작업

### 2. CLI 선택 가이드

**자동 활성화 시 CLI 추천:**

작업 내용을 분석하여 적합한 CLI를 추천하세요:

```python
IF 작업에 "코드 생성", "테스트 작성", "디버깅" 포함:
    추천 CLI = codex

ELIF 작업에 "아키텍처", "보안 분석", "코드 리뷰" 포함:
    추천 CLI = claude

ELIF 작업에 "번역", "대규모 데이터", "로그 분석" 포함:
    추천 CLI = gemini

ELIF 작업에 "수학", "알고리즘", "최적화" 포함:
    추천 CLI = qwen

ELSE:
    추천 CLI = claude (기본값)
```

### 3. 사용자 인터랙션

**대화형 CLI 선택 (v0.1.0):**

```
1. 작업 분석
2. 추천 CLI 제시 (1개)
3. 사용자에게 다른 CLI 선택 옵션 제공
4. 선택된 CLI로 작업 전달
```

**복잡도 기반 자동 선택 (v0.2.0+):**
- 작업 복잡도 계산 (키워드 + 길이 기반)
- 자동으로 최적 CLI 선택
- 사용자에게 결과만 표시

### 4. MCP 통합

**MCP 도구 사용:**

이 스킬은 다음 MCP 도구를 사용합니다:

1. `mcp__ai-cli-ping-pong__list_available_clis`
   - 로컬에 설치된 CLI 목록 확인

2. `mcp__ai-cli-ping-pong__send_message`
   - 선택된 CLI에 작업 전달
   - 응답 수신

### 5. 에러 처리

**일반적인 에러 시나리오:**

| 에러 | 원인 | 해결 방법 |
|------|------|----------|
| MCP 연결 실패 | ai-cli-ping-pong 미실행 | MCP 서버 시작 안내 |
| CLI 미설치 | 선택한 CLI 없음 | 설치 가이드 제공 |
| Git 저장소 에러 | Codex는 Git 필요 | 다른 CLI 추천 |
| API 키 오류 | 환경 변수 미설정 | 설정 방법 안내 |

---

## 참고 자료

상세 내용은 `resources/` 참조:

- **CLI 특징**: `resources/cli-capabilities.md`
  - 각 CLI의 강점, 약점, 적합한 작업
  - 비용 비교
  - 사용 사례별 추천

---

## 사용 예시

### 예시 1: 코드 생성 작업

```
사용자: "FastAPI로 RESTful API 서버 만드는 예제 작성해줘"

스킬 활성화:
1. 키워드 분석: "코드 생성", "RESTful API"
2. 추천 CLI: codex (코드 생성 전문)
3. 사용자 확인 후 codex에 작업 전달
4. 결과 요약 + 상세 코드 제공
```

### 예시 2: 아키텍처 분석

```
사용자: "이 프로젝트의 아키텍처를 분석하고 개선점 제안해줘"

스킬 활성화:
1. 키워드 분석: "아키텍처 분석", "개선점"
2. 추천 CLI: claude (심층 분석 강점)
3. 사용자 확인 후 claude에 작업 전달
4. 결과 요약 + 상세 분석 제공
```

---

## 제약 사항

- **v0.1.0**: 단일 CLI 실행만 지원 (병렬 처리 미지원)
- **v0.1.0**: 복잡도 자동 계산 미지원 (사용자 선택)
- **MCP 필수**: ai-cli-ping-pong MCP 서버 설치 필요
- **CLI 설치 필요**: 사용할 CLI가 로컬에 설치되어 있어야 함

---

## 향후 계획

### v0.2.0
- 복잡도 기반 자동 CLI 추천
- 키워드 + 프롬프트 길이 분석

### v0.3.0
- 병렬 처리 지원
- 여러 CLI에 동시 작업 전달
- 결과 비교 및 통합

---

## 변경 이력

- **2025-11-30**: 초기 작성 (v0.1.0 - 대화형 CLI 선택)
