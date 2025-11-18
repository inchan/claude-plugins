---
name: prompt-enhancer
description: Enhance user prompts by analyzing project context (code structure, dependencies, conventions, existing patterns). Use when users provide brief development requests that would benefit from project-specific context to generate more accurate, contextually-aware prompts.
---

# Prompt Enhancer

Transform brief development requests into clear, detailed requirements by analyzing project context. Present the enhanced requirements to the user for confirmation before implementation.

## When to Use This Skill

Use this skill when:
- User provides a brief development request like "로그인 기능 만들어줘", "API 추가해줘"
- Request lacks specific implementation details
- User uploads project files or mentions "the project"
- Task requires understanding project architecture

---

## GOLDEN Framework

모든 향상된 요구사항은 GOLDEN 프레임워크를 따릅니다:

| 요소 | 설명 | 예시 |
|------|------|------|
| **G**oal | 정량적 성공 기준 정의 | 로그인 성공률 99.9%, 응답 시간 < 500ms |
| **O**utput | 출력 형식 및 품질 기준 | TypeScript 타입 안정성, API 문서화 수준 |
| **L**imits | 토큰 예산, API 비용, 실행 시간 제약 | 최대 토큰 4000, API 호출 < 3회 |
| **D**ata | 프로젝트에서 자동 추출한 맥락 데이터 | 기존 패턴, 의존성, 코드 규칙 |
| **E**valuation | 자동 평가 기준 및 루브릭 | 테스트 커버리지 > 80%, 린트 통과 |
| **N**ext | 반복 개선 계획 및 대안 전략 | 실패 시 대체 접근 방식 |

---

## Core Workflow

### Step 1: Analyze Project Context & Complexity

**프로젝트 컨텍스트 수집:**
```bash
view /mnt/user-data/uploads
```

**복잡도 분석 기준:**

| 복잡도 | 조건 | 템플릿 |
|--------|------|--------|
| **단순 (Simple)** | CRUD 작업, 단일 파일, 기존 패턴 재사용 | 최소 컨텍스트 템플릿 |
| **중간 (Medium)** | 여러 파일, 외부 API 통합, 새 컴포넌트 | 표준 컨텍스트 템플릿 |
| **복잡 (Complex)** | 아키텍처 변경, 다중 시스템 통합, 보안 관련 | 확장 컨텍스트 템플릿 |

**수집할 핵심 정보:**
- Project structure and organization
- Technology stack (package.json, pubspec.yaml, requirements.txt, etc.)
- Existing patterns (state management, API calls, routing)
- Code conventions (naming, file structure)
- Similar existing features
- 기술 부채 수준 및 팀 숙련도 (가능한 경우)

### Step 2: Extract Request Intent & Risk Assessment

From the user's brief request, identify:
- **Feature type**: New feature, bug fix, refactoring, API integration
- **Scope**: Single screen, full flow, backend + frontend
- **Dependencies**: Related features or systems

**위험도 평가:**

| 위험도 | 조건 | 주의사항 |
|--------|------|----------|
| **높음 (High)** | 핵심 모듈 수정, 비즈니스 로직 변경, 인증/보안 관련 | 철저한 테스트 필수, 롤백 계획 수립 |
| **중간 (Medium)** | 기존 기능 수정, 새 의존성 추가, DB 스키마 변경 | 영향 범위 분석, 마이그레이션 계획 |
| **낮음 (Low)** | 새 기능 추가, 기존 코드 미영향, UI 변경 | 기본 테스트로 충분 |

### Step 3: Build Enhanced Requirements (Modular Layers)

모듈식 3레이어 구조로 요구사항을 구성합니다:

```markdown
# [기능명] 구현 요구사항

---

## Layer 1: 컨텍스트 레이어 (Context Layer)

### 📋 프로젝트 컨텍스트
- **Framework**: [detected framework and version]
- **Architecture**: [detected pattern]
- **State Management**: [detected library]
- **Key Libraries**: [list relevant dependencies]

### 🔍 기존 패턴 및 관례
- **코드 스타일**: [naming convention, file structure]
- **유사 기능 참조**: [existing similar features]
- **기술 제약사항**: [limitations, deprecated APIs]

### ⚠️ 위험도 및 영향 분석
- **위험도**: [높음/중간/낮음]
- **영향 범위**: [affected modules/services]
- **의존성**: [dependencies and integrations]

---

## Layer 2: 인스트럭션 레이어 (Instruction Layer)

### 🎯 구현 범위

#### 주요 기능
1. [Main feature 1]
2. [Main feature 2]
3. [Main feature 3]

#### 파일 구조
```
[Expected file structure based on project]
```

### 📝 상세 요구사항

#### 1. [Layer/Component Name]
- **위치**: [File path]
- **목적**: [What it does]
- **구현 내용**:
  - [Specific requirement 1]
  - [Specific requirement 2]
- **기존 패턴 따르기**: [Reference to existing pattern]
- **예외 처리**: [Error handling requirements]

#### 2. [Next Layer/Component]
...

---

## Layer 3: 검증 레이어 (Validation Layer)

### 📊 GOLDEN 평가 기준

| 요소 | 정의 | 측정 방법 |
|------|------|-----------|
| **Goal** | [정량적 성공 기준] | [how to measure] |
| **Output** | [출력 형식/품질 기준] | [validation method] |
| **Limits** | [제약 조건] | [constraint checks] |
| **Evaluation** | [평가 루브릭] | [testing approach] |
| **Next** | [실패 시 대안] | [fallback strategy] |

### ✅ 성공 기준 체크리스트

#### 기능 검증
- [ ] [Functional requirement 1]
- [ ] [Functional requirement 2]
- [ ] 모든 엣지 케이스 처리

#### 품질 검증
- [ ] 기존 코드 스타일 및 아키텍처 일관성 유지
- [ ] 테스트 커버리지 [X]% 이상
- [ ] 린트/포맷팅 통과
- [ ] 보안 취약점 없음

#### 성능 검증
- [ ] 응답 시간 < [X]ms
- [ ] 메모리 사용량 적정
- [ ] DB 쿼리 최적화

### 🔄 다중 메트릭 평가

| 메트릭 | 목표값 | 우선순위 |
|--------|--------|----------|
| **정확도 (Accuracy)** | 요구사항 충족도 > 95% | High |
| **효율성 (Efficiency)** | 최소 API 호출, 최적 쿼리 | Medium |
| **명확성 (Clarity)** | 코드 가독성, 문서화 수준 | Medium |
| **호환성 (Compatibility)** | 기존 시스템과 충돌 없음 | High |

### 🔍 확인 사항
- [Any questions or clarifications needed]
- [Assumptions made]

---
이 요구사항으로 진행할까요? 수정이 필요한 부분이 있다면 말씀해주세요.
```

### Step 4: Present to User

**Important**: After creating the enhanced requirements, present them to the user and ask for confirmation:

```
위 요구사항을 분석해서 정리했습니다. 

이대로 진행해도 될까요? 
수정하거나 추가할 내용이 있으면 말씀해주세요!
```

**Do NOT implement** until the user confirms. The goal is to clarify requirements first.

---

## Complexity-Based Templates

### Simple Template (단순 작업)

CRUD 작업, 단일 파일 수정, 기존 패턴 재사용에 적합합니다.

```markdown
# [기능명] 구현 요구사항

## 📋 컨텍스트
- **Framework**: [framework]
- **참조 패턴**: [existing similar code]

## 📝 요구사항
- **위치**: [file path]
- **구현**: [specific requirements]
- **기존 패턴**: [pattern to follow]

## ✅ 성공 기준
- [ ] [main criterion]
- [ ] 기존 스타일 일관성
- [ ] 기본 테스트

---
진행할까요?
```

### Standard Template (표준 작업)

여러 파일, 외부 API 통합, 새 컴포넌트에 적합합니다.

```markdown
# [기능명] 구현 요구사항

## Layer 1: 컨텍스트
- **Framework**: [framework and version]
- **Architecture**: [pattern]
- **Dependencies**: [key libraries]
- **위험도**: 중간

## Layer 2: 인스트럭션
### 구현 범위
1. [Component 1]
2. [Component 2]

### 상세 요구사항
[Detailed specifications per component]

## Layer 3: 검증
### GOLDEN 기준
- **Goal**: [quantitative success criteria]
- **Limits**: [constraints]

### 성공 기준
- [ ] 기능 요구사항
- [ ] 품질 (테스트, 린트)
- [ ] 성능

---
진행할까요?
```

### Extended Template (복잡 작업)

아키텍처 변경, 다중 시스템 통합, 보안 관련 작업에 적합합니다.
**위 전체 템플릿**을 사용합니다 (Layer 1-3 완전 구성).

---

## Analysis Patterns by Stack

### Flutter Projects

**Detect**: pubspec.yaml, lib/ directory

**Key context to gather:**
- State management (Riverpod, Bloc, Provider, GetX)
- Architecture (Clean Architecture, MVVM, MVC)
- Navigation (go_router, auto_route, Navigator)
- Network (Dio, http)
- Local storage (Hive, SharedPreferences, SQLite)

**Enhanced requirements should include:**
```markdown
## 구현 범위

### Presentation Layer
- 화면: lib/presentation/[feature]/[screen]_screen.dart
- 상태: [StateNotifier/Bloc/Controller] with [state pattern]
- 위젯: 재사용 가능한 컴포넌트

### Domain Layer
- Entity: lib/domain/entities/[name].dart
- UseCase: lib/domain/usecases/[action]_usecase.dart
- Repository Interface: lib/domain/repositories/

### Data Layer
- Model: lib/data/models/[name]_model.dart (fromJson/toJson)
- Repository Implementation: lib/data/repositories/
- DataSource: lib/data/datasources/

### Navigation
- Route: [route path]
- Navigation method: [context.go/push based on router]

## 성공 기준
✅ [State management]로 상태 관리
✅ [Existing widget] 스타일 일관성 유지
✅ API 응답 에러 처리
✅ 로딩 상태 표시
✅ Widget test 작성
```

### Next.js/React Projects

**Detect**: package.json with "next" or "react"

**Key context to gather:**
- Next.js version (App Router vs Pages Router)
- State management (Zustand, Redux, Context)
- Styling (Tailwind, CSS Modules, styled-components)
- API approach (Next.js API routes, external API)
- TypeScript usage

**Enhanced requirements should include:**
```markdown
## 구현 범위

### UI Components
- 컴포넌트: [path]/[ComponentName].tsx
- Props interface: [existing pattern]
- Styling: [Tailwind classes/CSS modules]

### State Management
- Store: [existing state structure]
- Actions: [action naming convention]

### API Layer
- Endpoint: [app/api or external]
- Method: [GET/POST/PUT/DELETE]
- Response type: [TypeScript interface]

### Routing
- Route: [app/[route] or pages/[route]]
- Dynamic segments: [if needed]

## 성공 기준
✅ TypeScript 타입 안정성
✅ [Existing components] 재사용
✅ 반응형 디자인 (모바일/데스크톱)
✅ SEO 최적화 (메타데이터)
✅ Unit test + Integration test
```

### Python (Django/FastAPI) Projects

**Detect**: requirements.txt, manage.py, main.py

**Key context to gather:**
- Framework (Django, FastAPI, Flask)
- ORM (SQLAlchemy, Django ORM, Tortoise)
- Authentication approach
- API documentation (OpenAPI/Swagger)

**Enhanced requirements should include:**
```markdown
## 구현 범위

### Models/Schema
- Model: [app]/models.py or schemas/[name].py
- Fields: [field definitions with types]
- Relationships: [ForeignKey/relationships]

### Views/Endpoints
- Route: [path]
- Method: [HTTP method]
- Request/Response schema: [Pydantic models]

### Business Logic
- Service: [if applicable]
- Validation: [input validation]

### Database
- Migration: [migration command]

## 성공 기준
✅ API documentation 자동 생성
✅ Request validation
✅ Error handling with proper status codes
✅ Unit test + Integration test
✅ [Authentication] 적용
```

## Example Enhancement

### Example 1: Complex Task (Extended Template)

**User input:**
```
로그인 기능 구현해줘
```

**Skill output:**
```markdown
# 로그인 기능 구현 요구사항

---

## Layer 1: 컨텍스트 레이어 (Context Layer)

### 📋 프로젝트 컨텍스트
- **Framework**: Flutter 3.16.0 with null safety
- **Architecture**: Clean Architecture
- **State Management**: Riverpod (StateNotifier pattern)
- **Key Libraries**: Dio 5.3.0, flutter_secure_storage, go_router

### 🔍 기존 패턴 및 관례
- **코드 스타일**: camelCase, feature-based directory structure
- **유사 기능 참조**: 회원가입 화면 (lib/presentation/auth/signup/)
- **기술 제약사항**: 최소 Flutter 3.10+ 필요

### ⚠️ 위험도 및 영향 분석
- **위험도**: 높음 (인증/보안 관련)
- **영향 범위**: 전체 앱 인증 상태, 토큰 관리
- **의존성**: TokenStorage, UserRepository, Navigation Guard

---

## Layer 2: 인스트럭션 레이어 (Instruction Layer)

### 🎯 구현 범위

#### 주요 기능
1. 이메일/비밀번호 로그인 폼
2. JWT 토큰 기반 인증
3. 로그인 성공 시 홈 화면 이동
4. 에러 처리 및 사용자 피드백

#### 파일 구조
```
lib/
├── presentation/
│   └── auth/
│       ├── login_screen.dart
│       ├── login_notifier.dart
│       └── login_state.dart
├── domain/
│   ├── entities/user.dart
│   ├── usecases/login_usecase.dart
│   └── repositories/auth_repository.dart
└── data/
    ├── models/
    │   ├── user_model.dart
    │   └── login_response.dart
    ├── repositories/auth_repository_impl.dart
    └── datasources/auth_remote_datasource.dart
```

## 📝 상세 요구사항

### 1. Presentation Layer - 로그인 화면
- **위치**: lib/presentation/auth/login_screen.dart
- **목적**: 사용자 로그인 UI 제공
- **구현 내용**:
  - ConsumerStatefulWidget 사용
  - Email TextFormField (이메일 형식 검증)
  - Password TextFormField (8자 이상, obscureText)
  - 로그인 PrimaryButton
  - 회원가입 링크
  - 로딩 상태 시 오버레이 표시
- **기존 패턴 따르기**: core/widgets/custom_text_field.dart 스타일 사용

### 2. State Management
- **위치**: lib/presentation/auth/login_notifier.dart
- **목적**: 로그인 상태 관리
- **구현 내용**:
  - StateNotifier<LoginState> 상속
  - login(email, password) 메서드
  - 성공 시 토큰 저장 후 상태 업데이트
  - 에러 시 에러 메시지 상태 설정
- **기존 패턴 따르기**: 다른 notifier들과 동일한 패턴

### 3. Domain Layer - 엔티티
- **위치**: lib/domain/entities/user.dart
- **목적**: 사용자 도메인 모델
- **구현 내용**:
  - Freezed로 불변 클래스 생성
  - id, email, name, profileImageUrl 필드
- **기존 패턴 따르기**: 다른 entity들과 동일한 구조

### 4. Domain Layer - UseCase
- **위치**: lib/domain/usecases/login_usecase.dart
- **목적**: 로그인 비즈니스 로직
- **구현 내용**:
  - call(LoginParams) 메서드
  - Either<Failure, User> 반환
  - repository 의존성 주입
- **기존 패턴 따르기**: 단일 책임 UseCase 패턴

### 5. Data Layer - API 통신
- **위치**: lib/data/datasources/auth_remote_datasource.dart
- **목적**: 로그인 API 호출
- **구현 내용**:
  - POST /api/auth/login
  - Request: {"email": string, "password": string}
  - Response: LoginResponse (accessToken, refreshToken, user)
  - Dio instance 재사용
- **기존 패턴 따르기**: 기존 datasource들의 에러 처리 방식

### 6. Data Layer - Repository 구현
- **위치**: lib/data/repositories/auth_repository_impl.dart
- **목적**: Repository 인터페이스 구현
- **구현 내용**:
  - login 메서드 구현
  - 토큰 저장 (TokenStorage 사용)
  - DioException 처리
  - UserModel을 User entity로 변환
- **기존 패턴 따르기**: try-catch-Either 패턴

### 7. Navigation 설정
- **위치**: lib/core/router/app_router.dart
- **목적**: 로그인 라우트 추가
- **구현 내용**:
  - /login 라우트 추가
  - 로그인 성공 시 /home으로 리다이렉트
  - 인증 가드 로직
- **기존 패턴 따르기**: 기존 go_router 설정 방식

---

## Layer 3: 검증 레이어 (Validation Layer)

### 📊 GOLDEN 평가 기준

| 요소 | 정의 | 측정 방법 |
|------|------|-----------|
| **Goal** | 로그인 성공률 99.9%, 응답 시간 < 2s | 테스트 통과율, API 응답 시간 측정 |
| **Output** | JWT 토큰 저장, 사용자 정보 반환 | 토큰 유효성 검증, 타입 안정성 |
| **Limits** | API 호출 1회, 토큰 저장 1회 | 네트워크 요청 수 확인 |
| **Evaluation** | 테스트 커버리지 > 80% | Widget/Unit/Repository 테스트 |
| **Next** | 실패 시 에러 메시지 표시, 재시도 옵션 | 에러 핸들링 동작 확인 |

### ✅ 성공 기준 체크리스트

#### 기능 검증
- [ ] 사용자가 이메일과 비밀번호 입력
- [ ] 로그인 버튼 클릭 시 API 호출
- [ ] 성공 시 토큰 저장 및 홈 화면 이동
- [ ] 실패 시 적절한 에러 메시지 표시 (SnackBar)
- [ ] 로딩 중 버튼 비활성화 및 로딩 인디케이터
- [ ] 이메일 형식 및 비밀번호 길이 검증

#### 품질 검증
- [ ] 기존 코드 스타일 및 아키텍처 일관성 유지
- [ ] 테스트 커버리지 80% 이상
- [ ] 린트/포맷팅 통과
- [ ] 보안 취약점 없음 (토큰 안전 저장)

#### 성능 검증
- [ ] API 응답 시간 < 2s
- [ ] 앱 메모리 영향 최소화

### 🔄 다중 메트릭 평가

| 메트릭 | 목표값 | 우선순위 |
|--------|--------|----------|
| **정확도** | 인증 성공 시 정확한 토큰 저장 | High |
| **효율성** | 단일 API 호출로 완료 | Medium |
| **명확성** | 에러 메시지 사용자 친화적 | High |
| **호환성** | 기존 TokenStorage와 완전 호환 | High |

#### 테스트 목록
- [ ] Widget test 작성 (로그인 화면)
- [ ] Repository test 작성 (mock API)
- [ ] UseCase test 작성

### 🔍 확인 사항
- API 엔드포인트 주소가 `https://api.example.com`이 맞나요?
- 토큰 만료 시 자동 갱신 기능이 필요한가요?
- 소셜 로그인(구글, 애플 등)도 함께 구현할까요?
- "비밀번호 찾기" 기능이 필요한가요?

---
위 요구사항으로 진행할까요? 수정이 필요한 부분이 있다면 말씀해주세요!
```

### Example 2: Simple Task (Simple Template)

**User input:**
```
버튼 색상 변경해줘
```

**Skill output:**
```markdown
# 버튼 색상 변경 구현 요구사항

## 📋 컨텍스트
- **Framework**: Flutter 3.16.0
- **참조 패턴**: lib/core/theme/app_theme.dart

## 📝 요구사항
- **위치**: lib/core/theme/app_theme.dart
- **구현**: primaryColor를 #4A90E2로 변경
- **기존 패턴**: ThemeData.colorScheme 사용

## ✅ 성공 기준
- [ ] 모든 PrimaryButton에 새 색상 적용
- [ ] 기존 UI 일관성 유지
- [ ] 접근성 대비 비율 확인

---
진행할까요?
```

## Tips for Effective Enhancement

### Always Ask for Clarification

If the project context is unclear or insufficient:
```
프로젝트 파일을 업로드해주시면 더 정확한 요구사항을 만들 수 있습니다.
또는 다음 정보를 알려주세요:
- 사용 중인 프레임워크
- 상태 관리 라이브러리
- 기존 프로젝트 구조
```

### Include Visual Examples

When helpful, mention existing screens/components:
```
기존 ProfileScreen과 유사한 레이아웃으로 구현
- AppBar 스타일 동일
- TextFormField 디자인 재사용
- PrimaryButton 컴포넌트 사용
```

### Highlight Dependencies

```
## 🔗 연관 기능
- UserRepository: 사용자 정보 조회에 재사용
- TokenStorage: 기존 토큰 저장 로직 활용
- ErrorHandler: 공통 에러 처리 적용
```

## Reference Files

For detailed patterns:
- **Enhancement patterns**: references/enhancement-patterns.md
- **Framework guides**: references/framework-guides.md
