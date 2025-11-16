---
name: dynamic-task-orchestrator
description: Implement Anthropic's Orchestrator-Workers pattern to dynamically decompose complex projects and coordinate specialized workers. Use this skill when tackling multi-faceted software projects requiring architecture design, implementation, testing, documentation, and optimization. The skill excels at adaptive planning and real-time task reallocation across code analysis, system design, development, testing, documentation, and performance optimization.
---

# Dynamic Task Orchestrator

## Overview

This skill implements the Orchestrator-Workers pattern from Anthropic's "Building Effective Agents" framework. It dynamically decomposes complex software projects into manageable tasks and coordinates six specialized workers to execute them efficiently.

**Core Principle:** One central orchestrator analyzes the project, creates an adaptive execution plan, assigns tasks to specialized workers, and dynamically adjusts the plan based on real-time feedback.

## When to Use This Skill

**이 스킬은 복잡도 0.7+ 프로젝트를 6개 내부 워커(Analyzer, Architect, Developer, Tester, Documenter, Optimizer)로 분해하여 실행합니다.**

Use this skill when:
- **복잡도 >= 0.7인 전체 프로젝트 (전체 스택, 마이크로서비스, 대규모 마이그레이션)**
- Building a complete application from scratch (web apps, APIs, full-stack systems)
- Migrating legacy systems to modern architectures (monolith to microservices)
- Refactoring large codebases with multiple concerns (architecture + code + tests + docs)
- Projects requiring coordination across analysis, design, implementation, testing, and documentation
- Complex tasks where single-agent approaches struggle with context or specialization

**Do not use for:**
- Simple, single-concern tasks (use individual agents instead)
- Quick bug fixes or minor edits
- Tasks requiring deep domain expertise beyond software engineering
- **복잡도 < 0.7 작업 (이 경우 agent-workflow-manager의 Simple/Parallel 패턴 사용)**

## Core Capabilities

### 1. Dynamic Project Analysis

Analyze incoming projects in real-time to understand:
- Project type (web app, CLI tool, library, API, full-stack)
- Existing codebase structure and dependencies
- Requirements and constraints
- Complexity level and estimated effort

### 2. Adaptive Task Decomposition

Break down projects into specialized subtasks:
- Identify which workers are needed for each phase
- Establish task dependencies and execution order
- Create priority queues for parallel execution
- Dynamically adjust decomposition based on discoveries

### 3. Intelligent Worker Selection

Select optimal workers based on:
- Current project state and needs
- Worker specialization and capabilities
- Task dependencies and prerequisites
- Worker availability and load balancing

### 4. Real-Time Orchestration

Coordinate workers through:
- Task assignment with clear objectives
- Shared execution context (state, decisions, artifacts)
- Inter-worker communication and collaboration
- Progress monitoring and bottleneck detection
- Adaptive replanning when issues arise

### 5. Context Synchronization

Maintain coherent project state:
- Centralized knowledge base of decisions and artifacts
- Worker-to-worker context sharing
- Checkpoint management for recovery
- Consistent naming, patterns, and conventions across workers

## Specialized Workers

### 1. Code Analyzer Worker

**Role:** Analyze existing codebases to extract architecture, dependencies, and patterns.

**Capabilities:**
- Dependency analysis (imports, packages, relationships)
- Code quality assessment (complexity, duplication, anti-patterns)
- Architecture extraction (layers, modules, design patterns)
- Technology stack identification

**Triggers:** `existing_project`, `refactoring`, `migration`, `legacy_code`

**Output:** Analysis report with structure, dependencies, quality metrics, and recommendations.

### 2. System Architect Worker

**Role:** Design system architecture and technical specifications.

**Capabilities:**
- Component design (modules, services, layers)
- API specification (endpoints, schemas, contracts)
- Database modeling (entities, relationships, migrations)
- Architecture decision records (ADRs)

**Triggers:** `new_project`, `architecture_change`, `system_design`

**Output:** Architecture diagrams, API specs, database schemas, technology choices.

### 3. Code Developer Worker

**Role:** Implement features, fix bugs, and write production code.

**Capabilities:**
- Feature implementation (following specs and patterns)
- Bug fixing (diagnosis and resolution)
- Integration (connecting components and services)
- Code review (quality and consistency checks)

**Triggers:** `implementation_needed`, `code_generation`, `bug_fix`, `feature_request`

**Output:** Working code, implementation notes, integration points.

### 4. Test Engineer Worker

**Role:** Create and execute comprehensive test suites.

**Capabilities:**
- Unit test creation (coverage and edge cases)
- Integration testing (component interactions)
- Performance testing (benchmarks and profiling)
- Test automation (CI/CD integration)

**Triggers:** `code_complete`, `quality_assurance`, `testing_needed`, `regression`

**Output:** Test files, coverage reports, performance benchmarks.

### 5. Documentation Writer Worker

**Role:** Generate clear, comprehensive documentation.

**Capabilities:**
- API documentation (endpoints, parameters, examples)
- User guides (setup, usage, troubleshooting)
- Code comments (inline explanations)
- README files (overview, installation, quick start)

**Triggers:** `feature_complete`, `documentation_gap`, `api_change`, `release`

**Output:** Markdown docs, API references, user guides, code comments.

### 6. Performance Optimizer Worker

**Role:** Identify and resolve performance bottlenecks.

**Capabilities:**
- Bottleneck identification (profiling and analysis)
- Algorithm optimization (time and space complexity)
- Resource optimization (memory, CPU, I/O)
- Code refactoring (maintainability and efficiency)

**Triggers:** `performance_issue`, `optimization_needed`, `scalability_concern`

**Output:** Optimized code, performance reports, refactoring recommendations.

## Orchestration Workflow

### Phase 1: Project Intake

1. Receive project request with requirements and constraints
2. Determine orchestration mode: `autonomous`, `guided`, or `collaborative`
3. Perform initial project analysis using Code Analyzer (if existing code)
4. Create initial execution plan with task breakdown

### Phase 2: Dynamic Execution

```
while project is not complete:
    1. Assess current project state
    2. Select next optimal worker(s) based on:
       - Task priorities
       - Dependencies satisfied
       - Worker availability
    3. Generate worker-specific task with context
    4. Execute worker task
    5. Integrate worker results into project state
    6. Update execution context
    7. Check if replanning is needed:
       - New dependencies discovered
       - Unexpected blockers
       - Scope changes
    8. If replanning needed: adjust execution plan
    9. Checkpoint progress
```

### Phase 3: Project Finalization

1. Verify all deliverables are complete
2. Run final quality checks (tests, docs, code quality)
3. Generate project summary with worker contributions
4. Recommend next steps or evaluator skill

## Usage Examples

### Example 1: Building a Todo App

**Input:**
```json
{
  "task_id": "todo-app-001",
  "project": {
    "name": "Simple Todo App",
    "type": "web_app",
    "requirements": [
      "Create, read, update, delete todos",
      "Mark todos as complete",
      "Filter by status"
    ],
    "constraints": ["Use React and Express", "SQLite database"]
  },
  "orchestration_mode": "autonomous"
}
```

**Execution Flow:**
1. **Architect Worker:** Design API endpoints, database schema, component structure
2. **Developer Worker:** Implement backend API (Express + SQLite)
3. **Developer Worker:** Implement frontend components (React)
4. **Test Engineer:** Write unit and integration tests
5. **Documentation Writer:** Create README and API docs
6. **Performance Optimizer:** (Optional) Optimize if performance issues detected

### Example 2: Migrating Monolith to Microservices

**Input:**
```json
{
  "task_id": "migration-002",
  "project": {
    "name": "E-commerce Migration",
    "type": "full_stack",
    "requirements": ["Extract user service", "Extract product service", "Extract order service"],
    "existing_code": "path/to/monolith"
  },
  "orchestration_mode": "guided"
}
```

**Execution Flow:**
1. **Code Analyzer:** Analyze monolith structure, dependencies, coupling
2. **Architect Worker:** Design microservices architecture, API contracts, data migration
3. **Developer Worker:** Extract user service code
4. **Test Engineer:** Create tests for user service
5. **Developer Worker:** Extract product service code
6. **Test Engineer:** Create tests for product service
7. **Developer Worker:** Extract order service code
8. **Test Engineer:** Create tests for order service
9. **Documentation Writer:** Document each service and migration guide
10. **Performance Optimizer:** Optimize inter-service communication

## Orchestration Modes

### Autonomous Mode
Orchestrator makes all decisions independently. Best for well-defined projects with clear requirements.

### Guided Mode
Orchestrator seeks user approval before major decisions (architecture choices, technology stack, replanning). Best for projects with flexibility or uncertainty.

### Collaborative Mode
Orchestrator involves user throughout execution with checkpoints and decision points. Best for learning or when user expertise is critical.

## Advanced Features

### Adaptive Replanning
- Real-time complexity reassessment
- Worker performance-based task reallocation
- Dynamic dependency adjustment when new dependencies discovered

### Worker Collaboration
- Direct worker-to-worker communication for coordination
- Shared knowledge base maintained across workers
- Cross-worker code review for quality

### Intelligent Delegation
- Worker expertise profiling based on past performance
- Optimal task-worker matching algorithm
- Load balancing across workers

### Progress Monitoring
- Real-time execution dashboard
- Bottleneck detection and early warning
- Dynamic ETA updates

### Failure Recovery
- Automatic task reassignment on worker failure
- Partial result recovery mechanisms
- Graceful degradation strategies

## Resources

### scripts/

The `scripts/` directory contains the core orchestration engine and worker implementations:

- `orchestrator/orchestration_engine.py` - Main orchestration logic
- `orchestrator/task_decomposer.py` - Project decomposition algorithms
- `orchestrator/worker_selector.py` - Worker selection and matching
- `orchestrator/adaptive_planner.py` - Dynamic replanning engine
- `workers/base_worker.py` - Base worker interface
- `workers/code_analyzer_worker.py` - Code analysis worker
- `workers/architect_worker.py` - Architecture design worker
- `workers/developer_worker.py` - Implementation worker
- `workers/tester_worker.py` - Testing worker
- `workers/documenter_worker.py` - Documentation worker
- `workers/optimizer_worker.py` - Performance optimization worker
- `state_management/project_state.py` - Project state tracking
- `state_management/context_manager.py` - Shared context management
- `state_management/checkpoint_manager.py` - Progress checkpointing
- `communication/worker_protocol.py` - Inter-worker communication protocol
- `communication/message_bus.py` - Message routing and delivery

### references/

The `references/` directory contains detailed guides and examples:

- `worker_protocol.md` - Worker communication protocol specification
- `orchestration_patterns.md` - Common orchestration patterns and strategies
- `saas_platform_example.md` - Complete SaaS platform orchestration example
- `microservice_migration_example.md` - Monolith to microservices migration example

### Integration with Other Skills

- **Receives from:** Task routing skills for complex projects
- **Delegates to:** Sequential task processor for ordered workflows, parallel executor for independent tasks
- **Sends to:** Evaluator skills for quality assessment and final validation

## Output Format

```json
{
  "task_id": "string",
  "execution_summary": {
    "total_workers_used": 6,
    "total_subtasks": 25,
    "execution_time": "2h 15m",
    "replanning_count": 3
  },
  "project_deliverables": {
    "source_code": ["path/to/files"],
    "tests": ["path/to/tests"],
    "documentation": ["path/to/docs"],
    "deployment": ["path/to/config"]
  },
  "worker_contributions": {
    "code_analyzer": { "tasks_completed": 3, "artifacts_created": ["analysis_report.md"] },
    "architect": { "tasks_completed": 5, "artifacts_created": ["architecture.md", "api_spec.yaml"] },
    "developer": { "tasks_completed": 10, "artifacts_created": ["src/**/*.js"] },
    "tester": { "tasks_completed": 4, "artifacts_created": ["tests/**/*.test.js"] },
    "documenter": { "tasks_completed": 2, "artifacts_created": ["README.md", "API.md"] },
    "optimizer": { "tasks_completed": 1, "artifacts_created": ["performance_report.md"] }
  },
  "next_skill_recommendation": "evaluator",
  "project_state": "completed"
}
```

## Best Practices

1. **Start Simple:** Begin with core workers (analyzer, architect, developer) before adding specialized workers
2. **Checkpoint Often:** Save progress regularly to enable recovery and rollback
3. **Monitor Context:** Keep shared context lean to avoid overwhelming workers
4. **Validate Early:** Run tests and quality checks as soon as code is written
5. **Document Decisions:** Record architecture decisions and rationale for future reference
6. **Replan Proactively:** Adjust plan early when issues detected, not after failures
7. **Balance Load:** Distribute tasks evenly across workers to avoid bottlenecks

---

## 통합 워크플로우 모드 (Integrated Workflow Mode)

### 개요

Orchestrator가 Router와 Evaluator 기능을 내장하여 전체 워크플로우를 자동 관리합니다.

### 활성화 조건

- Complexity >= 0.7
- 다중 컴포넌트 프로젝트
- 전체 스택 개발
- `/workflow-complex` 커맨드 사용

### 자동 Classification (Router 기능 내장)

```bash
# 작업 분석
CATEGORY=$(analyze_category "$USER_REQUEST")
COMPLEXITY=$(calculate_complexity "$USER_REQUEST")
WORKER_COUNT=$(estimate_workers "$COMPLEXITY")

echo "✓ Category: $CATEGORY"
echo "✓ Complexity: $COMPLEXITY"
echo "✓ Workers: $WORKER_COUNT개"
```

### 자동 워커 선택 및 조율

**Phase 1: Analysis & Design**
- Code Analyzer (기존 코드 분석)
- System Architect (아키텍처 설계)

**Phase 2: Implementation (병렬)**
- Frontend Developer
- Backend Developer
- Database Developer

**Phase 3: Quality Assurance**
- Test Engineer
- Performance Optimizer (필요 시)

**Phase 4: Documentation**
- Documentation Writer

### 자동 품질 평가 (Evaluator 기능 내장)

각 Phase 완료 후 자동 평가:

```bash
# Phase별 품질 검증
validate_phase() {
  PHASE=$1
  case $PHASE in
    design)
      check_architecture_completeness
      check_api_specification
      ;;
    implementation)
      run_integration_tests
      check_code_quality
      ;;
    *)
      ;;
  esac
}
```

### 피드백 루프

품질 미달 시 자동 재실행:

```bash
if [ "$QUALITY_SCORE" -lt "0.90" ]; then
  echo "⚠️  품질 미달 - 재실행"
  # 해당 워커 재할당
  reexecute_worker "$WORKER_ID" "$FEEDBACK"
fi
```

### 사용 예시

```
사용자: "E-commerce 플랫폼 구축"

Orchestrator (통합 모드):
  ✓ Auto Classification: feature_development, 0.95
  ✓ Auto Worker Selection: 7개 워커
  ✓ Phase 1: Analysis & Design 완료
  ✓ Phase 2: Implementation 완료 (병렬)
  ✓ Phase 3: Testing 완료
  ✓ Phase 4: Documentation 완료
  ✓ Auto Evaluation: 93% 품질
  ✅ 완료
```

### 메시지 프로토콜

통합 모드에서도 표준 메시지 프로토콜 사용:

```bash
# 워커에게 메시지 전송
.agent_skills/scripts/send_message.sh \
  orchestrator \
  sequential \
  execute_subtask \
  ${SUBTASK_ID} \
  '{"worker_type":"developer","subtask":{"description":"..."}}'

# 워커 완료 확인
.agent_skills/scripts/check_messages.sh orchestrator
```

### 참조

- **Workflow Manager:** `agent-workflow-manager` 스킬
- **슬래시 커맨드:** `/workflow-complex`
- **통합 프로토콜:** `.agent_skills/integration_protocol.md`

---
