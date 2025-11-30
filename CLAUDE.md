# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## 프로젝트 개요

**cc-plugins**는 Claude Code 확장 기능(Skills, Hooks, Agents, Commands)을 개발하고 플러그인으로 배포하는 프로젝트입니다.

프로젝트 상세 소개는 **[README.md](./README.md)** 참고

---

## 빠른 시작

개발을 시작하려면:
1. [docs/references/](docs/references/) - 질문별 빠른 검색 및 레퍼런스
2. [docs/guidelines/](docs/guidelines/) - 개발 가이드라인
3. [docs/workflows.md](docs/workflows.md) - 작업 흐름

---

## 개발 시 필수 확인 사항

### 1. 핵심 가이드라인 (우선순위 순)

1. **[개발 가이드라인](docs/guidelines/development.md)** - 코드 구현 원칙 (P1-P4 우선순위)
2. **[문서 작성 가이드](docs/guidelines/documentation.md)** - 문서 중복 최소화 원칙
3. **[도구 생성 가이드](docs/guidelines/tool-creation.md)** - Skills/Hooks/Agents/Commands 생성

### 2. 프로젝트 문서

- **[instruction.md](docs/instruction.md)** - 원본 지시사항 (최우선 기준)
- **[requirements.md](docs/requirements.md)** - 프로젝트 요구사항
- **[workflows.md](docs/workflows.md)** - 작업 흐름

### 3. 참고 자료

- **[레퍼런스 문서](docs/references/)** - Hooks/Agents/Commands/Plugins 패턴
- **[템플릿](templates/)** - 컴포넌트 템플릿

---

## 개발 원칙 (요약)

### 핵심 지침
- 모든 응답은 확인된 사실과 검증 가능한 근거에 기반
- 추정, 추측, 불확실한 정보 생성 금지
- 사실 관계가 모호한 경우 사용자에게 질문
- 작업 전 과제를 한 문장으로 재확인

### 문서 작성 시
- **중복 금지**: 동일 정보가 2곳 이상 존재 시 참조 사용
- **80% 룰**: 문서 내용 겹침 80% 초과 시 통합 필수
- **변경 이력**: 모든 문서 수정 시 변경 이력 기록

### 코드 작성 시
- **P1 - Validation First**: 성공 기준(Input/Output/Edge Cases) 먼저 정의
- **P2 - KISS/YAGNI**: 단순성 유지, 미래 대비 금지
- **P3 - DRY**: 3번 반복 시 중복 제거
- **P4 - SOLID**: 복잡도 임계치 초과 시에만 적용

**정량적 제약**:
- 함수 길이: 40줄 미만
- 조건문 깊이: 3단계 미만
- 공통 함수 매개변수: 5개 이하

---

## 워크플로우

상세 워크플로우는 **[workflows.md](docs/workflows.md)** 참고

---

## 자주 사용하는 명령어

```bash
# 테스트
npm test
npm run test:skills
npm run test:hooks

# 검증
npm run validate

# 빌드
npm run build
```

---

## 체크리스트

### 개발 시작 전
- [ ] instruction.md 확인
- [ ] requirements.md 해당 섹션 읽음
- [ ] 관련 가이드라인 읽음
- [ ] 공식 문서 확인

### 개발 완료 전
- [ ] 테스트 커버리지 80% 이상
- [ ] 문서화 완료
- [ ] 변경 이력 기록
- [ ] 자기비판리뷰 수행
- [ ] requirements.md 체크리스트 검증

---

## 참고: 프로젝트 구조

```
cc-plugins/
├── agents/                # 서브에이전트 (TDD 개발 팀 5개)
│   └── tdd/              # task-planner, test-writer, implementer, refactorer, reviewer
├── commands/              # 슬래시 커맨드 (tdd-team)
├── skills/                # 확장 스킬
├── hooks/                 # 이벤트 훅
├── rules/                 # 활성화 규칙
├── templates/             # 컴포넌트 템플릿
├── docs/                  # 프로젝트 문서
│   ├── guidelines/        # 개발 가이드라인 (필수)
│   └── references/        # 레퍼런스 패턴
└── .claude-plugin/        # 플러그인 메타데이터 (marketplace.json)
```

각 디렉토리 상세 구조는 해당 디렉토리의 README.md 참고

---

## 중요 알림

⚠️ **이 문서는 Claude Code 에이전트용 지시사항입니다.**

사용자용 문서는 다음을 참고하세요:
- 프로젝트 소개: [README.md](./README.md)
- 개발 레퍼런스: [docs/references/](docs/references/)

⚠️ **문서 중복 최소화**: 이 문서는 참조 중심으로 작성되었습니다.
상세 내용은 각 링크된 문서를 확인하세요.

---

## 변경 이력

- **2025-11-29**: 프로젝트 구조 최신화 (TDD 개발 팀 5개 에이전트 반영)
- **2025-11-29**: 워크플로우 섹션 간소화 - workflows.md 참조로 변환
- **2025-11-28**: QUICK_START.md 참조 제거 (파일 삭제됨)
- **2025-11-28**: CLAUDE.md 대폭 간소화 - 참조 중심으로 리팩토링, 중복 제거 (60% → 5%)
- **2025-11-28**: documentation.md 가이드라인 추가
- **2025-11-28**: 초기 작성
