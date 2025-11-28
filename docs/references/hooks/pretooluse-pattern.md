# PreToolUse Hook 패턴 레퍼런스

> 공식 예제: `bash_command_validator_example.py` 기반

**출처**: https://github.com/anthropics/claude-code/blob/main/examples/hooks/bash_command_validator_example.py

---

## 개요

PreToolUse 훅은 **도구 실행 직전**에 실행되어 입력을 검증하고 실행 여부를 제어합니다.

### 주요 특징

- **타이밍**: 도구 호출 직전
- **용도**: 입력 검증, 정책 강제, 명령 차단
- **제어**: 종료 코드로 실행 여부 결정

---

## 입출력 프로토콜

### 입력 (stdin - JSON)

```json
{
  "tool_name": "Bash",
  "tool_input": {
    "command": "grep pattern file.txt"
  }
}
```

**필드**:
- `tool_name`: 호출되는 도구 이름
- `tool_input`: 도구에 전달될 입력 (도구별 상이)

### 출력

**stderr**: 사용자에게 표시할 메시지
```python
print("• Use ripgrep (rg) instead of grep", file=sys.stderr)
```

**종료 코드**:
| 코드 | 의미 | 동작 |
|------|------|------|
| `0` | 통과 | 도구 실행 진행 |
| `1` | 에러 | 사용자에게만 표시 (도구 실행 안 함) |
| `2` | 차단 | Claude에게 차단 신호 전송 |

---

## 공식 예제 코드

```python
#!/usr/bin/env python3
"""
PreToolUse hook for Bash command validation
Enforces performance best practices
"""

import json
import re
import sys

# 검증 규칙 정의
_VALIDATION_RULES = [
    (re.compile(r'\bgrep\b'), "Use ripgrep (rg) instead of grep"),
    (re.compile(r'\bfind\b'), "Use ripgrep (rg) instead of find"),
]

def _validate_command(command: str) -> list[str]:
    """
    명령어를 검증 규칙과 비교

    Args:
        command: 검증할 명령어

    Returns:
        위반 사항 메시지 리스트
    """
    violations = []
    for pattern, message in _VALIDATION_RULES:
        if pattern.search(command):
            violations.append(f"• {message}")
    return violations

def main():
    # stdin에서 JSON 읽기
    try:
        data = json.load(sys.stdin)
    except json.JSONDecodeError as e:
        print(f"Error: Failed to parse JSON: {e}", file=sys.stderr)
        return 1

    # 도구 이름 확인 (Bash만 검증)
    if data.get("tool_name") != "Bash":
        return 0  # 다른 도구는 통과

    # 명령어 추출
    command = data.get("tool_input", {}).get("command", "")
    if not command:
        return 0  # 빈 명령어는 통과

    # 검증 실행
    violations = _validate_command(command)

    if violations:
        # 위반 사항을 stderr로 출력
        print("\n".join(violations), file=sys.stderr)
        return 2  # 차단

    return 0  # 통과

if __name__ == "__main__":
    sys.exit(main())
```

---

## 구현 패턴

### 1. 선언적 규칙 정의

```python
# ✓ Good: 규칙을 데이터로 관리
RULES = [
    (re.compile(r'pattern1'), "Message 1"),
    (re.compile(r'pattern2'), "Message 2"),
]

# ✗ Bad: 하드코딩
if 'grep' in command:
    print("Use rg")
if 'find' in command:
    print("Use rg")
```

### 2. 도구 필터링

```python
# ✓ Good: 관련 도구만 검증
if data.get("tool_name") != "Bash":
    return 0

# ✗ Bad: 모든 도구 검증 시도
```

### 3. 다중 위반 수집

```python
# ✓ Good: 모든 문제를 한 번에 보고
violations = []
for rule in RULES:
    if matches(rule):
        violations.append(message)
return violations

# ✗ Bad: 첫 번째 문제만 보고
for rule in RULES:
    if matches(rule):
        return [message]
```

---

## 사용 예시

### 예제 1: 명령어 금지

```python
_VALIDATION_RULES = [
    (re.compile(r'\brm\s+-rf\s+/'), "Dangerous: rm -rf / is prohibited"),
]
```

### 예제 2: 권장 도구 강제

```python
_VALIDATION_RULES = [
    (re.compile(r'\bcat\b.*\|\s*grep'), "Use grep directly instead of cat | grep"),
]
```

### 예제 3: 파라미터 검증

```python
_VALIDATION_RULES = [
    (re.compile(r'curl\b(?!.*--max-time)'), "Add --max-time to curl commands"),
]
```

---

## 베스트 프랙티스

### ✓ Do

1. **명확한 메시지**: 사용자에게 대안 제시
   ```python
   "Use ripgrep (rg) instead of grep"  # 구체적
   ```

2. **효율적 필터링**: 불필요한 검증 방지
   ```python
   if data.get("tool_name") != "Bash":
       return 0
   ```

3. **에러 처리**: JSON 파싱 실패 대비
   ```python
   try:
       data = json.load(sys.stdin)
   except json.JSONDecodeError:
       return 1
   ```

### ✗ Don't

1. **모호한 메시지**:
   ```python
   "Command not allowed"  # 이유 없음
   ```

2. **과도한 검증**:
   ```python
   # 모든 도구에 대해 복잡한 검증 시도
   ```

3. **긴 실행 시간**:
   ```python
   # 2초 이상 걸리는 검증 로직
   ```

---

## 테스트

### 단위 테스트

```python
def test_grep_detection():
    violations = _validate_command("grep pattern file.txt")
    assert len(violations) == 1
    assert "ripgrep" in violations[0]

def test_safe_command():
    violations = _validate_command("echo hello")
    assert len(violations) == 0
```

### 통합 테스트

```bash
# 훅 테스트
echo '{"tool_name":"Bash","tool_input":{"command":"grep x y"}}' | python hook.py
# Expected: exit code 2, stderr message
```

---

## 관련 문서

- [Hooks README](../../../hooks/README.md)
- [Hook Template](../../../templates/hooks/hook.py.template)
- [공식 예제](https://github.com/anthropics/claude-code/tree/main/examples/hooks)

---

## 변경 이력

- **2025-11-28**: 공식 예제 기반 레퍼런스 작성
