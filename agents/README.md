# Agents (서브에이전트)

> 특화된 작업을 수행하는 독립적 에이전트

---

## 디렉토리 구조

```
agents/
└── {agent-name}.md   # 에이전트 프롬프트
```

---

## 에이전트 생성 가이드

### 1. 에이전트 파일 생성

```bash
touch agents/{agent-name}.md
```

### 2. 에이전트 프롬프트 작성

**기본 구조**:
```markdown
# {Agent Name}

## Role
이 에이전트의 역할과 책임

## Context
에이전트가 동작하는 맥락

## Instructions
1. 수행할 작업 1
2. 수행할 작업 2
3. ...

## Input Format
- 입력 형식 정의
- 예시

## Output Format
- 출력 형식 정의
- 예시

## Examples
### Example 1
Input: ...
Output: ...

## Dependencies
- 의존하는 다른 에이전트
- 필요한 도구/리소스
```

### 3. 에이전트 호출 방법

**Task tool 사용**:
```typescript
Task({
  subagent_type: "your-agent-name",
  prompt: "작업 설명"
})
```

---

## 에이전트 유형

| 유형 | 역할 | 예시 |
|------|------|------|
| **Researcher** | 조사 및 정보 수집 | 공식 문서 조사 |
| **Architect** | 설계 및 구조 결정 | 시스템 아키텍처 설계 |
| **Implementer** | 구현 및 코드 작성 | 기능 개발 |
| **Reviewer** | 리뷰 및 품질 검증 | 코드 리뷰, 테스트 |
| **Debugger** | 디버깅 및 문제 해결 | 버그 수정 |

---

## 체크리스트

에이전트 개발 전 확인:
- [ ] 역할과 책임 명확히 정의
- [ ] 입출력 형식 문서화
- [ ] 예시 3개 이상 포함
- [ ] 다른 에이전트와의 의존성 명시
- [ ] 테스트 시나리오 작성

---

## 베스트 프랙티스

### 1. 단일 책임 원칙
- 하나의 에이전트는 하나의 명확한 역할
- 복잡한 작업은 여러 에이전트로 분리

### 2. 명확한 인터페이스
- 입력/출력 형식 엄격히 정의
- 예상 가능한 동작

### 3. 독립성
- 다른 에이전트에 과도한 의존 지양
- 필요한 경우 의존성 명시

---

## 참고 자료

- [Tool Creation Guide](../docs/guidelines/tool-creation.md)
- [Sub-agents 공식 문서](https://docs.anthropic.com/claude-code/agents)

---

## 변경 이력

- **2025-11-28**: agents 디렉토리 생성
