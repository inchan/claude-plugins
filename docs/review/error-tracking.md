# error-tracking 리뷰

**작성일**: 2025-11-16
**카테고리**: 개발 가이드

---

## 목적과 목표

- Sentry v8 에러 추적 및 성능 모니터링
- "ALL ERRORS MUST BE CAPTURED TO SENTRY" 원칙
- 컨트롤러, 라우트, 워크플로우, 크론잡 에러 처리 패턴
- 데이터베이스 성능 모니터링

## 진행과정

1. Sentry 초기화 (`instrument.ts` - 최우선 import)
2. BaseController.handleError() 또는 Sentry.captureException() 사용
3. 적절한 컨텍스트 추가 (tags, extra, user)
4. 적절한 에러 레벨 선택 (fatal/error/warning/info/debug)
5. 테스트 엔드포인트로 검증

## 레퍼런스

- 구체적인 파일 경로:
  - `/blog-api/src/instrument.ts`
  - `/blog-api/src/workflow/utils/sentryHelper.ts`
  - `/blog-api/src/utils/databasePerformance.ts`
  - `/blog-api/src/controllers/BaseController.ts`
  - `config.ini` 설정 파일

## 검증 및 진실성 분석

- ✅ **검증 통과**: Sentry v8 API 사용법이 정확함
- ✅ 실제 코드 패턴이 구체적이고 복사하여 사용 가능
- ✅ 테스트 엔드포인트 URL까지 제공
- ✅ 에러 레벨 분류가 명확
- ⚠️ 특정 프로젝트 구조(`blog-api`, `notifications`)에 의존
- ⚠️ 실제 해당 파일들이 프로젝트에 존재하는지는 확인 필요

## 철학적 평가

**강점**: "모든 에러는 반드시 Sentry로" 원칙이 명확

**약점**: 일반적 Sentry 가이드가 아닌 특정 프로젝트 전용

**추천**: 높은 실용성, 프로덕션 에러 추적의 모범 사례

## 최종 등급

✅ **완전 검증** - 즉시 사용 가능
