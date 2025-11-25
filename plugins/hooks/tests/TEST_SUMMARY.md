# Test Scripts Summary

## 생성된 7개 테스트 스크립트

### 1. test-plugin-discovery.sh
**목적**: 플러그인 및 스킬 탐색 기능 테스트

**주요 테스트**:
- `discover_installed_plugins` 함수 테스트
- `discover_plugin_skills` 함수 테스트
- SKILL.md 파일 탐지
- 출력 형식 검증 (plugin|skill|path)
- 빈 디렉토리 처리
- 성능 측정 (<1000ms)

**테스트 수**: 7개

---

### 2. test-metadata-parser.sh
**목적**: 메타데이터 파싱 기능 테스트

**주요 테스트**:
- YAML frontmatter 파싱
- skill-rules.json 파싱
- 메타데이터 집계 (pipe-separated 출력)
- 누락된 frontmatter 처리
- 잘못된 JSON 처리
- 키워드 추출
- 출력 형식 검증
- 성능 측정 (<10ms per parse)

**테스트 수**: 8개

---

### 3. test-cache-manager.sh
**목적**: 캐시 관리 기능 테스트

**주요 테스트**:
- 캐시 디렉토리 초기화
- 캐시 쓰기/읽기
- 캐시 유효성 검증 (fresh/stale)
- 파일 변경 감지
- 캐시 업데이트
- 다중 소스 파일 검증
- 캐시 만료 (age-based)
- 누락된 캐시 파일 처리
- 동시 접근
- 성능 측정 (<5ms per operation)

**테스트 수**: 11개

---

### 4. test-synonym-expansion.sh
**목적**: 동의어 확장 및 매칭 테스트

**주요 테스트**:
- synonyms.json 로드
- 파일 존재 확인
- JSON 구조 검증
- 카테고리 수 확인
- 키워드 확장
- 알 수 없는 키워드 처리
- 성능 측정 (<20ms per expansion)

**테스트 수**: 7개

---

### 5. test-tfidf-matching.sh
**목적**: TF-IDF 기반 스킬 매칭 테스트

**주요 테스트**:
- tfidf-matcher.js 존재 확인
- Node.js 가용성 확인
- 기본 TF-IDF 매칭
- 점수 계산
- 랭킹 순서
- 빈 프롬프트 처리
- 매칭 없는 경우
- 다중 키워드 중복
- JSON 출력 형식
- 성능 측정 (<100ms)

**테스트 수**: 10개

---

### 6. test-semantic-matching.sh
**목적**: 임베딩 기반 의미론적 매칭 테스트

**주요 테스트**:
- semantic-matcher.py 존재 확인
- Python 가용성 확인
- Python 의존성 확인 (sentence-transformers)
- 기본 의미론적 매칭
- 한글 프롬프트 지원
- 유사도 점수 계산
- 빈 프롬프트 처리
- JSON 출력 형식
- 모델 캐싱
- 성능 측정 (<350ms after model load)

**테스트 수**: 10개

---

### 7. benchmark-performance.sh
**목적**: 종합 성능 벤치마킹

**주요 벤치마크**:
- Tier 1 (Exact): 정확한 키워드 매칭
- Tier 2 (TF-IDF): 통계적 매칭
- Tier 3 (Semantic): 임베딩 유사도
- End-to-end: 전체 탐색 워크플로우
- Cache Operations: 읽기/쓰기 성능
- Metadata Parsing: YAML + JSON 파싱

**테스트 스케일**:
- 10 스킬, 50 스킬, 100 스킬

**성능 목표**:
- Tier 1: <10ms
- Tier 2: <100ms
- Tier 3: <350ms
- End-to-end: <200ms

**테스트 수**: 6개 벤치마크

---

## 전체 통계

| 메트릭 | 값 |
|--------|------|
| 총 테스트 스크립트 | 7개 |
| 총 테스트 케이스 | 59개 |
| 평균 테스트 수/스크립트 | 8.4개 |
| 예상 실행 시간 | 5-10분 (전체) |

## 테스트 실행 방법

### 개별 테스트
```bash
cd /Users/chans/workspace/pilot/cc-skills/plugins/hooks/tests
./test-plugin-discovery.sh
./test-metadata-parser.sh
./test-cache-manager.sh
./test-synonym-expansion.sh
./test-tfidf-matching.sh
./test-semantic-matching.sh
./benchmark-performance.sh
```

### 전체 테스트
```bash
./run-all-tests.sh
```

## 의존성

### 필수
- bash
- jq (JSON 파싱)

### 선택적
- Node.js v14+ (TF-IDF 테스트)
- Python 3.8+ (Semantic 테스트)
- sentence-transformers (Semantic 테스트)

## 로그

모든 테스트는 `/tmp/hook-tests.log`에 로그를 기록합니다.

## 성공 기준

- 모든 테스트 PASS
- 성능 목표 충족
- Exit code 0

## 주요 특징

1. **포괄적 커버리지**: 플러그인 탐색부터 의미론적 매칭까지 전 영역 테스트
2. **성능 검증**: 각 컴포넌트의 성능 목표 설정 및 측정
3. **에러 처리**: 누락/잘못된 데이터 처리 테스트
4. **확장성 테스트**: 10/50/100 스킬 규모 테스트
5. **다국어 지원**: 한글/영어 키워드 테스트
6. **캐시 검증**: 캐시 유효성 및 업데이트 로직 테스트
7. **출력 형식 검증**: JSON 및 pipe-separated 출력 형식 확인

## 문서

상세 내용은 `README.md` 참조.
