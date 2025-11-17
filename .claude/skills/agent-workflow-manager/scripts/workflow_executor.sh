#!/bin/bash
#
# workflow_executor.sh - 워크플로우 자동 실행 스크립트
#

set -e

PATTERN=""
TASK_ID=""
REQUEST=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --pattern) PATTERN="$2"; shift 2 ;;
    --task-id) TASK_ID="$2"; shift 2 ;;
    --request) REQUEST="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

if [ -z "$PATTERN" ] || [ -z "$TASK_ID" ]; then
  echo "Usage: $0 --pattern <simple|parallel|complex> --task-id <id> --request <request>"
  exit 1
fi

echo "╔══════════════════════════════════════════════════════╗"
echo "║  Workflow Executor                                   ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
echo "Pattern: $PATTERN"
echo "Task ID: $TASK_ID"
echo "Request: $REQUEST"
echo ""

case $PATTERN in
  simple)
    echo "🔄 Simple Workflow 실행..."
    echo ""
    echo "Step 1: Router Classification"
    .agent_skills/scripts/send_message.sh router sequential execute_task "$TASK_ID" "{\"description\":\"$REQUEST\"}"
    echo "✓ Router 완료"
    echo ""
    echo "💡 다음 명령 실행:"
    echo "   'Sequential 스킬로 $TASK_ID 작업 처리해줘'"
    ;;

  parallel)
    echo "🔄 Parallel Workflow 실행..."
    echo ""
    echo "Step 1: Router Analysis"
    .agent_skills/scripts/send_message.sh router parallel execute_task "$TASK_ID" "{\"description\":\"$REQUEST\"}"
    echo "✓ Router 완료"
    echo ""
    echo "💡 다음 명령 실행:"
    echo "   'Parallel 스킬로 $TASK_ID 작업 병렬 처리해줘'"
    ;;

  complex)
    echo "🔄 Complex Workflow 실행..."
    echo ""
    echo "Step 1: Router Project Analysis"
    PROJECT_ID="project_${TASK_ID}"
    .agent_skills/scripts/send_message.sh router orchestrator execute_task "$TASK_ID" "{\"description\":\"$REQUEST\",\"project_id\":\"$PROJECT_ID\"}"
    echo "✓ Router 완료"
    echo ""
    echo "💡 다음 명령 실행:"
    echo "   'Orchestrator 스킬로 $PROJECT_ID 프로젝트 조율해줘'"
    ;;

  *)
    echo "❌ Unknown pattern: $PATTERN"
    exit 1
    ;;
esac

echo ""
echo "📝 메시지 큐 확인:"
echo "   .agent_skills/scripts/check_messages.sh"
