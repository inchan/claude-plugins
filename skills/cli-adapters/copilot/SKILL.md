---
name: copilot-cli-adapter
description: GitHub Copilot CLI 어댑터. gh copilot extension을 사용한 코드 제안 및 설명 기능 제공.
---

# GitHub Copilot CLI Adapter

## 검증 상태

⚠️ **부분 검증** (2025-11-17)
- GitHub Copilot CLI는 실제로 존재하는 것으로 알려져 있습니다
- 그러나 이 환경에서 직접 테스트되지 않았습니다
- 명령어 구문은 공식 문서를 참조하세요: https://docs.github.com/en/copilot/github-copilot-in-the-cli

## 개요

GitHub Copilot CLI (gh copilot)와의 통합을 위한 어댑터입니다.

## 설치 확인

```bash
# gh CLI 확인
gh --version

# copilot extension 확인
gh extension list | grep copilot
```

## 설치 방법

### 1. GitHub CLI 설치

```bash
# macOS
brew install gh

# Linux
sudo apt install gh

# Windows
winget install GitHub.cli
```

### 2. Copilot Extension 설치

```bash
gh extension install github/gh-copilot
```

### 3. 인증

```bash
gh auth login
gh copilot alias
```

## 명령어 패턴

### 코드 제안

```bash
gh copilot suggest "로그인 기능 구현"
```

### 코드 설명

```bash
gh copilot explain "코드 내용"
```

### 셸 명령어 제안

```bash
gh copilot suggest -t shell "파일 찾기"
```

## dual-ai-loop 연동

### 구현자 역할

```bash
gh copilot suggest "구현 요청:
[Claude의 계획에 따른 기능 설명]"
```

### 검증자 역할

```bash
gh copilot explain "[Claude의 코드]

이 코드의 문제점과 개선 사항을 분석해주세요."
```

## 버전 정보

**지원 버전**: 1.0.0+
**필수**: GitHub Copilot 구독

## 제한사항

- GitHub Copilot 구독 필요 (유료)
- GitHub 인증 필요
- 인터넷 연결 필수
