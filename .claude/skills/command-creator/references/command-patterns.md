# Slash Command Patterns

This reference document provides proven patterns for different types of slash commands, with real-world examples and use cases.

## Table of Contents

1. [Simple Action Pattern](#simple-action-pattern)
2. [Workflow Pattern](#workflow-pattern)
3. [Prompt Expansion Pattern](#prompt-expansion-pattern)
4. [Agent Caller Pattern](#agent-caller-pattern)
5. [Context Gatherer Pattern](#context-gatherer-pattern)
6. [Interactive Pattern](#interactive-pattern)
7. [Batch Processing Pattern](#batch-processing-pattern)
8. [Anti-Patterns](#anti-patterns)

## Simple Action Pattern

**Use When:** Command performs a single, focused action

**Characteristics:**
- One primary task
- Minimal steps
- Clear input/output
- Quick execution

### Example 1: Format Code

```markdown
---
description: Format code using project style guide
allowed-tools: Read, Edit
---

Format the code following the project's ESLint and Prettier configuration.

1. Read current file
2. Apply formatting rules
3. Save formatted code
4. Report changes made
```

**Usage:**
```
> /format
```

### Example 2: Run Tests

```markdown
---
description: Run project test suite
allowed-tools: Bash(npm:*), Bash(yarn:*)
---

!npm test

Report test results and any failures.
```

**Usage:**
```
> /test
```

### Example 3: Generate Docs

```markdown
---
description: Generate API documentation from code comments
allowed-tools: Read, Write, Bash(npx:*)
---

Generate comprehensive API documentation:

1. Extract JSDoc comments
2. Generate markdown documentation
3. Save to docs/ directory
4. Update table of contents
```

**Usage:**
```
> /docs
```

### When to Use

- Single-purpose utilities
- Frequently used shortcuts
- Simple transformations
- Quick checks

### Template Structure

```markdown
---
description: One-line description of the action
allowed-tools: Minimal tool set
---

[Action verb] [what] with [how]

1. Step 1
2. Step 2
3. Report result
```

## Workflow Pattern

**Use When:** Command orchestrates multiple steps in a sequence

**Characteristics:**
- Multiple phases
- Each phase has clear output
- Sequential dependencies
- Complex decision making

### Example 1: PR Review

```markdown
---
description: Comprehensive pull request review
allowed-tools: Bash(git:*), Read, Grep, Glob
argument-hint: [pr-number]
---

# PR Review Workflow: #$ARGUMENTS

## Phase 1: Context Gathering
!git fetch origin pull/$ARGUMENTS/head:pr-$ARGUMENTS
!git checkout pr-$ARGUMENTS
!git diff main...HEAD

Review the diff output to understand changes.

## Phase 2: Code Analysis
For each changed file:
1. Read the file
2. Check code quality
3. Identify potential issues
4. Verify tests exist

## Phase 3: Security Check
Review for common vulnerabilities:
- SQL injection risks
- XSS vulnerabilities
- Authentication issues
- Data validation

## Phase 4: Testing
!npm test
Verify all tests pass.

## Phase 5: Summary
Provide structured feedback:
1. Summary of changes
2. Critical issues (must fix)
3. Suggestions (should fix)
4. Observations (nice to have)
```

**Usage:**
```
> /review-pr 123
```

### Example 2: Feature Implementation

```markdown
---
description: Implement new feature following project standards
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, TodoWrite
argument-hint: [feature-name]
---

# Implement Feature: $ARGUMENTS

## Step 1: Planning
1. Review existing code structure
2. Identify affected files
3. Plan implementation approach
4. Create TODO list

## Step 2: Implementation
1. Create necessary files
2. Implement core functionality
3. Add error handling
4. Update related components

## Step 3: Testing
1. Write unit tests
2. Write integration tests
3. Test edge cases

## Step 4: Documentation
1. Add inline comments
2. Update README
3. Add usage examples

## Step 5: Verification
!npm test
!npm run lint
Ensure everything passes.
```

**Usage:**
```
> /implement user-authentication
```

### When to Use

- Multi-step processes
- Complex decision trees
- Quality assurance workflows
- Release procedures

### Template Structure

```markdown
---
description: Workflow description with outcome
allowed-tools: Comprehensive tool set
---

# Workflow: [Name]

## Phase 1: [Name]
[Steps and decisions]

## Phase 2: [Name]
[Steps and decisions]

## Phase N: [Name]
[Steps and decisions]

## Summary
[Final report format]
```

## Prompt Expansion Pattern

**Use When:** Frequently used long prompts need a shortcut

**Characteristics:**
- Detailed instructions
- Consistent criteria
- Frequently repeated
- No dynamic input needed

### Example 1: Code Review Checklist

```markdown
---
description: Apply comprehensive code review checklist
---

Review this code against all criteria below. Provide specific, actionable feedback.

## Code Quality
- [ ] Follows naming conventions
- [ ] Proper abstraction levels
- [ ] DRY principle applied
- [ ] SOLID principles followed
- [ ] Appropriate comments
- [ ] No code smells

## Correctness
- [ ] Logic is correct
- [ ] Edge cases handled
- [ ] Error handling present
- [ ] Input validation
- [ ] Output validation
- [ ] No race conditions

## Performance
- [ ] Time complexity acceptable
- [ ] Space complexity acceptable
- [ ] No unnecessary operations
- [ ] Appropriate data structures
- [ ] Caching where beneficial
- [ ] Resource cleanup

## Security
- [ ] Input sanitized
- [ ] No SQL injection risks
- [ ] No XSS vulnerabilities
- [ ] Authentication checked
- [ ] Authorization verified
- [ ] Secrets not hardcoded

## Testing
- [ ] Unit tests present
- [ ] Integration tests present
- [ ] Edge cases tested
- [ ] Error cases tested
- [ ] Mocks appropriate
- [ ] Test coverage adequate

## Maintainability
- [ ] Code is readable
- [ ] Complexity is low
- [ ] Documentation complete
- [ ] Dependencies minimal
- [ ] Versioning appropriate

For each failed check, provide:
1. Specific location
2. Why it's an issue
3. How to fix it
4. Example if helpful
```

**Usage:**
```
> /checklist
```

### Example 2: Debugging Protocol

```markdown
---
description: Systematic debugging approach
allowed-tools: Read, Bash, Grep, Glob
argument-hint: [issue-description]
---

# Debug Issue: $ARGUMENTS

Follow this systematic debugging protocol:

## 1. Reproduce
- Identify exact steps to reproduce
- Note environment details
- Capture error messages
- Document expected vs actual behavior

## 2. Isolate
- Binary search the problem area
- Identify the smallest reproducible case
- Remove unrelated code
- Test in isolation

## 3. Hypothesize
- Form theories about root cause
- List possible causes
- Rank by likelihood
- Identify tests for each theory

## 4. Test
- Test most likely hypothesis first
- Use scientific method
- Change one variable at a time
- Document results

## 5. Fix
- Implement minimal fix
- Verify fix works
- Add regression test
- Document solution

## 6. Verify
- Test original issue
- Test edge cases
- Check for side effects
- Review related code

Report findings at each stage before proceeding.
```

**Usage:**
```
> /debug Login button not working
```

### When to Use

- Repeated detailed instructions
- Standard operating procedures
- Quality checklists
- Methodologies

### Template Structure

```markdown
---
description: What the expanded prompt does
---

# Detailed Instructions

[Comprehensive criteria, steps, or guidelines]

[Expected output format]
```

## Agent Caller Pattern

**Use When:** Command should delegate to a specialized subagent

**Characteristics:**
- Invokes Task tool with specific subagent
- Passes context to agent
- Clear delegation boundary
- Returns agent results

### Example 1: Security Analysis

```markdown
---
description: Run security vulnerability analysis
---

Launch security analysis using specialized agent:

Use the Task tool to launch the security-scanner subagent with the following context:

**Scope:** Entire codebase
**Focus Areas:**
- Authentication and authorization
- Input validation
- Data sanitization
- Secrets management
- API security

**Deliverable:**
Comprehensive security report with:
1. Critical vulnerabilities (CVSS 7.0+)
2. Medium-risk issues
3. Best practice recommendations
4. Remediation steps
```

**Usage:**
```
> /security-scan
```

### Example 2: Performance Audit

```markdown
---
description: Comprehensive performance analysis
argument-hint: [component]
---

# Performance Audit: $ARGUMENTS

Delegate to performance-analyzer subagent:

**Target:** $ARGUMENTS component
**Metrics:**
- Time complexity analysis
- Space complexity analysis
- Runtime profiling
- Memory usage
- Network calls
- Rendering performance

**Output:**
1. Performance bottlenecks
2. Optimization opportunities
3. Benchmark comparisons
4. Implementation recommendations
```

**Usage:**
```
> /perf-audit UserDashboard
```

### Example 3: Refactoring Plan

```markdown
---
description: Generate refactoring plan with architect agent
allowed-tools: Task
argument-hint: [target]
---

# Refactoring Plan: $ARGUMENTS

Use Task tool to launch architect subagent:

**Analysis Target:** $ARGUMENTS
**Requirements:**
1. Current architecture analysis
2. Code smell identification
3. Dependency mapping
4. Refactoring opportunities

**Deliverables:**
- Architecture diagram (before/after)
- Step-by-step refactoring plan
- Risk assessment
- Migration strategy
```

**Usage:**
```
> /refactor-plan authentication-module
```

### When to Use

- Specialized expertise needed
- Long-running analysis
- Isolated responsibility
- Reusable agent exists

### Template Structure

```markdown
---
description: What the agent will do
allowed-tools: Task
---

# [Task Name]

Use the Task tool to launch [subagent-name] with:

**Context:**
[What the agent needs to know]

**Requirements:**
[What the agent should do]

**Deliverables:**
[Expected output format]
```

## Context Gatherer Pattern

**Use When:** Need to collect information before main task

**Characteristics:**
- Gathers dynamic context
- Uses bash execution
- Provides context to Claude
- Minimal processing

### Example 1: Git Status Review

```markdown
---
description: Review current git status and recent changes
allowed-tools: Bash(git:*)
---

# Git Status Review

Gather current repository state:

!git status
!git log --oneline -10
!git diff --stat HEAD~5
!git branch -vv

Based on the above information:
1. Summarize current changes
2. Identify uncommitted work
3. Note branch status
4. Suggest next actions
```

**Usage:**
```
> /git-status
```

### Example 2: Dependency Check

```markdown
---
description: Analyze project dependencies
allowed-tools: Bash(npm:*), Read
---

# Dependency Analysis

!npm outdated
!npm audit

@package.json

Review the dependency information:
1. List outdated packages
2. Security vulnerabilities
3. Update recommendations
4. Breaking change warnings
```

**Usage:**
```
> /deps
```

### When to Use

- Dynamic system state needed
- Live command output required
- Real-time information gathering
- Environmental context important

### Template Structure

```markdown
---
description: What context is gathered
allowed-tools: Bash with specific patterns
---

# Context Gathering

!command1
!command2
@file1

Based on the above:
[Analysis or recommendations]
```

## Interactive Pattern

**Use When:** Command needs user decisions during execution

**Characteristics:**
- Uses AskUserQuestion
- Progressive disclosure
- Decision points
- Adaptive behavior

### Example 1: Smart Commit

```markdown
---
description: Interactive git commit with smart suggestions
allowed-tools: Bash(git:*), AskUserQuestion
---

# Smart Commit

!git status
!git diff --staged

Based on the changes, I'll suggest commit messages.

Use AskUserQuestion to ask:
- Commit type (feat/fix/docs/refactor)
- Affected components
- Breaking changes?

Generate commit message following conventional commits.
Confirm with user before committing.
```

**Usage:**
```
> /smart-commit
```

### Example 2: Guided Refactoring

```markdown
---
description: Interactive code refactoring
allowed-tools: Read, Edit, AskUserQuestion
---

# Guided Refactoring

1. Analyze current code
2. Identify refactoring opportunities
3. Use AskUserQuestion to present options:
   - Which pattern to apply?
   - Aggressive or conservative?
   - Create new files or modify existing?

4. Implement chosen approach
5. Confirm changes with user
```

**Usage:**
```
> /guided-refactor
```

### When to Use

- Multiple valid approaches
- User preferences matter
- Decision points exist
- Confirmation needed

### Template Structure

```markdown
---
description: Interactive task description
allowed-tools: Including AskUserQuestion
---

# Interactive Workflow

1. Analyze situation
2. Use AskUserQuestion for decision
3. Execute based on choice
4. Confirm results
```

## Batch Processing Pattern

**Use When:** Operating on multiple files or items

**Characteristics:**
- Iterates over collection
- Consistent transformation
- Progress tracking
- Error handling

### Example 1: Batch Rename

```markdown
---
description: Rename files following naming convention
allowed-tools: Read, Write, Bash, Grep, Glob
argument-hint: [pattern]
---

# Batch Rename: $ARGUMENTS

1. Find all files matching $ARGUMENTS
2. For each file:
   - Check current name
   - Generate new name (following convention)
   - Rename file
   - Update imports/references
3. Report changes made
```

**Usage:**
```
> /batch-rename *.test.js
```

### Example 2: Update License Headers

```markdown
---
description: Add or update license headers in source files
allowed-tools: Read, Edit, Glob
---

# Update License Headers

1. Glob for all source files (*.js, *.ts, *.jsx, *.tsx)
2. For each file:
   - Read current header
   - Add/update license header
   - Preserve existing code
3. Track: updated, skipped, errors
4. Summary report
```

**Usage:**
```
> /update-licenses
```

### When to Use

- Multiple similar items
- Consistent transformation
- Bulk operations
- Migration tasks

### Template Structure

```markdown
---
description: Batch operation description
allowed-tools: Read, Write, Edit, Glob
---

# Batch Processing

1. Find items to process
2. For each item:
   - Process item
   - Handle errors
   - Track progress
3. Summary report
```

## Anti-Patterns

### Anti-Pattern 1: Swiss Army Knife

❌ **Problem:**
```markdown
---
description: Do anything development-related
---

Help with development tasks. Can:
- Review code
- Write tests
- Debug issues
- Optimize performance
- Write documentation
- Deploy code
```

**Why it's bad:** No focus, unclear when to use, defeats purpose of commands

✅ **Solution:** Create separate focused commands

### Anti-Pattern 2: Mega-Prompt

❌ **Problem:**
```markdown
First analyze the entire codebase, then review all dependencies,
then check for security issues, then optimize performance, then
generate documentation, then create tests, then refactor everything,
then deploy to production...
```

**Why it's bad:** Too many responsibilities, likely to fail, hard to debug

✅ **Solution:** Break into workflow with clear phases or separate commands

### Anti-Pattern 3: Hidden Behavior

❌ **Problem:**
```markdown
---
description: Format code
---

Format code and also run tests and push to remote and deploy to staging.
```

**Why it's bad:** Description doesn't match behavior, unexpected side effects

✅ **Solution:** Be explicit about all actions, or create workflow with clear steps

### Anti-Pattern 4: No Error Handling

❌ **Problem:**
```markdown
!git push origin main
!npm publish

Done!
```

**Why it's bad:** No validation, no error handling, assumes success

✅ **Solution:**
```markdown
1. Verify git status is clean
2. Attempt git push, handle failures
3. If push succeeds, attempt npm publish
4. Report results and any errors
```

### Anti-Pattern 5: Hardcoded Paths

❌ **Problem:**
```markdown
Read /Users/john/project/src/main.js
```

**Why it's bad:** Not portable, won't work for other users

✅ **Solution:**
```markdown
Read src/main.js  # Relative to project root
```

## Pattern Selection Guide

```
Need single, focused action?
  → Simple Action Pattern

Need multiple coordinated steps?
  → Workflow Pattern

Repeat same detailed prompt often?
  → Prompt Expansion Pattern

Have specialized subagent for this?
  → Agent Caller Pattern

Need live system information?
  → Context Gatherer Pattern

Require user decisions?
  → Interactive Pattern

Operating on many items?
  → Batch Processing Pattern
```

## Combining Patterns

Powerful commands often combine patterns:

```markdown
---
description: Interactive PR creation with checks
allowed-tools: Bash(git:*), AskUserQuestion, Task
---

# Create PR Workflow

## 1. Context Gathering (Context Gatherer Pattern)
!git status
!git diff main...HEAD

## 2. Interactive Questions (Interactive Pattern)
Use AskUserQuestion:
- PR title?
- Type (feat/fix/docs)?
- Breaking changes?

## 3. Validation (Workflow Pattern)
- Run tests
- Run linter
- Check for merge conflicts

## 4. Specialized Review (Agent Caller Pattern)
Launch code-reviewer subagent for final check

## 5. Create PR (Simple Action Pattern)
!gh pr create --title "$TITLE" --body "$BODY"
```

This combines multiple patterns for a comprehensive solution.

## Summary

Choose the right pattern based on your command's:
- Complexity (simple vs multi-step)
- Interaction needs (automated vs interactive)
- Scope (single file vs batch)
- Specialization (general vs expert)

Well-designed commands follow these patterns consistently and predictably.
