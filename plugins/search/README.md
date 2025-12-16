# Search Plugin

> 웹 검색 통합 플러그인 - 공식 문서, 종합 검색, 모범 사례를 하나의 커맨드로

[![Version](https://img.shields.io/badge/version-0.1.1-blue.svg)](./.claude-plugin/plugin.json)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](../../LICENSE)

---

## 개요

Search Plugin은 3가지 검색 전략(공식 문서/종합/모범 사례)을 단일 인터페이스로 제공하는 Claude Code 플러그인입니다.

### 주요 특징

- **🔍 단일 커맨드**: `/search` 하나로 모든 검색 타입 접근
- **📊 Tier 기반 필터링**: 출처 신뢰도에 따라 4단계 분류
- **🎯 전략 선택**: 상황에 맞는 검색 전략 자동 적용
- **♻️ DRY 준수**: 중복 코드 0%, 유지보수 포인트 1곳

---

## 설치

### Claude Code에서 설치

```bash
# 플러그인 디렉토리로 이동
cd ~/.claude/plugins

# 저장소 클론
git clone https://github.com/inchan/claude-plugins.git

# 또는 특정 플러그인만 링크
ln -s /path/to/claude-plugin/plugins/search ~/.claude/plugins/search
```

### 수동 설치

1. 이 디렉토리 전체를 `~/.claude/plugins/search`로 복사
2. Claude Code 재시작
3. `/search` 커맨드 사용 가능

---

## 사용법

### 기본 사용

```bash
# Type 선택 질문 (interactive)
/search "React hooks"

# Type 직접 지정
/search --type=official "React Server Components"
/search --type=comprehensive "Next.js performance"
/search --type=best-practice "Express.js auth middleware"
```

### 검색 타입 비교

| 타입 | 검색 범위 | 신뢰도 | 최대 결과 | 언제 사용? |
|------|----------|--------|----------|-----------|
| **official** | Tier 1-2 (공식) | 90점 이상 | 10개 | 공식 API 확인, 빠른 검증 |
| **comprehensive** | Tier 1-4 (전체) | 60점 이상 | 20개 | 문제 해결, 비교 분석 |
| **best-practice** | 코드 샘플 중심 | 품질 30점+ | 10개 | 실전 예제, 튜토리얼 |

### 출력 형식

검색 시 3가지 출력 형식 중 선택 가능:

1. **요약 + 링크 목록** - 핵심 내용 2-3문장 + 주요 출처 3-5개
2. **상세 분석** - Tier별 분석 + 신뢰도 평가
3. **대화형 탐색** - 초기 결과 + 추가 drill-down 옵션

---

## 검색 Tier 시스템

| Tier | 출처 유형 | 신뢰도 | 예시 |
|------|----------|--------|------|
| **1** | 공식 문서 | 90-100점 | react.dev, docs.python.org |
| **2** | 공식 저장소/블로그 | 70-89점 | github.com/facebook/react |
| **3** | 신뢰 커뮤니티 | 50-69점 | Stack Overflow, Reddit |
| **4** | 일반 커뮤니티 | 30-49점 | Medium, Dev.to |

---

## 플러그인 구조

```
plugins/search/
├── README.md                          # 이 파일
└── .claude-plugin/
    └── plugin.json                    # 플러그인 메타데이터

참조하는 파일들:
├── commands/search.md                 # 통합 커맨드
├── agents/search/
│   ├── search-agent.md                # 통합 에이전트
│   └── resources/                     # 전략 문서
│       ├── official-docs-strategy.md
│       ├── comprehensive-strategy.md
│       └── best-practice-strategy.md
└── skills/search-core/
    ├── SKILL.md                       # 공통 검색 로직
    └── resources/
        ├── output-formats.md
        └── source-filters.md
```

---

## 예시

### 예시 1: 공식 문서 빠른 검색

```bash
$ /search --type=official "React useEffect cleanup"

## 답변

useEffect cleanup 함수는 컴포넌트 언마운트 시 또는 다음 effect 실행 전에
호출되며, 구독 해제, 타이머 정리 등에 사용됩니다.

## 주요 출처

- **[공식 문서]** useEffect - React - tier 1, 신뢰도: 95/100
  React 공식 문서, cleanup 함수 상세 설명

- **[공식 예제]** Cleanup Functions Example - tier 1, 신뢰도: 93/100
  GitHub 공식 예제, 즉시 실행 가능한 코드

Sources:
- [useEffect](https://react.dev/reference/react/useEffect)
- [Cleanup Example](https://github.com/facebook/react/tree/main/examples)
```

### 예시 2: 종합 검색 (비교 분석)

```bash
$ /search --type=comprehensive "TypeScript generics best practices"

## Tier 1: 공식 문서

### TypeScript Handbook - Generics - 신뢰도: 95/100
TypeScript 공식 문서의 Generics 가이드...

**주요 내용**:
- 타입 매개변수 기본값 사용
- 제약 조건(constraints) 활용
- ...

## Tier 3: 커뮤니티

### Stack Overflow: Generic Best Practices - 신뢰도: 68/100
커뮤니티에서 검증된 패턴...

**주의**: 커뮤니티 콘텐츠이므로 공식 문서와 교차 검증 필요

Sources:
- [...]
```

### 예시 3: 모범 사례 (코드 중심)

```bash
$ /search --type=best-practice "Node.js error handling middleware"

## 추천 샘플 코드

- [Express.js Official Examples](https://github.com/expressjs/express/tree/master/examples/error-pages) - 공식 예제

## 핵심 패턴

1. 중앙집중식 에러 핸들러 - 4개 매개변수 (err, req, res, next)
2. 비동기 에러 처리 - express-async-errors 또는 try-catch

## 빠른 예제

```javascript
// 중앙집중식 에러 핸들러
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).send('Something broke!');
});
```

Sources:
- [...]
```
```

---

## 아키텍처

```
User
  ↓
/search command
  ↓
search-agent (통합 에이전트)
  ↓
  ├─ type=official → resources/official-docs-strategy.md
  ├─ type=comprehensive → resources/comprehensive-strategy.md
  └─ type=best-practice → resources/best-practice-strategy.md
  ↓
search-core skill
  ↓
검색 방법 선택 (우선순위)
  ├─ 1순위: Gemini via MCP → google_search, web_fetch
  ├─ 2순위: Gemini via Bash → google_search, web_fetch
  └─ 3순위: 자체 WebSearch/WebFetch (Fallback)
  ↓
  ├─ Tier 분류 (신뢰도 평가)
  ├─ 중복 제거 (URL 정규화)
  └─ 결과 정렬
```

### 검색 방법 (우선순위)

| 순위 | 방법 | 도구 |
|------|------|------|
| **1순위** | Gemini via MCP | `google_search`, `web_fetch` |
| **2순위** | Gemini via Bash | `google_search`, `web_fetch` |
| **3순위** | 자체 WebSearch | `WebSearch`, `WebFetch` |

---

## 성능 지표

리팩토링 전후 비교:

| 지표 | Before | After | 개선율 |
|------|--------|-------|--------|
| 파일 수 | 6개 (3 commands + 3 agents) | 5개 (1 command + 1 agent + 3 strategies) | -17% |
| 코드 라인 | ~2189줄 | ~1139줄 | **-48%** |
| 커맨드 중복 | 95% | 0% | **-95%** |
| 에이전트 중복 | 60% | 0% | **-60%** |
| 유지보수 포인트 | 6곳 | 1곳 | **-83%** |

---

## 제약 사항

- **Gemini 권장**: other-agents MCP 또는 gemini CLI 설치 시 구글 검색 활용
- **WebSearch Fallback**: Gemini 사용 불가 시 자체 WebSearch 사용 (미국 지역만 가능)
- **최대 결과 수**: 타입별 10-20개

---

## 트러블슈팅

### Q: 검색 결과가 0개입니다

**A**: 다음을 시도하세요:
1. 검색어를 더 구체적으로 변경
2. 다른 검색 타입 시도 (official → comprehensive)
3. 영어 키워드로 재검색

### Q: "WebSearch failed" 에러

**A**:
- 네트워크 연결 확인
- VPN 사용 시 미국 서버로 변경 (WebSearch는 미국만 지원)
- 잠시 후 재시도

### Q: Tier 3-4 결과가 너무 많습니다

**A**: `--type=official`을 사용하여 공식 출처만 검색하세요.

---

## 참고 자료

### 상세 문서

- [Search Agent 개요](./agents/README.md)
- [공식 문서 전략](./agents/resources/official-docs-strategy.md)
- [종합 검색 전략](./agents/resources/comprehensive-strategy.md)
- [모범 사례 전략](./agents/resources/best-practice-strategy.md)
- [search-core 스킬](./skills/search-core/SKILL.md)

### 개발 가이드

- [Tool Creation Guide](../../docs/guidelines/tool-creation.md)
- [Development Guidelines](../../docs/guidelines/development.md)

---

## 라이선스

MIT License - [../../LICENSE](../../LICENSE) 참고

---

## 기여하기

1. [Issue](https://github.com/inchan/claude-plugins/issues)에서 버그 리포트 또는 기능 제안
2. Fork & Pull Request
3. [개발 가이드라인](../../docs/guidelines/development.md) 준수

---

## 변경 이력

### v0.1.1 (2025-11-30)
- 🔧 **품질 개선 (v2.1)**
  - 출력 형식 중복 제거 (85% → 5%)
  - format 검증 강화 (빈 값 기본 처리)
  - Edge Cases 완전 처리
  - P1-P4 가이드라인 100% 준수 달성

### v0.1.0 (2025-11-30)
- 🎉 **통합 플러그인으로 리팩토링**
  - 기존 3개 커맨드 → 1개 통합 커맨드
  - 기존 3개 에이전트 → 1개 통합 에이전트
  - Resources 패턴 도입 (전략 문서 분리)
  - 중복 코드 60% 제거
  - 유지보수 포인트 83% 감소

### v0.0.1 (2025-11-29)
- 초기 릴리스 (3개 분리된 커맨드/에이전트)

---

## 문의

- GitHub: [inchan/claude-plugins](https://github.com/inchan/claude-plugins)
- Issues: [Report a bug](https://github.com/inchan/claude-plugins/issues)

---

**Made with ❤️ using Claude Code**
