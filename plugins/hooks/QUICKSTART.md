# Quick Start Guide - Skill Activation Hook v3.0.0

빠른 시작을 위한 가이드입니다. 자세한 내용은 각 문서를 참조하세요.

## 📚 문서 구조

```
plugins/hooks/
├── QUICKSTART.md           ← 이 문서 (빠른 시작)
├── INSTALLATION.md         ← 설치 가이드 (의존성, 플랫폼별 설치)
├── ARCHITECTURE.md         ← 시스템 아키텍처 (컴포넌트, 데이터 흐름)
├── PERFORMANCE.md          ← 성능 최적화 (벤치마크, 튜닝)
├── README.md               ← 전체 개요 및 사용법
├── install-dependencies.sh ← 자동 설치 스크립트
└── config/
    ├── matcher-config.json ← 매처 설정
    └── synonyms.json       ← 동의어 사전
```

## 🚀 빠른 설치 (5분)

### 1단계: 시스템 요구사항 확인

```bash
# Node.js 16+, Python 3.8+ 필요
node --version   # v16.0.0 이상
python3 --version # Python 3.8.0 이상
```

**설치가 필요한 경우**:
- **macOS**: `brew install node python@3.11`
- **Ubuntu**: [INSTALLATION.md](./INSTALLATION.md) 참조

### 2단계: 자동 설치 스크립트 실행

```bash
cd ~/.claude/plugins/inchan-cc-skills/plugins/hooks
./install-dependencies.sh
```

스크립트가 자동으로 수행:
- ✅ 시스템 요구사항 검증
- ✅ Node.js 패키지 설치 (`natural`)
- ✅ Python 패키지 설치 (`sentence-transformers`)
- ✅ 모델 다운로드 (선택 사항, ~90MB)
- ✅ 실행 권한 설정
- ✅ 캐시 디렉토리 생성
- ✅ 설치 검증

**소요 시간**: 약 3-5분 (네트워크 속도에 따라 다름)

### 3단계: 설치 확인

```bash
# 의존성 확인 스크립트 실행
cd ~/.claude/plugins/inchan-cc-skills/plugins/hooks

cat << 'VERIFY' > verify-install.sh
#!/bin/bash
echo "=== Installation Verification ==="
echo "Node.js: $(node --version)"
echo "Python: $(python3 --version)"
echo "natural: $(cd matchers && npm list natural 2>/dev/null | grep natural | awk '{print $2}')"
echo "sentence-transformers: $(python3 -c 'import sentence_transformers; print(sentence_transformers.__version__)' 2>/dev/null)"
echo "==========================="
VERIFY

chmod +x verify-install.sh
./verify-install.sh
```

**예상 출력**:
```
=== Installation Verification ===
Node.js: v20.10.0
Python: Python 3.11.5
natural: 7.0.7
sentence-transformers: 2.2.2
===========================
```

## 🎯 기본 사용법

### 훅 테스트

```bash
# 간단한 테스트
echo '{"prompt": "React 컴포넌트를 만들고 싶어요"}' | ./skill-activation-hook.sh

# 로그 확인
tail -20 /tmp/claude-skill-activation.log
```

### Claude Code에서 사용

훅은 자동으로 실행됩니다:
1. Claude Code에서 프롬프트 입력
2. 훅이 자동으로 실행되어 관련 스킬 제안
3. 제안된 스킬이 UI에 표시

## ⚙️ 설정

### 기본 설정 (config/matcher-config.json)

```json
{
  "performance": {
    "maxExecutionMs": 500,
    "topKResults": 5
  },
  "caching": {
    "enabled": true,
    "maxAgeSeconds": 3600
  },
  "matchers": {
    "tier1": { "enabled": true, "method": "keyword" },
    "tier2": { "enabled": true, "method": "tfidf" },
    "tier3": { "enabled": true, "method": "semantic" }
  }
}
```

### 성능 튜닝

```bash
# 캐시 TTL 변경 (기본: 1시간)
# matcher-config.json에서 maxAgeSeconds 수정

# 디버그 모드 활성화
export DEBUG=1
./skill-activation-hook.sh

# 로그 실시간 확인
tail -f /tmp/claude-skill-activation.log
```

## 📊 성능 특성

### 실행 시간

| 시나리오 | 소요 시간 | 설명 |
|---------|----------|------|
| **Warm Start** (캐시 유효) | ~30ms | 대부분의 경우 |
| **Cold Start** (캐시 재구축) | ~340ms | 첫 실행 또는 파일 변경 시 |

### 매칭 정확도

| Tier | 속도 | 정확도 | 사용 빈도 |
|------|------|--------|----------|
| Tier 1 (Keyword) | 🚀 8ms | ⭐⭐ 67% | 85% |
| Tier 2 (TF-IDF) | ⚡ 65ms | ⭐⭐⭐ 83% | 12% |
| Tier 3 (Semantic) | 🐢 180ms | ⭐⭐⭐⭐⭐ 92% | 3% |

## 🔍 문제 해결

### 설치 문제

#### Node.js not found
```bash
# macOS
brew install node

# Ubuntu
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
```

#### Python not found
```bash
# macOS
brew install python@3.11

# Ubuntu
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt-get install -y python3.11
```

#### natural 설치 실패
```bash
cd matchers
rm -rf node_modules package-lock.json
npm cache clean --force
npm install natural
```

#### sentence-transformers 설치 실패
```bash
# pip 업그레이드
pip3 install --upgrade pip

# 재설치
pip3 install sentence-transformers
```

### 실행 문제

#### 훅이 실행되지 않음
```bash
# 1. 권한 확인
ls -la skill-activation-hook.sh
# -rwxr-xr-x여야 함

# 2. 권한 설정
chmod +x skill-activation-hook.sh

# 3. 수동 테스트
echo '{"prompt":"test"}' | ./skill-activation-hook.sh
```

#### 느린 실행 속도 (> 1초)
```bash
# 1. 캐시 확인
ls -lh cache/

# 2. 캐시 재생성
rm -rf cache/*
./skill-activation-hook.sh

# 3. 로그 확인
tail -50 /tmp/claude-skill-activation.log | grep "elapsed"
```

## 📖 추가 문서

### 설치 관련
- **[INSTALLATION.md](./INSTALLATION.md)**: 상세 설치 가이드
  - 플랫폼별 설치 방법 (macOS, Linux, WSL2)
  - 의존성 버전 요구사항
  - 트러블슈팅

### 아키텍처
- **[ARCHITECTURE.md](./ARCHITECTURE.md)**: 시스템 설계
  - 컴포넌트 구조
  - 데이터 흐름
  - 매칭 알고리즘
  - 캐싱 전략

### 성능
- **[PERFORMANCE.md](./PERFORMANCE.md)**: 성능 최적화
  - 벤치마크 결과
  - 성능 튜닝 가이드
  - 모니터링 방법
  - 문제 해결

### 사용법
- **[README.md](./README.md)**: 전체 개요 및 사용 가이드

## 🆘 도움말

### 일반적인 질문

**Q: 설치에 얼마나 걸리나요?**
A: 약 3-5분 (네트워크 속도에 따라 다름)

**Q: 어떤 플랫폼을 지원하나요?**
A: macOS, Linux (Ubuntu/Debian), WSL2

**Q: 설치 후 무엇을 해야 하나요?**
A: 자동으로 작동합니다. Claude Code에서 프롬프트를 입력하면 훅이 실행됩니다.

**Q: 성능이 느린 것 같아요**
A: [PERFORMANCE.md](./PERFORMANCE.md)의 "성능 문제 해결" 섹션 참조

**Q: 에러가 발생했어요**
A: [INSTALLATION.md](./INSTALLATION.md)의 "문제 해결" 섹션 참조

### 지원 채널

- **GitHub Issues**: https://github.com/inchan/cc-skills/issues
- **문서**: https://github.com/inchan/cc-skills/blob/main/docs/

---

**마지막 업데이트**: 2025-11-24  
**버전**: v3.0.0
