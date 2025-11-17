# Codex 스킬 개선 계획

**작성일**: 2025-11-16
**대상 스킬**: skills/codex/skill.md
**심각도**: Critical (최우선 개선 필요)

---

## 1. 문제점 분석

### 1.1 핵심 문제점

**A. 존재하지 않는 모델명 참조**
```
Line 9: 모델 선택: `gpt-5` or `gpt-5-codex`
```
- **문제**: GPT-5는 2025년 11월 현재 존재하지 않는 모델
- **영향**: 사용자가 실행 시 즉시 실패, 신뢰성 완전 상실
- **심각도**: Critical

**B. 미검증 CLI 옵션**
```
Line 14: --config model_reasoning_effort="<low|medium|high>"
Line 15: --sandbox <read-only|workspace-write|danger-full-access>
Line 17: -C, --cd <DIR>
```
- **문제**: OpenAI Codex CLI가 실제로 이러한 옵션을 지원하는지 검증 안됨
- **영향**: 실행 불가능한 명령어 제공
- **심각도**: High

**C. Codex CLI 존재 자체가 불확실**
- OpenAI가 공식적으로 "Codex CLI"를 배포하는지 확인 필요
- GitHub Copilot CLI와 혼동 가능성

### 1.2 논리적 결함

1. **검증 없는 기술**: CLI 버전, 설치 방법, 호환성 정보 없음
2. **에러 처리 부실**: 실제 CLI가 없을 때의 대응책 없음
3. **대안 부재**: CLI가 없을 경우의 대체 방안 제시 없음

### 1.3 실용성 평가

| 항목 | 현재 상태 | 개선 필요 |
|------|----------|----------|
| 실행 가능성 | 0% (모델 미존재) | 100% |
| 정보 정확성 | 10% (일부 개념만 맞음) | 95% |
| 사용자 가치 | 0% (사용 불가) | 80%+ |

---

## 2. 개선안

### 2.1 Option A: 완전 재작성 (권장)

**접근법**: 실제 사용 가능한 OpenAI API 기반 스킬로 전환

```markdown
---
name: openai-code-assistant
description: OpenAI API를 활용한 코드 분석 및 생성. GPT-4, GPT-4-turbo 등 실제 모델 사용
---

# OpenAI Code Assistant

## 핵심 기능
1. OpenAI API를 통한 코드 분석
2. 코드 리뷰 및 개선 제안
3. 코드 생성 및 리팩토링 지원

## 사용 방법
1. API 키 설정 확인 (OPENAI_API_KEY 환경변수)
2. 모델 선택: gpt-4, gpt-4-turbo, gpt-3.5-turbo
3. 컨텍스트 길이에 따른 모델 자동 선택

## 실제 구현
- curl 기반 API 호출
- 또는 openai CLI (pip install openai)
```

**장점**:
- 실제 사용 가능한 도구 기반
- 검증된 API 문서화
- 실용적 가치 제공

**단점**:
- 스킬 이름 변경 필요
- 기존 스킬과의 호환성 없음

### 2.2 Option B: GitHub Copilot CLI 기반 전환

**접근법**: 실제 존재하는 Copilot CLI 사용

```markdown
---
name: copilot-cli
description: GitHub Copilot CLI를 사용한 코드 생성 및 분석
---

# GitHub Copilot CLI Skill

## 전제조건
- GitHub Copilot 구독
- gh copilot extension 설치: `gh extension install github/gh-copilot`

## 사용 가능한 명령어
- `gh copilot suggest` - 코드 제안
- `gh copilot explain` - 코드 설명
```

**장점**:
- 실제 존재하는 도구
- GitHub 생태계 통합
- 검증된 명령어 옵션

**단점**:
- 구독 필요
- 원래 의도(Codex)와 다름

### 2.3 Option C: 스킬 제거 (최소 접근)

**접근법**: 허위 정보 제공보다 스킬 제거가 나음

```bash
rm -rf skills/codex/
```

**장점**:
- 허위 정보 제거
- 유지보수 부담 제거

**단점**:
- 기능 완전 상실
- AI 연동이라는 컨셉 자체 폐기

### 2.4 권장 접근법: Option A + 명확한 전제조건

```markdown
---
name: openai-assistant
description: OpenAI API를 통한 코드 분석 및 생성 지원. 실제 사용 가능한 모델(GPT-4, GPT-4-turbo) 기반.
---

# OpenAI Assistant Skill

## 전제조건 (반드시 확인)
1. OpenAI API 키 설정: `export OPENAI_API_KEY="your-key"`
2. openai CLI 설치 (선택): `pip install openai`
3. 사용량 및 비용 인지

## 지원 모델 (2025년 기준)
- gpt-4-turbo-preview (최신, 128k context)
- gpt-4 (안정적, 8k context)
- gpt-3.5-turbo (빠름, 저렴함)

## 사용 패턴

### 패턴 1: curl 기반 직접 호출
```bash
curl https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4-turbo-preview",
    "messages": [{"role": "user", "content": "코드 분석: ..."}]
  }'
```

### 패턴 2: Python openai 라이브러리
```python
from openai import OpenAI
client = OpenAI()
response = client.chat.completions.create(
    model="gpt-4-turbo-preview",
    messages=[{"role": "user", "content": "..."}]
)
```

## 제한사항 (정직한 명시)
- API 비용 발생 (토큰당 과금)
- 네트워크 연결 필요
- Rate limit 존재
- OpenAI 서비스 가용성에 의존
```

---

## 3. 검증 방법

### 3.1 기술적 검증

**A. 모델 존재 확인**
```bash
# OpenAI API로 사용 가능한 모델 목록 조회
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  | jq '.data[].id' | grep -E 'gpt-4|gpt-3.5'
```

**B. CLI 설치 가능성 확인**
```bash
# OpenAI Python 패키지 확인
pip index versions openai

# GitHub Copilot CLI 확인
gh extension list | grep copilot
```

**C. 명령어 옵션 검증**
```bash
# 실제 도움말 확인
openai --help
gh copilot --help
```

### 3.2 사용자 검증

1. **설치 가능성**: 신규 사용자가 5분 내 설정 완료 가능?
2. **실행 성공률**: 제시된 명령어 100% 실행 가능?
3. **결과 예측성**: 예상 출력과 실제 출력 일치?

### 3.3 문서 검증

| 검증 항목 | 방법 | 합격 기준 |
|-----------|------|-----------|
| 모델명 정확성 | OpenAI 공식 문서 대조 | 100% 일치 |
| CLI 옵션 정확성 | --help 출력과 대조 | 100% 일치 |
| 설치 가이드 | 클린 환경에서 테스트 | 성공률 100% |
| 에러 처리 | 실패 시나리오 테스트 | 모든 케이스 커버 |

### 3.4 자동화된 검증 스크립트

```bash
#!/bin/bash
# verify_openai_skill.sh

echo "=== OpenAI Skill 검증 ==="

# 1. API 키 확인
if [ -z "$OPENAI_API_KEY" ]; then
    echo "❌ OPENAI_API_KEY 환경변수 미설정"
    exit 1
fi
echo "✅ API 키 설정됨"

# 2. 모델 목록 확인
MODELS=$(curl -s https://api.openai.com/v1/models \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  | jq -r '.data[].id' | grep -E '^gpt-(4|3.5)')

if echo "$MODELS" | grep -q "gpt-4"; then
    echo "✅ GPT-4 모델 사용 가능"
else
    echo "❌ GPT-4 모델 접근 불가"
fi

# 3. 실제 API 호출 테스트
RESPONSE=$(curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model": "gpt-3.5-turbo", "messages": [{"role": "user", "content": "Say test"}], "max_tokens": 10}')

if echo "$RESPONSE" | grep -q "choices"; then
    echo "✅ API 호출 성공"
else
    echo "❌ API 호출 실패: $RESPONSE"
fi

echo "=== 검증 완료 ==="
```

---

## 4. 실행 계획

### Phase 1: 사전 조사 (1일)

**Day 1 작업**:
1. [ ] OpenAI 공식 문서에서 최신 모델 목록 확인
2. [ ] 실제 사용 가능한 CLI 도구 조사 (openai-python, gh copilot)
3. [ ] 각 도구의 설치 방법 및 사용법 검증
4. [ ] 대안 도구 비교표 작성

**산출물**:
- 최신 모델 목록 (공식 문서 링크 포함)
- 사용 가능 CLI 도구 목록
- 도구별 장단점 비교표

### Phase 2: 스킬 재설계 (2일)

**Day 2 작업**:
1. [ ] 새로운 스킬 이름 확정 (openai-assistant 또는 유지)
2. [ ] SKILL.md 구조 설계
3. [ ] 핵심 사용 시나리오 3가지 정의
4. [ ] 에러 처리 시나리오 정의

**Day 3 작업**:
1. [ ] SKILL.md 초안 작성
2. [ ] 모든 코드 예제 실제 실행 검증
3. [ ] 전제조건 명확히 문서화
4. [ ] 제한사항 정직하게 명시

**산출물**:
- 새로운 SKILL.md 초안
- 검증된 코드 예제 모음
- 설치 가이드

### Phase 3: 검증 및 테스트 (2일)

**Day 4 작업**:
1. [ ] 클린 환경에서 설치 테스트
2. [ ] 모든 코드 예제 실행
3. [ ] 에러 케이스 테스트
4. [ ] 검증 스크립트 실행

**Day 5 작업**:
1. [ ] 피드백 기반 수정
2. [ ] 최종 검증 수행
3. [ ] 문서 리뷰
4. [ ] 승인 및 배포

**산출물**:
- 검증 완료된 SKILL.md
- 테스트 결과 보고서
- 검증 스크립트

### Phase 4: 배포 및 정리 (1일)

**Day 6 작업**:
1. [ ] 기존 skills/codex/ 백업
2. [ ] 새 스킬 배포
3. [ ] skill-rules.json 업데이트 (필요시)
4. [ ] 문서 업데이트 (CLAUDE.md, README 등)

**산출물**:
- 배포된 새 스킬
- 업데이트된 문서
- 마이그레이션 가이드

---

## 5. 자기비판 리뷰

### 5.1 개선안의 약점

**Option A (OpenAI API 기반) 비판**:

1. **비용 문제 미해결**
   - API 호출마다 비용 발생
   - 스킬이 "무료로 사용 가능"하다는 착각 유발 가능
   - **개선**: 비용 추정 섹션 추가, 예산 관리 가이드 포함

2. **네트워크 의존성**
   - 오프라인 환경에서 사용 불가
   - 네트워크 지연 시 성능 저하
   - **개선**: 오프라인 대안(로컬 모델) 언급

3. **복잡성 증가**
   - 원래 "간단한 CLI 실행"에서 "API 호출"로 복잡도 상승
   - 사용자 진입 장벽 높아짐
   - **개선**: 단계별 가이드, 복사-붙여넣기 가능한 예제

4. **OpenAI 서비스 의존**
   - 서비스 중단 시 스킬 무용지물
   - API 변경 시 업데이트 필요
   - **개선**: 버전 호환성 테스트, 변경 모니터링 계획

### 5.2 검증 방법의 한계

1. **일회성 검증**
   - 검증 시점에만 유효, 시간 지나면 무효화 가능
   - **개선**: 정기 검증 스케줄 (월 1회)

2. **환경 특정성**
   - 특정 OS/버전에서만 테스트
   - **개선**: 다중 환경 테스트 (Mac, Linux, Windows)

3. **사용자 시나리오 부족**
   - 개발자 관점에서만 검증
   - **개선**: 실제 사용자 피드백 수집

### 5.3 실행 계획의 리스크

| 리스크 | 확률 | 영향 | 대응 |
|--------|------|------|------|
| OpenAI API 변경 | 중간 | 높음 | 버전 고정, 정기 업데이트 |
| 예상보다 복잡 | 높음 | 중간 | 버퍼 시간 포함 (1-2일) |
| 사용자 채택 저조 | 중간 | 중간 | 상세한 마이그레이션 가이드 |
| 비용 우려 | 높음 | 중간 | 무료 대안(GPT-3.5) 강조 |

---

## 6. 성찰

### 6.1 근본 원인 분석

**왜 이런 문제가 발생했는가?**

1. **희망적 사고(Wishful Thinking)**
   - "Codex CLI가 있을 것이다"라는 가정
   - "GPT-5가 곧 나올 것이다"라는 추측
   - 검증 없이 문서 작성

2. **기술 마케팅의 영향**
   - "Codex"라는 브랜드에 대한 과도한 기대
   - 실제 제품과 발표된 개념의 혼동

3. **문서화 문화의 부재**
   - "작동하는 것만 문서화"가 아닌 "작동했으면 하는 것 문서화"
   - 검증 프로세스 없이 배포

### 6.2 교훈

1. **진실성이 최우선**
   - 허위 정보는 신뢰를 완전히 파괴
   - "모른다"고 인정하는 것이 거짓말보다 나음
   - 검증 없이는 문서화하지 않음

2. **실용성 > 이론**
   - 이론적으로 가능한 것보다 실제로 사용 가능한 것
   - 사용자가 즉시 실행할 수 있어야 함
   - 추상적 개념보다 구체적 명령어

3. **지속적 검증**
   - 한 번 검증으로 끝이 아님
   - 기술은 변화하고, 문서도 업데이트 필요
   - 검증 자동화 도입 필요

### 6.3 향후 지침

**스킬 작성 시 반드시 확인할 체크리스트**:

- [ ] 참조하는 모든 도구가 실제로 존재하는가?
- [ ] 모든 명령어를 직접 실행해 보았는가?
- [ ] 설치 가이드를 클린 환경에서 테스트했는가?
- [ ] 버전 정보가 정확한가?
- [ ] 제한사항을 정직하게 명시했는가?
- [ ] 에러 발생 시 대응책이 있는가?

### 6.4 더 넓은 시야

이 스킬의 문제는 "AI 연동 스킬" 카테고리 전체의 문제를 반영합니다:

- **codex-claude-loop**: 동일한 GPT-5 허위 참조
- **qwen-claude-loop**: 미검증 CLI 참조
- **codex**: 근본적으로 존재하지 않는 도구 기반

이는 "있었으면 좋겠는 도구"를 "있는 도구"로 착각한 결과입니다. 근본적으로 AI 연동 스킬들은 전면 재검토가 필요합니다.

### 6.5 최종 권고

**단기 (즉시)**:
- codex 스킬을 "deprecated" 또는 "experimental" 태그 부착
- 사용자에게 현재 상태(미검증)를 명확히 고지

**중기 (1주)**:
- 실제 사용 가능한 도구로 대체 (OpenAI API, GitHub Copilot CLI)
- 검증된 문서로 재작성

**장기 (1개월)**:
- AI 연동 스킬 전체 재설계
- 검증 프로세스 의무화
- 정기 업데이트 체계 구축

---

## 7. 성공 지표

### 정량적 지표
- 모든 코드 예제 실행 성공률: 100%
- 설치 가이드 성공률: 95% 이상
- 문서 내 허위 정보: 0개

### 정성적 지표
- 사용자가 5분 내 시작 가능
- 실패 시 명확한 에러 메시지
- 대안 경로 제공

---

**결론**: codex 스킬은 "거짓말하는 스킬"입니다. 존재하지 않는 모델과 미검증 도구를 참조하여 사용자를 오도합니다. 이는 단순한 버그가 아니라 근본적인 신뢰성 문제입니다. 완전한 재작성 또는 제거가 필요하며, 재작성 시에는 반드시 검증된 정보만을 포함해야 합니다.
