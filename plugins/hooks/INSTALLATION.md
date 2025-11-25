# Skill Activation Hook Installation Guide (v3.0.0)

## 개요

이 가이드는 Skill Activation Hook v3.0.0의 의존성 설치 및 환경 설정 방법을 설명합니다.

## 시스템 요구사항

### 필수 요구사항

| 항목 | 최소 버전 | 권장 버전 | 확인 방법 |
|------|----------|----------|----------|
| Bash | 4.0+ | 5.0+ | `bash --version` |
| Node.js | 18.0+ | 20.0+ | `node --version` |
| Python | 3.8+ | 3.11+ | `python3 --version` |
| npm | 8.0+ | 10.0+ | `npm --version` |
| pip | 20.0+ | 23.0+ | `pip3 --version` |

### 선택 사항

| 항목 | 용도 | 설치 명령 |
|------|------|----------|
| jq | JSON 파싱 (폴백) | `brew install jq` (macOS) |

### 운영 체제

- ✅ macOS 12.0+ (Monterey)
- ✅ Linux (Ubuntu 20.04+, Debian 11+)
- ❌ Windows (미지원, WSL2 권장)

## 설치 단계

### 1. 플러그인 설치

#### CC-Skills Marketplace 추가

```bash
# Claude Code에서 실행
/plugin marketplace add inchan/cc-skills
```

#### Hooks 플러그인 설치

```bash
/plugin install cc-skills-hooks@inchan-cc-skills
```

**설치 확인**:
```bash
/plugin list
# 출력:
# cc-skills-hooks@inchan-cc-skills (v2.0.0)
```

### 2. Node.js 의존성 설치

#### 방법 1: Homebrew (macOS 권장)

```bash
# Homebrew 설치 (없는 경우)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Node.js 설치
brew install node

# 버전 확인
node --version  # v20.10.0 이상
npm --version   # 10.2.0 이상
```

#### 방법 2: nvm (버전 관리 선호 시)

```bash
# nvm 설치
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# 최신 LTS 버전 설치
nvm install --lts
nvm use --lts

# 버전 확인
node --version
```

#### 방법 3: apt (Ubuntu/Debian)

```bash
# Node.js 20.x 저장소 추가
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -

# Node.js 설치
sudo apt-get install -y nodejs

# 버전 확인
node --version
```

#### TF-IDF Matcher 패키지 설치

```bash
# hooks 플러그인 디렉토리로 이동
cd ~/.claude/plugins/inchan-cc-skills/plugins/hooks/matchers

# natural 패키지 설치
npm install natural

# 설치 확인
npm list natural
# natural@6.12.0 (또는 최신 버전)
```

### 3. Python 의존성 설치

#### 방법 1: Homebrew (macOS 권장)

```bash
# Python 3.11 설치
brew install python@3.11

# 버전 확인
python3 --version  # Python 3.11.x
pip3 --version     # pip 23.x
```

#### 방법 2: pyenv (버전 관리 선호 시)

```bash
# pyenv 설치
brew install pyenv

# Python 3.11 설치
pyenv install 3.11.5
pyenv global 3.11.5

# 버전 확인
python --version
```

#### 방법 3: apt (Ubuntu/Debian)

```bash
# Python 3.11 저장소 추가
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt-get update

# Python 3.11 설치
sudo apt-get install -y python3.11 python3.11-venv python3-pip

# 버전 확인
python3.11 --version
```

#### Semantic Matcher 패키지 설치

```bash
# sentence-transformers 설치
pip3 install sentence-transformers

# 설치 확인
python3 -c "import sentence_transformers; print(sentence_transformers.__version__)"
# 2.2.2 (또는 최신 버전)
```

**주의**: 첫 실행 시 모델 다운로드 (~90MB)가 자동으로 진행됩니다.

```bash
# 모델 사전 다운로드 (선택 사항)
python3 -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('all-MiniLM-L6-v2')"
```

### 4. 스크립트 권한 설정

```bash
# hooks 디렉토리로 이동
cd ~/.claude/plugins/inchan-cc-skills/plugins/hooks

# 실행 권한 부여
chmod +x skill-activation-hook.sh
chmod +x stop-hook-lint-and-translate.sh
chmod +x lib/*.sh
chmod +x matchers/*.py
chmod +x matchers/*.js

# 권한 확인
ls -la *.sh lib/*.sh matchers/*.{py,js}
# 모두 -rwxr-xr-x (또는 -rwx--x--x)로 표시되어야 함
```

### 5. 환경 변수 설정 (선택 사항)

#### 캐시 디렉토리 변경

```bash
# ~/.bashrc 또는 ~/.zshrc에 추가
export CACHE_DIR="$HOME/.cache/claude-skills"

# 디렉토리 생성
mkdir -p "$HOME/.cache/claude-skills"
```

#### 디버그 모드 활성화

```bash
# ~/.bashrc 또는 ~/.zshrc에 추가
export DEBUG=1

# 로그 파일 위치
tail -f /tmp/claude-skill-activation.log
```

## 설치 검증

### 1. 의존성 확인

```bash
# 통합 검증 스크립트
cd ~/.claude/plugins/inchan-cc-skills/plugins/hooks

cat << 'EOF' > verify-deps.sh
#!/bin/bash
echo "=== Dependency Verification ==="

# Node.js
if command -v node &> /dev/null; then
    echo "✅ Node.js: $(node --version)"
else
    echo "❌ Node.js: NOT FOUND"
fi

# npm
if command -v npm &> /dev/null; then
    echo "✅ npm: $(npm --version)"
else
    echo "❌ npm: NOT FOUND"
fi

# Python
if command -v python3 &> /dev/null; then
    echo "✅ Python: $(python3 --version)"
else
    echo "❌ Python: NOT FOUND"
fi

# pip
if command -v pip3 &> /dev/null; then
    echo "✅ pip: $(pip3 --version)"
else
    echo "❌ pip: NOT FOUND"
fi

# natural (Node.js)
cd matchers
if npm list natural &> /dev/null; then
    echo "✅ natural: $(npm list natural | grep natural | awk '{print $2}')"
else
    echo "❌ natural: NOT INSTALLED"
fi
cd ..

# sentence-transformers (Python)
if python3 -c "import sentence_transformers" &> /dev/null; then
    VERSION=$(python3 -c "import sentence_transformers; print(sentence_transformers.__version__)")
    echo "✅ sentence-transformers: $VERSION"
else
    echo "❌ sentence-transformers: NOT INSTALLED"
fi

echo "=== Verification Complete ==="
EOF

chmod +x verify-deps.sh
./verify-deps.sh
```

**예상 출력**:
```
=== Dependency Verification ===
✅ Node.js: v20.10.0
✅ npm: 10.2.3
✅ Python: Python 3.11.5
✅ pip: pip 23.2.1
✅ natural: 6.12.0
✅ sentence-transformers: 2.2.2
=== Verification Complete ===
```

### 2. 매처 테스트

#### TF-IDF Matcher 테스트

```bash
cd ~/.claude/plugins/inchan-cc-skills/plugins/hooks/matchers

node tfidf-matcher.js --test
```

**예상 출력**:
```json
{
  "matches": [
    {
      "plugin": "dev-guidelines",
      "skill": "error-tracking",
      "description": "Error tracking and bug fixing with Sentry",
      "tfidfScore": 0.68
    },
    {
      "plugin": "dev-guidelines",
      "skill": "frontend-dev-guidelines",
      "description": "React and TypeScript development patterns",
      "tfidfScore": 0.12
    }
  ],
  "metadata": {
    "totalCandidates": 3,
    "matchedCandidates": 2,
    "elapsedMs": 52,
    "method": "tfidf"
  }
}
```

#### Semantic Matcher 테스트

```bash
cd ~/.claude/plugins/inchan-cc-skills/plugins/hooks/matchers

python3 semantic-matcher.py --test
```

**예상 출력**:
```json
{
  "matches": [
    {
      "plugin": "dev-guidelines",
      "skill": "error-tracking",
      "description": "Error tracking and bug fixing with Sentry",
      "semanticScore": 0.72
    }
  ],
  "metadata": {
    "totalCandidates": 3,
    "matchedCandidates": 1,
    "elapsedMs": 185,
    "method": "semantic-embedding"
  }
}
```

### 3. 훅 실행 테스트

```bash
cd ~/.claude/plugins/inchan-cc-skills/plugins/hooks

# 테스트 입력 생성
echo '{"prompt": "React 컴포넌트를 만들고 싶어요"}' | ./skill-activation-hook.sh

# 로그 확인
tail -20 /tmp/claude-skill-activation.log
```

**예상 로그**:
```
[2025-11-24 10:30:15] Multi-plugin skill-activation-hook executed
[DEBUG] Repository root: /Users/user/.claude/plugins/inchan-cc-skills
[DEBUG] User prompt: React 컴포넌트를 만들고 싶어요
[DEBUG] Total skill-rules.json files: 7
[DEBUG] Total skills aggregated: 24
[DEBUG] Keyword matched skills: 3
[INFO] Suggesting skill: frontend-dev-guidelines (priority: high)
```

## 플랫폼별 설치 가이드

### macOS

#### 1. 사전 준비

```bash
# Xcode Command Line Tools 설치
xcode-select --install

# Homebrew 설치
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### 2. 의존성 설치

```bash
# Node.js, Python 일괄 설치
brew install node python@3.11

# pip 업그레이드
pip3 install --upgrade pip

# Python 패키지 설치
pip3 install sentence-transformers

# Node.js 패키지 설치
cd ~/.claude/plugins/inchan-cc-skills/plugins/hooks/matchers
npm install natural
```

#### 3. 권한 설정

```bash
cd ~/.claude/plugins/inchan-cc-skills/plugins/hooks
chmod +x skill-activation-hook.sh lib/*.sh matchers/*.{py,js}
```

### Linux (Ubuntu/Debian)

#### 1. 시스템 패키지 업데이트

```bash
sudo apt-get update
sudo apt-get upgrade -y
```

#### 2. Node.js 설치

```bash
# Node.js 20.x 저장소 추가
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -

# 설치
sudo apt-get install -y nodejs
```

#### 3. Python 설치

```bash
# Python 3.11 저장소 추가
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt-get update

# 설치
sudo apt-get install -y python3.11 python3.11-venv python3-pip

# 기본 Python 변경 (선택 사항)
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1
```

#### 4. 패키지 설치

```bash
# Python 패키지
pip3 install sentence-transformers

# Node.js 패키지
cd ~/.claude/plugins/inchan-cc-skills/plugins/hooks/matchers
npm install natural
```

#### 5. 권한 설정

```bash
cd ~/.claude/plugins/inchan-cc-skills/plugins/hooks
chmod +x skill-activation-hook.sh lib/*.sh matchers/*.{py,js}
```

### Windows (WSL2)

#### 1. WSL2 설치

```powershell
# PowerShell (관리자 권한)
wsl --install
wsl --set-default-version 2

# Ubuntu 설치
wsl --install -d Ubuntu-22.04
```

#### 2. Ubuntu 환경에서 Linux 가이드 따라하기

```bash
# WSL Ubuntu 터미널에서
sudo apt-get update
# ... (Linux 설치 가이드와 동일)
```

## 문제 해결

### Node.js 문제

#### 증상: `node: command not found`

**해결 방법**:
```bash
# macOS
brew install node

# Ubuntu
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# 경로 확인
which node
```

#### 증상: `natural` 패키지 설치 실패

**해결 방법**:
```bash
# 캐시 삭제 후 재설치
cd ~/.claude/plugins/inchan-cc-skills/plugins/hooks/matchers
rm -rf node_modules package-lock.json
npm cache clean --force
npm install natural
```

### Python 문제

#### 증상: `python3: command not found`

**해결 방법**:
```bash
# macOS
brew install python@3.11
echo 'export PATH="/usr/local/opt/python@3.11/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Ubuntu
sudo apt-get install -y python3.11
```

#### 증상: `sentence-transformers` 설치 실패

**해결 방법**:
```bash
# pip 업그레이드
pip3 install --upgrade pip

# 의존성 수동 설치
pip3 install torch torchvision torchaudio
pip3 install transformers
pip3 install sentence-transformers

# 가상 환경 사용 (권장)
python3 -m venv venv
source venv/bin/activate
pip install sentence-transformers
```

#### 증상: 모델 다운로드 실패

**해결 방법**:
```bash
# 프록시 설정 (필요 시)
export https_proxy=http://proxy.company.com:8080

# 수동 다운로드
python3 << EOF
from sentence_transformers import SentenceTransformer
model = SentenceTransformer('all-MiniLM-L6-v2')
model.save('/tmp/all-MiniLM-L6-v2')
EOF
```

### 권한 문제

#### 증상: `Permission denied` 실행 시

**해결 방법**:
```bash
cd ~/.claude/plugins/inchan-cc-skills/plugins/hooks

# 모든 스크립트에 실행 권한 부여
chmod +x skill-activation-hook.sh
chmod +x lib/*.sh
chmod +x matchers/*.py
chmod +x matchers/*.js

# 확인
ls -la *.sh lib/*.sh matchers/*.{py,js}
```

#### 증상: 캐시 디렉토리 쓰기 실패

**해결 방법**:
```bash
# 디렉토리 생성 및 권한 설정
mkdir -p ~/.claude/plugins/inchan-cc-skills/plugins/hooks/cache
chmod 755 ~/.claude/plugins/inchan-cc-skills/plugins/hooks/cache

# 소유자 확인
ls -la ~/.claude/plugins/inchan-cc-skills/plugins/hooks/cache
# 현재 사용자가 소유자여야 함
```

### 성능 문제

#### 증상: 첫 실행이 매우 느림 (> 10초)

**해결 방법**:
```bash
# 1. 모델 사전 다운로드
python3 -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('all-MiniLM-L6-v2')"

# 2. 캐시 디렉토리 로컬 디스크로 변경
export CACHE_DIR="$HOME/.cache/claude-skills"
mkdir -p "$HOME/.cache/claude-skills"

# 3. ~/.bashrc 또는 ~/.zshrc에 추가
echo 'export CACHE_DIR="$HOME/.cache/claude-skills"' >> ~/.zshrc
source ~/.zshrc
```

## 업그레이드 가이드

### v2.0.0 → v3.0.0

#### 1. 새 의존성 설치

```bash
# Node.js 패키지
cd ~/.claude/plugins/inchan-cc-skills/plugins/hooks/matchers
npm install natural

# Python 패키지
pip3 install sentence-transformers
```

#### 2. 설정 파일 업데이트

v3.0.0에서는 설정 파일 변경이 없습니다. 기존 설정 유지됩니다.

#### 3. 캐시 삭제 (권장)

```bash
cd ~/.claude/plugins/inchan-cc-skills/plugins/hooks
rm -rf cache/*
```

#### 4. 플러그인 재설치

```bash
/plugin uninstall cc-skills-hooks@inchan-cc-skills
/plugin install cc-skills-hooks@inchan-cc-skills
```

## 설치 확인 체크리스트

설치 완료 후 아래 항목을 확인하세요:

- [ ] Node.js v18.0+ 설치 (`node --version`)
- [ ] Python 3.8+ 설치 (`python3 --version`)
- [ ] `natural` 패키지 설치 (`npm list natural`)
- [ ] `sentence-transformers` 패키지 설치 (`python3 -c "import sentence_transformers"`)
- [ ] 스크립트 실행 권한 확인 (`ls -la *.sh`)
- [ ] 매처 테스트 성공 (`node tfidf-matcher.js --test`)
- [ ] 매처 테스트 성공 (`python3 semantic-matcher.py --test`)
- [ ] 훅 실행 테스트 성공 (`echo '{"prompt":"test"}' | ./skill-activation-hook.sh`)
- [ ] 로그 파일 생성 확인 (`ls -la /tmp/claude-skill-activation.log`)

## 도움말

### 지원 채널

- **GitHub Issues**: https://github.com/inchan/cc-skills/issues
- **문서**: https://github.com/inchan/cc-skills/blob/main/docs/

### 추가 리소스

- [ARCHITECTURE.md](./ARCHITECTURE.md) - 시스템 아키텍처
- [PERFORMANCE.md](./PERFORMANCE.md) - 성능 최적화 가이드
- [README.md](./README.md) - 사용 가이드
