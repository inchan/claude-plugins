# doc-updater 에이전트 패턴

> 문서-코드 불일치를 자동으로 탐지하고 수정하는 전문 에이전트

---

## 개요

`doc-updater` 에이전트는 프로젝트의 모든 마크다운 문서를 분석하여 코드와의 불일치를 찾아내고 자동으로 수정하는 전문 에이전트입니다.

- **모델**: haiku (비용 절감, 빠른 응답)
- **역할**: 문서-코드 불일치 탐지 및 수정
- **도구**: Read, Grep, Glob, Edit, Write
- **호출**: `/doc-update` 커맨드를 통해 호출

---

## 에이전트 아키텍처

### 입력 데이터 구조

```json
{
  "files": ["file1.md", "file2.md", ...],
  "auto_fix": true | false,
  "priorities": ["cross-validation", "traceability", "user-centric", "completeness"]
}
```

### 출력 데이터 구조

```json
{
  "summary": {
    "total_files": 10,
    "issues_found": 5,
    "fixes_applied": 3,
    "failed_files": 0
  },
  "issues": [
    {
      "category": "traceability",
      "file": "docs/example.md",
      "line": 42,
      "description": "파일:라인 번호 누락",
      "matched_text": "calculateTotal 함수",
      "suggestion": "src/utils.ts:123",
      "auto_fixable": true,
      "fixed": true
    }
  ]
}
```

---

## 4가지 검증 원칙

### 1. 교차 검증 (Cross-Validation) - 최우선

**목적**: 문서가 정확한 코드 참조를 포함하는지 검증

**검사 항목**:
1. **파일 존재 여부**
   - 문서에 언급된 모든 파일이 실제로 존재하는지 확인
   - 삭제된 파일 참조 탐지

2. **함수/클래스 존재 여부**
   - 문서에서 언급한 함수/클래스가 실제 코드에 존재하는지 확인
   - 이름 변경된 함수 탐지

3. **정보 중복 탐지**
   - 두 문서 간 80% 이상 유사도 감지
   - Jaccard Index 알고리즘 사용 (`|교집합| / |합집합|`)

**예시**:
```markdown
❌ 문제: "authenticate 함수 참조" (실제로는 auth 함수)
✓ 수정: "authenticate 함수" → "auth 함수 (src/auth.ts:78)"
```

### 2. 추적가능성 (Traceability)

**목적**: 요구사항 → 구현 → 테스트를 추적 가능하게 문서화

**검사 항목**:
1. **파일:라인 번호**
   - 함수/클래스 언급 시 위치 정보 필수
   - 형식: `{file}:{line}`

2. **API 시그니처**
   - 문서의 함수 시그니처가 최신 코드와 일치하는지 확인

3. **변경 이력**
   - 수정된 기능에 대한 변경 이력 기록 여부

**예시**:
```markdown
❌ 문제: "validateUser 함수로 사용자 검증"
✓ 수정: "validateUser 함수로 사용자 검증 (src/auth.ts:56)"
```

### 3. 사용자 중심 (User-Centric)

**목적**: 문서만으로 기능을 이해하고 사용 가능하도록 작성

**검사 항목**:
1. **경고 섹션**
   - CLI/API 도구: 중요 제약사항 명시
   - 누락 시 경고 섹션 템플릿 추가

2. **사용 예시**
   - 가이드/튜토리얼: 실행 가능한 코드 예제 필수
   - 누락 시 예시 추가 권장

3. **필수 정보**
   - 입력값, 반환값, 오류 처리 방법 포함

**예시**:
```markdown
❌ 문제: "API 엔드포인트: /api/users" (사용 방법 없음)
✓ 수정: "API 엔드포인트: /api/users/{id} (GET)\n예시: curl http://localhost:3000/api/users/123"
```

### 4. 완성도 (Completeness)

**목적**: 기본적인 완결성 확보

**검사 항목**:
1. **문서 길이**
   - 내용 부족한 문서 탐지 (50자 미만)

2. **TODO/FIXME**
   - 미완성 섹션 탐지
   - 그레프 패턴: `TODO|FIXME|XXX:`

3. **필수 섹션**
   - 변경 이력, 예제, 주의사항 등 포함 여부

**예시**:
```markdown
❌ 문제: "## 변경 이력\n- TODO: 변경 이력 추가"
✓ 수정: "## 변경 이력\n- **2025-12-01**: 초기 작성"
```

---

## 동작 흐름

```
doc-updater 에이전트 호출
    ↓
입력 검증
    ├─ files 배열 존재 확인
    ├─ Markdown 파일만 필터링
    └─ 유효한 파일 1개 이상 필수
    ↓
문서 스캔
    ├─ 각 파일 읽기 (Read 도구)
    ├─ 오류 발생 시 건너뛰기
    └─ failed_files에 기록
    ↓
불일치 탐지 (우선순위 순)
    ├─ 1. 교차 검증 (Cross-Validation)
    │   ├─ 파일 존재 여부
    │   ├─ 함수/클래스 존재 여부 (Grep)
    │   └─ 정보 중복 탐지 (유사도 > 80%)
    │
    ├─ 2. 추적가능성 (Traceability)
    │   ├─ 파일:라인 번호 누락 (Grep)
    │   └─ API 시그니처 불일치
    │
    ├─ 3. 사용자 중심 (User-Centric)
    │   ├─ 경고 섹션 누락 (CLI/API)
    │   └─ 사용 예시 누락 (가이드/튜토리얼)
    │
    └─ 4. 완성도 (Completeness)
        ├─ 빈 문서 탐지 (< 50자)
        ├─ TODO/FIXME 검사 (Grep)
        └─ 필수 섹션 확인
    ↓
자동 수정 (auto_fix=true인 경우)
    ├─ 수정 가능: 파일:라인 번호 추가, 템플릿 추가
    ├─ 수정 불가: 중복 통합, API 업데이트 (수동 필요)
    └─ 각 수정 기록 (fixed=true/false)
    ↓
결과 컴파일
    ├─ 요약 통계 생성
    ├─ 이슈 목록 정렬 (카테고리 → 파일명 → 라인)
    └─ 응답 반환
```

---

## 주요 알고리즘

### 유사도 계산 (Jaccard Index)

문서 간 중복 탐지에 사용되는 알고리즘:

```
유사도 = |공통 라인 수| / |전체 라인 수|

예:
파일A: 100줄 (10줄 공통)
파일B: 100줄

유사도 = 10 / 100 = 0.1 (10% - 중복 아님)

파일C: 50줄 (40줄 공통)
파일D: 50줄

유사도 = 40 / 50 = 0.8 (80% - 중복 탐지!)
```

---

## 사용 예시

### 기본 호출

```bash
# 전체 문서 검사 (자동 수정 안 함)
/doc-update

# 특정 디렉토리만 검사
/doc-update --scope=specific --path=docs/

# 자동 수정 적용
/doc-update --auto-fix
```

### 응답 예시

**성공 (불일치 없음):**
```json
{
  "summary": {
    "total_files": 45,
    "issues_found": 0,
    "fixes_applied": 0,
    "failed_files": 0
  },
  "issues": []
}
```

**성공 (불일치 탐지 및 수정):**
```json
{
  "summary": {
    "total_files": 45,
    "issues_found": 3,
    "fixes_applied": 2,
    "failed_files": 0
  },
  "issues": [
    {
      "category": "cross-validation",
      "file": "docs/api.md",
      "line": 23,
      "description": "삭제된 파일 참조",
      "matched_text": "src/old-auth.ts",
      "suggestion": "파일 참조 제거 또는 업데이트",
      "auto_fixable": false,
      "fixed": false
    },
    {
      "category": "traceability",
      "file": "README.md",
      "line": 42,
      "description": "파일:라인 번호 누락",
      "matched_text": "validate 함수",
      "suggestion": "src/validators.ts:78",
      "auto_fixable": true,
      "fixed": true
    }
  ]
}
```

---

## 에러 처리

| 상황 | 처리 방식 |
|------|---------|
| 파일 읽기 실패 | ⚠️ 경고 로그 + 파일 건너뛰기 |
| Grep/Glob 실패 | 해당 검사 건너뛰기 + 로그 |
| Edit 충돌 | fixed=false + 에러 메시지 기록 |
| 유효한 파일 0개 | ❌ 에러 반환 |

---

## 성공 기준

### Input Validation (P1)

```typescript
// 필수 입력
- files: string[] (1개 이상)

// 선택 입력 (기본값)
- auto_fix: boolean (기본값: false)
- priorities: string[] (기본값: 지정 순서)
```

### Output Format (P2)

```json
{
  "summary": { "total_files": number, "issues_found": number, "fixes_applied": number },
  "issues": Issue[],
  "failed_files": { file: string, error: string }[]
}
```

### Edge Cases

- `files=[]` → 에러
- 모든 파일 읽기 실패 → 에러
- `issues=[]` → summary만 반환
- `auto_fix=true` + 수정 불가 → fixed=false 기록

---

## 관련 문서

- [/doc-update 커맨드](../commands/doc-update-pattern.md)
- [문서 작성 가이드](../../guidelines/documentation.md)
- [agents/doc-tools/doc-updater.md](../../../agents/doc-tools/doc-updater.md) - 에이전트 프롬프트

---

## 변경 이력

- **2025-12-01**: 초기 작성
  - 4가지 검증 원칙 설명
  - 아키텍처 및 흐름도
  - 사용 예시 및 알고리즘
