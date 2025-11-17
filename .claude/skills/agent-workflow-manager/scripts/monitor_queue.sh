#!/bin/bash
#
# monitor_queue.sh - 메시지 큐 실시간 모니터링
#

TASK_ID=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --task-id) TASK_ID="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

echo "=== 메시지 큐 모니터링 ==="
if [ -n "$TASK_ID" ]; then
  echo "Task ID: $TASK_ID"
fi
echo ""

while true; do
  clear
  echo "=== 메시지 큐 상태 $(date +"%Y-%m-%d %H:%M:%S") ==="
  echo ""

  .agent_skills/scripts/check_messages.sh

  if [ -n "$TASK_ID" ]; then
    echo ""
    echo "=== Task $TASK_ID 관련 메시지 ==="
    grep -l "\"task_id\": \"$TASK_ID\"" .agent_skills/messages/*.json 2>/dev/null | while read file; do
      echo "• $(basename $file)"
    done
  fi

  sleep 5
done
