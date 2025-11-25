# Skill Activation Hook Architecture (v3.0.0)

## 개요

Skill Activation Hook v3.0.0은 사용자 프롬프트를 분석하여 관련 스킬을 자동으로 제안하는 다층 매칭 파이프라인입니다.

## 시스템 아키텍처

```
┌─────────────────────────────────────────────────────────────┐
│                     User Prompt Submit                       │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│              skill-activation-hook.sh (Main)                 │
│  - Repository root detection                                 │
│  - Input parsing (JSON/plain text)                          │
│  - Plugin/skill aggregation                                  │
└───────────────────────┬─────────────────────────────────────┘
                        │
        ┌───────────────┼───────────────┐
        ▼               ▼               ▼
   ┌─────────┐    ┌─────────┐    ┌─────────┐
   │ Tier 1  │    │ Tier 2  │    │ Tier 3  │
   │ Keyword │───>│ TF-IDF  │───>│Semantic │
   │ Match   │    │ Match   │    │ Match   │
   └─────────┘    └─────────┘    └─────────┘
        │               │               │
        └───────────────┼───────────────┘
                        ▼
              ┌──────────────────┐
              │ Score Aggregation│
              │ & Ranking        │
              └─────────┬────────┘
                        │
                        ▼
              ┌──────────────────┐
              │ Cache Manager    │
              │ (mtime tracking) │
              └─────────┬────────┘
                        │
                        ▼
              ┌──────────────────┐
              │ Output Formatter │
              │ (JSON/Text)      │
              └─────────┬────────┘
                        │
                        ▼
              ┌──────────────────┐
              │ Claude Code UI   │
              └──────────────────┘
```

## 핵심 컴포넌트

### 1. Main Hook Script (`skill-activation-hook.sh`)

**역할**: 훅 실행의 진입점

**주요 기능**:
- Repository root 자동 감지 (`.claude-plugin` 디렉토리 기준)
- 사용자 입력 파싱 (JSON 또는 plain text)
- 모든 플러그인의 `skill-rules.json` 수집
- 매칭 파이프라인 오케스트레이션
- 출력 포맷팅 및 로깅

**입력 형식**:
```json
{
  "prompt": "React 컴포넌트를 만들고 싶어요"
}
```

**출력 형식**:
```json
{
  "stopReason": "string",
  "systemMessage": "스킬 활성화 메시지",
  "message": "사용자에게 보여질 메시지"
}
```

### 2. Plugin Discovery (`lib/plugin-discovery.sh`)

**역할**: 설치된 플러그인 및 스킬 검색

**주요 기능**:
- `~/.claude/plugins/installed_plugins.json` 파싱
- 멀티 플러그인 마켓플레이스 지원
- SKILL.md 파일 자동 검색
- skill-rules.json 파일 검색

**검색 로직**:
```bash
# 1. installed_plugins.json에서 플러그인 목록 읽기
# 2. known_marketplaces.json에서 설치 경로 확인
# 3. 각 플러그인의 .claude-plugin/plugin.json 파싱
# 4. skills 디렉토리에서 SKILL.md 파일 검색
```

**출력 형식**:
```
plugin-name@marketplace|skill-name|/path/to/SKILL.md
```

### 3. Metadata Parser (`lib/metadata-parser.sh`)

**역할**: YAML frontmatter와 skill-rules.json 파싱

**파싱 대상**:
- **YAML frontmatter** (SKILL.md):
  ```yaml
  ---
  name: skill-name
  description: Skill description
  ---
  ```

- **skill-rules.json**:
  ```json
  {
    "skills": {
      "skill-name": {
        "priority": "high",
        "promptTriggers": {
          "keywords": ["react", "component"],
          "intentPatterns": ["create.*component", "build.*ui"]
        }
      }
    }
  }
  ```

**메타데이터 집계**:
```
plugin|skill|description|priority|keywords|patterns|file
```

### 4. Cache Manager (`lib/cache-manager.sh`)

**역할**: 스킬 메타데이터 캐싱 및 무효화 관리

**캐싱 전략**:
- **파일 기반 캐시**: `cache/skill-metadata.json`
- **변경 감지**: mtime 기반 파일 인덱스 (`cache/file-index.txt`)
- **기본 TTL**: 1시간 (3600초)

**무효화 조건**:
1. 캐시 파일이 TTL 초과
2. skill-rules.json 파일 변경 (mtime 비교)
3. SKILL.md 파일 변경
4. 플러그인 추가/제거

**성능 최적화**:
```bash
# Before (no cache): ~500ms for 24 skills
# After (cached):     ~50ms for 24 skills
# Improvement:        10x faster
```

### 5. Multi-Tier Matching Pipeline

#### Tier 1: Keyword Matching (AWK)

**특징**:
- 가장 빠른 매칭 (< 10ms)
- 대소문자 무시
- 부분 문자열 매칭

**알고리즘**:
```bash
# 1. prompt를 소문자로 변환
# 2. skill-rules.json의 keywords를 ','로 분할
# 3. 각 keyword가 prompt에 포함되는지 체크
# 4. 매칭된 스킬 반환
```

**예시**:
```bash
Prompt: "React 컴포넌트를 만들고 싶어요"
Keywords: ["react", "component", "프론트엔드"]
Result: MATCH (2/3 keywords found)
```

#### Tier 2: TF-IDF Matching (Node.js)

**특징**:
- 중간 정확도, 중간 속도 (50-100ms)
- 용어 빈도-역문서 빈도 기반
- 통계적 관련성 측정

**라이브러리**: `natural` (Node.js NLP)

**알고리즘**:
```javascript
// 1. 각 스킬의 description + keywords + skill name을 문서로 취급
// 2. TF-IDF 인덱스 구축
// 3. 사용자 프롬프트를 쿼리로 TF-IDF 점수 계산
// 4. 점수 순으로 정렬
```

**점수 의미**:
- `0.0`: 관련 없음
- `0.1-0.3`: 낮은 관련성
- `0.3-0.6`: 중간 관련성
- `0.6+`: 높은 관련성

#### Tier 3: Semantic Matching (Python)

**특징**:
- 최고 정확도, 느린 속도 (200-500ms)
- 문맥적 의미 이해
- Sentence embeddings 기반

**라이브러리**: `sentence-transformers` (all-MiniLM-L6-v2)

**알고리즘**:
```python
# 1. 사용자 프롬프트를 384차원 벡터로 임베딩
# 2. 각 스킬 설명을 384차원 벡터로 임베딩
# 3. 코사인 유사도 계산
# 4. 유사도 > 0.1인 스킬만 반환
```

**유사도 예시**:
```
Prompt: "버그를 수정하고 싶어요"
Skill: "error-tracking" (Sentry 패턴)
Cosine Similarity: 0.72 (높은 관련성)

Prompt: "버그를 수정하고 싶어요"
Skill: "frontend-dev-guidelines" (React 개발)
Cosine Similarity: 0.15 (낮은 관련성)
```

### 6. Synonym Dictionary (`config/synonyms.json`)

**역할**: 키워드 확장 및 동의어 매칭

**구조**:
```json
{
  "synonyms": {
    "debug": ["debugging", "디버그", "디버깅", "버그수정", "bug fix"],
    "review": ["리뷰", "검토", "코드리뷰", "code review"]
  },
  "categories": {
    "development": ["debug", "test", "refactor"],
    "frontend": ["frontend", "component", "style", "ui"]
  }
}
```

**사용 사례**:
- Tier 1에서 키워드 확장
- 한글-영어 상호 매칭
- 카테고리 기반 스킬 그룹핑

## 데이터 흐름

### 1. Cold Start (첫 실행)

```
User Prompt
    │
    ├─> Repository Root Detection
    │       └─> Find .claude-plugin directory
    │
    ├─> Plugin Discovery
    │       ├─> Parse installed_plugins.json
    │       ├─> Parse known_marketplaces.json
    │       └─> Find all SKILL.md files
    │
    ├─> Metadata Parsing
    │       ├─> Parse YAML frontmatter
    │       ├─> Parse skill-rules.json
    │       └─> Aggregate metadata
    │
    ├─> Cache Save
    │       ├─> Save skill-metadata.json
    │       └─> Save file-index.txt (mtime tracking)
    │
    ├─> Matching Pipeline
    │       ├─> Tier 1: Keyword Match (AWK)
    │       ├─> Tier 2: TF-IDF Match (Node.js) [optional]
    │       └─> Tier 3: Semantic Match (Python) [optional]
    │
    ├─> Score Aggregation
    │       └─> Combine scores from all tiers
    │
    └─> Output Formatting
            └─> JSON output to Claude Code
```

**소요 시간**: ~500ms

### 2. Warm Start (캐시 유효)

```
User Prompt
    │
    ├─> Cache Check
    │       ├─> Check TTL (< 1 hour?)
    │       └─> Check file changes (mtime)
    │
    ├─> Load from Cache
    │       └─> Read skill-metadata.json
    │
    ├─> Matching Pipeline
    │       └─> Tier 1: Keyword Match (AWK)
    │
    └─> Output Formatting
            └─> JSON output to Claude Code
```

**소요 시간**: ~50ms (10배 향상)

### 3. Cache Invalidation (파일 변경 감지)

```
User Prompt
    │
    ├─> Cache Check
    │       ├─> Check TTL (OK)
    │       └─> Check file changes (CHANGED!)
    │
    ├─> Rebuild Cache
    │       ├─> Re-parse metadata
    │       ├─> Update skill-metadata.json
    │       └─> Update file-index.txt
    │
    ├─> Matching Pipeline
    │
    └─> Output Formatting
```

**소요 시간**: ~200ms (재구축 포함)

## 우선순위 시스템

### Priority Levels

| Priority | 점수 | 사용 시기 | 예시 |
|----------|------|-----------|------|
| `critical` | 4 | 필수 스킬, 항상 제안 | `error-tracking` (에러 발생 시) |
| `high` | 3 | 자주 사용되는 스킬 | `frontend-dev-guidelines`, `backend-dev-guidelines` |
| `medium` | 2 | 일반 스킬 (기본값) | `intelligent-task-router`, `skill-developer` |
| `low` | 1 | 특수 목적 스킬 | `cli-updater`, `agent-workflow-orchestrator` |

### Enforcement Types

| Type | 동작 | 현재 사용 |
|------|------|----------|
| `suggest` | 스킬 제안 (기본) | ✅ 모든 스킬 |
| `block` | 스킬 차단 (예약) | ❌ 미사용 |
| `warn` | 경고 표시 (예약) | ❌ 미사용 |

## 출력 형식

### User Message (Claude Code UI)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  스킬 활성화
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📦 7개 플러그인 · 🔧 24개 스킬 (전체: 24)

🎯 제안 스킬:
  • workflow-automation:intelligent-task-router
  • dev-guidelines:frontend-dev-guidelines
  • quality-review:iterative-quality-enhancer
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Debug Logging

로그 파일: `/tmp/claude-skill-activation.log`

```
[2025-11-24 10:30:15] Multi-plugin skill-activation-hook executed
[DEBUG] Repository root: /Users/user/.claude/plugins/inchan-cc-skills
[DEBUG] User prompt: React 컴포넌트를 만들고 싶어요
[DEBUG] Found: /Users/user/.claude/plugins/inchan-cc-skills/plugins/dev-guidelines/skills/skill-rules.json
[DEBUG] Total skill-rules.json files: 7
[DEBUG] Total skills aggregated: 24
[DEBUG] Keyword matched skills: 3
[INFO] Suggesting skill: frontend-dev-guidelines (priority: high)
```

### Hook Input/Output (디버깅)

**입력**: `/tmp/claude-hook-input.json`
```json
{
  "prompt": "React 컴포넌트를 만들고 싶어요"
}
```

**출력**: `/tmp/claude-hook-output.json`
```json
{
  "stopReason": "string",
  "systemMessage": "...",
  "message": "..."
}
```

## 성능 특성

### 매칭 알고리즘 비교

| Tier | 알고리즘 | 속도 | 정확도 | 적용 시점 |
|------|----------|------|--------|-----------|
| 1 | Keyword (AWK) | 🚀 매우 빠름 (< 10ms) | ⭐⭐ 낮음 | 항상 |
| 2 | TF-IDF (Node.js) | ⚡ 빠름 (50-100ms) | ⭐⭐⭐ 중간 | Tier 1 실패 시 |
| 3 | Semantic (Python) | 🐢 느림 (200-500ms) | ⭐⭐⭐⭐⭐ 높음 | Tier 2 실패 시 |

### 캐싱 효과

| 시나리오 | Cold Start | Warm Start | 개선율 |
|---------|------------|------------|--------|
| 플러그인 7개, 스킬 24개 | ~500ms | ~50ms | 10배 |
| 플러그인 15개, 스킬 50개 | ~1200ms | ~80ms | 15배 |
| 플러그인 30개, 스킬 100개 | ~3000ms | ~150ms | 20배 |

### 메모리 사용량

| 컴포넌트 | 메모리 사용 |
|---------|------------|
| Bash 스크립트 | < 1MB |
| Node.js (TF-IDF) | ~30MB |
| Python (Semantic) | ~200MB (모델 로드 시) |
| Cache 파일 | < 100KB (스킬 100개 기준) |

## 확장성

### 플러그인 확장

새 플러그인 추가 시 자동으로 인식:
```bash
# 1. 플러그인 설치
/plugin install new-plugin@marketplace

# 2. 다음 실행 시 자동 검색
# - plugin-discovery.sh가 installed_plugins.json 파싱
# - 새 플러그인의 SKILL.md 및 skill-rules.json 자동 발견
```

### 매칭 알고리즘 확장

새 매처 추가:
```bash
# 1. matchers/ 디렉토리에 새 매처 추가
matchers/custom-matcher.py

# 2. skill-activation-hook.sh에 Tier 4 추가
# 3. 캐시 무효화 (파일 변경 감지)
```

### 동의어 사전 확장

```json
{
  "synonyms": {
    "custom-term": ["term1", "term2", "용어1", "용어2"]
  }
}
```

## 보안 고려사항

### 입력 검증

- JSON 파싱 실패 시 plain text 폴백
- 악의적 입력 방지 (특수문자 이스케이프)

### 파일 권한

- 스크립트 실행 권한: `755` (rwxr-xr-x)
- 캐시 파일 권한: `644` (rw-r--r--)

### 로그 파일

- `/tmp` 디렉토리 사용 (시스템 재시작 시 자동 삭제)
- 민감한 정보 로깅 금지

## 제한사항

### 현재 제한

1. **언어 지원**: 한국어, 영어만 최적화
2. **매칭 정확도**: 짧은 프롬프트(< 5단어)는 정확도 낮음
3. **동시성**: 훅은 순차 실행 (병렬 실행 불가)
4. **캐시 동기화**: 다중 사용자 환경에서 캐시 충돌 가능

### 향후 개선 방향

- [ ] 다국어 지원 (일본어, 중국어)
- [ ] 사용자 피드백 학습
- [ ] 실시간 성능 모니터링
- [ ] 분산 캐시 지원

## 참고 자료

- [Claude Code Hooks Documentation](https://claude.com/docs/hooks)
- [sentence-transformers Documentation](https://www.sbert.net/)
- [natural (Node.js NLP)](https://github.com/NaturalNode/natural)
