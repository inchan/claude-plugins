#!/bin/bash
# CLI 어댑터 설치 스크립트
# 사용법: ./setup-cli.sh [codex|qwen|aider|all]

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

check_node() {
    if ! command -v node &> /dev/null; then
        print_error "Node.js가 설치되어 있지 않습니다."
        echo "설치: https://nodejs.org/"
        exit 1
    fi
    NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 16 ]; then
        print_error "Node.js v16.0.0 이상이 필요합니다. 현재: $(node --version)"
        exit 1
    fi
    print_status "Node.js $(node --version) 확인됨"
}

check_python() {
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3가 설치되어 있지 않습니다."
        exit 1
    fi
    PYTHON_VERSION=$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1-2)
    print_status "Python $PYTHON_VERSION 확인됨"
}

install_codex() {
    echo ""
    echo "=== OpenAI Codex CLI 설치 ==="
    check_node

    if command -v codex &> /dev/null; then
        CURRENT_VERSION=$(codex --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
        print_warning "codex가 이미 설치되어 있습니다: v$CURRENT_VERSION"
        read -p "재설치하시겠습니까? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return
        fi
    fi

    echo "npm install -g @openai/codex 실행 중..."
    npm install -g @openai/codex

    if command -v codex &> /dev/null; then
        VERSION=$(codex --version 2>&1 | head -1)
        print_status "codex 설치 완료: $VERSION"
        echo ""
        echo "다음 단계:"
        echo "1. OpenAI API 키 설정:"
        echo "   export OPENAI_API_KEY='your-key'"
        echo "2. 또는 ChatGPT 계정으로 로그인:"
        echo "   codex login"
    else
        print_error "codex 설치 실패"
    fi
}

install_qwen() {
    echo ""
    echo "=== Qwen Code CLI 설치 ==="
    check_node

    if command -v qwen &> /dev/null; then
        CURRENT_VERSION=$(qwen --version 2>&1 || echo "unknown")
        print_warning "qwen이 이미 설치되어 있습니다: v$CURRENT_VERSION"
        read -p "재설치하시겠습니까? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return
        fi
    fi

    echo "npm install -g @qwen-code/qwen-code 실행 중..."
    npm install -g @qwen-code/qwen-code

    if command -v qwen &> /dev/null; then
        VERSION=$(qwen --version 2>&1)
        print_status "qwen 설치 완료: v$VERSION"
        echo ""
        echo "다음 단계:"
        echo "1. Qwen OAuth 인증 (권장):"
        echo "   qwen  # 실행 후 'Sign in' 선택"
        echo "2. 또는 OpenAI 호환 API 사용:"
        echo "   export OPENAI_API_KEY='your-key'"
        echo "   export OPENAI_BASE_URL='your-endpoint'"
        echo ""
        echo "주의: OAuth는 일일 2,000 요청 제한"
    else
        print_error "qwen 설치 실패"
    fi
}

install_aider() {
    echo ""
    echo "=== Aider CLI 설치 (가상환경 권장) ==="
    check_python

    print_warning "aider는 의존성이 엄격하여 가상환경 사용을 권장합니다."
    read -p "가상환경을 생성하시겠습니까? (Y/n): " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        VENV_DIR="${HOME}/.aider-venv"

        if [ -d "$VENV_DIR" ]; then
            print_warning "기존 가상환경이 존재합니다: $VENV_DIR"
            read -p "삭제하고 다시 생성하시겠습니까? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                rm -rf "$VENV_DIR"
            else
                return
            fi
        fi

        echo "가상환경 생성 중: $VENV_DIR"
        python3 -m venv "$VENV_DIR"

        echo "aider-chat 설치 중..."
        "$VENV_DIR/bin/pip" install aider-chat

        if [ -f "$VENV_DIR/bin/aider" ]; then
            VERSION=$("$VENV_DIR/bin/aider" --version 2>&1 | head -1)
            print_status "aider 설치 완료: $VERSION"
            echo ""
            echo "사용 방법:"
            echo "1. 가상환경 활성화:"
            echo "   source $VENV_DIR/bin/activate"
            echo "2. aider 실행:"
            echo "   aider --api-key provider=key"
            echo ""
            echo "또는 직접 실행:"
            echo "   $VENV_DIR/bin/aider --help"

            # PATH에 심볼릭 링크 생성 옵션
            read -p "aider를 PATH에 추가하시겠습니까? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                sudo ln -sf "$VENV_DIR/bin/aider" /usr/local/bin/aider
                print_status "aider가 /usr/local/bin/aider에 링크되었습니다"
            fi
        else
            print_error "aider 설치 실패"
        fi
    else
        echo "시스템에 직접 설치 (충돌 위험)..."
        pip3 install aider-chat
    fi
}

install_all() {
    install_codex
    install_qwen
    install_aider
}

verify_installations() {
    echo ""
    echo "=== 설치 상태 확인 ==="

    if command -v codex &> /dev/null; then
        VERSION=$(codex --version 2>&1 | head -1)
        print_status "codex: $VERSION"
    else
        print_warning "codex: 미설치"
    fi

    if command -v qwen &> /dev/null; then
        VERSION=$(qwen --version 2>&1)
        print_status "qwen: v$VERSION"
    else
        print_warning "qwen: 미설치"
    fi

    if command -v aider &> /dev/null; then
        VERSION=$(aider --version 2>&1 | head -1)
        print_status "aider: $VERSION"
    elif [ -f "${HOME}/.aider-venv/bin/aider" ]; then
        VERSION=$("${HOME}/.aider-venv/bin/aider" --version 2>&1 | head -1)
        print_status "aider (venv): $VERSION"
    else
        print_warning "aider: 미설치"
    fi
}

# 메인 로직
case "${1:-}" in
    codex)
        install_codex
        ;;
    qwen)
        install_qwen
        ;;
    aider)
        install_aider
        ;;
    all)
        install_all
        ;;
    verify|check)
        verify_installations
        ;;
    *)
        echo "CLI 어댑터 설치 스크립트"
        echo ""
        echo "사용법: $0 [명령어]"
        echo ""
        echo "명령어:"
        echo "  codex   - OpenAI Codex CLI 설치"
        echo "  qwen    - Qwen Code CLI 설치"
        echo "  aider   - Aider CLI 설치 (가상환경)"
        echo "  all     - 모든 CLI 설치"
        echo "  verify  - 설치 상태 확인"
        echo ""
        echo "예시:"
        echo "  $0 codex"
        echo "  $0 all"
        echo "  $0 verify"
        ;;
esac
