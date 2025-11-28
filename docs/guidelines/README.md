# Guidelines (가이드라인 모음)

> 이 디렉토리는 프로젝트의 모든 가이드라인 문서를 포함합니다.

---

## 가이드라인 목록

| 문서 | 설명 | 대상 |
|------|------|------|
| [development.md](./development.md) | 개발 구현 가이드라인 | 개발자 |
| [tool-creation.md](./tool-creation.md) | Skills/Hooks/Agents/Commands 생성 가이드 | 도구 개발자 |

---

## 가이드라인 사용 흐름

```
instruction.md (원본 지시)
    ↓
requirements.md (프로젝트 요구사항)
    ↓
guidelines/* (구현 가이드라인)
    ↓
실제 개발
```

---

## 각 가이드라인 개요

### development.md
- **목적**: 개발 시 준수해야 할 구현 원칙과 패턴
- **내용**:
  - 코딩 스타일
  - 아키텍처 패턴
  - 테스트 전략
  - 성공 기준

### tool-creation.md
- **목적**: Claude Code 확장 도구 생성 방법
- **내용**:
  - Skills 생성
  - Hooks 작성
  - Sub-agents 정의
  - Commands 개발
  - Rules 설정

---

## 가이드라인 추가 시

새로운 가이드라인을 추가할 때는:

1. **파일 생성**
   ```
   docs/guidelines/{guideline-name}.md
   ```

2. **README 업데이트**
   - 위 표에 새 가이드라인 추가
   - 개요 섹션에 설명 추가

3. **관련 문서 업데이트**
   - `requirements.md`의 파생 문서 표 업데이트
   - `workflows.md`에 필요시 워크플로우 추가

---

## 가이드라인 작성 원칙

1. **공식 소스 기반**
   - Anthropic 공식 문서 참고
   - 검증된 모범 사례만 포함

2. **실행 가능성**
   - 추상적 개념보다 구체적 예시
   - 체크리스트 형태로 검증 가능

3. **일관성**
   - requirements.md와 모순 없도록
   - 다른 가이드라인과 용어 통일

4. **유지보수성**
   - 변경 이력 기록
   - 출처 명시

---

## 변경 이력

- **2025-11-28**: guidelines 디렉토리 생성 및 기존 문서 이동
