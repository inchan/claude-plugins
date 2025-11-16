---
name: aider-cli-adapter
description: Aider CLI 어댑터. Git 통합 AI 페어 프로그래밍 도구.
---

# Aider CLI Adapter

## 개요

Aider CLI와의 통합을 위한 어댑터입니다. Git 저장소와 통합된 AI 페어 프로그래밍 도구입니다.

## 설치 확인

```bash
which aider
aider --version
```

## 설치 방법

```bash
# pip를 통한 설치
pip install aider-chat

# 또는 pipx (격리 환경)
pipx install aider-chat
```

### 설정

```bash
# OpenAI API 키
export OPENAI_API_KEY="your-key"

# 또는 Anthropic API 키
export ANTHROPIC_API_KEY="your-key"
```

## 명령어 패턴

### 메시지 모드

```bash
aider --message "구현 요청"
```

### 파일 지정

```bash
aider src/main.py --message "이 파일 수정"
```

### 자동 커밋

```bash
aider --auto-commits --message "기능 추가"
```

### 모델 선택

```bash
aider --model gpt-4 --message "작업"
```

## dual-ai-loop 연동

### 구현자 역할

```bash
aider --message "구현 요청:
[Claude의 계획]

요구사항:
- 파일 수정/생성
- Git 커밋 포함"
```

### 검증자 역할

```bash
aider --message "코드 리뷰:
[Claude의 코드]

검증 후 개선 제안"
```

## 특징

- **Git 통합**: 자동 커밋, diff 생성
- **멀티 모델**: GPT-4, Claude, 로컬 모델 지원
- **컨텍스트 유지**: 파일 변경 히스토리 추적
- **페어 프로그래밍**: 대화형 개발

## 버전 정보

**지원 버전**: 0.50.0+
**최소 버전**: 0.40.0

## 제한사항

- Git 저장소 내에서만 작동
- LLM API 키 필요
- 대용량 파일에서 성능 저하
