---
name: web-to-markdown
description: 웹페이지 URL을 입력받아 마크다운 형태로 변환하여 저장합니다. 웹 문서를 로컬 마크다운 파일로 아카이빙하거나 정리할 때 유용합니다.
---

# Web to Markdown Converter

웹페이지의 URL을 입력받아 해당 페이지의 내용을 마크다운 형식으로 변환하여 저장하는 스킬입니다.

## When to Use

다음과 같은 요청이 있을 때 이 스킬을 사용하세요:
- "웹페이지를 마크다운으로 변환해줘"
- "이 URL을 마크다운으로 저장해줘"
- "웹사이트 내용을 마크다운 파일로 만들어줘"
- "웹페이지 아카이빙해줘"
- "블로그 글을 마크다운으로 저장해줘"
- **"AI가 읽기 좋게 변환해줘"** (AI 최적화 모드)
- **"컨텍스트로 사용하기 좋게 변환해줘"** (AI 최적화 모드)
- **"원본이랑 AI 최적화 버전 둘 다 만들어줘"** (듀얼 모드) ⭐ NEW

## Core Workflow

### Step 1: URL 입력받기

사용자에게 변환하고자 하는 웹페이지의 URL을 입력받습니다.

**Example:**
```
Claude: 변환하실 웹페이지의 URL을 입력해주세요.
User: https://example.com/article
```

**Important:**
- URL은 `http://` 또는 `https://`로 시작해야 합니다
- HTTP URL은 자동으로 HTTPS로 업그레이드됩니다
- 유효하지 않은 URL은 에러를 반환합니다

### Step 2: 변환 모드 선택

사용자의 요청을 분석하여 적절한 변환 모드를 선택합니다.

**변환 모드:**
1. **일반 모드** (기본): 웹페이지를 읽기 좋은 마크다운으로 변환
2. **AI 최적화 모드**: AI 에이전트가 컨텍스트로 활용하기 최적화된 형태로 변환
3. **듀얼 모드** ⭐ NEW: 원본 + AI 최적화 버전 2개 파일 생성

**자동 감지 키워드:**
- "AI가 읽기 좋게", "컨텍스트로 사용", "AI 학습용" → AI 최적화 모드
- "원본이랑", "둘 다", "2개", "both", "원본도 저장" → 듀얼 모드
- 기타 → 일반 모드

**Example 1 (AI 최적화):**
```
User: https://example.com/article AI가 읽기 좋게 변환해줘
Claude: AI 최적화 모드로 변환하겠습니다. 구조화된 포맷과 메타데이터를 추가합니다.
```

**Example 2 (듀얼 모드):**
```
User: https://example.com/article 원본이랑 AI 최적화 버전 둘 다 만들어줘
Claude: 듀얼 모드로 변환하겠습니다.
- 원본 마크다운 (article.md)
- AI 최적화 버전 (article.context.md)
2개 파일을 생성합니다.
```

### Step 3: 저장 옵션 확인

사용자에게 저장 위치와 파일명을 확인합니다.

**Example:**
```
Claude: 마크다운 파일을 어디에 저장할까요?
옵션:
1. 현재 디렉토리 (./)
2. 특정 경로 지정
3. 파일로 저장하지 않고 내용만 보기

파일명은? (기본값: webpage.md)
User: 현재 디렉토리에 article.md로 저장해줘
```

### Step 4: 웹페이지 가져오기 및 변환

WebFetch 도구를 사용하여 웹페이지를 가져오고 마크다운으로 변환합니다.

#### 일반 모드 프롬프트

```python
url = "https://example.com/article"
prompt = "웹페이지의 전체 내용을 마크다운 형식으로 변환해주세요. 제목, 본문, 링크, 이미지 등 모든 요소를 포함하되, 불필요한 네비게이션이나 광고는 제외해주세요."
```

#### AI 최적화 모드 프롬프트 (CRITICAL)

```python
url = "https://example.com/article"
prompt = """이 웹페이지를 AI 에이전트가 컨텍스트로 활용하기 최적화된 형태로 변환해주세요:

**필수 구조:**

1. **프론트매터 (YAML 형식)**
---
title: "페이지 제목"
url: "원본 URL"
author: "작성자 (있는 경우)"
date: "발행일 (있는 경우)"
word_count: 대략적인 단어 수
topics: ["주제1", "주제2", "주제3"]
summary: |
  이 글의 핵심을 3-5줄로 요약
  AI가 빠르게 파악할 수 있도록
main_points:
  - 핵심 포인트 1
  - 핵심 포인트 2
  - 핵심 포인트 3
content_type: "tutorial|guide|article|documentation|news|blog"
difficulty: "beginner|intermediate|advanced"
---

2. **본문 구조**
# [원본 제목]

## 핵심 요약
[3-5줄로 이 글이 무엇을 다루는지 명확하게]

## 주요 내용
[명확한 계층 구조로 섹션 구분, H2/H3 사용]

### 섹션 1
[내용]

### 섹션 2
[내용]

## 핵심 인사이트
- 인사이트 1
- 인사이트 2
- 인사이트 3

## 실용적 적용
[이 내용을 어떻게 활용할 수 있는지]

## 관련 리소스
[링크가 있다면 설명과 함께]

## 결론
[마무리 요약]

**변환 규칙:**
- 광고, 네비게이션, 푸터, 사이드바 완전 제거
- 코드 블록은 언어 명시 (```python, ```javascript 등)
- 링크는 [설명](URL) 형식으로 명확하게
- 이미지는 ![설명](URL) 형식으로
- 불필요한 수식어 제거, 간결하게
- 리스트는 명확한 bullet points로
- 중요한 개념은 **굵게** 강조

**최종 목표:**
AI가 이 문서를 읽고 핵심을 3초 안에 파악하고,
사용자의 질문에 정확하게 답변할 수 있도록 최적화
"""
```

**Important:**
- WebFetch는 HTML을 자동으로 마크다운으로 변환합니다
- 15분 캐시가 적용되어 같은 URL을 반복 요청해도 빠릅니다
- 리다이렉트가 발생하면 새로운 URL로 다시 요청합니다
- **AI 최적화 모드는 토큰을 30-50% 절감하고 구조를 명확하게 합니다**

### Step 5: 마크다운 저장

변환된 마크다운을 파일로 저장합니다.

```bash
# Write 도구를 사용하여 파일 저장
Write {
  file_path: "/Users/symverse/workspaces-skill-test/my-skills-hub/article.md"
  content: "[변환된 마크다운 내용]"
}
```

**AI 최적화 모드 파일명 권장:**
- 일반: `article.md`
- AI 최적화: `article-ai-optimized.md` 또는 `article.context.md`

### Step 6: 결과 확인

저장된 파일의 경로와 간단한 통계를 사용자에게 보여줍니다.

```
✅ 웹페이지를 마크다운으로 변환했습니다!

📄 파일: article.md
📍 경로: /Users/symverse/workspaces-skill-test/my-skills-hub/article.md
📊 크기: 약 1,234 글자

[View file](computer:///Users/symverse/workspaces-skill-test/my-skills-hub/article.md)
```

## 듀얼 모드 워크플로우 ⭐ NEW

듀얼 모드는 원본 마크다운과 AI 최적화 버전을 모두 생성합니다. 사람이 읽을 자료와 AI가 처리할 자료를 동시에 확보할 수 있습니다.

### 듀얼 모드 Step 1: URL 및 파일명 확인

```
User: https://react.dev/reference/react/useState 원본이랑 AI 최적화 버전 둘 다 만들어줘

Claude: 듀얼 모드로 변환하겠습니다.
기본 파일명은? (기본: webpage)
```

### 듀얼 모드 Step 2: 원본 마크다운 생성

일반 모드 프롬프트로 WebFetch를 사용하여 원본 마크다운을 생성합니다.

```python
url = "https://react.dev/reference/react/useState"
prompt = "웹페이지의 전체 내용을 마크다운 형식으로 변환해주세요. 제목, 본문, 링크, 이미지 등 모든 요소를 포함하되, 불필요한 네비게이션이나 광고는 제외해주세요."
```

**원본 파일 저장:**
```bash
Write {
  file_path: "/path/to/useState.md"
  content: "[원본 마크다운 내용]"
}
```

### 듀얼 모드 Step 3: AI 최적화 버전 생성

**CRITICAL**: 같은 URL에 대해 AI 최적화 프롬프트로 다시 WebFetch를 호출합니다.

```python
url = "https://react.dev/reference/react/useState"  # 동일한 URL
prompt = """이 웹페이지를 AI 에이전트가 컨텍스트로 활용하기 최적화된 형태로 변환해주세요:

**필수 구조:**

1. **프론트매터 (YAML 형식)**
---
title: "페이지 제목"
url: "원본 URL"
author: "작성자 (있는 경우)"
date: "발행일 (있는 경우)"
word_count: 대략적인 단어 수
topics: ["주제1", "주제2", "주제3"]
summary: |
  이 글의 핵심을 3-5줄로 요약
  AI가 빠르게 파악할 수 있도록
main_points:
  - 핵심 포인트 1
  - 핵심 포인트 2
  - 핵심 포인트 3
content_type: "tutorial|guide|article|documentation|news|blog"
difficulty: "beginner|intermediate|advanced"
---

2. **본문 구조**
# [원본 제목]

## 핵심 요약
[3-5줄로 이 글이 무엇을 다루는지 명확하게]

## 주요 내용
[명확한 계층 구조로 섹션 구분, H2/H3 사용]

### 섹션 1
[내용]

### 섹션 2
[내용]

## 핵심 인사이트
- 인사이트 1
- 인사이트 2
- 인사이트 3

## 실용적 적용
[이 내용을 어떻게 활용할 수 있는지]

## 관련 리소스
[링크가 있다면 설명과 함께]

## 결론
[마무리 요약]

**변환 규칙:**
- 광고, 네비게이션, 푸터, 사이드바 완전 제거
- 코드 블록은 언어 명시 (```python, ```javascript 등)
- 링크는 [설명](URL) 형식으로 명확하게
- 이미지는 ![설명](URL) 형식으로
- 불필요한 수식어 제거, 간결하게
- 리스트는 명확한 bullet points로
- 중요한 개념은 **굵게** 강조

**최종 목표:**
AI가 이 문서를 읽고 핵심을 3초 안에 파악하고,
사용자의 질문에 정확하게 답변할 수 있도록 최적화
"""
```

**AI 최적화 파일 저장:**
```bash
Write {
  file_path: "/path/to/useState.context.md"
  content: "[AI 최적화 마크다운 내용]"
}
```

### 듀얼 모드 Step 4: 결과 요약

2개 파일 생성 결과를 사용자에게 보여줍니다.

```
✅ 듀얼 모드 변환 완료! 2개 파일이 생성되었습니다.

📄 원본 마크다운:
- 파일: useState.md
- 경로: /path/to/useState.md
- 크기: 약 3,500 글자
- 용도: 사람이 읽기 좋은 원본 보존

[View file](computer:///path/to/useState.md)

📄 AI 최적화 버전:
- 파일: useState.context.md
- 경로: /path/to/useState.context.md
- 크기: 약 2,100 글자 (40% 절감)
- 용도: AI 컨텍스트로 활용

[View file](computer:///path/to/useState.context.md)

💡 팁:
- 원본(.md)은 사람이 읽을 때 사용
- AI 최적화(.context.md)는 RAG 시스템이나 AI 에이전트 컨텍스트로 사용
```

### 듀얼 모드 파일명 규칙

**패턴 1: 확장자 구분 (권장)**
- 원본: `article.md`
- AI 최적화: `article.context.md`

**패턴 2: 접미사 구분**
- 원본: `article.md`
- AI 최적화: `article-ai-optimized.md`

**패턴 3: 폴더 구분**
```
/docs
├── original/
│   └── article.md
└── optimized/
    └── article.md
```

### 듀얼 모드 장점

1. **원본 보존**: 사람이 읽을 자료는 원본 그대로 유지
2. **AI 효율성**: AI용은 토큰 절감 및 구조화
3. **용도별 분리**: 목적에 맞는 파일 사용
4. **백업 효과**: 2가지 형태로 동시 백업
5. **비교 가능**: 원본과 최적화 버전 비교 분석 가능

### 듀얼 모드 사용 시나리오

**시나리오 1: 기술 문서 아카이빙**
```
User: 이 React 문서들 원본이랑 AI 최적화 버전 둘 다 만들어줘
- https://react.dev/reference/react/useState
- https://react.dev/reference/react/useEffect

Claude: 듀얼 모드로 4개 파일 생성합니다.
- useState.md (원본)
- useState.context.md (AI 최적화)
- useEffect.md (원본)
- useEffect.context.md (AI 최적화)
```

**시나리오 2: 블로그 글 백업**
```
User: 내 블로그 글을 백업하는데 원본도 저장하고 AI가 읽을 수 있는 버전도 만들어줘

Claude: 듀얼 모드로 변환하겠습니다.
- 원본: 사람이 다시 읽을 때
- AI 최적화: 나중에 AI에게 질문할 때
```

**시나리오 3: 학습 자료 구축**
```
User: 이 튜토리얼들을 둘 다 버전으로 저장해줘

Claude:
study-materials/
├── original/          # 사람이 학습용
│   ├── intro.md
│   └── advanced.md
└── ai-optimized/      # AI 질문 답변용
    ├── intro.context.md
    └── advanced.context.md
```

## Advanced Options

### 여러 URL 일괄 변환

여러 웹페이지를 한 번에 변환할 수 있습니다.

**Example:**
```
User: 이 URL들을 전부 마크다운으로 저장해줘
- https://example.com/article1
- https://example.com/article2
- https://example.com/article3

Claude: 3개의 웹페이지를 변환하겠습니다. 파일명은 자동으로 생성할까요, 아니면 각각 지정하시겠어요?
User: 자동으로

Claude: [각 URL을 순차적으로 변환하여 article1.md, article2.md, article3.md로 저장]
```

### 특정 섹션만 추출

웹페이지의 특정 부분만 추출할 수 있습니다.

**Example:**
```
User: https://example.com/docs 에서 "Installation" 섹션만 마크다운으로 저장해줘

Claude: [WebFetch 프롬프트에 "Installation 섹션만 추출"을 명시하여 해당 부분만 변환]
```

### 마크다운 포맷 커스터마이징

변환 시 원하는 마크다운 스타일을 지정할 수 있습니다.

**Example:**
```
User: 이 블로그 글을 마크다운으로 변환하되, 모든 제목을 H2(##)로 시작하고 코드 블록은 syntax highlighting 포함해줘

Claude: [WebFetch 프롬프트에 포맷 요구사항을 명시]
```

## Error Handling

### 잘못된 URL

```
User: htp://wrong-url
Claude: ❌ 올바르지 않은 URL입니다. http:// 또는 https://로 시작하는 전체 URL을 입력해주세요.
```

### 접근 불가능한 페이지

```
Claude: ❌ 해당 웹페이지에 접근할 수 없습니다.
- 페이지가 삭제되었거나
- 접근 권한이 필요하거나
- 네트워크 오류가 발생했을 수 있습니다.
```

### 파일 저장 오류

```
Claude: ❌ 파일을 저장할 수 없습니다.
- 경로가 올바른지 확인해주세요
- 쓰기 권한이 있는지 확인해주세요
- 디렉토리가 존재하는지 확인해주세요
```

## Example Workflows

### Example 1: 단일 웹페이지 변환

```
User: https://docs.python.org/3/tutorial/index.html 이거 마크다운으로 저장해줘

Claude: 파이썬 튜토리얼 페이지를 마크다운으로 변환하겠습니다.
파일명을 어떻게 할까요? (기본: webpage.md)

User: python-tutorial.md

Claude: [WebFetch로 페이지 가져오기]
Claude: [마크다운으로 변환]
Claude: [파일 저장]

✅ 웹페이지를 마크다운으로 변환했습니다!

📄 파일: python-tutorial.md
📍 경로: /Users/symverse/workspaces-skill-test/my-skills-hub/python-tutorial.md
📊 크기: 약 15,234 글자

[View file](computer:///Users/symverse/workspaces-skill-test/my-skills-hub/python-tutorial.md)
```

### Example 2: 블로그 글 아카이빙

```
User: 이 블로그 글들을 전부 마크다운으로 저장해서 아카이브 폴더에 넣어줘
- https://blog.example.com/post1
- https://blog.example.com/post2

Claude: 2개의 블로그 글을 archive 폴더에 저장하겠습니다.

[디렉토리 생성]
[각 URL을 순차적으로 변환]

✅ 2개의 웹페이지를 변환했습니다!

📁 archive/
  ├── post1.md
  └── post2.md
```

### Example 3: 문서 내용만 보기 (저장 안 함)

```
User: https://github.com/anthropics/claude-code 이 페이지 내용을 마크다운으로 보여줘만 하고 저장은 하지마

Claude: [WebFetch로 페이지 가져오기]

다음은 해당 페이지의 마크다운 변환 내용입니다:

---
# Claude Code

Claude Code is an official CLI...

[전체 내용 출력]
---

저장하지 않고 내용만 보여드렸습니다.
```

## Technical Details

### WebFetch 사용

- **자동 변환**: HTML → 마크다운 자동 변환
- **캐싱**: 15분 자가 정리 캐시
- **리다이렉트 처리**: 자동으로 새 URL로 재요청

### 마크다운 변환 품질

WebFetch는 다음 요소를 마크다운으로 변환합니다:
- 제목 (H1-H6)
- 단락과 텍스트 포맷 (bold, italic, code)
- 링크와 이미지
- 리스트 (ordered, unordered)
- 코드 블록
- 인용구
- 테이블

불필요한 요소는 제외됩니다:
- 네비게이션 메뉴
- 푸터
- 광고
- 사이드바 (상황에 따라)

### 파일 저장

- **기본 경로**: 현재 작업 디렉토리
- **파일 확장자**: `.md`
- **인코딩**: UTF-8
- **덮어쓰기**: 기존 파일이 있으면 확인 후 덮어씀

## Best Practices

1. **명확한 파일명 사용**: 내용을 잘 나타내는 파일명 사용
2. **폴더 구조화**: 여러 페이지를 변환할 때는 주제별로 폴더 정리
3. **URL 확인**: 변환 전 URL이 올바른지 확인
4. **저작권 주의**: 웹페이지 내용의 저작권을 존중
5. **개인적 아카이빙**: 주로 개인적인 참고 자료로 사용

## Tips

- **긴 문서**: 매우 긴 웹페이지는 요약이 포함될 수 있습니다
- **동적 콘텐츠**: JavaScript로 렌더링되는 콘텐츠는 포함되지 않을 수 있습니다
- **이미지**: 이미지는 원본 URL 링크로 포함됩니다 (다운로드되지 않음)
- **재변환**: 같은 URL을 15분 내에 다시 요청하면 캐시된 버전을 사용합니다
