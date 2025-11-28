# Rules (규칙)

> 스킬 활성화 조건 및 우선순위 정의

---

## 디렉토리 구조

```
rules/
└── skill-rules.json  # 규칙 정의
```

---

## skill-rules.json 구조

```json
{
  "version": "1.0",
  "rules": [
    {
      "id": "skill-id",
      "priority": 100,
      "triggers": {
        "keywords": ["keyword1", "keyword2"],
        "patterns": ["regex-pattern"],
        "context": ["context-condition"]
      },
      "conditions": {
        "fileTypes": [".js", ".ts"],
        "minConfidence": 0.8
      },
      "conflicts": ["conflicting-skill-id"],
      "enabled": true
    }
  ]
}
```

---

## 규칙 작성 가이드

### 1. 기본 필드

| 필드 | 타입 | 설명 | 필수 |
|------|------|------|------|
| `id` | string | 스킬 고유 ID | ✓ |
| `priority` | number | 우선순위 (높을수록 우선) | ✓ |
| `triggers` | object | 활성화 트리거 | ✓ |
| `conditions` | object | 추가 조건 | |
| `conflicts` | array | 충돌하는 스킬 ID | |
| `enabled` | boolean | 활성화 여부 | ✓ |

### 2. Triggers (트리거)

**keywords**: 키워드 매칭
```json
"keywords": ["create", "generate", "build"]
```

**patterns**: 정규식 패턴
```json
"patterns": [
  "create.*component",
  "build.*project"
]
```

**context**: 컨텍스트 조건
```json
"context": [
  "has-package-json",
  "is-typescript-project"
]
```

### 3. Conditions (조건)

**fileTypes**: 특정 파일 타입에만 활성화
```json
"fileTypes": [".js", ".jsx", ".ts", ".tsx"]
```

**minConfidence**: 최소 신뢰도 (0.0 ~ 1.0)
```json
"minConfidence": 0.8
```

### 4. Priority (우선순위)

- **1-100**: 낮은 우선순위 (일반 스킬)
- **101-200**: 중간 우선순위 (특화 스킬)
- **201-300**: 높은 우선순위 (핵심 스킬)
- **301+**: 최우선 (시스템 스킬)

---

## 예제

### 예제 1: React 컴포넌트 생성 스킬

```json
{
  "id": "react-component-creator",
  "priority": 150,
  "triggers": {
    "keywords": ["react", "component", "create"],
    "patterns": ["create.*react.*component"],
    "context": ["has-package-json"]
  },
  "conditions": {
    "fileTypes": [".jsx", ".tsx"],
    "minConfidence": 0.7
  },
  "conflicts": ["generic-component-creator"],
  "enabled": true
}
```

### 예제 2: TypeScript 타입 생성 스킬

```json
{
  "id": "typescript-type-generator",
  "priority": 180,
  "triggers": {
    "keywords": ["type", "interface", "typescript"],
    "patterns": ["(create|generate).*(type|interface)"]
  },
  "conditions": {
    "fileTypes": [".ts", ".tsx"],
    "minConfidence": 0.8
  },
  "conflicts": [],
  "enabled": true
}
```

---

## 충돌 해결

### 충돌 감지
두 스킬이 동일한 프롬프트에 매칭되는 경우:
1. `priority` 높은 스킬 우선
2. `priority` 동일 시 `minConfidence` 높은 스킬
3. 여전히 동일 시 먼저 정의된 스킬

### 명시적 충돌 정의
```json
{
  "id": "specific-skill",
  "conflicts": ["general-skill"]
}
```

---

## 체크리스트

규칙 추가 시 확인:
- [ ] JSON 스키마 유효성 검증
- [ ] 중복 ID 없음
- [ ] priority 적절히 설정
- [ ] 충돌하는 스킬 명시
- [ ] 테스트로 활성화 조건 검증

---

## 테스트

### 규칙 검증 스크립트
```bash
npm run validate-rules
```

### 수동 테스트
```bash
# 특정 프롬프트로 어떤 스킬이 활성화되는지 확인
npm run test-rule "create react component"
```

---

## 참고 자료

- [Tool Creation Guide](../docs/guidelines/tool-creation.md)
- [Skill Rules 공식 문서](https://docs.anthropic.com/claude-code/rules)

---

## 변경 이력

- **2025-11-28**: rules 디렉토리 생성
