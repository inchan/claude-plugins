# frontend-dev-guidelines 리뷰

**작성일**: 2025-11-16
**카테고리**: 개발 가이드

---

## 목적과 목표

- React/TypeScript/MUI v7 기반 프론트엔드 개발 가이드
- Suspense, lazy loading, useSuspenseQuery 패턴
- TanStack Router/Query 사용법
- 성능 최적화 및 파일 구조화

## 진행과정

1. 체크리스트 기반 컴포넌트/기능 생성
2. import alias 활용 (`@/`, `~types`, `~components`, `~features`)
3. 데이터 페칭 → 스타일링 → 라우팅 → 상태 관리
4. 성능 최적화 (useMemo, useCallback, React.memo)
5. 로딩/에러 상태 처리

## 레퍼런스

- 11개 상세 리소스 파일:
  - `resources/component-patterns.md`
  - `resources/data-fetching.md`
  - `resources/file-organization.md`
  - `resources/styling-guide.md`
  - `resources/routing-guide.md`
  - `resources/performance.md`
  - `resources/typescript-standards.md`
  - `resources/common-patterns.md`
  - `resources/complete-examples.md`
  - 등

## 검증 및 진실성 분석

- ✅ **검증 통과**: 모든 리소스 파일이 실제로 존재함
- ✅ 구체적인 코드 예제와 패턴 제공
- ✅ 실제 프로젝트에서 사용 가능한 실용적 가이드
- ✅ MUI v7 Grid 문법 (`size` prop) 정확히 설명
- ✅ 500라인 이하 규칙 준수
- ⚠️ `vite.config.ts` 라인 180-185 참조는 특정 프로젝트에만 적용됨

## 철학적 평가

**강점**: 실용적이고 구체적인 가이드라인

**약점**: 특정 프로젝트(React + TanStack + MUI)에 특화됨

**추천**: 가장 완성도 높은 스킬 중 하나

## 최종 등급

✅ **완전 검증** - 즉시 사용 가능
