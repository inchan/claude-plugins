#!/bin/bash

###############################################################################
# Multi-Plugin Migration Script (Enhanced with Error Handling)
#
# 7개 독립 플러그인으로 구조 변경:
# 1. workflow-automation
# 2. dev-guidelines
# 3. tool-creators
# 4. quality-review
# 5. ai-integration
# 6. prompt-enhancement
# 7. utilities
#
# v2.1.0 - Enhanced error handling with rollback support
###############################################################################

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Error handling
trap 'handle_error $? $LINENO' ERR

handle_error() {
    local exit_code=$1
    local line_number=$2
    log_error "마이그레이션 실패 (라인 ${line_number}, 종료 코드: ${exit_code})"
    echo
    log_warning "롤백을 실행하려면: bash scripts/rollback-migration.sh"
    exit $exit_code
}

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Directories
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_DIR="${ROOT_DIR}/src"
PLUGINS_DIR="${ROOT_DIR}/plugins"

log() {
    echo -e "${BLUE}━━━ $1 ━━━${NC}"
}

log_step() {
    echo -e "${CYAN}  ➜ $1${NC}"
}

log_success() {
    echo -e "${GREEN}  ✓ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}  ⚠ $1${NC}"
}

log_error() {
    echo -e "${RED}  ✗ $1${NC}"
}

# Checkpoint tracking
CHECKPOINT_FILE="/tmp/cc-skills-migration-checkpoint.txt"
declare -a COMPLETED_PHASES=()

###############################################################################
# Checkpoint Management
###############################################################################
save_checkpoint() {
    local phase=$1
    echo "$phase" >> "$CHECKPOINT_FILE"
    COMPLETED_PHASES+=("$phase")
    log_success "체크포인트 저장: $phase"
}

is_phase_completed() {
    local phase=$1
    grep -q "^${phase}$" "$CHECKPOINT_FILE" 2>/dev/null
}

###############################################################################
# Phase 1: Create Plugin Directories
###############################################################################
create_plugin_directories() {
    if is_phase_completed "phase1"; then
        log_warning "Phase 1 이미 완료됨 (스킵)"
        return 0
    fi

    log "Phase 1: 플러그인 디렉토리 생성"

    local plugins=(
        "workflow-automation"
        "dev-guidelines"
        "tool-creators"
        "quality-review"
        "ai-integration"
        "prompt-enhancement"
        "utilities"
    )

    for plugin in "${plugins[@]}"; do
        local plugin_dir="${PLUGINS_DIR}/${plugin}"

        log_step "생성 중: ${plugin}"

        # Error handling: check if directory already exists
        if [ -d "$plugin_dir" ]; then
            log_warning "${plugin} 디렉토리 이미 존재"
        else
            if ! mkdir -p "${plugin_dir}"/{.claude-plugin,skills,commands,agents,hooks}; then
                log_error "${plugin} 디렉토리 생성 실패"
                return 1
            fi
            log_success "${plugin} 디렉토리 구조 생성"
        fi
    done

    save_checkpoint "phase1"
    echo
}

###############################################################################
# Phase 2: Move Skills
###############################################################################
move_skills() {
    if is_phase_completed "phase2"; then
        log_warning "Phase 2 이미 완료됨 (스킵)"
        return 0
    fi

    log "Phase 2: 스킬 이동"

    local skills_moved=0
    local skills_failed=0

    # workflow-automation
    log_step "workflow-automation (7개 스킬)"
    local wa_skills=(
        "agent-workflow-manager"
        "agent-workflow-advisor"
        "agent-workflow-orchestrator"
        "intelligent-task-router"
        "sequential-task-processor"
        "parallel-task-executor"
        "dynamic-task-orchestrator"
    )
    for skill in "${wa_skills[@]}"; do
        if [ -d "${SRC_DIR}/skills/${skill}" ]; then
            if cp -r "${SRC_DIR}/skills/${skill}" "${PLUGINS_DIR}/workflow-automation/skills/" 2>/dev/null; then
                echo "    ✓ ${skill}"
                ((skills_moved++))
            else
                log_error "복사 실패: ${skill}"
                ((skills_failed++))
            fi
        else
            log_warning "소스 없음: ${skill}"
        fi
    done


    # dev-guidelines (similar error handling pattern)
    log_step "dev-guidelines (3개 스킬)"
    local dg_skills=(
        "frontend-dev-guidelines"
        "backend-dev-guidelines"
        "error-tracking"
    )
    for skill in "${dg_skills[@]}"; do
        if [ -d "${SRC_DIR}/skills/${skill}" ]; then
            if cp -r "${SRC_DIR}/skills/${skill}" "${PLUGINS_DIR}/dev-guidelines/skills/" 2>/dev/null; then
                echo "    ✓ ${skill}"
                ((skills_moved++))
            else
                log_error "복사 실패: ${skill}"
                ((skills_failed++))
            fi
        else
            log_warning "소스 없음: ${skill}"
        fi
    done

    # tool-creators
    log_step "tool-creators (5개 스킬)"
    local tc_skills=(
        "skill-generator-tool"
        "skill-developer"
        "command-creator"
        "subagent-creator"
        "hooks-creator"
    )
    for skill in "${tc_skills[@]}"; do
        if [ -d "${SRC_DIR}/skills/${skill}" ]; then
            if cp -r "${SRC_DIR}/skills/${skill}" "${PLUGINS_DIR}/tool-creators/skills/" 2>/dev/null; then
                echo "    ✓ ${skill}"
                ((skills_moved++))
            else
                log_error "복사 실패: ${skill}"
                ((skills_failed++))
            fi
        else
            log_warning "소스 없음: ${skill}"
        fi
    done

    # quality-review
    log_step "quality-review (2개 스킬)"
    local qr_skills=(
        "iterative-quality-enhancer"
        "reflection-review"
    )
    for skill in "${qr_skills[@]}"; do
        if [ -d "${SRC_DIR}/skills/${skill}" ]; then
            if cp -r "${SRC_DIR}/skills/${skill}" "${PLUGINS_DIR}/quality-review/skills/" 2>/dev/null; then
                echo "    ✓ ${skill}"
                ((skills_moved++))
            else
                log_error "복사 실패: ${skill}"
                ((skills_failed++))
            fi
        else
            log_warning "소스 없음: ${skill}"
        fi
    done

    # ai-integration
    log_step "ai-integration (3개 스킬)"
    local ai_skills=(
        "dual-ai-loop"
        "cli-updater"
        "cli-adapters"
    )
    for skill in "${ai_skills[@]}"; do
        if [ -d "${SRC_DIR}/skills/${skill}" ]; then
            if cp -r "${SRC_DIR}/skills/${skill}" "${PLUGINS_DIR}/ai-integration/skills/" 2>/dev/null; then
                echo "    ✓ ${skill}"
                ((skills_moved++))
            else
                log_error "복사 실패: ${skill}"
                ((skills_failed++))
            fi
        else
            log_warning "소스 없음: ${skill}"
        fi
    done

    # prompt-enhancement
    log_step "prompt-enhancement (2개 스킬)"
    local pe_skills=(
        "meta-prompt-generator"
        "prompt-enhancer"
    )
    for skill in "${pe_skills[@]}"; do
        if [ -d "${SRC_DIR}/skills/${skill}" ]; then
            if cp -r "${SRC_DIR}/skills/${skill}" "${PLUGINS_DIR}/prompt-enhancement/skills/" 2>/dev/null; then
                echo "    ✓ ${skill}"
                ((skills_moved++))
            else
                log_error "복사 실패: ${skill}"
                ((skills_failed++))
            fi
        else
            log_warning "소스 없음: ${skill}"
        fi
    done

    # utilities
    log_step "utilities (1개 스킬)"
    if [ -d "${SRC_DIR}/skills/route-tester" ]; then
        if cp -r "${SRC_DIR}/skills/route-tester" "${PLUGINS_DIR}/utilities/skills/" 2>/dev/null; then
            echo "    ✓ route-tester"
            ((skills_moved++))
        else
            log_error "복사 실패: route-tester"
            ((skills_failed++))
        fi
    else
        log_warning "소스 없음: route-tester"
    fi

    # Summary
    log_success "스킬 이동 완료: ${skills_moved}개 성공, ${skills_failed}개 실패"

    if [ $skills_failed -gt 0 ]; then
        log_error "일부 스킬 이동 실패 - 마이그레이션 중단"
        return 1
    fi

    save_checkpoint "phase2"
    echo
}

###############################################################################
# Phase 3: Move Commands
###############################################################################
move_commands() {
    if is_phase_completed "phase3"; then
        log_warning "Phase 3 이미 완료됨 (스킵)"
        return 0
    fi

    log "Phase 3: 커맨드 이동"

    log_step "workflow-automation (4개 커맨드)"
    local commands=(
        "auto-workflow.md"
        "workflow-simple.md"
        "workflow-parallel.md"
        "workflow-complex.md"
    )

    local commands_moved=0
    for cmd in "${commands[@]}"; do
        if [ -f "${SRC_DIR}/commands/${cmd}" ]; then
            if cp "${SRC_DIR}/commands/${cmd}" "${PLUGINS_DIR}/workflow-automation/commands/" 2>/dev/null; then
                echo "    ✓ ${cmd}"
                ((commands_moved++))
            else
                log_error "복사 실패: ${cmd}"
                return 1
            fi
        else
            log_warning "소스 없음: ${cmd}"
        fi
    done

    log_success "${commands_moved}개 커맨드 이동 완료"
    save_checkpoint "phase3"
    echo
}

###############################################################################
# Phase 4: Move Agents
###############################################################################
move_agents() {
    if is_phase_completed "phase4"; then
        log_warning "Phase 4 이미 완료됨 (스킵)"
        return 0
    fi

    log "Phase 4: 에이전트 이동"

    local agents_moved=0

    log_step "workflow-automation: workflow-orchestrator"
    if [ -f "${SRC_DIR}/agents/workflow-orchestrator.md" ]; then
        if cp "${SRC_DIR}/agents/workflow-orchestrator.md" "${PLUGINS_DIR}/workflow-automation/agents/" 2>/dev/null; then
            echo "    ✓ workflow-orchestrator.md"
            ((agents_moved++))
        else
            log_error "복사 실패: workflow-orchestrator.md"
            return 1
        fi
    else
        log_warning "소스 없음: workflow-orchestrator.md"
    fi

    log_step "quality-review: code-reviewer, architect"
    for agent in "code-reviewer.md" "architect.md"; do
        if [ -f "${SRC_DIR}/agents/${agent}" ]; then
            if cp "${SRC_DIR}/agents/${agent}" "${PLUGINS_DIR}/quality-review/agents/" 2>/dev/null; then
                echo "    ✓ ${agent}"
                ((agents_moved++))
            else
                log_error "복사 실패: ${agent}"
                return 1
            fi
        else
            log_warning "소스 없음: ${agent}"
        fi
    done

    log_success "${agents_moved}개 에이전트 이동 완료"
    save_checkpoint "phase4"
    echo
}

###############################################################################
# Phase 5: Create plugin.json files
###############################################################################
create_plugin_json() {
    if is_phase_completed "phase5"; then
        log_warning "Phase 5 이미 완료됨 (스킵)"
        return 0
    fi

    log "Phase 5: plugin.json 생성"

    # workflow-automation
    log_step "workflow-automation/plugin.json"
    cat > "${PLUGINS_DIR}/workflow-automation/.claude-plugin/plugin.json" <<'EOF'
{
  "name": "workflow-automation",
  "version": "2.0.0",
  "description": "Task orchestration with complexity-based routing (sequential/parallel/dynamic)",
  "author": {
    "name": "inchan",
    "url": "https://github.com/inchan"
  },
  "license": "MIT",
  "skills": ["./skills"],
  "commands": ["./commands"],
  "agents": ["./agents"]
}
EOF
    log_success "workflow-automation"

    # dev-guidelines
    log_step "dev-guidelines/plugin.json"
    cat > "${PLUGINS_DIR}/dev-guidelines/.claude-plugin/plugin.json" <<'EOF'
{
  "name": "dev-guidelines",
  "version": "2.0.0",
  "description": "Frontend/Backend development patterns and error tracking best practices",
  "author": {
    "name": "inchan",
    "url": "https://github.com/inchan"
  },
  "license": "MIT",
  "skills": ["./skills"]
}
EOF
    log_success "dev-guidelines"

    # tool-creators
    log_step "tool-creators/plugin.json"
    cat > "${PLUGINS_DIR}/tool-creators/.claude-plugin/plugin.json" <<'EOF'
{
  "name": "tool-creators",
  "version": "2.0.0",
  "description": "Create Skills, Commands, Subagents, and Hooks following Anthropic best practices",
  "author": {
    "name": "inchan",
    "url": "https://github.com/inchan"
  },
  "license": "MIT",
  "skills": ["./skills"]
}
EOF
    log_success "tool-creators"

    # quality-review
    log_step "quality-review/plugin.json"
    cat > "${PLUGINS_DIR}/quality-review/.claude-plugin/plugin.json" <<'EOF'
{
  "name": "quality-review",
  "version": "2.0.0",
  "description": "5-dimension quality evaluation and P0/P1/P2 prioritized feedback",
  "author": {
    "name": "inchan",
    "url": "https://github.com/inchan"
  },
  "license": "MIT",
  "skills": ["./skills"],
  "agents": ["./agents"]
}
EOF
    log_success "quality-review"

    # ai-integration
    log_step "ai-integration/plugin.json"
    cat > "${PLUGINS_DIR}/ai-integration/.claude-plugin/plugin.json" <<'EOF'
{
  "name": "ai-integration",
  "version": "2.0.0",
  "description": "External AI CLI integration (codex, qwen, copilot, rovo-dev, aider)",
  "author": {
    "name": "inchan",
    "url": "https://github.com/inchan"
  },
  "license": "MIT",
  "skills": ["./skills"]
}
EOF
    log_success "ai-integration"

    # prompt-enhancement
    log_step "prompt-enhancement/plugin.json"
    cat > "${PLUGINS_DIR}/prompt-enhancement/.claude-plugin/plugin.json" <<'EOF'
{
  "name": "prompt-enhancement",
  "version": "2.0.0",
  "description": "Meta-prompt generation and prompt quality enhancement",
  "author": {
    "name": "inchan",
    "url": "https://github.com/inchan"
  },
  "license": "MIT",
  "skills": ["./skills"]
}
EOF
    log_success "prompt-enhancement"

    # utilities
    log_step "utilities/plugin.json"
    cat > "${PLUGINS_DIR}/utilities/.claude-plugin/plugin.json" <<'EOF'
{
  "name": "utilities",
  "version": "2.0.0",
  "description": "Utility tools for development workflows",
  "author": {
    "name": "inchan",
    "url": "https://github.com/inchan"
  },
  "license": "MIT",
  "skills": ["./skills"]
}
EOF
    log_success "utilities"

    save_checkpoint "phase5"
    echo
}

###############################################################################
# Phase 6: Update marketplace.json
###############################################################################
update_marketplace_json() {
    if is_phase_completed "phase6"; then
        log_warning "Phase 6 이미 완료됨 (스킵)"
        return 0
    fi

    log "Phase 6: marketplace.json 업데이트"

    cat > "${ROOT_DIR}/.claude-plugin/marketplace.json" <<'EOF'
{
  "name": "inchan-cc-skills",
  "owner": {
    "name": "inchan"
  },
  "metadata": {
    "description": "Modular Claude Code plugins collection - workflow automation, dev guidelines, quality tools",
    "homepage": "https://github.com/inchan/cc-skills"
  },
  "plugins": [
    {
      "name": "workflow-automation",
      "version": "2.0.0",
      "source": "./plugins/workflow-automation",
      "description": "Task orchestration with complexity-based routing"
    },
    {
      "name": "dev-guidelines",
      "version": "2.0.0",
      "source": "./plugins/dev-guidelines",
      "description": "Frontend/Backend development patterns"
    },
    {
      "name": "tool-creators",
      "version": "2.0.0",
      "source": "./plugins/tool-creators",
      "description": "Create Skills/Commands/Agents/Hooks"
    },
    {
      "name": "quality-review",
      "version": "2.0.0",
      "source": "./plugins/quality-review",
      "description": "Code quality evaluation and review"
    },
    {
      "name": "ai-integration",
      "version": "2.0.0",
      "source": "./plugins/ai-integration",
      "description": "External AI CLI integration"
    },
    {
      "name": "prompt-enhancement",
      "version": "2.0.0",
      "source": "./plugins/prompt-enhancement",
      "description": "Meta-prompt generation"
    },
    {
      "name": "utilities",
      "version": "2.0.0",
      "source": "./plugins/utilities",
      "description": "Utility tools"
    }
  ]
}
EOF

    # Validate JSON
    if ! node -e "JSON.parse(require('fs').readFileSync('${ROOT_DIR}/.claude-plugin/marketplace.json'))" 2>/dev/null; then
        log_error "marketplace.json JSON 오류"
        return 1
    fi

    log_success "marketplace.json 업데이트 완료"
    save_checkpoint "phase6"
    echo
}

###############################################################################
# Phase 7: Copy hooks to root
###############################################################################
copy_hooks() {
    if is_phase_completed "phase7"; then
        log_warning "Phase 7 이미 완료됨 (스킵)"
        return 0
    fi

    log "Phase 7: hooks 복사 (루트 유지)"

    mkdir -p "${ROOT_DIR}/hooks"

    if [ -d "${SRC_DIR}/hooks" ]; then
        if cp -r "${SRC_DIR}/hooks/"* "${ROOT_DIR}/hooks/" 2>/dev/null; then
            log_success "hooks 디렉토리 복사 완료"
        else
            log_warning "일부 hooks 파일 복사 실패 (무시)"
        fi
    else
        log_warning "src/hooks 디렉토리 없음"
    fi

    save_checkpoint "phase7"
    echo
}

###############################################################################
# Phase 8: Validation
###############################################################################
validate_migration() {
    log "Phase 8: 마이그레이션 검증"

    local errors=0

    # Check plugin directories
    log_step "플러그인 디렉토리 확인"
    local plugins=(
        "workflow-automation"
        "dev-guidelines"
        "tool-creators"
        "quality-review"
        "ai-integration"
        "prompt-enhancement"
        "utilities"
    )

    for plugin in "${plugins[@]}"; do
        if [ ! -d "${PLUGINS_DIR}/${plugin}" ]; then
            log_error "${plugin} 디렉토리 없음"
            ((errors++))
        elif [ ! -f "${PLUGINS_DIR}/${plugin}/.claude-plugin/plugin.json" ]; then
            log_error "${plugin}/plugin.json 없음"
            ((errors++))
        else
            echo "    ✓ ${plugin}"
        fi
    done

    # Check marketplace.json
    log_step "marketplace.json 확인"
    if [ -f "${ROOT_DIR}/.claude-plugin/marketplace.json" ]; then
        if node -e "JSON.parse(require('fs').readFileSync('${ROOT_DIR}/.claude-plugin/marketplace.json'))" 2>/dev/null; then
            echo "    ✓ marketplace.json (유효한 JSON)"
        else
            log_error "marketplace.json JSON 오류"
            ((errors++))
        fi
    else
        log_error "marketplace.json 없음"
        ((errors++))
    fi

    echo

    if [ $errors -eq 0 ]; then
        log_success "✅ 모든 검증 통과"
        return 0
    else
        log_error "❌ $errors 개 오류 발견"
        return 1
    fi
}

###############################################################################
# Phase 9: Summary
###############################################################################
print_summary() {
    echo
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  마이그레이션 완료${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    echo "생성된 플러그인:"
    echo "  1. workflow-automation (7 스킬, 4 커맨드, 1 에이전트)"
    echo "  2. dev-guidelines (3 스킬)"
    echo "  3. tool-creators (5 스킬)"
    echo "  4. quality-review (2 스킬, 2 에이전트)"
    echo "  5. ai-integration (3 스킬)"
    echo "  6. prompt-enhancement (2 스킬)"
    echo "  7. utilities (1 스킬)"
    echo
    echo "총계: 23 스킬, 4 커맨드, 3 에이전트"
    echo
    echo "다음 단계:"
    echo "  1. git status 확인"
    echo "  2. 변경사항 검토"
    echo "  3. 커밋 및 푸시"
    echo
}

###############################################################################
# Main Execution
###############################################################################
main() {
    echo
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  Multi-Plugin Migration (Enhanced)${NC}"
    echo -e "${BLUE}  23 skills → 7 independent plugins${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo

    # Initialize checkpoint file
    if [ ! -f "$CHECKPOINT_FILE" ]; then
        touch "$CHECKPOINT_FILE"
        log_step "체크포인트 파일 초기화: $CHECKPOINT_FILE"
    else
        log_warning "이전 체크포인트 발견 - 중단된 마이그레이션 재개"
        cat "$CHECKPOINT_FILE"
        echo
    fi

    # Check if src/ exists
    if [ ! -d "${SRC_DIR}" ]; then
        log_error "src/ 디렉토리가 없습니다"
        echo "src/ 복원 방법:"
        echo "  git checkout 990ed11 -- src/"
        exit 1
    fi

    # Pre-flight checks
    log_step "사전 확인: node 설치 여부"
    if ! command -v node &> /dev/null; then
        log_error "node.js가 설치되어 있지 않습니다"
        exit 1
    fi
    log_success "node.js 사용 가능"
    echo

    # Execute phases with error handling
    set +e  # Don't exit on error for individual phases

    create_plugin_directories || { log_error "Phase 1 실패"; exit 1; }
    move_skills || { log_error "Phase 2 실패"; exit 1; }
    move_commands || { log_error "Phase 3 실패"; exit 1; }
    move_agents || { log_error "Phase 4 실패"; exit 1; }
    create_plugin_json || { log_error "Phase 5 실패"; exit 1; }
    update_marketplace_json || { log_error "Phase 6 실패"; exit 1; }
    copy_hooks || { log_error "Phase 7 실패"; exit 1; }

    set -e  # Re-enable exit on error

    # Validation
    if validate_migration; then
        # Clean up checkpoint file on success
        rm -f "$CHECKPOINT_FILE"
        print_summary
        exit 0
    else
        log_error "마이그레이션 검증 실패"
        log_warning "체크포인트 파일 유지: $CHECKPOINT_FILE"
        exit 1
    fi
}

# Run main
main
