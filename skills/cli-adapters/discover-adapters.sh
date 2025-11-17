#!/bin/bash
# CLI 어댑터 자동 탐색 스크립트
# 사용법: ./discover-adapters.sh [--json] [--available] [--recommended]

set -e

ADAPTERS_DIR="$(dirname "$0")"
REGISTRY_FILE="$ADAPTERS_DIR/cli-registry.json"

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# JSON 출력 모드
json_output() {
    if [ ! -f "$REGISTRY_FILE" ]; then
        echo '{"error": "Registry file not found"}'
        exit 1
    fi

    jq '{
        available_adapters: [.adapters | to_entries[] | select(.value.enabled == true) | .key],
        default_cli: .default_cli,
        adapters: .adapters
    }' "$REGISTRY_FILE"
}

# 사용 가능한 어댑터 목록
available_adapters() {
    echo "사용 가능한 CLI 어댑터:"
    echo ""

    jq -r '.adapters | to_entries[] | select(.value.enabled == true) |
        "  \(.key) - \(.value.display_name) [\(.value.automation_support)]"' "$REGISTRY_FILE" | \
        while read -r line; do
            echo -e "${GREEN}✓${NC} $line"
        done

    echo ""
    echo "비활성화된 어댑터:"
    jq -r '.adapters | to_entries[] | select(.value.enabled == false) |
        "  \(.key) - \(.value.display_name) [\(.value.verification_status)]"' "$REGISTRY_FILE" | \
        while read -r line; do
            if [ -n "$line" ]; then
                echo -e "${YELLOW}○${NC} $line"
            fi
        done
}

# 추천 CLI 선택
recommend_cli() {
    echo "추천 CLI 어댑터:"
    echo ""

    # 1. 완전 검증된 CLI 우선
    echo -e "${BLUE}[완전 검증됨]${NC}"
    jq -r '.adapters | to_entries[] |
        select(.value.verification_status == "full" and .value.automation_support == "full") |
        "  ⭐ \(.key) - \(.value.display_name)"' "$REGISTRY_FILE"

    echo ""

    # 2. 부분 검증된 CLI
    echo -e "${YELLOW}[부분 검증됨]${NC}"
    jq -r '.adapters | to_entries[] |
        select(.value.verification_status == "partial") |
        "  ◐ \(.key) - \(.value.display_name)"' "$REGISTRY_FILE"

    echo ""

    # 3. 기본값
    default=$(jq -r '.default_cli' "$REGISTRY_FILE")
    echo -e "${GREEN}기본 CLI: $default${NC}"
}

# 시스템 검사 (설치 여부)
check_system() {
    echo "시스템 CLI 검사:"
    echo ""

    local installed=0
    local total=0

    # 각 CLI 설치 확인
    for cli in $(jq -r '.adapters | keys[]' "$REGISTRY_FILE"); do
        ((total++))

        case "$cli" in
            codex)
                if command -v codex &> /dev/null; then
                    echo -e "${GREEN}[✓]${NC} codex - 설치됨"
                    ((installed++))
                else
                    echo -e "${YELLOW}[○]${NC} codex - 미설치"
                fi
                ;;
            qwen)
                if command -v qwen &> /dev/null; then
                    echo -e "${GREEN}[✓]${NC} qwen - 설치됨"
                    ((installed++))
                else
                    echo -e "${YELLOW}[○]${NC} qwen - 미설치"
                fi
                ;;
            aider)
                if command -v aider &> /dev/null || [ -f ~/.aider-venv/bin/aider ]; then
                    echo -e "${GREEN}[✓]${NC} aider - 설치됨"
                    ((installed++))
                else
                    echo -e "${YELLOW}[○]${NC} aider - 미설치"
                fi
                ;;
            rovo-dev)
                if command -v acli &> /dev/null; then
                    echo -e "${GREEN}[✓]${NC} rovo-dev (via ACLI) - 설치됨"
                    ((installed++))
                else
                    echo -e "${YELLOW}[○]${NC} rovo-dev - ACLI 미설치"
                fi
                ;;
            copilot)
                if command -v gh &> /dev/null; then
                    if gh extension list 2>/dev/null | grep -q "copilot"; then
                        echo -e "${GREEN}[✓]${NC} copilot - 설치됨"
                        ((installed++))
                    else
                        echo -e "${YELLOW}[○]${NC} copilot - gh 있지만 확장 미설치"
                    fi
                else
                    echo -e "${YELLOW}[○]${NC} copilot - gh CLI 미설치"
                fi
                ;;
            *)
                echo -e "${YELLOW}[?]${NC} $cli - 검사 로직 없음"
                ;;
        esac
    done

    echo ""
    echo "설치됨: $installed / $total"
}

# dual-ai-loop용 동적 CLI 목록 생성
generate_loop_config() {
    echo "# Dual-AI Loop 동적 CLI 설정"
    echo ""
    echo "# 사용 가능한 CLI 목록 (자동 생성됨)"
    echo "AVAILABLE_CLIS=("
    jq -r '.adapters | to_entries[] | select(.value.enabled == true) | "  \"\(.key)\""' "$REGISTRY_FILE"
    echo ")"
    echo ""
    echo "# 기본 CLI"
    echo "DEFAULT_CLI=\"$(jq -r '.default_cli' "$REGISTRY_FILE")\""
    echo ""
    echo "# CLI별 실행 명령어"
    jq -r '.adapters | to_entries[] | select(.value.enabled == true) |
        "CLI_CMD_" + (.key | ascii_upcase) + "=\"" + (.value.execution_pattern // ("echo | " + .key + " exec -")) + "\""' "$REGISTRY_FILE"
}

# 메인 로직
case "${1:-}" in
    --json|-j)
        json_output
        ;;
    --available|-a)
        available_adapters
        ;;
    --recommended|-r)
        recommend_cli
        ;;
    --check|-c)
        check_system
        ;;
    --config|-g)
        generate_loop_config
        ;;
    --help|-h)
        echo "CLI 어댑터 자동 탐색 스크립트"
        echo ""
        echo "사용법: $0 [옵션]"
        echo ""
        echo "옵션:"
        echo "  --json, -j        JSON 형태로 전체 정보 출력"
        echo "  --available, -a   사용 가능한 어댑터 목록"
        echo "  --recommended, -r 추천 CLI 목록"
        echo "  --check, -c       시스템 CLI 설치 상태 검사"
        echo "  --config, -g      Dual-AI Loop용 설정 생성"
        echo "  --help, -h        도움말"
        echo ""
        echo "예시:"
        echo "  $0 --available    # 활성화된 어댑터 목록"
        echo "  $0 --check        # 시스템 설치 상태 확인"
        echo "  $0 --config       # Bash 설정 변수 생성"
        ;;
    "")
        available_adapters
        echo ""
        check_system
        ;;
    *)
        echo "알 수 없는 옵션: $1"
        echo "도움말: $0 --help"
        exit 1
        ;;
esac
