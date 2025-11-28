# 플러그인 표준 구조 레퍼런스

> 공식 저장소 기반 플러그인 구조

**출처**: https://github.com/anthropics/claude-code/tree/main/plugins/README.md

---

## 공식 표준 구조

```
plugin-name/
├── .claude-plugin/
│   └── plugin.json          # 플러그인 메타데이터 (필수)
├── commands/                # 슬래시 커맨드 (선택)
│   └── {command-name}.md
├── agents/                  # 전문화된 에이전트 (선택)
│   └── {agent-name}.md
├── skills/                  # 스킬 (선택)
│   └── {skill-name}/
│       └── SKILL.md
├── hooks/                   # 이벤트 훅 (선택)
│   ├── hooks.json
│   └── *.py|*.sh
├── .mcp.json               # MCP 서버 설정 (선택)
└── README.md               # 문서 (필수)
```

---

## 필수 요소

### 1. .claude-plugin/plugin.json

플러그인 메타데이터 파일

**예상 필드** (공식 스키마 미확인):
```json
{
  "name": "plugin-name",
  "version": "1.0.0",
  "description": "플러그인 설명",
  "author": "Author Name",
  "license": "MIT",
  "main": "index.js",
  "keywords": ["claude-code", "plugin"],
  "engines": {
    "claude-code": ">=1.0.0"
  }
}
```

### 2. README.md

플러그인 문서

**필수 섹션**:
- 플러그인 설명
- 설치 방법
- 사용 방법
- 커맨드/에이전트 목록
- 예제

---

## 선택 요소

### commands/

슬래시 커맨드 정의

**파일**: `{command-name}.md`

**내용**:
```markdown
# /command-name

## Description
커맨드 설명

## Usage
/command-name [args]

## Implementation
수행할 작업
```

### agents/

전문화된 에이전트

**파일**: `{agent-name}.md`

**내용**:
```markdown
# Agent Name

## Role
에이전트 역할

## Instructions
수행할 작업 단계
```

### skills/

스킬 정의 (형식 미확인)

**구조**:
```
skills/{skill-name}/
└── SKILL.md
```

### hooks/

이벤트 훅

**필수**: `hooks.json` (훅 정의)
**파일**: `*.py` 또는 `*.sh` (훅 스크립트)

---

## 공식 플러그인 예제

### code-review

**구조**:
```
code-review/
├── .claude-plugin/
├── commands/
│   └── code-review.md
├── agents/
│   ├── claude-md-checker-1.md
│   ├── claude-md-checker-2.md
│   ├── bug-detector.md
│   └── history-analyzer.md
└── README.md
```

**특징**:
- 다중 에이전트 오케스트레이션
- `/code-review` 커맨드
- 4개의 전문 에이전트

### feature-dev

**특징**:
- 7단계 구조화 워크플로우
- 기능 개발 전용

### plugin-dev

**특징**:
- 8단계 안내 워크플로우
- 플러그인 생성/검증/리뷰 지원
- 7개 전문 스킬

---

## 플러그인 개발 워크플로우

### 1. 생성

```bash
# plugin-dev 플러그인 사용 (권장)
/plugin-dev:create-plugin

# 또는 수동 생성
mkdir -p my-plugin/.claude-plugin
mkdir -p my-plugin/{commands,agents,skills,hooks}
```

### 2. 메타데이터 작성

``.claude-plugin/plugin.json` 작성

### 3. 컴포넌트 개발

- Commands: `commands/*.md`
- Agents: `agents/*.md`
- Skills: `skills/*/SKILL.md`
- Hooks: `hooks/hooks.json` + `hooks/*.py|*.sh`

### 4. 문서화

`README.md` 작성:
- 개요
- 설치
- 사용법
- 예제

### 5. 테스트

```bash
# 로컬 테스트
cd my-plugin
claude  # 플러그인 로드 확인
```

### 6. 배포

- GitHub 저장소 생성
- 마켓플레이스 등록 (향후)

---

## 베스트 프랙티스

### ✓ Do

1. **표준 구조 준수**: 공식 구조 사용
2. **포괄적 README**: 모든 기능 문서화
3. **명확한 명명**: 직관적인 파일/디렉토리명
4. **예제 제공**: 사용 예제 포함

### ✗ Don't

1. **비표준 구조**: 임의의 디렉토리 추가
2. **문서 부족**: README 없이 배포
3. **모호한 이름**: `helper.md`, `utils.md` 등
4. **예제 누락**: 사용법만 나열

---

## 설치 방법

### 마켓플레이스 (향후)

```bash
claude
/plugin
# UI에서 플러그인 검색 및 설치
```

### 설정 파일

`.claude/settings.json`:
```json
{
  "plugins": [
    "code-review",
    "feature-dev"
  ]
}
```

---

## 관련 문서

- [Agents Reference](../agents/)
- [Commands Reference](../commands/)
- [Hooks Reference](../hooks/)
- [공식 플러그인 README](https://github.com/anthropics/claude-code/tree/main/plugins/README.md)

---

## 변경 이력

- **2025-11-28**: 공식 구조 기반 레퍼런스 작성
