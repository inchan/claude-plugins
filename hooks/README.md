# Hooks (훅)

> 특정 이벤트 발생 시 실행되는 자동화 스크립트

---

## 디렉토리 구조

```
hooks/
├── hooks.json        # 훅 정의 (필수)
├── {hook-name}.py    # Python 훅
└── {hook-name}.sh    # Shell 훅
```

---

## 훅 생성 가이드

### 1. hooks.json 업데이트

```json
{
  "hooks": {
    "session-start": {
      "script": "./hooks/session-start.py",
      "description": "세션 시작 시 초기화"
    },
    "user-prompt-submit": {
      "script": "./hooks/prompt-analyzer.sh",
      "description": "프롬프트 분석 및 향상"
    }
  }
}
```

### 2. 훅 스크립트 작성

**Python 예시**:
```python
#!/usr/bin/env python3
"""
Hook: session-start
Description: 세션 시작 시 초기화
"""
import sys
import json

def main():
    # 훅 로직
    print("Session initialized")
    return 0

if __name__ == "__main__":
    sys.exit(main())
```

**Shell 예시**:
```bash
#!/bin/bash
# Hook: user-prompt-submit
# Description: 프롬프트 분석

PROMPT="$1"
echo "Analyzing prompt: $PROMPT"
```

### 3. 실행 권한 부여
```bash
chmod +x hooks/{hook-name}.py
chmod +x hooks/{hook-name}.sh
```

---

## 지원 이벤트

| 이벤트 | 설명 | 타이밍 |
|--------|------|--------|
| `session-start` | 세션 시작 | Claude Code 실행 시 |
| `user-prompt-submit` | 프롬프트 제출 | 사용자 입력 후 |
| `pre-tool-use` | 도구 사용 전 | 도구 실행 전 |
| `post-tool-use` | 도구 사용 후 | 도구 실행 후 |
| `stop` | 세션 종료 | Claude Code 종료 시 |

---

## 체크리스트

훅 개발 전 확인:
- [ ] hooks.json에 훅 등록
- [ ] 에러 처리 로직 포함
- [ ] 실행 시간 2초 이내 (성능 요구사항)
- [ ] 테스트 작성
- [ ] 실행 권한 설정

---

## 성능 가이드

- **타임아웃**: 각 훅은 2초 이내 실행
- **비동기 처리**: 긴 작업은 백그라운드로
- **에러 핸들링**: 실패 시 전체 워크플로우 중단 방지

---

## 참고 자료

- [Tool Creation Guide](../docs/guidelines/tool-creation.md)
- [Hooks 공식 문서](https://docs.anthropic.com/claude-code/hooks)

---

## 변경 이력

- **2025-11-28**: hooks 디렉토리 생성
