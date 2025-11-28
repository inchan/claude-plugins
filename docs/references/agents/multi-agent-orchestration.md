# 다중 에이전트 오케스트레이션 패턴

> code-review 플러그인 기반 패턴

**출처**: https://github.com/anthropics/claude-code/tree/main/plugins/code-review

---

## 개요

여러 전문화된 에이전트를 병렬 또는 순차적으로 실행하여 복잡한 작업을 수행하는 패턴

### 핵심 원칙

1. **전문화**: 각 에이전트는 하나의 특정 역할
2. **독립성**: 에이전트 간 느슨한 결합
3. **조합**: 결과를 종합하여 최종 출력

---

## code-review 플러그인 사례

### 에이전트 구성 (4개)

| 에이전트 | 역할 | 책임 |
|---------|------|------|
| **CLAUDE.md Checker #1** | 규칙 준수 검사 | 프로젝트 규칙 검증 |
| **CLAUDE.md Checker #2** | 규칙 준수 검사 | 중복 검증 (교차 검증) |
| **Bug Detector** | 버그 탐지 | 잠재적 버그 식별 |
| **History Analyzer** | 히스토리 분석 | Git 히스토리 패턴 분석 |

### 실행 흐름

```
/code-review 호출
    ↓
┌───────────────────────────────────┐
│   에이전트 병렬 실행                │
├───────────────────────────────────┤
│ • CLAUDE.md Checker #1            │
│ • CLAUDE.md Checker #2            │
│ • Bug Detector                    │
│ • History Analyzer                │
└───────────────────────────────────┘
    ↓
┌───────────────────────────────────┐
│   결과 수집 및 종합                │
└───────────────────────────────────┘
    ↓
최종 리포트 생성
```

---

## 구현 패턴

### 1. 에이전트 정의

각 에이전트는 독립적인 Markdown 파일:

```markdown
# Bug Detector Agent

## Role
코드에서 잠재적 버그를 탐지하는 전문 에이전트

## Instructions
1. 코드 변경사항 분석
2. 일반적인 버그 패턴 검사
3. 보안 취약점 확인
4. 발견된 이슈 리포트

## Input
- PR diff
- 파일 목록
- 변경 사유

## Output
{
  "bugs": [...],
  "severity": "high|medium|low",
  "suggestions": [...]
}
```

### 2. 오케스트레이터 (커맨드)

`commands/code-review.md`:

```markdown
# /code-review

## Implementation

1. PR 정보 수집
2. 4개 에이전트 병렬 실행:
   - Task tool로 각 에이전트 호출
   - 병렬 실행으로 시간 단축
3. 결과 수집 대기
4. 결과 통합:
   - 중복 제거
   - 우선순위 정렬
   - 종합 리포트 생성
5. 출력
```

### 3. 에이전트 호출 (예상 코드)

```typescript
// 병렬 실행
const results = await Promise.all([
  callAgent('claude-md-checker-1', input),
  callAgent('claude-md-checker-2', input),
  callAgent('bug-detector', input),
  callAgent('history-analyzer', input)
]);

// 결과 통합
const report = aggregateResults(results);
```

---

## 에이전트 전문화 전략

### 역할 분리

**✓ Good**: 명확한 단일 책임
```
Bug Detector       → 버그만 탐지
Style Checker      → 스타일만 검사
Performance Analyzer → 성능만 분석
```

**✗ Bad**: 모호한 다중 책임
```
General Reviewer   → 모든 것 검사 (너무 광범위)
```

### 중복 검증 (Cross-Validation)

동일 역할의 에이전트 2개 실행하여 신뢰도 향상:

```
CLAUDE.md Checker #1 ─┐
                       ├─→ 교차 검증 → 높은 신뢰도
CLAUDE.md Checker #2 ─┘
```

---

## 결과 통합 전략

### 1. 병합 (Merge)

```python
def merge_results(results):
    combined = {
        "issues": [],
        "suggestions": []
    }

    for result in results:
        combined["issues"].extend(result.get("issues", []))
        combined["suggestions"].extend(result.get("suggestions", []))

    # 중복 제거
    combined["issues"] = deduplicate(combined["issues"])

    return combined
```

### 2. 우선순위 정렬

```python
def prioritize(issues):
    severity_order = {
        "critical": 0,
        "high": 1,
        "medium": 2,
        "low": 3
    }

    return sorted(issues, key=lambda x: severity_order.get(x["severity"], 99))
```

### 3. 투표 (Voting)

```python
def vote(results):
    """
    여러 에이전트가 동일한 이슈를 발견하면 신뢰도 증가
    """
    issue_counts = {}

    for result in results:
        for issue in result["issues"]:
            key = issue["id"]
            issue_counts[key] = issue_counts.get(key, 0) + 1

    # 2개 이상 에이전트가 발견한 이슈만 포함
    high_confidence = [
        issue for issue in all_issues
        if issue_counts.get(issue["id"], 0) >= 2
    ]

    return high_confidence
```

---

## 성능 최적화

### 병렬 실행

```python
# ✓ Good: 병렬 실행 (Task tool 활용)
async def run_parallel():
    tasks = [
        Task(subagent_type="agent1", ...),
        Task(subagent_type="agent2", ...),
        Task(subagent_type="agent3", ...),
    ]
    results = await asyncio.gather(*tasks)
    return results

# ✗ Bad: 순차 실행
def run_sequential():
    r1 = run_agent1()
    r2 = run_agent2()  # agent1 완료 대기
    r3 = run_agent3()  # agent2 완료 대기
    return [r1, r2, r3]
```

### 타임아웃 설정

```python
async def run_with_timeout(agent, timeout=30):
    try:
        return await asyncio.wait_for(
            run_agent(agent),
            timeout=timeout
        )
    except asyncio.TimeoutError:
        return {"error": "timeout", "agent": agent}
```

---

## 에러 처리

### Partial Failure 허용

```python
def handle_partial_failure(results):
    """
    일부 에이전트 실패해도 나머지 결과는 사용
    """
    successful = [r for r in results if not r.get("error")]
    failed = [r for r in results if r.get("error")]

    if failed:
        print(f"Warning: {len(failed)} agents failed")

    if not successful:
        raise Exception("All agents failed")

    return merge_results(successful)
```

---

## 실전 예제

### feature-dev 플러그인 (7단계)

```
1. Requirements Analyst  → 요구사항 분석
2. Architecture Designer → 아키텍처 설계
3. Code Implementer      → 코드 구현
4. Test Generator        → 테스트 생성
5. Code Reviewer         → 코드 리뷰
6. Doc Writer            → 문서 작성
7. Integration Tester    → 통합 테스트
```

**특징**: 순차 실행 (각 단계는 이전 결과 의존)

---

## 베스트 프랙티스

### ✓ Do

1. **명확한 인터페이스**: 입출력 형식 표준화
2. **독립적 에이전트**: 상태 공유 최소화
3. **에러 복원력**: 일부 실패 허용
4. **타임아웃 설정**: 무한 대기 방지

### ✗ Don't

1. **과도한 의존성**: 에이전트 간 강한 결합
2. **무한 재시도**: 실패 시 즉시 포기 또는 제한된 재시도
3. **동기 실행**: 병렬 가능한 작업을 순차 실행
4. **결과 무시**: 실패한 에이전트 결과도 로깅

---

## 관련 문서

- [Agent Template](../../../templates/agents/agent.md.template)
- [Agents README](../../../agents/README.md)

---

## 변경 이력

- **2025-11-28**: code-review 플러그인 기반 패턴 정리
