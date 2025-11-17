---
name: command-creator
description: Create, modify, and manage Claude Code slash commands. Use when users request to create new custom commands, update existing commands, or need templates for common command patterns. Also use when agents or other skills need to automatically generate slash commands for specific workflows.
---

# Command Creator

## Overview

This skill enables creation and management of Claude Code slash commands - user-defined shortcuts that expand to full prompts. Slash commands provide convenient access to frequently used workflows, prompt templates, and automated sequences. This skill includes initialization scripts, validation tools, templates for common patterns, and comprehensive documentation.

## When to Use This Skill

Invoke this skill when:
- User requests: "Create a slash command for X"
- User asks to modify existing command
- User needs command templates for common patterns (simple action, workflow, etc.)
- Another skill/agent needs to automatically generate a command
- User asks about slash command best practices or patterns

## Quick Start

### Creating a New Command

Use the initialization script for fastest results:

```bash
python3 scripts/init_command.py my-command "Brief description" --location project
```

**Options:**
- `--location project|user` - Where to save (.claude/commands/ or ~/.claude/commands/)
- `--template basic|simple-action|workflow|prompt-expansion|agent-caller|full-power` - Use template
- `--namespace folder` - Organize in subdirectory
- `--allowed-tools "Read,Edit,Bash"` - Specify tool permissions
- `--argument-hint "[file]"` - Show expected arguments
- `--model sonnet|opus|haiku` - Override model
- `--disable-invocation` - Prevent automatic execution

**Example:**
```bash
# Create simple formatting command
python3 scripts/init_command.py format "Format code using project style" \
  --template simple-action \
  --allowed-tools "Read,Edit" \
  --location project

# Create workflow command with arguments
python3 scripts/init_command.py review-pr "Review pull request changes" \
  --template workflow \
  --argument-hint "[pr-number]" \
  --allowed-tools "Bash(git:*),Read,Grep,Glob" \
  --location project

# Create command in namespace
python3 scripts/init_command.py deploy "Deploy to environment" \
  --namespace ops \
  --argument-hint "[env]" \
  --allowed-tools "Bash" \
  --location project
```

### Validating a Command

After creating or modifying:

```bash
python3 scripts/validate_command.py .claude/commands/my-command.md
```

### Using Templates

Six pre-built templates available in `assets/templates/`:

1. **basic.md** - Empty template with structure
2. **simple-action.md** - Single action execution (format, lint, etc.)
3. **workflow.md** - Multi-step workflow process
4. **prompt-expansion.md** - Long prompt abbreviation
5. **agent-caller.md** - Subagent invocation command
6. **full-power.md** - Complex multi-feature command

Templates provide complete, production-ready command definitions that can be used as-is or customized.

## Core Workflows

### Workflow 1: Creating From Scratch

```
1. User requests: "Create a command that X"
2. Ask clarifying questions:
   - What should the command do specifically?
   - Should it accept arguments?
   - What tools does it need?
   - Should it be project-specific or personal?
3. Use init_command.py script with appropriate template
4. Customize the generated file based on requirements
5. Validate with validate_command.py
6. Inform user where file was created and how to use it
```

**Example Conversation:**
```
User: "Create a command to run tests and show coverage"

Claude: I'll create a test-with-coverage command. A few questions:
1. Should it run all tests or accept specific test files?
2. What test command does your project use (npm/yarn/pytest)?
3. Should it be available project-wide or just for you?

User: Run all tests, use npm test, project-wide.

Claude: Perfect! I'll create it now.
```

```bash
python3 scripts/init_command.py test-coverage \
  "Run tests with coverage report" \
  --template simple-action \
  --allowed-tools "Bash(npm:*)" \
  --location project
```

Then customize the generated file to add coverage-specific commands.

### Workflow 2: Modifying Existing Command

```
1. Read current command file
2. Identify what needs to change:
   - Update description?
   - Add/remove tools?
   - Change arguments?
   - Update workflow steps?
3. Make targeted edits
4. Validate with validate_command.py
5. Confirm changes with user
```

### Workflow 3: Choosing the Right Template

**Decision Tree:**

```
Need single, focused action (format, lint)?
  → Use simple-action template

Need multiple coordinated steps?
  → Use workflow template

Have long prompt you type repeatedly?
  → Use prompt-expansion template

Want to invoke a specific subagent?
  → Use agent-caller template

Need basic empty structure?
  → Use basic template

Need complex multi-feature command?
  → Use full-power template
```

### Workflow 4: Automated Command Generation

When another skill/agent needs to create a command programmatically:

```bash
# Use init_command.py script with clear parameters
python3 scripts/init_command.py {name} \
  "{description}" \
  --template {template_name} \
  --allowed-tools "{tools}" \
  --location project
```

## Command Structure Reference

### Required Components

**File Name:** Becomes command name (e.g., `optimize.md` → `/optimize`)
- Must be lowercase + hyphens
- No spaces or special characters
- Descriptive and action-oriented

**File Location:**
- Project: `.claude/commands/` (team-shared, version controlled)
- User: `~/.claude/commands/` (personal, cross-project)

### Optional YAML Frontmatter

```yaml
---
description: Brief description shown in autocomplete
allowed-tools: Tool1, Tool2, Bash(git:*)  # Tool permissions
argument-hint: [args]                      # Expected arguments
model: claude-3-5-haiku-20241022          # Model override
disable-model-invocation: false            # Prevent auto-execution
---
```

### Content Structure

```markdown
# Command: /command-name

Brief overview of what this command does.

## Process

1. First step
2. Second step
3. Third step

## Guidelines

- Important guideline
- Another guideline

## Output

Expected output format.
```

### Argument Handling

**$ARGUMENTS** - Captures everything:
```markdown
Commit with message: "$ARGUMENTS"
```
Usage: `/commit Fixed bug in authentication`

**$1, $2, etc.** - Positional arguments:
```markdown
---
argument-hint: [source] [dest]
---

Move $1 to $2
```
Usage: `/move-file old.js new.js`

### Bash Execution

Include command output with `!` prefix:
```markdown
---
allowed-tools: Bash(git:*)
---

!git status
!git log --oneline -5

Based on the above output, analyze changes.
```

### File References

Include specific files with `@` prefix:
```markdown
Review @src/auth.js against @docs/security.md
```

## Best Practices

### 1. Single-Responsibility Design

✅ **Good:**
```yaml
name: optimize-images
description: Optimize image files for web performance
```

❌ **Bad:**
```yaml
name: dev-helper
description: Helps with coding, testing, debugging, and docs
```

### 2. Permission Hygiene

**Only grant necessary tools:**

- **Read-only:** `Read, Grep, Glob`
- **Editing:** `Read, Edit, Write`
- **Bash:** `Bash(git:*)` (specific patterns)
- **Full dev:** `Read, Write, Edit, Bash, Grep, Glob, TodoWrite`

### 3. Clear Descriptions

✅ **Good:**
- "Format code using project ESLint and Prettier config"
- "Review pull request with security and performance checks"
- "Deploy to specified environment with validation"

❌ **Bad:**
- "Format stuff"
- "Review code"
- "Deploy things"

### 4. Proper Naming

✅ **Good:**
- `review-pr`
- `optimize-images`
- `run-tests`

❌ **Bad:**
- `ReviewPR` (use lowercase)
- `review_pr` (use hyphens)
- `rpr` (too cryptic)

### 5. Argument Clarity

When using arguments, make expectations clear:

```markdown
---
argument-hint: [environment]
description: Deploy to specified environment (dev/staging/prod)
---

Deploy to $1 environment.

Validate environment is one of: dev, staging, prod.
```

## Command Patterns

Consult `references/command-patterns.md` for detailed pattern documentation.

**Quick Pattern Reference:**

### Simple Action
Single focused task (formatting, linting, single check)
```markdown
Format code → Apply rules → Report changes
```

### Workflow
Multi-step coordinated process
```markdown
Phase 1 → Phase 2 → Phase 3 → Summary
```

### Prompt Expansion
Detailed checklist or criteria
```markdown
Comprehensive review criteria with specific checks
```

### Agent Caller
Delegate to specialized subagent
```markdown
Launch subagent → Provide context → Return results
```

### Context Gatherer
Collect information before processing
```markdown
!git status → !npm outdated → Analysis
```

### Interactive
Ask user decisions during execution
```markdown
Analyze → AskUserQuestion → Execute based on choice
```

## Integration Patterns

Consult `references/integration-guide.md` for comprehensive integration documentation.

### Commands + Subagents

```markdown
# Launch specialized agent
Use Task tool to launch security-scanner subagent
```

### Commands + Hooks

```json
{
  "hooks": {
    "SlashCommandStart": {
      "command": "deploy",
      "script": "bash pre-deploy-check.sh"
    }
  }
}
```

### Commands + Skills

```markdown
# Reference skill resources
Use api-design skill to review against standards
See skill references/rest-api.md for conventions
```

### Commands + MCP

```markdown
---
allowed-tools: mcp__github__*, mcp__slack__*
---

Use mcp__github__create_pr to create pull request
Use mcp__slack__post to notify team
```

## Validation and Testing

### Validation Script

Always validate after creating/modifying:

```bash
python3 scripts/validate_command.py .claude/commands/my-command.md
```

**Checks performed:**
- YAML frontmatter format
- File naming conventions
- Description quality
- Tool validity
- Argument placeholders
- Bash execution syntax
- File references

**Output:**
- ✅ Pass: All checks successful
- ⚠️  Warning: Non-critical issues
- ❌ Error: Must fix before using

### Testing New Commands

1. **Start Simple**: Test with straightforward example
2. **Test Arguments**: Verify argument substitution
3. **Verify Tools**: Ensure using correct tools
4. **Check Output**: Review results
5. **Iterate**: Refine based on performance

## Troubleshooting

### "Command not found"
**Cause**: File not in `.claude/commands/` or `~/.claude/commands/`
**Fix**: Check file location and name

### Bash execution fails
**Cause**: Missing `allowed-tools: Bash` in frontmatter
**Fix**: Add Bash to allowed-tools or use pattern like `Bash(git:*)`

### Arguments not substituting
**Cause**: Wrong placeholder syntax or missing arguments
**Fix**: Use `$ARGUMENTS` for all args or `$1`, `$2` for positional

### Command behaves unexpectedly
**Cause**: Tool permissions too broad or unclear instructions
**Fix**: Restrict tools to minimum needed, clarify prompt

### Validation errors
**Cause**: YAML formatting or missing fields
**Fix**: Run `validate_command.py` and follow error messages

## Advanced Topics

### Namespacing

Organize commands in subdirectories:

```
.claude/commands/
├── dev/
│   ├── review.md    # /review (project:dev)
│   └── test.md      # /test (project:dev)
├── ops/
│   ├── deploy.md    # /deploy (project:ops)
│   └── monitor.md   # /monitor (project:ops)
```

### Model Selection

- **haiku**: Fast, cheap - use for simple formatting, linting
- **sonnet**: Balanced - use for most tasks (default)
- **opus**: Most capable - use for complex analysis, architecture

### Project vs User Commands

**Project** (`.claude/commands/`):
- Team-shared commands
- Version controlled
- Project-specific workflows
- Higher priority than user commands

**User** (`~/.claude/commands/`):
- Personal commands
- Across all projects
- Personal workflows
- Lower priority (overridden by project commands)

## Resources

### Scripts
- **`init_command.py`**: Initialize new command with template
- **`validate_command.py`**: Validate command structure and format

### References
- **`best-practices.md`**: Comprehensive best practices from official docs
- **`command-patterns.md`**: Common patterns and anti-patterns with examples
- **`integration-guide.md`**: Integration with subagents, hooks, skills, MCP

### Templates
- **`basic.md`**: Empty template with full structure
- **`simple-action.md`**: Single action execution
- **`workflow.md`**: Multi-step workflow process
- **`prompt-expansion.md`**: Long prompt abbreviation
- **`agent-caller.md`**: Subagent invocation command
- **`full-power.md`**: Complex multi-feature command

## Examples from Practice

### Example 1: Code Formatter

**Request:** "Create a command to format code"

**Implementation:**
```bash
python3 scripts/init_command.py format \
  "Format code using project style guide" \
  --template simple-action \
  --allowed-tools "Read,Edit" \
  --location project
```

Customize to add project-specific formatting tools.

### Example 2: PR Review Workflow

**Request:** "Create a command for comprehensive PR review"

**Implementation:**
```bash
python3 scripts/init_command.py review-pr \
  "Comprehensive pull request review" \
  --template workflow \
  --argument-hint "[pr-number]" \
  --allowed-tools "Bash(git:*),Read,Grep,Glob" \
  --location project
```

Customize to include project-specific review criteria.

### Example 3: Deploy Command

**Request:** "Create a deployment command"

**Implementation:**
```bash
python3 scripts/init_command.py deploy \
  "Deploy to specified environment" \
  --namespace ops \
  --argument-hint "[environment]" \
  --allowed-tools "Bash,AskUserQuestion" \
  --location project
```

Customize with deployment scripts and validation.

## Quick Reference Card

### Create Command
```bash
python3 scripts/init_command.py NAME "DESCRIPTION" \
  --template TEMPLATE --allowed-tools "TOOLS" --location LOCATION
```

### Validate Command
```bash
python3 scripts/validate_command.py .claude/commands/NAME.md
```

### Use in Claude Code
```
> /command-name [arguments]
```

### File Locations
- **Project**: `.claude/commands/NAME.md`
- **User**: `~/.claude/commands/NAME.md`
- **Namespaced**: `.claude/commands/NAMESPACE/NAME.md`

### Templates Available
`basic | simple-action | workflow | prompt-expansion | agent-caller | full-power`

### Common Tool Combinations
- **Read-only**: `Read, Grep, Glob`
- **Editing**: `Read, Edit, Write`
- **Git**: `Bash(git:*), Read`
- **Testing**: `Bash(npm:*), Bash(yarn:*), Read`
- **Full**: `Read, Write, Edit, Bash, Grep, Glob, TodoWrite`

## Learn More

- [Official Slash Commands Documentation](https://docs.claude.com/en/docs/claude-code/slash-commands)
- [Common Workflows](https://docs.claude.com/en/docs/claude-code/common-workflows)
- Review `references/` directory for detailed guides
