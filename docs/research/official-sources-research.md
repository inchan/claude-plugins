# 공식 소스 조사 결과

> Anthropic 공식 자료 기반 Claude Code 확장 기능 패턴 조사

**조사 날짜**: 2025-11-28
**조사 대상**: GitHub 공식 저장소, 공식 문서

---

## 1. 공식 저장소 정보

### GitHub Repository
- **URL**: https://github.com/anthropics/claude-code
- **통계**: 43.8k stars, 3k forks, 1.2k dependencies
- **설명**: 터미널 기반 에이전트 코딩 도구

### 공식 문서
- **URL**: https://docs.anthropic.com/en/docs/claude-code/overview
- **상태**: 리다이렉트 발생 (platform.claude.com으로 이동)
- **접근 이슈**: 일부 문서 경로 404 오류

---

## 2. 플러그인 구조 (공식 표준)

### 표준 디렉토리 구조

```
plugin-name/
├── .claude-plugin/
│   └── plugin.json          # 플러그인 메타데이터
├── commands/                # 슬래시 커맨드
├── agents/                  # 전문화된 에이전트
├── skills/                  # 스킬 (선택)
├── hooks/                   # 이벤트 훅 (선택)
├── .mcp.json               # MCP 서버 설정 (선택)
└── README.md               # 문서
```

### 확인된 플러그인 예제

| 플러그인 | 기능 | 구성 요소 |
|---------|------|-----------|
| **code-review** | 자동화된 PR 리뷰 | 다중 전문 에이전트, `/code-review` 커맨드 |
| **feature-dev** | 구조화된 기능 개발 | 7단계 워크플로우 |
| **plugin-dev** | 플러그인 생성 지원 | 8단계 안내 워크플로우, 검증 및 리뷰 에이전트 |

---

## 3. Hooks 패턴 (공식 예제)

### bash_command_validator_example.py

**위치**: `examples/hooks/bash_command_validator_example.py`

#### 핵심 패턴

1. **이벤트 타입**: PreToolUse 훅
   - Bash 도구 호출 직전에 실행
   - 명령어 검증 및 차단 가능

2. **입력 형식** (JSON via stdin):
```json
{
  "tool_name": "Bash",
  "tool_input": {
    "command": "grep pattern file.txt"
  }
}
```

3. **종료 코드 규칙**:
   - `0`: 통과 (도구 실행 진행)
   - `1`: JSON 파싱 실패 (사용자에게만 표시)
   - `2`: 검증 실패 (Claude에게 차단 신호)

4. **코드 구조**:
```python
#!/usr/bin/env python3
import json
import re
import sys

# 검증 규칙 정의
_VALIDATION_RULES = [
    (re.compile(r'\bgrep\b'), "Use ripgrep (rg) instead of grep"),
    (re.compile(r'\bfind\b'), "Use ripgrep (rg) instead of find"),
]

def _validate_command(command: str) -> list[str]:
    """명령어 검증"""
    violations = []
    for pattern, message in _VALIDATION_RULES:
        if pattern.search(command):
            violations.append(f"• {message}")
    return violations

def main():
    # stdin에서 JSON 읽기
    try:
        data = json.load(sys.stdin)
    except json.JSONDecodeError:
        print("Error parsing JSON", file=sys.stderr)
        return 1

    # Bash 도구만 검증
    if data.get("tool_name") != "Bash":
        return 0

    # 명령어 검증
    command = data.get("tool_input", {}).get("command", "")
    violations = _validate_command(command)

    if violations:
        print("\n".join(violations), file=sys.stderr)
        return 2  # 차단

    return 0  # 통과

if __name__ == "__main__":
    sys.exit(main())
```

#### 베스트 프랙티스

1. **선언적 규칙 정의**: 정규식과 메시지를 튜플 리스트로 관리
2. **도구 이름 확인**: 불필요한 검증 방지
3. **다중 위반 수집**: 모든 문제를 한 번에 보고
4. **명확한 피드백**: "•" 기호로 가독성 향상

---

## 4. Agents 패턴 (공식 플러그인)

### code-review 플러그인 에이전트

#### 에이전트 구성 (4개)

1. **CLAUDE.md 준수 검사 에이전트** (2개)
   - 프로젝트 규칙 검증

2. **버그 탐지 에이전트** (1개)
   - 잠재적 버그 식별

3. **히스토리 분석 에이전트** (1개)
   - Git 히스토리 분석

#### 에이전트 호출 패턴

- 다중 에이전트 병렬 실행
- 각 에이전트는 특화된 역할
- 결과 종합 후 리포트 생성

---

## 5. Commands 패턴 (공식 플러그인)

### /code-review 커맨드

**위치**: `plugins/code-review/commands/`

#### 기능
- 자동화된 코드 리뷰 수행
- 다중 에이전트 오케스트레이션
- PR 분석 및 피드백 생성

#### 사용법
```bash
/code-review
```

#### 구현 패턴
- Markdown 형식 커맨드 정의
- 에이전트 호출 로직 포함
- 결과 포맷팅 및 출력

---

## 6. 설치 및 사용 (공식 방법)

### 설치

**macOS/Linux**:
```bash
curl -fsSL https://claude.ai/install.sh | bash
```

**Homebrew**:
```bash
brew install --cask claude-code
```

**Windows**:
```powershell
irm https://claude.ai/install.ps1 | iex
```

**NPM** (Node.js 18+):
```bash
npm install -g @anthropic-ai/claude-code
```

### 플러그인 설치

1. **마켓플레이스 방식**:
```bash
claude
/plugin  # 마켓플레이스에서 설치
```

2. **설정 파일 방식**:
`.claude/settings.json`에서 구성

---

## 7. 공식 문서 링크

### 확인된 문서

- **Overview**: https://docs.anthropic.com/en/docs/claude-code/overview
- **Data Usage**: https://docs.anthropic.com/en/docs/claude-code/data-usage
- **Plugin README**: https://github.com/anthropics/claude-code/tree/main/plugins/README.md

### 확인 필요 (404 또는 리다이렉트)

- ~~`https://docs.claude.com/claude-code`~~ → 404
- ~~`https://platform.claude.com/docs/en/agents-and-tools/agent-skills`~~ → 404

---

## 8. 주요 발견사항

### ✓ 확인된 패턴

1. **Hooks**: PreToolUse 패턴 확인 (bash_command_validator)
2. **Plugins**: 표준 디렉토리 구조 확인
3. **Agents**: 다중 전문화 에이전트 패턴
4. **Commands**: Markdown 기반 커맨드 정의

### ⚠ 추가 조사 필요

1. **Skills 파일 형식**: SKILL.md 구조 미확인
2. **hooks.json 스키마**: 훅 정의 형식 미확인
3. **plugin.json 스키마**: 상세 필드 정보 미확인
4. **지원 훅 이벤트**: PreToolUse 외 다른 이벤트 확인 필요

### 🔍 추천 조사 방향

1. GitHub 저장소 직접 클론하여 파일 구조 분석
2. 공식 플러그인 코드 상세 리뷰
3. MCP 서버 설정 (.mcp.json) 조사
4. 커뮤니티 플러그인 사례 수집

---

## 9. 다음 단계

### 즉시 적용 가능

- [x] Hooks 템플릿에 PreToolUse 패턴 반영
- [x] 플러그인 구조를 공식 표준과 일치시킴
- [ ] bash_command_validator 패턴으로 첫 번째 훅 개발

### 추가 조사 후 적용

- [ ] Skills 파일 형식 확정
- [ ] hooks.json 스키마 정의
- [ ] 전체 훅 이벤트 타입 정리
- [ ] plugin.json 필드 상세화

---

## 변경 이력

- **2025-11-28**: 초기 조사 및 문서 작성
