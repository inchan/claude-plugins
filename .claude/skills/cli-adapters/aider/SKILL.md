---
name: aider-cli-adapter
description: Aider CLI 어댑터. Git 통합 AI 페어 프로그래밍 도구.
---

# Aider CLI Adapter

## 검증 상태

✅ **검증됨** (2025-11-17)
- PyPI 패키지: aider-chat (v0.86.1)
- GitHub: https://github.com/paul-gauthier/aider
- 163명 기여자, 93개 릴리스

## 개요

Aider CLI와의 통합을 위한 어댑터입니다. Git 저장소와 통합된 AI 페어 프로그래밍 도구입니다.

## 설치 확인

```bash
which aider
aider --version
```

## 설치 방법

```bash
# 권장 방법 (공식 문서 기준)
python -m pip install aider-install
aider-install

# 또는 직접 설치
pip install aider-chat

# 또는 pipx (격리 환경)
pipx install aider-chat
```

### 설정 (검증된 형식)

```bash
# API 키를 인라인으로 지정 (공식 문서 기준)
aider --model deepseek --api-key deepseek=<your-key>
aider --model sonnet --api-key anthropic=<your-key>
aider --model o3-mini --api-key openai=<your-key>
```

### 환경변수 설정 (대안)

```bash
# OpenAI API 키
export OPENAI_API_KEY="your-key"

# 또는 Anthropic API 키
export ANTHROPIC_API_KEY="your-key"

# 또는 DeepSeek API 키
export DEEPSEEK_API_KEY="your-key"
```

## 명령어 패턴 (검증됨)

### 기본 형식

```bash
aider --model [모델명] --api-key [제공자]=[키값]
```

### 모델 선택 예시

```bash
# DeepSeek
aider --model deepseek --api-key deepseek=<key>

# Claude 3.7 Sonnet
aider --model sonnet --api-key anthropic=<key>

# OpenAI o3-mini
aider --model o3-mini --api-key openai=<key>
```

### 파일 지정

```bash
aider src/main.py --message "이 파일 수정"
```

### 자동 커밋

```bash
aider --auto-commits --message "기능 추가"
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

**최신 버전**: 0.86.1 (PyPI 확인됨)
**최소 버전**: 0.50.0

## 제한사항

- Git 저장소 내에서만 작동
- LLM API 키 필요
- 대용량 파일에서 성능 저하
