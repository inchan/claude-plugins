---
name: parallel-task-executor
description: Execute independent tasks in parallel and aggregate results using Anthropic's Parallelization pattern. Use when tasks can be decomposed into independent sections (file-level, module-level, test-level) or when evaluating multiple approaches through voting. Automatically manages dependency graphs, dynamic worker pools, and result synthesis for 2-10x speedup.
---

# Parallel Task Executor

## Overview

Execute independent tasks in parallel and intelligently aggregate results, implementing Anthropic's Parallelization pattern from "Building Effective Agents". This skill provides two core modes: **Sectioning** for decomposing work into independent parallel units, and **Voting** for executing multiple approaches and selecting the optimal result.

**When to use this skill:**
- Creating multiple independent files, modules, or components simultaneously
- Running test suites (unit/integration/e2e) in parallel
- Developing microservices or multi-layer architectures concurrently
- Comparing multiple implementation approaches or paradigms
- Any task where subtasks have minimal interdependencies

**Performance characteristics:**
- Parallelism: 2-10 concurrent workers (auto-scaled based on task complexity)
- Typical speedup: 2-5x for sectioning, valuable consensus for voting
- Automatic dependency analysis and DAG-based execution planning

## Core Capabilities

### 1. Sectioning Mode

Decompose a main task into independent sections that can be executed in parallel, then merge results.

**Execution patterns:**

**File-Level Parallelization** (max 10 parallel)
```
Task: "Create React components for user profile, dashboard, and settings pages"
Execution: 3 parallel file creation tasks → merge imports and exports
Benefit: 3x speedup on independent component creation
```

**Module-Level Parallelization** (max 5 parallel)
```
Task: "Build a full-stack todo app with React frontend, Express backend, and PostgreSQL database"
Execution:
  - Worker 1: Frontend React components
  - Worker 2: Backend Express routes + controllers
  - Worker 3: Database schema + migrations
→ Merge: Integration layer (API calls, types, config)
Benefit: 3x speedup + parallel expertise application
```

**Test-Level Parallelization** (max 8 parallel)
```
Task: "Run comprehensive test suite"
Execution:
  - Worker 1: Unit tests (model layer)
  - Worker 2: Unit tests (service layer)
  - Worker 3: Integration tests (API)
  - Worker 4: E2E tests (critical paths)
→ Aggregate: Test report with coverage
Benefit: 4x speedup on test execution
```

**Usage:**
```json
{
  "task_id": "fullstack-app-001",
  "mode": "sectioning",
  "main_task": {
    "description": "Build full-stack e-commerce product catalog",
    "components": [
      "React frontend with product grid",
      "Express API with CRUD endpoints",
      "PostgreSQL schema for products",
      "Integration tests"
    ]
  },
  "parallelism_hint": 4,
  "timeout_seconds": 300
}
```

**Sectioning workflow:**
1. **Analyze** main task to identify independent sections
2. **Build DAG** of dependencies and find parallelizable groups
3. **Execute** parallel workers on independent sections
4. **Sync** at dependency boundaries (wait for prerequisites)
5. **Merge** results with conflict resolution
6. **Validate** integrated output

### 2. Voting Mode

Execute the same task using multiple approaches, then aggregate results to select the optimal solution.

**Voting strategies:**

**Multi-Paradigm Voting**
```
Task: "Implement a data processing pipeline"
Voters:
  - Functional approach (immutable, pure functions)
  - OOP approach (classes, encapsulation)
  - Reactive approach (streams, observables)
Aggregation: Weighted score based on readability, performance, maintainability
Selection: Highest composite score or hybrid approach
```

**Multi-Model Voting**
```
Task: "Optimize algorithm for complex calculation"
Voters:
  - Haiku: Fast, simple solution
  - Sonnet: Balanced solution
  - Opus: Comprehensive, robust solution
Aggregation: Consensus on correctness + performance benchmarks
Selection: Best performance/complexity tradeoff
```

**Multi-Strategy Voting**
```
Task: "Refactor legacy authentication system"
Voters:
  - Performance-optimized approach
  - Readability-focused approach
  - Maintainability-focused approach
Aggregation: Balanced scoring across all three dimensions
Selection: Pareto-optimal solution
```

**Usage:**
```json
{
  "task_id": "algorithm-optimization-001",
  "mode": "voting",
  "main_task": {
    "description": "Optimize search algorithm for large dataset",
    "evaluation_criteria": ["performance", "code_quality", "maintainability"]
  },
  "voters": ["functional", "imperative", "hybrid"],
  "aggregation": "weighted_score",
  "timeout_seconds": 180
}
```

**Voting workflow:**
1. **Define** evaluation criteria and voting strategies
2. **Execute** multiple parallel implementations
3. **Benchmark** each approach (performance, metrics)
4. **Score** based on criteria (weighted or consensus)
5. **Select** winner or synthesize hybrid solution
6. **Document** decision rationale

### 3. Dependency Management

Automatic dependency analysis and DAG-based execution planning ensure correct execution order while maximizing parallelism.

**Dependency analysis features:**
- Extract imports, function calls, variable references
- Build directed acyclic graph (DAG) of dependencies
- Identify parallelizable groups (nodes with no dependencies)
- Calculate critical path for time estimation
- Detect circular dependencies and conflicts

**Execution strategy:**
```python
# Pseudo-code for execution planning
def plan_execution(main_task):
    subtasks = decompose(main_task)
    dependencies = analyze_dependencies(subtasks)
    dag = build_dag(subtasks, dependencies)

    # Group by execution waves
    parallel_groups = []
    while dag.has_nodes():
        # Get all nodes with no remaining dependencies
        ready_nodes = dag.nodes_with_no_dependencies()
        parallel_groups.append(ready_nodes)
        dag.remove_nodes(ready_nodes)

    return {
        "waves": parallel_groups,  # Execute each wave in parallel
        "sync_points": len(parallel_groups),  # Wait points between waves
        "critical_path": dag.longest_path(),  # Bottleneck tasks
        "max_parallelism": max(len(wave) for wave in parallel_groups)
    }
```

**Conflict resolution:**
- File-level conflicts: Line-by-line merge with syntax validation
- Import conflicts: Deduplication and ordering
- Type conflicts: Union types or explicit casting
- Logic conflicts: Flag for manual review

### 4. Dynamic Worker Pool Management

Automatically scale worker pool size based on task complexity and resource availability.

**Scaling strategy:**
- **Minimum workers:** 2 (always maintain parallelism)
- **Maximum workers:** 10 (avoid overhead from context switching)
- **Default workers:** 5 (balanced for most tasks)
- **Auto-scaling:** Increase for independent tasks, decrease for dependent tasks

**Resource monitoring:**
- Track execution time per worker
- Monitor memory usage (avoid OOM)
- Detect stuck workers (timeout and retry)
- Balance load across workers

**Fault tolerance:**
- Automatic retry on worker failure (max 3 attempts)
- Graceful degradation (continue with completed work)
- Checkpoint mechanism (resume from last sync point)
- Rollback on critical failure

### 5. Result Aggregation

Intelligently merge parallel execution results into cohesive output.

**Sectioning aggregation:**
- **Code merging:** Combine files with import deduplication
- **Test results:** Aggregate pass/fail with coverage report
- **Documentation:** Merge sections maintaining structure
- **Artifacts:** Collect and organize output files

**Voting aggregation:**
- **Weighted scoring:** Assign weights to evaluation criteria
- **Consensus detection:** Identify common patterns across voters
- **Hybrid synthesis:** Combine best elements from multiple approaches
- **Decision documentation:** Record rationale and tradeoffs

**Output format:**
```json
{
  "task_id": "example-001",
  "execution_summary": {
    "total_subtasks": 10,
    "parallel_executions": 5,
    "execution_time": "45s",
    "speedup_factor": 3.2,
    "workers_used": 5,
    "sync_points": 3
  },
  "results": {
    "mode": "sectioning",
    "completed_sections": [
      {"name": "frontend", "status": "success", "output": "path/to/frontend"},
      {"name": "backend", "status": "success", "output": "path/to/backend"},
      {"name": "database", "status": "success", "output": "path/to/db"}
    ],
    "merged_output": "path/to/integrated/app",
    "conflicts_resolved": 2,
    "manual_review_required": []
  },
  "performance_metrics": {
    "worker_utilization": 0.85,
    "avg_task_time": "12s",
    "critical_path_time": "35s"
  },
  "next_steps": [
    "Run integration tests on merged output",
    "Review conflict resolutions",
    "Deploy integrated application"
  ]
}
```

## Integration with Other Skills

**Upstream integration (receiving tasks from):**
- **Router skill:** Identifies tasks suitable for parallelization
- **Orchestrator skill:** Delegates parallel execution to this skill
- **User request:** Direct invocation with parallel task description

**Parallel execution (used within this skill):**
- **Sequential skill:** Each parallel worker may use sequential processing
- **Task tool:** Spawn parallel agents for independent subtasks

**Downstream integration (sending results to):**
- **Evaluator skill:** Validate merged results and check quality
- **Testing skill:** Run integration tests on combined output
- **Documentation skill:** Generate documentation for parallel workflow

**Example flow:**
```
User: "Build microservices architecture"
  ↓
Router: "Detect parallel opportunity"
  ↓
Parallel Task Executor: "Sectioning mode - 3 services in parallel"
  ↓ (parallel)
  Worker 1: Auth service (using Sequential skill)
  Worker 2: Payment service (using Sequential skill)
  Worker 3: Notification service (using Sequential skill)
  ↓ (merge)
Parallel Task Executor: "Merge with API gateway"
  ↓
Evaluator: "Validate integrated system"
  ↓
User: "System ready for deployment"
```

## Advanced Features

### Dynamic Scaling
- Monitor task complexity and adjust worker pool size
- Track CPU/memory usage to prevent resource exhaustion
- Real-time parallelism optimization based on performance data
- Adaptive timeout adjustment for complex tasks

### Conflict Resolution
- Automatic file merge with syntax-aware conflict detection
- Import/export deduplication and ordering
- Type conflict resolution (union types, explicit casting)
- Dependency conflict detection and resolution

### Performance Optimization
- Task queue priority management (critical path first)
- Result caching and memoization for repeated operations
- Resource pooling (database connections, API clients)
- Incremental result streaming for long-running tasks

### Fault Tolerance
- Automatic retry with exponential backoff
- Partial failure handling with graceful degradation
- Checkpoint and resume mechanism for long tasks
- Comprehensive error logging and debugging

## Resources

### scripts/

Python implementations of core execution components. These scripts can be executed directly without loading into context.

- **`executors/sectioning_executor.py`** - Implements sectioning mode with DAG-based parallel execution
- **`executors/voting_executor.py`** - Implements voting mode with multi-approach evaluation
- **`executors/worker_pool.py`** - Dynamic worker pool management with auto-scaling
- **`analyzers/dependency_analyzer.py`** - Extracts dependencies from code and builds dependency graph
- **`analyzers/dag_builder.py`** - Constructs directed acyclic graph for execution planning
- **`analyzers/conflict_resolver.py`** - Detects and resolves conflicts in parallel execution results
- **`aggregators/code_merger.py`** - Merges code files with import deduplication
- **`aggregators/vote_aggregator.py`** - Aggregates voting results with weighted scoring
- **`aggregators/result_synthesizer.py`** - Synthesizes hybrid solutions from multiple approaches
- **`monitors/progress_tracker.py`** - Tracks execution progress and performance metrics

### references/

No reference documentation needed - all necessary information is in SKILL.md.

### examples/

Real-world usage examples demonstrating sectioning and voting modes.

- **`examples/fullstack_parallel.md`** - Complete example of building full-stack application in parallel
- **`examples/code_review_voting.md`** - Example of using voting mode for code review and optimization

### config.json

Configuration file for execution parameters and resource limits.

```json
{
  "parallelism": {
    "min_workers": 2,
    "max_workers": 10,
    "default_workers": 5
  },
  "timeouts": {
    "default_task": 300,
    "max_task": 600,
    "worker_heartbeat": 30
  },
  "retry": {
    "max_attempts": 3,
    "backoff_multiplier": 2,
    "initial_delay": 1
  },
  "resources": {
    "max_memory_mb": 4096,
    "cpu_threshold": 0.8
  }
}
```

## Usage Examples

### Example 1: Full-Stack Application (Sectioning)

**Request:** "Build a full-stack todo application with React frontend, Express backend, and PostgreSQL database"

**Execution:**
```
Mode: sectioning
Workers: 3 parallel

Worker 1 (Frontend):
- React components (TodoList, TodoItem, AddTodo)
- State management with hooks
- API client for backend communication

Worker 2 (Backend):
- Express server setup
- CRUD routes for todos
- Controller and service layer
- Input validation with middleware

Worker 3 (Database):
- PostgreSQL schema (todos table)
- Migration scripts
- Seed data for development

Sync Point: Wait for all workers

Merge:
- Configure API endpoint URLs in frontend
- Set database connection in backend
- Create docker-compose for local development
- Integration test setup

Result: Fully integrated application ready to run
Speedup: 3x (45 min → 15 min)
```

### Example 2: Algorithm Optimization (Voting)

**Request:** "Optimize search algorithm for finding user by email in large dataset"

**Execution:**
```
Mode: voting
Voters: 3 approaches

Voter 1 (Functional):
- Immutable data structures
- Filter and map operations
- Pure functions for search logic

Voter 2 (Imperative):
- Index-based iteration
- Early termination on match
- Mutable state for optimization

Voter 3 (Hybrid):
- Hash map for O(1) lookup
- Lazy evaluation for memory efficiency
- Caching for repeated searches

Evaluation Criteria:
- Performance: Benchmark on 1M records
- Readability: Code complexity metrics
- Maintainability: Coupling and cohesion

Scoring:
- Functional: Performance 6/10, Readability 9/10, Maintainability 8/10 → Total: 23/30
- Imperative: Performance 8/10, Readability 6/10, Maintainability 7/10 → Total: 21/30
- Hybrid: Performance 10/10, Readability 7/10, Maintainability 9/10 → Total: 26/30

Winner: Hybrid approach (highest total score)
Rationale: Best performance with acceptable readability and excellent maintainability
```

### Example 3: Test Suite Execution (Sectioning)

**Request:** "Run comprehensive test suite for authentication service"

**Execution:**
```
Mode: sectioning
Workers: 4 parallel

Worker 1: Unit tests - auth controller (15 tests)
Worker 2: Unit tests - token service (12 tests)
Worker 3: Integration tests - login flow (8 tests)
Worker 4: E2E tests - full authentication cycle (5 tests)

Parallel execution: All workers run simultaneously

Aggregation:
- Total tests: 40
- Passed: 38
- Failed: 2 (in integration tests)
- Coverage: 87%
- Execution time: 23s (vs 85s sequential)

Result: Test report with 3.7x speedup
Action: Fix 2 failing integration tests
```

## Best Practices

1. **Identify independence:** Ensure subtasks have minimal dependencies before parallelizing
2. **Balance granularity:** Too fine-grained = overhead, too coarse-grained = underutilization
3. **Handle failures gracefully:** Always implement retry logic and fallback strategies
4. **Monitor performance:** Track speedup factor to validate parallelization benefit
5. **Document decisions:** Record why parallel approach was chosen and what tradeoffs were made
6. **Test integration:** Always run integration tests after merging parallel results
7. **Use voting strategically:** Best for subjective decisions or when multiple valid approaches exist
8. **Respect resource limits:** Don't parallelize when resources (memory, CPU) are constrained

## Limitations

- **Not suitable for:**
  - Highly sequential tasks (e.g., stateful workflows)
  - Tasks with complex interdependencies
  - Single atomic operations (overhead > benefit)

- **Performance considerations:**
  - Overhead from spawning workers and merging results
  - Context switching can reduce benefit with too many workers
  - Network-bound tasks may not benefit from parallelization

- **Conflict resolution:**
  - Complex logic conflicts require manual review
  - Type system conflicts may need explicit resolution
  - Semantic conflicts cannot be automatically resolved

## Troubleshooting

**Low speedup factor (<1.5x):**
- Check for hidden dependencies between subtasks
- Reduce number of workers to decrease overhead
- Verify tasks are truly independent

**Merge conflicts:**
- Review dependency analysis for missing edges
- Check for shared state or global variables
- Consider sequential execution for conflicting sections

**Worker failures:**
- Check timeout settings (may be too aggressive)
- Review resource limits (memory, CPU)
- Examine error logs for root cause

**Memory issues:**
- Reduce number of parallel workers
- Implement streaming for large data
- Clear intermediate results after merge
