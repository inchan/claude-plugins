---
name: intelligent-task-router
description: Implements Anthropic's Routing pattern to classify incoming tasks and direct them to specialized handlers. Analyzes task complexity, intent, and category to select optimal processing path and model (Haiku/Sonnet/Opus). Use as the entry point for complex requests requiring intelligent dispatch.
---

# Intelligent Task Router (Routing Pattern)

## Overview

This skill implements the **Routing** workflow pattern from Anthropic's "Building Effective Agents". The core principle is to classify input and direct it to specialized downstream processes, allowing optimization for different task categories.

**Reference**: https://www.anthropic.com/engineering/building-effective-agents

### Key Principle

> "Routing classifies an input and directs it to a specialized followup task. This workflow allows for separation of concerns, and building more specialized prompts."

**Trade-off**: Upfront classification cost for better specialized handling downstream.

## When to Use This Skill

**Ideal scenarios:**
- Complex tasks with **distinct categories** requiring different handling
- When **model selection** matters (cost vs. capability optimization)
- Tasks where **accurate classification** is achievable
- Entry point for multi-skill workflows

**Concrete examples:**
- Customer support routing: refund → billing team, technical → support team
- Development task routing: bug fix → debugger, feature → architect
- Content processing: simple query → Haiku, complex analysis → Opus
- Multi-language support: Korean → KO specialist, English → EN specialist

**Do NOT use when:**
- Task is already clearly defined
- All inputs require the same handling
- Classification overhead exceeds benefit
- Real-time latency is critical

## Core Routing Workflow

### Input Classification

```
[Incoming Request]
       ↓
[Classification Analysis]
       ↓
[Category Assignment] ─→ Category A → [Handler A]
       ↓                 Category B → [Handler B]
       ↓                 Category C → [Handler C]
       ↓
[Route to Optimal Handler]
```

## Classification Framework

### Step 1: Multi-Factor Analysis

Analyze each incoming task across **4 dimensions**:

```markdown
## Task Classification: [Task Description]

### 1. Category Analysis
**Primary Category**: [one of 8 categories]
**Secondary Categories**: [supporting categories]
**Confidence**: [0-100%]

### 2. Intent Detection
**User Intent**: [CREATE/MODIFY/DEBUG/ANALYZE/OPTIMIZE/DOCUMENT/TEST]
**Underlying Goal**: [what the user ultimately wants to achieve]

### 3. Complexity Assessment
**Scope**: [single file / multiple files / system-wide]
**Dependencies**: [none / few / many]
**Technical Depth**: [basic / intermediate / advanced]
**Overall Complexity**: [0.0 - 1.0]

### 4. Urgency Level
**Priority**: [critical / high / medium / low]
**Time Sensitivity**: [immediate / soon / eventual]
```

### Step 2: Category Classification

**8 Primary Categories:**

| Category | Keywords | Typical Complexity | Default Model |
|----------|----------|-------------------|---------------|
| **bug_fix** | bug, error, fix, 버그, 오류, 수정 | 0.3-0.6 | Sonnet |
| **feature_development** | add, create, implement, 추가, 구현, 개발 | 0.5-0.9 | Sonnet/Opus |
| **refactoring** | refactor, clean, restructure, 리팩토링, 정리 | 0.4-0.7 | Sonnet |
| **testing** | test, coverage, validation, 테스트, 검증 | 0.3-0.5 | Sonnet |
| **documentation** | document, explain, readme, 문서, 설명 | 0.2-0.4 | Haiku/Sonnet |
| **performance** | optimize, speed, memory, 최적화, 성능 | 0.5-0.8 | Sonnet/Opus |
| **security** | security, vulnerability, auth, 보안, 취약점 | 0.6-0.9 | Opus |
| **data_processing** | data, transform, ETL, 데이터, 변환 | 0.4-0.7 | Sonnet |

**Classification Output:**

```markdown
## Classification Result

**Task**: "Fix login page authentication error"

**Category Analysis**:
- Primary: bug_fix (85% confidence)
- Secondary: security (30%)
- Intent: DEBUG
- Complexity: 0.55

**Reasoning**:
- Keywords "fix" and "error" → bug_fix
- "authentication" suggests security concern
- Single component (login page) → moderate complexity
- Error fixing intent is clear → DEBUG
```

### Step 3: Routing Decision

Based on classification, select:

#### A. Target Skill

| Classification | Route To | Reasoning |
|----------------|----------|-----------|
| Simple sequential task (complexity < 0.7) | sequential-task-processor | Step-by-step execution with gates |
| Independent parallel work | parallel-task-executor | Concurrent processing |
| Complex multi-component (complexity >= 0.7) | dynamic-task-orchestrator | Dynamic decomposition |
| Quality improvement focus | iterative-quality-enhancer | Iterative refinement |

#### B. Model Selection

**Cost-Optimized Model Selection:**

```markdown
## Model Selection Matrix

### Claude Haiku (complexity < 0.4)
- Simple documentation updates
- Basic data transformations
- Straightforward bug fixes
- Quick information retrieval
**Trade-off**: Fastest, cheapest, less capable

### Claude Sonnet (complexity 0.4-0.7)
- Standard feature development
- Medium complexity refactoring
- Most testing tasks
- Performance analysis
**Trade-off**: Balanced performance and cost (DEFAULT)

### Claude Opus (complexity > 0.7)
- Complex architecture design
- Security-critical implementations
- Large-scale system migrations
- Novel problem solving
**Trade-off**: Most capable, slowest, most expensive
```

## Complete Routing Example

### Input Request
"사용자 프로필에 프로필 이미지 업로드 및 크롭 기능을 추가해주세요. 이미지는 S3에 저장되어야 하고, 썸네일도 자동 생성되어야 합니다."

### Classification Process

```markdown
## Classification: Profile Image Feature

### 1. Category Analysis
**Primary**: feature_development (90%)
- Keywords: "추가", "기능"
- Nature: Adding new capability

**Secondary**: data_processing (40%)
- Keywords: "저장", "생성"
- Nature: Image transformation

**Confidence**: High (90%)

### 2. Intent Detection
**Intent**: CREATE
- Building new functionality from scratch
- Multi-component feature

**Underlying Goal**: Enable users to personalize profiles with images

### 3. Complexity Assessment
**Scope**: Multiple components
- Frontend: Upload UI, crop interface
- Backend: Upload handling, image processing
- Infrastructure: S3 integration

**Dependencies**: High
- S3 AWS SDK
- Image processing library (Sharp/ImageMagick)
- Database schema updates

**Technical Depth**: Advanced
- Image manipulation algorithms
- Cloud storage patterns
- Async processing for thumbnails

**Overall Complexity**: 0.78 (High)

### 4. Urgency Level
**Priority**: Medium
- No urgency keywords detected
- Standard feature request
```

### Routing Decision

```markdown
## Routing Decision

**Target Skill**: dynamic-task-orchestrator
**Reasoning**:
- Complexity 0.78 > 0.7 threshold
- Multiple independent components
- Requires dynamic task decomposition

**Model**: Claude Opus
**Reasoning**:
- High complexity (0.78)
- Multiple technical domains
- Architecture decisions required

**Priority**: Medium
**Estimated Effort**: 90-120 minutes

**Recommended Decomposition**:
1. Frontend upload UI component
2. Crop interface with preview
3. Backend upload endpoint
4. S3 integration service
5. Image processing worker
6. Thumbnail generation
7. Database schema update
8. Integration testing

**Secondary Considerations**:
- Security: Validate file types, size limits
- Performance: Async thumbnail generation
- Error handling: Upload failures, S3 connectivity
```

### Output to Next Skill

```json
{
  "routing": {
    "task_id": "task_profile_image_001",
    "target_skill": "dynamic-task-orchestrator",
    "model": "claude-opus",
    "priority": "medium"
  },
  "task_context": {
    "original_request": "사용자 프로필에 프로필 이미지 업로드...",
    "category": "feature_development",
    "complexity": 0.78,
    "intent": "CREATE",
    "secondary_concerns": ["data_processing", "security"],
    "estimated_minutes": 105
  },
  "recommendations": {
    "decomposition_hint": ["frontend_ui", "backend_api", "infrastructure", "testing"],
    "critical_paths": ["S3 integration", "image processing"],
    "risk_factors": ["cloud service dependency", "image format compatibility"]
  }
}
```

## Handling Low Confidence

When classification confidence is below 60%, request clarification:

```markdown
## Clarification Request

I've analyzed your request but need additional information for optimal routing.

**Current Classification** (55% confidence):
- Possible categories: bug_fix OR feature_development
- Unclear aspects: Is this fixing existing behavior or adding new?

**Questions to Clarify**:

1. **Scope**: Is this affecting a single component or multiple parts of the system?
   - [ ] Single file/component
   - [ ] Multiple related components
   - [ ] System-wide changes

2. **Nature**: What best describes this task?
   - [ ] Fixing something that's broken (bug_fix)
   - [ ] Adding something that doesn't exist (feature_development)
   - [ ] Improving something that works (refactoring/performance)

3. **Priority**: How urgent is this?
   - [ ] Critical - needs immediate attention
   - [ ] High - important but not blocking
   - [ ] Medium - standard priority
   - [ ] Low - nice to have

4. **Constraints**: Any specific requirements?
   - Technical constraints (e.g., must use specific library)
   - Time constraints (e.g., deadline)
   - Compatibility requirements (e.g., backward compatible)

Please provide these details so I can route your task optimally.
```

## Integration with Other Skills

### As Entry Point

The Router serves as the **gateway** to other skills:

```
[User Request]
       ↓
[Intelligent Task Router] ─→ Sequential Processor
       ↓                    → Parallel Executor
       ↓                    → Dynamic Orchestrator
       ↓                    → Quality Enhancer
[Routing Decision + Context]
```

### Workflow Examples

**1. Simple Bug Fix Flow:**
```
User: "Fix null pointer in UserService"
       ↓
Router: category=bug_fix, complexity=0.4, model=Sonnet
       ↓
Route to: sequential-task-processor
       ↓
Sequential executes: Analyze → Fix → Test → Document
```

**2. Complex Feature Flow:**
```
User: "Build real-time collaboration feature"
       ↓
Router: category=feature_development, complexity=0.85, model=Opus
       ↓
Route to: dynamic-task-orchestrator
       ↓
Orchestrator: Decomposes into 10 sub-tasks, assigns workers
```

**3. Performance Optimization Flow:**
```
User: "Optimize database queries"
       ↓
Router: category=performance, complexity=0.6, model=Sonnet
       ↓
Route to: iterative-quality-enhancer
       ↓
Enhancer: Analyze → Optimize → Evaluate → Iterate
```

## Best Practices

### 1. Classify First, Always
Every significant task should pass through the router. This ensures optimal resource allocation.

### 2. Trust Complexity Scores
Model selection based on complexity prevents:
- Wasting resources (Opus for simple tasks)
- Insufficient capability (Haiku for complex tasks)

### 3. Consider Secondary Categories
A bug_fix with security secondary means security review is needed during fix.

### 4. Update Routing Rules
As you learn project patterns:
- Adjust complexity thresholds
- Add project-specific categories
- Refine model selection rules

### 5. Track Routing Outcomes
Monitor which routings lead to success:
- Did the selected skill complete the task?
- Was the model choice appropriate?
- Were complexity estimates accurate?

Use this feedback to improve future routing.

## Edge Cases and Special Handling

### Multi-Category Tasks

When task spans multiple categories equally:

```markdown
**Example**: "Refactor authentication module and add two-factor authentication"

**Categories**:
- refactoring (50%): "Refactor" keyword
- feature_development (45%): "add...authentication"
- security (40%): "authentication", "two-factor"

**Resolution**:
1. Primary: refactoring (highest score)
2. Route to dynamic-task-orchestrator (multiple concerns)
3. Include sub-routing for each aspect
```

### Urgent vs. Complex

When urgency conflicts with complexity:

```markdown
**Example**: "URGENT: Fix critical security vulnerability"

**Analysis**:
- Urgency: CRITICAL (override normal priority)
- Complexity: 0.75 (normally → Opus)
- Category: security (high-stakes)

**Decision**:
- Model: Claude Opus (critical security needs best)
- Priority: Immediate
- But: Consider if simpler mitigation exists first
```

### Unknown Task Types

When task doesn't fit categories:

```markdown
**Example**: "Deploy to production"

**Analysis**:
- No direct category match
- Keywords suggest: operations, infrastructure

**Handling**:
1. Default to medium complexity
2. Ask for clarification
3. Consider adding "devops" category if pattern repeats
```

## Performance Considerations

### Routing Overhead

- Classification: ~1-2 seconds
- Model selection: ~0.5 seconds
- Context preparation: ~1 second
- **Total overhead**: ~3-4 seconds

**Worth it when**: Task execution time >> routing overhead

### When to Skip Routing

- Explicitly simple tasks
- User specifies exact approach
- Repeated identical tasks (cache routing decision)

## Customization

### Adding Custom Categories

```markdown
## New Category: api_integration

**Keywords**: API, integration, external, third-party, endpoint
**Default Complexity**: 0.5-0.7
**Typical Model**: Sonnet
**Default Skill**: sequential-task-processor

**When to Use**:
- Connecting to external services
- Implementing API clients
- Handling API authentication
```

### Adjusting Thresholds

Based on project needs:
- Lower Opus threshold for security-critical projects
- Raise Haiku threshold for cost-sensitive environments
- Add project-specific keywords for better classification

## Summary

The Intelligent Task Router implements Anthropic's Routing pattern by:

1. **Classifying** incoming tasks across multiple dimensions
2. **Analyzing** complexity, intent, and urgency
3. **Selecting** optimal downstream skill based on task characteristics
4. **Choosing** appropriate model (Haiku/Sonnet/Opus) for cost-capability balance
5. **Providing** rich context for downstream skills

This pattern excels when different task types benefit from specialized handling, and when upfront classification cost is offset by downstream efficiency gains.

**Remember**: The router is a **dispatcher**, not an executor. Its value is in intelligent delegation, not task completion.
