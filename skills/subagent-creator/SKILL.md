---
name: subagent-creator
description: Create, modify, and manage Claude Code subagents. Use when users request to create new specialized agents, update existing agents, or need templates for common agent patterns. Also use when agents or other skills need to automatically generate subagents for specific domains.
---

# Subagent Creator

## Overview

This skill enables creation and management of Claude Code subagents - specialized AI agents with focused responsibilities, custom tool permissions, and domain-specific expertise. Subagents extend Claude Code's capabilities through modular, reusable agent definitions.

## When to Use This Skill

Invoke this skill when:
- User requests: "Create a subagent for X"
- User asks to modify existing subagent
- User needs subagent templates for common patterns (reviewer, implementer, etc.)
- Another skill/agent needs to automatically generate a specialized subagent
- User asks about subagent best practices or patterns

## Quick Start

### Creating a New Subagent

Use the initialization script for fastest results:

```bash
python scripts/init_subagent.py my-subagent "Description of when to use" --location project
```

**Options:**
- `--tools "Read,Grep,Glob"` - Specify allowed tools (comma-separated)
- `--model sonnet|opus|haiku|inherit` - Choose model
- `--location project|user` - Where to save (.claude/agents/ or ~/.claude/agents/)
- `--template basic|code-reviewer|debugger|architect|implementer|researcher|tester` - Use template

**Example:**
```bash
# Create API security reviewer from template
python scripts/init_subagent.py api-security-reviewer \
  "Reviews API endpoints for security vulnerabilities" \
  --template code-reviewer \
  --tools "Read,Grep,Glob" \
  --location project
```

### Validating a Subagent

After creating or modifying:

```bash
python scripts/validate_subagent.py .claude/agents/my-subagent.md
```

### Using Templates

Seven pre-built templates available in `assets/templates/`:

1. **basic.md** - Empty template with structure
2. **code-reviewer.md** - Code review specialist
3. **debugger.md** - Bug diagnosis and fixing
4. **architect.md** - System design and architecture decisions
5. **implementer.md** - Feature implementation
6. **researcher.md** - Codebase and technology research
7. **tester.md** - Testing and validation

Templates provide complete, production-ready subagent definitions that can be used as-is or customized.

## Core Workflows

### Workflow 1: Creating From Scratch

```
1. User requests: "Create a subagent that X"
2. Ask clarifying questions:
   - What should the subagent do specifically?
   - What tools does it need?
   - Should it be read-only or have write access?
3. Use init_subagent.py script with appropriate template
4. Customize the generated file based on requirements
5. Validate with validate_subagent.py
6. Inform user where file was created
```

**Example Conversation:**
```
User: "Create a subagent for GraphQL schema validation"

Claude: I'll create a GraphQL schema validator subagent. A few questions:
1. Should it only read and validate schemas, or also suggest fixes?
2. Does it need to check against existing queries?
3. Should it use the code-reviewer template as a base?

User: It should read and validate, checking against existing queries.

Claude: Perfect! I'll create it now.
```

```bash
python scripts/init_subagent.py graphql-validator \
  "Validates GraphQL schema changes against existing queries" \
  --template code-reviewer \
  --tools "Read,Grep,Glob" \
  --location project
```

Then customize the generated file to add GraphQL-specific validation logic.

### Workflow 2: Modifying Existing Subagent

```
1. Read current subagent file
2. Identify what needs to change:
   - Update description?
   - Add/remove tools?
   - Change model?
   - Update system prompt?
3. Make targeted edits
4. Validate with validate_subagent.py
5. Confirm changes with user
```

### Workflow 3: Choosing the Right Template

**Decision Tree:**

```
Need to review code without modifying?
  → Use code-reviewer template

Need to find and fix bugs?
  → Use debugger template

Need to make design decisions?
  → Use architect template

Need to implement features?
  → Use implementer template

Need to research codebase or technologies?
  → Use researcher template

Need to run and validate tests?
  → Use tester template

Need something custom?
  → Use basic template
```

### Workflow 4: Automated Subagent Generation

When another skill/agent needs to create a subagent programmatically:

```python
# Use init_subagent.py script with clear parameters
python scripts/init_subagent.py {name} \
  "{description}" \
  --tools "{comma_separated_tools}" \
  --template {template_name} \
  --location project
```

## Subagent Structure Reference

### Required YAML Frontmatter

```yaml
---
name: subagent-name              # Required: lowercase + hyphens
description: When to use this    # Required: Action-oriented description
tools: Read, Grep, Glob          # Optional: Comma-separated tool list
model: sonnet                    # Optional: sonnet|opus|haiku|inherit
---
```

### System Prompt Structure

A well-structured system prompt includes:

1. **Role**: Define the subagent's expertise and persona
2. **Responsibilities**: List key duties (numbered list)
3. **Process/Workflow**: Step-by-step approach
4. **Output Format**: Expected output structure
5. **Examples**: 1-2 concrete examples
6. **Success Criteria**: Checklist of completion criteria
7. **Constraints**: Limitations and boundaries
8. **Tools Usage**: How to use each allowed tool

See templates for detailed examples.

## Best Practices

### 1. Single-Responsibility Design

✅ **Good:**
```yaml
name: api-security-reviewer
description: Reviews API endpoints for OWASP Top 10 vulnerabilities
```

❌ **Bad:**
```yaml
name: dev-helper
description: Helps with coding, reviewing, debugging, and documentation
```

### 2. Permission Hygiene

**Only grant necessary tools:**

- **Reviewers**: `Read, Grep, Glob` (read-only)
- **Implementers**: `Read, Write, Edit, Bash, Grep, Glob`
- **Researchers**: `Read, Grep, Glob, WebSearch, WebFetch`
- **Testers**: `Read, Bash, Grep, Glob`

### 3. Detailed Prompts

Subagents cannot ask follow-up questions. Include:
- Specific responsibilities
- Expected output format
- Success criteria
- Common edge cases
- Examples

### 4. Action-Oriented Descriptions

✅ **Good:**
- "Reviews code for security vulnerabilities"
- "Use when implementing new API endpoints"
- "Helps debug production errors"

❌ **Bad:**
- "A helpful agent for coding"
- "General purpose assistant"

### 5. Proper Naming

✅ **Good:**
- `code-reviewer`
- `api-security-scanner`
- `test-runner`

❌ **Bad:**
- `MyAgent` (use lowercase)
- `code_reviewer` (use hyphens)
- `helper` (too generic)

## Tool Selection Guide

Consult `references/tool-reference.md` for comprehensive tool documentation.

**Quick Reference:**

| Agent Type | Recommended Tools |
|-----------|------------------|
| Code Reviewer | Read, Grep, Glob |
| Implementer | Read, Write, Edit, Bash, Grep, Glob, TodoWrite |
| Debugger | Read, Edit, Bash, Grep, Glob |
| Architect | Read, Write, Grep, Glob, WebFetch |
| Researcher | Read, Grep, Glob, WebSearch, WebFetch |
| Tester | Read, Bash, Grep, Glob |

## Common Patterns

Consult `references/subagent-patterns.md` for detailed workflow patterns.

**Quick Pattern Reference:**

### Three-Stage Development Pipeline
```
PM-Spec → Architect-Review → Implementer-Tester
```
Each stage has clear handoffs via status tracking.

### Multi-Agent Verification
```
Writer → Reviewer → Judge → Editor
```
Separation of concerns prevents rubber-stamp reviews.

### Parallel Specialization
```
Launch concurrently:
- security-reviewer
- performance-reviewer
- style-reviewer
```
Fast, comprehensive analysis.

## Validation and Testing

### Validation Script

Always validate after creating/modifying:

```bash
python scripts/validate_subagent.py .claude/agents/my-agent.md
```

**Checks performed:**
- YAML frontmatter format
- Required fields present
- Name format (lowercase + hyphens)
- Description quality
- Tool validity
- Model validity

**Output:**
- ✅ Pass: All checks successful
- ⚠️  Warning: Non-critical issues
- ❌ Error: Must fix before using

### Testing New Subagents

1. **Start Simple**: Test with straightforward example
2. **Test Edge Cases**: Try boundary conditions
3. **Verify Tool Usage**: Ensure using correct tools
4. **Check Output Quality**: Review results
5. **Iterate**: Refine based on performance

## Troubleshooting

### "Tool not available" Error
**Cause**: Tool not in subagent's `tools` list
**Fix**: Add to YAML frontmatter or omit `tools` field to inherit all

### Subagent Not Using Correct Tools
**Cause**: Either too many tools available or unclear instructions
**Fix**: Explicitly list only necessary tools and clarify in system prompt

### Validation Errors
**Cause**: YAML formatting or missing required fields
**Fix**: Run `validate_subagent.py` and follow error messages

### Description Not Triggering Subagent
**Cause**: Description not action-oriented or specific enough
**Fix**: Rewrite to clearly state WHEN to use the subagent

## Advanced Topics

### Hook-Based Chaining

Connect subagents via hooks for automated workflows.

**Example** (`.claude/settings.json`):
```json
{
  "hooks": {
    "SubagentStop": {
      "subagent": "pm-spec",
      "command": "bash ~/.claude/hooks/trigger-architect.sh"
    }
  }
}
```

### Model Selection Strategy

- **haiku**: Fast, cheap - use for simple validation, searches
- **sonnet**: Balanced - use for most tasks (default)
- **opus**: Most capable - use for complex architecture, analysis
- **inherit**: Use parent conversation's model

### Project vs User Subagents

**Project** (`.claude/agents/`):
- Team-shared subagents
- Version controlled
- Project-specific patterns
- Higher priority than user agents

**User** (`~/.claude/agents/`):
- Personal subagents
- Across all projects
- Personal workflows
- Lower priority (overridden by project agents)

## Resources

### Scripts
- **`init_subagent.py`**: Initialize new subagent with template
- **`validate_subagent.py`**: Validate subagent structure and format

### References
- **`best-practices.md`**: Comprehensive best practices from Anthropic
- **`tool-reference.md`**: Complete tool documentation with examples
- **`subagent-patterns.md`**: Common workflow patterns and anti-patterns

### Templates
- **`basic.md`**: Empty template with full structure
- **`code-reviewer.md`**: Production-ready code reviewer
- **`debugger.md`**: Bug diagnosis and fixing specialist
- **`architect.md`**: Architecture and design decisions
- **`implementer.md`**: Feature implementation expert
- **`researcher.md`**: Codebase and technology research
- **`tester.md`**: Testing and validation specialist

## Examples from Practice

### Example 1: Security Reviewer

**Request:** "Create a subagent that checks for SQL injection vulnerabilities"

**Implementation:**
```bash
python scripts/init_subagent.py sql-injection-checker \
  "Scans code for SQL injection vulnerabilities" \
  --template code-reviewer \
  --tools "Read,Grep,Glob" \
  --location project
```

Then customize to focus on SQL injection patterns specifically.

### Example 2: API Implementer

**Request:** "Create a subagent for implementing REST API endpoints"

**Implementation:**
```bash
python scripts/init_subagent.py api-implementer \
  "Implements RESTful API endpoints following project patterns" \
  --template implementer \
  --tools "Read,Write,Edit,Bash,Grep,Glob,TodoWrite" \
  --location project
```

Customize to include REST API best practices and project routing patterns.

### Example 3: Performance Tester

**Request:** "Create a subagent that runs performance tests"

**Implementation:**
```bash
python scripts/init_subagent.py performance-tester \
  "Executes performance tests and analyzes results" \
  --template tester \
  --tools "Read,Bash,Grep,Glob" \
  --model sonnet \
  --location project
```

Customize to include performance benchmarking tools and thresholds.

## Quick Reference Card

### Create Subagent
```bash
python scripts/init_subagent.py NAME "DESCRIPTION" \
  --template TEMPLATE --tools "TOOLS" --location LOCATION
```

### Validate Subagent
```bash
python scripts/validate_subagent.py .claude/agents/NAME.md
```

### Use in Claude Code
```
User: "Use the X subagent to..."
```
or
```
User: "/agents" (interactive UI)
```

### File Locations
- **Project**: `.claude/agents/NAME.md`
- **User**: `~/.claude/agents/NAME.md`

### Templates Available
`basic | code-reviewer | debugger | architect | implementer | researcher | tester`

### Tool Categories
- **Read-only**: Read, Grep, Glob
- **Write**: Write, Edit
- **Execute**: Bash
- **Research**: WebSearch, WebFetch
- **Coordination**: Task, AskUserQuestion, TodoWrite

## Learn More

- [Official Subagents Documentation](https://docs.claude.com/en/docs/claude-code/sub-agents)
- [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
- Review `references/` directory for detailed guides