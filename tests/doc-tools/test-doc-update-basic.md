# Test: doc-update 기본 기능 검증

## 목적

`/doc-update` 커맨드와 `doc-updater` 에이전트의 기본 동작을 검증합니다.

---

## Test Case 1: 전체 문서 검사

**실행**:
```bash
/doc-update
```

**기대 결과**:
- ✓ 모든 Markdown 파일 스캔 완료
- ✓ 4가지 원칙 기반 불일치 탐지
- ✓ 결과 리포트 출력 (요약 + 불일치 항목)

**검증 항목**:
1. TodoWrite로 진행상황 표시
2. doc-updater 에이전트 호출 (haiku 모델)
3. 불일치 항목이 카테고리별로 정렬됨

---

## Test Case 2: 특정 파일 검사

**실행**:
```bash
/doc-update --scope=specific --path=README.md
```

**기대 결과**:
- ✓ README.md만 검사
- ✓ 결과 리포트에 README.md 관련 항목만 표시

**검증 항목**:
1. scope="specific" 파라미터 정상 파싱
2. path 검증 (파일 존재 확인)
3. 1개 파일만 에이전트에 전달

---

## Test Case 3: 자동 수정

**실행**:
```bash
/doc-update --scope=specific --path=docs/example.md --auto-fix
```

**기대 결과**:
- ✓ 불일치 탐지
- ✓ 자동 수정 가능 항목 수정 완료
- ✓ git diff로 변경사항 확인 가능

**검증 항목**:
1. auto_fix=true 파라미터 전달
2. Edit 도구 사용 (에이전트)
3. 수정 완료 항목 표시 (fixed=true)

---

## Test Case 4: 에러 처리 - path 미존재

**실행**:
```bash
/doc-update --scope=specific --path=nonexistent.md
```

**기대 결과**:
- ✗ 에러 메시지: "파일/디렉토리를 찾을 수 없습니다: nonexistent.md"
- ✓ 프로세스 종료

**검증 항목**:
1. Glob 도구로 존재 확인
2. 에러 조기 반환

---

## Test Case 5: 에러 처리 - scope=specific + path 없음

**실행**:
```bash
/doc-update --scope=specific
```

**기대 결과**:
- ✗ 에러 메시지: "--scope=specific일 때 --path 파라미터 필수입니다."
- ✓ 프로세스 종료

**검증 항목**:
1. 입력 검증 로직
2. 에러 메시지 명확성

---

## Test Case 6: 불일치 0개

**실행**:
```bash
/doc-update --scope=specific --path=tests/doc-tools/fixtures/perfect-doc.md
```

*전제: perfect-doc.md는 불일치가 없는 완벽한 문서 (fixtures/에 생성됨)*

**기대 결과**:
- ✓ 메시지: "✓ 모든 문서가 최신 상태입니다."
- ✓ issues=[] 반환

**검증 항목**:
1. 불일치 탐지 로직 정상 동작
2. Edge Case 처리

---

## Test Case 7: 4가지 원칙 검증

**실행**:
```bash
/doc-update --scope=specific --path=tests/doc-tools/fixtures/test-all-rules.md
```

*전제: test-all-rules.md에는 4가지 원칙 위반 사항이 모두 포함됨 (fixtures/에 생성됨)*

**기대 결과**:
- ✓ 교차 검증 불일치 탐지 (예: 삭제된 파일 참조)
- ✓ 추적가능성 불일치 탐지 (예: 파일:라인 번호 누락)
- ✓ 사용자 중심 불일치 탐지 (예: 경고 섹션 누락)
- ✓ 완성도 불일치 탐지 (예: TODO 주석)

**검증 항목**:
1. 각 카테고리별 최소 1개 이상 탐지
2. 우선순위 순서대로 정렬 (cross-validation → traceability → user-centric → completeness)

---

## 실행 가이드

### 사전 준비

1. 테스트 문서는 이미 생성되어 있습니다:
   - `tests/doc-tools/fixtures/perfect-doc.md` (불일치 없음)
   - `tests/doc-tools/fixtures/test-all-rules.md` (4가지 원칙 위반 포함)

2. 플러그인 활성화:
```bash
claude --reload-plugins
```

### 실행 순서

```bash
# 1. 기본 기능
/doc-update

# 2. 특정 파일
/doc-update --scope=specific --path=README.md

# 3. 자동 수정
/doc-update --scope=specific --path=docs/example.md --auto-fix

# 4-5. 에러 처리
/doc-update --scope=specific --path=nonexistent.md
/doc-update --scope=specific

# 6. 불일치 0개
/doc-update --scope=specific --path=tests/doc-tools/fixtures/perfect-doc.md

# 7. 4가지 원칙
/doc-update --scope=specific --path=tests/doc-tools/fixtures/test-all-rules.md
```

---

## 성공 기준

- [ ] Test Case 1-7 모두 통과
- [ ] 에러 메시지 명확성 확인
- [ ] haiku 모델 사용 확인
- [ ] 결과 리포트 형식 검증

---

## 변경 이력

- **2025-11-30**: 초기 작성 (7개 테스트 케이스)
