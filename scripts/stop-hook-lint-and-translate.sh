#!/bin/bash

# Claude Code Stop Event Hook - Interactive Version
# 변경사항에 대한 린트 및 번역 작업을 사용자가 선택하여 실행합니다.

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# JSON 입력 읽기
INPUT=$(cat)

# stop_hook_active 확인하여 무한 루프 방지
STOP_HOOK_ACTIVE=$(echo "$INPUT" | grep -o '"stop_hook_active":[^,}]*' | cut -d: -f2 | tr -d ' ')
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
  exit 0
fi

# Git 루트 디렉토리 찾기
if ! GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null); then
  exit 0
fi

cd "$GIT_ROOT"

# package.json이 있는지 확인 (OfficeMail 프로젝트 확인)
if [ ! -f "package.json" ]; then
  exit 0
fi

# 변경된 파일 목록 가져오기
CHANGED_FILES=$(git status --porcelain 2>/dev/null | grep -E '^\s*[MAU]' | awk '{print $2}' || true)

if [ -z "$CHANGED_FILES" ]; then
  exit 0
fi

# 변경된 파일 유형 분석
JS_FILES=$(echo "$CHANGED_FILES" | grep -E '\.(js|jsx|ts|tsx)$' || true)
CSS_FILES=$(echo "$CHANGED_FILES" | grep -E '\.(css|scss|less)$' || true)

# 실행 가능한 작업 목록 생성
AVAILABLE_TASKS=()
TASK_DESCRIPTIONS=()

if [ -n "$JS_FILES" ]; then
  AVAILABLE_TASKS+=("eslint")
  TASK_DESCRIPTIONS+=("ESLint (JS/TS 파일 검사)")
  
  # i18n 사용 여부 확인
  I18N_USAGE=$(echo "$JS_FILES" | xargs grep -l -E '\bt\(|i18Key\(' 2>/dev/null || true)
  if [ -n "$I18N_USAGE" ]; then
    AVAILABLE_TASKS+=("i18n")
    TASK_DESCRIPTIONS+=("i18n 번역 업데이트")
  fi
fi

if [ -n "$CSS_FILES" ]; then
  AVAILABLE_TASKS+=("stylelint")
  TASK_DESCRIPTIONS+=("Stylelint (CSS 파일 검사)")
fi

# 실행 가능한 작업이 없으면 종료
if [ ${#AVAILABLE_TASKS[@]} -eq 0 ]; then
  exit 0
fi

# 사용자에게 작업 선택 제안
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔍 변경된 파일 분석 완료${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [ -n "$JS_FILES" ]; then
  JS_COUNT=$(echo "$JS_FILES" | wc -l | tr -d ' ')
  echo -e "  ${GREEN}•${NC} JS/TS 파일: ${JS_COUNT}개"
fi

if [ -n "$CSS_FILES" ]; then
  CSS_COUNT=$(echo "$CSS_FILES" | wc -l | tr -d ' ')
  echo -e "  ${GREEN}•${NC} CSS/SCSS 파일: ${CSS_COUNT}개"
fi

echo ""
echo -e "${YELLOW}실행 가능한 작업:${NC}"
for i in "${!AVAILABLE_TASKS[@]}"; do
  NUM=$((i+1))
  echo -e "  ${NUM}. ${TASK_DESCRIPTIONS[$i]}"
done

echo ""
echo -e "${YELLOW}실행할 작업을 선택하세요:${NC}"
echo -e "  - 숫자를 입력 (예: ${GREEN}1,3${NC})"
echo -e "  - ${GREEN}all${NC}: 모든 작업 실행"
echo -e "  - ${GREEN}n${NC} 또는 ${GREEN}skip${NC}: 건너뛰기"
echo ""
read -p "선택: " USER_CHOICE

# 입력 처리
USER_CHOICE=$(echo "$USER_CHOICE" | tr '[:upper:]' '[:lower:]' | tr -d ' ')

if [ "$USER_CHOICE" = "n" ] || [ "$USER_CHOICE" = "skip" ] || [ -z "$USER_CHOICE" ]; then
  echo -e "${YELLOW}작업을 건너뜁니다.${NC}"
  exit 0
fi

# 선택된 작업 파싱
SELECTED_TASKS=()
if [ "$USER_CHOICE" = "all" ]; then
  SELECTED_TASKS=("${AVAILABLE_TASKS[@]}")
else
  IFS=',' read -ra CHOICES <<< "$USER_CHOICE"
  for choice in "${CHOICES[@]}"; do
    choice=$(echo "$choice" | tr -d ' ')
    if [[ "$choice" =~ ^[0-9]+$ ]]; then
      INDEX=$((choice-1))
      if [ $INDEX -ge 0 ] && [ $INDEX -lt ${#AVAILABLE_TASKS[@]} ]; then
        SELECTED_TASKS+=("${AVAILABLE_TASKS[$INDEX]}")
      fi
    fi
  done
fi

if [ ${#SELECTED_TASKS[@]} -eq 0 ]; then
  echo -e "${YELLOW}선택된 작업이 없습니다.${NC}"
  exit 0
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}선택된 작업:${NC}"
for task in "${SELECTED_TASKS[@]}"; do
  echo -e "  ${GREEN}✓${NC} ${task}"
done
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 임시 디렉토리 생성
TMP_DIR=$(mktemp -d)
trap "rm -rf $TMP_DIR" EXIT

# 각 작업 실행 함수
run_eslint() {
  echo "⏳ ESLint 실행 중..." > "$TMP_DIR/eslint.status"
  
  if ESLINT_OUTPUT=$(npx eslint --quiet $JS_FILES 2>&1); then
    echo "✅ ESLint: 통과" > "$TMP_DIR/eslint.result"
    echo "0" > "$TMP_DIR/eslint.exit"
  else
    echo "❌ ESLint: 오류 발견" > "$TMP_DIR/eslint.result"
    echo "$ESLINT_OUTPUT" > "$TMP_DIR/eslint.output"
    echo "1" > "$TMP_DIR/eslint.exit"
  fi
}

run_stylelint() {
  echo "⏳ Stylelint 실행 중..." > "$TMP_DIR/stylelint.status"
  
  if STYLELINT_OUTPUT=$(npx stylelint $CSS_FILES 2>&1); then
    echo "✅ Stylelint: 통과" > "$TMP_DIR/stylelint.result"
    echo "0" > "$TMP_DIR/stylelint.exit"
  else
    echo "❌ Stylelint: 오류 발견" > "$TMP_DIR/stylelint.result"
    echo "$STYLELINT_OUTPUT" > "$TMP_DIR/stylelint.output"
    echo "1" > "$TMP_DIR/stylelint.exit"
  fi
}

run_i18n() {
  echo "⏳ i18n 업데이트 중..." > "$TMP_DIR/i18n.status"
  
  I18N_USAGE=$(echo "$JS_FILES" | xargs grep -l -E '\bt\(|i18Key\(' 2>/dev/null || true)
  if [ -n "$I18N_USAGE" ]; then
    echo "✅ i18n: 업데이트 필요한 파일 발견" > "$TMP_DIR/i18n.result"
    echo "$I18N_USAGE" > "$TMP_DIR/i18n.files"
    echo "0" > "$TMP_DIR/i18n.exit"
  else
    echo "✅ i18n: 업데이트 필요 없음" > "$TMP_DIR/i18n.result"
    echo "0" > "$TMP_DIR/i18n.exit"
  fi
}

# 병렬 실행
echo -e "${BLUE}작업을 시작합니다...${NC}"
echo ""

declare -A PIDS

for task in "${SELECTED_TASKS[@]}"; do
  case $task in
    "eslint")
      run_eslint &
      PIDS[eslint]=$!
      ;;
    "stylelint")
      run_stylelint &
      PIDS[stylelint]=$!
      ;;
    "i18n")
      run_i18n &
      PIDS[i18n]=$!
      ;;
  esac
done

# 상태 표시
for task in "${!PIDS[@]}"; do
  if [ -f "$TMP_DIR/$task.status" ]; then
    cat "$TMP_DIR/$task.status"
  fi
done

# 모든 작업 완료 대기
for task in "${!PIDS[@]}"; do
  wait ${PIDS[$task]}
done

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}실행 결과:${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 결과 수집
HAS_ERROR=0
ERROR_TASKS=()

for task in "${SELECTED_TASKS[@]}"; do
  if [ -f "$TMP_DIR/$task.result" ]; then
    RESULT=$(cat "$TMP_DIR/$task.result")
    echo -e "  $RESULT"
    
    if [ -f "$TMP_DIR/$task.exit" ]; then
      EXIT_CODE=$(cat "$TMP_DIR/$task.exit")
      if [ "$EXIT_CODE" != "0" ]; then
        HAS_ERROR=1
        ERROR_TASKS+=("$task")
      fi
    fi
  fi
done

echo ""

# 에러 상세 정보 출력
if [ $HAS_ERROR -eq 1 ]; then
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${YELLOW}⚠️  일부 작업이 실패했습니다${NC}"
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  for task in "${ERROR_TASKS[@]}"; do
    echo -e "${RED}▸ ${task} 오류:${NC}"
    
    if [ -f "$TMP_DIR/$task.output" ]; then
      echo ""
      head -15 "$TMP_DIR/$task.output" | sed 's/^/  /'
      echo ""
      
      LINE_COUNT=$(wc -l < "$TMP_DIR/$task.output")
      if [ "$LINE_COUNT" -gt 15 ]; then
        echo -e "  ${YELLOW}... (총 ${LINE_COUNT}줄, 처음 15줄만 표시)${NC}"
        echo ""
      fi
    fi
  done
  
  echo -e "${YELLOW}수정 명령어:${NC}"
  
  for task in "${ERROR_TASKS[@]}"; do
    case $task in
      "eslint")
        echo -e "  ${GREEN}yarn eslint --fix [파일명]${NC}"
        ;;
      "stylelint")
        echo -e "  ${GREEN}yarn stylelint --fix [파일명]${NC}"
        ;;
    esac
  done
  
  echo ""
  echo -e "${YELLOW}계속 진행하시겠습니까? (y/n):${NC}"
  read -p "" CONTINUE_CHOICE
  
  if [ "$CONTINUE_CHOICE" != "y" ] && [ "$CONTINUE_CHOICE" != "Y" ]; then
    echo ""
    echo -e "${RED}작업이 중단되었습니다.${NC}"
    cat <<EOF
{
  "decision": "block",
  "reason": "린트 오류가 발견되었습니다. 위의 명령어로 수정하거나, 다시 시도해주세요."
}
EOF
    exit 2
  fi
fi

# i18n 업데이트 안내
if [[ " ${SELECTED_TASKS[@]} " =~ " i18n " ]]; then
  if [ -f "$TMP_DIR/i18n.files" ]; then
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}📝 i18n 업데이트 필요${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "다음 파일에서 i18n 키가 사용되고 있습니다:"
    cat "$TMP_DIR/i18n.files" | head -5 | sed 's/^/  /'
    
    FILE_COUNT=$(wc -l < "$TMP_DIR/i18n.files")
    if [ "$FILE_COUNT" -gt 5 ]; then
      echo -e "  ${YELLOW}... 외 $((FILE_COUNT - 5))개 파일${NC}"
    fi
    
    echo ""
    echo -e "${YELLOW}💡 번역 텍스트를 업데이트하려면:${NC}"
    echo -e "  ${GREEN}yarn i18n-extract${NC}"
    echo ""
  fi
fi

# 성공 메시지
if [ $HAS_ERROR -eq 0 ]; then
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${GREEN}✅ 모든 작업이 성공적으로 완료되었습니다!${NC}"
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
else
  echo ""
  echo -e "${YELLOW}⚠️  일부 오류가 있지만 계속 진행합니다.${NC}"
fi

echo ""
exit 0
