# Bug Fix Routing Example

## 사용자 요청
"로그인 페이지에서 비밀번호 입력 시 에러가 발생합니다. 수정해주세요."

## 라우팅 분석 과정

### 1. Keyword Classification
```json
{
  "extracted_keywords": ["로그인", "비밀번호", "에러", "수정"],
  "category_scores": {
    "bug_fix": 0.75,
    "security": 0.25,
    "feature_development": 0.0
  }
}
```

### 2. Intent Classification
```json
{
  "intent": "debug",
  "confidence": 0.85,
  "action_verbs": ["수정"],
  "is_question": false
}
```

### 3. Complexity Analysis
```json
{
  "complexity_score": 0.45,
  "scope_score": 0.3,
  "dependency_score": 0.4,
  "technical_depth_score": 0.5,
  "effort_level": "medium",
  "estimated_minutes": 45
}
```

### 4. Urgency Detection
```json
{
  "urgency_level": "medium",
  "indicators_found": ["에러"]
}
```

## 라우팅 결정

```json
{
  "task_id": "task_20250111_001",
  "classification": {
    "primary": "bug_fix",
    "secondary": ["security"],
    "confidence": 0.85
  },
  "routing": {
    "target_skill": "sequential-task-processor",
    "model": "claude-3-sonnet",
    "priority": "medium"
  },
  "metadata": {
    "complexity_score": 0.45,
    "estimated_minutes": 45,
    "requires_clarification": false
  }
}
```

## 실행 워크플로우

1. **Sequential Task Processor** 활성화
2. Claude 3 Sonnet 모델 사용
3. 작업 단계:
   - 로그인 페이지 코드 분석
   - 비밀번호 입력 관련 버그 식별
   - 보안 측면 검토 (부 카테고리: security)
   - 수정 사항 구현
   - 테스트 및 검증

## 예상 결과
- 버그 수정 완료
- 보안 관련 개선사항 제안 (해당되는 경우)
- 테스트 케이스 추가 권장
