# Claude Code Skills 공식 표준 준수 보고서

**생성일**: 2025-11-17
**검사 대상**: 28개 스킬 (skills/ 디렉토리)

---

## 1. 핵심 문제점 (CRITICAL)

### 1.1 디렉토리 구조 비준수 ❌

**공식 표준**:
- 개인 스킬: `~/.claude/skills/skill-name/`
- 프로젝트 스킬: `.claude/skills/skill-name/`

**현재 상태**:
- 모든 스킬이 `skills/` 디렉토리에 위치
- `.claude/skills/`를 사용하지 않음

**영향**: Claude Code가 스킬을 자동으로 발견하지 못할 수 있음

**권장 조치**:
```bash
mkdir -p .claude/skills
mv skills/* .claude/skills/
# 또는 심볼릭 링크
ln -s ../skills .claude/skills
```

---

### 1.2 파일명 비준수

**문제 스킬**: `skills/codex/skill.md`

- **현재**: `skill.md` (소문자)
- **표준**: `SKILL.md` (대문자)

**권장 조치**:
```bash
mv skills/codex/skill.md skills/codex/SKILL.md
```

---

## 2. Frontmatter 준수 현황

### 2.1 검사 기준

| 항목 | 표준 요구사항 |
|------|---------------|
| YAML 구조 | 파일 첫 줄에 `---`, 닫는 `---` 필수 |
| name 필드 | 소문자, 숫자, 하이픈만 (최대 64자) |
| description 필드 | 구체적이고 실행 가능한 설명 (최대 1024자) |
| 추가 필드 | `allowed-tools`는 허용, 기타 필드는 비표준 |

### 2.2 준수 결과

| 항목 | 준수 | 부분 준수 | 비준수 |
|------|------|-----------|--------|
| 유효한 YAML 구조 | 28/28 | - | 0 |
| name 필드 존재 | 28/28 | - | 0 |
| description 필드 존재 | 28/28 | - | 0 |
| name 형식 올바름 | 28/28 | - | 0 |
| description 1024자 이내 | 27/28 | - | 1 |
| 비표준 필드 없음 | 26/28 | 2 | 0 |

---

## 3. 개별 스킬 검사 결과

### 3.1 완전 준수 스킬 ✅ (23개)

다음 스킬들은 모든 공식 표준을 충족합니다:

- agent-workflow-manager (version 필드 있으나 무해)
- backend-dev-guidelines
- cli-updater
- codex-claude-loop
- command-creator
- dual-ai-loop
- dynamic-task-orchestrator
- error-tracking
- frontend-dev-guidelines
- hooks-creator
- intelligent-task-router
- iterative-quality-enhancer
- parallel-task-executor
- prompt-enhancer
- qwen-claude-loop
- route-tester
- sequential-task-processor
- skill-developer
- subagent-creator
- cli-adapters/aider
- cli-adapters/codex
- cli-adapters/copilot
- cli-adapters/qwen
- cli-adapters/rovo-dev

### 3.2 부분 준수 스킬 ⚠️ (3개)

#### 1. **skill-creator**
```yaml
---
name: skill-creator
description: Guide for creating effective skills...
license: Complete terms in LICENSE.txt  # ← 비표준 필드
---
```

**문제**: `license` 필드는 표준 frontmatter 필드가 아님
**권장**: 문서 본문으로 이동

#### 2. **web-to-markdown**
```yaml
---
name: web-to-markdown
description: 웹페이지 URL을 입력받아... (2000+ 자)
---
```

**문제**: description이 1024자 초과 (약 2000자)
**권장**: 핵심 기능만 요약하여 1024자 이내로 축소

#### 3. **meta-prompt-generator**
```yaml
---
name: meta-prompt-generator
description: 간단한 설명을 받아...
---

## Metadata  # ← 중복 메타데이터 (혼란 야기)

name: 메타 프롬프트 생성기
description: ...
version: 1.0.0
```

**문제**: 본문에 중복된 메타데이터 섹션 존재 (혼란)
**권장**: 본문의 Metadata 섹션 제거 또는 명확히 구분

### 3.3 비준수 스킬 ❌ (1개)

#### **codex**
- **파일명**: `skill.md` (소문자)
- **위치**: `skills/codex/skill.md`
- **표준**: `SKILL.md` 사용 필요

---

## 4. 모범 사례 분석

### 4.1 우수 사례 ⭐

**cli-adapters/codex/SKILL.md** - 모범 frontmatter:
```yaml
---
name: codex-cli-adapter
description: OpenAI Codex CLI adapter for dual-ai-loop...
---
```
- 명확하고 간결한 이름
- 구체적인 사용 시기 명시
- 1024자 이내 description

**intelligent-task-router/SKILL.md**:
```yaml
---
name: intelligent-task-router
description: 작업 분류 및 최적 실행 경로 결정...
---
```
- 기능이 명확히 드러나는 이름
- 언제 사용해야 하는지 설명

### 4.2 개선 필요 사례 ⚠️

**web-to-markdown/SKILL.md**:
```yaml
---
name: web-to-markdown
description: 웹페이지 URL을 입력받아 마크다운 형태로 변환합니다...
  (이후 구체적인 단계, 예제, 주의사항 등 2000자 이상)
---
```

**문제점**:
1. Description이 과도하게 길음
2. 세부 단계를 frontmatter가 아닌 문서 본문에 포함해야 함

**수정안**:
```yaml
---
name: web-to-markdown
description: 웹페이지 URL을 마크다운으로 변환합니다. URL에서 콘텐츠 추출이 필요할 때 사용하세요.
---

# Web to Markdown

## 상세 단계
1. URL 유효성 검사
2. WebFetch로 콘텐츠 가져오기
...
```

---

## 5. 권장 조치 우선순위

### 긴급 (즉시 수정 필요)

1. **디렉토리 구조 변경**
   ```bash
   # 옵션 1: 직접 이동
   mkdir -p .claude/skills
   cp -r skills/* .claude/skills/

   # 옵션 2: 심볼릭 링크
   ln -s ../skills .claude/skills
   ```

2. **파일명 수정**
   ```bash
   mv skills/codex/skill.md skills/codex/SKILL.md
   ```

### 높은 우선순위

3. **web-to-markdown description 축소** (2000자 → 200자 이내)

4. **skill-creator license 필드 제거**

### 중간 우선순위

5. **meta-prompt-generator 중복 메타데이터 정리**

6. **agent-workflow-manager version 필드 제거** (선택적)

---

## 6. 공식 표준 체크리스트

### 필수 요구사항

- [x] SKILL.md 파일 존재 (27/28 - codex만 소문자)
- [x] 유효한 YAML frontmatter (28/28)
- [x] name 필드 존재 (28/28)
- [x] description 필드 존재 (28/28)
- [x] name 형식 준수 (소문자, 하이픈) (28/28)
- [ ] description 1024자 이내 (27/28)
- [ ] .claude/skills/ 디렉토리 사용 (0/28) ❌

### 권장 사항

- [ ] allowed-tools 명시 (0/28) - 해당되는 스킬에만
- [x] 구체적이고 실행 가능한 description (26/28)
- [ ] 영문 description (다국어 지원 시) (부분적)
- [x] 과도한 범위 피하기 - 단일 기능 집중 (28/28)

---

## 7. 언어 사용 패턴

### 현재 상황

| 언어 | 스킬 수 |
|------|---------|
| 영문 description | 14개 |
| 한국어 description | 14개 |

**공식 문서 권장**: Description은 영문으로 작성 (Claude가 이해하기 쉬움)

**권장**: 최소한 description은 영문으로, 문서 본문은 한국어/영문 모두 가능

---

## 8. 최종 평가

### 준수율

| 영역 | 점수 |
|------|------|
| Frontmatter 구조 | 96% (27/28) |
| 필수 필드 | 100% (28/28) |
| 이름 형식 | 100% (28/28) |
| Description 길이 | 96% (27/28) |
| **디렉토리 구조** | **0% (0/28)** ❌ |

### 전체 준수율: **78%**

**주요 문제**: 디렉토리 구조가 공식 표준과 일치하지 않음

---

## 9. 즉각 실행 가능한 수정 스크립트

```bash
#!/bin/bash
# Claude Code Skills 표준 준수 수정 스크립트

set -e

SKILLS_DIR="/home/user/cc-skills/skills"
CLAUDE_DIR="/home/user/cc-skills/.claude/skills"

# 1. .claude/skills 디렉토리 생성
echo "1. .claude/skills 디렉토리 생성..."
mkdir -p "$CLAUDE_DIR"

# 2. codex/skill.md → SKILL.md 이름 변경
echo "2. codex/skill.md 파일명 수정..."
if [ -f "$SKILLS_DIR/codex/skill.md" ]; then
  mv "$SKILLS_DIR/codex/skill.md" "$SKILLS_DIR/codex/SKILL.md"
fi

# 3. 심볼릭 링크 생성 (선택적)
echo "3. 심볼릭 링크 생성..."
for skill_dir in "$SKILLS_DIR"/*/; do
  skill_name=$(basename "$skill_dir")
  if [ ! -L "$CLAUDE_DIR/$skill_name" ]; then
    ln -s "../../skills/$skill_name" "$CLAUDE_DIR/$skill_name"
  fi
done

echo "완료!"
```

---

## 10. 결론

현재 스킬들은 **frontmatter 구조와 필드 요구사항**을 대체로 잘 준수하고 있습니다. 그러나 가장 중요한 **디렉토리 구조**가 공식 표준과 일치하지 않아 Claude Code가 스킬을 자동으로 발견하지 못할 수 있습니다.

**최우선 조치**: `.claude/skills/` 디렉토리 구조 적용

**차선 조치**: 개별 스킬의 description 길이 및 비표준 필드 정리

모든 조치를 완료하면 공식 표준 준수율이 78%에서 **95% 이상**으로 향상될 것입니다.
