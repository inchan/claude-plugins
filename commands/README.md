# Commands (커맨드)

> 슬래시(/) 명령으로 호출되는 사용자 정의 동작

---

## 디렉토리 구조

```
commands/
└── {command-name}.md   # 커맨드 정의
```

---

## 커맨드 생성 가이드

### 1. 커맨드 파일 생성

```bash
touch commands/{command-name}.md
```

### 2. 커맨드 정의 작성

**기본 구조**:
```markdown
# /{command-name}

## Description
커맨드 설명

## Usage
/{command-name} [arguments]

## Arguments
- `arg1`: 첫 번째 인자 설명
- `arg2`: 두 번째 인자 설명 (선택)

## Examples
### Example 1
```
/{command-name} arg1 arg2
```
설명...

## Implementation
커맨드 실행 시 수행할 작업:
1. 단계 1
2. 단계 2
3. ...

## Output
예상 출력 형식

## Notes
- 주의사항
- 제한사항
```

### 3. 커맨드 등록

커맨드는 `.claude/commands/` 또는 프로젝트 루트 `commands/`에 배치하면 자동 인식됩니다.

---

## 커맨드 명명 규칙

- **소문자 사용**: `/mycommand` (O), `/MyCommand` (X)
- **하이픈 구분**: `/my-command` (O), `/my_command` (X)
- **동사로 시작**: `/create-skill`, `/analyze-code`
- **간결성**: 3단어 이내 권장

---

## 커맨드 유형

| 유형 | 설명 | 예시 |
|------|------|------|
| **생성** | 새로운 것 생성 | `/create-skill`, `/init-project` |
| **분석** | 코드/데이터 분석 | `/analyze-performance`, `/review-code` |
| **변환** | 형식 변환 | `/convert-json`, `/format-code` |
| **실행** | 작업 실행 | `/run-tests`, `/deploy` |
| **정보** | 정보 조회 | `/show-config`, `/list-skills` |

---

## 체크리스트

커맨드 개발 전 확인:
- [ ] 커맨드 이름 규칙 준수 (소문자, 하이픈)
- [ ] 사용 예시 3개 이상 포함
- [ ] 파라미터 문서화
- [ ] 에러 케이스 처리
- [ ] 테스트 작성

---

## 예제: `/create-skill`

```markdown
# /create-skill

## Description
새로운 스킬을 생성합니다.

## Usage
/create-skill <skill-name> [--type <type>]

## Arguments
- `skill-name`: 생성할 스킬 이름 (필수)
- `--type`: 스킬 유형 (선택, 기본값: basic)
  - basic: 기본 스킬
  - advanced: 고급 스킬

## Examples
### Example 1: 기본 스킬 생성
```
/create-skill my-skill
```

### Example 2: 고급 스킬 생성
```
/create-skill my-skill --type advanced
```

## Implementation
1. `skills/{skill-name}` 디렉토리 생성
2. `SKILL.md` 템플릿 복사
3. `resources/`, `scripts/` 디렉토리 생성
4. 테스트 파일 생성
5. `rules/skill-rules.json` 업데이트

## Output
```
✓ Created skills/my-skill/
✓ Created skills/my-skill/SKILL.md
✓ Created skills/my-skill/resources/
✓ Created skills/my-skill/scripts/
✓ Created tests/skills/my-skill.test.js

Skill 'my-skill' created successfully!
```
```

---

## 참고 자료

- [Tool Creation Guide](../docs/guidelines/tool-creation.md)
- [Commands 공식 문서](https://docs.anthropic.com/claude-code/commands)

---

## 변경 이력

- **2025-11-28**: commands 디렉토리 생성
