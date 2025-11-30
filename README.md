# CC-Plugins

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

## 빠른 시작

### 1. 설치

```bash
git clone https://github.com/your-org/cc-plugins.git
cd cc-plugins
npm install
```

### 2. 문서 읽기

프로젝트를 이해하려면 다음 순서로 문서를 읽으세요:

1. [docs/instruction.md](docs/instruction.md) - 원본 지시사항
2. [docs/requirements.md](docs/requirements.md) - 프로젝트 요구사항
3. [docs/guidelines/](docs/guidelines/) - 개발 가이드라인 모음
4. [docs/references/](docs/references/) - 레퍼런스 및 빠른 검색 ⭐

### 3. 개발 시작

```bash
# 테스트 실행
npm test

# 검증
npm run validate
```

상세한 개발 워크플로우는 [docs/workflows.md](docs/workflows.md)와 [docs/references/](docs/references/)를 참고하세요.

---

## 프로젝트 구조

```
cc-plugins/
├── agents/                # 서브에이전트 (TDD 개발 팀 5개)
├── commands/              # 슬래시 커맨드
├── skills/                # 확장 스킬
├── hooks/                 # 이벤트 훅
├── rules/                 # 활성화 규칙
├── docs/                  # 프로젝트 문서
│   ├── guidelines/        # 개발 가이드라인
│   └── references/        # 레퍼런스 패턴
└── .claude-plugin/        # 플러그인 메타데이터
```

각 디렉토리 상세 구조는 해당 디렉토리의 README.md 참고

---

## 참고 자료

### 공식 문서 (1순위)

- [Claude Code 공식 사이트](https://claude.ai/claude-code)
- [공식 문서](https://docs.anthropic.com/claude-code)
- [GitHub 샘플](https://github.com/anthropics/claude-code)

### 프로젝트 문서

- [개발 가이드라인](docs/guidelines/development.md)
- [도구 생성 가이드](docs/guidelines/tool-creation.md)
- [문서 작성 가이드](docs/guidelines/documentation.md)

---

## 기여하기

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Read [Development Guidelines](docs/guidelines/development.md) and [References](docs/references/)
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

- Issues: [GitHub Issues](https://github.com/your-org/cc-plugins/issues)
- Discussions: [GitHub Discussions](https://github.com/your-org/cc-plugins/discussions)

---

## 변경 이력

- **2025-11-29**: 프로젝트 구조 직접 표기 (TDD 개발 팀 5개 반영)
- **2025-11-29**: 프로젝트 구조 섹션 참조로 변환 (CLAUDE.md 참조)
- **2025-11-28**: QUICK_START.md 삭제 - 마켓플레이스 설치 기반으로 불필요, 내용은 docs/references로 이동
- **2025-11-28**: README 간소화 - 중복 제거
