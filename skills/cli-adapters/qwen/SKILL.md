---
name: qwen-cli-adapter
description: Alibaba Qwen CLI 어댑터. dual-ai-loop에서 Qwen 모델을 사용하기 위한 설치, 명령어 패턴, 에러 처리 가이드.
---

# Qwen CLI Adapter

## 검증 상태

❌ **미검증** (2025-11-17)
- PyPI에서 `qwen-cli` 패키지 **존재하지 않음** (직접 확인됨)
- GitHub에서 `alibaba/qwen-cli` 저장소 **확인되지 않음**
- 아래 정보는 **추측 기반이며 실제 작동하지 않을 수 있습니다**

⚠️ **경고**: 이 CLI가 실제로 존재하는지 확인되지 않았습니다.

## 검증된 대안

Qwen 모델을 사용하려면 다음을 고려하세요:

```bash
# Ollama (권장 - 실제로 작동함)
ollama pull qwen2.5-coder
ollama run qwen2.5-coder "프롬프트"

# Hugging Face Transformers (Python 라이브러리)
pip install transformers
# from transformers import AutoModelForCausalLM

# vLLM (로컬 서버)
pip install vllm
```

## 개요

Alibaba Qwen CLI와의 통합을 위한 어댑터입니다.

## 설치 확인 (미검증)

```bash
which qwen
qwen --version
```

## 설치 방법 (⚠️ 미검증 - 실패 예상)

```bash
# ❌ 이 패키지는 PyPI에 존재하지 않습니다
pip install qwen-cli  # ERROR: No matching distribution found

# ❌ 이 저장소는 확인되지 않았습니다
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
