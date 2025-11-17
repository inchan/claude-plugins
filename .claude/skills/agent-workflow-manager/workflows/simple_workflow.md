# Simple Workflow Pattern

**Router → Sequential → Evaluator**

## 적용 조건
- Complexity < 0.7
- 단일 파일/기능 수정
- 버그 수정, 소규모 기능 추가

## 실행 흐름

### 1. Router Classification
```bash
.agent_skills/scripts/send_message.sh router sequential execute_task ${TASK_ID} '{...}'
```

### 2. Sequential Processing (5단계)
- Requirements Analysis
- Design
- Implementation
- Testing
- Documentation

### 3. Evaluator Quality Check
- 5개 차원 평가
- 피드백 루프 (필요 시)

## 예상 소요 시간
30-60분
