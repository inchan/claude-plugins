#!/bin/bash
# CLI 어댑터 검증 스크립트
# 사용법: ./validate-adapter.sh [cli-name] [--all] [--list]

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ADAPTERS_DIR="$(dirname "$0")"
REGISTRY_FILE="$ADAPTERS_DIR/cli-registry.json"

print_success() { echo -e "${GREEN}[✓]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[⚠]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }
print_info() { echo -e "${BLUE}[i]${NC} $1"; }

# 어댑터 목록 출력
list_adapters() {
    echo "등록된 CLI 어댑터 목록:"
    echo ""

    if [ ! -f "$REGISTRY_FILE" ]; then
        print_error "레지스트리 파일이 없습니다: $REGISTRY_FILE"
        exit 1
    fi

    jq -r '.adapters | to_entries[] | "\(.key): \(.value.display_name) [\(.value.verification_status)]"' "$REGISTRY_FILE"
    echo ""

    # 디렉토리에 있지만 레지스트리에 없는 것 찾기
    echo "디렉토리 스캔:"
    for dir in "$ADAPTERS_DIR"/*/; do
        if [ -d "$dir" ]; then
            name=$(basename "$dir")
            if ! jq -e ".adapters.\"$name\"" "$REGISTRY_FILE" > /dev/null 2>&1; then
                print_warning "$name - 디렉토리 존재하지만 레지스트리에 미등록"
            fi
        fi
    done
}

# 단일 어댑터 검증
validate_adapter() {
    local name="$1"
    local adapter_dir="$ADAPTERS_DIR/$name"
    local errors=0
    local warnings=0

    echo ""
    echo "=== $name 어댑터 검증 ==="

    # 1. 디렉토리 존재 확인
    if [ ! -d "$adapter_dir" ]; then
        print_error "디렉토리가 존재하지 않습니다: $adapter_dir"
        return 1
    fi
    print_success "디렉토리 존재: $adapter_dir"

    # 2. SKILL.md 존재 확인
    if [ ! -f "$adapter_dir/SKILL.md" ]; then
        print_error "SKILL.md 파일이 없습니다"
        ((errors++))
    else
        print_success "SKILL.md 존재"

        # frontmatter 확인
        if ! head -1 "$adapter_dir/SKILL.md" | grep -q "^---$"; then
            print_warning "SKILL.md에 frontmatter가 없습니다"
            ((warnings++))
        fi
    fi

    # 3. VERSION.json 존재 확인
    if [ ! -f "$adapter_dir/VERSION.json" ]; then
        print_error "VERSION.json 파일이 없습니다"
        ((errors++))
    else
        print_success "VERSION.json 존재"

        # JSON 유효성 검사
        if ! jq . "$adapter_dir/VERSION.json" > /dev/null 2>&1; then
            print_error "VERSION.json이 유효한 JSON이 아닙니다"
            ((errors++))
        else
            print_success "VERSION.json JSON 유효성 검증 통과"

            # 필수 필드 확인
            local required_fields=("cli_name" "display_name" "current_supported_version" "verification_level" "sources" "install_methods" "verification")

            for field in "${required_fields[@]}"; do
                if ! jq -e ".$field" "$adapter_dir/VERSION.json" > /dev/null 2>&1; then
                    print_warning "필수 필드 누락: $field"
                    ((warnings++))
                fi
            done

            # cli_name 일치 확인
            local json_name=$(jq -r '.cli_name' "$adapter_dir/VERSION.json")
            if [ "$json_name" != "$name" ] && [ "$json_name" != "acli-$name" ]; then
                print_warning "cli_name ($json_name)이 디렉토리명 ($name)과 다릅니다"
                ((warnings++))
            fi

            # verification_level 구조 확인
            if jq -e '.verification_level.package_exists' "$adapter_dir/VERSION.json" > /dev/null 2>&1; then
                print_success "verification_level 구조 올바름"
            else
                print_warning "verification_level 구조가 표준과 다릅니다"
                ((warnings++))
            fi
        fi
    fi

    # 4. 레지스트리 등록 확인
    if ! jq -e ".adapters.\"$name\"" "$REGISTRY_FILE" > /dev/null 2>&1; then
        print_warning "cli-registry.json에 등록되지 않았습니다"
        ((warnings++))
    else
        print_success "레지스트리에 등록됨"

        # 레지스트리 필수 필드 확인
        local reg_fields=("enabled" "display_name" "adapter_path" "verification_status" "automation_support")
        for field in "${reg_fields[@]}"; do
            if ! jq -e ".adapters.\"$name\".$field" "$REGISTRY_FILE" > /dev/null 2>&1; then
                print_warning "레지스트리 필수 필드 누락: $field"
                ((warnings++))
            fi
        done
    fi

    # 5. 자동화 지원 정보 확인
    if jq -e '.automation' "$adapter_dir/VERSION.json" > /dev/null 2>&1; then
        print_success "자동화 정보 존재"

        local auto_support=$(jq -r '.automation.support_level // "unknown"' "$adapter_dir/VERSION.json")
        print_info "자동화 지원 수준: $auto_support"
    else
        print_warning "자동화 정보가 없습니다 (VERSION.json에 automation 필드 추가 권장)"
        ((warnings++))
    fi

    # 결과 요약
    echo ""
    if [ $errors -eq 0 ] && [ $warnings -eq 0 ]; then
        print_success "✅ $name 어댑터 검증 통과 (오류 없음)"
    elif [ $errors -eq 0 ]; then
        print_warning "⚠️  $name 어댑터 검증 통과 (경고 $warnings개)"
    else
        print_error "❌ $name 어댑터 검증 실패 (오류 $errors개, 경고 $warnings개)"
        return 1
    fi

    return 0
}

# 모든 어댑터 검증
validate_all() {
    echo "모든 CLI 어댑터 검증 중..."

    local total=0
    local passed=0
    local failed=0

    for dir in "$ADAPTERS_DIR"/*/; do
        if [ -d "$dir" ]; then
            name=$(basename "$dir")
            if validate_adapter "$name"; then
                ((passed++))
            else
                ((failed++))
            fi
            ((total++))
        fi
    done

    echo ""
    echo "=== 검증 결과 요약 ==="
    echo "총 어댑터: $total"
    print_success "통과: $passed"
    if [ $failed -gt 0 ]; then
        print_error "실패: $failed"
    else
        echo "실패: $failed"
    fi
}

# 레지스트리 동기화 확인
check_sync() {
    echo "레지스트리 동기화 확인..."

    # 디렉토리에 있지만 레지스트리에 없는 것
    for dir in "$ADAPTERS_DIR"/*/; do
        if [ -d "$dir" ]; then
            name=$(basename "$dir")
            if ! jq -e ".adapters.\"$name\"" "$REGISTRY_FILE" > /dev/null 2>&1; then
                print_warning "$name: 디렉토리 O, 레지스트리 X"
            fi
        fi
    done

    # 레지스트리에 있지만 디렉토리가 없는 것
    for key in $(jq -r '.adapters | keys[]' "$REGISTRY_FILE"); do
        if [ ! -d "$ADAPTERS_DIR/$key" ]; then
            print_error "$key: 디렉토리 X, 레지스트리 O"
        fi
    done

    print_success "동기화 확인 완료"
}

# 메인 로직
case "${1:-}" in
    --list|-l)
        list_adapters
        ;;
    --all|-a)
        validate_all
        ;;
    --sync|-s)
        check_sync
        ;;
    --help|-h)
        echo "CLI 어댑터 검증 스크립트"
        echo ""
        echo "사용법: $0 [옵션] [cli-name]"
        echo ""
        echo "옵션:"
        echo "  <cli-name>    특정 CLI 어댑터 검증"
        echo "  --list, -l    등록된 어댑터 목록 출력"
        echo "  --all, -a     모든 어댑터 검증"
        echo "  --sync, -s    레지스트리 동기화 확인"
        echo "  --help, -h    도움말 출력"
        echo ""
        echo "예시:"
        echo "  $0 codex          # codex 어댑터 검증"
        echo "  $0 --all          # 모든 어댑터 검증"
        echo "  $0 --list         # 어댑터 목록 출력"
        ;;
    "")
        echo "사용법: $0 [--list|--all|--sync|cli-name]"
        echo "도움말: $0 --help"
        ;;
    *)
        validate_adapter "$1"
        ;;
esac
