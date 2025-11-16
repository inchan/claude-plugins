# Slash Command Best Practices

This reference document provides comprehensive best practices for creating effective Claude Code slash commands, based on official documentation and real-world usage patterns.

## Table of Contents

1. [Command Design Principles](#command-design-principles)
2. [File Organization](#file-organization)
3. [YAML Frontmatter](#yaml-frontmatter)
4. [Argument Handling](#argument-handling)
5. [Tool Permissions](#tool-permissions)
6. [Command Naming](#command-naming)
7. [Content Structure](#content-structure)
8. [Advanced Features](#advanced-features)
9. [Common Pitfalls](#common-pitfalls)

## Command Design Principles

### Single Responsibility

Each command should do one thing well. Avoid creating catch-all commands.

✅ **Good:**
```
/optimize - Optimize code for performance
/review-pr - Review pull request changes
/fix-bug - Debug and fix a specific issue
```

❌ **Bad:**
```
/dev-helper - Does everything (coding, reviewing, debugging, docs)
```

### Action-Oriented

Commands should be verbs that clearly indicate what action will be taken.

✅ **Good:**
- `/refactor` - Refactor selected code
- `/generate-tests` - Generate unit tests
- `/analyze-performance` - Analyze code performance

❌ **Bad:**
- `/helper` - Too vague
- `/code` - Not action-oriented
- `/stuff` - Meaningless

### Discoverable

Use descriptive names and include good descriptions in frontmatter to help users find your command.

```markdown
---
description: Refactor code to improve readability and maintainability
---
```

## File Organization

### Location Strategy

**Project Commands** (`.claude/commands/`)
- Team-shared commands
- Project-specific workflows
- Version controlled
- Committed to repository

**User Commands** (`~/.claude/commands/`)
- Personal commands
- Cross-project utilities
- Not shared with team
- Personal workflows

### Namespacing

Organize related commands in subdirectories for better structure:

```
.claude/commands/
├── dev/
│   ├── review.md      # /review (project:dev)
│   ├── test.md        # /test (project:dev)
│   └── deploy.md      # /deploy (project:dev)
├── git/
│   ├── commit.md      # /commit (project:git)
│   └── pr.md          # /pr (project:git)
└── optimize.md        # /optimize
```

**Benefits:**
- Logical grouping
- Namespace indication in autocomplete
- Easier maintenance
- Clear ownership

## YAML Frontmatter

### Description Field

Provide a clear, concise description that appears in autocomplete and help.

```markdown
---
description: Brief description of what this command does
---
```

**Best Practices:**
- Keep under 80 characters
- Be specific about the action
- Include key behavior if non-obvious
- Defaults to first line of content if omitted

### Allowed Tools

Specify which tools the command can use. This restricts Claude's permissions when executing the command.

```markdown
---
allowed-tools: Bash(git:*), Read, Grep
---
```

**Best Practices:**
- Only grant necessary tools (principle of least privilege)
- Use patterns for specific tool scopes: `Bash(git:*)` allows only git commands
- Inherit from conversation if omitted
- Be explicit for security-sensitive commands

**Common Patterns:**
```markdown
# Read-only analysis
allowed-tools: Read, Grep, Glob

# Git operations
allowed-tools: Bash(git:*), Read

# Code modification
allowed-tools: Read, Edit, Write

# Full development
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, TodoWrite
```

### Argument Hint

Show users what arguments your command expects:

```markdown
---
argument-hint: [file-path]
---
```

**Examples:**
- `[message]` - Single argument
- `[source] [dest]` - Multiple arguments
- `[issue-number]` - Specific format
- `[options]` - Variable arguments

### Model Override

Specify a different model for this command:

```markdown
---
model: claude-3-5-haiku-20241022
---
```

**Use Cases:**
- Haiku for simple, fast commands (formatting, linting)
- Sonnet for balanced performance (default)
- Opus for complex reasoning (architecture decisions)

### Disable Model Invocation

Prevent automatic execution via SlashCommand tool:

```markdown
---
disable-model-invocation: false
---
```

**When to use:**
- Commands that require manual user confirmation
- Commands with side effects
- Debugging or experimental commands

## Argument Handling

### $ARGUMENTS - Catch All

Use `$ARGUMENTS` to capture everything after the command name:

```markdown
---
argument-hint: [message]
---

Create a git commit with message: "$ARGUMENTS"

!git add .
!git commit -m "$ARGUMENTS"
```

**Usage:**
```
> /commit Fixed bug in user authentication
```

### Positional Arguments

Use `$1`, `$2`, etc. for structured multi-parameter commands:

```markdown
---
argument-hint: [source] [destination]
---

Move file from $1 to $2 with validation.

Steps:
1. Verify $1 exists
2. Check $2 location is valid
3. Move $1 to $2
4. Update references
```

**Usage:**
```
> /move-file src/old.js src/new.js
```

**Benefits:**
- Named parameters
- Default values possible
- Better validation
- Clearer intent

### Default Values

Provide defaults for optional arguments:

```markdown
Analyze performance with depth: ${1:-shallow}

If depth is "deep", run comprehensive analysis.
Otherwise, run quick analysis.
```

## Tool Permissions

### Read-Only Commands

For analysis and review:

```markdown
---
allowed-tools: Read, Grep, Glob
---

Analyze codebase for security vulnerabilities
```

### Modification Commands

For editing and refactoring:

```markdown
---
allowed-tools: Read, Write, Edit, Grep, Glob
---

Refactor code to improve performance
```

### Bash Execution Commands

For running scripts and tools:

```markdown
---
allowed-tools: Bash, Read
---

!npm run test
!npm run build
```

### Specific Tool Scoping

Restrict Bash to specific commands:

```markdown
---
allowed-tools: Bash(git:*), Bash(npm:*), Read
---

!git status
!npm test
```

**Security Benefits:**
- Prevents accidental destructive operations
- Limits blast radius
- Clear permission boundaries
- Easier auditing

## Command Naming

### Naming Conventions

- **Lowercase only:** `review-pr` not `ReviewPR`
- **Hyphens for spaces:** `fix-bug` not `fix_bug` or `fixBug`
- **Verb-first:** `generate-tests` not `test-generator`
- **Descriptive:** `optimize-images` not `opt-img`

### Length Guidelines

- **Minimum:** 2 characters (practical minimum is 3-4)
- **Recommended:** 4-15 characters
- **Maximum:** 50 characters

### Examples

✅ **Good Names:**
```
/review
/fix-bug
/generate-docs
/analyze-perf
/refactor-component
```

❌ **Bad Names:**
```
/r (too short)
/review_pull_request (underscores)
/ReviewCode (uppercase)
/do-a-thing (vague)
```

## Content Structure

### Template Structure

```markdown
---
description: Brief description
allowed-tools: Tool1, Tool2
argument-hint: [args]
---

# Command: /command-name

Brief overview of what this command does.

## Process

1. First step
2. Second step
3. Third step

## Guidelines

- Guideline 1
- Guideline 2

## Examples

Example usage or output format.
```

### Multi-Step Workflows

For complex commands with multiple phases:

```markdown
---
description: Review pull request with comprehensive checks
---

# PR Review Workflow

Review the pull request systematically.

## Phase 1: Understanding
1. Read PR description and related issues
2. Understand the change intent
3. Identify affected areas

## Phase 2: Code Review
1. Check code quality and style
2. Identify potential bugs
3. Verify error handling
4. Check test coverage

## Phase 3: Testing
1. Verify tests pass
2. Check edge cases
3. Review test quality

## Phase 4: Feedback
1. Summarize findings
2. Prioritize issues (critical, major, minor)
3. Suggest improvements
```

### Prompt Expansion

For frequently used long prompts:

```markdown
---
description: Apply comprehensive code review checklist
---

Review this code with the following criteria:

**Code Quality:**
- Readability and maintainability
- Proper naming conventions
- Appropriate abstraction levels
- DRY principle adherence

**Correctness:**
- Logic errors
- Edge cases handling
- Error handling
- Input validation

**Performance:**
- Time complexity
- Space complexity
- Resource usage
- Caching opportunities

**Security:**
- Input sanitization
- SQL injection prevention
- XSS prevention
- Authentication/authorization

**Testing:**
- Test coverage
- Test quality
- Edge case testing

Provide specific, actionable feedback with examples.
```

## Advanced Features

### Bash Execution

Include live command output in context using `!` prefix:

```markdown
---
allowed-tools: Bash(git:*)
---

Review recent changes:

!git status
!git diff HEAD~5

Based on the above output, analyze the changes.
```

**Requirements:**
- Must have `allowed-tools: Bash` or pattern in frontmatter
- Output is included in Claude's context
- Use for dynamic context gathering

### File References

Include specific file contents with `@` prefix:

```markdown
Review the implementation in @src/auth.js against
the API specification in @docs/api.md
```

**Benefits:**
- Precise file targeting
- Clear dependencies
- Better context control

### Extended Thinking

Trigger deeper reasoning for complex tasks:

```markdown
---
description: Design system architecture with deep analysis
---

<extended_thinking>
Design a scalable architecture for this feature.
Consider trade-offs, alternatives, and long-term maintenance.
</extended_thinking>
```

**When to use:**
- Architecture decisions
- Complex refactoring
- Algorithm design
- Security analysis

### Combining Features

Powerful commands combine multiple features:

```markdown
---
description: Comprehensive PR review with context
allowed-tools: Bash(git:*), Read, Grep, Glob
argument-hint: [pr-number]
---

# PR Review: #$ARGUMENTS

## 1. Gather Context

!git log -10 --oneline
!git diff main...HEAD

## 2. Analyze Changed Files

Review all files in the diff output above.

## 3. Check Tests

!npm test

## 4. Review Specific Files

For key files mentioned in diff, read with @ syntax:
@src/main.js
@tests/main.test.js

## 5. Provide Feedback

Comprehensive review based on all gathered context.
```

## Common Pitfalls

### Pitfall 1: Too Generic

❌ **Problem:**
```markdown
# /help

Help with coding tasks
```

**Why it's bad:** No clear action, duplicates Claude's existing functionality

✅ **Solution:**
```markdown
# /analyze-deps

Analyze project dependencies for security vulnerabilities and updates
```

### Pitfall 2: Missing Tool Permissions

❌ **Problem:**
```markdown
---
description: Run tests
---

!npm test
```

**Why it's bad:** Missing `allowed-tools: Bash` - command will fail

✅ **Solution:**
```markdown
---
description: Run tests
allowed-tools: Bash(npm:*)
---

!npm test
```

### Pitfall 3: Argument Confusion

❌ **Problem:**
```markdown
Move $ARGUMENTS from old location to new location
```

**Why it's bad:** `$ARGUMENTS` captures all arguments as one string - can't split

✅ **Solution:**
```markdown
---
argument-hint: [source] [destination]
---

Move $1 to $2
```

### Pitfall 4: Over-Permissive Tools

❌ **Problem:**
```markdown
---
allowed-tools: Bash, Write, Edit, Read, Grep, Glob, WebFetch, Task
---

Format code
```

**Why it's bad:** Grants unnecessary permissions for a simple task

✅ **Solution:**
```markdown
---
allowed-tools: Read, Edit
---

Format code following project style guide
```

### Pitfall 5: No Description

❌ **Problem:**
```markdown
# /optimize

Optimize stuff
```

**Why it's bad:** Unclear what gets optimized, hard to discover

✅ **Solution:**
```markdown
---
description: Optimize code performance by analyzing bottlenecks and applying improvements
---

# /optimize

Analyze code performance...
```

### Pitfall 6: Hardcoded Values

❌ **Problem:**
```markdown
Deploy to production server at 192.168.1.100
```

**Why it's bad:** Not reusable, hardcoded environment

✅ **Solution:**
```markdown
---
argument-hint: [environment]
---

Deploy to $1 environment (dev/staging/production)
```

## Summary Checklist

Before finalizing your command:

- [ ] Name is lowercase with hyphens
- [ ] Description is clear and concise
- [ ] Only necessary tools are allowed
- [ ] Arguments are clearly documented
- [ ] Content is well-structured
- [ ] No TODOs or placeholders remain
- [ ] Tested with real usage
- [ ] Follows single responsibility principle
- [ ] Security implications considered
- [ ] Validated with `validate_command.py`

## Additional Resources

- [Official Slash Commands Documentation](https://docs.claude.com/en/docs/claude-code/slash-commands)
- [Common Workflows](https://docs.claude.com/en/docs/claude-code/common-workflows)
- [Tool Permissions Guide](https://docs.claude.com/en/docs/claude-code/settings)
