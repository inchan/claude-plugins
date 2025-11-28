# References (레퍼런스 모음)

> 공식 예제 기반 개발 참고 자료

**목적**: Skills, Hooks, Agents, Commands 개발 시 빠르게 참고할 수 있는 패턴과 예제 제공

---

## 디렉토리 구조

```
references/
├── hooks/              # 훅 패턴 및 예제
│   ├── pretooluse-pattern.md
│   └── event-types.md
├── plugins/            # 플러그인 구조 가이드
│   └── standard-structure.md
├── agents/             # 에이전트 패턴
│   └── multi-agent-orchestration.md
├── commands/           # 커맨드 패턴
│   └── slash-command-pattern.md
├── examples/           # 공식 예제 코드
│   └── bash-command-validator.py
└── README.md           # 이 파일
```

---

## 빠른 참조

### 새로운 Hook 개발 시

1. [PreToolUse Pattern](./hooks/pretooluse-pattern.md) 읽기
2. [Event Types](./hooks/event-types.md)에서 이벤트 확인
3. [공식 예제 코드](./examples/bash-command-validator.py) 참고
4. [Hook Template](../../templates/hooks/hook.py.template) 사용

### 새로운 Agent 개발 시

1. [Multi-Agent Orchestration](./agents/multi-agent-orchestration.md) 패턴 학습
2. [Agent Template](../../templates/agents/agent.md.template) 사용
3. code-review 플러그인 구조 참고

### 새로운 Command 개발 시

1. [Slash Command Pattern](./commands/slash-command-pattern.md) 읽기
2. [Command Template](../../templates/commands/command.md.template) 사용
3. 파라미터 처리 패턴 참고

### 새로운 Plugin 개발 시

1. [Standard Structure](./plugins/standard-structure.md) 확인
2. 공식 구조 준수
3. plugin.json 작성

---

## 레퍼런스별 요약

### Hooks

| 문서 | 내용 | 언제 보기 |
|------|------|-----------|
| [pretooluse-pattern.md](./hooks/pretooluse-pattern.md) | PreToolUse 훅 구현 패턴 | 훅 개발 전 필수 |
| [event-types.md](./hooks/event-types.md) | 지원 이벤트 타입 목록 | 이벤트 선택 시 |

**핵심 포인트**:
- 종료 코드: 0(통과), 1(에러), 2(차단)
- stdin으로 JSON 입력
- stderr로 메시지 출력

### Plugins

| 문서 | 내용 | 언제 보기 |
|------|------|-----------|
| [standard-structure.md](./plugins/standard-structure.md) | 공식 플러그인 구조 | 플러그인 시작 전 |

**핵심 포인트**:
- `.claude-plugin/plugin.json` 필수
- commands/, agents/, skills/, hooks/ 선택
- README.md 필수

### Agents

| 문서 | 내용 | 언제 보기 |
|------|------|-----------|
| [multi-agent-orchestration.md](./agents/multi-agent-orchestration.md) | 다중 에이전트 패턴 | 복잡한 작업 분해 시 |

**핵심 포인트**:
- 각 에이전트는 단일 책임
- 병렬 실행으로 성능 향상
- 결과 통합 전략 (병합, 투표, 우선순위)

### Commands

| 문서 | 내용 | 언제 보기 |
|------|------|-----------|
| [slash-command-pattern.md](./commands/slash-command-pattern.md) | 슬래시 커맨드 구조 | 커맨드 개발 전 |

**핵심 포인트**:
- Markdown 파일로 정의
- Implementation 섹션에 단계별 작업
- 예제 필수 포함

### Examples

| 파일 | 설명 | 언제 보기 |
|------|------|-----------|
| [bash-command-validator.py](./examples/bash-command-validator.py) | 공식 PreToolUse 예제 | 훅 구현 시 참고 |

---

## 사용 워크플로우

### 1. 요구사항 확인

```
docs/requirements.md 읽기
    ↓
개발 대상 결정 (Skill/Hook/Agent/Command)
```

### 2. 레퍼런스 선택

```
references/{타입}/README.md 확인
    ↓
관련 패턴 문서 읽기
    ↓
공식 예제 코드 분석
```

### 3. 템플릿 활용

```
templates/{타입}/ 에서 템플릿 복사
    ↓
레퍼런스 패턴 적용
    ↓
구현
```

### 4. 검증

```
베스트 프랙티스 체크
    ↓
테스트 작성
    ↓
문서화
```

---

## 공식 소스 링크

### GitHub 저장소
- **메인**: https://github.com/anthropics/claude-code
- **Plugins**: https://github.com/anthropics/claude-code/tree/main/plugins
- **Examples**: https://github.com/anthropics/claude-code/tree/main/examples

### 공식 문서
- **Overview**: https://docs.anthropic.com/en/docs/claude-code/overview
- **Data Usage**: https://docs.anthropic.com/en/docs/claude-code/data-usage

---

## 레퍼런스 업데이트 정책

### 언제 업데이트하는가?

1. **공식 예제 추가**: 새로운 공식 예제 발견 시
2. **패턴 발견**: 커뮤니티에서 검증된 새 패턴
3. **공식 문서 변경**: Anthropic 공식 문서 업데이트 시
4. **버그 수정**: 기존 레퍼런스 오류 발견 시

### 업데이트 프로세스

1. `docs/research/` 에 조사 결과 추가
2. `references/` 해당 섹션 업데이트
3. 변경 이력 기록
4. `instruction.md`에 출처 명시

---

## 기여 가이드

### 새로운 레퍼런스 추가

1. **공식 소스 확인**: Anthropic 공식 자료에 근거
2. **패턴 추출**: 재사용 가능한 패턴으로 정리
3. **예제 포함**: 실제 코드 스니펫 제공
4. **베스트 프랙티스**: ✓ Do / ✗ Don't 명시

### 파일 명명 규칙

- 소문자 + 하이픈: `multi-agent-orchestration.md`
- 명확한 이름: `pretooluse-pattern.md` (O), `hook1.md` (X)
- 카테고리별 분류: `hooks/`, `agents/`, `commands/`

---

## 관련 문서

- [공식 소스 조사 결과](../research/official-sources-research.md)
- [Requirements](../requirements.md)
- [Workflows](../workflows.md)
- [Templates](../../templates/)

---

## 변경 이력

- **2025-11-28**: 초기 레퍼런스 구조 생성
- **2025-11-28**: 공식 예제 기반 4개 카테고리 레퍼런스 작성
