# CC-Skills

Claude Code용 스킬 및 훅 컬렉션 플러그인입니다.

## 설치

```bash
# 마켓플레이스 추가
/plugin marketplace add inchan/cc-skills

# 플러그인 설치 및 활성화
/plugin install cc-skills@inchan-cc-skills
/plugin enable cc-skills@inchan-cc-skills
```

## 구성 요소

### 스킬 (27개)

**워크플로우 관리**
- `agent-workflow-manager` - 워크플로우 자동 관리
- `intelligent-task-router` - 작업 분류 및 라우팅
- `parallel-task-executor` - 병렬 작업 실행
- `dynamic-task-orchestrator` - 복잡한 프로젝트 조율
- `sequential-task-processor` - 순차 작업 처리

**개발 가이드**
- `frontend-dev-guidelines` - React/TypeScript/MUI v7
- `backend-dev-guidelines` - Node.js/Express/Prisma
- `error-tracking` - Sentry v8 패턴

**도구 생성**
- `command-creator` - 슬래시 커맨드 생성
- `skill-creator` - 스킬 생성
- `subagent-creator` - 서브에이전트 생성
- `hooks-creator` - 훅 생성

**기타**
- `iterative-quality-enhancer` - 코드 품질 평가
- `dual-ai-loop` - 외부 AI CLI 협업
- `prompt-enhancer` - 프롬프트 개선

### 에이전트 (3개)

- `code-reviewer` - 코드 품질/보안 리뷰
- `architect` - 시스템 아키텍처 설계
- `workflow-orchestrator` - 워크플로우 오케스트레이션

### 훅 (3개)

| 이벤트 | 기능 |
|--------|------|
| UserPromptSubmit | 프롬프트 분석 후 스킬 제안 |
| PostToolUse | Edit/Write 후 변경사항 추적 |
| Stop | 응답 완료 후 린트/번역 |

## 사용법

플러그인 활성화 후 프롬프트를 입력하면 `UserPromptSubmit` 훅이 적합한 스킬을 자동으로 제안합니다.

```bash
# 스킬 수동 호출
/skill frontend-dev-guidelines
/skill backend-dev-guidelines
```

## 디렉토리 구조

```
cc-skills/
├── .claude-plugin/       # 플러그인 메타데이터
│   ├── plugin.json
│   └── marketplace.json
├── .claude/
│   ├── skills/           # 스킬 컬렉션
│   ├── commands/         # 슬래시 커맨드
│   └── hooks/            # 원본 훅 스크립트
├── agents/               # 서브에이전트
├── hooks/                # 플러그인 훅 설정
└── scripts/              # 컴파일된 훅 스크립트
```

## 요구사항

- Claude Code CLI
- Node.js 18+

## 라이선스

MIT
