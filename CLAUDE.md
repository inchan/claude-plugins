# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This is a Claude Code skills and hooks collection - a toolkit for extending Claude Code capabilities with specialized skills, workflows, subagents, and hooks.

## Quick Start for Tool Creation

**When users want to create any Claude Code tool (command, skill, subagent, hook):**
1. Use the `skill-generator-tool` skill first to analyze intent and recommend the optimal tool type
2. Route to specialized creators: `command-creator`, `skill-developer`, `subagent-creator`, `hooks-creator`

## Core Architecture

### Directory Structure
```
.claude/
├── skills/           # 23+ skills (SKILL.md + bundled resources)
├── commands/         # Slash commands (.md files)
├── hooks/            # Event hooks (shell scripts)
└── settings.local.json  # Hook configuration

# Plugin structure (root level)
.claude-plugin/       # Plugin metadata
├── plugin.json       # Plugin configuration
└── marketplace.json  # Marketplace listing
agents/               # Subagent definitions
scripts/              # Installation and utility scripts
hooks/hooks.json      # Plugin hook configuration
```

### Key Configuration Files
- `.claude/skills/skill-rules.json` - Skill auto-activation triggers (keywords, intent patterns)
- `.claude/settings.local.json` - Hook registration and permissions

### Skill Categories

1. **Tool Creators** (highest priority for tool creation tasks):
   - `skill-generator-tool` - Entry point, recommends optimal tool type
   - `command-creator`, `skill-developer`, `subagent-creator`, `hooks-creator`

2. **Workflow Management**:
   - `agent-workflow-manager`, `intelligent-task-router`, `parallel-task-executor`
   - `dynamic-task-orchestrator`, `sequential-task-processor`

3. **Development Guidelines**:
   - `frontend-dev-guidelines` - React/TypeScript/MUI v7
   - `backend-dev-guidelines` - Node.js/Express/Prisma
   - `error-tracking` - Sentry v8 patterns

## Development Commands

### Installation
```bash
# Install skills to global (~/.claude) or workspace (./.claude)
node scripts/install-skills.js
node scripts/install-skills.js --target global
node scripts/install-skills.js --target workspace
node scripts/install-skills.js --dry-run  # Preview without changes
```

### Intent Analysis (for skill-generator-tool)
```bash
python3 .claude/skills/skill-generator-tool/scripts/analyze_intent.py "user request"
```

### Workflow Commands
```bash
# Use slash commands for workflows
/auto-workflow <작업 설명>      # Auto-analyze and execute optimal workflow
/workflow-simple <작업 설명>    # Sequential task processing
/workflow-parallel <작업 설명>  # Parallel task execution
/workflow-complex <프로젝트 설명> # Complex project orchestration
```

## Important Patterns

### Skill Auto-Activation
Skills trigger automatically via `skill-rules.json` patterns. The `UserPromptSubmit` hook (`skill-activation-prompt.ts`) analyzes prompts and suggests relevant skills.

### Progressive Disclosure
Skills use three-level loading:
1. Metadata (name + description) - Always in context
2. SKILL.md body - When skill triggers
3. Bundled resources - As needed

### Tool Type Selection
- **Command**: User-invoked prompt shortcuts (`/format`, `/review-pr`)
- **Skill**: Domain expertise with bundled resources
- **Subagent**: Focused AI agents with restricted permissions
- **Hook**: Event-driven automation (PreToolUse, PostToolUse, Stop)
- **Plugin**: Package multiple tools together

## Official Documentation References
- [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
- [Agent Skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills)
- [Plugins](https://claude.com/blog/claude-code-plugins)

---

# Claude Code Skills & Hooks - 통합 관리 가이드

**최종 업데이트**: 2025-11-19
**버전**: 1.3.0

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

### 스킬 현황 (총 23개)

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

#### 4. 도구 생성 (3개)
- **command-creator**: 슬래시 커맨드 생성 및 관리
- **hooks-creator**: 훅 생성 가이드
- **subagent-creator**: 서브에이전트 생성 가이드

#### 5. AI 연동 (1개) ✅ 통합 완료
- **dual-ai-loop**: 통합 Dual-AI 엔지니어링 루프
  - 5개 CLI 지원 (codex ✅, qwen ✅, copilot, rovo-dev, aider)
  - codex와 qwen은 실제 테스트 검증됨
  - 역할 교체 가능 (구현자/리뷰어)
  - CLI 어댑터 모듈화 (.claude/skills/cli-adapters/)
  - cli-updater로 자동 버전 관리

#### 6. 프롬프트 도구 (2개)
- **meta-prompt-generator-v2**: 슬래시 커맨드용 프롬프트 생성 (간결하고 실용적)
- **prompt-enhancer**: 프로젝트 컨텍스트 기반 프롬프트 개선

#### 7. 기타 도구 (6개)
- **skill-developer**: 스킬 개발 종합 가이드 (Anthropic 공식 표준 준수 + 유틸리티 스크립트 포함)
- **skill-generator-tool**: 도구 유형 분석 및 최적 생성기 추천
- **reflection-review**: Claude Code 결과를 6개 영역에서 평가 및 성찰 기반 리뷰
- **route-tester**: 인증 라우트 테스트
- **web-to-markdown**: 웹페이지 마크다운 변환
- **cli-updater**: CLI 도구 자동 버전 업데이트

### 훅 현황 (활성화 3개)

**위치**: `.claude/hooks/`
**설정 파일**: `.claude/settings.local.json`

#### UserPromptSubmit 훅 (2개)
1. **skill-activation-prompt.ts**:
   - 사용자 프롬프트 분석 후 적합한 스킬 자동 제안
   - `.claude/skills/skill-rules.json` 기반 키워드/인텐트 매칭
   - 우선순위별 스킬 추천 (Critical → High → Medium → Low)

2. **meta-prompt-logger.js**:
   - 프롬프트 로깅 및 분석
   - 사용 패턴 추적

#### PostToolUse 훅 (1개)
- **post-tool-use-tracker.sh**: Edit/Write 후 변경 사항 추적

#### Stop 훅 (1개)
- **stop-hook-lint-and-translate.sh**: 응답 완료 후 린트 및 번역

### Skill Rules 등록 현황

**등록된 스킬** (20개) ✅ 대폭 개선됨:
- skill-developer
- skill-generator-tool ✅ (신규)
- meta-prompt-generator-v2 ✅
- backend-dev-guidelines
- frontend-dev-guidelines
- route-tester
- error-tracking
- prompt-enhancer ✅
- reflection-review ✅ (신규)
- agent-workflow-manager ✅
- agent-workflow-advisor ✅
- intelligent-task-router ✅
- parallel-task-executor ✅
- dynamic-task-orchestrator ✅
- sequential-task-processor ✅
- iterative-quality-enhancer ✅
- dual-ai-loop ✅
- command-creator ✅ (신규)
- hooks-creator ✅ (신규)
- subagent-creator ✅ (신규)

**미등록 스킬** (3개):
- agent-workflow-orchestrator
- cli-updater
- web-to-markdown

---

## 🎯 해결된 문제 및 현재 상태

### ✅ 해결 완료

1. **스킬 등록 개선** (Critical → Resolved)
   - 핵심 워크플로우 스킬 8개 + 도구 생성 스킬 3개 모두 등록 완료
   - 등록률: 33% → 87% (20/23)
   - 자동 활성화 기능 정상화

2. **중복 제거** (High → Resolved)
   - meta-prompt-generator → meta-prompt-generator-v2 통합 완료
   - skill-creator → skill-developer 통합 완료 (스크립트 포함)
   - AI Loop 통합 완료 (dual-ai-loop)

3. **워크플로우 연결** (High → Resolved)
   - /auto-workflow 커맨드 생성 완료
   - 워크플로우별 커맨드 3개 생성 (simple, parallel, complex)
   - 자동 체인 실행 가능

### ⚠️ 남은 과제 (Minor)

1. **미등록 스킬 6개**
   - agent-workflow-orchestrator (중요도: 낮음 - agent-workflow-manager와 중복)
   - command-creator, hooks-creator, subagent-creator, cli-updater, web-to-markdown

2. **문서화 개선 필요**
   - 각 스킬의 활용 예제 추가
   - 워크플로우 사용 가이드 작성

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
- `docs/agent-patterns/`: 에이전트 패턴 문서
- `docs/TOOL-CREATORS-*.md`: 도구 생성 가이드 및 아키텍처
- `docs/skills-guide/`: 스킬 사용 가이드 및 결정 트리
- `README.md`: 설치 및 사용 가이드
- `PLUGIN.md`: 플러그인 구조 및 기능 설명
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

**Last Updated**: 2025-11-19
**Version**: 1.3.0
**Maintainer**: @inchan

---

## 📝 변경 이력

### v1.3.0 (2025-11-20)
- ✅ **원격 저장소 머지**: 플러그인 구조, README, agents 디렉토리 통합
- ✅ **스킬 등록 대폭 개선**: skill-rules.json에 20개 스킬 등록
  - 워크플로우: agent-workflow-manager, advisor, router, parallel, orchestrator 등
  - 도구 생성: command-creator, hooks-creator, subagent-creator
  - 등록률: 33% → 87% (20/23)
- ✅ **슬래시 커맨드 생성**: 워크플로우 커맨드 4개 추가
  - /auto-workflow (통합 진입점)
  - /workflow-simple, /workflow-parallel, /workflow-complex
- ✅ **스킬 중복 제거**:
  - meta-prompt-generator → meta-prompt-generator-v2 통합
  - skill-creator → skill-developer 통합 (스크립트 포함)
- ✅ **문서 현행화**: 실제 상태와 문서 동기화

### v1.2.0 (2025-11-17)
- ✅ **디렉토리 구조 재편**: Claude Code 표준 구조로 마이그레이션
  - `skills/` → `.claude/skills/`
  - `hooks/` → `.claude/hooks/`
  - `.claude/commands/` 디렉토리 생성
- ✅ **훅 설정 등록**: `.claude/settings.local.json`에 훅 구성 추가

### v1.1.0 (2025-11-17)
- ✅ AI 연동 스킬 통합: codex-claude-loop, qwen-claude-loop, codex → dual-ai-loop
- ✅ 문서 구조 개편: 루트 파일을 docs/ 하위로 이동
- ✅ 스킬 총 개수 업데이트: 19개 → 22개
- ✅ 새로운 스킬 추가: agent-workflow-advisor, agent-workflow-orchestrator, cli-updater, subagent-creator
- ✅ CLI 어댑터 모듈화 (.claude/skills/cli-adapters/)

### v1.0.0 (2025-11-14)
- 초기 통합 관리 가이드 작성
