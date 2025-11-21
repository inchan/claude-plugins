# Cross-Plugin Skill Calls

Multi-plugin 아키텍처에서 플러그인 간 스킬 호출 가이드

## 네임스페이스 형식

v2.0.0부터 모든 스킬은 플러그인 네임스페이스를 사용합니다:

```
plugin-name:skill-name
```

### 예시

```javascript
// ✓ 올바른 형식
Skill("workflow-automation:intelligent-task-router")
Skill("dev-guidelines:frontend-dev-guidelines")
Skill("quality-review:iterative-quality-enhancer")

// ✗ 잘못된 형식 (v1.x 레거시)
Skill("intelligent-task-router")  // 플러그인 지정 없음
```

## Hook 자동 제안

`hooks/skill-activation-hook.sh`가 UserPromptSubmit 시 모든 플러그인의 스킬을 분석하여 제안합니다:

```
INSTRUCTION: MULTI-PLUGIN SKILL ACTIVATION

Available Skills by Plugin:

📦 Plugin: workflow-automation
  - intelligent-task-router [priority: high]
  - parallel-task-executor [priority: medium]
  ...

📦 Plugin: dev-guidelines
  - frontend-dev-guidelines [priority: high]
  - backend-dev-guidelines [priority: high]
  ...

Step 1 - EVALUATE:
For each skill above, state: [plugin:skill-name] - YES/NO - [reason]

Step 2 - ACTIVATE:
Use Skill("plugin-name:skill-name") for each YES skill
Example: Skill("workflow-automation:intelligent-task-router")

Step 3 - IMPLEMENT:
Proceed with implementation after activation
```

## 플러그인 간 독립성 원칙

### ✅ 권장: Zero Dependencies

각 플러그인은 다른 플러그인에 의존하지 않아야 합니다:

```markdown
<!-- ✓ 플러그인 내부 참조 -->
이 작업 후 `iterative-quality-enhancer`로 품질 검증하세요.
(같은 quality-review 플러그인 내부)

<!-- ✗ 외부 플러그인 의존 -->
이 작업 후 반드시 Skill("quality-review:iterative-quality-enhancer")를 호출하세요.
(다른 플러그인 강제 의존)
```

### ✅ 권장: 선택적 제안

다른 플러그인 스킬이 유용할 경우, 강제가 아닌 제안으로:

```markdown
<!-- ✓ 선택적 제안 -->
**선택사항**: 품질 검증이 필요하다면 `quality-review:iterative-quality-enhancer` 스킬을 고려하세요.

<!-- ✗ 강제 호출 -->
다음 단계로 반드시 Skill("quality-review:iterative-quality-enhancer")를 실행하세요.
```

## 실제 사용 패턴

### 1. 워크플로우 자동화

`workflow-automation` 플러그인은 다른 플러그인 스킬을 오케스트레이션할 수 있습니다:

```markdown
# intelligent-task-router/SKILL.md

## 작업 완료 후 권장사항

복잡도 분석 후 다음 스킬 고려:
- 프론트엔드 작업 → `dev-guidelines:frontend-dev-guidelines`
- 백엔드 작업 → `dev-guidelines:backend-dev-guidelines`
- 품질 검증 → `quality-review:iterative-quality-enhancer`

**주의**: 이는 제안이며 자동 호출하지 않습니다.
```

### 2. 품질 리뷰 통합

`quality-review` 플러그인은 독립적으로 작동하지만, 다른 플러그인이 참조할 수 있습니다:

```markdown
# 다른 플러그인의 스킬에서

## 완료 체크리스트

- [ ] 기능 구현 완료
- [ ] 테스트 작성
- [ ] (선택) Skill("quality-review:iterative-quality-enhancer") 실행
```

### 3. 개발 가이드라인 참조

`dev-guidelines` 플러그인은 다른 스킬에서 가이드로 참조:

```markdown
# 다른 플러그인의 SKILL.md

## 구현 시 고려사항

프론트엔드 개발 시 `dev-guidelines:frontend-dev-guidelines` 스킬 확인 권장:
- MUI v7 Grid2 사용
- Suspense 패턴
- TanStack Router 라우팅
```

## Hook 집계 메커니즘

### skill-activation-hook.sh 동작

1. **플러그인 스캔**
   ```bash
   for plugin_dir in "${REPO_ROOT}/plugins/"*/; do
       if [[ -f "${plugin_dir}skills/skill-rules.json" ]]; then
           SKILL_RULES_FILES+=("${plugin_dir}skills/skill-rules.json")
       fi
   done
   ```

2. **스킬 집계**
   ```bash
   node -e "
   const rules = JSON.parse(fs.readFileSync('${rules_file}'));
   Object.entries(rules.skills).forEach(([name, config]) => {
       const priority = config.priority || 'medium';
       const keywords = (config.promptTriggers?.keywords || []).join(',');
       console.log(\`\${priority}|\${plugin_name}|\${name}|\${keywords}\`);
   });
   "
   ```

3. **출력 형식**
   ```
   priority|plugin|skill-name|keywords
   high|workflow-automation|intelligent-task-router|workflow,task,routing
   high|dev-guidelines|frontend-dev-guidelines|react,frontend,mui
   ```

## 마이그레이션 가이드 (v1.x → v2.0.0)

### v1.x (단일 플러그인)
```javascript
Skill("intelligent-task-router")
Skill("frontend-dev-guidelines")
```

### v2.0.0 (멀티 플러그인)
```javascript
Skill("workflow-automation:intelligent-task-router")
Skill("dev-guidelines:frontend-dev-guidelines")
```

### 자동 변환

Hook이 자동으로 플러그인 이름을 포함하여 제안하므로, Claude Code가 올바른 형식을 사용합니다.

## 베스트 프랙티스

### ✅ DO

1. **네임스페이스 사용**
   ```javascript
   Skill("plugin-name:skill-name")
   ```

2. **선택적 제안**
   ```markdown
   **권장**: 다음 스킬 고려
   - `quality-review:iterative-quality-enhancer`
   ```

3. **플러그인 독립성 유지**
   - 각 플러그인은 독립적으로 작동해야 함
   - Hard dependency 없이 설계

### ❌ DON'T

1. **네임스페이스 생략**
   ```javascript
   Skill("skill-name")  // ✗ 어느 플러그인인지 불명확
   ```

2. **강제 의존성**
   ```markdown
   반드시 다음 스킬을 실행하세요: Skill("other-plugin:skill")
   ```

3. **순환 의존성**
   ```
   plugin-a → plugin-b → plugin-a  // ✗ 순환 참조
   ```

## 테스트 및 검증

### 의존성 분석

```bash
# 스킬 간 의존성 체크
node scripts/analyze-dependencies.js
```

출력 예시:
```json
{
  "summary": {
    "totalPlugins": 7,
    "totalSkills": 23,
    "skillDependencies": 0,
    "fileDependencies": 0,
    "commandDependencies": 0,
    "agentDependencies": 0
  }
}
```

### 통합 테스트

```bash
# 플러그인 독립성 검증
bash tests/integration-test.sh
```

Test Suite 6: Cross-Plugin Independence
```
✓ Plugin is independent: workflow-automation
✓ Plugin is independent: dev-guidelines
✓ Plugin is independent: tool-creators
...
```

## 트러블슈팅

### 문제: 스킬이 활성화되지 않음

**원인**: 네임스페이스 없이 호출
```javascript
Skill("intelligent-task-router")  // ✗
```

**해결**:
```javascript
Skill("workflow-automation:intelligent-task-router")  // ✓
```

### 문제: Hook이 스킬을 제안하지 않음

**원인**: skill-rules.json 누락 또는 잘못된 위치

**확인**:
```bash
ls plugins/*/skills/skill-rules.json
```

**해결**: 각 플러그인의 skills/ 디렉토리에 skill-rules.json 생성

### 문제: 플러그인 간 순환 참조

**원인**: 플러그인 A가 B를 호출하고, B가 A를 호출

**해결**:
1. 공통 기능을 별도 플러그인으로 분리
2. 강제 호출 대신 선택적 제안으로 변경

## 향후 확장

### 플러그인 레지스트리

향후 버전에서 플러그인 간 호출을 명시적으로 관리하는 레지스트리 추가 가능:

```json
{
  "plugin": "workflow-automation",
  "allowedDependencies": [
    "dev-guidelines",
    "quality-review"
  ],
  "providedSkills": [
    "intelligent-task-router",
    "parallel-task-executor"
  ]
}
```

### 동적 플러그인 로딩

사용자가 필요한 플러그인만 선택적으로 활성화:

```bash
# workflow와 quality만 활성화
claude-code --plugins workflow-automation,quality-review
```

## 참고 문서

- [PLUGIN.md](../PLUGIN.md) - 플러그인 구조 상세
- [docs/agent-patterns/INTER_SKILL_PROTOCOL.md](agent-patterns/INTER_SKILL_PROTOCOL.md) - 스킬 간 통신
- [scripts/analyze-dependencies.js](../scripts/analyze-dependencies.js) - 의존성 분석 도구
- [tests/integration-test.sh](../tests/integration-test.sh) - 통합 테스트

---

**v2.0.0** - Multi-Plugin Architecture
