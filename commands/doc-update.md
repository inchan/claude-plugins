---
description: 문서 업데이트 자동화 - 추적가능성/교차검증/사용자중심/완성도 검증
allowed-tools: Task, TodoWrite, Read, Grep, Glob, AskUserQuestion
argument-hint: [--scope=all|specific] [--path=docs/] [--auto-fix]
---

# Document Update

문서-코드 불일치를 탐지하고 수정하는 자동화 도구입니다.

## 사용법

```bash
# 전체 문서 검사
/doc-update

# 특정 디렉토리만 검사
/doc-update --scope=specific --path=docs/

# 특정 파일 검사 + 자동 수정
/doc-update --scope=specific --path=README.md --auto-fix
```

---

## Implementation

### 1. 입력 파싱 및 검증

**1.1 인자 파싱**

`$ARGUMENTS`에서 다음 파라미터 추출:
- `scope`: "all" (기본값) | "specific"
- `path`: 문서 경로 (scope="specific"일 때 필수)
- `auto-fix`: 자동 수정 여부 (기본값: false)

**파싱 알고리즘**:
```
scope = "all"
path = null
autoFix = false

FOR EACH arg IN $ARGUMENTS.split(" "):
  IF arg.startsWith("--scope="):
    scope = arg.split("=")[1]
  ELSE IF arg.startsWith("--path="):
    path = arg.split("=")[1]
  ELSE IF arg === "--auto-fix":
    autoFix = true
```

**1.2 검증 규칙**

```
IF scope NOT IN ["all", "specific"]:
    ERROR: "잘못된 scope 값입니다. (허용: all, specific)"

IF scope === "specific" AND path === null:
    ERROR: "--scope=specific일 때 --path 파라미터 필수입니다."

IF path !== null:
    IF NOT (파일 존재 OR 디렉토리 존재):
        ERROR: "파일/디렉토리를 찾을 수 없습니다: {path}"
```

**구현 방법**:
- 파일/디렉토리 존재 확인: Glob 도구 사용
  ```
  Glob(pattern=path)
  IF result.length === 0: ERROR
  ```

### 2. 문서 범위 결정

**2.1 검사 대상 파일 수집**

**IF scope === "all"**:
```
Glob(pattern="**/*.md")
→ 모든 Markdown 파일 반환
```

**ELSE IF scope === "specific"**:
```
IF path가 디렉토리:
    Glob(pattern="{path}/**/*.md")
ELSE IF path가 파일:
    [path]
```

**2.2 제외 대상**
- `node_modules/`, `.git/`, `.claude/` 하위 파일
- `CHANGELOG.md`, `LICENSE.md`

### 3. doc-updater 에이전트 호출

**3.1 Task 도구 호출**

```json
{
  "subagent_type": "doc-tools:doc-updater",
  "model": "haiku",
  "description": "문서 업데이트 검증",
  "prompt": "{
    \"files\": [\"file1.md\", \"file2.md\", ...],
    \"auto_fix\": <autoFix>,
    \"priorities\": [\"cross-validation\", \"traceability\", \"user-centric\", \"completeness\"]
  }"
}
```

**3.2 에이전트 응답 형식**

```json
{
  "summary": {
    "total_files": 10,
    "issues_found": 5,
    "fixes_applied": 3
  },
  "issues": [
    {
      "category": "traceability" | "cross-validation" | "user-centric" | "completeness",
      "file": "docs/example.md",
      "line": 42,
      "description": "파일:라인 번호 누락",
      "suggestion": "src/utils.ts:123 추가 권장",
      "fixed": true | false
    }
  ]
}
```

### 4. 결과 출력

**4.1 TodoWrite로 진행상황 표시**

```
TodoWrite([
  { content: "문서 스캔 완료", status: "completed" },
  { content: "불일치 탐지 완료", status: "completed" },
  { content: "수정 제안 생성", status: "in_progress" }
])
```

**4.2 이슈 정렬**

우선순위 순서대로 이슈를 정렬:
```
category_order = ["cross-validation", "traceability", "user-centric", "completeness"]

sorted_issues = issues.sort((a, b) => {
    // 1. 카테고리 우선순위
    IF category_order.indexOf(a.category) !== category_order.indexOf(b.category):
        RETURN category_order.indexOf(a.category) - category_order.indexOf(b.category)

    // 2. 파일명 알파벳 순
    IF a.file !== b.file:
        RETURN a.file.localeCompare(b.file)

    // 3. 라인 번호 순
    RETURN a.line - b.line
})
```

**4.3 최종 리포트**

```markdown
## 문서 업데이트 결과

### 검사 요약
- 총 문서: {total_files}개
- 불일치 발견: {issues_found}개
- 수정 완료: {fixes_applied}개
- 실패한 파일: {failed_files}개

{IF failed_files > 0:}
### ⚠️ 처리 실패한 파일

FOR EACH failed IN failed_files_list:
  - **{failed.file}**: {failed.error}

{END IF}

### 불일치 항목

#### 1. 교차 검증 (Cross-Validation) - 최우선

FOR EACH issue IN issues WHERE category="cross-validation":
  - **{issue.file}:{issue.line}**
    - 문제: {issue.description}
    - 제안: {issue.suggestion}
    - 상태: {issue.fixed ? "✓ 자동 수정 완료" : "⚠️ 수동 검토 필요"}

#### 2. 추적가능성 (Traceability)

FOR EACH issue IN issues WHERE category="traceability":
  - **{issue.file}:{issue.line}**
    - 문제: {issue.description}
    - 제안: {issue.suggestion}
    - 상태: {issue.fixed ? "✓ 자동 수정 완료" : "⚠️ 수동 검토 필요"}

#### 3. 사용자 중심 (User-Centric)

FOR EACH issue IN issues WHERE category="user-centric":
  - **{issue.file}:{issue.line}**
    - 문제: {issue.description}
    - 제안: {issue.suggestion}
    - 상태: {issue.fixed ? "✓ 자동 수정 완료" : "⚠️ 수동 검토 필요"}

#### 4. 완성도 (Completeness)

FOR EACH issue IN issues WHERE category="completeness":
  - **{issue.file}:{issue.line}**
    - 문제: {issue.description}
    - 제안: {issue.suggestion}
    - 상태: {issue.fixed ? "✓ 자동 수정 완료" : "⚠️ 수동 검토 필요"}

### 다음 단계

{IF autoFix === false:}
**수동 수정 필요**:
각 항목의 suggestion을 참고하여 수정하세요.

{IF autoFix === true AND fixes_applied > 0:}
**자동 수정 완료**:
git diff로 변경사항을 확인하세요.

**권장 명령어**:
```bash
git diff
git add .
git commit -m "docs: 문서 업데이트 (불일치 {fixes_applied}개 수정)"
```
```

### 5. 에러 처리

| 상황 | 처리 |
|------|------|
| 문서 0개 | "검사할 문서가 없습니다." 메시지 출력 후 종료 |
| path 미존재 | 에러 메시지 출력 후 종료 |
| 에이전트 실패 | 에러 로그 출력 + 재시도 제안 |
| 불일치 0개 | "✓ 모든 문서가 최신 상태입니다." 메시지 |

---

## 주의사항

- `--auto-fix`는 신중하게 사용 (변경사항 리뷰 필수)
- 대량 수정 시 배치 처리 (10개 단위)
- 에이전트는 haiku 모델로 비용 절감

---

## 성공 기준 (P1: Validation First)

### Input Validation

```typescript
interface DocUpdateInput {
  scope: "all" | "specific";
  path?: string;
  autoFix?: boolean;
}
```

### Output Format

```markdown
## 문서 업데이트 결과
{요약 + 불일치 항목 + 다음 단계}
```

### Edge Cases

- scope="specific" + path 없음 → 에러
- path 미존재 → 에러
- 문서 0개 → 메시지 출력
- 불일치 0개 → 성공 메시지

---

## 변경 이력

- **2025-11-30**: 초기 생성
  - 추적가능성/교차검증/사용자중심/완성도 검증
  - doc-updater 에이전트 연동
  - haiku 모델 사용으로 비용 절감
