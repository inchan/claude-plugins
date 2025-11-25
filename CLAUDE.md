# CLAUDE.md

---
version: 0.0.1
status: pre-release
last_updated: 2025-11-25
---

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> **⚠️ Pre-release**: 현재 v0.0.1 개발 버전입니다. 정식 릴리스는 v1.0.0부터 시작됩니다.

## Multi-Plugin Architecture (Pre-release)

이 프로젝트는 anthropics/claude-code 패턴을 따라 **8개 독립 플러그인**으로 구성됩니다.

### 플러그인 목록

| 플러그인 | 타입 | 설명 |
|---------|--------|------|
| **hooks** | Hooks | Multi-Tier 스킬 자동 활성화 시스템 |
| **workflow-automation** | 7 Skills | 복잡도 기반 작업 라우팅 (순차/병렬/동적) |
| **dev-guidelines** | 3 Skills | Frontend/Backend 개발 패턴, 에러 추적 |
| **tool-creators** | 6 Skills | Skill/Command/Agent/Hook 생성 도구 |
| **quality-review** | 2 Skills | 5차원 품질 평가, P0/P1/P2 피드백 |
| **ai-integration** | 3 Skills | 외부 AI CLI 통합 (codex, qwen, aider 등) |
| **prompt-enhancement** | 2 Skills | 메타 프롬프트 생성, 프롬프트 최적화 |
| **utilities** | 1 Skill | 유틸리티 도구 (route-tester) |

**총계**: 24 스킬, 4 커맨드, 3 에이전트, 3 훅

### 디렉토리 구조

```
plugins/
├── hooks/                  # 🔥 스킬 자동 활성화 시스템
│   ├── .claude-plugin/plugin.json
│   ├── skill-activation-hook.sh
│   ├── lib/               # 공유 라이브러리
│   ├── matchers/          # Multi-Tier 매칭 엔진
│   ├── config/            # 설정 (synonyms.json 등)
│   ├── cache/             # 캐시 디렉토리
│   └── tests/             # 테스트 스크립트
├── workflow-automation/
│   ├── .claude-plugin/plugin.json
│   ├── skills/ (7개)
│   ├── commands/ (4개)
│   └── agents/ (1개)
├── dev-guidelines/
│   ├── .claude-plugin/plugin.json
│   └── skills/ (3개)
├── tool-creators/
│   ├── .claude-plugin/plugin.json
│   └── skills/ (5개)
├── quality-review/
│   ├── .claude-plugin/plugin.json
│   ├── skills/ (2개)
│   └── agents/ (2개)
├── ai-integration/
│   ├── .claude-plugin/plugin.json
│   └── skills/ (3개)
├── prompt-enhancement/
│   ├── .claude-plugin/plugin.json
│   └── skills/ (2개)
└── utilities/
    ├── .claude-plugin/plugin.json
    └── skills/ (1개)

scripts/                    # 유틸리티 스크립트
.claude-plugin/             # Marketplace 메타데이터
    └── marketplace.json
```

### 배포 방식

**직접 Git 추적** - 빌드 프로세스 없음
- `plugins/` 디렉토리를 직접 Git에 커밋
- 변경 시 바로 반영
- anthropics/claude-code와 동일한 패턴

## Development Commands

### Dependency Analysis
```bash
# Phase 0: 스킬 간 의존성 분석
node scripts/analyze-dependencies.js
# 결과: tests/dependency-analysis.json
```

### Migration Scripts
```bash
# 단일 플러그인 → 다중 플러그인 마이그레이션
bash scripts/migrate-to-multi-plugin.sh

# skill-rules.json 플러그인별 분할
node scripts/split-skill-rules.js
```

### Plugin Development

#### 새 플러그인 추가
```
plugins/new-plugin/
├── .claude-plugin/
│   └── plugin.json          # 메타데이터
├── skills/
│   ├── skill-rules.json     # 스킬 트리거
│   └── skill-name/
│       ├── SKILL.md          # 500줄 제한
│       └── resources/       # 번들 리소스
├── commands/                # 슬래시 커맨드 (선택)
├── agents/                  # 에이전트 (선택)
└── hooks/                   # 훅 (선택)
```

#### marketplace.json 업데이트
```json
{
  "plugins": [
    {
      "name": "new-plugin",
      "version": "0.0.1",
      "source": "./plugins/new-plugin",
      "description": "Plugin description"
    }
  ]
}
```

## Key Architecture Patterns

### Skill Auto-Activation

**Multi-Tier Matching Pipeline**:
- **Tier 1**: Keyword Matching (Bash + AWK) - <50ms
- **Tier 2**: TF-IDF Matching (Node.js) - <150ms
- **Tier 3**: Semantic Matching (Python) - <400ms
- **전체 타임아웃**: 500ms 이내

**구성**:
- **각 플러그인**: `plugins/*/skills/skill-rules.json` - 플러그인별 트리거
- **전역 훅**: `plugins/hooks/skill-activation-hook.sh` - Multi-Tier 매칭 시스템
- **동의어 사전**: `plugins/hooks/config/synonyms.json` - 한글-영어 매핑
- **Priority levels**: critical > high > medium > low

**참고 문서**: [plugins/hooks/INDEX.md](plugins/hooks/INDEX.md)

### Tool Type Selection Guide
| Type | When to Use | Example |
|------|-------------|---------|
| **Command** | User-invoked shortcuts | `/auto-workflow`, `/workflow-simple` |
| **Skill** | Domain expertise + resources | `frontend-dev-guidelines`, `error-tracking` |
| **Subagent** | Focused AI with permissions | `code-reviewer`, `architect` |
| **Hook** | Event-driven automation | `skill-forced-eval-hook` |

### Workflow Orchestration
```
User Prompt → skill-forced-eval-hook
           → intelligent-task-router (complexity 0.0-1.0)
           → Sequential (< 0.3) / Parallel (0.3-0.7) / Orchestrator (> 0.7)
           → iterative-quality-enhancer
```

## Configuration Files

### skill-rules.json Structure
```json
{
  "skills": {
    "skill-name": {
      "type": "domain",           // domain | guideline | tool
      "enforcement": "suggest",   // suggest | block | warn
      "priority": "high",         // critical | high | medium | low
      "promptTriggers": {
        "keywords": ["word1", "word2"],
        "intentPatterns": ["regex1", "regex2"]
      }
    }
  }
}
```

### hooks.json (Plugin Hooks)
```json
{
  "hooks": {
    "UserPromptSubmit": [{
      "matcher": "",
      "hooks": [{"type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/skill-forced-eval-hook.sh"}]
    }],

  }
}
```

## Common Tasks

### Adding a New Skill
1. Create `skills/my-skill/SKILL.md` (≤500 lines)
2. Add bundled resources to `skills/my-skill/resources/` (optional)
3. Register in `skills/skill-rules.json`
4. Test: `node tests/run-activation-tests.js`
5. Use `skill-developer` skill for detailed guidance

### Creating a Slash Command
1. Create `commands/my-command.md` with frontmatter:
```markdown
---
description: Brief description
allowed-tools: Task, Bash
---
Your prompt here
```
2. Use `command-creator` skill for templates

### Adding a Hook
1. Create script in `hooks/my-hook.{js,sh}`
2. Register in `hooks/hooks.json`
3. Set permissions in `settings.local.json`
4. Use `hooks-creator` skill for patterns

## Testing Guidelines

When modifying skills or hooks:
1. Run `node tests/validate-skill-rules.js` to check syntax
2. Test activation with `node tests/run-activation-tests.js`
3. Check installation with `node tests/install-skills.test.js --dry-run`
4. Review test results in `tests/activation-test-results.json`

## Skill Categories & Entry Points

### Tool Creation (Use these first for creating new tools)
- **skill-generator-tool** - Analyzes intent, recommends tool type (Command/Skill/Subagent/Hook)
- **command-creator** - Creates slash commands
- **skill-developer** - Creates skills (Anthropic best practices + 500-line rule)
- **subagent-creator** - Creates subagents (7 templates)
- **hooks-creator** - Creates hooks (6 event types)

### Workflow Management (Auto-orchestration)
- **agent-workflow-manager** - Entry point: auto-routes to Sequential/Parallel/Orchestrator based on complexity
- **intelligent-task-router** - Classifies tasks into 8 categories (bug_fix, feature_development, etc.)
- **parallel-task-executor** - Sectioning (parallel) / Voting (multi-approach) modes
- **dynamic-task-orchestrator** - Complex projects (complexity > 0.7), 6 specialized workers
- **sequential-task-processor** - Simple sequential tasks (complexity < 0.3)

### Quality & Review
- **iterative-quality-enhancer** - 5-dimension evaluation (Functionality, Performance, Code Quality, Security, Documentation)
- **reflection-review** - 6-area scoring with P0/P1/P2 prioritized feedback

### Development Guidelines
- **frontend-dev-guidelines** - React/TypeScript/MUI v7, Suspense, TanStack Router
- **backend-dev-guidelines** - Node.js/Express/Prisma, layered architecture, Zod validation
- **error-tracking** - Sentry v8 patterns (ALL errors must be captured)

### AI Integration
- **dual-ai-loop** - Integrates external AI CLIs (codex, qwen, copilot, rovo-dev, aider)
- **cli-updater** - Auto-updates CLI adapter skills and docs

## Important Notes

### Skill Development
- **500-line rule**: SKILL.md must be ≤500 lines
- **Progressive disclosure**: Metadata → SKILL.md body → Bundled resources
- **Bundle resources**: Put templates/examples in `resources/` subdirectory
- Always register in `skill-rules.json` with keywords/intentPatterns

### Hook Development
- Hooks run on every trigger - keep them lightweight
- Use `${CLAUDE_PLUGIN_ROOT}` for plugin-relative paths
- Test with minimal permissions first

### Testing Before Commit
```bash
node tests/validate-skill-rules.js  # Must pass
node tests/run-activation-tests.js  # Verify triggers work
```

## Documentation

이 프로젝트는 체계적인 문서 관리를 위해 문서 가이드라인을 따릅니다.

### 문서 구조
```
docs/
├── DOCUMENTATION_GUIDELINES.md   # 📚 문서 작성 가이드라인 (필수 읽기)
├── SKILL-DEVELOPMENT-GUIDE.md    # 스킬 개발 가이드
├── skills-guide/                 # 스킬 사용 가이드
│   ├── README.md                 # 스킬 가이드 메인
│   ├── DECISION_TREE.md          # 스킬 선택 결정 트리
│   └── COMMON_PITFALLS.md        # 흔한 실수 및 해결책
├── agent-patterns/               # 에이전트 패턴
│   ├── AGENT_PATTERNS_README.md  # 에이전트 패턴 개요
│   └── INTER_SKILL_PROTOCOL.md   # 스킬 간 통신 프로토콜
├── tool-creators/                # 도구 생성 가이드
│   ├── README.md                 # 도구 생성 메인 가이드
│   ├── ARCHITECTURE.md           # 아키텍처 설명
│   ├── QUICK_REFERENCE.md        # 빠른 참조
│   └── ...
├── review/                       # 리뷰 및 분석
└── archive/                      # 아카이브된 문서
```

### 문서 작성 규칙

새 문서 작성 또는 기존 문서 수정 시:
1. **[DOCUMENTATION_GUIDELINES.md](docs/DOCUMENTATION_GUIDELINES.md)** 필수 참조
2. 한글 우선, 기술 용어는 영어 사용
3. 명확한 구조 (제목, 목차, 섹션)
4. 실행 가능한 예제 포함
5. 링크 유효성 검증

### 주요 문서 링크

| 문서 | 설명 | 대상 |
|------|------|------|
| [DOCUMENTATION_GUIDELINES.md](docs/DOCUMENTATION_GUIDELINES.md) | 문서 작성 표준 및 스타일 가이드 | 모든 기여자 |
| [SKILL-DEVELOPMENT-GUIDE.md](docs/SKILL-DEVELOPMENT-GUIDE.md) | 스킬 개발 종합 가이드 | 스킬 개발자 |
| [tool-creators/](docs/tool-creators/) | 도구 생성 가이드 (Command/Skill/Hook/Subagent) | 도구 개발자 |
| [skills-guide/](docs/skills-guide/) | 스킬 사용 가이드 | 사용자 |
| [agent-patterns/](docs/agent-patterns/) | 에이전트 패턴 참조 | 개발자 |

## Official References
- [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
- [Agent Skills Guide](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills)
- [Plugins Documentation](https://claude.com/blog/claude-code-plugins)

---

# Additional Context (Historical Project Status)

이 섹션은 프로젝트의 역사적 맥락과 개선 계획을 담고 있습니다.
현재 프로젝트 상태 및 로드맵은 `docs/` 디렉토리를 참조하세요.

## Plugin Status Summary

**스킬**: 24개 (20개 skill-rules.json 등록)
**에이전트**: 3개 (code-reviewer, architect, workflow-orchestrator)
**훅**: 3개 (UserPromptSubmit, PostToolUse, Stop)
**슬래시 커맨드**: 4개 (auto-workflow, workflow-simple/parallel/complex)

### Recent Changes (v1.5.0)
- ✅ 플러그인 구조로 완전 마이그레이션
- ✅ hooks/node_modules 제거 (TypeScript → JavaScript 마이그레이션 완료)
- ✅ meta-prompt-generator 통합 (v2 및 .old 버전 제거)
- ✅ 20개 스킬 skill-rules.json 등록
- ✅ 워크플로우 슬래시 커맨드 4개 생성
- ✅ dual-ai-loop으로 AI 연동 통합

### Unregistered Skills (intentionally)
- **agent-workflow-orchestrator**: 고급 기능, 명시적 호출 권장 (agent-workflow-manager로 충분)
- **cli-updater**: dual-ai-loop 내부 호출용, 자동 트리거 불필요
- **skill-creator.old**: 레거시 버전, skill-developer로 대체됨

자세한 프로젝트 계획 및 로드맵은 이전 버전 CLAUDE.md 또는 `docs/` 디렉토리를 참조하세요.

---

## Legacy Content Removed

이전 CLAUDE.md의 나머지 내용(현재 상태 분석, 개선 방향성, 로드맵, 베스트 프랙티스, 변경 이력)은 제거되었습니다.
필요시 git history에서 복구하거나 `docs/` 디렉토리의 관련 문서를 참조하세요.

