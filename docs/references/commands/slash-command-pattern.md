# 슬래시 커맨드 패턴 레퍼런스

> code-review 플러그인 기반 커맨드 패턴

**출처**: https://github.com/anthropics/claude-code/tree/main/plugins/code-review

---

## 개요

슬래시 커맨드(`/command-name`)는 사용자가 명시적으로 호출하는 확장 기능입니다.

### 특징

- **명시적 호출**: 사용자가 `/`로 시작하는 명령어 입력
- **Markdown 정의**: `.md` 파일로 정의
- **프롬프트 확장**: 커맨드 내용이 프롬프트로 확장됨

---

## 파일 구조

```
commands/
└── {command-name}.md
```

**예시**:
```
commands/
└── code-review.md    → /code-review 커맨드
```

---

## Markdown 형식

### 기본 구조

```markdown
# /command-name

## Description
커맨드에 대한 간단한 설명

## Usage
/command-name [arguments]

## Arguments
- `arg1`: 인자 설명

## Implementation
이 커맨드가 실행될 때 수행할 작업:

1. 첫 번째 단계
2. 두 번째 단계
3. 세 번째 단계

## Examples
### Example 1
/command-name arg1

예상 결과...
```

### code-review 예제 (추정)

```markdown
# /code-review

## Description
자동화된 코드 리뷰를 수행합니다.

## Usage
/code-review

## Implementation

### 1. PR 정보 수집
- 현재 브랜치의 변경사항 확인
- Git diff 분석
- 변경된 파일 목록 생성

### 2. 에이전트 실행
다음 에이전트들을 병렬로 실행:
- CLAUDE.md 준수 검사 에이전트 #1
- CLAUDE.md 준수 검사 에이전트 #2
- Bug Detector 에이전트
- History Analyzer 에이전트

### 3. 결과 통합
- 각 에이전트 결과 수집
- 중복 이슈 제거
- 우선순위 정렬

### 4. 리포트 생성
다음 형식으로 리포트 출력:
\`\`\`
## Code Review Report

### Critical Issues
- ...

### Suggestions
- ...

### Summary
- Files reviewed: X
- Issues found: Y
\`\`\`
```

---

## 커맨드 작동 원리

### 1. 호출

사용자가 입력:
```
/code-review
```

### 2. 확장

Claude Code가 `commands/code-review.md` 내용을 프롬프트로 확장:
```
User: [Original prompt]

System: Execute the /code-review command as defined:

[code-review.md 내용이 여기 삽입됨]
```

### 3. 실행

확장된 프롬프트에 따라 Claude가 작업 수행

---

## 구현 패턴

### 패턴 1: 에이전트 호출

```markdown
# /my-command

## Implementation

Use the Task tool to call the following agents:
1. Task(subagent_type="analyzer", prompt="Analyze the code")
2. Task(subagent_type="suggester", prompt="Provide suggestions")

Combine the results and present them to the user.
```

### 패턴 2: 도구 사용

```markdown
# /run-tests

## Implementation

1. Use Bash tool to run tests:
   ```bash
   npm test
   ```

2. Analyze the output:
   - If tests pass: Report success
   - If tests fail: List failing tests

3. Provide suggestions for fixing failures
```

### 패턴 3: 파일 조작

```markdown
# /create-component

## Arguments
- `component-name`: Name of the component

## Implementation

1. Read template file:
   - Use Read tool to load `templates/component.tsx`

2. Replace placeholders:
   - `{{COMPONENT_NAME}}` → user-provided name

3. Write new file:
   - Use Write tool to create `src/components/{component-name}.tsx`

4. Update index:
   - Add export to `src/components/index.ts`
```

---

## 베스트 프랙티스

### ✓ Do

1. **명확한 설명**: Description에 커맨드 목적 명시
   ```markdown
   ## Description
   자동화된 코드 리뷰를 수행하여 버그와 스타일 이슈를 탐지합니다.
   ```

2. **단계별 구현**: Implementation을 명확한 단계로 분리
   ```markdown
   ## Implementation
   1. 정보 수집
   2. 분석 실행
   3. 결과 포맷팅
   4. 출력
   ```

3. **예제 제공**: 실제 사용 예시 포함
   ```markdown
   ## Examples
   ### Basic usage
   /code-review

   ### With specific files
   /code-review src/app.ts src/utils.ts
   ```

4. **에러 처리 명시**:
   ```markdown
   ## Error Handling
   - If no changes found: Display "No changes to review"
   - If git not available: Display "Git repository required"
   ```

### ✗ Don't

1. **모호한 지시**:
   ```markdown
   ## Implementation
   Do the review  # 너무 추상적
   ```

2. **예제 없음**: 사용법만 나열하고 예제 생략

3. **에러 무시**: 실패 케이스 처리 없음

---

## 고급 패턴

### 파라미터 처리

```markdown
# /deploy

## Arguments
- `environment`: Target environment (staging|production)
- `--skip-tests`: Skip test execution (optional)

## Implementation

1. Parse arguments:
   - Extract environment from first argument
   - Check for --skip-tests flag

2. Validate:
   - If environment not in [staging, production]: Error

3. Execute:
   - If --skip-tests not set: Run tests first
   - Deploy to specified environment
```

### 조건부 실행

```markdown
# /smart-commit

## Implementation

1. Check git status:
   - If no changes: "No changes to commit"
   - If unstaged changes: "Stage changes first"

2. Analyze changes:
   - Use AI to generate commit message
   - Categorize: feat|fix|docs|refactor|test

3. Create commit:
   - Use conventional commit format
   - Add emoji based on category
```

---

## 커맨드 vs 스킬

| 측면 | Commands | Skills |
|------|----------|--------|
| **활성화** | 명시적 (`/command`) | 자동 (키워드 매칭) |
| **용도** | 특정 작업 실행 | 컨텍스트 향상 |
| **정의** | `commands/*.md` | `skills/*/SKILL.md` |
| **예시** | `/code-review`, `/deploy` | React 컴포넌트 생성 가이드 |

---

## 관련 문서

- [Commands README](../../../commands/README.md)
- [Command Template](../../../templates/commands/command.md.template)
- [Agents Orchestration](../agents/multi-agent-orchestration.md)

---

## 변경 이력

- **2025-11-28**: code-review 기반 커맨드 패턴 정리
