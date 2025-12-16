# TDD Plugin

> TDD 방식의 자동화된 개발 워크플로우 (Red-Green-Refactor)

[![Version](https://img.shields.io/badge/version-0.0.1-blue.svg)](./.claude-plugin/plugin.json)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](../../LICENSE)

---

## 개요

TDD Plugin은 5개의 전문 에이전트가 협력하여 TDD(Test-Driven Development) 사이클을 자동으로 실행하는 Claude Code 플러그인입니다.

### 주요 특징

- **5개 전문 에이전트**: task-planner, test-writer, implementer, refactorer, reviewer
- **Red-Green-Refactor**: 완전한 TDD 사이클 자동화
- **다국어 지원**: TypeScript/JavaScript, Python
- **병렬 처리**: 의존성 없는 작업은 최대 4개까지 병렬 실행
- **자동 재시도**: 실패 시 최대 3회 재시도

---

## 설치

### Claude Code에서 설치

```bash
# 플러그인 디렉토리로 이동
cd ~/.claude/plugins

# 저장소 클론
git clone https://github.com/inchan/claude-plugins.git

# 또는 특정 플러그인만 링크
ln -s /path/to/claude-plugin/plugins/tdd ~/.claude/plugins/tdd
```

### 수동 설치

1. 이 디렉토리 전체를 `~/.claude/plugins/tdd`로 복사
2. Claude Code 재시작
3. `/tdd-team` 커맨드 사용 가능

---

## 사용법

### 기본 사용

```bash
# 간단한 기능
/tdd-team "배열 합계 함수"

# 복잡한 기능 (추가 요구사항 포함)
/tdd-team "사용자 인증 API" "JWT 토큰" "bcrypt 해싱"
```

### 사전 요구사항

테스트 프레임워크가 설치되어 있어야 합니다:

| 언어 | 지원 프레임워크 | 설치 명령 |
|------|---------------|----------|
| TypeScript/JS | Jest, Vitest, Mocha | `npm install --save-dev jest` |
| Python | Pytest, Unittest | `pip install pytest` |

---

## 에이전트 구성

### TDD 팀 (5개 에이전트)

| 에이전트 | 역할 | TDD 단계 | 주요 기능 |
|---------|------|---------|----------|
| **task-planner** | 작업 분해 | 준비 | 큰 기능 → 작은 단위 (최대 20개), 성공 기준 정의 |
| **test-writer** | 테스트 우선 | Red | 실패하는 테스트 먼저 작성, 실패 확인 |
| **implementer** | 최소 구현 | Green | 테스트 통과하는 최소 코드, YAGNI 준수 |
| **refactorer** | 코드 개선 | Refactor | 품질 향상 (복잡도 감소, DRY 적용) |
| **reviewer** | 품질 검증 | 검증 | P1-P4 원칙 확인, 승인/거부 결정 |

### 워크플로우

```
사용자
  ↓
/tdd-team "기능 설명"
  ↓
1. 입력 검증 (10자 이상)
  ↓
2. 언어/프레임워크 감지
  ↓
3. task-planner: 작업 분해
  ↓
4. 배치 그룹화 (의존성 기반)
  ↓
5. 배치별 TDD 사이클
   ├─ RED: test-writer (병렬 가능)
   ├─ GREEN: implementer
   ├─ REFACTOR: refactorer
   └─ REVIEW: reviewer
  ↓
6. 최종 리포트
```

---

## 플러그인 구조

```
plugins/tdd/
├── README.md                      # 이 파일
├── .claude-plugin/
│   └── plugin.json                # 플러그인 메타데이터
├── commands/
│   └── tdd-team.md                # 슬래시 커맨드
└── agents/
    ├── task-planner.md            # 작업 분해 에이전트
    ├── test-writer.md             # Red 단계 에이전트
    ├── implementer.md             # Green 단계 에이전트
    ├── refactorer.md              # Refactor 단계 에이전트
    └── reviewer.md                # 품질 검증 에이전트

# 관련 테스트 (프로젝트 루트 기준)
tests/tdd/
├── README.md                      # 테스트 가이드
└── test-*.md                      # 개별 테스트 시나리오
```

---

## 예시

### 예시 1: 간단한 유틸리티 함수

```bash
$ /tdd-team "배열의 짝수만 필터링하는 함수"

## 언어 감지
TypeScript 프로젝트 감지 (jest)

## 작업 분해
1. filterEven 함수 기본 구현
2. 빈 배열 처리
3. 음수 처리

## TDD 진행

### Batch 1 (3개 작업 병렬)

**Task 1: filterEven 기본 구현**
- RED: filterEven.test.ts 생성 ✓
- GREEN: filterEven.ts 구현 ✓
- REFACTOR: 타입 추가 ✓
- REVIEW: 승인 ✓

[... 나머지 작업 ...]

## 완료
- 완료: 3/3 작업
- 생성 파일: filterEven.ts, filterEven.test.ts

## 다음 단계
npm test && git commit
```

### 예시 2: 복잡한 API

```bash
$ /tdd-team "사용자 인증 API" "JWT 토큰" "bcrypt 해싱"

## 언어 감지
TypeScript 프로젝트 감지 (jest)

## 작업 분해 (20개 초과 감지)
총 25개 작업이 생성되었습니다.

어떻게 진행하시겠습니까?
1. 첫 20개만 실행
2. 기능 분할 (로그인/회원가입/토큰갱신)
3. 전체 실행

[사용자 선택: 2. 기능 분할]

로그인 기능부터 시작합니다...
```

---

## 배치 실행 전략

### 의존성 기반 그룹화

```
tasks = [A, B, C, D, E]
dependencies = { B: [A], C: [A], D: [B, C], E: [] }

→ Batch 1: [A, E]     (의존성 없음, 병렬 실행)
→ Batch 2: [B, C]     (A 완료 후, 병렬 실행)
→ Batch 3: [D]        (B, C 완료 후)
```

### 파일 충돌 방지

같은 파일을 수정하는 작업은 동일 배치에 포함되지 않음

---

## 제약 사항

- **테스트 프레임워크 필수**: Jest, Vitest, Pytest 등
- **최대 작업 수**: 20개 초과 시 사용자 선택
- **병렬 실행**: Red 단계만, 최대 4개
- **재시도 횟수**: 최대 3회
- **기능 설명**: 10자 이상 필수

---

## 트러블슈팅

### Q: "테스트 프레임워크를 찾을 수 없습니다" 에러

**A**: 테스트 프레임워크를 설치하세요:
```bash
# TypeScript/JavaScript
npm install --save-dev jest
# 또는
npm install --save-dev vitest

# Python
pip install pytest
```

### Q: 작업이 계속 실패합니다

**A**:
- 기능 설명을 더 구체적으로 작성
- 복잡한 기능은 여러 개로 분할
- 3회 실패 시 "건너뛰기" 선택 후 수동 구현

### Q: 병렬 실행이 되지 않습니다

**A**:
- 의존성이 있는 작업은 순차 실행됨
- 같은 파일을 수정하는 작업은 순차 실행됨

---

## 참고 자료

### 상세 문서

- [TDD 다중 에이전트 패턴](../../docs/references/agents/tdd-multi-agent-pattern.md)
- [TDD Orchestrator 가이드](../../docs/references/agents/tdd-orchestrator-guide.md)

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

### v0.0.2 (2025-12-15)
- 📝 플러그인 구조 섹션 수정 (tests 경로 명확화: tests/tdd/)

### v0.0.1 (2025-11-30)
- 초기 릴리스
  - `/tdd-team` 슬래시 커맨드 추가
  - 5개 TDD 에이전트 (task-planner, test-writer, implementer, refactorer, reviewer)
  - Red-Green-Refactor 자동화
  - TypeScript/JavaScript, Python 지원
  - 배치 병렬 처리 (최대 4개)
  - 자동 재시도 (최대 3회)

---

## 문의

- GitHub: [inchan/claude-plugins](https://github.com/inchan/claude-plugins)
- Issues: [Report a bug](https://github.com/inchan/claude-plugins/issues)
