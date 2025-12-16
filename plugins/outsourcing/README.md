# Outsourcing Plugin

> MCP를 통해 로컬 CLI에 작업을 아웃소싱하는 Claude Code 플러그인

[![Version](https://img.shields.io/badge/version-0.1.0-blue.svg)](./.claude-plugin/plugin.json)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](../../LICENSE)

---

## 개요

Outsourcing Plugin은 MCP(Model Context Protocol)를 활용하여 로컬에 설치된 CLI 도구에 작업을 위임하는 플러그인입니다.

### 주요 특징

- **🔌 MCP 통합**: 로컬 CLI와 MCP를 통한 안전한 통신
- **📤 작업 위임**: Claude가 처리하기 어려운 작업을 전문 CLI에 아웃소싱
- **🛡️ 격리된 실행**: MCP를 통한 샌드박스 환경에서 안전하게 실행

---

## 설치

### Claude Code에서 설치

```bash
# 플러그인 디렉토리로 이동
cd ~/.claude/plugins

# 저장소 클론
git clone https://github.com/inchan/claude-plugins.git

# 또는 특정 플러그인만 링크
ln -s /path/to/claude-plugin/plugins/outsourcing ~/.claude/plugins/outsourcing
```

### 수동 설치

1. 이 디렉토리 전체를 `~/.claude/plugins/outsourcing`로 복사
2. Claude Code 재시작

---

## 사용법

### 기본 사용

```bash
# CLI 선택 질문 (대화형)
/outsource "이 프로젝트의 아키텍처를 분석하고 개선점을 제안해줘"

# 사용 흐름
1. 작업 내용 입력
2. 적합한 CLI 추천 (Claude, Gemini, Codex, Qwen 중 선택)
3. 선택한 CLI에 작업 전달
4. 요약 + 상세 결과 제공
```

### 지원하는 CLI

| CLI | 강점 | 적합한 작업 |
|-----|------|------------|
| **Claude** | 복잡한 분석, 코드 리뷰 | 아키텍처 설계, 보안 분석 |
| **Gemini** | 대규모 데이터, 다국어 | 로그 분석, 번역 |
| **Codex** | 코드 생성, 디버깅 | API 서버 작성, 테스트 생성 |
| **Qwen** | 수학, 논리적 추론 | 알고리즘 설계, 수식 풀이 |

---

## 플러그인 구조

```
plugins/outsourcing/
├── README.md                          # 이 파일
└── .claude-plugin/
    └── plugin.json                    # 플러그인 메타데이터

참조하는 파일들:
├── commands/outsource.md              # 슬래시 커맨드
├── agents/outsourcing/
│   └── outsourcing-agent.md           # MCP CLI 통신 에이전트
└── skills/outsourcing-core/
    ├── SKILL.md                       # 자동 활성화 스킬
    └── resources/
        └── cli-capabilities.md        # CLI별 특징 참고 자료
```

---

## 아키텍처

```
사용자
  ↓
/outsource 커맨드
  ↓
1. 입력 검증 (작업 내용 확인)
  ↓
2. CLI 선택 (대화형 질문)
  ↓
outsourcing-agent
  ↓
3. MCP 도구 호출
   - list_agents (설치된 CLI 확인)
   - use_agent (작업 전달)
  ↓
4. 응답 처리
   - 요약 생성 (2-3문장)
   - 상세 결과 (펼쳐보기)
  ↓
사용자에게 표시
```

---

## 예시

### 예시 1: 코드 분석 요청

```bash
$ /outsource "이 리포지토리의 테스트 커버리지를 분석하고 개선 방안을 제안해줘"

어떤 AI CLI에 작업을 위임하시겠습니까?
[사용자 선택: Claude]

작업을 Claude CLI에 전달 중...

## 요약
테스트 커버리지 65% (목표: 80%). 주요 누락: API 엔드포인트 에러 핸들링,
비동기 함수 경계 케이스. 우선순위: auth 모듈(현재 45%) 테스트 보강 권장.

## 상세 분석
<details>
<summary>펼쳐보기</summary>

[상세 분석 내용...]

</details>

---
**사용된 CLI**: claude
**작업**: 이 리포지토리의 테스트 커버리지를 분석하고 개선 방안을 제안해줘
```

### 예시 2: 코드 생성 요청

```bash
$ /outsource "FastAPI로 RESTful API 서버 만드는 예제 코드 작성"

어떤 AI CLI에 작업을 위임하시겠습니까?
[사용자 선택: Codex]

작업을 Codex CLI에 전달 중...

## 요약
FastAPI 기본 구조(라우팅, Pydantic 모델, CRUD 엔드포인트) 예제 생성 완료.
SQLAlchemy ORM 통합, 비동기 처리, OpenAPI 문서 자동 생성 포함.

## 생성된 코드
<details>
<summary>펼쳐보기</summary>

```python
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

app = FastAPI()

class Item(BaseModel):
    id: int
    name: str

@app.get("/")
def read_root():
    return {"message": "Hello World"}

# ... 추가 코드
```

</details>

---
**사용된 CLI**: codex
**작업**: FastAPI로 RESTful API 서버 만드는 예제 코드 작성
```

---

## 제약 사항

- **MCP 서버 필수**: other-agents MCP 서버가 설치되어 있어야 합니다
- **CLI 설치 필요**: 사용할 CLI(claude, gemini, codex, qwen)가 로컬에 설치되어 있어야 합니다
- **Codex Git 제약**: Codex 사용 시 현재 디렉토리가 Git 저장소여야 합니다
- **v0.1.0 제약**: 단일 CLI 실행만 지원 (병렬 처리 미지원)

---

## 향후 계획

### v0.2.0
- 복잡도 기반 자동 CLI 추천
- 키워드 + 프롬프트 길이 분석으로 최적 CLI 자동 선택

### v0.3.0
- 병렬 처리 지원
- 여러 CLI에 동시 작업 전달
- 결과 비교 및 통합

---

## 트러블슈팅

### Q: "MCP 서버에 연결할 수 없습니다" 에러

**A**: 다음을 확인하세요:
1. other-agents MCP 서버가 실행 중인지 확인
2. `~/.claude/settings.json`에 MCP 서버 설정 확인

설정 예시:
```json
{
  "mcpServers": {
    "other-agents": {
      "command": "uvx",
      "args": ["other-agents-mcp"]
    }
  }
}
```

### Q: "CLI가 로컬에 설치되어 있지 않습니다" 에러

**A**: 선택한 CLI를 설치하세요:
- **claude**: `npm install -g @anthropic-ai/claude-cli`
- **gemini**: `pip install google-generativeai`
- **codex**: `npm install -g openai`
- **qwen**: `pip install dashscope`

### Q: "Codex는 Git 저장소에서만 사용할 수 있습니다" 에러

**A**:
- Git 저장소 내에서 명령 실행
- 또는 다른 CLI(claude, gemini, qwen) 사용

---

## 참고 자료

### 상세 문서

- [Outsourcing Agent](./agents/outsourcing-agent.md)
- [CLI 특징 비교](./skills/outsourcing-core/resources/cli-capabilities.md)
- [outsourcing-core 스킬](./skills/outsourcing-core/SKILL.md)

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

### v0.1.0 (2025-11-30)
- 🎉 **초기 릴리스**
  - `/outsource` 슬래시 커맨드 추가
  - outsourcing-agent 에이전트 추가
  - outsourcing-core 스킬 추가
  - 대화형 CLI 선택 (Claude, Gemini, Codex, Qwen)
  - MCP 통합 (other-agents)
  - 요약 + 상세 결과 출력 형식
  - CLI별 특징 참고 자료 (cli-capabilities.md)

---

## 문의

- GitHub: [inchan/claude-plugins](https://github.com/inchan/claude-plugins)
- Issues: [Report a bug](https://github.com/inchan/claude-plugins/issues)

---

**Made with ❤️ using Claude Code**
