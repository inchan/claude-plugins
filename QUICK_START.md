# Quick Start Guide

> CC-Skills 프로젝트 빠른 시작 가이드

---

## 1. 프로젝트 개요

```
📁 cc-skills/
├── 📄 docs/              문서
│   ├── instruction.md    원본 지시사항
│   ├── requirements.md   프로젝트 요구사항
│   ├── workflows.md      작업 흐름
│   ├── guidelines/       가이드라인 모음
│   └── research/         공식 자료 조사
│
│   └── references/      레퍼런스 (개발 시 참고)
│       ├── hooks/       훅 패턴
│       ├── agents/      에이전트 패턴
│       ├── commands/    커맨드 패턴
│       ├── plugins/     플러그인 구조
│       └── examples/    공식 예제 코드
│
├── 📦 templates/         템플릿
│   ├── skills/          스킬 템플릿
│   ├── hooks/           훅 템플릿
│   ├── agents/          에이전트 템플릿
│   └── commands/        커맨드 템플릿
│
├── 🔧 skills/           스킬 구현
├── 🪝 hooks/            훅 구현
├── 🤖 agents/           에이전트 구현
├── ⚡ commands/         커맨드 구현
├── 📋 rules/            규칙 정의
└── ✅ tests/            테스트
```

---

## 2. 문서 읽는 순서

### 처음 시작하는 경우

```
1. README.md              ← 프로젝트 전체 개요
2. docs/instruction.md    ← 원본 지시사항
3. docs/requirements.md   ← 프로젝트 요구사항
4. docs/workflows.md      ← 작업 흐름
5. docs/references/README.md   ← 레퍼런스 사용법
```

### 개발 시작 전

```
1. docs/guidelines/development.md     ← 개발 가이드라인
2. docs/guidelines/tool-creation.md   ← 도구 생성 가이드
3. docs/references/{타입}/                ← 해당 타입 레퍼런스
```

---

## 3. 개발 워크플로우

### 새로운 Hook 개발

```bash
# 1. 레퍼런스 읽기
cat docs/references/hooks/pretooluse-pattern.md

# 2. 템플릿 복사
cp templates/hooks/hook.py.template hooks/my-hook.py

# 3. 편집
vim hooks/my-hook.py

# 4. hooks.json 업데이트
vim hooks/hooks.json

# 5. 실행 권한
chmod +x hooks/my-hook.py

# 6. 테스트
echo '{"tool_name":"Bash","tool_input":{"command":"test"}}' | python3 hooks/my-hook.py
```

### 새로운 Skill 개발

```bash
# 1. 디렉토리 생성
mkdir -p skills/my-skill/{resources,scripts}

# 2. 템플릿 복사
cp templates/skills/SKILL.md.template skills/my-skill/SKILL.md

# 3. 편집
vim skills/my-skill/SKILL.md

# 4. 규칙 추가
vim rules/skill-rules.json

# 5. 테스트
npm run test:skills
```

### 새로운 Agent 개발

```bash
# 1. 레퍼런스 읽기
cat docs/references/agents/multi-agent-orchestration.md

# 2. 템플릿 복사
cp templates/agents/agent.md.template agents/my-agent.md

# 3. 편집
vim agents/my-agent.md

# 4. 테스트
# Task tool로 에이전트 호출 테스트
```

### 새로운 Command 개발

```bash
# 1. 레퍼런스 읽기
cat docs/references/commands/slash-command-pattern.md

# 2. 템플릿 복사
cp templates/commands/command.md.template commands/my-command.md

# 3. 편집
vim commands/my-command.md

# 4. 테스트
claude
/my-command
```

---

## 4. 레퍼런스 빠른 검색

### 질문별 레퍼런스

| 질문 | 레퍼런스 |
|------|---------|
| "PreToolUse 훅 어떻게 만들지?" | `docs/references/hooks/pretooluse-pattern.md` |
| "훅 이벤트 종류는?" | `docs/references/hooks/event-types.md` |
| "다중 에이전트 패턴은?" | `docs/references/agents/multi-agent-orchestration.md` |
| "슬래시 커맨드 구조는?" | `docs/references/commands/slash-command-pattern.md` |
| "플러그인 표준 구조는?" | `docs/references/plugins/standard-structure.md` |
| "공식 예제 코드는?" | `docs/references/examples/bash-command-validator.py` |

### 타입별 필수 문서

**Hooks 개발 시**:
```
docs/references/hooks/pretooluse-pattern.md  (필수)
docs/references/hooks/event-types.md
docs/references/examples/bash-command-validator.py
hooks/README.md
```

**Agents 개발 시**:
```
docs/references/agents/multi-agent-orchestration.md  (필수)
agents/README.md
templates/agents/agent.md.template
```

**Commands 개발 시**:
```
docs/references/commands/slash-command-pattern.md  (필수)
commands/README.md
templates/commands/command.md.template
```

---

## 5. 체크리스트

### 개발 전

- [ ] `docs/instruction.md` 읽음
- [ ] `docs/requirements.md` 해당 섹션 확인
- [ ] `docs/references/{타입}/` 레퍼런스 읽음
- [ ] 공식 예제 코드 분석

### 개발 중

- [ ] 템플릿 사용
- [ ] 베스트 프랙티스 준수
- [ ] 주석 작성
- [ ] 예제 포함

### 개발 후

- [ ] 단위 테스트 작성
- [ ] 통합 테스트 실행
- [ ] README 업데이트
- [ ] `requirements.md` 체크리스트 검증

---

## 6. 자주 찾는 파일

### 문서

```bash
# 지시사항 확인
cat docs/instruction.md

# 요구사항 확인
cat docs/requirements.md

# 워크플로우 확인
cat docs/workflows.md
```

### 레퍼런스

```bash
# Hooks 패턴
cat docs/references/hooks/pretooluse-pattern.md

# 에이전트 패턴
cat docs/references/agents/multi-agent-orchestration.md

# 공식 예제
cat docs/references/examples/bash-command-validator.py
```

### 템플릿

```bash
# 모든 템플릿 보기
ls -R templates/

# 특정 템플릿 복사
cp templates/hooks/hook.py.template hooks/new-hook.py
```

---

## 7. 유용한 명령어

```bash
# 전체 구조 보기
tree -L 2 -I 'node_modules|.git'

# 레퍼런스 검색
grep -r "PreToolUse" docs/references/

# 템플릿 목록
find templates/ -name "*.template"

# 테스트 실행
npm test

# 검증
npm run validate
```

---

## 8. 도움말

### 더 알아보기

- **README.md**: 프로젝트 전체 개요
- **docs/**: 상세 문서
- **docs/references/**: 개발 패턴 및 예제
- **GitHub**: https://github.com/anthropics/claude-code

### 막힐 때

1. `docs/references/README.md`에서 관련 레퍼런스 찾기
2. `docs/workflows.md`에서 워크플로우 확인
3. 공식 예제 코드 분석
4. GitHub Issues 검색

---

## 9. 다음 단계

프로젝트 설정 완료! 이제:

1. **첫 번째 Hook 개발**: `docs/references/hooks/pretooluse-pattern.md` 참고
2. **첫 번째 Skill 개발**: `skills/README.md` 참고
3. **플러그인 패키징**: `docs/references/plugins/standard-structure.md` 참고

---

**Happy Coding! 🚀**
