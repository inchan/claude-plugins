---
name: qwen-cli-adapter
description: Alibaba Qwen CLI 어댑터. dual-ai-loop에서 Qwen 모델을 사용하기 위한 설치, 명령어 패턴, 에러 처리 가이드.
---

# Qwen CLI Adapter

## 개요

Alibaba Qwen CLI와의 통합을 위한 어댑터입니다.

## 설치 확인

```bash
which qwen
qwen --version
```

## 설치 방법

```bash
# pip를 통한 설치
pip install qwen-cli

# 또는 공식 저장소에서
git clone https://github.com/alibaba/qwen-cli
cd qwen-cli && pip install .
```

### 설정

```bash
# API 키 설정 (클라우드 사용 시)
export QWEN_API_KEY="your-key"

# 로컬 모델 경로 (로컬 사용 시)
qwen config set model_path "/path/to/model"
```

## 명령어 패턴

### 기본 실행

```bash
# stdin으로 프롬프트
echo "프롬프트" | qwen -p

# 모델 지정
qwen -m qwen2.5-coder "프롬프트"

# 파일 입력
qwen -p < prompt.txt
```

### 주요 옵션

| 옵션 | 설명 |
|------|------|
| `-p, --prompt` | stdin에서 프롬프트 읽기 |
| `-m, --model` | 모델 선택 |
| `-t, --temperature` | 생성 온도 |
| `--max-tokens` | 최대 토큰 수 |

## dual-ai-loop 연동

### 구현자 역할

```bash
echo "구현 요청:
[Claude의 계획]

요구사항:
- 완전한 코드
- 에러 처리
- 주석 포함" | qwen -p -m qwen2.5-coder
```

### 검증자 역할

```bash
echo "코드 검증:
[Claude의 코드]

검증 항목:
- 로직 정확성
- 성능
- 보안" | qwen -p -m qwen2.5-coder
```

## 버전 정보

**지원 버전**: 1.0.0+
**최소 버전**: 0.9.0

## 제한사항

- 로컬 모델은 높은 시스템 요구사항
- 클라우드 사용 시 API 비용
- 영어/중국어 최적화 (다른 언어는 성능 저하 가능)
