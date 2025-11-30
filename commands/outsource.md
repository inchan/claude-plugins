---
description: MCP를 통해 로컬 CLI에 작업을 아웃소싱
allowed-tools: Task, AskUserQuestion
argument-hint: <task-description>
---

# Outsource Command

MCP를 통해 로컬에 설치된 AI CLI(claude, gemini, codex, qwen)에 작업을 위임하는 커맨드입니다.

## 사용법

```bash
# 기본 사용 (CLI 선택 질문)
/outsource "복잡한 코드 분석 작업"

# 예시
/outsource "이 프로젝트의 아키텍처를 분석하고 개선점을 제안해줘"
/outsource "Python으로 REST API 서버 만드는 예제 코드 작성해줘"
```

---

## 당신의 작업

### Step 1: 입력 파싱 및 검증

**1.1 $ARGUMENTS 파싱**

$ARGUMENTS를 분석하여 `task`를 추출하세요:

- task: $ARGUMENTS 전체 문자열

**1.2 검증 수행**

다음 검증을 순서대로 수행하세요:

1. **task 길이 확인**
   - task < 5자 → 에러 출력 후 종료:
     ```
     에러: 작업 설명은 최소 5자 이상이어야 합니다.

     사용 예시:
       /outsource "React 컴포넌트 설계 패턴 조사"
       /outsource "이 코드의 성능 병목 지점 분석"
     ```

2. **task 내용 확인**
   - task가 비어있거나 공백만 있을 경우 → 에러 출력 후 종료:
     ```
     에러: 작업 내용을 입력해주세요.

     사용법: /outsource <task-description>
     ```

검증 통과 시 Step 2로 진행하세요.

---

### Step 2: CLI 선택

**AskUserQuestion 도구를 사용하여 CLI를 선택하세요:**

```json
{
  "questions": [
    {
      "question": "어떤 AI CLI에 작업을 위임하시겠습니까?",
      "header": "CLI 선택",
      "multiSelect": false,
      "options": [
        {
          "label": "Claude",
          "description": "Anthropic Claude - 복잡한 분석, 코드 리뷰, 아키텍처 설계에 강함"
        },
        {
          "label": "Gemini",
          "description": "Google Gemini - 대규모 데이터 처리, 다국어 번역에 강함"
        },
        {
          "label": "Codex",
          "description": "OpenAI Codex - 코드 생성, 디버깅, 테스트 작성에 강함 (Git 저장소 필요)"
        },
        {
          "label": "Qwen",
          "description": "Alibaba Qwen - 수학 문제 해결, 논리적 추론에 강함"
        }
      ]
    }
  ]
}
```

**사용자 선택을 `selected_cli` 변수에 저장하세요:**
- "Claude" → selected_cli = "claude"
- "Gemini" → selected_cli = "gemini"
- "Codex" → selected_cli = "codex"
- "Qwen" → selected_cli = "qwen"

---

### Step 3: Outsourcing Agent 호출

**Task 도구를 사용하여 outsourcing-agent를 호출하세요:**

```
subagent_type: "general-purpose"
description: "CLI로 작업 아웃소싱"
prompt: |
  당신은 outsourcing-agent입니다.

  다음 작업을 {selected_cli} CLI에 전달하고 결과를 처리하세요:

  **작업**: {task}
  **선택된 CLI**: {selected_cli}

  agents/outsourcing/outsourcing-agent.md 파일의 지시사항을 따라 수행하세요.
```

**중요**:
- `{task}`와 `{selected_cli}`는 실제 값으로 치환하세요
- 에이전트 응답을 그대로 사용자에게 전달하세요

**에러 처리**:

Task 도구 호출 후 다음 검증을 수행하세요:

1. **에이전트 호출 실패 시**:
   ```
   에러: 에이전트 호출 중 오류가 발생했습니다.

   상세 오류: {error_message}

   해결 방법:
   1. 네트워크 연결 확인
   2. Claude Code 재시작
   3. 문제가 지속되면 /help로 지원 요청
   ```

2. **에이전트 응답이 비어있을 시**:
   ```
   에러: 에이전트로부터 응답을 받지 못했습니다.

   가능한 원인:
   - MCP 서버 연결 문제
   - 선택한 CLI 미설치

   해결 방법: 트러블슈팅 가이드 참조 (README.md)
   ```

---

### Step 4: 에러 처리

**Edge Cases 테이블:**

| 상황 | 처리 방법 |
|------|----------|
| task가 너무 짧음 (< 5자) | Step 1.2 검증에서 에러 출력 후 종료 |
| task가 비어있음 | Step 1.2 검증에서 에러 출력 후 종료 |
| 사용자가 CLI 선택을 취소 | "작업이 취소되었습니다" 출력 후 종료 |
| Agent 호출 실패 | 에러 메시지를 사용자에게 전달 |
| MCP 서버 연결 실패 | Agent에서 처리 (outsourcing-agent.md 참조) |

---

## 예시

### 예시 1: 코드 분석 요청

```bash
$ /outsource "이 리포지토리의 테스트 커버리지를 분석하고 개선 방안을 제안해줘"

어떤 AI CLI에 작업을 위임하시겠습니까?
[사용자 선택: Claude]

작업을 Claude CLI에 전달 중...

## 요약
테스트 커버리지 65% (목표: 80%). 주요 누락: API 엔드포인트 에러 핸들링,
비동기 함수 경계 케이스. 우선순위: auth 모듈(현재 45%) 테스트 보강 권장.

## 상세 분석
[펼쳐보기]
...
```

### 예시 2: 코드 생성 요청

```bash
$ /outsource "FastAPI로 RESTful API 서버 만드는 예제 코드 작성"

어떤 AI CLI에 작업을 위임하시겠습니까?
[사용자 선택: Codex]

작업을 Codex CLI에 전달 중...

## 요약
FastAPI 기본 구조(라우팅, Pydantic 모델, CRUD 엔드포인트) 예제 생성 완료.
SQLAlchemy ORM 통합, 비동기 처리, OpenAPI 문서 자동 생성 포함.

## 생성된 코드
[펼쳐보기]
...
```

---

## 제약 사항

- **MCP 서버 필수**: ai-cli-ping-pong MCP 서버가 설치되어 있어야 합니다
- **CLI 설치 필요**: 선택한 CLI(claude, gemini, codex, qwen)가 로컬에 설치되어 있어야 합니다
- **Codex Git 제약**: Codex 사용 시 현재 디렉토리가 Git 저장소여야 합니다 (skip_git_repo_check 옵션 없음)

---

## 참고

- **Agent 문서**: agents/outsourcing/outsourcing-agent.md
- **CLI 특징**: skills/outsourcing-core/resources/cli-capabilities.md
