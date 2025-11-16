# Integration Guide: Commands, Subagents, Hooks, and Skills

This guide explains how to integrate slash commands with other Claude Code features: subagents, hooks, skills, and MCP servers.

## Table of Contents

1. [Commands + Subagents](#commands--subagents)
2. [Commands + Hooks](#commands--hooks)
3. [Commands + Skills](#commands--skills)
4. [Commands + MCP Servers](#commands--mcp-servers)
5. [Complex Integration Patterns](#complex-integration-patterns)

## Commands + Subagents

### Overview

Slash commands and subagents complement each other:
- **Commands:** User-facing shortcuts that orchestrate workflows
- **Subagents:** Specialized AI agents with focused responsibilities

### Pattern 1: Command Launches Subagent

The most common pattern - command delegates work to a specialized agent.

**Example: Security Scan Command**

```markdown
# .claude/commands/security-scan.md
---
description: Run comprehensive security analysis
allowed-tools: Task
---

# Security Scan

Launch security-scanner subagent to analyze codebase:

Use the Task tool with subagent_type "security-scanner" and provide:

**Scope:**
- Authentication mechanisms
- API endpoints
- Data validation
- Secret management

**Deliverables:**
- Vulnerability report
- Risk assessment
- Remediation steps
```

**Corresponding Subagent:**

```markdown
# .claude/agents/security-scanner.md
---
name: security-scanner
description: Analyzes code for security vulnerabilities
tools: Read, Grep, Glob
model: sonnet
---

You are a security specialist focused on identifying vulnerabilities.

## Responsibilities
1. Scan code for OWASP Top 10 vulnerabilities
2. Check authentication/authorization
3. Review input validation
4. Identify hardcoded secrets

## Process
[Detailed security scanning process...]
```

**Benefits:**
- Command provides user-friendly interface
- Subagent has specialized expertise
- Separation of concerns
- Reusable subagent

### Pattern 2: Command Coordinates Multiple Subagents

Complex workflows can orchestrate multiple specialized agents.

**Example: PR Review Command**

```markdown
# .claude/commands/review-pr.md
---
description: Comprehensive PR review with multiple specialists
allowed-tools: Task, Bash(git:*)
argument-hint: [pr-number]
---

# PR Review: #$ARGUMENTS

Multi-agent review process:

## 1. Context Gathering
!git fetch origin pull/$ARGUMENTS/head
!git diff main...HEAD

## 2. Security Review
Launch security-scanner subagent:
- Focus: Changed files only
- Priority: Critical and high severity

## 3. Performance Review
Launch performance-analyzer subagent:
- Focus: Algorithm complexity
- Benchmark critical paths

## 4. Style Review
Launch style-reviewer subagent:
- Check: Naming conventions
- Verify: Code organization

## 5. Consolidate
Combine findings from all agents into unified report.
```

**Benefits:**
- Parallel specialized reviews
- Comprehensive coverage
- Expert analysis in each domain
- Consolidated reporting

### Pattern 3: Subagent Suggests Command

Subagents can recommend commands to users.

**Example: Architect Subagent**

```markdown
# .claude/agents/architect.md
---
name: architect
description: System design and architecture decisions
tools: Read, Write, Grep, Glob
---

[...architecture expertise...]

## Command Recommendations

After analysis, suggest relevant commands:
- "/implement [feature]" to execute the design
- "/generate-tests [component]" for test coverage
- "/document-api" to update documentation
```

### When to Use Each

**Use Command When:**
- User-initiated workflow
- Needs orchestration
- Multiple steps
- Requires user input

**Use Subagent When:**
- Specialized expertise needed
- Deep analysis required
- Reusable capability
- Can work autonomously

**Use Both When:**
- Complex workflow needs orchestration (command)
- Specialized steps need expertise (subagent)

## Commands + Hooks

### Overview

Hooks automate actions at specific events. Commands can trigger hooks or be triggered by hooks.

### Pattern 1: Hook Runs Before Command

Validate preconditions before command executes.

**Example: Pre-Deploy Validation**

```json
// .claude/settings.json
{
  "hooks": {
    "SlashCommandStart": {
      "command": "deploy",
      "script": "bash ~/.claude/hooks/pre-deploy-check.sh"
    }
  }
}
```

```bash
#!/bin/bash
# ~/.claude/hooks/pre-deploy-check.sh

# Check if tests pass
npm test || {
  echo "❌ Tests must pass before deployment"
  exit 1
}

# Check if on correct branch
BRANCH=$(git branch --show-current)
if [ "$BRANCH" != "main" ]; then
  echo "❌ Must deploy from main branch"
  exit 1
fi

echo "✅ Pre-deploy checks passed"
exit 0
```

**Benefits:**
- Enforces prerequisites
- Prevents errors
- Automated validation
- Consistent checks

### Pattern 2: Hook Runs After Command

Perform cleanup or follow-up actions.

**Example: Post-Commit Notification**

```json
{
  "hooks": {
    "SlashCommandStop": {
      "command": "commit",
      "script": "bash ~/.claude/hooks/post-commit.sh"
    }
  }
}
```

```bash
#!/bin/bash
# ~/.claude/hooks/post-commit.sh

# Get last commit message
MSG=$(git log -1 --pretty=%B)

# Send notification
curl -X POST https://slack.com/api/chat.postMessage \
  -H "Authorization: Bearer $SLACK_TOKEN" \
  -d "text=New commit: $MSG"
```

### Pattern 3: Command Designed for Hook Integration

Commands can be designed to work with hooks.

**Example: Staged Workflow**

```markdown
# .claude/commands/stage1-analyze.md
---
description: Stage 1 - Analysis (triggers stage 2 via hook)
---

Perform initial analysis...

[Analysis complete - hook will trigger stage 2]
```

```json
{
  "hooks": {
    "SlashCommandStop": {
      "command": "stage1-analyze",
      "script": "claude /stage2-implement"
    }
  }
}
```

### Pattern 4: Hook Suggests Command

Hooks can recommend commands based on events.

**Example: Edit Hook Suggests Formatting**

```json
{
  "hooks": {
    "EditStop": {
      "script": "bash ~/.claude/hooks/suggest-format.sh"
    }
  }
}
```

```bash
#!/bin/bash
# ~/.claude/hooks/suggest-format.sh

# Check if file needs formatting
if ! npx prettier --check $FILE 2>/dev/null; then
  echo "💡 Tip: Run /format to apply code formatting"
fi
```

### Available Hook Events

**For Commands:**
- `SlashCommandStart`: Before command executes
- `SlashCommandStop`: After command completes

**Other Events:**
- `EditStop`: After Edit tool
- `WriteStop`: After Write tool
- `BashStop`: After Bash tool
- `TaskStop`: After Task tool
- `SubagentStop`: After subagent completes

## Commands + Skills

### Overview

Skills provide procedural knowledge. Commands provide shortcuts to invoke that knowledge.

### Pattern 1: Command Activates Skill

Create a command that loads a skill.

**Example: PDF Processing**

```markdown
# .claude/commands/pdf.md
---
description: Process PDF files
---

Use the pdf skill to handle PDF operations.

The pdf skill provides:
- PDF rotation
- Page extraction
- PDF merging
- Text extraction

What PDF operation do you need?
```

**Benefits:**
- User-friendly entry point
- Skill provides deep expertise
- Skill can use bundled scripts/references
- Command provides context

### Pattern 2: Skill Includes Commands

Skills can bundle related commands.

**Example: Git Workflow Skill**

```
git-workflow/
├── SKILL.md
├── commands/
│   ├── smart-commit.md
│   ├── review-branch.md
│   └── sync-main.md
├── scripts/
│   └── branch-status.py
└── references/
    └── git-best-practices.md
```

Skills can include `.claude/commands/` directory that gets symlinked when skill is installed.

### Pattern 3: Command References Skill Resources

Commands can reference skill bundled resources.

```markdown
# .claude/commands/api-design.md
---
description: Design API following best practices
---

Design the API following the standards in the api-standards skill.

Key references:
- REST conventions (see skill references/rest-api.md)
- Authentication patterns (see skill references/auth.md)
- Error handling (see skill references/errors.md)

Apply the validation script from skill scripts/validate-api.py
```

### When to Use Each

**Use Command When:**
- Simple entry point needed
- Shortcut to common operation
- Quick context switch

**Use Skill When:**
- Bundled resources needed (scripts, docs, assets)
- Complex procedural knowledge
- Multiple related capabilities
- Reusable across projects

**Use Both When:**
- Skill provides expertise
- Command provides convenient access
- Workflow combines both

## Commands + MCP Servers

### Overview

MCP (Model Context Protocol) servers provide external integrations. Commands can use MCP tools.

### Pattern 1: Command Uses MCP Tool

Leverage MCP server capabilities in commands.

**Example: Database Query Command**

```markdown
# .claude/commands/db-query.md
---
description: Query database using SQL
allowed-tools: mcp__database__query
argument-hint: [sql]
---

# Database Query

Use the mcp__database__query tool to execute:

```sql
$ARGUMENTS
```

Format results as table.
```

### Pattern 2: Command Coordinates Multiple MCP Servers

Combine multiple external services.

**Example: Deploy with Notifications**

```markdown
# .claude/commands/deploy.md
---
description: Deploy and notify team
allowed-tools: mcp__github__create_deployment, mcp__slack__post_message
argument-hint: [environment]
---

# Deploy to $ARGUMENTS

## 1. Create Deployment
Use mcp__github__create_deployment:
- Environment: $ARGUMENTS
- Auto-merge: false

## 2. Notify Team
Use mcp__slack__post_message:
- Channel: #deployments
- Message: "Deploying to $ARGUMENTS"

## 3. Monitor
Wait for deployment status...

## 4. Confirm
Send success/failure notification.
```

### Pattern 3: MCP Tool Suggests Command

MCP tools can recommend commands.

```markdown
# MCP server response includes:
"✅ Analysis complete. Run /optimize-images to process findings."
```

### Available MCP Patterns

**Database MCP:**
```markdown
allowed-tools: mcp__database__query, mcp__database__schema
```

**Cloud MCP:**
```markdown
allowed-tools: mcp__aws__s3_upload, mcp__aws__lambda_invoke
```

**Communication MCP:**
```markdown
allowed-tools: mcp__slack__post, mcp__email__send
```

**Development MCP:**
```markdown
allowed-tools: mcp__github__*, mcp__jira__*, mcp__figma__*
```

## Complex Integration Patterns

### Pattern: Full Workflow Integration

Combine all features for powerful workflows.

**Example: Feature Development Workflow**

```markdown
# .claude/commands/full-feature.md
---
description: Complete feature development workflow
allowed-tools: Task, Bash, mcp__github__*, mcp__jira__*
argument-hint: [feature-name]
---

# Feature Development: $ARGUMENTS

## Phase 1: Planning (Skill)
Use api-design skill to:
- Review requirements
- Design API
- Plan implementation

## Phase 2: Setup (Hook)
Pre-implementation hook runs:
- Create feature branch
- Update JIRA ticket
- Notify team

## Phase 3: Implementation (Subagents)
Launch implementer subagent:
- Context: Design from Phase 1
- Task: Implement feature
- Tools: Read, Write, Edit, Bash

## Phase 4: Review (Subagent)
Launch code-reviewer subagent:
- Review implementation
- Check against design
- Verify tests

## Phase 5: PR Creation (MCP)
Use mcp__github__create_pull_request:
- Title: $ARGUMENTS
- Body: Generated from phases
- Reviewers: Auto-assigned

## Phase 6: Notification (MCP + Hook)
- Update JIRA: mcp__jira__update
- Notify Slack: mcp__slack__post
- Post-PR hook: Run checks

## Summary
Report all artifacts and links.
```

This workflow integrates:
- ✅ Skill (api-design)
- ✅ Hooks (pre/post actions)
- ✅ Subagents (implementer, reviewer)
- ✅ MCP (GitHub, JIRA, Slack)
- ✅ Command (orchestration)

### Pattern: Event-Driven Command Chain

Commands trigger other commands via hooks.

**Example: Progressive Enhancement**

```json
{
  "hooks": {
    "SlashCommandStop": {
      "command": "implement",
      "script": "claude /review"
    },
    "SlashCommandStop": {
      "command": "review",
      "script": "claude /test"
    },
    "SlashCommandStop": {
      "command": "test",
      "script": "claude /commit"
    }
  }
}
```

Chain: `/implement` → `/review` → `/test` → `/commit`

### Pattern: Adaptive Workflow

Commands use subagent results to decide next steps.

```markdown
# .claude/commands/adaptive-fix.md
---
description: Adaptive bug fixing workflow
---

## 1. Analyze
Launch debugger subagent to analyze issue.

## 2. Decide
Based on debugger findings:
- If simple: Fix directly
- If complex: Launch architect for design
- If test-related: Launch tester for analysis
- If security: Launch security-scanner

## 3. Execute
Run appropriate command:
- /simple-fix
- /architectural-fix
- /test-fix
- /security-fix

## 4. Verify
Launch appropriate verification subagent.
```

## Best Practices

### 1. Clear Boundaries

Define what each component does:
- **Commands:** User interaction, orchestration
- **Subagents:** Specialized expertise, analysis
- **Hooks:** Automation, validation, notifications
- **Skills:** Knowledge, procedures, resources
- **MCP:** External integrations

### 2. Loose Coupling

Components should work independently:
- Command works without subagent (degraded mode)
- Subagent works without command (direct invocation)
- Hook failures don't break command
- MCP failures have fallbacks

### 3. Progressive Enhancement

Start simple, add integrations:
1. Basic command
2. Add subagent for expertise
3. Add hooks for automation
4. Add MCP for external integration
5. Package as skill for distribution

### 4. Documentation

Document integrations:
```markdown
# /deploy command

**Uses:**
- Subagent: deployment-validator
- Hook: pre-deploy-check.sh (validation)
- Hook: post-deploy.sh (notification)
- MCP: github (create deployment)
- MCP: slack (team notification)

**Workflow:**
1. Pre-hook validates environment
2. Command orchestrates deployment
3. Subagent validates configuration
4. MCP creates GitHub deployment
5. Post-hook sends notifications
```

### 5. Error Handling

Handle integration failures gracefully:
```markdown
## Deployment

Try launching deployment-validator subagent:
- If available: Use expert validation
- If not: Run basic validation checks

Try using mcp__github__deploy:
- If available: Automated deployment
- If not: Provide manual deployment steps
```

## Summary

Integration hierarchy:
```
Command (orchestration)
  ├── Subagent (expertise)
  ├── Hook (automation)
  ├── Skill (knowledge)
  └── MCP (external services)
```

Best results come from using each component for its strengths and combining them thoughtfully.

## Additional Resources

- [Subagent Documentation](https://docs.claude.com/en/docs/claude-code/sub-agents)
- [Hooks Documentation](https://docs.claude.com/en/docs/claude-code/hooks)
- [Skills Documentation](https://docs.claude.com/en/docs/claude-code/skills)
- [MCP Documentation](https://modelcontextprotocol.io)
