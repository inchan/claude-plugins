# Hook 이벤트 타입 레퍼런스

> Claude Code에서 지원하는 훅 이벤트 종류

---

## 확인된 이벤트

### PreToolUse

**타이밍**: 도구 실행 직전

**용도**:
- 입력 검증
- 명령어 정책 강제
- 위험한 동작 차단

**입력**:
```json
{
  "tool_name": "Bash",
  "tool_input": {...}
}
```

**출력**: 종료 코드 (0=통과, 1=에러, 2=차단)

**공식 예제**: `bash_command_validator_example.py`

---

## 추정 이벤트 (확인 필요)

다음 이벤트들은 일반적인 훅 시스템에서 지원되나, Claude Code 공식 문서에서 미확인:

### PostToolUse

**타이밍**: 도구 실행 직후

**용도**:
- 결과 검증
- 로깅
- 후처리

### SessionStart

**타이밍**: Claude Code 세션 시작

**용도**:
- 초기화
- 환경 설정
- 캐시 로드

### SessionEnd

**타이밍**: Claude Code 세션 종료

**용도**:
- 정리 작업
- 로그 저장
- 리소스 해제

### UserPromptSubmit

**타이밍**: 사용자 프롬프트 제출 시

**용도**:
- 프롬프트 분석
- 프롬프트 향상
- 통계 수집

---

## hooks.json 형식 (추정)

```json
{
  "hooks": {
    "pre-tool-use": {
      "script": "./hooks/validator.py",
      "description": "도구 실행 전 검증",
      "enabled": true
    },
    "post-tool-use": {
      "script": "./hooks/logger.py",
      "description": "도구 실행 후 로깅",
      "enabled": true
    },
    "session-start": {
      "script": "./hooks/init.sh",
      "description": "세션 초기화",
      "enabled": true
    }
  }
}
```

---

## 추가 조사 필요

- [ ] 전체 이벤트 타입 목록
- [ ] 각 이벤트의 입출력 형식
- [ ] hooks.json 공식 스키마
- [ ] 이벤트 실행 순서
- [ ] 이벤트 간 데이터 전달 방법

---

## 관련 문서

- [PreToolUse Pattern](./pretooluse-pattern.md)
- [Hooks README](../../../hooks/README.md)

---

## 변경 이력

- **2025-11-28**: 초기 작성 (PreToolUse 확인, 나머지 추정)
