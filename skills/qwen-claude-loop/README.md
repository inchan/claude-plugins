# Qwen-Claude Loop 스킬 사용법

## 🔄 역할 분담 (Reversed Roles)

- **Claude Code**: 계획 수립, 코드 리뷰, 품질 검증, 최종 배포
- **Qwen**: 코드 구현 및 작성

## 기본 사용 시나리오

### 1️⃣ 새로운 기능 개발

```
👤 사용자: "로그인 기능을 OAuth 2.0으로 구현해줘"

🤖 Claude:
[먼저 상세한 계획을 세움]
"다음과 같이 구현 계획을 세웠습니다:
- OAuth 2.0 플로우 설계
- 보안 토큰 관리 방식
- CSRF 토큰 검증
- Refresh token 로테이션
- 에러 핸들링 전략

이제 Qwen에게 구현을 요청하겠습니다."
- 구현 스타일을 선택해주세요: concise / standard / detailed

👤 사용자: "detailed"

🤖 Claude:
[Qwen에게 구현 요청]
$ echo "Implement OAuth 2.0 login with these specifications..." | qwen -p

[Qwen의 구현 결과 받음]
"Qwen이 다음 파일들을 구현했습니다:
- auth/oauth.js (143 lines)
- middleware/csrf.js (45 lines)
- utils/tokenManager.js (89 lines)

이제 코드를 리뷰하겠습니다..."

[Claude의 코드 리뷰]
"코드 리뷰 결과:
✅ OAuth 플로우 구현 - 우수
✅ 토큰 관리 로직 - 양호
⚠️ 에러 핸들링 개선 필요 - 일부 edge case 미처리
🔴 보안 이슈 - XSS 방어 코드 누락

어떻게 할까요?"
1. Qwen에게 수정 요청
2. 제가 직접 수정

👤 사용자: "너가 직접 수정해줘"

🤖 Claude:
[Claude가 이슈 수정]
- Edit/Write 도구로 보안 코드 추가
- 에러 핸들링 강화
- XSS 방어 로직 추가

"수정 완료! 최종 검증 후 파일에 적용하겠습니다"
[파일 배포 완료]
```

### 2️⃣ 코드 리팩토링

```
👤 사용자: "이 코드를 리팩토링해줘"

🤖 Claude:
[먼저 코드 분석 및 리팩토링 계획 수립]
"다음과 같이 개선하겠습니다:
- 중복 코드 제거
- 함수 분리로 가독성 향상
- 성능 최적화
- 에러 핸들링 강화

Qwen에게 리팩토링 구현을 요청하겠습니다"

[Qwen에게 구현 요청]
$ echo "Refactor this code based on the plan..." | qwen -p

[Qwen의 리팩토링 결과]
"Qwen이 코드를 다음과 같이 개선했습니다:
- 5개 함수로 모듈화
- 중복 코드 40% 감소
- 성능 20% 향상

이제 리뷰하겠습니다..."

[Claude의 리뷰]
"리뷰 결과:
✅ 모듈화 - 훌륭함
✅ 코드 중복 제거 - 우수
⚠️ 일부 함수 네이밍 개선 필요
💡 타입 체크 추가 제안

제가 직접 개선사항을 적용하겠습니다"

[Claude가 최종 수정 및 배포]
```

### 3️⃣ 버그 수정

```
👤 사용자: "이 버그를 고쳐줘 (에러 로그 첨부)"

🤖 Claude:
[버그 분석 및 수정 계획 수립]
"버그 원인을 분석했습니다:
- Null pointer exception
- 비동기 처리 순서 문제
- 에러 핸들링 누락

수정 계획을 세우고 Qwen에게 구현을 요청하겠습니다"

[Qwen에게 버그 수정 요청]
$ echo "Fix this bug based on analysis..." | qwen -p

[Qwen의 수정 결과]
"Qwen이 다음과 같이 수정했습니다:
- Null 체크 추가
- async/await 순서 조정
- try-catch 블록 추가

이제 리뷰하겠습니다..."

[Claude의 검증]
"✅ 버그 수정 확인됨
✅ 에러 핸들링 적절함
💡 추가 테스트 케이스 필요

파일에 적용하겠습니다"

[Claude가 최종 배포]
```

## 주요 명령어 패턴

### 1. 계획 수립 (Claude)
Claude가 상세한 구현 계획을 작성

### 2. 구현 요청 (Qwen)
```bash
echo "Implement this plan: [상세 계획]" | qwen -p
```

### 3. 코드 리뷰 (Claude)
Claude가 Qwen의 구현을 분석하고 검증:
- ✅ 잘된 부분
- ⚠️ 개선 필요
- 🔴 치명적 이슈
- 💡 제안사항

### 4. 수정 선택지
**옵션 A**: Qwen에게 재구현 요청
```bash
echo "Revise based on feedback: [리뷰 내용]" | qwen -p
```

**옵션 B**: Claude가 직접 수정
```bash
# Claude가 Edit/Write 도구로 직접 수정
```

### 5. 최종 배포 (Claude)
Claude가 검증된 코드를 파일에 적용

## 언제 이 스킬을 쓰나?

✅ **이럴 때 사용:**
- 복잡한 기능 개발 (여러 단계 필요)
- Qwen의 코드 생성 능력을 활용하고 싶을 때
- Claude의 코드 리뷰 능력을 활용하고 싶을 때
- 보안/성능이 critical한 작업 (Claude가 검증)
- 로컬 AI로 빠르게 구현하고 검증받고 싶을 때
- 다양한 구현 아이디어를 빠르게 시도하고 싶을 때

❌ **이럴 땐 과함:**
- 간단한 일회성 수정
- 프로토타입/실험 코드 (직접 구현이 더 빠름)
- 개인 학습용 간단한 예제

## 실전 팁

### 💡 Tip 1: 모델 선택
- **qwen2.5-coder**: 코드 작업에 최적화 (기본값, 권장)
- **-m 옵션**: 다른 Qwen 모델 지정 가능

### 💡 Tip 2: 구현 스타일
- **concise**: 간결한 구현, 빠른 프로토타입
- **standard**: 일반적인 작업 (권장)
- **detailed**: 복잡한 로직, 상세한 주석 필요시

### 💡 Tip 3: 역할 분담 (중요!)
```
Claude: 계획, 리뷰, 검증, 배포
Qwen: 코드 구현
```

### 💡 Tip 4: 컨텍스트 제공
Qwen에게 구현 요청 시:
- **상세한 계획** 제공 (Claude가 작성)
- **명확한 요구사항** 명시
- **예상 입출력** 샘플 포함
- **코드 스타일** 가이드라인 제공

### 💡 Tip 5: 리뷰 전략
Claude의 코드 리뷰 시:
- **체계적 분석**: 로직 → 보안 → 성능 → 품질
- **구조화된 피드백**: ✅⚠️🔴💡 표시 활용
- **명확한 지시**: Qwen 재구현 vs Claude 직접 수정

### 💡 Tip 6: 반복 주기
```
계획 → 구현(Qwen) → 리뷰(Claude) → 수정 → 배포
작은 기능: 1회 사이클
중간 기능: 2-3회 반복
큰 기능: 완전 검증까지 반복
```

## 실제 워크플로우 예시

```
1. 👤 "결제 시스템 만들어줘"

2. 🤖 Claude가 상세 계획 수립
   - Stripe API 통합 방식
   - 웹훅 서명 검증
   - 환불 로직 플로우
   - 에러 핸들링 전략
   - 보안 고려사항

3. 🤖 Qwen에게 구현 요청
   $ echo "Implement payment system with Stripe..." | qwen -p

4. 📦 Qwen이 코드 구현
   - payment/stripe.js (234 lines)
   - webhooks/handler.js (156 lines)
   - utils/validator.js (89 lines)

5. 👀 Claude가 코드 리뷰
   "리뷰 결과:
   ✅ Stripe 연동 - 우수
   ✅ 웹훅 처리 - 양호
   ⚠️ 에러 핸들링 개선 필요
   🔴 보안: API 키 하드코딩됨!"

6. 🤖 Claude가 사용자에게 질문
   "Qwen에게 수정 요청 vs 제가 직접 수정?"

7. 👤 "너가 수정해"

8. 🔧 Claude가 직접 수정
   - API 키 환경변수로 이동
   - 에러 핸들링 강화
   - 로깅 추가

9. ✅ Claude가 최종 검증 후 배포
   "모든 이슈 해결 완료!"

10. 🎉 완료!
```

## Codex-Claude Loop와의 차이점

### 🔄 Qwen-Claude Loop (역할 반전!)
- **역할**: Qwen 구현 → Claude 리뷰
- **로컬 실행**: 인터넷 없이도 사용 가능
- **무료**: API 비용 없음
- **프라이버시**: 코드가 외부로 전송되지 않음
- **빠른 반복**: 로컬에서 즉시 구현 시도
- **세션 없음**: 매번 명확한 컨텍스트 제공 필요
- **명령어**: `qwen -p` 사용

### 🌐 Codex-Claude Loop
- **역할**: Claude 구현 → Codex 리뷰
- **클라우드 기반**: OpenAI API 사용
- **유료**: API 비용 발생
- **고급 기능**: 세션 재개(resume), 샌드박스 모드
- **명령어**: `codex exec` 사용

### 🎯 장단점 비교

**Qwen-Claude Loop 장점:**
- ✅ 무료 (API 비용 없음)
- ✅ 프라이버시 보장
- ✅ 오프라인 가능
- ✅ Qwen의 빠른 코드 생성 + Claude의 정밀한 리뷰
- ✅ 다양한 구현 시도가 용이

**Qwen-Claude Loop 단점:**
- ⚠️ Qwen 품질이 Codex보다 낮을 수 있음
- ⚠️ 세션 유지 안 됨 (컨텍스트 매번 제공)
- ⚠️ 로컬 리소스 필요

## 요구사항

### ✅ 필수
- Qwen CLI 설치 및 PATH 등록
- 테스트: `qwen --version` 또는 `qwen --help`
- 동작 확인: `echo "test" | qwen -p`

### 💡 권장
- qwen2.5-coder 모델 사용 (코드 최적화)
- 충분한 시스템 메모리 (모델 실행용)

## 문제 해결

### 🚨 "qwen: command not found"
```bash
# Qwen CLI 설치 확인
which qwen

# PATH 확인
echo $PATH
```

### 🚨 Qwen 응답이 느림
- 모델 크기 확인 (더 작은 모델 사용 고려)
- 시스템 리소스 확인 (메모리/CPU)
- 프롬프트 길이 최적화

### 🚨 검증 품질이 낮음
- 더 상세한 컨텍스트 제공
- 구체적인 체크포인트 명시
- thorough 리뷰 모드 사용

핵심은 **"계획(Claude) → 구현(Qwen) → 리뷰(Claude) → 수정 → 배포(Claude)"** 루프입니다! 🔄

**역할 분담의 장점:**
- 🎯 **Qwen**: 빠른 코드 생성에 집중
- 🔍 **Claude**: 정밀한 리뷰와 품질 보증에 집중
- 💡 각 AI의 강점을 최대한 활용!

로컬에서 안전하고 빠르게 고품질 코드를 만들어보세요! 🚀
