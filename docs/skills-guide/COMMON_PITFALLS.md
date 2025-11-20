# Common Pitfalls: Mistakes to Avoid with Claude Code Skills

**Learn from others' mistakes. This guide covers the most common errors when working with Skills, Commands, Sub-agents, and Hooks.**

---

## Table of Contents

- [Skills Pitfalls](#skills-pitfalls)
- [Commands Pitfalls](#commands-pitfalls)
- [Sub-agents Pitfalls](#sub-agents-pitfalls)
- [Hooks Pitfalls](#hooks-pitfalls)
- [Integration Pitfalls](#integration-pitfalls)
- [General Anti-Patterns](#general-anti-patterns)

---

## Skills Pitfalls

### Pitfall #1: Exceeding 500-Line Rule

**The Mistake:**
```markdown
# SKILL.md (800 lines)

[Massive file with everything included]
```

**Why It's Wrong:**
- Violates progressive disclosure principle
- Wastes context window tokens
- Harder to maintain
- Slows down Claude's processing

**The Fix:**
```markdown
# SKILL.md (< 500 lines)
Core concepts and quick reference only

## For Details:
- [patterns.md](resources/patterns.md)
- [examples.md](resources/examples.md)
```

---

### Pitfall #2: Vague Description

**The Mistake:**
```yaml
description: A helpful skill for coding
```

**Why It's Wrong:**
- Too generic to trigger reliably
- No clear keywords for matching
- Claude can't determine when to use it

**The Fix:**
```yaml
description: React/TypeScript/MUI v7 development patterns. Use when creating React components, handling state management with hooks, styling with Material UI Grid, or implementing data fetching with useSuspenseQuery.
```

---

### Pitfall #3: Expecting Tool Control

**The Mistake:**
```yaml
---
name: secure-reviewer
description: Secure code review
tools: Read, Grep  # THIS DOESN'T WORK
---
```

**Why It's Wrong:**
- Skills cannot restrict tools
- No `tools` field in skill YAML
- Skills inherit all parent tools

**The Fix:**
- Use Sub-agent if you need tool restrictions
- Use Command with `allowed-tools` if user-triggered
- Skill provides guidance, not restrictions

---

### Pitfall #4: Skill Overload

**The Mistake:**
```yaml
description: Handles frontend, backend, database, testing, deployment, documentation, security, and performance optimization.
```

**Why It's Wrong:**
- Single-responsibility violation
- Too many trigger scenarios
- Confusion about when to use
- Hard to maintain

**The Fix:**
One skill per domain:
- `frontend-patterns`
- `backend-patterns`
- `database-ops`
- `testing-strategies`

---

### Pitfall #5: Not Testing Triggers

**The Mistake:**
Creating skill without testing if it actually activates.

**Why It's Wrong:**
- Description may not match as expected
- Keywords might be too generic/specific
- False positives/negatives undetected

**The Fix:**
```bash
# Test trigger manually
echo '{"prompt":"create a react component"}' | \
  npx tsx .claude/hooks/skill-activation-prompt.ts

# Verify expected skill appears in suggestions
```

---

### Pitfall #6: Ignoring Progressive Disclosure

**The Mistake:**
Putting ALL information in SKILL.md with no references.

**Why It's Wrong:**
- Every skill load costs same tokens
- Can't load partial information
- Context window fills quickly

**The Fix:**
Structure for on-demand loading:
```
SKILL.md: What you need to know
resources/: What you might need to know
examples/: How others have done it
```

---

## Commands Pitfalls

### Pitfall #7: No Tool Restrictions

**The Mistake:**
```yaml
---
description: Simple format command
# No allowed-tools field
---

Format my code.
```

**Why It's Wrong:**
- Command has full tool access
- May do unintended operations
- Security risk

**The Fix:**
```yaml
---
description: Simple format command
allowed-tools: Read, Edit  # Only what's needed
---

Format my code using only Read and Edit tools.
```

---

### Pitfall #8: Wrong Argument Syntax

**The Mistake:**
```markdown
---
argument-hint: [env]
---

Deploy to {env} environment.  # WRONG
Deploy to $env environment.   # WRONG
Deploy to ${env} environment. # WRONG
```

**Why It's Wrong:**
- Incorrect substitution syntax
- Arguments won't substitute
- Command fails or behaves unexpectedly

**The Fix:**
```markdown
---
argument-hint: [env]
---

Deploy to $1 environment.  # CORRECT for first argument
Deploy to $ARGUMENTS.      # CORRECT for all arguments
```

---

### Pitfall #9: Forgetting Bash Tool Permission

**The Mistake:**
```markdown
---
description: Run tests
# No allowed-tools
---

!npm test  # This won't work
```

**Why It's Wrong:**
- `!` requires Bash tool permission
- Will fail silently or error out

**The Fix:**
```markdown
---
description: Run tests
allowed-tools: Bash(npm:*)
---

!npm test  # Now works
```

---

### Pitfall #10: Overly Cryptic Names

**The Mistake:**
```
.claude/commands/rpr.md     # What does this do?
.claude/commands/fmtcs.md   # Format... something?
```

**Why It's Wrong:**
- Hard to remember
- Not self-documenting
- Team confusion

**The Fix:**
```
.claude/commands/review-pr.md
.claude/commands/format-code-styles.md
```

---

## Sub-agents Pitfalls

### Pitfall #11: Assuming Context Access

**The Mistake:**
```
Task: Review the changes we discussed earlier.
```

**Why It's Wrong:**
- Sub-agent has NO access to conversation history
- Starts with blank context
- "Earlier" means nothing to it

**The Fix:**
```
Task: Review the following changes to auth.ts:
1. Added password hashing (lines 45-60)
2. Modified login flow (lines 120-150)
3. Updated session handling (lines 200-230)

Focus on security vulnerabilities.
```

Provide ALL needed context in task description.

---

### Pitfall #12: Too Many Tools

**The Mistake:**
```yaml
tools: Read, Write, Edit, Bash, Grep, Glob, WebSearch, WebFetch, Task, TodoWrite, AskUserQuestion
```

**Why It's Wrong:**
- Security risk (too much access)
- Agent may use wrong tool
- Unclear purpose

**The Fix:**
```yaml
# For code reviewer
tools: Read, Grep, Glob  # Read-only, focused

# For implementer
tools: Read, Write, Edit, Bash, Grep, Glob, TodoWrite  # Write access needed
```

---

### Pitfall #13: Generic Descriptions

**The Mistake:**
```yaml
name: helper
description: A helpful agent
```

**Why It's Wrong:**
- Unclear when to use
- May be selected inappropriately
- Not discoverable

**The Fix:**
```yaml
name: api-security-scanner
description: Scans API endpoints for OWASP Top 10 vulnerabilities. Use when reviewing authentication, authorization, or data validation code.
```

---

### Pitfall #14: No Success Criteria

**The Mistake:**
```markdown
# System Prompt

You are a code reviewer. Review code and find issues.
```

**Why It's Wrong:**
- No clear definition of "done"
- Agent may stop too early
- May miss important aspects

**The Fix:**
```markdown
# System Prompt

You are a code reviewer.

## Success Criteria:
- [ ] All functions have error handling
- [ ] No SQL injection vulnerabilities
- [ ] Input validation present
- [ ] Authentication checks in place
- [ ] Rate limiting considered

Do not return until all criteria checked.
```

---

### Pitfall #15: Ignoring Model Selection

**The Mistake:**
Always using default model for all agents.

**Why It's Wrong:**
- Haiku is faster/cheaper for simple tasks
- Opus is better for complex reasoning
- Sonnet is balanced but not always optimal

**The Fix:**
```yaml
# Quick search task
model: haiku  # Fast, cheap

# Complex architecture
model: opus  # Most capable

# Balanced tasks
model: sonnet  # Default
```

---

## Hooks Pitfalls

### Pitfall #16: Wrong Exit Codes

**The Mistake:**
```bash
#!/bin/bash
echo "Error occurred"
exit 0  # Should be exit 1 or 2
```

**Why It's Wrong:**
- exit 0 means success
- Claude won't see this as error
- Intended block doesn't happen

**The Fix:**
```bash
#!/bin/bash
echo "Error occurred" >&2  # stderr for errors
exit 2  # Block the operation
```

Exit codes:
- 0: Success (stdout becomes context)
- 1: Error (non-blocking)
- 2: Block (critical guardrail)

---

### Pitfall #17: Infinite Loops

**The Mistake:**
```bash
# PostToolUse hook
if tool was Edit; then
  # Triggers another Edit which triggers hook again...
  edit_something
fi
```

**Why It's Wrong:**
- Hook triggers tool
- Tool triggers hook
- Infinite loop

**The Fix:**
```bash
# Add guard against recursion
if [ "$RECURSION_GUARD" = "true" ]; then
  exit 0
fi

export RECURSION_GUARD=true
# Do work
```

---

### Pitfall #18: Not Handling JSON Input

**The Mistake:**
```bash
#!/bin/bash
tool_name=$1  # WRONG - input is JSON, not args
```

**Why It's Wrong:**
- Hooks receive JSON via stdin
- Not command-line arguments
- Will get garbage data

**The Fix:**
```bash
#!/bin/bash
input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name')
```

---

### Pitfall #19: Blocking Too Much

**The Mistake:**
```bash
# Blocks EVERY file edit
exit 2
```

**Why It's Wrong:**
- Too aggressive
- Frustrates users
- Defeats productivity

**The Fix:**
```bash
# Block only specific cases
if echo "$file_path" | grep -q "schema.prisma"; then
  exit 2  # Block schema changes
else
  exit 0  # Allow other edits
fi
```

---

### Pitfall #20: Slow Hook Performance

**The Mistake:**
```bash
#!/bin/bash
# Reads entire codebase
grep -r "pattern" .
# Takes 30 seconds
```

**Why It's Wrong:**
- Hooks run on every event
- Slow hooks = slow Claude
- User experience degrades

**The Fix:**
- Keep hooks under 100ms (suggest) or 200ms (block)
- Cache results where possible
- Use targeted searches, not full scans

---

## Integration Pitfalls

### Pitfall #21: Skill-Command Confusion

**The Mistake:**
Using Skill when Command is appropriate (or vice versa).

**Example:** Creating a Skill for "deploy to production"

**Why It's Wrong:**
- Deployment shouldn't auto-trigger
- Needs explicit user control
- Safety-critical operation

**The Fix:**
- Use Command: `/deploy production`
- User explicitly controls when to deploy

---

### Pitfall #22: Not Combining Tools

**The Mistake:**
Trying to do everything with one mechanism.

**Example:** Complex workflow using only Commands.

**Why It's Wrong:**
- Misses benefits of other tools
- Overcomplicates single mechanism
- Not using best tool for each part

**The Fix:**
Combine appropriately:
- Skill: Provides domain knowledge
- Command: User triggers workflow
- Sub-agent: Performs complex analysis
- Hook: Automates validation

---

### Pitfall #23: Duplicate Functionality

**The Mistake:**
```
skills/skill-developer/SKILL.md
skills/skill-developer/SKILL.md  # Same thing!
```

**Why It's Wrong:**
- Maintenance burden
- Confusion about which to use
- Trigger conflicts

**The Fix:**
- Consolidate duplicates
- Use one canonical version
- Deprecate others

---

## General Anti-Patterns

### Anti-Pattern: "God Skill"

**What It Is:**
One massive skill that handles everything.

**Problems:**
- Violates single-responsibility
- Difficult to trigger correctly
- Maintenance nightmare
- Context window bloat

**Solution:**
Decompose into focused skills.

---

### Anti-Pattern: "Trigger Everything"

**What It Is:**
```json
{
  "keywords": ["code", "write", "create", "fix", "update", ...]
}
```

**Problems:**
- Too many false positives
- Skill activates when not needed
- Annoys users

**Solution:**
Use specific, domain-relevant keywords.

---

### Anti-Pattern: "Context Blindness"

**What It Is:**
Creating sub-agents without providing needed context.

**Problems:**
- Agent can't access conversation
- Results are poor quality
- Wasted resources

**Solution:**
Always provide complete context in task description.

---

### Anti-Pattern: "Security Ignorance"

**What It Is:**
Installing skills/hooks from untrusted sources without review.

**Problems:**
- Prompt injection risks
- Malicious code execution
- Data exfiltration

**Solution:**
- Review all code before installing
- Verify sources
- Test in isolated environment first

---

### Anti-Pattern: "Documentation Laziness"

**What It Is:**
Creating skills/commands without proper documentation.

**Problems:**
- Others can't use it
- You forget how it works
- Maintenance becomes impossible

**Solution:**
- Document purpose, usage, examples
- Keep documentation updated
- Test documentation accuracy

---

## Debugging Checklist

When things don't work, check:

1. **Skill not triggering?**
   - [ ] Description includes relevant keywords?
   - [ ] SKILL.md in correct location?
   - [ ] Hooks configured in settings.json?
   - [ ] skill-rules.json has entry?

2. **Command not working?**
   - [ ] File in .claude/commands/?
   - [ ] YAML frontmatter valid?
   - [ ] Tools permitted in allowed-tools?
   - [ ] Argument syntax correct ($1, $ARGUMENTS)?

3. **Sub-agent failing?**
   - [ ] All context provided in task?
   - [ ] Tools list includes needed tools?
   - [ ] Model appropriate for task?
   - [ ] Success criteria defined?

4. **Hook not executing?**
   - [ ] Registered in settings.json?
   - [ ] Script is executable?
   - [ ] Handles JSON input correctly?
   - [ ] Exit codes are appropriate?

5. **Performance issues?**
   - [ ] SKILL.md under 500 lines?
   - [ ] Hooks under 100-200ms?
   - [ ] Not loading unnecessary content?
   - [ ] No infinite loops?

---

## Summary

**Most Common Root Causes:**

1. **Wrong tool for job** - Use Skills for knowledge, Commands for shortcuts, Sub-agents for delegation
2. **Violating principles** - 500-line rule, single-responsibility, progressive disclosure
3. **Missing context** - Sub-agents need explicit context, not conversation history
4. **Poor descriptions** - Triggers fail without specific keywords
5. **Security oversight** - Not restricting tools appropriately

**Golden Rules:**

1. ✅ Test before deploying
2. ✅ Keep it simple
3. ✅ Document everything
4. ✅ Follow the 500-line rule
5. ✅ Provide explicit context to sub-agents
6. ✅ Use specific, meaningful keywords
7. ✅ Restrict tools to minimum needed
8. ✅ Monitor performance

Avoid these pitfalls, and your Claude Code extensions will be robust, maintainable, and effective.

---

**See Also:**
- [README.md](README.md) - Core concepts
- [DECISION_TREE.md](DECISION_TREE.md) - Choosing the right tool
- [LATEST_INFO_SOURCES.md](LATEST_INFO_SOURCES.md) - Staying updated
