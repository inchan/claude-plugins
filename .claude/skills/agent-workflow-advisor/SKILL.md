---
name: agent-workflow-advisor
description: Analyzes tasks and recommends the optimal agent pattern from Anthropic's Building Effective Agents. Provides pattern selection guidance based on task complexity, structure, and requirements. Use this as the entry point when unsure which pattern (Sequential, Router, Parallel, Orchestrator, Evaluator) fits your task best.
---

# Agent Workflow Advisor

## Overview

This skill serves as the **entry point** for the 5 agent pattern skills, helping you select the optimal workflow pattern for your task. It analyzes your request and provides a **recommendation with reasoning**, but you make the final decision.

**Reference**: https://www.anthropic.com/engineering/building-effective-agents

### Purpose

> "When building agents, you should start with the simplest solution possible, adding complexity only when needed."

This advisor helps you:
1. **Understand** your task's characteristics
2. **Match** to the best-fit pattern
3. **Decide** with confidence which skill to use

**This skill does NOT execute tasks** - it recommends the right tool for the job.

## When to Use This Skill

Use this advisor when:
- **Uncertain** which pattern fits your task
- **Starting** a complex project
- **Learning** the agent pattern system
- **Want validation** of your pattern choice

## Quick Pattern Reference

| Pattern | Best For | Key Characteristic |
|---------|----------|-------------------|
| **No Pattern** | Simple, single-step tasks | Direct execution, no overhead |
| **Sequential** (Prompt Chaining) | Fixed multi-step tasks | Validation gates between steps |
| **Router** (Routing) | Task classification & delegation | Categorize → Route to specialist |
| **Parallel** (Parallelization) | Independent work or voting | Concurrent execution, merge results |
| **Orchestrator** (Orchestrator-Workers) | Open-ended complex projects | Dynamic subtask discovery |
| **Evaluator** (Evaluator-Optimizer) | Quality improvement | Feedback loop until threshold met |

## Critical First Question: Do You Even Need a Pattern?

**Before recommending any pattern, I ask:**

> "Is this task simple enough that a pattern would add overhead without benefit?"

### When NO PATTERN is Best

**Complexity < 0.3** AND any of:
- Single file change
- One clear action (fix this bug, add this field)
- Less than 10 minutes of work
- No validation checkpoints needed
- No parallel opportunities

**Examples of "No Pattern" tasks:**
- "Fix null pointer in UserService line 45"
- "Add email field to User model"
- "Update README with new installation step"
- "Rename variable from 'temp' to 'userCount'"

**My response for simple tasks:**
```markdown
## Recommendation: No Pattern Needed

This task is straightforward enough to execute directly.

**Why no pattern:**
- Single action required
- No validation gates needed
- Complexity: 0.2 (Low)
- Estimated time: < 10 minutes

**Just do it:**
[Direct instructions for the task]

**If this turns out to be more complex:**
Come back and we'll reassess with more information.
```

**Philosophy**: Patterns are tools, not requirements. Simple tasks done simply.

## Analysis Framework

When you describe your task, I analyze it across 5 dimensions:

### 1. Task Structure
- **Fixed steps** → Sequential
- **Multiple categories** → Router
- **Independent parts** → Parallel
- **Unknown scope** → Orchestrator
- **Quality focus** → Evaluator

### 2. Complexity Score (0.0 - 1.0)
- **< 0.3** (Low): Simple, single-step task → Maybe no pattern needed
- **0.3 - 0.5** (Medium-Low): Clear steps → Sequential or Router
- **0.5 - 0.7** (Medium): Multiple components → Parallel or Sequential
- **0.7 - 0.9** (High): Complex, multi-faceted → Orchestrator
- **> 0.9** (Very High): System-level changes → Orchestrator + Evaluator

### 3. Predictability
- **Predictable subtasks** → Sequential or Parallel
- **Unpredictable subtasks** → Orchestrator
- **Known categories** → Router
- **Clear quality metrics** → Evaluator

### 4. Dependencies
- **Sequential dependencies** → Sequential
- **No dependencies** → Parallel
- **Dynamic dependencies** → Orchestrator

### 5. Success Criteria
- **Step completion** → Sequential
- **Correct routing** → Router
- **Speed/consensus** → Parallel
- **Adaptive delivery** → Orchestrator
- **Quality threshold** → Evaluator

## How to Use This Skill

### Step 1: Describe Your Task

Provide:
- What you want to accomplish
- Any known constraints
- Quality requirements
- Time/resource constraints

**Example**: "I want to build a user authentication system with login, registration, password reset, and OAuth integration."

### Step 2: Receive Analysis

I'll provide:

```markdown
## Task Analysis

### Task Summary
[Your task restated for clarity]

### Characteristics Detected
- Structure: [Fixed/Variable/Unknown]
- Complexity: [Score with reasoning]
- Subtasks: [Predictable/Dynamic]
- Dependencies: [Sequential/Independent/Mixed]

### Pattern Recommendation

**Primary Recommendation**: [Pattern Name]

**Reasoning**:
1. [Why this pattern fits]
2. [Key characteristics match]
3. [Trade-offs considered]

**Alternative Patterns**:
- [Pattern B]: Use if [condition]
- [Pattern C]: Use if [different condition]

### Execution Guidance

If you choose [Recommended Pattern]:
1. First step: [What to do first]
2. Key considerations: [What to watch for]
3. Expected outcome: [What success looks like]

### Questions to Consider
- [Question that might change recommendation]
- [Clarification that could help]
```

### Step 3: Make Your Decision

You decide:
- Accept the recommendation
- Choose an alternative
- Ask for more analysis
- Proceed without a pattern (for simple tasks)

## Pattern Selection Decision Tree

```
Is the task simple enough to do in one shot? (Complexity < 0.3?)
├─ Yes → NO PATTERN - just do it directly
└─ No → Continue analysis
         │
         Is the task about categorizing/routing different inputs?
         ├─ Yes → ROUTER pattern
         └─ No → Continue
                  │
                  Are all subtasks known upfront?
                  ├─ Yes → Do subtasks have dependencies?
                  │         ├─ Yes (must do A before B) → SEQUENTIAL pattern
                  │         │
                  │         └─ No (A and B are independent)
                  │                  │
                  │                  Want to compare approaches or split work?
                  │                  ├─ Compare → PARALLEL (Voting mode)
                  │                  └─ Split → PARALLEL (Sectioning mode)
                  │
                  └─ No (subtasks emerge during work)
                           │
                           Is it about improving existing output?
                           ├─ Yes → EVALUATOR pattern
                           └─ No → ORCHESTRATOR pattern
                                    │
                                    Need quality validation after?
                                    ├─ Yes → Add EVALUATOR at end
                                    └─ No → Orchestrator alone
```

## Critical Decision Points (Disambiguations)

### 1. Sequential vs Parallel: The Dependency Test

**Ask**: "Can I do task B without completing task A first?"

```markdown
## Dependency Analysis

Task: "Build user profile feature with upload, crop, and save"

Subtasks:
1. Design UI component
2. Create backend API
3. Set up S3 storage
4. Implement image processing

**Dependency Check:**
- UI needs API contract? → **YES, dependency exists**
- API needs S3 config? → **YES, dependency exists**
- UI and S3 setup simultaneously? → **NO, UI needs final endpoint**

**Result**: Sequential (dependencies force ordering)
**Alternative**: Define API contract FIRST, then Parallel for implementation

---

Task: "Run unit tests, integration tests, E2E tests"

**Dependency Check:**
- Unit tests need integration tests? → **NO**
- E2E needs unit tests? → **NO** (can run independently)

**Result**: Parallel (Sectioning) - all independent
```

**Rule**: If ANY subtask depends on another's OUTPUT, use Sequential. If all independent, use Parallel.

### 2. Parallel(Voting) vs Evaluator: Compare or Improve?

**Ask**: "Am I comparing different approaches OR improving a single approach?"

```markdown
## Voting vs Evaluator Decision

**Scenario A: Algorithm Selection**
"Best algorithm for user search - linear, binary, or hash?"

- Multiple approaches exist
- Need to compare and pick best
- One-time decision

**Result**: PARALLEL (Voting)
- Try all 3 approaches
- Score each on criteria
- Select winner

---

**Scenario B: Code Quality Improvement**
"Improve this API endpoint's security and performance"

- One existing implementation
- Need iterative improvement
- Clear quality thresholds to meet

**Result**: EVALUATOR
- Evaluate current state
- Provide feedback
- Apply improvements
- Re-evaluate until threshold met
```

**Key Distinction**:
- **Voting**: "Which approach is best?" (comparison)
- **Evaluator**: "How do I make this better?" (refinement)

### 3. Sequential vs Orchestrator: Known vs Discovered

**Ask**: "Do I know ALL subtasks upfront, or will I discover them?"

```markdown
## Known vs Discovered Subtasks

**Scenario A: User Authentication**
"Add JWT auth, OAuth, 2FA support"

Known upfront:
1. JWT implementation
2. OAuth integration
3. 2FA setup

But wait... during implementation:
- Need token refresh logic (discovered)
- Need rate limiting (discovered)
- Need session management (discovered)

**Result**: ORCHESTRATOR
- Initial subtasks known, but more will emerge
- Need adaptive planning

---

**Scenario B: Report Generation**
"Generate quarterly sales report"

Known upfront:
1. Fetch data
2. Calculate metrics
3. Generate charts
4. Compile PDF

No new subtasks expected.

**Result**: SEQUENTIAL
- All steps predictable
- Use gates for validation
```

**Rule**:
- Known and fixed → Sequential
- Known but will grow → Orchestrator

### 4. Complexity Score: Guide, Not Gospel

**The score is a signal, not a decision:**

```markdown
## Complexity as Secondary Factor

**High Complexity (0.8) but Simple Structure**
"Migrate 100 database tables to new schema"
- Complexity: 0.8 (lots of work)
- Structure: Repetitive (same operation 100x)
- Pattern: PARALLEL (Sectioning) - batch process

NOT Orchestrator just because complexity is high.

---

**Low Complexity (0.4) but Needs Gates**
"Add input validation to API endpoint"
- Complexity: 0.4 (straightforward)
- Structure: Needs verification at each step
- Pattern: SEQUENTIAL - validate each change

NOT "No Pattern" just because complexity is low.
```

**Priority Order**:
1. **Structure** (dependencies, predictability)
2. **Goal** (compare vs improve vs build)
3. **Complexity** (as tie-breaker)

## Pattern Combinations

Sometimes one pattern isn't enough:

### Common Combinations

**1. Router → Any Pattern**
```
Task comes in → Router classifies → Routes to appropriate pattern
```
Use when: Multiple types of tasks need handling

**2. Orchestrator → Parallel/Sequential (nested)**
```
Orchestrator decomposes → Some subtasks are parallel, some sequential
```
Use when: Complex project with mixed dependency structures

**3. Any Pattern → Evaluator (chain)**
```
Pattern completes → Evaluator validates quality → Feedback loop if needed
```
Use when: Quality assurance is critical

**4. Sequential with Parallel Steps**
```
Step 1 → Step 2 (parallel: A,B,C) → Step 3 → Step 4
```
Use when: Some steps have independent subtasks

### When NOT to Combine

- Don't add Evaluator if quality is already checked by gates (Sequential)
- Don't use Router if task type is already clear
- Don't nest Orchestrator inside Orchestrator (too complex)

## Advanced Scenarios

### Mixed Dependencies: Phased Execution

**Problem**: Some subtasks are independent AFTER a dependency is resolved.

```markdown
## Example: Backend API + Frontend + Mobile

Dependency Structure:
- Backend API: Independent (start first)
- Frontend UI: Depends on API
- Mobile App: Depends on API
- Frontend ↔ Mobile: Independent of each other

**Wrong Approach**: Pure Sequential
1. Build API
2. Build Frontend
3. Build Mobile
→ Total time: 3 units

**Right Approach**: Phased Execution
Phase 1 (Sequential): Build API (blocker)
Phase 2 (Parallel): Build Frontend AND Mobile simultaneously
→ Total time: 2 units (33% faster)
```

**Pattern**: **SEQUENTIAL with Parallel Phases**

```
[Blocker Task] → [Parallel Tasks] → [Integration]
```

**How to Identify**:
1. List all subtasks
2. Map dependencies (what blocks what?)
3. Group independent tasks after blockers
4. Execute: Blockers sequentially, then independents in parallel

**Decision Rule**:
- If dependencies exist BUT some tasks are independent after blocker → Phased Execution
- If ALL tasks are sequential → Pure Sequential
- If ALL tasks are independent → Pure Parallel

### Partial Knowledge: Discovery Likelihood

**Problem**: You know SOME subtasks, but might discover more.

**Spectrum**:
```
|--------------------|--------------------|---------------------|
Low Discovery        Medium Discovery     High Discovery
(90% known)          (60-80% known)       (<60% known)
↓                    ↓                    ↓
SEQUENTIAL           FLEXIBLE SEQUENTIAL  ORCHESTRATOR
(proceed, adjust     (plan for extras,    (expect significant
if needed)           reserve 20% buffer)  scope evolution)
```

**Assessment Questions**:
1. What percentage of work is clearly defined?
2. How likely is scope expansion?
3. How impactful would undiscovered tasks be?

**Example Assessments**:

```markdown
## Low Discovery (Use Sequential)
Task: "Add notification system - Email, SMS, Push"
- 3 known channels: 90% of work
- Possible extras: Common interface (10%)
- Impact if missed: Minor refactor
→ Use SEQUENTIAL, add tasks if discovered

## Medium Discovery (Use Flexible Sequential)
Task: "Implement payment system"
- Known: Card payment, basic flow (60%)
- Likely extras: Refunds, webhooks, fraud detection (30-40%)
- Impact if missed: Significant redesign
→ Use SEQUENTIAL with checkpoints, prepare for additions

## High Discovery (Use Orchestrator)
Task: "Modernize legacy system"
- Known: Some pain points (40%)
- Unknown: Full scope of issues (60%+)
- Impact if missed: Project failure
→ Use ORCHESTRATOR for adaptive planning
```

### External Changes vs Internal Discovery

**Two types of uncertainty**:

1. **Internal Discovery** (Orchestrator territory)
   - New subtasks emerge from doing the work
   - Technical complexity reveals hidden requirements
   - "We found out we need X while building Y"

2. **External Changes** (Requires human checkpoint)
   - Requirements change from outside
   - Business priorities shift
   - "Client changed their mind about Z"

**Handling**:
- Internal Discovery → Orchestrator (adaptive planning)
- External Changes → Sequential with Human Checkpoints
- Both → Orchestrator + User Reviews at milestones

```markdown
## Example: Legacy Refactoring with Possible Requirement Changes

"Refactor auth module, but requirements might change"

**Analysis**:
- Internal discovery likely (hidden tech debt)
- External changes possible (business priorities)

**Recommendation**: ORCHESTRATOR + User Checkpoints
- Orchestrator handles internal discoveries
- User checkpoints catch external changes
- Review at: 25%, 50%, 75% completion
```

### Unclear Quality Criteria: Prerequisite Questions

**Problem**: Evaluator pattern needs clear metrics, but user provides vague goals.

**Before recommending Evaluator, ask**:

```markdown
## Prerequisite Questions for Quality Improvement

Your goal: "Make this code better"

**I need clarity on**:

1. **What dimensions matter most?**
   - [ ] Performance (speed, memory)
   - [ ] Security (vulnerabilities, auth)
   - [ ] Readability (clean code, maintainability)
   - [ ] Test coverage
   - [ ] Documentation

2. **What are your thresholds?**
   - Performance: Target response time? (e.g., < 200ms)
   - Security: Compliance level? (e.g., OWASP Top 10)
   - Readability: Complexity score? (e.g., cyclomatic < 10)
   - Coverage: Percentage? (e.g., > 80%)

3. **What's "good enough"?**
   - Perfect score on all dimensions?
   - Meeting minimum thresholds?
   - Relative improvement? (e.g., 30% better)

4. **Constraints?**
   - Max iterations allowed?
   - Time budget?
   - Breaking changes acceptable?

**Once you provide these, I can recommend Evaluator with confidence.**

**If you can't define these**:
Consider if you need comparison (Voting) instead of improvement (Evaluator).
"I don't know what's best" → Try multiple approaches → PARALLEL (Voting)
"I want this specific thing better" → Iterative refinement → EVALUATOR
```

### User Override: When You Disagree

**Scenario**: You recommend X, user wants Y.

**Response Framework**:

```markdown
## Override Acknowledgment

You want: [Pattern Y]
My recommendation was: [Pattern X]

**Respectful pushback** (if pattern seems wrong):

"I understand you want to use [Y]. Before proceeding, consider:

- **Risk**: [What could go wrong with Y]
- **Overhead**: [Extra cost of using Y]
- **Alternative**: [Why X might be better]

If you still prefer [Y], I'll support that choice. You know your context best.

**Questions to confirm**:
- What information do you have that changes the analysis?
- Is there a specific reason Y fits better?
- Are you willing to accept the trade-offs?"

**Full support** (if pattern is reasonable):

"You chose [Y] instead of [X]. Both are valid options.

Your choice makes sense if:
- [Condition where Y works]
- [Another valid reason]

Proceeding with [Y]."

**Strong warning** (if pattern is clearly wrong):

"⚠️ Using [Y] for this task has significant risks:

- [Critical issue 1]
- [Critical issue 2]

This could result in:
- [Consequence]

I strongly recommend reconsidering. If you proceed, please be aware of these risks."
```

**Examples**:

```markdown
## Example 1: Mild Override
Task: "Simple bug fix"
My rec: No Pattern
User wants: Sequential (for learning)

Response: "Using Sequential for a simple bug fix adds overhead, but it's fine for learning purposes. Proceed."

## Example 2: Reasonable Override
Task: "Build 3 microservices"
My rec: Parallel (Sectioning)
User wants: Sequential (wants validation)

Response: "Sequential works if you want quality gates between each service. You'll trade speed for validation. Valid choice."

## Example 3: Strong Warning
Task: "Write hello world"
User wants: Orchestrator (thinks it's complex)

Response: "⚠️ Orchestrator is for complex, open-ended projects. 'Hello world' is a single line of code. Using Orchestrator here wastes resources. Please reconsider."
```

## Complete Analysis Example

### User Request
"우리 레거시 모놀리식 앱을 마이크로서비스로 분리하고 싶어요. User, Product, Order 세 개의 서비스로 나눌 계획입니다."

### Analysis

```markdown
## Task Analysis: Monolith to Microservices Migration

### Task Summary
Decompose a legacy monolithic application into 3 microservices: User Service, Product Service, and Order Service.

### Characteristics Detected
- **Structure**: Semi-fixed (3 known services, but internal details unknown)
- **Complexity**: 0.85 (High)
  - Multi-component system changes
  - Database splitting required
  - API contract design needed
  - Integration concerns
- **Subtasks**: Mixed (3 services known, but implementation details will emerge)
- **Dependencies**: Complex (services may have shared data, APIs must be coordinated)

### Pattern Recommendation

**Primary Recommendation**: 🎯 **ORCHESTRATOR** (Dynamic Task Orchestrator)

**Reasoning**:
1. **High complexity (0.85)** - Multiple services with unknown internal requirements
2. **Discovery needed** - Will find hidden dependencies during analysis
3. **Multiple specialists required** - Code analysis, architecture design, implementation, testing
4. **Adaptive planning essential** - Scope will evolve as legacy code is analyzed

**Why not other patterns?**
- ❌ Sequential: Too rigid, can't handle discovered dependencies
- ❌ Parallel: Services aren't fully independent (shared DB, APIs)
- ❌ Router: Not about categorizing, it's about building
- ✅ Evaluator: Could add after, for quality validation

**Alternative Patterns**:
- **PARALLEL (Sectioning)**: Use if services are truly independent with no shared state
  - Condition: Each service has separate database and no inter-service calls
  - Benefit: Faster execution (3 services simultaneously)
  - Risk: Integration issues discovered late

- **SEQUENTIAL + EVALUATOR**: Use if you want strict phase gates
  - Condition: Must validate each service before starting next
  - Benefit: Catch issues early
  - Risk: Slower, less adaptive

### Execution Guidance

If you choose **ORCHESTRATOR**:

1. **First step**: Analyze legacy codebase
   - Assign Code Analyzer Worker
   - Discover actual dependencies
   - Map data flows between modules

2. **Key considerations**:
   - Database splitting strategy (shared → separate)
   - API contract versioning
   - Data migration plan
   - Rollback strategy

3. **Expected workflow**:
   - Start with 3 known services
   - Likely discover 5-8 additional subtasks (shared auth, API gateway, etc.)
   - Expect 3-5 replanning cycles
   - Duration: 2-4 hours of orchestrated work

4. **Success metrics**:
   - All 3 services independently deployable
   - Integration tests passing
   - No direct database sharing
   - API contracts documented

### Questions to Consider

1. **독립성**: 세 서비스가 데이터베이스를 공유하나요, 아니면 각각 분리된 DB를 사용할 예정인가요?
   - If shared DB → Orchestrator definitely (need to plan splitting)
   - If separate DBs → Parallel might work

2. **기존 테스트**: 레거시 앱에 테스트가 있나요?
   - If yes → Use them to validate migration
   - If no → Add Test Engineer worker priority

3. **다운타임**: 마이그레이션 중 다운타임이 허용되나요?
   - If no downtime → Need more careful planning, Orchestrator essential
   - If downtime OK → Simpler migration possible

### My Recommendation

Given the complexity and need for discovery, **start with ORCHESTRATOR**.

To activate:
```
"orchestrator 패턴으로 마이크로서비스 마이그레이션 진행해주세요"
```

Or if you want quality validation at the end:
```
"orchestrator로 마이그레이션 후 evaluator로 품질 검증해주세요"
```

---

**Remember**: You know your project best. This is a recommendation based on task characteristics, but you can always choose differently if you have specific constraints or preferences.
```

## Common Scenarios and Recommendations

### Scenario 1: Bug Fix
**Task**: "로그인 페이지 버그 수정"
**Recommendation**: **SEQUENTIAL** (if multi-step) or **No pattern** (if simple)
- Analyze → Fix → Test → Document
- Clear steps, validation needed

### Scenario 2: New Feature
**Task**: "결제 시스템 추가"
**Recommendation**: **ORCHESTRATOR** (high complexity) or **SEQUENTIAL** (medium)
- Multiple unknowns (payment gateway, security, etc.)
- Will discover requirements during work

### Scenario 3: Performance Optimization
**Task**: "API 응답 속도 개선"
**Recommendation**: **EVALUATOR**
- Clear quality metric (response time)
- Iterative improvement with feedback

### Scenario 4: Code Review
**Task**: "보안 관점으로 코드 리뷰"
**Recommendation**: **PARALLEL (Voting)**
- Multiple perspectives (security, performance, maintainability)
- Consensus-based evaluation

### Scenario 5: Documentation
**Task**: "API 문서화"
**Recommendation**: **SEQUENTIAL** or **No pattern**
- Fixed steps: Analyze API → Write docs → Validate → Examples
- Low complexity, predictable

### Scenario 6: Multi-Component Build
**Task**: "React frontend + Node backend + PostgreSQL DB 앱 구축"
**Recommendation**: **PARALLEL (Sectioning)** or **ORCHESTRATOR**
- If truly independent: Parallel for speed
- If need coordination: Orchestrator for adaptation

## Limitations

This advisor:
- **Cannot execute tasks** - only recommends
- **Based on analysis** - may miss nuances you know
- **Pattern-focused** - sometimes no pattern is best
- **General guidance** - your specific context matters

## When NOT to Follow Recommendations

Override the recommendation when:
1. **You have domain expertise** that changes the analysis
2. **Specific constraints** not captured in the description
3. **Learning purposes** - want to try a specific pattern
4. **Simple task** - overhead of pattern exceeds benefit
5. **Previous experience** - know what works for your project

## Next Steps After Receiving Recommendation

1. **Accept**: Activate the recommended skill
2. **Modify**: Use alternative pattern suggested
3. **Clarify**: Ask follow-up questions
4. **Skip**: Proceed without formal pattern (simple tasks)
5. **Combine**: Use multiple patterns in sequence (advanced)

---

## Summary

The Agent Workflow Advisor helps you:
1. **Analyze** your task's characteristics
2. **Match** to optimal agent pattern
3. **Understand** the trade-offs
4. **Decide** with confidence

**Remember**: This is guidance, not a mandate. You always have the final say in which approach to use. The goal is to help you make an informed decision, not to automate the choice away.

**Start simple, add complexity only when needed.**
