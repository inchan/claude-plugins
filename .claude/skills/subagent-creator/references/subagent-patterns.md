# Subagent Patterns and Workflows

This document describes common patterns and workflows for using Claude Code subagents effectively.

## Pattern 1: Three-Stage Development Pipeline

**Source:** PubNub production workflow

### Overview
A structured pipeline with clear handoffs between planning, design, and implementation phases.

### Stages

#### Stage 1: PM-Spec
```markdown
---
name: pm-spec
description: Converts enhancement requests into structured specifications with acceptance criteria
tools: Read, Write, Grep, Glob, WebSearch
---

# Role
Product Manager - Requirements Analyst

# Responsibilities
1. Read enhancement request
2. Ask clarifying questions if needed
3. Produce structured specification with:
   - User stories
   - Acceptance criteria
   - Open questions
   - Success metrics
4. Update queue status to READY_FOR_ARCH

# Output Format
Write to `specs/{slug}.md`:
- Summary
- User stories
- Acceptance criteria
- Technical considerations
- Open questions

# Handoff
Set status in `_queue.json`:
```json
{
  "slug": "feature-name",
  "status": "READY_FOR_ARCH"
}
```
```

#### Stage 2: Architect-Review
```markdown
---
name: architect-review
description: Validates designs against constraints and produces Architecture Decision Records
tools: Read, Write, Grep, Glob, WebFetch
---

# Role
Software Architect - Design Reviewer

# Responsibilities
1. Read specification from Stage 1
2. Validate against:
   - System constraints
   - Existing architecture
   - Best practices
3. Produce ADR (Architecture Decision Record)
4. Update queue status to READY_FOR_BUILD

# Output Format
Write to `adrs/{slug}.md`:
- Context
- Decision
- Consequences
- Alternatives considered

# Handoff
Set status in `_queue.json`:
```json
{
  "slug": "feature-name",
  "status": "READY_FOR_BUILD"
}
```
```

#### Stage 3: Implementer-Tester
```markdown
---
name: implementer-tester
description: Implements code, runs tests, and updates documentation
tools: Read, Write, Edit, Bash, Grep, Glob, TodoWrite
---

# Role
Software Engineer - Implementation Specialist

# Responsibilities
1. Read spec and ADR
2. Implement feature following design
3. Run unit tests
4. Run optional UI tests
5. Update documentation
6. Update queue status to DONE

# Output Format
- Code changes in appropriate files
- Test results in `test-results/{slug}.md`
- Updated documentation

# Handoff
Set status in `_queue.json`:
```json
{
  "slug": "feature-name",
  "status": "DONE"
}
```
```

### Benefits
- Clear separation of concerns
- Human-in-the-loop at stage transitions
- Trackable status via queue file
- Auditable via spec, ADR, and test results

---

## Pattern 2: Multi-Agent Verification

**Source:** Anthropic best practices

### Overview
Use separate agents for writing, reviewing, judging, and editing.

### Workflow

```
┌─────────────┐
│   Writer    │  Implements feature
└─────┬───────┘
      │
      v
┌─────────────┐
│  Reviewer   │  Reviews implementation
└─────┬───────┘
      │
      v
┌─────────────┐
│    Judge    │  Reads code + review, decides on changes
└─────┬───────┘
      │
      v
┌─────────────┐
│   Editor    │  Makes final changes
└─────────────┘
```

### Agents

#### Writer
```markdown
---
name: feature-writer
description: Implements new features based on specifications
tools: Read, Write, Edit, Grep, Glob, TodoWrite
---

# Role
Implement features without worrying about review concerns.
Focus on functionality and correctness.

# Output
Working implementation with tests.
```

#### Reviewer
```markdown
---
name: code-reviewer
description: Reviews code for quality, security, and maintainability
tools: Read, Grep, Glob
---

# Role
Critical reviewer looking for:
- Security issues
- Performance problems
- Maintainability concerns
- Missing edge cases

# Output
Detailed review with specific line numbers and suggestions.
```

#### Judge
```markdown
---
name: review-judge
description: Evaluates code and review feedback to decide on changes
tools: Read, Grep, Glob, AskUserQuestion
---

# Role
Read both implementation and review.
Decide which feedback to address and how.

# Output
Action items prioritized by importance.
```

#### Editor
```markdown
---
name: code-editor
description: Makes surgical edits based on review feedback
tools: Read, Edit, Grep, Glob
---

# Role
Make precise edits addressing approved feedback.
Don't make unnecessary changes.

# Output
Updated code addressing review items.
```

### Benefits
- Separation prevents "rubber stamp" reviews
- Independent judgment reduces bias
- Surgical edits reduce unnecessary changes

---

## Pattern 3: Parallel Specialization

**Source:** Community best practices

### Overview
Launch multiple specialized reviewers in parallel for comprehensive analysis.

### Agents

```markdown
---
name: security-reviewer
description: Reviews code for security vulnerabilities (OWASP Top 10)
tools: Read, Grep, Glob
---
```

```markdown
---
name: performance-reviewer
description: Reviews code for performance issues and optimization opportunities
tools: Read, Grep, Glob
---
```

```markdown
---
name: style-reviewer
description: Reviews code for style consistency and readability
tools: Read, Grep, Glob
---
```

### Usage
```
Launch in parallel:
- security-reviewer on src/**/*.js
- performance-reviewer on src/**/*.js
- style-reviewer on src/**/*.js

Aggregate results for comprehensive feedback.
```

### Benefits
- Parallel execution saves time
- Specialized focus increases accuracy
- Comprehensive coverage across concerns

---

## Pattern 4: Research → Design → Implement

**Source:** Anthropic recommendations

### Overview
Use subagents early for research before making design decisions.

### Workflow

#### Phase 1: Research
```
User: "Implement user authentication"
Main: "Before deciding on approach, let's research."
     → Launch researcher subagent

Researcher:
- Searches codebase for existing auth patterns
- Checks external docs for best practices
- Identifies constraints (e.g., existing OAuth setup)

Returns: Summary of findings
```

#### Phase 2: Design
```
Main: Based on research, design the solution.
      → Launch architect subagent (optional) or do inline

Architect:
- Reviews research findings
- Proposes architecture
- Identifies integration points

Returns: Architecture decision
```

#### Phase 3: Implement
```
Main: Now implement based on design.
      → Launch implementer subagent

Implementer:
- Follows design
- Writes code
- Runs tests

Returns: Implementation
```

### Benefits
- Research prevents reinventing the wheel
- Early context preservation
- Informed decision-making

---

## Pattern 5: Hook-Based Automation

**Source:** PubNub advanced workflows

### Overview
Use hooks to automatically trigger next agent in pipeline.

### Hook Configuration

`.claude/settings.json`:
```json
{
  "hooks": {
    "SubagentStop": [
      {
        "subagent": "pm-spec",
        "command": "bash ~/.claude/hooks/trigger-architect.sh"
      },
      {
        "subagent": "architect-review",
        "command": "bash ~/.claude/hooks/trigger-implementer.sh"
      }
    ]
  }
}
```

### Hook Script Example

`~/.claude/hooks/trigger-architect.sh`:
```bash
#!/bin/bash

# Read queue status
STATUS=$(jq -r '.status' _queue.json)

if [ "$STATUS" == "READY_FOR_ARCH" ]; then
  echo "✅ Spec complete. Ready for architecture review."
  echo "📋 Next: Run /agents and select 'architect-review'"
else
  echo "⏸️  Not ready for architecture review yet."
fi
```

### Benefits
- Automated workflow progression
- Human approval at gate points
- Clear status tracking

---

## Pattern 6: Parallel Git Worktrees

**Source:** Anthropic advanced techniques

### Overview
Work on multiple features simultaneously using git worktrees.

### Setup
```bash
# Main repo
cd /project

# Create worktrees for different features
git worktree add ../project-feature-a feature-a
git worktree add ../project-feature-b feature-b
git worktree add ../project-feature-c feature-c
```

### Usage
```bash
# Terminal 1
cd ../project-feature-a
claude code
# Work on feature A with subagents

# Terminal 2
cd ../project-feature-b
claude code
# Work on feature B with subagents

# Terminal 3
cd ../project-feature-c
claude code
# Work on feature C with subagents
```

### Benefits
- True parallel development
- Independent contexts
- No blocking on long-running tasks

---

## Pattern 7: Test-Driven Development with Subagents

### Overview
Separate test writing from implementation.

### Workflow

#### Phase 1: Test Writer
```markdown
---
name: test-writer
description: Writes comprehensive test cases before implementation
tools: Read, Write, Grep, Glob
---

# Role
Write failing tests that define expected behavior.

# Output
Test files covering:
- Happy path
- Edge cases
- Error conditions
```

#### Phase 2: Implementer
```markdown
---
name: tdd-implementer
description: Implements code to pass existing tests
tools: Read, Write, Edit, Bash, Grep, Glob
---

# Role
Make tests pass with minimal code changes.

# Process
1. Run tests (should fail)
2. Implement feature
3. Run tests (should pass)
4. Refactor if needed

# Success
All tests passing.
```

#### Phase 3: Test Validator
```markdown
---
name: test-validator
description: Verifies test coverage and quality
tools: Read, Bash, Grep, Glob
---

# Role
Ensure tests are comprehensive and meaningful.

# Checks
- Coverage metrics
- Edge case coverage
- Test quality (not just assert true)
```

### Benefits
- Clearer requirements from tests
- Implementation guided by specs
- Built-in validation

---

## Pattern 8: Incremental Review Pipeline

### Overview
Review changes incrementally as they're made.

### Agents

```markdown
---
name: file-reviewer
description: Reviews individual files as they're modified
tools: Read, Grep, Glob
---

Triggered after each Edit/Write.
Provides immediate feedback.
```

```markdown
---
name: integration-reviewer
description: Reviews how changes fit together
tools: Read, Grep, Glob
---

Triggered after multiple files modified.
Checks integration points.
```

```markdown
---
name: final-reviewer
description: Comprehensive review before commit
tools: Read, Grep, Glob
---

Triggered before commit.
Full security and quality check.
```

### Benefits
- Early problem detection
- Reduced review burden at end
- Continuous quality improvement

---

## Pattern 9: Documentation-First Workflow

### Overview
Write documentation before implementation.

### Workflow

#### Phase 1: Documentation Writer
```markdown
---
name: doc-writer
description: Writes API documentation before implementation
tools: Read, Write, Grep, Glob, WebFetch
---

# Role
Write comprehensive API docs describing:
- Function signatures
- Parameters
- Return values
- Examples
- Edge cases

# Output
Documentation that serves as specification.
```

#### Phase 2: Implementation Validator
```markdown
---
name: impl-validator
description: Ensures implementation matches documentation
tools: Read, Grep, Glob
---

# Role
Verify implementation matches documented API.

# Checks
- Signature matches docs
- Behavior matches examples
- Edge cases handled
```

### Benefits
- Documentation drives design
- Implementation has clear target
- Built-in validation

---

## Pattern Selection Guide

| Use Case | Recommended Pattern |
|----------|-------------------|
| Complex feature development | Three-Stage Pipeline |
| Code review | Multi-Agent Verification |
| Comprehensive analysis | Parallel Specialization |
| Greenfield project | Research → Design → Implement |
| Automated workflows | Hook-Based Automation |
| Multiple features | Parallel Git Worktrees |
| High-quality code | Test-Driven Development |
| Continuous feedback | Incremental Review Pipeline |
| API development | Documentation-First Workflow |

---

## Combining Patterns

Patterns can be combined for maximum effectiveness:

### Example: TDD + Three-Stage Pipeline
1. PM-Spec includes test requirements
2. Architect-Review includes test architecture
3. Implementer uses TDD pattern

### Example: Parallel Specialization + Incremental Review
1. File-reviewer runs on each change
2. Parallel specialized reviewers run before commit
3. Final comprehensive review before merge

---

## Anti-Patterns to Avoid

### ❌ One Agent Does Everything
```markdown
---
name: super-agent
description: Does all development tasks
---
```
**Problem:** No specialization, poor results

**Fix:** Split into focused agents

### ❌ No Clear Handoffs
```markdown
# Agent 1 does stuff...
# Agent 2 does related stuff...
# But how do they communicate?
```
**Problem:** Lost context, duplicated work

**Fix:** Use queue files, hooks, clear status tracking

### ❌ Overlapping Responsibilities
```markdown
---
name: implementer-reviewer
description: Implements and reviews own code
---
```
**Problem:** Conflict of interest, rubber stamp reviews

**Fix:** Separate implementation and review agents

### ❌ Missing Error Handling
```markdown
# Agent assumes happy path always...
```
**Problem:** Fails on edge cases

**Fix:** Include error handling in agent prompts

---

## Resources

- [Best Practices](./best-practices.md)
- [Tool Reference](./tool-reference.md)
- [Official Subagents Documentation](https://docs.claude.com/en/docs/claude-code/sub-agents)
