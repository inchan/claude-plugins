# CC-Skills Plugin

Claude Code 스킬 및 훅 컬렉션 플러그인 - 특화된 워크플로우, 에이전트, 개발 가이드라인으로 Claude Code를 확장합니다.

## 설치 방법

### 마켓플레이스에서 설치

```bash
# 마켓플레이스 추가
/plugin marketplace add inchan/cc-skills

# 플러그인 설치
/plugin install cc-skills@inchan-cc-skills

# 플러그인 활성화
/plugin enable cc-skills@inchan-cc-skills
```

### 로컬 설치 (개발용)

```bash
# 저장소 클론
git clone https://github.com/inchan/cc-skills.git
cd cc-skills

# 로컬 마켓플레이스로 추가
/plugin marketplace add ./

# 플러그인 설치
/plugin install cc-skills@inchan-cc-skills
```

### GitHub에서 직접 설치

```bash
/plugin marketplace add https://github.com/inchan/cc-skills
/plugin install cc-skills@inchan-cc-skills
```

## 플러그인 구성 요소

### 스킬 (23개)

| 카테고리 | 스킬 | 설명 |
|---------|------|------|
| **워크플로우** | agent-workflow-manager | 전체 워크플로우 자동 관리 |
| | agent-workflow-advisor | 패턴 추천 어드바이저 |
| | agent-workflow-orchestrator | 고급 오케스트레이션 |
| | intelligent-task-router | 작업 분류 및 라우팅 |
| | parallel-task-executor | 병렬 실행 엔진 |
| | dynamic-task-orchestrator | 복잡한 프로젝트 조율 |
| | sequential-task-processor | 순차 작업 처리 |
| **품질 관리** | iterative-quality-enhancer | 품질 평가 및 최적화 |
| | reflection-review | 코드 결과 평가 및 성찰 리뷰 |
| **개발 가이드** | frontend-dev-guidelines | React/TypeScript/MUI v7 |
| | backend-dev-guidelines | Node.js/Express/Prisma |
| | error-tracking | Sentry v8 패턴 |
| **도구 생성** | command-creator | 슬래시 커맨드 생성 |
| | hooks-creator | 훅 생성 가이드 |
| | skill-developer | 스킬 개발 종합 가이드 |
| | subagent-creator | 서브에이전트 생성 |
| | skill-generator-tool | 도구 타입 추천 |
| **AI 연동** | dual-ai-loop | 외부 AI CLI 협업 |
| | cli-updater | CLI 버전 업데이트 |
| **프롬프트** | meta-prompt-generator-v2 | 슬래시 커맨드용 프롬프트 생성 |
| | prompt-enhancer | 컨텍스트 기반 개선 |
| **기타** | route-tester | 인증 라우트 테스트 |
| | web-to-markdown | 웹페이지 변환 |

### 에이전트 (3개)

- **code-reviewer**: 코드 품질, 보안, 유지보수성 리뷰
- **architect**: 시스템 아키텍처 설계 및 기술 결정
- **workflow-orchestrator**: 복잡한 멀티스텝 워크플로우 오케스트레이션

### 훅 (3개)

| 이벤트 | 훅 | 설명 |
|--------|------|------|
| UserPromptSubmit | skill-activation-prompt | 프롬프트 분석 후 적합한 스킬 제안 |
| PostToolUse | post-tool-use-tracker | Edit/Write 후 변경 사항 추적 |
| Stop | stop-hook-lint-and-translate | 응답 완료 후 린트 및 번역 |

## 사용법

### 스킬 자동 활성화

플러그인이 활성화되면 `UserPromptSubmit` 훅이 사용자 프롬프트를 분석하여 적합한 스킬을 자동으로 제안합니다.

```
# 예시: "React 컴포넌트를 만들어줘"
# → frontend-dev-guidelines 스킬이 자동 제안됨

# 예시: "복잡한 워크플로우를 실행해줘"
# → agent-workflow-manager 스킬이 자동 제안됨
```

### 수동 스킬 호출

```bash
# 스킬 호출
/skill frontend-dev-guidelines
/skill backend-dev-guidelines
/skill error-tracking
```

### 워크플로우 패턴 선택

작업 복잡도에 따라 적절한 패턴이 선택됩니다:

- **복잡도 < 0.3**: Router (간단한 분류)
- **복잡도 0.3 - 0.7**: Sequential/Parallel
- **복잡도 > 0.7**: Orchestrator + Evaluator

## 플러그인 구조

```
cc-skills/
├── .claude-plugin/           # 플러그인 메타데이터
│   ├── plugin.json           # 플러그인 매니페스트
│   └── marketplace.json      # 마켓플레이스 설정
├── .claude/                   # Claude Code 설정
│   ├── commands/             # 슬래시 커맨드
│   ├── skills/               # 스킬 컬렉션 (23개)
│   ├── hooks/                # 원본 훅 스크립트
│   └── settings.local.json   # 프로젝트 훅 설정
├── agents/                    # 서브에이전트 정의
│   ├── code-reviewer.md
│   ├── architect.md
│   └── workflow-orchestrator.md
├── hooks/                     # 플러그인 훅 설정
│   └── hooks.json
├── scripts/                   # 훅 실행 스크립트
│   ├── skill-activation-prompt.ts
│   ├── post-tool-use-tracker.sh
│   ├── stop-hook-lint-and-translate.sh
│   └── meta-prompt-logger.js
├── skills -> .claude/skills   # 심볼릭 링크
├── .mcp.json                  # MCP 서버 설정
├── CLAUDE.md                  # 프로젝트 가이드
└── PLUGIN.md                  # 플러그인 문서 (이 파일)
```

## 참고 문서

### 공식 Anthropic 문서

- [Claude Code Plugins](https://code.claude.com/docs/en/plugins)
- [Plugin Marketplaces](https://code.claude.com/docs/en/plugin-marketplaces)
- [Plugins Reference](https://code.claude.com/docs/en/plugins-reference)
- [Hooks Reference](https://code.claude.com/docs/en/hooks)
- [MCP Documentation](https://code.claude.com/docs/en/mcp)

### 공식 저장소

- [claude-code](https://github.com/anthropics/claude-code) - Claude Code 메인 저장소
- [anthropics/skills](https://github.com/anthropics/skills) - 공식 Skills 예제
- [anthropics/life-sciences](https://github.com/anthropics/life-sciences) - 생명과학 MCP 서버

### 커뮤니티 마켓플레이스

- [EveryInc/every-marketplace](https://github.com/EveryInc/every-marketplace) - 17개 에이전트, 6개 커맨드
- [jeremylongshore/claude-code-plugins-plus](https://github.com/jeremylongshore/claude-code-plugins) - 253개 플러그인
- [claudeforge/marketplace](https://github.com/claudeforge/marketplace) - 161개 엔터프라이즈급 플러그인

### 모범 사례

- [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
- [Agent Skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills)
- [Plugins Blog](https://claude.com/blog/claude-code-plugins)

## 플러그인 개발 가이드

### plugin.json 스키마

```json
{
  "name": "plugin-name",
  "version": "1.0.0",
  "description": "Brief description",
  "author": {
    "name": "Author Name",
    "url": "https://github.com/author"
  },
  "commands": "./commands/",
  "agents": "./agents/",
  "hooks": "./hooks/hooks.json",
  "mcpServers": "./.mcp.json"
}
```

### marketplace.json 스키마

```json
{
  "name": "marketplace-name",
  "owner": {
    "name": "Owner Name"
  },
  "plugins": [
    {
      "name": "plugin-name",
      "source": "./",
      "description": "Plugin description",
      "version": "1.0.0"
    }
  ]
}
```

### 훅 설정

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/my-hook.sh"
          }
        ]
      }
    ]
  }
}
```

### 환경 변수

- `${CLAUDE_PLUGIN_ROOT}`: 플러그인 루트 디렉토리 경로

## 문제 해결

### 플러그인이 로드되지 않음
```bash
# 플러그인 유효성 검증
claude plugin validate .

# 디버그 모드로 확인
claude --debug
```

### 훅이 실행되지 않음
```bash
# 스크립트 실행 권한 확인
chmod +x scripts/*.sh
```

### 스킬이 활성화되지 않음
- `skill-rules.json`에 스킬이 등록되어 있는지 확인
- 키워드와 인텐트 패턴이 올바른지 확인

## 기여

1. 이 저장소를 포크합니다
2. 기능 브랜치를 만듭니다 (`git checkout -b feature/amazing-feature`)
3. 변경사항을 커밋합니다 (`git commit -m 'Add amazing feature'`)
4. 브랜치에 푸시합니다 (`git push origin feature/amazing-feature`)
5. Pull Request를 엽니다

## 라이선스

MIT License

## 버전 히스토리

### v1.2.0 (2025-11-19)
- Claude Code 플러그인 시스템으로 전환
- plugin.json, marketplace.json 추가
- 에이전트 디렉토리 구조화
- PLUGIN.md 문서 추가

### v1.1.0 (2025-11-17)
- dual-ai-loop으로 AI 연동 스킬 통합
- 디렉토리 구조 재편

### v1.0.0 (2025-11-14)
- 초기 릴리스
