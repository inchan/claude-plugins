# Workflow Examples

## Example 1: Simple - 버그 수정

```
사용자: "로그인 버튼 클릭 시 에러 수정"

→ Workflow Manager: Simple 패턴 선택
→ Router: bug_fix, complexity 0.45 → Sequential
→ Sequential: 5단계 처리
→ Evaluator: 품질 통과
→ 완료 (45분)
```

## Example 2: Parallel - 테스트 실행

```
사용자: "전체 테스트 스위트 병렬 실행"

→ Workflow Manager: Parallel 패턴 선택
→ Router: 병렬 가능 판단 → Parallel
→ Parallel: 4개 워커 병렬 실행 (Unit, Integration, E2E, Performance)
→ Evaluator: 결과 집계 (3.5x speedup)
→ 완료 (20분)
```

## Example 3: Complex - 전체 스택 앱

```
사용자: "Todo 앱 전체 스택 개발 (React + Express + PostgreSQL)"

→ Workflow Manager: Complex 패턴 선택
→ Router: complexity 0.85 → Orchestrator
→ Orchestrator: 프로젝트 분해
   ├ System Architect: 설계
   ├ Frontend Developer: React 구현
   ├ Backend Developer: Express 구현
   ├ DB Developer: PostgreSQL 설정
   ├ Test Engineer: 테스트
   └ Documentation Writer: 문서
→ Evaluator: 프로젝트 레벨 평가
→ 완료 (2시간)
```
