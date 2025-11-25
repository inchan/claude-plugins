# Configuration Files - Skill Activation Hook v3.0.0

이 디렉토리에는 Skill Activation Hook의 설정 파일들이 포함되어 있습니다.

## 📁 파일 목록

### 1. matcher-config.json

**역할**: 매처 시스템의 모든 설정을 관리하는 중앙 설정 파일

**주요 설정 섹션**:

#### Performance (성능)
```json
{
  "maxExecutionMs": 500,        // 최대 실행 시간 (밀리초)
  "tier1ThresholdMax": 50,      // Tier 1 최대 실행 시간
  "tier2ThresholdMax": 20,      // Tier 2 최대 실행 시간
  "tier3ThresholdMax": 10,      // Tier 3 최대 실행 시간
  "topKResults": 5              // 반환할 최대 결과 수
}
```

#### Caching (캐싱)
```json
{
  "enabled": true,              // 캐싱 활성화/비활성화
  "maxAgeSeconds": 3600,        // 캐시 유효 시간 (1시간)
  "cacheDir": "cache",          // 캐시 디렉토리
  "fileIndexName": "file-index.txt",
  "metadataFileName": "skill-metadata.json"
}
```

#### Matchers (매처)
```json
{
  "tier1": {
    "enabled": true,            // Tier 1 활성화
    "method": "keyword",        // 키워드 매칭
    "timeoutMs": 50,
    "minScore": 0.0,
    "fallbackToTier2": true
  },
  "tier2": {
    "enabled": true,            // Tier 2 활성화
    "method": "tfidf",          // TF-IDF 매칭
    "timeoutMs": 100,
    "minScore": 0.1,
    "fallbackToTier3": true,
    "nodeScript": "matchers/tfidf-matcher.js"
  },
  "tier3": {
    "enabled": true,            // Tier 3 활성화
    "method": "semantic",       // 의미론적 매칭
    "timeoutMs": 500,
    "minScore": 0.1,
    "pythonScript": "matchers/semantic-matcher.py",
    "model": "all-MiniLM-L6-v2",
    "dimensions": 384
  }
}
```

#### Scoring (점수)
```json
{
  "weights": {
    "keyword": 1.0,             // 키워드 매칭 가중치
    "tfidf": 1.5,               // TF-IDF 가중치
    "semantic": 2.0             // 의미론적 매칭 가중치
  },
  "priority": {
    "critical": 4,              // Critical 우선순위 점수
    "high": 3,
    "medium": 2,
    "low": 1
  }
}
```

**수정 방법**:
```bash
# 파일 편집
vim config/matcher-config.json

# 또는
nano config/matcher-config.json
```

**주의사항**:
- JSON 형식을 유지해야 합니다
- 변경 후 캐시를 삭제하세요: `rm -rf cache/*`
- 설정 검증: `node -e "console.log(JSON.parse(require('fs').readFileSync('config/matcher-config.json')))"`

---

### 2. synonyms.json

**역할**: 키워드 매칭을 위한 동의어 및 유사어 사전

**구조**:
```json
{
  "synonyms": {
    "키워드": ["동의어1", "동의어2", "영어표현", "한글표현"]
  },
  "categories": {
    "카테고리명": ["키워드1", "키워드2"]
  }
}
```

**예시**:
```json
{
  "synonyms": {
    "debug": ["debugging", "디버그", "디버깅", "버그수정", "bug fix"],
    "frontend": ["프론트엔드", "front-end", "클라이언트", "UI", "client"],
    "backend": ["백엔드", "back-end", "서버", "server", "API"]
  },
  "categories": {
    "development": ["debug", "test", "refactor", "optimize"],
    "frontend": ["react", "component", "style", "ui", "ux"],
    "backend": ["api", "database", "server", "auth"]
  }
}
```

**동의어 추가 방법**:
```json
{
  "synonyms": {
    "새키워드": ["동의어1", "동의어2"]
  }
}
```

**사용 사례**:
- 한글-영어 상호 매칭
- 약어 확장 (UI → User Interface)
- 유사 개념 그룹핑 (디버깅 → 버그수정 → 에러추적)

**주의사항**:
- 모든 동의어는 소문자로 저장 (매칭 시 대소문자 무시)
- 너무 많은 동의어는 false positive 증가 가능
- 카테고리는 스킬 그룹핑에만 사용

---

## 🔧 설정 가이드

### 성능 최적화

#### 1. 빠른 응답이 필요한 경우
```json
{
  "matchers": {
    "tier1": { "enabled": true },
    "tier2": { "enabled": false },  // Tier 2 비활성화
    "tier3": { "enabled": false }   // Tier 3 비활성화
  }
}
```

#### 2. 정확도가 중요한 경우
```json
{
  "matchers": {
    "tier1": { "enabled": true },
    "tier2": { "enabled": true },
    "tier3": { "enabled": true }    // 모든 Tier 활성화
  },
  "performance": {
    "maxExecutionMs": 1000          // 시간 제한 완화
  }
}
```

#### 3. 캐시 TTL 조정
```json
{
  "caching": {
    "maxAgeSeconds": 7200           // 2시간으로 연장
  }
}
```

### 동의어 확장

#### 프로젝트 특화 용어 추가
```json
{
  "synonyms": {
    "프로젝트명": ["약어", "풀네임", "영어명"],
    "내부용어": ["외부용어", "표준용어"]
  }
}
```

#### 카테고리 추가
```json
{
  "categories": {
    "mobile": ["ios", "android", "react-native", "flutter"],
    "devops": ["docker", "kubernetes", "ci", "cd", "deploy"]
  }
}
```

---

## 📊 설정 템플릿

### 개발 환경 (빠른 피드백)
```json
{
  "performance": {
    "maxExecutionMs": 300,
    "topKResults": 3
  },
  "caching": {
    "maxAgeSeconds": 1800
  },
  "matchers": {
    "tier1": { "enabled": true },
    "tier2": { "enabled": false },
    "tier3": { "enabled": false }
  },
  "logging": {
    "debugMode": true
  }
}
```

### 프로덕션 환경 (균형)
```json
{
  "performance": {
    "maxExecutionMs": 500,
    "topKResults": 5
  },
  "caching": {
    "maxAgeSeconds": 3600
  },
  "matchers": {
    "tier1": { "enabled": true },
    "tier2": { "enabled": true },
    "tier3": { "enabled": true }
  },
  "logging": {
    "debugMode": false
  }
}
```

### 정확도 우선 (느림)
```json
{
  "performance": {
    "maxExecutionMs": 1000,
    "topKResults": 10
  },
  "caching": {
    "maxAgeSeconds": 7200
  },
  "matchers": {
    "tier1": { "enabled": true },
    "tier2": { "enabled": true },
    "tier3": { "enabled": true }
  },
  "scoring": {
    "weights": {
      "keyword": 0.5,
      "tfidf": 1.0,
      "semantic": 3.0
    }
  }
}
```

---

## 🔍 문제 해결

### 설정 파일 검증

```bash
# JSON 유효성 검사
cat config/matcher-config.json | jq . > /dev/null && echo "Valid JSON" || echo "Invalid JSON"

# synonyms.json 검증
cat config/synonyms.json | jq . > /dev/null && echo "Valid JSON" || echo "Invalid JSON"
```

### 설정 백업

```bash
# 백업 생성
cp config/matcher-config.json config/matcher-config.json.backup
cp config/synonyms.json config/synonyms.json.backup

# 복원
cp config/matcher-config.json.backup config/matcher-config.json
```

### 기본 설정으로 복원

```bash
# 원본 다시 다운로드 또는 Git에서 복구
git checkout config/matcher-config.json
git checkout config/synonyms.json
```

---

## 📖 참고 문서

- **[INSTALLATION.md](../INSTALLATION.md)**: 설치 가이드
- **[ARCHITECTURE.md](../ARCHITECTURE.md)**: 시스템 아키텍처
- **[PERFORMANCE.md](../PERFORMANCE.md)**: 성능 최적화

---

**마지막 업데이트**: 2025-11-24
**버전**: v3.0.0
