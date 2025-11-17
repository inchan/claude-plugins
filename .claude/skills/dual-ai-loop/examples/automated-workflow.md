# Dual-AI Loop 자동화 워크플로우 예제

이 문서는 Claude Code에서 외부 AI CLI를 실제로 호출하는 구체적인 예제를 제공합니다.

## 예제 1: Codex로 함수 구현

### 시나리오
사용자가 "JWT 토큰 검증 함수를 만들어줘"라고 요청

### Claude의 실제 동작

**Step 1: 계획 수립**

```markdown
## JWT 토큰 검증 함수 구현 계획

### 목표
JWT 토큰의 유효성을 검증하는 함수 구현

### 요구사항
- 토큰 서명 검증
- 만료 시간 확인
- 페이로드 디코딩
- 에러 처리

### 구현 전략
1. jsonwebtoken 라이브러리 사용
2. 비동기 함수로 구현
3. 커스텀 에러 타입 정의

### 검증 기준
- [ ] 유효한 토큰 검증 성공
- [ ] 만료된 토큰 에러 반환
- [ ] 잘못된 서명 감지
```

**Step 2: Codex 호출 (Bash 도구 사용)**

```bash
# Claude가 실제로 실행하는 명령어
echo "JWT 토큰 검증 함수를 TypeScript로 구현하세요.

요구사항:
1. jsonwebtoken 라이브러리 사용
2. 비동기 함수 (async/await)
3. 커스텀 에러 타입 정의:
   - TokenExpiredError
   - InvalidSignatureError
   - MalformedTokenError
4. 페이로드 타입 제네릭 지원

예상 시그니처:
interface JWTPayload { sub: string; exp: number; iat: number; }
async function verifyToken<T extends JWTPayload>(token: string, secret: string): Promise<T>

포함 사항:
- 완전한 에러 처리
- JSDoc 주석
- 테스트 케이스 예제" | codex exec -
```

**Step 3: Codex 출력 파싱**

Codex가 생성한 코드를 Claude가 받아서 분석

**Step 4: Claude 리뷰**

```markdown
## 코드 리뷰 결과

### 긍정적 측면
- ✅ 에러 타입이 잘 정의됨
- ✅ 제네릭 타입 지원 구현됨
- ✅ JSDoc 주석 포함

### 문제점
- ⚠️ 클럭 스큐(clock skew) 처리 없음
- 🔴 토큰 블랙리스트 확인 누락

### 개선 제안
- 💡 clockTolerance 옵션 추가
- 💡 audience/issuer 검증 추가

### 검증 결과
- [x] 유효한 토큰 검증 성공
- [x] 만료된 토큰 에러 반환
- [x] 잘못된 서명 감지

### 결정
반복 필요 - clockTolerance 추가 후 재검증
```

**Step 5: 피드백 전달 (반복)**

```bash
echo "이전 구현을 개선하세요:

문제점:
1. 클럭 스큐(clock skew) 처리 없음

개선 요청:
1. jwt.verify() 옵션에 clockTolerance: 60 추가
2. audience와 issuer 검증 옵션 추가
3. 옵션 인터페이스 정의

수정된 시그니처:
interface VerifyOptions {
  secret: string;
  clockTolerance?: number;
  audience?: string;
  issuer?: string;
}
async function verifyToken<T>(token: string, options: VerifyOptions): Promise<T>" | codex exec -
```

---

## 예제 2: Qwen으로 코드 리뷰

### 시나리오
Claude가 구현한 코드를 Qwen이 검증

### Claude의 실제 동작

**Step 1: Claude가 코드 구현**

```typescript
// Claude가 작성한 코드
export async function fetchUserData(userId: string): Promise<User> {
  const response = await fetch(`/api/users/${userId}`);
  const data = await response.json();
  return data;
}
```

**Step 2: Qwen에게 검증 요청 (Bash 도구 사용)**

```bash
# Claude가 실제로 실행하는 명령어
qwen -p "다음 TypeScript 코드를 검증하세요:

\`\`\`typescript
export async function fetchUserData(userId: string): Promise<User> {
  const response = await fetch('/api/users/' + userId);
  const data = await response.json();
  return data;
}
\`\`\`

검증 항목:
1. 에러 처리 확인
2. 타입 안전성
3. 보안 취약점 (XSS, 인젝션)
4. 성능 이슈
5. 베스트 프랙티스 준수

포맷:
- 문제점 목록
- 심각도 (Critical/High/Medium/Low)
- 수정 제안 코드"
```

**Step 3: Qwen 출력 분석**

Qwen이 반환한 리뷰 결과:
- Critical: 에러 처리 없음
- High: userId 검증 없음
- Medium: response.ok 확인 없음

**Step 4: Claude가 수정 적용**

```typescript
// 개선된 코드
export async function fetchUserData(userId: string): Promise<User> {
  if (!userId || typeof userId !== 'string') {
    throw new Error('Invalid userId');
  }

  const response = await fetch(`/api/users/${encodeURIComponent(userId)}`);

  if (!response.ok) {
    throw new Error(`HTTP error! status: ${response.status}`);
  }

  const data = await response.json();
  return data as User;
}
```

---

## 예제 3: YOLO 모드로 빠른 구현

### 시나리오
빠른 프로토타이핑이 필요한 경우

```bash
# qwen YOLO 모드 - 모든 도구 자동 승인
qwen -y -p "간단한 Express 서버를 만들어서 /health 엔드포인트를 추가하세요.
파일명: server.ts
포트: 3000
응답: { status: 'ok', timestamp: Date.now() }"
```

### 주의사항
- YOLO 모드는 파일 수정을 자동 승인
- 프로덕션 코드에는 사용 금지
- 샌드박스 환경에서만 사용 권장

---

## 예제 4: 출력 파싱 패턴

### Codex 출력 구조

```
OpenAI Codex v0.58.0 (research preview)
--------
workdir: /path/to/project
model: gpt-5-codex
...
--------
user
[프롬프트]

assistant
[생성된 코드 또는 응답]
```

### Claude의 파싱 전략

```markdown
## Bash 출력 파싱

1. 헤더 건너뛰기 (--------까지)
2. 'assistant' 이후 텍스트 추출
3. 코드 블록 파싱
4. 에러 메시지 감지
```

---

## 환경 설정

### 필수 환경 변수

```bash
# Codex용
export OPENAI_API_KEY="sk-..."

# Qwen용 (방법 1: OAuth)
# qwen 실행 후 브라우저 로그인

# Qwen용 (방법 2: API)
export QWEN_OAUTH="your-oauth-token"
# 또는
export OPENAI_API_KEY="your-key"
export OPENAI_BASE_URL="https://your-endpoint"
```

### 인증 확인

```bash
# Codex 인증 상태
codex login --status

# Qwen 설정 확인
qwen --help  # 실행 가능 여부 확인
```

---

## 에러 처리

### 공통 에러

1. **인증 실패**
```bash
# Codex
Error: Authentication required

# Qwen
Please set an Auth method in your ~/.qwen/settings.json
```

**해결**: 환경 변수 설정 또는 로그인 실행

2. **타임아웃**
```bash
# 긴 작업 시 타임아웃 설정
timeout 300 codex exec -  # 5분
```

3. **API 제한**
```bash
# Qwen: 일일 2,000 요청 제한
# 해결: 요청 수 모니터링
```

---

## 베스트 프랙티스

1. **프롬프트 명확성**
   - 구체적인 요구사항 명시
   - 예상 출력 포맷 지정
   - 제약 조건 명시

2. **반복 제한**
   - 최대 3-5회 반복
   - 무한 루프 방지
   - 품질 기준 명확히 정의

3. **검증 우선**
   - 생성된 코드 항상 리뷰
   - 보안 취약점 검사
   - 테스트 실행

4. **인증 관리**
   - API 키 환경 변수로 관리
   - .gitignore에 설정 파일 추가
   - 정기적인 토큰 갱신
