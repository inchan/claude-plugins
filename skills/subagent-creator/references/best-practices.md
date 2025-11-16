# Subagent Best Practices

This document contains official best practices for creating effective Claude Code subagents, compiled from Anthropic documentation and community expertise.

## Core Design Principles

### 1. Single-Responsibility Design

Each subagent should have **one clear goal, input, output, and handoff rule**.

**Good Example:**
```markdown
---
name: code-reviewer
description: Reviews code for quality, security, and maintainability issues
---
```

**Bad Example:**
```markdown
---
name: dev-helper
description: Helps with coding tasks, reviews, debugging, and documentation
---
```

**Why:** Focused agents are more reliable, easier to maintain, and produce better results than general-purpose agents.

### 2. Permission Hygiene

Explicitly scope tools per agent. If you omit the `tools` field, subagents inherit all available tools.

**Tool Access Guidelines:**
- **PM/Architect agents**: Read-heavy permissions (Read, Grep, Glob, WebSearch)
- **Implementer agents**: Write permissions (Edit, Write, Bash)
- **Reviewer agents**: Read-only (Read, Grep, Glob)
- **Tester agents**: Execution permissions (Bash, Read)

**Example:**
```markdown
---
name: code-reviewer
description: Reviews code for quality issues
tools: Read, Grep, Glob
---
```

**Why:** Limiting tool access improves security and helps the subagent focus on relevant actions.

### 3. Write Detailed Prompts

Subagents cannot ask follow-up questions, so include all necessary context upfront.

**Include:**
- Specific responsibilities and boundaries
- Expected output format
- Success criteria
- Common edge cases to handle
- Examples of good outputs

**Example:**
```markdown
# Role
You are a security-focused code reviewer.

# Responsibilities
- Check for OWASP Top 10 vulnerabilities
- Verify input validation
- Review authentication/authorization logic

# Output Format
Provide findings in priority order:
1. Critical (security vulnerabilities)
2. High (bugs)
3. Medium (code quality)
4. Low (style)

# Success Criteria
- All security issues identified
- Clear remediation steps provided
- No false positives on standard patterns
```

### 4. Start with Claude

Anthropic's official guidance: **Generate your initial subagent with Claude, then iterate**.

**Workflow:**
1. Describe your needs to Claude: "I need a subagent that reviews API security"
2. Let Claude generate the initial subagent
3. Test it on real tasks
4. Refine based on results

**Why:** Claude understands the subagent format and best practices, making it faster to start with a generated template.

### 5. Use Subagents Early

Tell Claude to use subagents to verify details or investigate questions, especially early in a conversation.

**Benefits:**
- Preserves context in main conversation
- Enables parallel exploration
- Reduces cognitive load on main agent

**Example:**
```
"Before implementing, use a subagent to research existing authentication
patterns in the codebase."
```

## Advanced Techniques

### Parallel Processing

Launch multiple subagents concurrently for independent tasks.

**Use Cases:**
- Multiple independent research areas
- Parallel code reviews across different modules
- Concurrent testing of different components

**Limits:** Up to 10 parallel tasks supported

**Example:**
```
"Launch three subagents in parallel:
1. Research authentication patterns
2. Review database schema
3. Check API endpoint security"
```

### Hook-Based Chaining

Connect subagents via hooks for automated workflows.

**Register Events:**
- `SubagentStop`: Triggered when subagent completes
- `Stop`: Triggered at conversation end

**Example Use Case:**
```
PM-spec → (hook triggers) → Architect-review → (hook triggers) → Implementer
```

**Implementation:**
```json
// .claude/settings.json
{
  "hooks": {
    "SubagentStop": {
      "subagent": "pm-spec",
      "command": "bash ~/.claude/hooks/trigger-architect.sh"
    }
  }
}
```

### Multi-Agent Verification Workflow

Use separate Claude instances for different roles:

1. **Writer**: Implements feature
2. **Reviewer**: Reviews implementation
3. **Judge**: Reads both and decides on edits
4. **Editor**: Makes final changes

**Why:** Separation of concerns often yields better results than single-agent workflows.

## Common Patterns

### Pattern 1: Research → Plan → Implement

```
1. researcher: Explore codebase and gather context
2. architect: Design solution based on findings
3. implementer: Write code following design
```

### Pattern 2: Implement → Review → Fix

```
1. implementer: Write initial code
2. code-reviewer: Identify issues
3. implementer: Fix identified issues
```

### Pattern 3: Parallel Specialization

```
Launch concurrently:
- security-reviewer: Check for vulnerabilities
- performance-reviewer: Check for performance issues
- style-reviewer: Check code style
```

## Model Selection

Use the `model` field to optimize for different tasks:

**`haiku`**: Fast, cost-effective for simple tasks
- File searches
- Basic validation
- Quick reviews

**`sonnet`**: Balanced for most tasks (default)
- Code implementation
- Standard reviews
- General analysis

**`opus`**: Most capable for complex tasks
- Complex architecture decisions
- Deep analysis
- Creative problem-solving

**`inherit`**: Use parent conversation's model
- Maintains consistency
- Adapts to user's model choice

## Security Best Practices

### Principle of Least Privilege

Only grant necessary permissions:

```markdown
---
name: safe-reviewer
description: Reviews code without executing anything
tools: Read, Grep, Glob  # No Write, Edit, or Bash
---
```

### Scope Limitations

Limit subagent scope to specific areas:

```markdown
# Scope
You may only review files in src/api/ directory.
Do not access database credentials or secrets.
```

### Validation

Always validate subagent files before using:

```bash
python validate_subagent.py .claude/agents/my-agent.md
```

## Naming Conventions

**Good Names:**
- `code-reviewer`
- `api-security-scanner`
- `test-runner`
- `db-migration-helper`

**Bad Names:**
- `MyAgent` (use lowercase)
- `code_reviewer` (use hyphens, not underscores)
- `helper` (too generic)
- `agent-1` (not descriptive)

## Description Writing

**Action-Oriented Language:**
- ✅ "Reviews code for security vulnerabilities"
- ✅ "Use when implementing new API endpoints"
- ✅ "Helps debug production errors"
- ❌ "A helpful agent for coding"
- ❌ "General purpose assistant"

**Specificity:**
- ✅ "Validates GraphQL schema changes against existing queries"
- ❌ "Helps with GraphQL"

## Testing Subagents

1. **Start Simple**: Test on straightforward examples first
2. **Increase Complexity**: Gradually add edge cases
3. **Monitor Failures**: Note when subagent struggles
4. **Iterate Quickly**: Update and re-test immediately
5. **Document Limitations**: Note what the subagent cannot handle

## Maintenance

### Version Control

Keep subagents in version control:
- Project subagents: Commit `.claude/agents/` to git
- User subagents: Backup `~/.claude/agents/` separately

### Documentation

Document subagents in your project:
```markdown
# Our Subagents

## code-reviewer
- **Purpose**: Reviews PRs for security and quality
- **When to use**: Before merging any PR
- **Tools**: Read, Grep, Glob
```

### Iteration

Based on usage:
1. Track success/failure rate
2. Identify common failure patterns
3. Update prompts to address failures
4. Add examples of correct behavior

## Common Mistakes

### ❌ Too Broad Scope
```markdown
description: Helps with development tasks
```
**Fix:** Be specific about what tasks

### ❌ Missing Context
```markdown
# Role
Review code.
```
**Fix:** Add detailed instructions, examples, success criteria

### ❌ Inheriting All Tools Unintentionally
```markdown
---
name: reviewer
# Missing tools field - inherits ALL tools including Bash, Edit, Write!
---
```
**Fix:** Explicitly list tools

### ❌ Vague Names
```markdown
name: helper
```
**Fix:** Use descriptive names like `api-security-reviewer`

### ❌ No Examples
The prompt has no examples of good output.

**Fix:** Include 1-2 examples of expected output

## Resources

- [Official Subagents Documentation](https://docs.claude.com/en/docs/claude-code/sub-agents)
- [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
- [Subagent Patterns Reference](./subagent-patterns.md)
- [Tool Reference](./tool-reference.md)
