# Doc-Tools Plugin

> 문서-코드 불일치 탐지 및 자동 수정 플러그인

[![Version](https://img.shields.io/badge/version-1.0.1-blue.svg)](./.claude-plugin/plugin.json)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](../../LICENSE)

---

## 개요

Doc-Tools Plugin은 문서와 코드 간의 불일치를 자동으로 탐지하고 수정하는 Claude Code 플러그인입니다.

### 주요 특징

- **4가지 검증 원칙**: 추적가능성, 교차검증, 사용자중심, 완성도
- **자동 수정**: `--auto-fix` 옵션으로 불일치 자동 수정
- **비용 효율**: haiku 모델 사용으로 비용 절감
- **배치 처리**: 대량 문서도 10개 단위로 안전하게 처리

---

## 설치

### Claude Code에서 설치

```bash
# 플러그인 디렉토리로 이동
cd ~/.claude/plugins

# 저장소 클론
git clone https://github.com/inchan/claude-plugins.git

# 또는 특정 플러그인만 링크
ln -s /path/to/claude-plugin/plugins/doc-tools ~/.claude/plugins/doc-tools
```

### 수동 설치

1. 이 디렉토리 전체를 `~/.claude/plugins/doc-tools`로 복사
2. Claude Code 재시작
3. `/doc-update` 커맨드 사용 가능

---

## 사용법

### 기본 사용

```bash
# 전체 문서 검사
/doc-update

# 특정 디렉토리만 검사
/doc-update --scope=specific --path=docs/

# 특정 파일 검사 + 자동 수정
/doc-update --scope=specific --path=README.md --auto-fix
```

### 옵션

| 옵션 | 설명 | 기본값 |
|------|------|--------|
| `--scope` | 검사 범위 (`all` / `specific`) | `all` |
| `--path` | 검사할 경로 (scope=specific일 때 필수) | - |
| `--auto-fix` | 자동 수정 활성화 | `false` |

---

## 검증 원칙

### 우선순위

| 순위 | 원칙 | 설명 | 예시 |
|------|------|------|------|
| 1 | **교차 검증** | 코드와 문서 간 정보 일치 | API 시그니처, 파라미터 |
| 2 | **추적가능성** | 파일:라인 참조 정확성 | `src/utils.ts:123` 형식 |
| 3 | **사용자 중심** | 사용자 관점에서의 명확성 | 예제 코드, 사용법 |
| 4 | **완성도** | 필수 섹션 존재 여부 | 변경 이력, 참고 자료 |

---

## 플러그인 구조

```
plugins/doc-tools/
├── README.md                    # 이 파일
├── .claude-plugin/
│   └── plugin.json              # 플러그인 메타데이터
├── commands/
│   └── doc-update.md            # 슬래시 커맨드
└── agents/
    └── doc-updater.md           # 불일치 탐지 에이전트
```

---

## 예시

### 예시 1: 전체 문서 검사

```bash
$ /doc-update

## 문서 업데이트 결과

### 검사 요약
- 총 문서: 15개
- 불일치 발견: 3개
- 수정 완료: 0개

### 불일치 항목

#### 1. 교차 검증 (Cross-Validation) - 최우선

- **docs/api.md:42**
  - 문제: 함수 시그니처 불일치 (문서: 2개 파라미터, 코드: 3개)
  - 제안: `processData(input, options, callback)` 형식으로 수정
  - 상태: 수동 검토 필요

#### 2. 추적가능성 (Traceability)

- **README.md:15**
  - 문제: 파일:라인 번호 누락
  - 제안: `src/index.ts:45` 추가 권장
  - 상태: 수동 검토 필요
```

### 예시 2: 자동 수정

```bash
$ /doc-update --scope=specific --path=docs/ --auto-fix

## 문서 업데이트 결과

### 검사 요약
- 총 문서: 5개
- 불일치 발견: 2개
- 수정 완료: 2개

### 다음 단계

**자동 수정 완료**:
git diff로 변경사항을 확인하세요.

**권장 명령어**:
git diff
git add .
git commit -m "docs: 문서 업데이트 (불일치 2개 수정)"
```

---

## 아키텍처

```
사용자
  ↓
/doc-update 커맨드
  ↓
1. 입력 검증 (scope, path, auto-fix 파싱)
  ↓
2. 문서 범위 결정 (Glob으로 .md 파일 수집)
  ↓
3. doc-updater 에이전트 호출
   - 4가지 원칙 기반 검증
   - haiku 모델 사용
  ↓
4. 결과 출력
   - 우선순위별 정렬
   - 수정 제안 포함
```

---

## 제약 사항

- **Markdown 전용**: `.md` 파일만 검사
- **제외 대상**: `node_modules/`, `.git/`, `.claude/`, `CHANGELOG.md`, `LICENSE.md`
- **배치 처리**: 10개 단위로 처리 (대량 문서 시)
- **자동 수정 주의**: 변경사항 리뷰 필수

---

## 트러블슈팅

### Q: "검사할 문서가 없습니다" 메시지

**A**: 다음을 확인하세요:
1. `--path` 경로가 올바른지 확인
2. 해당 경로에 `.md` 파일이 존재하는지 확인

### Q: 자동 수정이 적용되지 않음

**A**:
- `--auto-fix` 플래그가 포함되었는지 확인
- 일부 복잡한 불일치는 수동 수정이 필요할 수 있음

### Q: 에이전트 실패

**A**:
- 잠시 후 재시도
- 문서 수가 많으면 `--scope=specific`으로 범위 축소

---

## 참고 자료

### 개발 가이드

- [Tool Creation Guide](../../docs/guidelines/tool-creation.md)
- [Development Guidelines](../../docs/guidelines/development.md)
- [Documentation Guidelines](../../docs/guidelines/documentation.md)

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

### v1.0.1 (2025-12-15)
- 📝 문서 개선
  - 배치 처리 로직 상세화 (10개 단위 처리 알고리즘)
  - Constants 섹션 추가 (매직 넘버 상수화)
  - 에이전트/커맨드 문서 일관성 개선

### v1.0.0 (2025-11-30)
- 초기 릴리스
  - `/doc-update` 슬래시 커맨드 추가
  - doc-updater 에이전트 추가
  - 4가지 검증 원칙 (추적가능성/교차검증/사용자중심/완성도)
  - haiku 모델 사용으로 비용 절감
  - `--auto-fix` 옵션 지원

---

## 문의

- GitHub: [inchan/claude-plugins](https://github.com/inchan/claude-plugins)
- Issues: [Report a bug](https://github.com/inchan/claude-plugins/issues)
