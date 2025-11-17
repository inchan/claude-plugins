# Feature Development Routing Example

## 사용자 요청
"사용자가 프로필 이미지를 업로드하고 편집할 수 있는 기능을 추가해주세요. 이미지 크기 조절과 필터 적용도 지원해야 합니다."

## 라우팅 분석 과정

### 1. Keyword Classification
```json
{
  "extracted_keywords": ["기능", "추가", "업로드", "편집", "이미지", "크기", "필터"],
  "category_scores": {
    "feature_development": 0.85,
    "data_processing": 0.30,
    "testing": 0.10
  }
}
```

### 2. Intent Classification
```json
{
  "intent": "create",
  "confidence": 0.90,
  "action_verbs": ["추가", "업로드", "편집"],
  "is_question": false
}
```

### 3. Complexity Analysis
```json
{
  "complexity_score": 0.75,
  "scope_score": 0.7,
  "dependency_score": 0.6,
  "technical_depth_score": 0.8,
  "effort_level": "high",
  "estimated_minutes": 90
}
```

### 4. Feature Analysis
- **다중 기능 요구사항**: 업로드, 편집, 크기 조절, 필터
- **파일 처리**: 이미지 업로드 및 변환
- **UI 컴포넌트**: 프로필 이미지 편집 인터페이스

## 라우팅 결정

```json
{
  "task_id": "task_20250111_002",
  "classification": {
    "primary": "feature_development",
    "secondary": ["data_processing"],
    "confidence": 0.90
  },
  "routing": {
    "target_skill": "dynamic-orchestrator",
    "model": "claude-3-opus",
    "priority": "medium"
  },
  "metadata": {
    "complexity_score": 0.75,
    "estimated_minutes": 90,
    "requires_clarification": false,
    "multi_component": true
  }
}
```

## 실행 워크플로우

1. **Dynamic Orchestrator** 활성화
2. Claude 3 Opus 모델 사용 (높은 복잡도)
3. 작업 분해:

   **Phase 1: 설계**
   - 이미지 업로드 플로우 설계
   - 편집 기능 아키텍처 설계
   - 데이터 모델 정의

   **Phase 2: 백엔드 구현**
   - 이미지 업로드 API
   - 이미지 처리 서비스 (크기 조절, 필터)
   - 파일 스토리지 통합

   **Phase 3: 프론트엔드 구현**
   - 프로필 이미지 업로드 UI
   - 이미지 편집 인터페이스
   - 크기 조절 및 필터 컨트롤

   **Phase 4: 통합 및 테스트**
   - 컴포넌트 통합
   - 테스트 작성
   - 성능 최적화

## Sub-task Routing

Orchestrator는 각 sub-task를 추가 라우팅할 수 있습니다:

- **이미지 처리 로직** → `data_processing` → parallel-executor
- **API 엔드포인트** → `feature_development` → sequential-task-processor
- **UI 컴포넌트** → `feature_development` → sequential-task-processor
- **테스트 작성** → `testing` → parallel-executor

## 예상 결과
- 완전한 프로필 이미지 업로드/편집 기능
- 백엔드 API 및 이미지 처리 서비스
- 프론트엔드 UI 컴포넌트
- 통합 테스트 및 문서화
