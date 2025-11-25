# CC-Skills Matchers

다층 스킬 매칭 시스템

## 의존성 설치

### Node.js (TF-IDF)
```bash
cd matchers
npm install
```

### Python (Semantic Matching)
```bash
cd matchers
pip3 install -r requirements.txt
```

## 사용법

### TF-IDF Matcher
```bash
echo '{"prompt": "버그 수정", "candidates": [...]}' | node tfidf-matcher.js
```

### Semantic Matcher
```bash
echo '{"prompt": "버그 수정", "candidates": [...]}' | python3 semantic-matcher.py
```

## 성능

- TF-IDF: ~50-100ms
- Semantic: ~200-350ms (초기 로딩 포함)
