# CLI 인증 설정 가이드

이 문서는 각 CLI 도구의 인증 설정 방법을 상세히 설명합니다.

---

## Codex CLI 인증

### 방법 1: ChatGPT 계정 로그인 (권장)

```bash
codex login
```

- 브라우저가 열리고 ChatGPT 계정으로 로그인
- 지원 플랜: Plus, Pro, Team, Edu, Enterprise
- 토큰이 자동으로 저장됨

**상태 확인:**
```bash
codex login --status
```

### 방법 2: API 키 사용

```bash
# 환경 변수 설정
export OPENAI_API_KEY="sk-your-api-key-here"

# 또는 설정 파일에 저장
codex -c 'api_key="sk-your-key"' exec "테스트"
```

**설정 파일 위치:**
```
~/.codex/config.toml
```

### 테스트

```bash
echo "Hello, what is 2+2?" | codex exec -
# 인증 성공 시 응답 출력
# 실패 시: "Authentication required" 또는 "Reconnecting..."
```

---

## Qwen CLI 인증

### 방법 1: Qwen OAuth (권장)

```bash
qwen
# 'Sign in' 선택 → 브라우저에서 인증
```

**제한사항:**
- 일일 2,000 요청
- 분당 60 요청

**토큰 저장 위치:**
```
~/.qwen/settings.json
```

### 방법 2: OpenAI 호환 API

```bash
# 환경 변수 설정
export OPENAI_API_KEY="your-api-key"
export OPENAI_BASE_URL="https://your-endpoint/v1"
export OPENAI_MODEL="your-model-name"
```

**또는 프로젝트 루트에 .env 파일:**
```env
OPENAI_API_KEY=your-key
OPENAI_BASE_URL=https://your-endpoint
OPENAI_MODEL=your-model
```

### 테스트

```bash
qwen -p "What is 2+2?"
# 인증 성공 시: AI 응답
# 실패 시: "Please set an Auth method..."
```

---

## Aider CLI 인증

### 지원 API 키

```bash
# OpenAI
export OPENAI_API_KEY="sk-..."

# Anthropic (Claude)
export ANTHROPIC_API_KEY="sk-ant-..."

# DeepSeek
export DEEPSEEK_API_KEY="..."
```

### 명령줄 옵션

```bash
# 특정 제공자와 키 지정
aider --api-key openai=sk-your-key

# 여러 제공자
aider --api-key openai=sk-... --api-key anthropic=sk-ant-...
```

### 설정 파일

```yaml
# ~/.aider/config.yml
api_keys:
  openai: sk-your-key
  anthropic: sk-ant-your-key
```

### 테스트

```bash
aider --version  # 설치 확인
aider --check    # API 연결 테스트
```

---

## 환경 변수 관리

### 영구 설정 (권장)

**Bash (~/.bashrc 또는 ~/.bash_profile):**
```bash
# Codex
export OPENAI_API_KEY="sk-..."

# Qwen
export QWEN_OAUTH="your-oauth-token"
# 또는
export OPENAI_API_KEY="your-key"
export OPENAI_BASE_URL="https://..."

# Aider
export ANTHROPIC_API_KEY="sk-ant-..."
```

**적용:**
```bash
source ~/.bashrc
```

### Zsh (~/.zshrc):
```bash
echo 'export OPENAI_API_KEY="sk-..."' >> ~/.zshrc
source ~/.zshrc
```

### 프로젝트별 설정

**.env 파일 사용:**
```bash
# .env
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
```

**중요:** `.gitignore`에 `.env` 추가!

```bash
echo ".env" >> .gitignore
```

---

## 보안 베스트 프랙티스

### 1. API 키 보호

```bash
# ❌ 나쁜 예
git commit -m "Add API key: sk-abc123"

# ✅ 좋은 예
# .gitignore에 추가
echo "*.env" >> .gitignore
echo ".codex/" >> .gitignore
echo ".qwen/" >> .gitignore
echo ".aider/" >> .gitignore
```

### 2. 키 로테이션

- 정기적으로 API 키 교체
- 사용하지 않는 키는 폐기
- 의심스러운 활동 시 즉시 키 재생성

### 3. 권한 최소화

```bash
# Codex 샌드박스 모드 사용
codex exec --sandbox read-only "분석 작업"

# Qwen 승인 모드
qwen --approval-mode plan -p "작업"  # 실행 전 검토
```

### 4. 로그 확인

```bash
# 사용량 모니터링
# OpenAI: https://platform.openai.com/usage
# Anthropic: https://console.anthropic.com/
```

---

## 트러블슈팅

### 인증 실패

**Codex:**
```
Error: Authentication required
```
→ `codex login` 실행 또는 API 키 확인

**Qwen:**
```
Please set an Auth method in your ~/.qwen/settings.json
```
→ `qwen` 실행 후 'Sign in' 또는 환경변수 설정

**Aider:**
```
No API key found
```
→ 환경변수 또는 --api-key 옵션 확인

### API 제한

**Qwen OAuth:**
- 일일 2,000 요청 초과 시 다음 날까지 대기
- 또는 자체 API 엔드포인트 사용

**OpenAI:**
- Rate limit 에러 시 잠시 대기 후 재시도
- 플랜 업그레이드 고려

### 연결 문제

```bash
# 프록시 설정 필요 시
export HTTPS_PROXY="http://proxy:port"

# 또는 각 CLI의 프록시 옵션 사용
qwen --proxy "http://proxy:port"
```

---

## 빠른 시작

### 1. Codex 빠른 설정

```bash
npm install -g @openai/codex
codex login
echo "Test" | codex exec -
```

### 2. Qwen 빠른 설정

```bash
npm install -g @qwen-code/qwen-code
qwen  # Sign in
qwen -p "Test"
```

### 3. 전체 검증

```bash
./setup-cli.sh verify
```

---

## 참고 자료

- [OpenAI API Keys](https://platform.openai.com/api-keys)
- [Anthropic Console](https://console.anthropic.com/)
- [Qwen Code GitHub](https://github.com/QwenLM/qwen-code)
- [Codex GitHub](https://github.com/openai/codex)
- [Aider Documentation](https://aider.chat/docs)
