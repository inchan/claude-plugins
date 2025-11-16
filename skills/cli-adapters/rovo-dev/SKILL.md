---
name: rovo-dev-cli-adapter
description: Atlassian Rovo Dev CLI 어댑터. Jira/Confluence 통합 AI 개발 도구.
---

# Atlassian Rovo Dev CLI Adapter

## 개요

Atlassian Rovo Dev CLI와의 통합을 위한 어댑터입니다. Jira, Confluence와 연동된 AI 개발 지원 도구입니다.

## 설치 확인

```bash
which rovo-dev
rovo-dev --version
```

## 설치 방법

```bash
# npm을 통한 설치
npm install -g @atlassian/rovo-dev-cli

# 또는 atlassian-cli를 통해
atlassian cli install rovo-dev
```

### 설정

```bash
# Atlassian 인증
rovo-dev auth login

# 워크스페이스 연결
rovo-dev workspace connect
```

## 명령어 패턴

### 코드 생성

```bash
rovo-dev generate "기능 설명"
```

### 코드 리뷰

```bash
rovo-dev review "코드 파일 또는 내용"
```

### Jira 이슈 기반 구현

```bash
rovo-dev implement --issue PROJ-123
```

### Confluence 문서 기반

```bash
rovo-dev from-doc --page "페이지 ID"
```

## dual-ai-loop 연동

### 구현자 역할

```bash
echo "[Claude의 계획]" | rovo-dev generate --stdin
```

### 검증자 역할

```bash
echo "[Claude의 코드]" | rovo-dev review --stdin
```

## 버전 정보

**지원 버전**: 1.0.0+
**필수**: Atlassian Cloud 구독

## 제한사항

- Atlassian Cloud 구독 필요
- 워크스페이스 연결 필수
- Jira/Confluence 권한 필요
