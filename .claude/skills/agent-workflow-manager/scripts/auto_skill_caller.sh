#!/bin/bash
#
# auto_skill_caller.sh - 다음 스킬 자동 호출 가이드
#

CURRENT_SKILL=""
TASK_ID=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --current-skill) CURRENT_SKILL="$2"; shift 2 ;;
    --task-id) TASK_ID="$2"; shift 2 ;;
    *) shift ;;
  esac
done

echo "=== 다음 스킬 호출 가이드 ==="
echo ""

case $CURRENT_SKILL in
  router)
    # Router 메시지 확인
    TARGET=$(find .agent_skills/messages -name "*${TASK_ID}*.json" -exec grep -l "\"source_skill\": \"router\"" {} \; | head -1 | xargs grep -o '"target_skill"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)

    if [ -n "$TARGET" ]; then
      echo "✓ Router 완료"
      echo "  Target: $TARGET"
      echo ""
      echo "💡 다음 명령 실행:"
      echo "   '${TARGET} 스킬로 ${TASK_ID} 작업 처리해줘'"
    fi
    ;;

  sequential|parallel)
    echo "✓ ${CURRENT_SKILL} 완료"
    echo ""
    echo "💡 다음 명령 실행:"
    echo "   'Evaluator 스킬로 ${TASK_ID} 작업 평가해줘'"
    ;;

  orchestrator)
    echo "✓ Orchestrator 조율 완료"
    echo ""
    echo "💡 다음 명령 실행:"
    echo "   'Evaluator로 전체 프로젝트 종합 평가해줘'"
    ;;

  evaluator)
    echo "✓ Evaluator 평가 완료"
    echo ""
    echo "🎉 워크플로우 완료!"
    ;;

  *)
    echo "❌ Unknown skill: $CURRENT_SKILL"
    ;;
esac
