# Claude Code Tool Reference

Complete reference of tools available to Claude Code subagents, organized by category.

## Tool Categories

### 🔍 Read-Only Tools (Safe for all subagents)

#### Read
Reads file contents from the filesystem.
- **Use case**: Reading source code, config files, documentation
- **Parameters**: `file_path`, optional `offset`, `limit`
- **Security**: Read-only, safe for reviewers
- **Example**: Reading a file to review code

#### Grep
Searches for patterns in files using ripgrep.
- **Use case**: Finding code patterns, searching across codebase
- **Parameters**: `pattern`, optional `glob`, `output_mode`, `path`
- **Security**: Read-only, safe for all subagents
- **Example**: Finding all TODO comments

#### Glob
Finds files matching patterns.
- **Use case**: Listing files, finding specific file types
- **Parameters**: `pattern`, optional `path`
- **Security**: Read-only, safe for all subagents
- **Example**: Finding all JavaScript files

#### WebFetch
Fetches content from URLs.
- **Use case**: Reading documentation, API references
- **Parameters**: `url`, `prompt`
- **Security**: External access, requires approval
- **Example**: Fetching library documentation

#### WebSearch
Searches the web for information.
- **Use case**: Research, finding up-to-date information
- **Parameters**: `query`, optional `allowed_domains`, `blocked_domains`
- **Security**: External access, requires approval
- **Example**: Finding best practices for a library

### ✏️ Write Tools (Restrict to implementers)

#### Write
Creates new files or overwrites existing files.
- **Use case**: Creating new code files, templates
- **Parameters**: `file_path`, `content`
- **Security**: Can overwrite files, restrict to trusted subagents
- **Example**: Creating a new component file
- **Best Practice**: Prefer Edit for modifying existing files

#### Edit
Makes precise edits to existing files.
- **Use case**: Modifying code, fixing bugs
- **Parameters**: `file_path`, `old_string`, `new_string`, optional `replace_all`
- **Security**: Can modify files, restrict to implementers
- **Example**: Fixing a bug in existing code
- **Best Practice**: Safer than Write for modifications

#### NotebookEdit
Edits Jupyter notebook cells.
- **Use case**: Modifying notebook cells
- **Parameters**: `notebook_path`, `new_source`, optional `cell_id`, `cell_type`
- **Security**: Modifies notebooks, restrict to implementers

### 🖥️ Execution Tools (High privilege)

#### Bash
Executes shell commands.
- **Use case**: Running tests, build commands, git operations
- **Parameters**: `command`, optional `timeout`, `run_in_background`
- **Security**: Can execute arbitrary commands, high risk
- **Restrictions**: Should only be given to trusted implementers/testers
- **Example**: Running unit tests

#### BashOutput
Retrieves output from background bash shells.
- **Use case**: Monitoring long-running commands
- **Parameters**: `bash_id`, optional `filter`
- **Security**: Read-only but requires Bash access

#### KillShell
Terminates background bash shells.
- **Use case**: Stopping long-running processes
- **Parameters**: `shell_id`
- **Security**: Requires Bash access

### 🤖 Coordination Tools

#### Task
Launches specialized subagents.
- **Use case**: Delegating complex tasks to specialized agents
- **Parameters**: `subagent_type`, `prompt`, `description`, optional `model`
- **Security**: Inherits permissions based on subagent type
- **Example**: Launching a debugger subagent

#### AskUserQuestion
Asks user for input during execution.
- **Use case**: Getting user preferences, clarifications
- **Parameters**: `questions` with `header`, `options`, `multiSelect`
- **Security**: Safe, enables human-in-the-loop
- **Example**: Asking which approach to use

#### TodoWrite
Manages task lists.
- **Use case**: Tracking progress, organizing complex tasks
- **Parameters**: `todos` array with `content`, `status`, `activeForm`
- **Security**: Safe, helps with organization
- **Example**: Breaking down implementation into steps

### 🎯 Specialized Tools

#### Skill
Executes a skill.
- **Use case**: Running specialized workflows
- **Parameters**: `command` (skill name)
- **Security**: Depends on skill permissions
- **Example**: Running pdf skill for PDF operations

#### SlashCommand
Executes custom slash commands.
- **Use case**: Running project-specific commands
- **Parameters**: `command`
- **Security**: Depends on command definition
- **Example**: Running /review-pr command

#### ExitPlanMode
Exits planning mode.
- **Use case**: Transitioning from planning to implementation
- **Parameters**: `plan`
- **Security**: Safe, workflow control

### 🗄️ MCP Tools

#### ListMcpResourcesTool
Lists resources from MCP servers.
- **Use case**: Discovering available MCP resources
- **Parameters**: optional `server`
- **Security**: Read-only, safe

#### ReadMcpResourceTool
Reads MCP server resources.
- **Use case**: Accessing MCP-provided data
- **Parameters**: `server`, `uri`
- **Security**: Read-only, safe

## Tool Permission Patterns

### Pattern 1: Read-Only Reviewer
```yaml
tools: Read, Grep, Glob
```
**Use for:** Code reviewers, documentation analyzers, security scanners (read-only)

### Pattern 2: Read + Research
```yaml
tools: Read, Grep, Glob, WebSearch, WebFetch
```
**Use for:** Research agents, documentation writers, architecture analysts

### Pattern 3: Full Implementer
```yaml
tools: Read, Write, Edit, Bash, Grep, Glob
```
**Use for:** Code implementers, feature developers, bug fixers

### Pattern 4: Tester
```yaml
tools: Read, Bash, Grep, Glob
```
**Use for:** Test runners, validation agents

### Pattern 5: Coordinator
```yaml
tools: Read, Task, AskUserQuestion, TodoWrite, Grep, Glob
```
**Use for:** Project managers, orchestration agents

### Pattern 6: Inherit All
```yaml
# Omit tools field
```
**Use for:** Trusted general-purpose agents (use sparingly)

## Tool Selection Guidelines

### For Code Review Subagents
**Include:**
- Read (view code)
- Grep (search for patterns)
- Glob (find files)

**Exclude:**
- Write, Edit (reviewers shouldn't modify)
- Bash (reviewers shouldn't execute)

### For Implementation Subagents
**Include:**
- Read (view existing code)
- Write, Edit (create/modify files)
- Bash (run tests, build)
- Grep, Glob (search codebase)

**Maybe Include:**
- Task (delegate sub-tasks)
- TodoWrite (track progress)

### For Research Subagents
**Include:**
- Read (read documentation)
- Grep, Glob (search codebase)
- WebFetch, WebSearch (external research)

**Exclude:**
- Write, Edit (researchers shouldn't modify)
- Bash (researchers shouldn't execute)

### For Testing Subagents
**Include:**
- Read (read test files)
- Bash (execute tests)
- Grep (find test patterns)

**Maybe Include:**
- Write (generate test reports)

### For Orchestration Subagents
**Include:**
- Read (understand codebase)
- Task (delegate to other agents)
- AskUserQuestion (get user input)
- TodoWrite (manage tasks)
- Grep, Glob (explore codebase)

**Exclude:**
- Write, Edit (orchestrators coordinate, not implement)

## Security Considerations

### High-Risk Tools
These tools can modify state or execute code:
- **Bash**: Can run arbitrary commands
- **Write**: Can create/overwrite files
- **Edit**: Can modify files

**Best Practice:** Only grant to trusted, well-tested subagents

### Medium-Risk Tools
These tools access external resources:
- **WebFetch**: Can access arbitrary URLs
- **WebSearch**: Makes external requests

**Best Practice:** Use approval requirements for sensitive contexts

### Low-Risk Tools
These tools only read local data:
- **Read**: Read-only file access
- **Grep**: Read-only search
- **Glob**: Read-only file listing

**Best Practice:** Safe to grant to all subagents

## Common Tool Combinations

### Minimal Safe Set
```yaml
tools: Read, Grep, Glob
```
Use when you want subagent to understand code but not modify anything.

### Research Set
```yaml
tools: Read, Grep, Glob, WebSearch, WebFetch
```
Use for agents that need to research and gather information.

### Implementation Set
```yaml
tools: Read, Write, Edit, Bash, Grep, Glob, TodoWrite
```
Use for agents that implement features and run tests.

### Coordination Set
```yaml
tools: Read, Task, AskUserQuestion, TodoWrite, Grep, Glob
```
Use for agents that manage workflows and delegate to other agents.

## Tool Usage Examples

### Example 1: Code Reviewer
```markdown
---
name: security-reviewer
description: Reviews code for security vulnerabilities
tools: Read, Grep, Glob
---

# Role
Security-focused code reviewer

# Tools Usage
- **Read**: Review individual files for vulnerabilities
- **Grep**: Search for dangerous patterns (eval, innerHTML, etc.)
- **Glob**: Find all files that need security review
```

### Example 2: Feature Implementer
```markdown
---
name: api-implementer
description: Implements new API endpoints
tools: Read, Write, Edit, Bash, Grep, Glob, TodoWrite
---

# Role
Backend API developer

# Tools Usage
- **Read**: Understand existing code
- **Write**: Create new endpoint files
- **Edit**: Modify route configurations
- **Bash**: Run tests after implementation
- **Grep**: Find similar endpoints for reference
- **Glob**: Locate relevant files
- **TodoWrite**: Track implementation steps
```

### Example 3: Research Agent
```markdown
---
name: tech-researcher
description: Researches best practices and solutions
tools: Read, Grep, Glob, WebSearch, WebFetch
---

# Role
Technology researcher

# Tools Usage
- **Read**: Review local documentation
- **Grep**: Search for existing patterns
- **Glob**: Find related files
- **WebSearch**: Find external best practices
- **WebFetch**: Read external documentation
```

## Tool Restrictions in Practice

### Explicit Restrictions in Prompt
```markdown
# Tool Restrictions
- You may ONLY use Read, Grep, Glob
- You must NOT execute any Bash commands
- You must NOT modify any files
```

### Validation in Subagent
```markdown
# Before Using Tools
1. Verify tool is in approved list
2. Check if operation matches role
3. Prefer least-privilege tool (Read over Edit)
```

## Troubleshooting

### "Tool not available" Error
**Cause:** Tool not in subagent's `tools` list
**Fix:** Add tool to YAML frontmatter or remove `tools` field to inherit all

### Subagent using wrong tools
**Cause:** No `tools` field = inherits all tools
**Fix:** Explicitly list allowed tools in YAML frontmatter

### Permission denied errors
**Cause:** User approval required for certain tools
**Fix:** Configure approval settings or use pre-approved tools only

## Best Practices

1. **Principle of Least Privilege**: Only grant necessary tools
2. **Explicit Over Implicit**: Always specify `tools` field for security
3. **Documentation**: Document why each tool is needed
4. **Testing**: Test with minimal tool set first, add as needed
5. **Review**: Regularly audit subagent tool permissions

## Quick Reference

| Tool | Read | Write | Execute | External | Risk Level |
|------|------|-------|---------|----------|------------|
| Read | ✅ | ❌ | ❌ | ❌ | Low |
| Grep | ✅ | ❌ | ❌ | ❌ | Low |
| Glob | ✅ | ❌ | ❌ | ❌ | Low |
| Write | ❌ | ✅ | ❌ | ❌ | Medium |
| Edit | ❌ | ✅ | ❌ | ❌ | Medium |
| Bash | ✅ | ✅ | ✅ | ❌ | High |
| WebFetch | ✅ | ❌ | ❌ | ✅ | Medium |
| WebSearch | ✅ | ❌ | ❌ | ✅ | Medium |
| Task | Varies | Varies | Varies | ❌ | Varies |
| AskUserQuestion | ❌ | ❌ | ❌ | ❌ | Low |
| TodoWrite | ❌ | ✅ | ❌ | ❌ | Low |
