#!/bin/bash
#
# install-dependencies.sh
# Skill Activation Hook v3.0.0 - Dependency Installation Script
#
# 이 스크립트는 Skill Activation Hook에 필요한 모든 의존성을 설치합니다.
#

set -e  # 에러 발생 시 즉시 종료

# 색상 코드
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 로깅 함수
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 버전 체크 함수
check_version() {
    local cmd=$1
    local min_version=$2
    local version_flag=$3

    if ! command -v "$cmd" &> /dev/null; then
        return 1
    fi

    local installed_version=$($cmd $version_flag 2>&1 | head -n1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n1)

    if [ -z "$installed_version" ]; then
        return 1
    fi

    # 간단한 버전 비교 (major.minor만 체크)
    local min_major=$(echo "$min_version" | cut -d. -f1)
    local min_minor=$(echo "$min_version" | cut -d. -f2)
    local inst_major=$(echo "$installed_version" | cut -d. -f1)
    local inst_minor=$(echo "$installed_version" | cut -d. -f2)

    if [ "$inst_major" -gt "$min_major" ]; then
        return 0
    elif [ "$inst_major" -eq "$min_major" ] && [ "$inst_minor" -ge "$min_minor" ]; then
        return 0
    else
        return 1
    fi
}

# 스크립트 시작
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Skill Activation Hook v3.0.0 - Dependency Installer"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 현재 디렉토리 저장
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 1. 시스템 요구사항 확인
log_info "시스템 요구사항 확인 중..."
echo ""

# Node.js 확인
log_info "Node.js 확인 중..."
if check_version "node" "16.0" "--version"; then
    NODE_VERSION=$(node --version)
    log_info "✅ Node.js: $NODE_VERSION"
else
    log_error "❌ Node.js 16.0+ 가 필요합니다."
    log_info "설치 방법:"
    log_info "  macOS:  brew install node"
    log_info "  Ubuntu: curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - && sudo apt-get install -y nodejs"
    exit 1
fi

# npm 확인
log_info "npm 확인 중..."
if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm --version)
    log_info "✅ npm: $NPM_VERSION"
else
    log_error "❌ npm이 필요합니다 (Node.js와 함께 설치됨)."
    exit 1
fi

# Python 확인
log_info "Python 확인 중..."
if check_version "python3" "3.8" "--version"; then
    PYTHON_VERSION=$(python3 --version)
    log_info "✅ Python: $PYTHON_VERSION"
else
    log_error "❌ Python 3.8+ 가 필요합니다."
    log_info "설치 방법:"
    log_info "  macOS:  brew install python@3.11"
    log_info "  Ubuntu: sudo add-apt-repository ppa:deadsnakes/ppa && sudo apt-get install -y python3.11"
    exit 1
fi

# pip 확인
log_info "pip 확인 중..."
if command -v pip3 &> /dev/null; then
    PIP_VERSION=$(pip3 --version | awk '{print $2}')
    log_info "✅ pip: $PIP_VERSION"
else
    log_error "❌ pip3가 필요합니다."
    log_info "설치 방법:"
    log_info "  macOS:  python3 -m ensurepip --upgrade"
    log_info "  Ubuntu: sudo apt-get install -y python3-pip"
    exit 1
fi

echo ""
log_info "모든 시스템 요구사항이 충족되었습니다."
echo ""

# 2. Node.js 패키지 설치
log_info "Node.js 패키지 설치 중..."
cd matchers

if [ -f "package.json" ]; then
    log_info "npm install 실행 중..."
    if npm install; then
        log_info "✅ Node.js 패키지 설치 완료"

        # natural 패키지 확인
        if npm list natural &> /dev/null; then
            NATURAL_VERSION=$(npm list natural | grep natural | awk '{print $2}' | sed 's/@//')
            log_info "  - natural: $NATURAL_VERSION"
        fi
    else
        log_error "❌ Node.js 패키지 설치 실패"
        exit 1
    fi
else
    log_error "❌ package.json을 찾을 수 없습니다."
    exit 1
fi

echo ""

# 3. Python 패키지 설치
log_info "Python 패키지 설치 중..."

if [ -f "requirements.txt" ]; then
    log_info "pip install 실행 중 (시간이 걸릴 수 있습니다)..."

    # sentence-transformers 설치 (처음에는 오래 걸릴 수 있음)
    if pip3 install -r requirements.txt --quiet; then
        log_info "✅ Python 패키지 설치 완료"

        # sentence-transformers 확인
        if python3 -c "import sentence_transformers" &> /dev/null; then
            ST_VERSION=$(python3 -c "import sentence_transformers; print(sentence_transformers.__version__)")
            log_info "  - sentence-transformers: $ST_VERSION"
        fi
    else
        log_error "❌ Python 패키지 설치 실패"
        exit 1
    fi
else
    log_error "❌ requirements.txt를 찾을 수 없습니다."
    exit 1
fi

cd "$SCRIPT_DIR"
echo ""

# 4. 모델 사전 다운로드 (선택 사항)
log_info "Sentence Transformer 모델 확인 중..."
log_warn "첫 실행 시 모델 다운로드(~90MB)가 필요합니다."
read -p "지금 모델을 다운로드하시겠습니까? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "모델 다운로드 중 (시간이 걸릴 수 있습니다)..."
    if python3 -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('all-MiniLM-L6-v2')" &> /dev/null; then
        log_info "✅ 모델 다운로드 완료"
    else
        log_warn "⚠️  모델 다운로드 실패 (첫 사용 시 자동 다운로드됩니다)"
    fi
else
    log_info "모델 다운로드 건너뛰기 (첫 사용 시 자동 다운로드됩니다)"
fi

echo ""

# 5. 권한 설정
log_info "실행 권한 설정 중..."

chmod +x skill-activation-hook.sh 2>/dev/null || true
chmod +x lib/*.sh 2>/dev/null || true
chmod +x matchers/*.py 2>/dev/null || true
chmod +x matchers/*.js 2>/dev/null || true

log_info "✅ 실행 권한 설정 완료"
echo ""

# 6. 캐시 디렉토리 생성
log_info "캐시 디렉토리 생성 중..."

if [ ! -d "cache" ]; then
    mkdir -p cache
    log_info "✅ 캐시 디렉토리 생성 완료"
else
    log_info "✅ 캐시 디렉토리 이미 존재함"
fi

echo ""

# 7. 설치 검증
log_info "설치 검증 중..."
echo ""

# TF-IDF Matcher 테스트
log_info "TF-IDF Matcher 테스트 중..."
cd matchers
if node tfidf-matcher.js --test &> /dev/null; then
    log_info "✅ TF-IDF Matcher 작동 확인"
else
    log_warn "⚠️  TF-IDF Matcher 테스트 실패"
fi

# Semantic Matcher 테스트
log_info "Semantic Matcher 테스트 중..."
if python3 semantic-matcher.py --test &> /dev/null; then
    log_info "✅ Semantic Matcher 작동 확인"
else
    log_warn "⚠️  Semantic Matcher 테스트 실패"
fi

cd "$SCRIPT_DIR"
echo ""

# 8. 설치 완료
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
log_info "🎉 설치가 완료되었습니다!"
echo ""
echo "다음 단계:"
echo "  1. 플러그인 설치 확인: /plugin list"
echo "  2. 훅 테스트: echo '{\"prompt\":\"test\"}' | ./skill-activation-hook.sh"
echo "  3. 문서 확인: cat README.md"
echo ""
echo "문제가 발생하면 다음 문서를 참조하세요:"
echo "  - INSTALLATION.md: 설치 가이드"
echo "  - TROUBLESHOOTING.md: 문제 해결"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
