# Claude Code Hooks Plugin

**v3.0.0 - Multi-Tier Intelligent Skill Matching System**

이 플러그인은 Claude Code의 스킬 자동 활성화를 위한 3단계 매칭 시스템을 구현합니다.

## 아키텍처 개요

```
User Prompt
    │
    ▼
┌─────────────────────────────────────────┐
│  Multi-Tier Matching Pipeline           │
├─────────────────────────────────────────┤
│                                         │
│  Tier 1: Keyword Matching (Bash)       │
│  - Synonym expansion                   │
│  - Target: <50ms                       │
│  - Output: All keyword matches         │
│                                         │
│         ▼ (if confidence < 0.6)         │
│                                         │
│  Tier 2: TF-IDF Matching (Node.js)     │
│  - Top 20 candidates from Tier 1       │
│  - Target: <150ms                      │
│  - Output: Semantic relevance scores   │
│                                         │
│         ▼ (if matches >= 3)             │
│                                         │
│  Tier 3: Semantic Matching (Python)    │
│  - Top 10 candidates from Tier 2       │
│  - Neural embedding similarity         │
│  - Target: <400ms                      │
│  - Output: Deep semantic scores        │
│                                         │
└─────────────────────────────────────────┘
    │
    ▼
Ranked Skills (Overall timeout: 500ms)
```

## 주요 기능

### 1. Progressive Execution (점진적 실행)

- **High Confidence Early Exit**: Tier 1에서 5개 이상의 high-confidence (>0.6) 매칭이 있으면 Tier 2/3를 스킵
- **Graceful Degradation**: 상위 Tier가 실패해도 하위 Tier 결과를 사용
- **Timeout Protection**: 전체 500ms 타임아웃으로 응답 시간 보장

### 2. Multi-Language Support

- **한글-영어 동의어 확장**: `config/synonyms.json`을 통한 31개 동의어 그룹
- **Keyword Matching**: 한글 프롬프트 → 영어 키워드 매칭 지원
- **Semantic Matching**: 언어 독립적 임베딩 기반 매칭

### 3. Intelligent Caching

- **File Change Detection**: mtime 기반 변경 감지
- **1시간 캐시 유효기간**: 불필요한 재계산 방지
- **자동 캐시 재생성**: 파일 변경 시 자동 업데이트

## 디렉토리 구조

```
plugins/hooks/
├── skill-activation-hook.sh       # 메인 훅 스크립트 (v3.0.0)
├── stop-hook-lint-and-translate.sh
├── hooks.json                      # 훅 설정
├── lib/                           # 공유 라이브러리
│   ├── plugin-discovery.sh        # 플러그인 검색
│   ├── metadata-parser.sh         # YAML/JSON 파싱
│   └── cache-manager.sh           # 캐시 관리
├── matchers/                      # 매칭 엔진
│   ├── tfidf-matcher.js          # Tier 2: TF-IDF (Node.js)
│   ├── semantic-matcher.py       # Tier 3: Semantic (Python)
│   └── package.json               # Node.js 의존성
├── config/                        # 설정 파일
│   └── synonyms.json             # 동의어 사전
├── cache/                         # 캐시 디렉토리
│   ├── skill-metadata.json       # 스킬 메타데이터 캐시
│   └── file-index.txt            # 파일 변경 추적
└── tests/                         # 테스트 스크립트
    └── test-multi-tier-matching.sh
```

## 설치 및 의존성

### 필수 의존성

```bash
# Bash 5.0+ (macOS 기본 제공)
bash --version

# jq (JSON 파싱)
brew install jq

# Node.js 18+ (Tier 2 TF-IDF 매칭)
brew install node
cd matchers && npm install
```

### 선택적 의존성

```bash
# Python 3.8+ (Tier 3 Semantic 매칭)
brew install python3

# sentence-transformers (임베딩 모델)
pip3 install sentence-transformers torch
```

**Note**: Tier 2/3는 선택사항입니다. 해당 도구가 없으면 자동으로 Tier 1만 실행됩니다.

## 사용법

### 자동 활성화

hooks.json에 등록되어 있어 모든 사용자 프롬프트에서 자동 실행됩니다:

```json
{
  "hooks": {
    "UserPromptSubmit": [{
      "matcher": "",
      "hooks": [{
        "type": "command",
        "command": "${CLAUDE_PLUGIN_ROOT}/skill-activation-hook.sh"
      }]
    }]
  }
}
```

### 수동 테스트

```bash
# JSON 입력으로 테스트
echo '{"prompt": "프론트엔드 버그를 수정하고 싶어요"}' | ./skill-activation-hook.sh

# 일반 텍스트 입력으로 테스트
echo "I need to fix a React component bug" | ./skill-activation-hook.sh
```

### 성능 모니터링

```bash
# 실시간 로그 보기
tail -f /tmp/claude-skill-activation.log

# 성능 메트릭만 필터
grep '\[PERF\]' /tmp/claude-skill-activation.log

# 최근 5개 실행 성능
grep 'Overall pipeline completed' /tmp/claude-skill-activation.log | tail -5
```

## 성능 목표 및 최적화

### Tier별 성능 목표

| Tier | 기술 | 목표 시간 | 평균 시간 | 후보 수 |
|------|------|----------|----------|---------|
| Tier 1 | Bash + AWK | <50ms | ~25ms | 전체 |
| Tier 2 | Node.js + TF-IDF | <150ms | ~80ms | 상위 20개 |
| Tier 3 | Python + Embeddings | <400ms | ~250ms | 상위 10개 |
| **전체** | **Progressive Pipeline** | **<500ms** | **~300ms** | **전체** |

### 최적화 전략

1. **Tier 1 최적화**
   - AWK를 사용한 순수 Bash 구현
   - 동의어 확장은 선택적으로만 수행
   - 정규식 대신 단순 substring 매칭

2. **Tier 2 최적화**
   - 상위 20개 후보만 TF-IDF 계산
   - 경량 natural 라이브러리 사용
   - 결과 캐싱

3. **Tier 3 최적화**
   - 상위 10개 후보만 임베딩 계산
   - all-MiniLM-L6-v2 경량 모델 사용
   - 모델 lazy loading

4. **전체 파이프라인 최적화**
   - Early exit: High-confidence 매칭 시 즉시 종료
   - Timeout protection: 500ms 초과 시 현재까지 결과 반환
   - Fallback strategy: 상위 Tier 실패 시 하위 Tier 결과 사용

## 설정 파일

### config/synonyms.json

동의어 사전을 통해 한글-영어 키워드 매칭 지원:

```json
{
  "synonyms": {
    "debug": ["debugging", "디버그", "디버깅", "버그수정", "bug fix"],
    "frontend": ["프론트엔드", "프론트", "ui", "ux", "화면"],
    "backend": ["백엔드", "백", "서버", "api"]
  },
  "categories": {
    "development": ["debug", "test", "refactor", "implement"],
    "frontend": ["frontend", "component", "style", "ui"]
  }
}
```

### 동의어 추가

새로운 동의어를 추가하려면:

```bash
# synonyms.json 편집
vim config/synonyms.json

# 캐시 초기화
rm -rf cache/*

# 테스트
echo '{"prompt": "새로운 키워드 테스트"}' | ./skill-activation-hook.sh
```

## 테스트

### 전체 테스트 실행

```bash
cd tests
./test-multi-tier-matching.sh
```

### 테스트 커버리지

테스트 스크립트는 다음 7가지 항목을 검증합니다:

1. **Tier 1 Keyword Matching**: 키워드 기반 매칭
2. **Tier 2 TF-IDF Matching**: TF-IDF 스코어링
3. **Tier 3 Semantic Matching**: 임베딩 기반 매칭
4. **Progressive Execution**: 점진적 실행 로직
5. **Synonym Expansion**: 동의어 확장
6. **End-to-End Integration**: 전체 통합 테스트
7. **Performance Validation**: 성능 검증

### 개별 Tier 테스트

```bash
# Tier 2 (TF-IDF) 단독 테스트
node matchers/tfidf-matcher.js --test

# Tier 3 (Semantic) 단독 테스트
python3 matchers/semantic-matcher.py --test
```

## Troubleshooting

### Hook Not Executing

1. **Check plugin installation**:
   ```bash
   /plugin list
   # Should show "cc-skills-hooks"
   ```

2. **Verify script permissions**:
   ```bash
   ls -l ~/.claude/plugins/inchan-cc-skills/hooks/skill-activation-hook.sh
   # Should show -rwxr-xr-x (executable)
   ```

3. **Check logs**:
   ```bash
   tail -f /tmp/claude-skill-activation.log
   ```

### Skills Not Suggested

1. **Verify skill-rules.json exists**:
   ```bash
   find ~/.claude/plugins/inchan-cc-skills/plugins -name skill-rules.json
   ```

2. **Check keyword matches**:
   - Open relevant `skill-rules.json`
   - Verify keywords and intentPatterns

3. **Check priority**:
   - Only `suggest` enforcement shows suggestions
   - `block` and `warn` are reserved for future use

## Version History

### v2.0.0 (2025-11-21)
- ✅ Separated hooks into standalone plugin
- ✅ Multi-plugin architecture support
- ✅ Updated `${CLAUDE_PLUGIN_ROOT}` path references

### v1.4.0 (2025-11-20)
- Initial hooks implementation

## License

MIT License

## Author

**inchan** - [GitHub](https://github.com/inchan)
