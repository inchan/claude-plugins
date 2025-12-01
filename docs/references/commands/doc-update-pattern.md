# doc-update 커맨드 패턴

> 문서-코드 불일치 자동 탐지 및 수정

---

## 개요

`/doc-update` 커맨드는 프로젝트의 모든 마크다운 문서를 스캔하여 코드와의 불일치를 탐지하고 자동 수정하는 도구입니다.

- **모델**: haiku (비용 절감)
- **에이전트**: doc-updater (doc-tools 플러그인)
- **범위**: 전체 문서 또는 특정 디렉토리/파일

---

## 사용법

### 기본 사용

```bash
# 전체 문서 검사
/doc-update

# 특정 디렉토리만 검사
/doc-update --scope=specific --path=docs/

# 특정 파일 검사 + 자동 수정
/doc-update --scope=specific --path=README.md --auto-fix
```

### 파라미터

| 파라미터 | 값 | 기본값 | 설명 |
|---------|-----|--------|------|
| `scope` | `all` \| `specific` | `all` | 검사 범위 |
| `path` | 문서 경로 | - | scope=specific일 때 필수 |
| `auto-fix` | 플래그 | false | 자동 수정 여부 |

---

## 검증 원칙 (4가지)

### 1. 교차 검증 (Cross-Validation) - 최우선

**목표**: 문서가 정확한 코드 참조를 포함하는지 확인

**확인 항목**:
- 파일:라인 번호 형식 (`file.ts:123`)
- 실제 파일/라인 존재 여부
- 함수/클래스명 정확성

**예시**:
```markdown
❌ 잘못됨: "src/utils.ts에서 calculateTotal 함수"
✓올바름: "calculateTotal 함수 (src/utils.ts:42)"
```

### 2. 추적가능성 (Traceability)

**목표**: 문서가 코드 변경 사항을 추적 가능하도록 작성

**확인 항목**:
- API 변경사항 기록
- 디렉토리 경로 명시
- 함수 시그니처 정확성

**예시**:
```markdown
❌ 잘못됨: "새로운 기능 추가"
✓올바름: "새로운 validateUser 함수 추가 (src/auth.ts:78)"
```

### 3. 사용자 중심 (User-Centric)

**목표**: 사용자가 문서만으로 기능을 이해하고 사용 가능

**확인 항목**:
- 실제 사용 예시
- 필수 입력 파라미터 설명
- 오류 처리 방법

**예시**:
```markdown
❌ 잘못됨: "API 엔드포인트: /api/users"
✓올바름: "API 엔드포인트: /api/users/{id} (GET)\n예시: curl http://localhost:3000/api/users/123"
```

### 4. 완성도 (Completeness)

**목표**: 필수 문서 요소가 모두 포함

**확인 항목**:
- 변경 이력 기록
- 예시 코드 포함
- 에러 케이스 설명

**예시**:
```markdown
❌ 잘못됨: "변경 이력 없음"
✓올바름: "## 변경 이력\n- **2025-12-01**: 초기 작성"
```

---

## 구현 아키텍처

### 실행 흐름

```
/doc-update
    ↓
파라미터 파싱 및 검증
    ↓
문서 범위 결정
    ├─ scope=all → Glob(**/*.md)
    └─ scope=specific → Glob(path/**/*.md)
    ↓
doc-updater 에이전트 호출
    ├─ Task(subagent_type: doc-tools:doc-updater)
    └─ model: haiku
    ↓
불일치 탐지 및 수정
    ├─ Cross-validation 검사
    ├─ Traceability 검사
    ├─ User-centric 검사
    └─ Completeness 검사
    ↓
결과 리포트 생성
    ├─ 요약 (총 파일, 불일치, 수정)
    ├─ 카테고리별 상세 이슈
    └─ 다음 단계 가이드
```

### 제외 대상

다음 파일/디렉토리는 자동으로 제외:
- `node_modules/`
- `.git/`
- `.claude/`
- `CHANGELOG.md`
- `LICENSE.md`

---

## 실행 결과 예시

### 성공 (불일치 없음)

```markdown
## 문서 업데이트 결과

### 검사 요약
- 총 문서: 45개
- 불일치 발견: 0개
- 수정 완료: 0개

✓ 모든 문서가 최신 상태입니다.
```

### 성공 (불일치 탐지 및 수정)

```markdown
## 문서 업데이트 결과

### 검사 요약
- 총 문서: 45개
- 불일치 발견: 3개
- 수정 완료: 2개

### 불일치 항목

#### 1. 교차 검증 (Cross-Validation) - 최우선
- **docs/examples.md:23**
  - 문제: 참조 파일:라인 번호 누락
  - 제안: src/api.ts:56 추가 권장
  - 상태: ✓ 자동 수정 완료

#### 2. 추적가능성 (Traceability)
- **README.md:42**
  - 문제: 변경 이력 누락
  - 제안: 변경 이력 섹션 추가 권장
  - 상태: ⚠️ 수동 검토 필요

### 다음 단계
git diff로 변경사항을 확인한 후 커밋하세요.
```

---

## 주의사항

### --auto-fix 사용 시

⚠️ **자동 수정은 신중하게 사용하세요:**
1. `--auto-fix` 없이 먼저 검사
2. 결과 검토
3. `git diff` 확인
4. 그 다음 `--auto-fix` 적용

### 대량 수정

- 한 번에 10개 파일 이상 수정할 경우 배치 처리 권장
- `--path` 파라미터로 범위 제한

### 모델 선택

- haiku: 빠르고 저렴 (기본값)
- 복잡한 검증이 필요한 경우 상위 모델 사용 권장

---

## 관련 문서

- [doc-updater 에이전트](../../agents/doc-updater-agent-pattern.md)
- [문서 작성 가이드](../../guidelines/documentation.md)
- [commands/doc-update.md](../../../commands/doc-update.md) - 구현 명세

---

## 변경 이력

- **2025-12-01**: 초기 작성
  - 4가지 검증 원칙 설명
  - 사용법 및 예시
  - 아키텍처 다이어그램
