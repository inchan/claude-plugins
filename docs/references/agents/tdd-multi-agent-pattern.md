# TDD 다중 에이전트 패턴

> cc-plugins 프로젝트의 TDD 자동화 패턴

**구현 위치**: `agents/tdd/`, `commands/tdd-team.md`

**아키텍처**: `/tdd-team` 커맨드가 메인 스레드에서 5개 에이전트를 조율

---

## 개요

5개의 전문화된 에이전트가 협업하여 Red-Green-Refactor 사이클을 자동화하는 TDD 개발 팀 시스템입니다.

### 핵심 원칙

1. **전문화**: 각 에이전트는 TDD 사이클의 한 단계만 담당
2. **순차 실행**: Red → Green → Refactor 순서 엄격 준수
3. **품질 게이트**: Reviewer의 승인 없이 다음 단계 진행 불가
4. **Fail-Safe**: 일부 작업 실패해도 전체 계속 진행

---

## 에이전트 구성 (5개)

| 에이전트 | 역할 | 책임 | 도구 |
|---------|------|------|------|
| **Task Planner** | 작업 분해 | 큰 기능 → 작은 단위 (20개 제한) | Read, Grep, Glob, TodoWrite |
| **Test Writer** | Red 단계 | 실패하는 테스트 먼저 작성 | Read, Grep, Glob, Write, Bash |
| **Implementer** | Green 단계 | 테스트 통과하는 최소 코드 | Read, Edit, Bash |
| **Refactorer** | Refactor 단계 | 코드 품질 개선 | Read, Edit, Grep, Bash |
| **Reviewer** | 품질 검증 | 승인/거부 결정 + 피드백 | Read, Grep, Bash |

**워크플로우 조율**: `/tdd-team` 커맨드가 메인 스레드에서 담당 (Claude Code 제약으로 인한 아키텍처 변경)

---

## 아키텍처

### 실행 흐름

```
사용자: /tdd-team "기능 설명"
    ↓
┌─────────────────────────────────────┐
│ /tdd-team 커맨드 활성화              │
│ (메인 스레드에서 워크플로우 조율)     │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│ 1. Task Planner                     │
│    기능 → N개 작업으로 분해 (최대 20개)│
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│ 2. FOR EACH 작업:                   │
│                                     │
│  ┌─ Red (Test Writer) ─────────┐   │
│  │  - 실패 테스트 작성           │   │
│  │  - 실패 확인 (0 passed)      │   │
│  └──────────────────────────────┘   │
│    ↓                                │
│  ┌─ Green (Implementer) ────────┐   │
│  │  - 최소 코드 작성             │   │
│  │  - 테스트 통과 (N passed)    │   │
│  └──────────────────────────────┘   │
│    ↓                                │
│  ┌─ Refactor (Refactorer) ──────┐   │
│  │  - 코드 품질 개선             │   │
│  │  - 테스트 여전히 통과        │   │
│  └──────────────────────────────┘   │
│    ↓                                │
│  ┌─ Review (Reviewer) ───────────┐   │
│  │  - P1-P4 원칙 검증            │   │
│  │  - 승인/거부 결정             │   │
│  └──────────────────────────────┘   │
│    ↓                                │
│    승인? ─ NO ─→ 재시도 (최대 3회)   │
│    ↓ YES                            │
│    다음 작업                         │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│ 3. 최종 리포트 생성                  │
│    - 성공/실패 통계                  │
│    - 생성된 파일 목록                │
└─────────────────────────────────────┘
```

### 데이터 흐름

```
Task Planner
    ↓ (tasks[])
FOR EACH task:
    Test Writer
        ↓ (test_file, failing_tests)
    Implementer
        ↓ (implementation_file, test_result)
    Refactorer
        ↓ (refactored_code, metrics)
    Reviewer
        ↓ (decision: approved/rejected)

    IF approved:
        다음 작업
    ELSE:
        재시도 (최대 3회)
```

---

## 에이전트 간 통신 프로토콜

### JSON 기반 표준화

모든 에이전트는 명확한 Input/Output JSON 형식을 사용합니다.

#### Task Planner → Test Writer

```json
{
  "task_id": "TASK-001",
  "success_criteria": {
    "input": { "type": "string", "description": "이메일 주소" },
    "output": { "type": "boolean", "description": "유효 여부" },
    "edge_cases": [
      "빈 문자열 → false",
      "@ 없음 → false",
      "도메인 없음 → false"
    ]
  },
  "files": {
    "implementation": "src/validators/email.ts",
    "test": "src/validators/email.test.ts"
  },
  "test_framework": "jest"
}
```

#### Test Writer → Implementer

```json
{
  "task_id": "TASK-001",
  "test_file": "src/validators/email.test.ts",
  "failing_tests": [
    "returns true for valid email",
    "returns false for empty string",
    "returns false when @ is missing"
  ],
  "interface_suggestion": {
    "function_signature": "function validateEmail(email: string): boolean"
  }
}
```

#### Implementer → Refactorer

```json
{
  "task_id": "TASK-001",
  "implementation_file": "src/validators/email.ts",
  "test_result": {
    "passed": 4,
    "failed": 0,
    "coverage": 100
  },
  "complexity_metrics": {
    "function_length": 12,
    "condition_depth": 1
  }
}
```

#### Refactorer → Reviewer

```json
{
  "task_id": "TASK-001",
  "changes": [
    {
      "type": "extract_function",
      "reason": "함수 길이 감소"
    }
  ],
  "metrics": {
    "before": { "function_length": 15, "complexity": 5 },
    "after": { "function_length": 10, "complexity": 3 }
  },
  "test_result": {
    "passed": 4,
    "failed": 0
  }
}
```

#### Reviewer → Orchestrator

```json
{
  "decision": "approved",
  "quality_score": 92,
  "feedback": [],
  "checklist": {
    "p1_validation_first": true,
    "p2_kiss_yagni": true,
    "function_length_40": true,
    "condition_depth_3": true,
    "tests_passing": true
  },
  "next_action": "proceed_to_next_task"
}
```

---

## 루프 제어 로직

### /tdd-team 커맨드의 핵심 루프

```python
def orchestrate(feature_description):
    # 1. 작업 분해
    tasks = call_task_planner(feature_description)

    # 2. 20개 제한 확인
    if len(tasks) > 20:
        user_choice = ask_user("작업 수 초과", ["첫 20개만", "분할", "전체"])
        if user_choice == "첫 20개만":
            tasks = tasks[:20]
        elif user_choice == "분할":
            return "기능을 분할하여 재실행하세요"

    # 3. 각 작업 처리
    for task in tasks:
        todo_write(f"TASK-{task.id}: {task.title}", "in_progress")

        result = execute_red_green_refactor_cycle(task)

        if result.success:
            todo_write(f"TASK-{task.id}", "completed")
        else:
            # 실패 처리
            user_choice = ask_user(
                f"TASK-{task.id} 실패",
                ["스킵하고 계속", "재시도", "중단"]
            )

            if user_choice == "스킵하고 계속":
                failed_tasks.append(task)
            elif user_choice == "재시도":
                result = execute_red_green_refactor_cycle(task)
            else:  # 중단
                break

    # 4. 최종 리포트
    return generate_report(tasks, failed_tasks)


def execute_red_green_refactor_cycle(task):
    attempt = 1
    max_retries = 3

    while attempt <= max_retries:
        # Red 단계
        red_output = call_test_writer(task)
        if red_output.status != "red":
            attempt += 1
            continue

        # Green 단계
        green_output = call_implementer(red_output)
        if green_output.status != "green":
            attempt += 1
            continue

        # Refactor 단계
        refactor_output = call_refactorer(green_output)
        if refactor_output.status != "refactored":
            attempt += 1
            continue

        # Review 단계
        review_output = call_reviewer(refactor_output)

        if review_output.decision == "approved":
            return {"success": True}
        else:
            attempt += 1
            # 피드백을 다음 시도에 반영

    return {"success": False, "reason": "max_retries_exceeded"}
```

---

## 실패 처리 전략

### 1. 재시도 메커니즘

```
작업당 최대 3회 재시도
    ↓
각 재시도마다 Reviewer 피드백 반영
    ↓
3회 실패 시 사용자에게 질문
```

### 2. 사용자 개입 시점

```python
IF cycle_failed_after_3_retries:
    user_choice = AskUserQuestion({
        question: "TASK-{id} 실패. 어떻게 할까요?",
        options: [
            "스킵하고 계속",  # Partial Success 허용
            "재시도",          # 4회째 시도
            "중단"            # 전체 종료
        ]
    })
```

### 3. Partial Success 허용

```
전체 10개 작업 중:
- 8개 성공 ✓
- 2개 실패 ✗

→ status: "partial"
→ 성공한 8개 결과 반환
→ 실패한 2개 별도 리포트
```

---

## 진행 추적

### TodoWrite 2단계 구조

```json
{
  "todos": [
    // 레벨 1: 전체 및 작업 목록
    {
      "content": "전체: 사용자 인증 API (5개 작업)",
      "status": "in_progress"
    },
    {
      "content": "TASK-001: 이메일 검증",
      "status": "completed"
    },
    {
      "content": "TASK-002: 비밀번호 해싱",
      "status": "in_progress"
    },

    // 레벨 2: 현재 작업의 단계
    {
      "content": "  ├─ Red: 실패 테스트 작성",
      "status": "completed"
    },
    {
      "content": "  ├─ Green: 테스트 통과 코드",
      "status": "in_progress"
    },
    {
      "content": "  ├─ Refactor: 코드 개선",
      "status": "pending"
    },
    {
      "content": "  └─ Review: 품질 검증",
      "status": "pending"
    }
  ]
}
```

---

## 성능 최적화

### 순차 실행 (병렬 불가)

TDD는 본질적으로 순차적:

```
Red → Green → Refactor
  (각 단계는 이전 단계 결과 의존)
```

### 예상 실행 시간

| 작업 수 | 예상 시간 |
|--------|----------|
| 1-5개 | 5-15분 |
| 6-10개 | 15-30분 |
| 11-20개 | 30-60분 |

작업당 평균 3분 (Red 1분 + Green 1분 + Refactor+Review 1분)

---

## 베스트 프랙티스

### ✓ Do

1. **명확한 기능 설명**
   ```bash
   ✓ /tdd-team "이메일 형식 검증 함수"
   ✗ /tdd-team "검증"
   ```

2. **작은 단위로 분할**
   ```bash
   ✓ /tdd-team "사용자 등록 API"
   ✗ /tdd-team "전체 전자상거래 시스템"
   ```

3. **요구사항 명시**
   ```bash
   ✓ /tdd-team "결제 API" "PCI-DSS 준수" "3D Secure"
   ```

4. **실패 시 스킵**
   - 일부 작업 실패해도 나머지 진행
   - 나중에 실패한 작업만 재시도

### ✗ Don't

1. **모호한 요구사항**
   ```bash
   ✗ /tdd-team "좋은 API 만들기"
   ```

2. **너무 큰 범위**
   ```bash
   ✗ /tdd-team "전체 백엔드 시스템"
   ```

3. **테스트 프레임워크 없이 실행**
   ```bash
   # package.json에 jest 없으면 에러
   ```

---

## 실전 예제

### Example 1: 단순 유틸리티

**입력**:
```bash
/tdd-team "배열 합계 함수"
```

**실행**:
```
1. Task Planner → 1개 작업
2. TASK-001: 배열 합계 함수
   - Red: 4개 테스트 (빈 배열, 단일, 음수, 소수)
   - Green: 3줄 구현 (reduce 사용)
   - Refactor: 변경 없음 (이미 단순)
   - Review: 승인 ✓
3. 완료 (3분)
```

**출력**:
```
✓ 1/1개 작업 완료

생성 파일:
- src/math/sum.ts (3줄)
- src/math/sum.test.ts (20줄)
```

### Example 2: 중간 복잡도

**입력**:
```bash
/tdd-team "사용자 인증 API" "이메일 로그인" "JWT 토큰"
```

**실행**:
```
1. Task Planner → 5개 작업
   - TASK-001: 이메일 검증
   - TASK-002: 비밀번호 검증
   - TASK-003: 비밀번호 해싱
   - TASK-004: 로그인 로직
   - TASK-005: JWT 생성

2. 실행:
   TASK-001 ✓ (3분)
   TASK-002 ✓ (3분)
   TASK-003 ✓ (4분)
   TASK-004 ✓ (5분)
   TASK-005 ✗ (재시도 3회 후 실패)

3. 사용자 질문: "TASK-005 실패. 어떻게 할까요?"
   → 선택: "스킵하고 계속"

4. 완료 (4/5, 18분)
```

**출력**:
```
✓ 4/5개 작업 완료 (80%)

성공:
✓ TASK-001: 이메일 검증
✓ TASK-002: 비밀번호 검증
✓ TASK-003: 비밀번호 해싱
✓ TASK-004: 로그인 로직

실패:
✗ TASK-005: JWT 생성
  - 실패 이유: 함수 길이 52줄 (40줄 초과)
  - 제안: 함수를 generateToken, signToken으로 분리

다음 단계:
/tdd-team "JWT 토큰 생성 함수"
```

---

## 제한 사항

1. **병렬 작업 불가**: 의존성 있는 작업은 순차만 가능
2. **최대 20개**: 한 번에 20개 작업까지
3. **자동 커밋 없음**: 사용자가 수동으로 Git 커밋
4. **동적 분석 불가**: 런타임 프로파일링, 메모리 누수 탐지 불가

---

## 관련 문서

- [TDD Orchestrator 가이드](./tdd-orchestrator-guide.md) (참조용)
- [Task Planner](../../../agents/tdd/task-planner.md)
- [Test Writer](../../../agents/tdd/test-writer.md)
- [Implementer](../../../agents/tdd/implementer.md)
- [Refactorer](../../../agents/tdd/refactorer.md)
- [Reviewer](../../../agents/tdd/reviewer.md)
- [/tdd-team 커맨드](../../../commands/tdd-team.md)
- [개발 가이드라인](../../guidelines/development.md)

---

## 변경 이력

- **2025-11-29**: orchestrator 에이전트 제거, /tdd-team 커맨드가 조율 담당 (5개 에이전트로 변경)
- **2025-11-28**: TDD 다중 에이전트 패턴 문서 작성
