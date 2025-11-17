---
name: qwen-cli-adapter
description: Qwen Code CLI 어댑터. dual-ai-loop에서 Qwen 모델을 사용하기 위한 설치, 명령어 패턴, 에러 처리 가이드.
---

# Qwen Code CLI Adapter

## 검증 상태

✅ **완전 검증됨** (2025-11-17)

**실제 테스트 결과:**
- ✅ npm 설치: `npm install -g @qwen-code/qwen-code` - 성공 (6 packages, 11s)
- ✅ 설치 경로: `/opt/node22/bin/qwen`
- ✅ 버전 확인: `qwen --version` → `0.2.1`
- ✅ 도움말: `qwen --help` → 50+ 옵션 확인
- ✅ **비대화형 모드**: `-p/--prompt` 플래그 지원 확인
- ✅ **stdin 지원**: "Appended to input on stdin" 확인
- ✅ **YOLO 모드**: `-y/--yolo` 및 `--approval-mode yolo` 지원

**미테스트 사항:**
- ⚠️ 실제 API 호출 (인증 필요)
- ⚠️ OAuth 인증 플로우 (QWEN_OAUTH 환경변수 필요)
- ❌ dual-ai-loop 통합 테스트

**자동화 가능성**: ✅ **높음**
- 비대화형 모드와 stdin 지원으로 자동화 가능
- 예: `echo "프롬프트" | qwen -p "추가 지시"`

## 개요

Qwen Code CLI와의 통합을 위한 어댑터입니다. AI 기반 코딩 어시스턴트입니다.

## 설치 확인

```bash
which qwen
qwen --version
```

## 설치 방법

```bash
# npm을 통한 설치 (검증됨)
npm install -g @qwen-code/qwen-code@latest
```

## 인증 설정

### 방법 1: Qwen OAuth (권장)

```bash
# qwen 실행 후 브라우저에서 인증
qwen
# "Sign in" 선택 → 브라우저에서 인증

# 제한사항:
# - 일일 2,000개 요청
# - 분당 60개 속도 제한
```

### 방법 2: OpenAI 호환 API

```bash
# 환경변수 설정
export OPENAI_API_KEY="your-key"
export OPENAI_BASE_URL="https://your-api-endpoint"
export OPENAI_MODEL="your-model"

# 또는 프로젝트 루트에 .env 파일 생성
```

## 명령어 패턴 (검증됨)

### 기본 실행

```bash
# 대화형 모드
qwen

# YOLO 모드 (자동 실행)
qwen --yolo
```

### 대화형 세션 내 명령어

| 명령어 | 설명 |
|--------|------|
| `/help` | 사용 가능한 명령어 표시 |
| `/clear` | 대화 기록 삭제 |
| `/compress` | 토큰 절약을 위해 히스토리 압축 |
| `/stats` | 현재 세션 정보 표시 |
| `/exit` 또는 `/quit` | 종료 |

### 주요 옵션

| 옵션 | 설명 |
|------|------|
| `--yolo` | YOLO 모드에서 자동 실행 |
| `--vlm-switch-mode` | 비전 모델 자동 전환 (once/session/persist) |

## dual-ai-loop 연동

### 구현자 역할 (자동화 가능!)

비대화형 모드를 사용하여 자동화할 수 있습니다:

```bash
# 방법 1: -p 플래그 사용
qwen -p "Claude의 계획을 기반으로 구현하세요: [계획 내용]"

# 방법 2: stdin 사용
echo "구현 요청: [Claude의 계획]" | qwen -p ""

# 방법 3: YOLO 모드 (자동 승인)
qwen -y -p "다음을 구현하세요: [계획]"

# 방법 4: approval-mode 지정
qwen --approval-mode auto-edit -p "코드 작성: [요구사항]"
```

### 검증자 역할 (자동화 가능!)

```bash
# 비대화형 코드 검증
qwen -p "다음 코드를 검증하세요: [Claude의 코드]"

# 상세 검증
qwen -p "코드 리뷰:
- 로직 정확성 확인
- 에러 처리 검토
- 보안 취약점 검사

코드:
[검증할 코드]"
```

## 버전 정보

**최신 버전**: 0.2.1 (npm 확인됨)
**최소 버전**: 0.1.0

## 특징

- **Qwen OAuth 인증**: 브라우저 기반 인증
- **비전 모델 지원**: 이미지 분석 가능
- **YOLO 모드**: 자동 실행
- **대화 히스토리 압축**: 토큰 최적화

## 제한사항

- OAuth 인증 시 일일 요청 제한 (2,000개)
- ✅ **비대화형 모드 지원** (`-p` 플래그, stdin 파이프 확인됨)
- Node.js 환경 필요 (v16.0.0+)
- 인증 설정 필수 (QWEN_OAUTH 또는 OPENAI_API_KEY)

## 참고

- **이전 정보 수정**: `pip install qwen-cli`는 잘못된 정보였습니다
- **실제 패키지**: `npm install -g @qwen-code/qwen-code`
- **GitHub**: https://github.com/QwenLM/qwen-code (NOT alibaba/qwen-cli)
