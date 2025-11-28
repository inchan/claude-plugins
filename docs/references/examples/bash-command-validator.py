#!/usr/bin/env python3
"""
공식 예제: bash_command_validator_example.py

출처: https://github.com/anthropics/claude-code/blob/main/examples/hooks/bash_command_validator_example.py

이 훅은 Bash 명령어 실행 전에 성능 최적화를 위한 검증을 수행합니다.
PreToolUse 훅으로 동작하며, 명령어가 권장 도구를 사용하는지 확인합니다.
"""

import json
import re
import sys
from typing import List, Tuple

# 검증 규칙 정의
# (정규식 패턴, 에러 메시지) 튜플 리스트
_VALIDATION_RULES: List[Tuple[re.Pattern, str]] = [
    (re.compile(r'\bgrep\b'), "Use ripgrep (rg) instead of grep for better performance"),
    (re.compile(r'\bfind\b'), "Use ripgrep (rg) instead of find for better performance"),
]


def _validate_command(command: str) -> List[str]:
    """
    명령어를 검증 규칙과 비교하여 위반 사항을 확인합니다.

    Args:
        command: 검증할 Bash 명령어

    Returns:
        위반 사항 메시지 리스트. 빈 리스트면 통과.
    """
    violations = []

    for pattern, message in _VALIDATION_RULES:
        if pattern.search(command):
            violations.append(f"• {message}")

    return violations


def main() -> int:
    """
    메인 훅 로직

    Returns:
        종료 코드:
        - 0: 통과 (도구 실행 진행)
        - 1: JSON 파싱 실패 (사용자에게만 표시)
        - 2: 검증 실패 (Claude에게 차단 신호)
    """
    try:
        # stdin에서 JSON 데이터 읽기
        data = json.load(sys.stdin)
    except json.JSONDecodeError as e:
        print(f"Error: Failed to parse JSON input: {e}", file=sys.stderr)
        return 1

    # 도구 이름 확인 (Bash가 아니면 패스)
    tool_name = data.get("tool_name")
    if tool_name != "Bash":
        return 0

    # 명령어 추출
    tool_input = data.get("tool_input", {})
    command = tool_input.get("command", "")

    if not command:
        # 빈 명령어는 통과
        return 0

    # 명령어 검증
    violations = _validate_command(command)

    if violations:
        # 위반 사항을 stderr로 출력
        # Claude가 이 메시지를 읽고 사용자에게 전달
        print("\n".join(violations), file=sys.stderr)
        return 2  # 차단

    return 0  # 통과


if __name__ == "__main__":
    sys.exit(main())
