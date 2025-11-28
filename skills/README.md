# Skills (스킬)

> 사용자 프롬프트에 자동 또는 수동으로 활성화되는 확장 기능

---

## 디렉토리 구조

```
skills/
└── {skill-name}/
    ├── SKILL.md          # 스킬 정의 (필수)
    ├── resources/        # 참고 자료 (선택)
    │   └── *.md
    └── scripts/          # 실행 스크립트 (선택)
        └── *.py|*.sh
```

---

## 스킬 생성 가이드

### 1. 디렉토리 생성
```bash
mkdir -p skills/{skill-name}/{resources,scripts}
```

### 2. SKILL.md 작성

**필수 섹션**:
- **id**: 고유 식별자
- **trigger**: 활성화 조건 (키워드, 패턴)
- **description**: 스킬 설명
- **instructions**: 실행 지시사항

**예시**:
```markdown
---
id: example-skill
trigger:
  - keywords: ["example", "demo"]
  - patterns: ["create.*example"]
---

# Example Skill

## Description
이 스킬은 예제를 생성합니다.

## Instructions
1. 사용자 요청 분석
2. 예제 템플릿 로드
3. 커스터마이징 후 출력
```

### 3. 테스트 작성
```bash
touch tests/skills/{skill-name}.test.js
```

---

## 체크리스트

스킬 개발 전 확인:
- [ ] requirements.md의 요구사항 확인
- [ ] 공식 문서에서 유사 패턴 조사
- [ ] SKILL.md 필수 섹션 작성
- [ ] 테스트 커버리지 80% 이상
- [ ] rules/skill-rules.json에 규칙 추가

---

## 참고 자료

- [Tool Creation Guide](../docs/guidelines/tool-creation.md)
- [Development Guidelines](../docs/guidelines/development.md)
- [Anthropic 공식 문서](https://docs.anthropic.com/claude-code)

---

## 변경 이력

- **2025-11-28**: skills 디렉토리 생성
