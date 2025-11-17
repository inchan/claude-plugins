# Claude Code Skills & Hooks - 통합 관리 가이드

**최종 업데이트**: 2025-11-17
**버전**: 1.1.0

---

## 📋 목표 및 비전

### 핵심 목표
클로드 코드의 **스킬**과 **훅**을 상황에 맞게 효과적으로 활용하여 개발 생산성을 극대화합니다.

### 세부 목표
1. **스킬 자동 활성화**: 작업 내용에 따라 적절한 스킬이 자동으로 제안되도록
2. **워크플로우 최적화**: 복잡한 작업을 체계적인 워크플로우로 자동 처리
3. **품질 보증**: 코드 작성 후 자동 품질 검증 및 개선
4. **지속적 개선**: 사용 패턴 분석을 통한 지속적인 업그레이드

---

## 🔍 현재 상태 분석

### 스킬 현황 (총 22개)

#### 1. 워크플로우 관리 (7개)
- **agent-workflow-manager**: 전체 워크플로우 자동 관리 조율자
  - Router → Sequential/Parallel/Orchestrator → Evaluator 자동 연결
  - 3가지 패턴: Simple (복잡도 < 0.7), Parallel (독립 작업), Complex (복잡도 >= 0.7)

- **agent-workflow-advisor**: 워크플로우 패턴 추천 어드바이저
  - 작업 분석 및 최적 패턴 제안
  - 복잡도 기반 의사결정 지원

- **agent-workflow-orchestrator**: 고급 워크플로우 오케스트레이션
  - 다중 에이전트 조율
  - 복잡한 작업 흐름 관리

- **intelligent-task-router**: 작업 분류 및 최적 라우팅
  - 8개 카테고리 분류 (bug_fix, feature_development, refactoring, testing, documentation, performance, security, data_processing)
  - 복잡도/우선순위/의도 분석

- **parallel-task-executor**: 병렬 작업 실행 엔진
  - Sectioning 모드: 독립 작업 동시 실행 (2-10x 속도 향상)
  - Voting 모드: 다중 접근 방식 평가 및 최적안 선택

- **dynamic-task-orchestrator**: 복잡한 프로젝트 조율
  - 6개 전문 워커 (Code Analyzer, System Architect, Developer, Test Engineer, Documentation Writer, Performance Optimizer)
  - 복잡도 0.7+ 프로젝트에 최적화

- **sequential-task-processor**: 순차 작업 처리
  - 단계별 작업 실행
  - 의존성 관리

#### 2. 품질 관리 (1개)
- **iterative-quality-enhancer**: 품질 평가 및 최적화
  - 5개 차원 평가 (Functionality, Performance, Code Quality, Security, Documentation)
  - 최대 5회 반복 개선

#### 3. 개발 가이드 (3개)
- **frontend-dev-guidelines**: React/TypeScript/MUI v7 가이드
- **backend-dev-guidelines**: Node.js/Express/TypeScript/Prisma 가이드
- **error-tracking**: Sentry v8 에러 추적 패턴

#### 4. 도구 생성 (4개)
- **command-creator**: 슬래시 커맨드 생성 및 관리
- **hooks-creator**: 훅 생성 가이드
- **skill-creator**: 스킬 생성 가이드
- **subagent-creator**: 서브에이전트 생성 가이드

#### 5. AI 연동 (1개) ✅ 통합 완료
- **dual-ai-loop**: 통합 Dual-AI 엔지니어링 루프
  - 5개 CLI 지원 (codex ✅, qwen ✅, copilot, rovo-dev, aider)
  - codex와 qwen은 실제 테스트 검증됨
  - 역할 교체 가능 (구현자/리뷰어)
  - CLI 어댑터 모듈화 (skills/cli-adapters/)
  - cli-updater로 자동 버전 관리

#### 6. 프롬프트 도구 (2개)
- **meta-prompt-generator**: 구조화된 커스텀 슬래시 커맨드 생성
- **prompt-enhancer**: 프로젝트 컨텍스트 기반 프롬프트 개선

#### 7. 기타 도구 (4개)
- **skill-developer**: 스킬 개발 종합 가이드 (Anthropic 공식 표준 준수)
- **route-tester**: 인증 라우트 테스트
- **web-to-markdown**: 웹페이지 마크다운 변환
- **cli-updater**: CLI 도구 자동 버전 업데이트

### 훅 현황 (활성화 3개)

#### UserPromptSubmit 훅 (2개)
1. **skill-activation-prompt.ts**:
   - 사용자 프롬프트 분석 후 적합한 스킬 자동 제안
   - skill-rules.json 기반 키워드/인텐트 매칭
   - 우선순위별 스킬 추천 (Critical → High → Medium → Low)

2. **meta-prompt-logger.js**:
   - 프롬프트 로깅 및 분석
   - 사용 패턴 추적

#### PostToolUse 훅 (1개)
- **post-tool-use-tracker.sh**: Edit/Write 후 변경 사항 추적

#### Stop 훅 (1개)
- **stop-hook-lint-and-translate.sh**: 응답 완료 후 린트 및 번역

### Skill Rules 등록 현황

**등록된 스킬** (7개):
- skill-developer
- meta-prompt-generator
- backend-dev-guidelines
- frontend-dev-guidelines
- route-tester
- error-tracking

**미등록 스킬** (15개):
- agent-workflow-manager ⚠️
- agent-workflow-advisor ⚠️
- agent-workflow-orchestrator ⚠️
- intelligent-task-router ⚠️
- parallel-task-executor ⚠️
- dynamic-task-orchestrator ⚠️
- sequential-task-processor ⚠️
- iterative-quality-enhancer ⚠️
- command-creator
- hooks-creator
- skill-creator
- subagent-creator
- dual-ai-loop
- cli-updater
- prompt-enhancer

---

## 🎯 문제점 분석

### 1. 스킬 등록 불완전
- **핵심 워크플로우 스킬이 미등록**: agent-workflow-manager, router, parallel-executor, orchestrator, evaluator
- **자동 활성화 불가**: skill-rules.json에 없어서 UserPromptSubmit 훅이 감지 못함

### 2. 중복 및 정리 필요 ✅ 일부 완료
- **스킬 생성 중복**: skill-creator, skill-developer (유사 기능) - 검토 필요
- ~~**AI Loop 중복**: codex-claude-loop, qwen-claude-loop (동일 패턴)~~ ✅ **해결됨** - dual-ai-loop으로 통합
- **훅 중복**: skill-activation-prompt.ts, skill-activation-prompt-with-notification.ts

### 3. 워크플로우 연결 부족
- 개별 스킬은 강력하지만 자동 연결이 미흡
- 사용자가 수동으로 스킬 체인을 구성해야 함

### 4. 문서화 부족
- 각 스킬의 활용 예제가 제한적
- 스킬 간 연동 가이드 부족

---

## 🚀 개선 방향성

### Phase 1: 핵심 인프라 정비 (우선순위: 높음)

#### 1.1 핵심 워크플로우 스킬 등록
```json
// skill-rules.json에 추가 필요
{
  "agent-workflow-manager": {
    "type": "domain",
    "enforcement": "suggest",
    "priority": "critical",
    "promptTriggers": {
      "keywords": ["워크플로우", "자동화", "전체 프로세스", "workflow", "automation"],
      "intentPatterns": [
        "(전체|통합).*?(워크플로우|프로세스)",
        "(자동|auto).*?(workflow|처리)"
      ]
    }
  },
  "intelligent-task-router": {
    "type": "domain",
    "enforcement": "suggest",
    "priority": "critical",
    "promptTriggers": {
      "keywords": ["라우팅", "분류", "routing", "classify"],
      "intentPatterns": ["(분류|classify|route).*?작업"]
    }
  },
  "parallel-task-executor": {
    "type": "domain",
    "enforcement": "suggest",
    "priority": "high",
    "promptTriggers": {
      "keywords": ["병렬", "동시", "parallel", "concurrent"],
      "intentPatterns": ["(병렬|parallel|동시).*?(실행|처리)"]
    }
  },
  "dynamic-task-orchestrator": {
    "type": "domain",
    "enforcement": "suggest",
    "priority": "high",
    "promptTriggers": {
      "keywords": ["복잡한", "대규모", "전체 스택", "orchestrate", "complex"],
      "intentPatterns": [
        "(복잡한|complex).*?(프로젝트|시스템)",
        "(전체|full).*?(스택|stack)"
      ]
    }
  },
  "iterative-quality-enhancer": {
    "type": "domain",
    "enforcement": "suggest",
    "priority": "high",
    "promptTriggers": {
      "keywords": ["최적화", "품질", "개선", "optimize", "enhance", "quality"],
      "intentPatterns": [
        "(최적화|optimize|개선|enhance).*?(코드|성능|품질)",
        "(품질|quality).*?(검증|평가)"
      ]
    }
  }
}
```

#### 1.2 중복 제거 ✅ 부분 완료
- **통합**: skill-creator + skill-developer → skill-developer (하나로 통합) - 검토 필요
- ~~**선택**: codex-claude-loop vs qwen-claude-loop (주로 사용하는 것 1개만 유지)~~ ✅ **완료** - dual-ai-loop으로 통합됨 (2025-11-17)
- **훅 정리**: skill-activation-prompt.ts만 유지 (notification 버전 제거)

### Phase 2: 워크플로우 자동화 (우선순위: 높음)

#### 2.1 슬래시 커맨드 추가
```markdown
# .claude/commands/auto-workflow.md
---
description: 작업을 자동으로 분석하고 최적 워크플로우 실행
allowed-tools: Task
---

사용자 요청을 intelligent-task-router로 분석한 후,
복잡도에 따라 자동으로 적절한 워크플로우 실행:
- 복잡도 < 0.7: sequential-task-processor
- 병렬 가능: parallel-task-executor
- 복잡도 >= 0.7: dynamic-task-orchestrator

완료 후 iterative-quality-enhancer로 품질 검증
```

#### 2.2 통합 워크플로우 훅
```bash
# hooks/auto-workflow.sh
# Stop 훅: 응답 완료 후 자동으로 품질 검증 제안
```

### Phase 3: 문서화 및 가이드 (우선순위: 중간)

#### 3.1 통합 사용 가이드 작성
- **GETTING_STARTED.md**: 초보자용 빠른 시작 가이드
- **WORKFLOW_GUIDE.md**: 워크플로우별 사용법
- **EXAMPLES.md**: 실제 사용 예제 모음

#### 3.2 각 스킬 예제 강화
- 각 스킬 디렉토리에 `examples/` 추가
- 실제 프로젝트 적용 사례 문서화

### Phase 4: 성능 최적화 (우선순위: 낮음)

#### 4.1 훅 성능 개선
- skill-activation-prompt.ts 최적화 (불필요한 파일 읽기 제거)
- 캐싱 도입

#### 4.2 스킬 실행 최적화
- 모델 선택 최적화 (Haiku/Sonnet/Opus)
- 병렬 실행 극대화

---

## 📊 우선순위 로드맵

### 즉시 실행 (1-2일)
1. ✅ **현재 상태 분석** (완료)
2. 🔄 **핵심 스킬 등록**: agent-workflow-manager, router, parallel, orchestrator, evaluator
3. 🔄 **중복 제거**: 불필요한 스킬/훅 정리
4. 🔄 **통합 워크플로우 커맨드 생성**: /auto-workflow

### 단기 목표 (1주)
5. 📝 **GETTING_STARTED.md** 작성
6. 📝 **WORKFLOW_GUIDE.md** 작성
7. 🔧 **슬래시 커맨드 추가**: /simple-workflow, /parallel-workflow, /complex-workflow

### 중기 목표 (2-4주)
8. 📚 **각 스킬 예제 강화**
9. 🔧 **훅 성능 최적화**
10. 📊 **사용 패턴 분석 시스템 구축**

### 장기 목표 (1-3개월)
11. 🤖 **자동 학습**: 사용 패턴 기반 스킬 추천 개선
12. 🌐 **커뮤니티 공유**: 유용한 스킬/훅 공개
13. 🔄 **지속적 업데이트**: 새로운 패턴 및 도구 추가

---

## 🛠 실행 계획

### Step 1: skill-rules.json 업데이트
```bash
# 핵심 워크플로우 스킬 5개 등록
# command-creator, hooks-creator 등록
# 총 12개 스킬 추가 등록
```

### Step 2: 중복 제거 ✅ 완료 (2025-11-17)
```bash
# ✅ dual-ai-loop으로 통합 완료
# ✅ codex-claude-loop, qwen-claude-loop, codex 스킬 제거됨
# skill-activation-prompt-with-notification.ts 제거 - 검토 필요
```

### Step 3: 통합 워크플로우 커맨드 생성
```bash
# /auto-workflow 생성
# /simple-workflow, /parallel-workflow, /complex-workflow 생성
```

### Step 4: 문서화
```bash
# GETTING_STARTED.md 작성
# WORKFLOW_GUIDE.md 작성
# EXAMPLES.md 작성
```

---

## 📈 성공 지표

### 정량적 지표
- **스킬 등록률**: 현재 37% (7/19) → 목표 100% (19/19)
- **자동 활성화율**: 목표 80% 이상
- **워크플로우 완료율**: 목표 95% 이상

### 정성적 지표
- **사용 편의성**: 수동 스킬 선택 최소화
- **품질 향상**: 자동 품질 검증으로 버그 감소
- **생산성**: 워크플로우 자동화로 작업 시간 30% 단축

---

## 🔄 유지보수 가이드

### 주간 점검
- [ ] skill-rules.json 업데이트 여부 확인
- [ ] 새로운 스킬 추가 검토
- [ ] 훅 성능 모니터링

### 월간 점검
- [ ] 사용 패턴 분석
- [ ] 미사용 스킬/훅 제거 검토
- [ ] 문서 업데이트

### 분기별 점검
- [ ] 전체 아키텍처 리뷰
- [ ] 새로운 워크플로우 패턴 발굴
- [ ] 성공 지표 달성 여부 평가

---

## 📚 참고 자료

### 공식 문서
- [Claude Code Skills](https://docs.claude.com/en/docs/claude-code/skills)
- [Claude Code Hooks](https://docs.claude.com/en/docs/claude-code/hooks)
- [Slash Commands](https://docs.claude.com/en/docs/claude-code/slash-commands)

### 내부 문서
- `docs/reports/`: 검증 및 분석 리포트
- `docs/agent-patterns/`: 에이전트 패턴 문서
- `docs/review/`: 스킬별 리뷰 보고서
- `docs/skills-guide/`: 스킬 사용 가이드
- 각 스킬 디렉토리의 `SKILL.md`

---

## 🎓 베스트 프랙티스

### 스킬 사용
1. **복잡도 먼저 파악**: 작업의 복잡도에 따라 적절한 워크플로우 선택
2. **자동화 우선**: 가능한 자동 워크플로우 사용
3. **품질 검증 필수**: 코드 작성 후 반드시 evaluator 실행

### 훅 사용
1. **최소 권한 원칙**: 필요한 권한만 부여
2. **성능 고려**: 훅은 매번 실행되므로 가볍게 유지
3. **에러 처리**: 훅 실패가 전체 워크플로우를 막지 않도록

### 슬래시 커맨드
1. **명확한 이름**: 기능이 명확히 드러나는 이름 사용
2. **문서화**: description 필드 상세 작성
3. **도구 제한**: allowed-tools로 필요한 도구만 허용

---

**Last Updated**: 2025-11-17
**Version**: 1.1.0
**Maintainer**: @inchan

---

## 📝 변경 이력

### v1.1.0 (2025-11-17)
- ✅ AI 연동 스킬 통합: codex-claude-loop, qwen-claude-loop, codex → dual-ai-loop
- ✅ 문서 구조 개편: 루트 파일을 docs/ 하위로 이동
- ✅ 스킬 총 개수 업데이트: 19개 → 22개
- ✅ 새로운 스킬 추가: agent-workflow-advisor, agent-workflow-orchestrator, cli-updater, subagent-creator
- ✅ CLI 어댑터 모듈화 (skills/cli-adapters/)

### v1.0.0 (2025-11-14)
- 초기 통합 관리 가이드 작성
