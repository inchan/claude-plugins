# Instruction (지시사항 기록)

> 이 문서는 프로젝트의 원본 지시사항을 시간순으로 기록합니다.
> 지시사항은 `requirements.md`로 구체화되어 프로젝트 요구사항이 됩니다.

---

## 2025-11-28: 프로젝트 방향 설정

### 원본 지시

> 우리는 클로드코드의 공식사이트, 공식문서, 공식블로그, 공식샘플, 공식모범사례와 신뢰도가 있는 사이트를 참고하여 skills, hooks, sub-agents, command, rules를 생성하고 개선하며, 마켓플레이스와 플러그인으로 만들어서 배포할 예정입니다.

### 핵심 키워드

- **참고 대상**: 공식사이트, 공식문서, 공식블로그, 공식샘플, 공식모범사례, 신뢰도 있는 사이트
- **개발 대상**: skills, hooks, sub-agents, command, rules
- **활동**: 생성, 개선
- **목표**: 마켓플레이스 배포, 플러그인 형태

---

## 2025-11-28: 프로젝트 구조 결정

### 원본 지시

> 모두 루트에 있게 해주세요.

### 의미

- Skills, Hooks, Sub-agents, Commands, Rules를 루트 디렉토리에 직접 배치
- `plugins/` 구조가 아닌 평면적 구조 채택

---

## 2025-11-28: 문서 분리 결정

### 원본 지시

> 기존을 instruction과 requirements로 분리하고싶어 내가 지시한사항과 그 지시한사항을 반영한 요구사항

### 의미

- `instruction.md`: 원본 지시사항만 기록
- `requirements.md`: 지시사항을 구체화한 요구사항 정의

---

## 문서 관계

```
instruction.md (원본 지시)
    ↓ 구체화
requirements.md (프로젝트 요구사항)
    ↓ 적용
dev-guidelines.md, TOOL-CREATION-GUIDE.md 등
```

---

## 업데이트 프로세스

### 1. 새로운 지시사항이 생길 때

**단계**:
1. `instruction.md`에 새로운 섹션 추가
   ```markdown
   ## YYYY-MM-DD: {제목}

   ### 원본 지시
   > {사용자의 원본 지시를 그대로 인용}

   ### 핵심 키워드
   - {핵심 개념 추출}
   ```

2. `requirements.md` 해당 섹션 업데이트
   - 지시사항을 구체적 요구사항으로 변환
   - 체크리스트 추가
   - 변경 이력 기록

3. 영향받는 다른 문서 업데이트
   - `guidelines/development.md`
   - `guidelines/tool-creation.md`
   - 기타 관련 문서

### 2. 지시사항 해석이 필요할 때

**원칙**:
- 추측하지 않음
- 사용자에게 명확히 질문
- 확인 후 instruction.md에 기록

**예시**:
```
사용자: "더 빠르게 만들어주세요"
에이전트: "어떤 부분을 빠르게 만들까요?"
         1. 빌드 속도
         2. 실행 속도
         3. 개발 속도

확인 후 → instruction.md 기록
```

### 3. 문서 동기화 규칙

**필수**:
- instruction.md 변경 시 반드시 requirements.md 검토
- requirements.md 변경 시 변경 이력에 출처 명시
- 모순 발견 시 instruction.md가 우선

---

## 변경 이력

- **2025-11-28**: 초기 지시사항 기록
- **2025-11-28**: 루트 기반 구조 결정
- **2025-11-28**: instruction/requirements 문서 분리 결정
