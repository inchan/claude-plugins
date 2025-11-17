# Parallel Workflow Pattern

**Router → Parallel → Evaluator**

## 적용 조건
- 독립적인 작업들
- 테스트 스위트, 다중 컴포넌트
- Sectioning 또는 Voting 모드

## 실행 흐름

### 1. Router Analysis
- 병렬 가능 여부 판단
- 모드 선택 (sectioning/voting)

### 2. Parallel Execution
- N개 워커 동시 실행
- Wave 단위 sync
- 결과 집계

### 3. Evaluator Aggregation
- 병합 검증
- 통합 평가

## 예상 Speedup
2-5x
