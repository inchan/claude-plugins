# Skill Activation Hook v3.0.0 - 문서 색인

## 📖 문서 개요

이 디렉토리에는 Skill Activation Hook v3.0.0의 모든 문서가 포함되어 있습니다.

## 🎯 시작하기

### 처음 사용하시나요?

1. **[QUICKSTART.md](./QUICKSTART.md)** ⚡ - 5분 안에 설치 및 실행
   - 빠른 설치 가이드
   - 기본 사용법
   - 자주 묻는 질문

### 상세 설치 가이드

2. **[INSTALLATION.md](./INSTALLATION.md)** 📦 - 상세 설치 가이드
   - 시스템 요구사항 (Node.js, Python)
   - 플랫폼별 설치 방법 (macOS, Linux, WSL2)
   - 의존성 설치 (natural, sentence-transformers)
   - 문제 해결 (15개 이상의 해결책)
   - 업그레이드 가이드 (v2.0 → v3.0)

### 시스템 이해하기

3. **[ARCHITECTURE.md](./ARCHITECTURE.md)** 🏗️ - 시스템 아키텍처
   - 전체 시스템 구조 (다이어그램 포함)
   - 핵심 컴포넌트 설명
   - 데이터 흐름 (Cold/Warm/Invalidation)
   - 다층 매칭 파이프라인 (Tier 1/2/3)
   - 캐싱 전략 및 성능 특성

4. **[PERFORMANCE.md](./PERFORMANCE.md)** 📊 - 성능 최적화
   - 벤치마크 결과 (실제 측정 데이터)
   - 성능 최적화 전략 (4가지)
   - 성능 모니터링 방법
   - 문제 해결 (5가지 일반적인 문제)
   - 향후 개선 계획

### 사용 가이드

5. **[README.md](./README.md)** 📘 - 전체 개요 및 사용 가이드
   - 프로젝트 개요
   - 사용 방법
   - 설정 옵션
   - 예제

## 🛠️ 설치 도구

### 자동 설치 스크립트

**[install-dependencies.sh](./install-dependencies.sh)** 🔧
- 원클릭 설치 스크립트
- 시스템 요구사항 자동 검증
- Node.js/Python 패키지 설치
- 모델 다운로드 (선택 사항)
- 실행 권한 설정
- 설치 검증

**사용법**:
```bash
cd ~/.claude/plugins/inchan-cc-skills/plugins/hooks
./install-dependencies.sh
```

## ⚙️ 설정 파일

### config/matcher-config.json

매처 시스템의 모든 설정을 포함:
- 성능 임계값 (execution time, timeout)
- 캐싱 설정 (TTL, cache directory)
- 매처 활성화/비활성화 (Tier 1/2/3)
- 점수 가중치 (keyword, tfidf, semantic)
- 로깅 설정
- 출력 형식
- 실험적 기능 플래그

### config/synonyms.json

키워드 확장을 위한 동의어 사전:
- 한글-영어 동의어 매핑
- 카테고리별 그룹핑
- 확장 가능한 구조

## 📁 파일 구조

```
plugins/hooks/
├── INDEX.md                      ← 이 문서 (문서 색인)
├── QUICKSTART.md                 ← 빠른 시작 가이드
├── INSTALLATION.md               ← 설치 가이드
├── ARCHITECTURE.md               ← 시스템 아키텍처
├── PERFORMANCE.md                ← 성능 최적화
├── README.md                     ← 전체 개요
│
├── install-dependencies.sh       ← 자동 설치 스크립트
├── skill-activation-hook.sh      ← 메인 훅 스크립트
├── stop-hook-lint-and-translate.sh
│
├── config/
│   ├── matcher-config.json       ← 매처 설정
│   └── synonyms.json             ← 동의어 사전
│
├── lib/
│   ├── cache-manager.sh          ← 캐시 관리
│   ├── metadata-parser.sh        ← 메타데이터 파싱
│   └── plugin-discovery.sh       ← 플러그인 검색
│
├── matchers/
│   ├── tfidf-matcher.js          ← TF-IDF 매처 (Node.js)
│   ├── semantic-matcher.py       ← Semantic 매처 (Python)
│   ├── package.json              ← Node.js 의존성
│   └── requirements.txt          ← Python 의존성
│
├── cache/
│   ├── skill-metadata.json       ← 스킬 메타데이터 캐시
│   └── file-index.txt            ← 파일 변경 추적
│
└── tests/
    ├── run-all-tests.sh
    ├── benchmark-performance.sh
    └── ...
```

## 🎓 학습 경로

### 초보자

1. **[QUICKSTART.md](./QUICKSTART.md)** - 기본 개념 이해
2. **[INSTALLATION.md](./INSTALLATION.md)** - 시스템 설치
3. 실제 사용 (Claude Code에서 테스트)

### 중급자

1. **[ARCHITECTURE.md](./ARCHITECTURE.md)** - 시스템 동작 방식 이해
2. **[PERFORMANCE.md](./PERFORMANCE.md)** - 성능 최적화 방법
3. **config/matcher-config.json** - 설정 커스터마이징

### 고급자

1. 코드 분석 (`skill-activation-hook.sh`, `lib/*.sh`)
2. 매처 커스터마이징 (`matchers/*.js`, `matchers/*.py`)
3. 새로운 Tier 추가 또는 알고리즘 개선

## 🔍 빠른 참조

### 설치 관련

| 질문 | 답변 문서 |
|------|----------|
| 어떻게 설치하나요? | [QUICKSTART.md](./QUICKSTART.md) |
| 의존성은 무엇인가요? | [INSTALLATION.md](./INSTALLATION.md) |
| 플랫폼별 설치 방법은? | [INSTALLATION.md](./INSTALLATION.md) - 플랫폼별 가이드 |
| 설치가 실패했어요 | [INSTALLATION.md](./INSTALLATION.md) - 문제 해결 |

### 아키텍처 관련

| 질문 | 답변 문서 |
|------|----------|
| 시스템이 어떻게 작동하나요? | [ARCHITECTURE.md](./ARCHITECTURE.md) |
| 매칭 알고리즘은? | [ARCHITECTURE.md](./ARCHITECTURE.md) - Multi-Tier Matching |
| 캐싱은 어떻게 작동하나요? | [ARCHITECTURE.md](./ARCHITECTURE.md) - Cache Manager |
| 데이터 흐름은? | [ARCHITECTURE.md](./ARCHITECTURE.md) - 데이터 흐름 |

### 성능 관련

| 질문 | 답변 문서 |
|------|----------|
| 실행 속도가 느려요 | [PERFORMANCE.md](./PERFORMANCE.md) - 문제 해결 |
| 벤치마크 결과는? | [PERFORMANCE.md](./PERFORMANCE.md) - 벤치마크 결과 |
| 어떻게 최적화하나요? | [PERFORMANCE.md](./PERFORMANCE.md) - 최적화 전략 |
| 성능 모니터링은? | [PERFORMANCE.md](./PERFORMANCE.md) - 성능 모니터링 |

### 설정 관련

| 질문 | 답변 문서 |
|------|----------|
| 설정 파일 위치는? | `config/matcher-config.json` |
| 캐시 TTL 변경 | `matcher-config.json` - caching.maxAgeSeconds |
| Tier 비활성화 | `matcher-config.json` - matchers.tierN.enabled |
| 동의어 추가 | `config/synonyms.json` |

## 📞 지원

### 문제가 해결되지 않나요?

1. **문서 검색**: 위의 빠른 참조 테이블 활용
2. **로그 확인**: `/tmp/claude-skill-activation.log`
3. **디버그 모드**: `DEBUG=1 ./skill-activation-hook.sh`
4. **GitHub Issues**: https://github.com/inchan/cc-skills/issues

## 🔄 버전 정보

- **현재 버전**: v3.0.0
- **마지막 업데이트**: 2025-11-24
- **주요 변경사항**:
  - 다층 매칭 파이프라인 추가 (Tier 1/2/3)
  - 지능형 캐싱 시스템 도입
  - TF-IDF 기반 통계적 매칭
  - Semantic embedding 기반 의미론적 매칭
  - 성능 10배 향상 (500ms → 50ms)

## 📝 기여

문서 개선 제안이나 오류 발견 시:
1. GitHub Issue 생성
2. Pull Request 제출
3. 문서 피드백 제공

---

**Happy Coding! 🚀**
