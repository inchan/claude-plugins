---
name: dynamic-task-orchestrator
description: Implements Anthropic's Orchestrator-Workers pattern where a central LLM dynamically breaks down complex tasks, delegates to specialized worker LLMs, and synthesizes results. Use for open-ended problems where subtask number and nature are unpredictable. Ideal for complex projects (0.7+ complexity) requiring adaptive planning.
---

# Dynamic Task Orchestrator (Orchestrator-Workers Pattern)

## Overview

This skill implements the **Orchestrator-Workers** workflow pattern from Anthropic's "Building Effective Agents". The core principle is that a central orchestrator LLM **dynamically** breaks down tasks, delegates to worker LLMs, and synthesizes results - with the key distinction that **subtasks are not predetermined**.

**Reference**: https://www.anthropic.com/engineering/building-effective-agents

### Key Principle

> "Orchestrator-Workers: A central LLM dynamically breaks down tasks, delegates them to worker LLMs, and synthesizes their results."

**Critical Distinction from Parallelization:**
> "The key difference from parallelization is its flexibility—subtasks aren't pre-defined, but determined by the orchestrator based on the specific input."

**Trade-off**: Complexity for adaptability in handling open-ended problems.

## When to Use This Skill

**Ideal scenarios:**
- **Open-ended problems** with unpredictable subtask requirements
- Complex projects where **number and nature of subtasks** depend on input
- Tasks requiring **adaptive decomposition** as work progresses
- **Multi-faceted projects** needing coordinated specialists

**Concrete examples:**
- "Build an e-commerce platform" → Unknown number of services until analyzed
- "Refactor this legacy codebase" → Discover issues during analysis
- "Create a data pipeline" → Requirements emerge from data inspection
- Complex coding tasks that touch multiple files dynamically

**Do NOT use when:**
- Subtasks are **predetermined and fixed** → Use Sequential or Parallel
- Simple, well-defined tasks
- Low complexity (< 0.7) where overhead isn't justified
- Tasks with no natural delegation boundaries

## Core Workflow: Dynamic Orchestration

### The Orchestration Loop

```
[Complex Task]
       ↓
[Orchestrator: Analyze & Plan]
       ↓
[Dynamic Decomposition] ─→ Subtask 1 → [Worker 1] → Result 1
       ↓                   Subtask 2 → [Worker 2] → Result 2
       ↓                   ...discovered as work progresses...
       ↓                   Subtask N → [Worker N] → Result N
       ↓
[Orchestrator: Synthesize Results]
       ↓
[Orchestrator: Assess Completion]
       ↓ (not complete)
[Orchestrator: Identify Next Subtasks] ← (loop back)
       ↓ (complete)
[Final Deliverable]
```

**Key Feature**: The orchestrator **discovers** subtasks as it goes, not all at once.

### Step 1: Initial Analysis

```markdown
## Orchestrator: Initial Analysis

### Task
[Complex task description]

### Initial Assessment
**Complexity**: [High - 0.7+]
**Type**: [open-ended / partially defined / evolving]
**Estimated Workers Needed**: [initial guess, will adapt]

### Known Requirements
1. [Requirement 1]
2. [Requirement 2]
3. ... (may discover more during execution)

### Unknown Factors
- [What needs investigation]
- [What will be discovered during work]
- [Potential scope changes]

### Initial Subtask Identification
Based on current understanding, first subtasks:
1. **Subtask A**: [Description] → Assign to [Worker type]
2. **Subtask B**: [Description] → Assign to [Worker type]
(More subtasks will emerge as we proceed)

### Execution Strategy
- Start with analysis/investigation
- Dynamically add subtasks as scope becomes clearer
- Reassess and replan after each worker completes
```

### Step 2: Worker Delegation

Delegate to specialized workers:

```markdown
## Worker Assignment: [Subtask Name]

### Orchestrator → Worker Message
**Worker Type**: [Code Analyzer / Architect / Developer / Tester / Documenter / Optimizer]
**Task**: [Specific task for this worker]
**Context**: [What this worker needs to know]
**Expected Output**: [What to return]

### Worker Execution
[Worker performs specialized task]

### Worker → Orchestrator Report
**Status**: [Complete/Partial/Blocked]
**Results**: [What was accomplished]
**Discoveries**: [New information uncovered]
**Recommendations**: [Suggested next steps]
**New Subtasks Identified**: [Tasks discovered during this work]
```

### Step 3: Dynamic Replanning

After each worker completes:

```markdown
## Orchestrator: Replan

### Worker Results Integration
- Worker [X] completed [task]
- New information: [discoveries]
- New subtasks identified: [list]

### Updated Task List
1. [x] Subtask A - Complete
2. [x] Subtask B - Complete
3. [ ] Subtask C - **NEW** (discovered during A)
4. [ ] Subtask D - **NEW** (discovered during B)
5. [ ] Subtask E - Original, now reprioritized

### Next Actions
- **Immediate**: Assign Subtask C to [Worker type]
- **Following**: Subtask D depends on C, queue after
- **Reassess after**: E may change based on C/D results

### Scope Assessment
- Original estimate: 5 subtasks
- Current count: 8 subtasks (and counting)
- Complexity increased/decreased: [assessment]
```

### Step 4: Result Synthesis

Combine all worker outputs:

```markdown
## Orchestrator: Final Synthesis

### All Completed Subtasks
1. Subtask A by Code Analyzer → [result]
2. Subtask B by Architect → [result]
3. Subtask C by Developer → [result]
... (all N subtasks)

### Integration Points
- How Worker 1's output connects to Worker 2's
- Dependencies resolved
- Conflicts reconciled

### Coherence Check
- All results consistent: [Yes/No]
- Missing pieces: [None / List]
- Quality assessment: [Score]

### Final Deliverable
[Synthesized output combining all worker results into cohesive whole]

### Execution Summary
- Total subtasks: N (started with estimate of M)
- Workers used: [list]
- Replanning cycles: [count]
- Total time: [duration]
- Adaptive decisions: [key pivots made]
```

## Specialized Workers

### 1. Code Analyzer Worker
**Purpose**: Investigate and understand existing code

```markdown
### Worker: Code Analyzer
**Input**: Source code or codebase path
**Analysis Tasks**:
- Map dependencies and imports
- Identify architectural patterns
- Detect anti-patterns and tech debt
- Measure complexity metrics

**Output**:
```markdown
## Code Analysis Report

### Structure
[Directory layout and module organization]

### Dependencies
[External and internal dependency graph]

### Patterns Found
[Design patterns, architectural style]

### Quality Issues
[Anti-patterns, duplication, complexity hotspots]

### Recommendations
[Suggested improvements]

### Discovered Subtasks
- Refactor module X (high complexity)
- Update deprecated dependency Y
- Add missing tests for Z
```
```

### 2. System Architect Worker
**Purpose**: Design system structure and specifications

```markdown
### Worker: System Architect
**Input**: Requirements and analysis
**Design Tasks**:
- Define component structure
- Create API contracts
- Design data models
- Document architecture decisions

**Output**:
```markdown
## Architecture Design

### System Components
[High-level component diagram]

### API Specification
[Endpoints, request/response formats]

### Data Models
[Entities, relationships, schemas]

### Technology Decisions
[Stack choices with rationale]

### Discovered Subtasks
- Implement authentication service
- Create database migrations
- Set up API gateway
```
```

### 3. Code Developer Worker
**Purpose**: Implement features and write code

```markdown
### Worker: Code Developer
**Input**: Architecture specs and requirements
**Implementation Tasks**:
- Write production code
- Implement business logic
- Create integrations
- Fix bugs

**Output**:
```markdown
## Implementation Complete

### Files Created/Modified
[List of changes]

### Key Implementation Details
[Important design choices made]

### Integration Points
[How this connects to other components]

### Discovered Subtasks
- Frontend needs error handling for API X
- Database needs index for query Y
- Need validation for input Z
```
```

### 4. Test Engineer Worker
**Purpose**: Ensure quality through testing

```markdown
### Worker: Test Engineer
**Input**: Implementation and requirements
**Testing Tasks**:
- Create unit tests
- Write integration tests
- Perform edge case testing
- Measure coverage

**Output**:
```markdown
## Test Report

### Tests Created
[List of test files]

### Coverage
[Coverage percentage and gaps]

### Issues Found
[Bugs or problems discovered]

### Discovered Subtasks
- Fix bug in authentication flow
- Add validation for edge case X
- Improve error messages for Y
```
```

### 5. Documentation Writer Worker
**Purpose**: Create clear documentation

```markdown
### Worker: Documentation Writer
**Input**: Code and architecture
**Documentation Tasks**:
- Write README
- Create API docs
- Document setup process
- Add code comments

**Output**:
```markdown
## Documentation Complete

### Documents Created
[README.md, API.md, etc.]

### Coverage
[What's documented]

### Discovered Subtasks
- Need examples for complex API endpoint
- Missing deployment instructions
- Unclear error code documentation
```
```

### 6. Performance Optimizer Worker
**Purpose**: Improve performance and efficiency

```markdown
### Worker: Performance Optimizer
**Input**: Code and performance requirements
**Optimization Tasks**:
- Profile performance
- Identify bottlenecks
- Optimize algorithms
- Improve resource usage

**Output**:
```markdown
## Optimization Report

### Performance Analysis
[Profiling results]

### Bottlenecks Identified
[Slow operations, memory issues]

### Optimizations Applied
[Changes made]

### Discovered Subtasks
- Database queries need indexing
- Caching layer needed for API
- Memory leak in component X
```
```

## Complete Example: E-Commerce Platform

### Task
"Build an e-commerce platform with product catalog, shopping cart, and checkout"

### Orchestrator: Initial Analysis

```markdown
## Initial Assessment

**Task**: E-commerce platform
**Complexity**: 0.85 (High)
**Type**: Open-ended with multiple unknowns

### Known Requirements
- Product catalog browsing
- Shopping cart functionality
- Checkout process
- (Payment integration? Inventory management? User accounts? - TO DISCOVER)

### Initial Subtasks
1. **Analyze scope** → Code Analyzer (even for new project, analyze requirements)
2. **Design architecture** → System Architect

(More subtasks will emerge from these initial analyses)
```

### Phase 1: Discovery

```markdown
## Worker: System Architect - Scope Analysis

**Task**: Define complete scope for e-commerce platform

**Discoveries**:
- Need user authentication system
- Need inventory management
- Need order tracking
- Need payment gateway integration
- Need admin dashboard

**Recommended Architecture**:
- Microservices: User, Product, Cart, Order, Payment
- Database: PostgreSQL with Redis cache
- Frontend: React with state management

**New Subtasks Identified**:
1. Design User Service API
2. Design Product Service API
3. Design Cart Service API
4. Design Order Service API
5. Design Payment Service integration
6. Design Admin Dashboard
```

### Orchestrator: Replan (First Cycle)

```markdown
## Updated Plan

**Original estimate**: 3-4 main components
**New reality**: 6 services + admin dashboard + integrations

### Revised Subtask List
1. [x] Initial scope analysis - Complete
2. [ ] User Service (auth, profiles)
3. [ ] Product Service (catalog, inventory)
4. [ ] Cart Service (session, persistence)
5. [ ] Order Service (checkout, tracking)
6. [ ] Payment integration (Stripe/PayPal)
7. [ ] Admin Dashboard
8. [ ] Frontend components
9. [ ] Integration testing
10. [ ] Documentation

### Execution Order
1. Parallel: User Service + Product Service (independent)
2. Then: Cart Service (depends on both)
3. Then: Order Service (depends on cart)
4. Then: Payment (depends on order)
5. Parallel: Admin + Frontend (can start partially earlier)
6. Final: Integration + Docs
```

### Phase 2: Implementation (Dynamic)

```markdown
## Worker: Code Developer - User Service

**Implementation**: JWT auth, user CRUD, profile management

**Discoveries During Implementation**:
- Need email verification flow
- Need password reset functionality
- Need role-based access control (RBAC)
- Need rate limiting for auth endpoints

**New Subtasks**:
- Implement email service
- Add RBAC middleware
- Configure rate limiter
```

### Orchestrator: Replan (Second Cycle)

```markdown
## Updated Plan

**Discovery**: Email service needed across multiple services

### New Subtasks Added
11. [ ] Email Service (shared infrastructure)
12. [ ] RBAC Middleware (security layer)
13. [ ] Rate Limiting (infrastructure)

### Reprioritization
- Email Service: Move to high priority (blocks User Service completion)
- RBAC: Needed before other services
- This affects timeline: +2 days estimated
```

### Phase 3: Synthesis

After all workers complete (with many replanning cycles):

```markdown
## Final Synthesis

### Completed Work
- 6 microservices implemented and tested
- Shared infrastructure (email, auth, rate limiting)
- Admin dashboard
- Frontend application
- Integration tests
- Full documentation

### Total Subtasks Executed: 23
(Started with estimate of 10, grew through discovery)

### Worker Contributions
- Code Analyzer: 2 analysis tasks
- System Architect: 8 design tasks
- Code Developer: 15 implementation tasks
- Test Engineer: 10 testing tasks
- Documentation Writer: 3 documentation tasks
- Performance Optimizer: 2 optimization tasks

### Replanning Cycles: 7
Key pivots:
1. Added email service infrastructure
2. Expanded RBAC requirements
3. Split payment service from order service
4. Added caching layer for product catalog
5. Redesigned checkout flow after testing
6. Added monitoring and logging infrastructure
7. Extended admin capabilities

### Final Deliverable
Complete e-commerce platform with:
- Scalable microservices architecture
- Comprehensive test coverage (85%)
- Full API documentation
- Deployment configuration
- Admin dashboard
- Performance optimized

### Adaptive Value Demonstrated
Original monolithic approach would have missed:
- Infrastructure needs (discovered in implementation)
- Security requirements (discovered in testing)
- Performance bottlenecks (discovered in optimization)
- Edge cases (discovered throughout)
```

## Integration with Other Skills

### From Router
```
Router: Complex task detected (0.85 complexity)
→ Route to: dynamic-task-orchestrator
→ Context: Open-ended, needs adaptive planning
```

### With Sequential Processor
```
Orchestrator: "This subtask is sequential"
→ Delegate to: sequential-task-processor for Worker X
→ Worker executes with gates
→ Return results to orchestrator
```

### With Parallel Executor
```
Orchestrator: "These subtasks are independent"
→ Delegate to: parallel-task-executor
→ Run Workers A, B, C simultaneously
→ Return merged results to orchestrator
```

### To Evaluator
```
Orchestrator: "All work complete"
→ Send to: iterative-quality-enhancer
→ Request: "Evaluate entire project quality"
→ Receive: Improvement suggestions
→ Orchestrator may trigger more workers based on feedback
```

## Best Practices

### 1. Embrace Adaptive Planning
The whole point is **dynamic decomposition**. Don't try to plan everything upfront - plan to replan.

### 2. Workers Report Discoveries
Every worker should report:
- What they accomplished
- What they discovered
- New subtasks needed
This feeds the adaptive loop.

### 3. Maintain Coherent Context
Orchestrator must ensure all workers have necessary context:
- Shared decisions
- Common patterns
- Integration points

### 4. Checkpoint Progress
Save state after each worker completes:
- Enables recovery from failures
- Allows rollback if needed
- Provides audit trail

### 5. Know When to Stop
Orchestrator must recognize:
- Diminishing returns
- Scope creep
- When "good enough" is reached

### 6. Balance Workers
Don't over-specialize:
- One worker doing 80% defeats purpose
- Load balance across specialists

## Error Handling

### Worker Failure

```markdown
## Orchestrator: Worker Failure Handling

**Scenario**: Developer Worker failed on Service X implementation

**Recovery Options**:
1. **Retry**: Same worker, same task (transient failure)
2. **Reassign**: Different worker approach (systematic issue)
3. **Decompose further**: Break task into smaller pieces
4. **Escalate**: Request human input

**Action Taken**: [Choice with rationale]
**Impact on Plan**: [How this affects timeline/other tasks]
```

### Scope Explosion

```markdown
## Orchestrator: Scope Control

**Issue**: Subtask count growing uncontrollably (was 10, now 50)

**Assessment**:
- Is growth justified? [Analysis]
- Core requirements still met? [Check]
- Timeline impact acceptable? [Evaluation]

**Actions**:
- Prioritize must-haves vs. nice-to-haves
- Defer non-critical subtasks
- Communicate scope change to user
```

## Performance Considerations

### Overhead
- Orchestration layer adds coordination cost
- Each worker delegation has context cost
- Replanning cycles take time

### When Worth It
- Complex, unpredictable problems
- High-stakes projects needing adaptability
- When discovery is part of the task

### When Too Much
- Simple, well-defined tasks
- Time-critical with no room for adaptation
- When subtasks are clearly predetermined

## Summary

The Dynamic Task Orchestrator implements Anthropic's Orchestrator-Workers pattern by:

1. **Dynamically analyzing** complex tasks without predetermined decomposition
2. **Delegating** to specialized workers based on emerging needs
3. **Synthesizing** worker results into coherent output
4. **Adaptively replanning** as new information emerges
5. **Coordinating** multiple specialists for complex work

This pattern excels when:
- Task complexity requires specialization
- Subtasks emerge during execution (not predetermined)
- Adaptive planning provides better outcomes than fixed workflows

**Remember**: The power is in **adaptability**. Unlike Sequential (fixed steps) or Parallel (predetermined splits), the Orchestrator **discovers** the work structure as it proceeds. This is the key differentiator.
