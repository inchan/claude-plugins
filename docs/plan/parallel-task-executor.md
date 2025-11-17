# Parallel-Task-Executor 스킬 개선 계획

**작성일**: 2025-11-16
**대상 스킬**: skills/parallel-task-executor/SKILL.md
**심각도**: Critical (구조적 재설계 필요)

---

## 1. 문제점 분석

### 1.1 핵심 문제점

**A. 대량의 미존재 스크립트 참조**
```
Line 331-343: scripts/executors/
- sectioning_executor.py (존재 안함)
- voting_executor.py (존재 안함)
- worker_pool.py (존재 안함)

Line 337-339: scripts/analyzers/
- dependency_analyzer.py (존재 안함)
- dag_builder.py (존재 안함)
- conflict_resolver.py (존재 안함)

Line 340-342: scripts/aggregators/
- code_merger.py (존재 안함)
- vote_aggregator.py (존재 안함)
- result_synthesizer.py (존재 안함)
```

- **문제**: 10개 이상의 Python 스크립트를 참조하지만 실제로 구현되지 않음
- **영향**: 스킬이 "자동화된 시스템"으로 보이지만 실제로는 문서에 불과
- **심각도**: Critical

**B. 과장된 성능 주장**
```
Line 20-22: "2-10x speedup"
Line 196: "Minimum workers: 2"
Line 197: "Maximum workers: 10"
Line 419: "Speedup: 3x (45 min → 15 min)"
```

- **문제**: 성능 수치가 검증되지 않은 주장
- **영향**: 비현실적 기대치 설정
- **심각도**: High

**C. Claude Code 기능을 넘어서는 주장**
```
Line 192-200: "Dynamic Worker Pool Management"
- Auto-scaling
- Resource monitoring
- Load balancing

Line 304-308: "Dynamic Scaling"
- CPU/memory usage tracking
- Real-time optimization
```

- **문제**: Claude Code는 이러한 시스템 레벨 기능을 제공하지 않음
- **현실**: Task 도구는 서브에이전트를 생성하지만, "동적 워커 풀 관리"는 없음
- **심각도**: High

**D. 미존재 설정 파일**
```
Line 355-381: config.json
{
  "parallelism": { ... },
  "timeouts": { ... },
  "retry": { ... }
}
```

- **문제**: 이 설정 파일이 실제로 존재하지 않고, 누가/어떻게 읽는지 불명확
- **심각도**: Medium

### 1.2 논리적 결함

1. **자동화 vs 개념적 가이드 혼란**
   - 스킬이 "자동 실행 시스템"처럼 기술되지만 실제로는 "개념적 프레임워크"
   - 사용자가 무엇을 직접 해야 하는지 불명확

2. **Task 도구와의 관계 모호**
   - Claude Code의 Task 도구는 서브에이전트 생성 가능
   - 하지만 "워커 풀", "DAG 실행", "자동 병합"은 구현되지 않음
   - 스킬이 Task 도구를 어떻게 활용하는지 구체적이지 않음

3. **의존성 분석 비현실적**
   - "Extract imports, build DAG, detect circular dependencies"
   - 이러한 분석이 자동으로 이루어지지 않음
   - Claude가 추론으로 할 수는 있지만, 자동화된 스크립트는 없음

4. **충돌 해결의 과도한 약속**
   - "Line-by-line merge with syntax validation"
   - 실제 구현 없이 git merge 수준의 기능을 약속

### 1.3 실제 Claude Code Task 도구 기능

**실제로 가능한 것**:
```javascript
// Task 도구로 병렬 에이전트 생성
<invoke tool="Task">
  <description>프론트엔드 컴포넌트 생성</description>
  <prompt>React 컴포넌트를 생성하세요...</prompt>
  <subagent_type>Explore</subagent_type>
</invoke>
```

**불가능한 것**:
- 동적 워커 수 조절 (미리 정의된 호출만 가능)
- 자동 리소스 모니터링
- 실시간 로드 밸런싱
- 자동 충돌 해결

---

## 2. 개선안

### 2.1 Option A: 정직한 개념적 가이드로 전환 (권장)

**접근법**: 자동화 주장 제거, Claude의 추론 능력에 기반한 가이드

```markdown
---
name: parallel-task-guide
description: Claude를 사용하여 독립적인 작업을 병렬로 실행하는 가이드. Task 도구를 활용한 실제 병렬화 패턴.
---

# 병렬 작업 실행 가이드

## 핵심 개념
Claude의 Task 도구를 사용하여 여러 서브에이전트를 동시에 실행합니다.

## 실제 사용 가능한 패턴

### 패턴 1: 단일 메시지에서 여러 Task 호출
```xml
<!-- 병렬로 3개의 에이전트 실행 -->
<invoke tool="Task">
  <description>프론트엔드 구현</description>
  <prompt>React 컴포넌트를 생성하세요</prompt>
  <subagent_type>general-purpose</subagent_type>
</invoke>

<invoke tool="Task">
  <description>백엔드 구현</description>
  <prompt>Express API를 생성하세요</prompt>
  <subagent_type>general-purpose</subagent_type>
</invoke>

<invoke tool="Task">
  <description>데이터베이스 스키마</description>
  <prompt>PostgreSQL 스키마를 설계하세요</prompt>
  <subagent_type>general-purpose</subagent_type>
</invoke>
```

### 패턴 2: Claude의 분석 기반 병렬화
1. 사용자가 작업 요청
2. Claude가 독립적인 부분을 식별 (수동 분석)
3. Task 도구로 병렬 실행
4. 결과를 Claude가 통합 (수동 병합)

## 제한사항 (정직한 명시)
- 워커 수는 Task 호출 수로 결정 (동적 스케일링 없음)
- 자동 충돌 해결 없음 (Claude가 수동으로 검토)
- 리소스 모니터링 없음
- 성능 향상은 작업에 따라 다름 (보장 없음)

## 언제 사용하는가?
- 명확히 독립적인 작업들 (다른 파일, 다른 모듈)
- 의존성이 없거나 최소인 경우
- 각 작업이 완전히 독립적으로 완료될 수 있을 때
```

**장점**:
- 정직하고 현실적
- Claude Code의 실제 기능에 기반
- 사용자 기대치 올바르게 설정

**단점**:
- "자동화된 시스템" 인상 사라짐
- 덜 인상적으로 보임

### 2.2 Option B: 핵심 스크립트 실제 구현

**접근법**: 언급된 스크립트 중 핵심만 실제로 구현

```markdown
## 실제 구현된 도구

### 1. dependency_analyzer.py (간단 버전)
```python
#!/usr/bin/env python3
import ast
import sys

def analyze_imports(file_path):
    with open(file_path, 'r') as f:
        tree = ast.parse(f.read())

    imports = []
    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            for alias in node.names:
                imports.append(alias.name)
        elif isinstance(node, ast.ImportFrom):
            imports.append(node.module)
    return imports

if __name__ == "__main__":
    print(analyze_imports(sys.argv[1]))
```

### 2. simple_merger.py (기본 버전)
```python
#!/usr/bin/env python3
def merge_files(files):
    """단순 파일 연결 (충돌 감지 없음)"""
    result = []
    for f in files:
        with open(f, 'r') as fp:
            result.append(fp.read())
    return '\n\n'.join(result)
```

### 제한사항
- 이것은 보조 도구일 뿐, 자동화 시스템이 아님
- Claude가 결과를 해석하고 결정을 내림
- 복잡한 충돌은 수동 해결 필요
```

**장점**:
- 일부 자동화 제공
- 참조된 스크립트가 실제로 존재
- 점진적 개선 가능

**단점**:
- 개발 노력 필요
- 유지보수 부담
- 완전한 시스템이 아님

### 2.3 Option C: Anthropic 패턴에 집중

**접근법**: 자동화 도구 대신 패턴과 원칙에 집중

```markdown
---
name: parallel-pattern-guide
description: Anthropic의 Parallelization 패턴을 Claude Code에서 적용하는 가이드
---

# Parallelization Pattern Guide

## Anthropic의 Parallelization 패턴이란?

"Building Effective Agents" 문서에서 정의된 패턴:
- **Sectioning**: 작업을 독립적인 섹션으로 분할
- **Voting**: 여러 접근법을 평가하고 최선을 선택

## Claude Code에서의 적용

### Sectioning 적용법

1. **작업 분해** (Claude의 추론)
   "이 작업에서 독립적으로 실행 가능한 부분은?"
   - 프론트엔드 vs 백엔드
   - 모듈 A vs 모듈 B
   - 테스트 스위트 분리

2. **병렬 실행** (Task 도구)
   - 각 섹션에 대해 Task 도구 호출
   - 단일 메시지에서 여러 호출로 병렬화

3. **결과 통합** (Claude의 추론)
   - 각 Task의 결과를 검토
   - 충돌 식별 및 해결
   - 최종 통합

### Voting 적용법

1. **대안 정의** (Claude의 추론)
   "이 문제를 해결하는 다른 방법들은?"

2. **병렬 구현** (Task 도구)
   - 각 접근법에 대해 Task 호출
   - 동일한 목표, 다른 방법

3. **평가 및 선택** (Claude의 추론)
   - 각 결과의 장단점 분석
   - 기준에 따라 최선 선택
   - 또는 하이브리드 생성

## 핵심 원칙
- 자동화 도구가 아닌 **사고 프레임워크**
- Claude의 추론이 핵심
- Task 도구는 실행 수단
```

**장점**:
- Anthropic 공식 패턴에 충실
- 개념적으로 명확
- 유지보수 부담 낮음

**단점**:
- 도구 제공 없음
- 추상적일 수 있음

### 2.4 권장 접근법: Option A + Option C 결합

**구성**:
1. **SKILL.md**: 정직한 개념적 가이드 (Option A)
2. **references/**: Anthropic 패턴 상세 설명 (Option C)
3. **examples/**: 실제 사용 예제 (검증된 것만)

**핵심 원칙**:
- 자동화 스크립트 참조 제거
- Claude의 추론 능력 활용 명시
- Task 도구의 실제 사용법 설명
- 과장된 성능 주장 제거

---

## 3. 검증 방법

### 3.1 현재 스킬의 문제 확인

```bash
#!/bin/bash
# verify_current_skill.sh

cd /home/user/cc-skills/skills/parallel-task-executor

echo "=== 미존재 스크립트 확인 ==="
for script in \
  "scripts/executors/sectioning_executor.py" \
  "scripts/analyzers/dependency_analyzer.py" \
  "scripts/aggregators/code_merger.py" \
  "config.json"; do
  if [ ! -f "$script" ]; then
    echo "❌ 미존재: $script"
  else
    echo "✅ 존재: $script"
  fi
done

echo "=== 참조 파일 확인 ==="
grep -r "scripts/" SKILL.md | head -20
```

예상 결과: 모든 스크립트 미존재

### 3.2 개선된 스킬 검증

**A. 정직성 검증**
```bash
# 모든 참조된 파일이 실제로 존재하는가?
grep -oE '\`[^`]+\.(py|sh|json)\`' SKILL.md | \
  sed 's/`//g' | \
  while read file; do
    if [ ! -f "$file" ] && [ ! -f "scripts/$file" ]; then
      echo "❌ 허위 참조: $file"
    fi
  done
```

**B. 실행 가능성 검증**
```bash
# 제시된 Task 도구 호출이 올바른 형식인가?
# Claude Code 문서와 대조 검증
```

**C. 주장 검증**
```bash
# 성능 주장에 "검증되지 않음" 또는 "예상치"가 명시되어 있는가?
grep -i "speedup\|performance\|x faster" SKILL.md | \
  grep -v "may\|expected\|estimated\|not guaranteed"
# 결과가 있으면 과장된 주장
```

### 3.3 사용자 경험 검증

| 테스트 | 방법 | 합격 기준 |
|--------|------|----------|
| 이해도 | 새 사용자에게 읽히기 | 5분 내 개념 파악 |
| 실행 가능성 | 예제 따라하기 | Task 도구 호출 성공 |
| 기대치 | 결과 예측 | 실제 결과와 일치 |
| 제한사항 인식 | 무엇이 안 되는지 이해 | 불가능한 요청 안 함 |

### 3.4 비교 검증

**개선 전후 비교표**:

| 항목 | 개선 전 | 개선 후 | 검증 방법 |
|------|---------|---------|-----------|
| 미존재 파일 참조 | 10+ | 0 | grep + file check |
| 과장된 성능 주장 | 5+ | 0 | 주장별 검증 |
| 실행 가능 예제 | 불확실 | 100% | 직접 실행 |
| Claude Code 기능 일치 | 30% | 95% | 공식 문서 대조 |

---

## 4. 실행 계획

### Phase 1: 문제 확인 및 백업 (1일)

**Day 1 작업**:
1. [ ] 현재 스킬의 모든 허위 참조 목록화
2. [ ] 과장된 주장 목록화
3. [ ] 기존 스킬 백업 (`parallel-task-executor.backup`)
4. [ ] Claude Code Task 도구 공식 문서 검토

**산출물**:
- 문제점 상세 목록
- 백업 파일
- Task 도구 실제 기능 정리

### Phase 2: 새 스킬 설계 (2일)

**Day 2 작업**:
1. [ ] 새 SKILL.md 구조 설계
2. [ ] Anthropic Parallelization 패턴 정리
3. [ ] Task 도구 실제 사용법 정리
4. [ ] 제거할 내용 결정 (스크립트 참조, 과장 주장)

**Day 3 작업**:
1. [ ] SKILL.md 초안 작성
2. [ ] 실제 사용 가능한 예제 3개 작성
3. [ ] 각 예제 Task 도구 호출 형식 검증
4. [ ] 제한사항 명시

**산출물**:
- 새 SKILL.md 초안
- 검증된 예제 3개
- 제한사항 문서

### Phase 3: 보조 자료 작성 (2일)

**Day 4 작업**:
1. [ ] references/ 디렉토리 정리
2. [ ] Anthropic 패턴 상세 문서 작성
3. [ ] Task 도구 사용 가이드 작성
4. [ ] 트러블슈팅 가이드 작성

**Day 5 작업**:
1. [ ] examples/ 디렉토리 검증
2. [ ] 각 예제의 실제 실행 결과 문서화
3. [ ] 성공/실패 시나리오 추가
4. [ ] 최종 검토

**산출물**:
- 정리된 references/
- 검증된 examples/
- 트러블슈팅 가이드

### Phase 4: 검증 (2일)

**Day 6 작업**:
1. [ ] 허위 참조 확인 스크립트 실행
2. [ ] 과장된 주장 확인
3. [ ] 예제 실행 테스트
4. [ ] 사용자 관점 검토

**Day 7 작업**:
1. [ ] 피드백 반영
2. [ ] 최종 문서 리뷰
3. [ ] 공식 문서와 대조 확인
4. [ ] 승인

**산출물**:
- 검증 보고서
- 최종 SKILL.md
- 승인 문서

### Phase 5: 배포 (1일)

**Day 8 작업**:
1. [ ] 새 스킬 배포
2. [ ] 관련 문서 업데이트 (CLAUDE.md)
3. [ ] skill-rules.json 업데이트
4. [ ] 마이그레이션 노트 작성

**산출물**:
- 배포된 스킬
- 업데이트된 문서
- 변경 로그

---

## 5. 자기비판 리뷰

### 5.1 개선안의 약점

**Option A (정직한 가이드)의 문제**:

1. **자동화 없음**
   - 사용자가 모든 것을 수동으로 해야 함
   - "병렬 실행 자동화 시스템"이라는 인상 사라짐
   - **개선**: 실용적 가치에 집중, 과대 포장 제거

2. **Task 도구 제한**
   - Claude Code의 Task 도구 자체가 제한적
   - "동적 워커 풀", "자동 스케일링" 불가능
   - **인정**: 현재 기술의 한계를 정직히 명시

3. **성능 예측 어려움**
   - "2-10x 속도 향상"을 보장할 수 없음
   - 실제 성능은 작업에 따라 크게 다름
   - **개선**: "성능은 작업에 따라 다름" 명시, 기대치 낮춤

### 5.2 더 깊은 문제: 병렬화의 실제 가치

**질문**: Claude Code에서 병렬화가 정말 의미 있는가?

**논거 1: 의미 있다**
- Task 도구로 실제 병렬 에이전트 생성 가능
- 독립적인 작업은 동시에 처리 가능
- 복잡한 프로젝트에서 시간 절약

**논거 2: 의미 없다**
- Claude 자체가 이미 효율적으로 작업 처리
- 서브에이전트 오버헤드 존재
- 컨텍스트 분리로 인한 품질 저하 가능

**결론**: 병렬화는 **특정 상황에서만** 가치 있음:
- 완전히 독립적인 작업
- 충분히 큰 작업 (오버헤드 상쇄)
- 명확한 분리 가능

### 5.3 검증 방법의 한계

1. **주관적 판단**
   - "정직한가?" "과장인가?"는 주관적
   - 명확한 기준 필요
   - **개선**: 체크리스트 기반 검증

2. **실제 성능 측정 어려움**
   - 병렬 실행의 실제 이점을 측정하기 어려움
   - 작업마다 다름
   - **개선**: 구체적인 벤치마크 사례 제시

3. **Task 도구 동작 불확실성**
   - Claude Code 업데이트로 동작 변경 가능
   - **개선**: 버전 명시, 정기 검토

### 5.4 근본적 질문

**이 스킬이 제공하는 실제 가치는 무엇인가?**

**현재 스킬의 주장**: "자동화된 병렬 실행 시스템"
**실제 가치**: "병렬화 개념 설명 + Task 도구 사용 가이드"

**차이**: 자동화 시스템이 아니라 개념적 프레임워크

**정직한 가치 제안**:
- Claude Code에서 병렬화를 언제/어떻게 사용할지 가이드
- Task 도구의 올바른 사용법
- Anthropic 패턴의 실제 적용

---

## 6. 성찰

### 6.1 원래 스킬의 근본적 오류

**"구현된 시스템"으로 보이려는 욕구**

원래 스킬 작성자는:
1. 인상적인 자동화 시스템을 만들고 싶었음
2. Python 스크립트, 설정 파일, 동적 스케일링 등을 언급
3. 하지만 실제로 구현하지 않음
4. "있는 것처럼" 문서화

이는 **허세(Facade)**의 전형입니다. 화려한 외관 뒤에 내용이 없습니다.

### 6.2 기술 문서의 윤리

**문서화는 거짓말하면 안 된다**

1. **존재하지 않는 것을 참조하지 않음**
   - "scripts/analyzer.py" → 파일이 없으면 언급하지 않음

2. **검증되지 않은 성능을 주장하지 않음**
   - "2-10x 속도 향상" → 측정되지 않았으면 말하지 않음

3. **불가능한 기능을 약속하지 않음**
   - "동적 워커 풀 관리" → Claude Code가 못 하면 쓰지 않음

### 6.3 워크플로우 스킬 전체의 문제

이 스킬의 문제는 다른 워크플로우 스킬에도 적용됩니다:

- **agent-workflow-manager**: 미존재 메시지 큐 참조
- **intelligent-task-router**: 미구현 classifier 참조
- **dynamic-task-orchestrator**: 미존재 워커 스크립트 참조

**공통 패턴**: "이론적으로 가능한 것"을 "구현된 것"으로 포장

### 6.4 교훈

1. **정직함이 최고의 전략**
   - 할 수 없는 것을 인정하는 것이 나음
   - 과장된 주장보다 제한된 기능이 더 신뢰받음
   - 사용자는 속임수를 알아챔

2. **개념과 구현의 명확한 구분**
   - "이것이 개념입니다" vs "이것이 작동하는 시스템입니다"
   - 둘을 혼동하지 않음
   - 현재 상태를 명확히 명시

3. **점진적 개선**
   - 완벽한 시스템을 바로 만들 필요 없음
   - 기본 기능부터 시작
   - 검증된 것만 추가

### 6.5 향후 워크플로우 스킬 지침

**반드시 포함해야 할 것**:
1. Claude Code의 실제 기능에 기반한 설명
2. 검증된 예제 (직접 실행해본 것)
3. 명확한 제한사항
4. "개념"인지 "구현"인지 명시

**피해야 할 것**:
1. 미구현 스크립트 참조
2. 검증되지 않은 성능 주장
3. Claude Code가 제공하지 않는 기능 약속
4. "자동화"라는 과장된 표현

### 6.6 최종 권고

**단기**:
- 현재 스킬에 "EXPERIMENTAL - 스크립트 미구현" 경고 추가
- 과장된 성능 주장에 "예상치, 검증되지 않음" 표시

**중기**:
- 정직한 개념적 가이드로 재작성
- 미존재 스크립트 참조 모두 제거
- Task 도구의 실제 사용법에 집중

**장기**:
- 워크플로우 스킬 전체 아키텍처 재검토
- "개념적 가이드" vs "자동화 시스템" 명확히 분리
- 실제로 구현된 기능만 문서화

---

## 7. 성공 지표

### 정량적 지표
- 미존재 파일 참조: 0개
- 과장된 성능 주장: 0개 (모두 "예상치" 표시)
- 검증된 예제: 100% 실행 가능
- Claude Code 공식 기능과 일치: 95% 이상

### 정성적 지표
- 사용자가 실제 기능을 정확히 이해
- 기대치와 실제 결과 일치
- "속았다"는 느낌 없음
- 실제로 유용한 가이드 제공

---

**결론**: parallel-task-executor는 "화려한 허세"의 전형입니다. 10개 이상의 미존재 스크립트를 참조하고, 검증되지 않은 성능을 주장하며, Claude Code가 제공하지 않는 기능을 약속합니다. 이 스킬은 "구현된 시스템"이 아니라 "개념적 프레임워크"로 정직하게 재정의되어야 합니다. Anthropic의 Parallelization 패턴은 가치 있지만, 그것을 과장하여 "자동화된 시스템"으로 포장하는 것은 사용자를 오도합니다.
