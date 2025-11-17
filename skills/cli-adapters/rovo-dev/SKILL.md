---
name: rovo-dev-cli-adapter
description: Atlassian Rovo Dev CLI 어댑터 (ACLI 서브커맨드). Jira/Confluence 통합 AI 개발 도구.
---

# Atlassian Rovo Dev CLI Adapter

## 검증 상태

⚠️ **부분 검증됨** (2025-11-17)

**확인된 사항:**
- ✅ 공식 문서 존재: https://support.atlassian.com/rovo/docs/install-and-run-rovo-dev-cli-on-your-device/
- ✅ 제품 페이지: https://www.atlassian.com/software/rovo-dev
- ✅ 기본 명령어 구조: `acli rovodev run`

**미확인 사항:**
- ❌ ACLI 실제 설치 테스트
- ❌ `acli rovodev` 명령어 실행 테스트
- ❌ API 토큰 인증 플로우 작동
- ❌ 설정 파일 옵션 검증
- ❌ dual-ai-loop 통합 테스트

⚠️ **중요**:
- `rovo-dev`는 독립 CLI가 아닌 **ACLI (Atlassian Command Line Interface)의 서브커맨드**입니다.
- 대화형 에이전트로, 자동화에 제한이 있을 수 있습니다.
- 현재 베타 버전 (기능 및 API 변경 가능)

## 개요

Atlassian Rovo Dev CLI와의 통합을 위한 어댑터입니다. ACLI를 통해 Jira, Confluence, Bitbucket과 연동된 AI 개발 지원 도구입니다.

- **SWE-bench 성능**: 41.98% resolve rate (2,294개 작업) - 리더보드 1위
- **주요 기능**: 코드 이해/탐색, 개발 가속화, 코드 마이그레이션

## 설치 확인

```bash
# ACLI 설치 확인
which acli
acli --version

# Rovo Dev 서브커맨드 확인
acli rovodev --help
```

## 설치 방법

### 1단계: ACLI 설치 (필수)

**npm/pip가 아닌 OS별 설치 가이드를 따르세요:**
- macOS: https://support.atlassian.com/rovo/docs/install-acli-macos/
- Linux: https://support.atlassian.com/rovo/docs/install-acli-linux/
- Windows: https://support.atlassian.com/rovo/docs/install-acli-windows/

```bash
# ACLI가 설치되면 rovodev 서브커맨드 자동 포함
acli rovodev --help
```

### 2단계: Rovo Dev Agents 앱 설치

Atlassian 사이트에 Rovo Dev Agents 앱이 설치되어야 합니다.

### 3단계: 인증 설정

```bash
# Atlassian 계정 인증
acli rovodev auth login

# API 토큰 생성 필요 (자동 또는 수동)
# 필요 권한: Admin, Chat, Delete, Manage, Read, Search, Write
```

## 명령어 패턴 (검증됨)

### 기본 실행

```bash
# Rovo Dev 실행
acli rovodev run

# 설정 파일 지정
acli rovodev run --config-file ~/.rovodev/configuration.yml
```

### 인증

```bash
acli rovodev auth login
```

## dual-ai-loop 연동

### 구현자 역할

Rovo Dev는 대화형 에이전트입니다. dual-ai-loop에서 사용 시:

1. `acli rovodev run` 실행
2. Claude의 계획을 프롬프트로 입력
3. 결과를 Claude에게 전달

```bash
# 대화형 모드에서
acli rovodev run
# 그 후 프롬프트 입력:
# "구현 요청: [Claude의 계획]"
```

### 검증자 역할

```bash
acli rovodev run
# "코드 검증: [Claude의 코드]"
```

## 버전 정보

**현재 상태**: 베타 버전
**필수**: ACLI 최신 버전 + Atlassian Cloud 구독

## 특징

- **Atlassian 통합**: Jira, Confluence, Bitbucket 연동
- **적응형 메모리**: 프로젝트 지식 유지
- **MCP 서버**: Model Context Protocol 확장성
- **역할 기반 권한**: 세밀한 접근 제어

## 제한사항

- ACLI 설치 필수 (npm/pip 불가)
- Atlassian Cloud 구독 필요
- Rovo Dev Agents 앱 사이트 설치 필수
- API 토큰 및 적절한 권한 필요
- 현재 베타 버전 (기능 변경 가능)

## 참고

- **이전 정보 수정**: `npm install -g @atlassian/rovo-dev-cli`는 잘못된 정보였습니다
- **실제 설치**: ACLI를 통해 설치 (OS별 가이드 참조)
- **실제 명령어**: `acli rovodev` (NOT `rovo-dev`)
