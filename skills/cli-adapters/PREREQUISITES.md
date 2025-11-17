# CLI 실행 필수 조건

⚠️ **중요**: CLI는 **설치 + 로그인/인증** 두 조건이 모두 충족되어야 실행됩니다.

---

## 실행 조건 체크리스트

### Codex CLI

```bash
# 1. 설치 확인
which codex
# ✅ 경로 출력되면 설치됨
# ❌ 출력 없으면 미설치

# 2. 인증 확인
codex login --status
# ✅ "Logged in as..." → 인증됨
# ❌ "Not logged in" → 미인증

# 3. 실행 테스트
echo "test" | codex exec -
# ✅ AI 응답 출력 → 성공
# ❌ "Authentication required" → 실패
# ❌ "Reconnecting..." → 인증 실패
```

**실패 원인:**
- 미설치: `command not found`
- 미인증: `Authentication required`
- API 키 무효: `Reconnecting...`

---

### Qwen CLI

```bash
# 1. 설치 확인
which qwen
# ✅ 경로 출력되면 설치됨
# ❌ 출력 없으면 미설치

# 2. 인증 확인
qwen -p "test" 2>&1 | head -5
# ✅ AI 응답 → 인증됨
# ❌ "Please set an Auth method" → 미인증

# 3. 실행 테스트
qwen -p "What is 2+2?"
# ✅ 숫자 응답 → 성공
# ❌ 인증 오류 → 실패
```

**실패 원인:**
- 미설치: `command not found`
- 미인증: `Please set an Auth method in ~/.qwen/settings.json`
- API 제한 초과: 요청 실패

---

### Aider CLI

```bash
# 1. 설치 확인
which aider
# 또는
~/.aider-venv/bin/aider --version
# ✅ 버전 출력 → 설치됨
# ❌ 오류 → 미설치/의존성 문제

# 2. 인증 확인
echo $OPENAI_API_KEY  # 또는 다른 API 키
# ✅ 값 있음 → 키 설정됨
# ❌ 빈 값 → 미설정

# 3. 실행 테스트
aider --check
# ✅ "API connection successful" → 성공
# ❌ "No API key found" → 실패
```

**실패 원인:**
- 미설치: 의존성 오류
- 미인증: `No API key found`
- 키 무효: 연결 실패

---

### Rovo Dev CLI (via ACLI)

```bash
# 1. ACLI 설치 확인
which acli
# ✅ 경로 출력 → 설치됨
# ❌ 출력 없음 → 미설치

# 2. Rovodev 서브커맨드 확인
acli rovodev --help
# ✅ 도움말 출력 → 사용 가능
# ❌ 오류 → 미지원

# 3. 인증 확인
acli rovodev auth login
# ✅ 이미 로그인됨 또는 성공
# ❌ 인증 실패

# 4. 실행 테스트
acli rovodev run
# ✅ 실행됨 → 성공
# ❌ 인증 오류 → 실패
```

**실패 원인:**
- ACLI 미설치
- Rovodev 서브커맨드 미지원
- API 토큰 미설정
- Rovo Dev Agents 앱 미설치

---

## 실패 시나리오별 해결 방법

### 1. "command not found"

**원인**: CLI 미설치

**해결**:
```bash
# Codex
npm install -g @openai/codex

# Qwen
npm install -g @qwen-code/qwen-code

# Aider (가상환경 권장)
pip install aider-chat
```

---

### 2. "Authentication required" / "Please set an Auth method"

**원인**: 로그인 안됨

**해결**:
```bash
# Codex
codex login

# Qwen
qwen  # Sign in 선택

# Aider
export OPENAI_API_KEY="sk-..."
```

---

### 3. "API key invalid" / "Reconnecting..."

**원인**: 잘못된 인증 정보

**해결**:
- API 키 재확인
- 만료된 토큰 갱신
- 올바른 환경 변수 설정

---

### 4. "Rate limit exceeded"

**원인**: API 요청 제한 초과

**해결**:
- Qwen OAuth: 다음 날까지 대기 (일일 2,000)
- OpenAI: 플랜 업그레이드 또는 대기
- 요청 빈도 줄이기

---

## dual-ai-loop에서의 처리

### 실행 전 필수 검증

Claude가 외부 AI CLI를 호출하기 전에 **반드시** 확인해야 하는 사항:

```markdown
## CLI 실행 전 체크리스트

### Step 1: 설치 확인
- [ ] `which <cli>` 실행
- [ ] 경로 출력 확인
- [ ] 미설치 시 → 설치 가이드 안내

### Step 2: 인증 확인
- [ ] 환경 변수 또는 로그인 상태 확인
- [ ] 미인증 시 → 인증 가이드 안내
- [ ] 인증 필수임을 사용자에게 알림

### Step 3: 실행 시도
- [ ] 간단한 테스트 명령어 실행
- [ ] 성공 시 → 실제 작업 진행
- [ ] 실패 시 → 오류 분석 및 대안 제시
```

### Claude의 실제 검증 코드

```bash
# dual-ai-loop 시작 시 Claude가 실행하는 명령어

# Codex 검증
if ! command -v codex &> /dev/null; then
    echo "ERROR: codex 미설치"
    exit 1
fi

if ! codex login --status 2>&1 | grep -q "Logged in"; then
    echo "ERROR: codex 미인증"
    exit 1
fi

echo "SUCCESS: codex 실행 가능"
```

```bash
# Qwen 검증
if ! command -v qwen &> /dev/null; then
    echo "ERROR: qwen 미설치"
    exit 1
fi

if qwen -p "test" 2>&1 | grep -q "Please set an Auth"; then
    echo "ERROR: qwen 미인증"
    exit 1
fi

echo "SUCCESS: qwen 실행 가능"
```

---

## 실행 조건 요약표

| CLI | 설치 | 인증 | 기타 요구사항 | 실행 가능 |
|-----|------|------|--------------|-----------|
| codex | ✅ | ✅ | - | ✅ |
| codex | ✅ | ❌ | - | ❌ |
| codex | ❌ | - | - | ❌ |
| qwen | ✅ | ✅ | - | ✅ |
| qwen | ✅ | ❌ | - | ❌ |
| qwen | ❌ | - | - | ❌ |
| aider | ✅ | ✅ | git 설치됨 | ✅ |
| aider | ✅ | ❌ | - | ❌ |
| rovo-dev | ✅ ACLI | ✅ API 토큰 | Rovo 앱 설치됨 | ✅ |
| rovo-dev | ✅ ACLI | ❌ | - | ❌ |

**결론**: 설치 + 인증 = 실행 가능, 그 외는 모두 **실패**

---

## 사용자 알림 템플릿

### CLI 선택 시

```
어떤 AI CLI를 사용하시겠습니까?

1. codex ← 설치됨 ✅ / 인증됨 ✅ → 실행 가능
2. qwen ← 설치됨 ✅ / 인증됨 ❌ → 실행 불가 (로그인 필요)
3. aider ← 설치됨 ❌ → 실행 불가 (설치 필요)

⚠️ 선택한 CLI가 실행 불가능한 경우, 설치 및 인증 과정을 먼저 완료해야 합니다.
```

### 실행 실패 시

```
❌ {cli_name} 실행 실패

원인: {미설치|미인증|API 오류}

해결 방법:
1. [구체적인 명령어]
2. [구체적인 단계]

다른 CLI를 선택하시겠습니까?
→ 현재 실행 가능한 CLI: [목록]
```

---

## 핵심 메시지

**설치만으로는 충분하지 않습니다.**

- ✅ 설치됨 + ✅ 인증됨 = **실행 가능**
- ✅ 설치됨 + ❌ 미인증 = **실행 불가**
- ❌ 미설치 = **실행 불가**

**모든 CLI는 인증/로그인이 필수입니다.**
