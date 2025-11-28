# Claude Code 도구 생성 가이드

Claude Code 플러그인에서 사용할 수 있는 4가지 도구 타입과 생성 방법입니다.

## 도구 타입 선택

```
질문                              → 답변
───────────────────────────────────────────────
Claude가 자동으로 알아야 하는가?     → Skill
사용자가 명시적으로 호출하는가?       → Command
독립적인 작업 위임이 필요한가?        → Subagent
이벤트 발생 시 자동 실행되어야 하는가? → Hook
```

### 비교표

| 구분 | Skill | Command | Subagent | Hook |
|------|-------|---------|----------|------|
| **활성화** | 자동 (Claude 판단) | 수동 (`/command`) | Task 위임 | 이벤트 트리거 |
| **컨텍스트** | 공유 | 공유 | 격리 | 없음 |
| **도구 제한** | 불가 | 가능 | 가능 | N/A |
| **모델 선택** | 불가 | 가능 | 가능 | N/A |

---

## 1. Skill 생성

### 기본 구조

```
skills/my-skill/
├── SKILL.md           # 필수 (500줄 이하)
└── resources/         # 선택 (상세 내용)
```

### SKILL.md 템플릿

```yaml
---
name: my-skill
description: 언제 이 스킬이 활성화되어야 하는지 명확하게 기술
---

## 목적
간단한 설명

## 핵심 지침
1. 지침 1
2. 지침 2

## 참고 자료
상세 내용은 `resources/` 참조
```

### 필수 규칙

- **500줄 규칙**: SKILL.md는 500줄 이하
- **Progressive Disclosure**: 상세 내용은 resources/로 분리
- **명확한 description**: 트리거 키워드 포함

---

## 2. Command 생성

### 기본 구조

```
commands/my-command.md
```

### 템플릿

```yaml
---
description: 커맨드 설명
allowed-tools: Read, Edit, Bash(npm:*)
argument-hint: [arg1] [arg2]
---

$ARGUMENTS를 사용하여 작업 수행
$1은 첫 번째 인자
```

### 주요 설정

- `allowed-tools`: 허용할 도구 목록
- `argument-hint`: 인자 힌트 (`/command arg1 arg2`)
- `model`: 사용할 모델 (선택)

---

## 3. Subagent 생성

### 기본 구조

```
agents/my-agent.md
```

### 템플릿

```yaml
---
name: my-agent
description: 에이전트 역할 설명
model: sonnet
tools: Read, Grep, Glob
---

# 시스템 프롬프트

## 역할
당신은 [역할] 전문가입니다.

## 성공 기준
- [ ] 기준 1
- [ ] 기준 2

## 결과물
완료 후 반환할 내용
```

### 모델 선택 가이드

| 모델 | 용도 |
|------|------|
| `haiku` | 빠른 검색, 간단한 작업 |
| `sonnet` | 일반적인 작업 (기본값) |
| `opus` | 복잡한 분석, 아키텍처 설계 |

---

## 4. Hook 생성

### 기본 구조

```
hooks/
├── hooks.json         # 훅 등록
└── my-hook.py         # 훅 스크립트
```

### hooks.json

```json
{
  "hooks": {
    "UserPromptSubmit": [{
      "matcher": "",
      "hooks": [{
        "type": "command",
        "command": "${CLAUDE_PLUGIN_ROOT}/hooks/my-hook.py"
      }]
    }]
  }
}
```

### 이벤트 타입

| 이벤트 | 발생 시점 |
|--------|----------|
| `UserPromptSubmit` | 사용자 프롬프트 제출 시 |
| `PostToolUse` | 도구 사용 후 |
| `PreToolUse` | 도구 사용 전 |
| `Stop` | 응답 완료 시 |

### 훅 스크립트 (Python)

```python
#!/usr/bin/env python3
import sys
import json

input_data = json.loads(sys.stdin.read())
prompt = input_data.get("prompt", "")

# 처리 로직
result = {"message": "추가 컨텍스트"}

print(json.dumps(result))
sys.exit(0)  # 0: 성공, 1: 에러, 2: 블록
```

---

## skill-rules.json

스킬 자동 활성화를 위한 트리거 규칙입니다.

```json
{
  "skills": {
    "my-skill": {
      "type": "domain",
      "enforcement": "suggest",
      "priority": "high",
      "promptTriggers": {
        "keywords": ["keyword1", "keyword2"],
        "intentPatterns": ["regex pattern"]
      }
    }
  }
}
```

### 설정 옵션

| 필드 | 값 | 설명 |
|------|-----|------|
| `type` | domain, guideline, tool | 스킬 유형 |
| `enforcement` | suggest, warn, block | 강제 수준 |
| `priority` | critical, high, medium, low | 우선순위 |

---

## 체크리스트

### Skill 생성 시
- [ ] SKILL.md 500줄 이하
- [ ] description에 트리거 키워드 포함
- [ ] skill-rules.json에 등록

### Command 생성 시
- [ ] allowed-tools 최소화
- [ ] 인자 문법 올바름 ($1, $ARGUMENTS)

### Subagent 생성 시
- [ ] 필요한 컨텍스트 모두 제공
- [ ] tools 최소화
- [ ] 성공 기준 명확히 정의

### Hook 생성 시
- [ ] hooks.json에 등록
- [ ] 스크립트 실행 권한 설정
- [ ] exit code 올바르게 사용

---

## 참고 자료

- [Claude Code Skills 문서](https://docs.claude.com/en/docs/claude-code/skills)
- [Claude Code Hooks 문서](https://docs.claude.com/en/docs/claude-code/hooks)
- [Anthropic Skills 가이드](https://www.anthropic.com/engineering/agent-skills)
