# CC-Skills

> Claude Code 확장 기능 개발 및 배포 프로젝트

**공식 문서 기반**으로 개발된 Skills, Hooks, Sub-agents, Commands, Rules 모음

---

## 프로젝트 개요

Claude Code의 확장 기능을 체계적으로 개발하고 마켓플레이스 플러그인으로 배포하여 Claude Code 사용자 경험을 향상시킵니다.

### 핵심 원칙

1. **공식 소스 기반**: Anthropic 공식 자료에 근거
2. **검증된 패턴**: 커뮤니티 검증 모범 사례 적용
3. **재사용성**: 범용 컴포넌트 설계
4. **품질 우선**: 배포 전 철저한 테스트

---

## 프로젝트 구조

```
cc-skills/
├── docs/                  # 문서
│   ├── guidelines/        # 가이드라인 모음
│   ├── instruction.md     # 원본 지시사항
│   ├── requirements.md    # 프로젝트 요구사항
│   └── workflows.md       # 워크플로우 정의
├── skills/                # 스킬 모음
│   └── {skill-name}/
├── hooks/                 # 훅 모음
│   ├── hooks.json
│   └── *.py|*.sh
├── agents/                # 서브에이전트 모음
│   └── {agent-name}.md
├── commands/              # 커맨드 모음
│   └── {command-name}.md
├── rules/                 # 규칙 정의
│   └── skill-rules.json
├── templates/             # 템플릿
│   ├── skills/
│   ├── hooks/
│   ├── agents/
│   └── commands/
├── tests/                 # 테스트
│   ├── skills/
│   ├── hooks/
│   ├── agents/
│   ├── commands/
│   └── integration/
└── .claude-plugin/        # 플러그인 메타데이터
    ├── plugin.json
    └── marketplace.json
```

---

## 시작하기

### 1. 문서 읽기

먼저 다음 문서들을 순서대로 읽어주세요:

1. [instruction.md](docs/instruction.md) - 프로젝트 원본 지시사항
2. [requirements.md](docs/requirements.md) - 프로젝트 요구사항
3. [workflows.md](docs/workflows.md) - 작업 흐름
4. [Development Guidelines](docs/guidelines/development.md) - 개발 가이드라인
5. [Tool Creation Guide](docs/guidelines/tool-creation.md) - 도구 생성 가이드

### 2. 개발 환경 설정

```bash
# 저장소 클론
git clone https://github.com/your-org/cc-skills.git
cd cc-skills

# 의존성 설치
npm install

# 검증
npm run validate
```

### 3. 새로운 컴포넌트 개발

#### Skills 생성
```bash
# 템플릿 복사
cp -r templates/skills/SKILL.md.template skills/my-skill/SKILL.md

# 편집 후 규칙 추가
vim rules/skill-rules.json

# 테스트
npm run test:skills
```

#### Hooks 생성
```bash
# 템플릿 복사
cp templates/hooks/hook.py.template hooks/my-hook.py

# hooks.json 업데이트
vim hooks/hooks.json

# 실행 권한
chmod +x hooks/my-hook.py

# 테스트
npm run test:hooks
```

#### Agents 생성
```bash
# 템플릿 복사
cp templates/agents/agent.md.template agents/my-agent.md

# 편집
vim agents/my-agent.md
```

#### Commands 생성
```bash
# 템플릿 복사
cp templates/commands/command.md.template commands/my-command.md

# 편집
vim commands/my-command.md
```

---

## Attribution

일부 스킬은 공식 소스에서 복사 또는 참고했습니다:

- **webapp-testing**: [anthropics/skills](https://github.com/anthropics/skills)
- **skill-creator**: [anthropics/skills](https://github.com/anthropics/skills)

---

## 참고 자료

### 공식 문서 (1순위)

- [Claude Code 공식 사이트](https://claude.ai/claude-code)
- [공식 문서](https://docs.anthropic.com/claude-code)
- [공식 블로그](https://www.anthropic.com/news)
- [GitHub 샘플](https://github.com/anthropics/claude-code)

### 프로젝트 문서

- [각 디렉토리별 README](skills/README.md)
- [템플릿 가이드](templates/)

---

## 기여하기

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Read [Development Guidelines](docs/guidelines/development.md)
4. Commit your changes following [workflows](docs/workflows.md)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

### 품질 기준

Pull Request 전 확인:
- [ ] 공식 문서 기반 구현
- [ ] 테스트 커버리지 80% 이상
- [ ] 문서화 완료
- [ ] 코드 리뷰 완료
- [ ] requirements.md 요구사항 충족

---

## 라이센스

MIT License - 자세한 내용은 [LICENSE](LICENSE) 참고

---

## 연락처

- Issues: [GitHub Issues](https://github.com/your-org/cc-skills/issues)
- Discussions: [GitHub Discussions](https://github.com/your-org/cc-skills/discussions)

---

## 변경 이력

변경 사항은 [CHANGELOG.md](CHANGELOG.md) 참고
