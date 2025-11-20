---
name: skill-generator-tool
description: Automatically analyzes user intent and recommends the optimal Claude Code tool type (Command, Skill, Subagent, or Hook). Use when users want to create automation, extend capabilities, or are unsure which tool type best fits their needs. This skill routes to specialized creators and provides unified guidance.
---

# Skill Generator Tool

## Overview

This skill serves as the intelligent entry point for creating Claude Code tools. It analyzes user requirements, recommends the optimal tool type, and provides unified guidance for tool creation. Rather than duplicating functionality, it routes to specialized creator skills while offering decision support and best practices.

## When to Use This Skill

Invoke this skill when:
- User wants to create automation but is unsure which tool type to use
- User asks "What should I use for X?" or "How do I automate Y?"
- User needs to extend Claude Code capabilities
- User wants to compare different tool types
- Another skill/agent needs to programmatically generate Claude Code tools

**Example triggers:**
- "I want to automate code formatting after every edit"
- "Create something that reviews my PRs"
- "I need to add domain expertise for GraphQL"
- "What's the best way to automate deployment validation?"

## Official Best Practices (Anthropic)

### Key Principles from Official Documentation

1. **"Think from Claude's Perspective"** - The `name` and `description` are critical. They determine when Claude uses the tool. Pay special attention to these fields.

2. **Progressive Disclosure** - Skills use a three-level loading system:
   - Level 1: Metadata (name + description) - Always in context (~100 words)
   - Level 2: SKILL.md body - When skill triggers (<5k words)
   - Level 3: Bundled resources - As needed (unlimited via scripts)

3. **"Iterate with Claude"** - Ask Claude to capture successful approaches and common mistakes into reusable context and code.

4. **Specificity Matters** - "Claude Code's success rate improves significantly with more specific instructions, especially on first attempts."

5. **description Required for Commands** - Commands need `description` frontmatter to work with the SlashCommand tool.

6. **Scripts for Determinism** - Use scripts for tasks where "programming is more reliable than token generation" - sorting, calculations, file operations.

### Plugin Consideration (New in 2025)

**Plugins** package multiple customizations together:
- Slash commands
- Subagents
- MCP servers
- Hooks

Consider creating a **Plugin** when:
- You have multiple related tools that work together
- You want to share a complete workflow with a team
- You need to toggle capabilities on/off
- You're packaging for marketplace distribution

Use `/plugin` command to install and manage plugins.

## Tool Type Decision Matrix

Use this matrix to determine the optimal tool type:

### Quick Decision Guide

```
User Intent                              → Recommended Tool
─────────────────────────────────────────────────────────────
Shortcut for repeated prompts/workflows  → Slash Command
Specialized domain knowledge/procedures  → Skill
Focused AI agent for specific tasks      → Subagent
Automated response to events             → Hook
Package multiple tools together          → Plugin
```

### Detailed Decision Criteria

#### Choose **Slash Command** When:
- Need a reusable prompt template or workflow shortcut
- Want to abbreviate long, frequently-typed prompts
- Need to invoke specific tool combinations
- Want team-shared workflows (version controlled)
- Single, focused action or multi-step workflow

**Examples:**
- `/format` - Format code with project style
- `/review-pr [number]` - Comprehensive PR review
- `/deploy [env]` - Deploy to environment

**Key characteristics:**
- Lives in `.claude/commands/`
- YAML frontmatter for metadata
- Supports arguments ($1, $ARGUMENTS)
- Can include bash execution (!)
- Can reference files (@)

---

#### Choose **Skill** When:
- Need specialized domain knowledge or procedures
- Have reusable scripts, references, or assets
- Claude needs "onboarding" for specific domains
- Tasks require deterministic reliability (scripts)
- Knowledge is too specialized for general Claude

**Examples:**
- `pdf-editor` - PDF manipulation with bundled scripts
- `big-query` - Database schemas and query patterns
- `brand-guidelines` - Company assets and standards

**Key characteristics:**
- Directory with SKILL.md + bundled resources
- Scripts for deterministic operations
- References for domain knowledge
- Assets for output templates
- Progressive disclosure (metadata → body → resources)

---

#### Choose **Subagent** When:
- Need focused AI agent for specific responsibility
- Want to parallelize work (multiple reviewers)
- Task requires isolated context and permissions
- Agent should have restricted tool access
- Need specialized persona with clear output format

**Examples:**
- `security-reviewer` - OWASP vulnerability scanning
- `api-implementer` - REST endpoint implementation
- `performance-tester` - Benchmark and analyze

**Key characteristics:**
- Single markdown file in `.claude/agents/`
- Restricted tool permissions
- Detailed system prompt with persona
- Cannot ask follow-up questions
- Can be invoked via Task tool

---

#### Choose **Hook** When:
- Need automated response to events
- Want validation before operations
- Need post-operation automation (formatting, linting)
- Want to enforce project standards
- Integration with external tools/APIs

**Examples:**
- Pre-edit file protection
- Post-edit auto-formatting
- Stop hook for running tests
- Session start initialization

**Key characteristics:**
- Shell scripts executed on events
- JSON input/output for complex decisions
- Exit codes control flow (0=allow, 2=block)
- Configured in settings.json
- 9 event types available

---

## Workflow: Analyzing User Intent

### Step 1: Gather Requirements

Ask clarifying questions to understand the user's needs:

1. **What problem are you solving?**
   - Automation of repetitive tasks?
   - Adding domain expertise?
   - Parallelizing work?
   - Enforcing standards?

2. **When should it trigger?**
   - User-invoked (Command)
   - Task-based (Skill/Subagent)
   - Event-driven (Hook)

3. **What does it need access to?**
   - Specific tools only?
   - Full capabilities?
   - Read-only?

4. **Who will use it?**
   - Just you?
   - Whole team?
   - Across projects?

### Step 2: Apply Decision Matrix

Based on answers, determine the best tool type:

```
IF need reusable prompt/workflow shortcut
   AND user-invoked
   → Recommend COMMAND

IF need specialized knowledge/procedures
   AND have scripts/references/assets to bundle
   → Recommend SKILL

IF need focused AI agent
   AND can work independently
   AND want tool restrictions
   → Recommend SUBAGENT

IF need automated event response
   AND trigger is system event
   → Recommend HOOK
```

### Step 3: Route to Specialized Creator

Once tool type is determined, invoke the appropriate creator skill:

| Tool Type | Creator Skill | Init Script |
|-----------|--------------|-------------|
| Command | command-creator | `init_command.py` |
| Skill | skill-developer | `init_skill.py` |
| Subagent | subagent-creator | `init_subagent.py` |
| Hook | hooks-creator | `init_hook.py` |

Provide the user with:
1. Recommendation rationale
2. Quick start command
3. Relevant templates
4. Best practices summary

## Comparison Table

| Aspect | Command | Skill | Subagent | Hook | Plugin |
|--------|---------|-------|----------|------|--------|
| **Trigger** | User types `/name` | Claude decides | User/Command invokes | System event | `/plugin` |
| **Purpose** | Prompt shortcut | Domain expertise | Focused agent | Event automation | Bundle tools |
| **Location** | `.claude/commands/` | `.claude/skills/` | `.claude/agents/` | `.claude/hooks/` | Via registry |
| **Format** | Single .md file | Directory + SKILL.md | Single .md file | Shell script | Package |
| **Tool access** | Configurable | Full (by default) | Configurable | N/A (runs external) | Varies |
| **Arguments** | Yes ($1, $ARGUMENTS) | No | Via Task prompt | JSON input | N/A |
| **Team sharing** | Version controlled | Version controlled | Version controlled | Version controlled | Marketplace |
| **Use case** | "Format my code" | "Query BigQuery" | "Review for security" | "Lint after edit" | "Complete toolset" |

## Common Patterns and Anti-Patterns

### Pattern 1: Workflow Automation
**Need:** Automate multi-step development workflow

**Good:** Slash command with workflow template
```bash
python3 init_command.py pr-workflow "Complete PR workflow" \
  --template workflow \
  --allowed-tools "Bash(git:*),Read,Edit,Grep,Glob"
```

**Anti-pattern:** Creating a skill for simple workflow (overkill)

---

### Pattern 2: Domain Expertise
**Need:** Add company-specific knowledge and procedures

**Good:** Skill with references and scripts
```bash
python3 init_skill.py company-standards --path .claude/skills
```
Then add `references/coding-standards.md`, `references/api-conventions.md`

**Anti-pattern:** Putting all knowledge in a command (unmanageable)

---

### Pattern 3: Code Review
**Need:** Focused code review with specific criteria

**Good:** Subagent with restricted permissions
```bash
python3 init_subagent.py security-reviewer \
  "Reviews code for OWASP vulnerabilities" \
  --template code-reviewer \
  --tools "Read,Grep,Glob"
```

**Anti-pattern:** Full-permission subagent (defeats purpose)

---

### Pattern 4: Quality Enforcement
**Need:** Automatically lint code after edits

**Good:** PostToolUse hook
```bash
python3 init_hook.py auto-lint --event PostToolUse --path .claude/hooks
```

**Anti-pattern:** Command that user must remember to run (unreliable)

---

### Pattern 5: Hybrid Solution
**Need:** Complex automation with multiple components

**Good:** Combine tool types
- Command: Entry point (`/deploy`)
- Subagent: Validation (`deployment-validator`)
- Hook: Post-deploy notification

**Example:**
```bash
# Create deployment command
python3 init_command.py deploy "Deploy with validation" \
  --template workflow --allowed-tools "Task,Bash"

# Create validation subagent
python3 init_subagent.py deployment-validator \
  "Validates deployment configuration" \
  --template tester --tools "Read,Grep,Glob"

# Create notification hook
python3 init_hook.py deploy-notify --event SubagentStop --path .claude/hooks
```

## Best Practices Summary

### Universal Practices (All Tool Types)

1. **Single Responsibility** - Each tool does one thing well
2. **Clear Naming** - Lowercase + hyphens, descriptive
3. **Detailed Descriptions** - Action-oriented, specific trigger conditions
4. **Minimal Permissions** - Only grant necessary tools/access
5. **Test Before Use** - Validate with provided scripts

### Tool-Specific Practices

#### Commands
- Use templates for common patterns
- Validate with `validate_command.py`
- Use argument hints for clarity
- Restrict tools with `allowed-tools`

#### Skills
- Keep SKILL.md lean, use references for details
- Bundle scripts for deterministic operations
- Follow progressive disclosure
- Package for distribution

#### Subagents
- Detailed system prompts (can't ask follow-ups)
- Include success criteria and examples
- Match model to task complexity
- Read-only for reviewers

#### Hooks
- Validate all JSON input
- Use absolute paths
- Check exit codes carefully
- Test with `test_hook.sh`

## Quick Start Examples

### Example 1: "I want to automate code formatting"

**Analysis:** Event-driven automation → Hook

```bash
# Create PostToolUse hook for auto-formatting
python3 .claude/skills/hooks-creator/scripts/init_hook.py \
  auto-format --event PostToolUse --path .claude/hooks
```

Then customize to run Prettier/ESLint on edited files.

---

### Example 2: "I need a shortcut to review PRs"

**Analysis:** Reusable workflow shortcut → Command

```bash
# Create PR review command
python3 .claude/skills/command-creator/scripts/init_command.py \
  review-pr "Comprehensive PR review workflow" \
  --template workflow \
  --argument-hint "[pr-number]" \
  --allowed-tools "Bash(git:*),Read,Grep,Glob"
```

---

### Example 3: "I want Claude to understand our database schema"

**Analysis:** Domain expertise with references → Skill

```bash
# Create database skill
python3 .claude/skills/skill-developer/scripts/init_skill.py \
  database-expert --path .claude/skills
```

Then add `references/schema.md` with table definitions and relationships.

---

### Example 4: "I need parallel security reviews"

**Analysis:** Focused agents for parallel work → Subagents

```bash
# Create multiple focused reviewers
python3 .claude/skills/subagent-creator/scripts/init_subagent.py \
  sql-injection-checker "Checks for SQL injection vulnerabilities" \
  --template code-reviewer --tools "Read,Grep,Glob"

python3 .claude/skills/subagent-creator/scripts/init_subagent.py \
  xss-checker "Checks for XSS vulnerabilities" \
  --template code-reviewer --tools "Read,Grep,Glob"
```

---

### Example 5: "I'm not sure what I need"

**Questions to ask:**
1. Is this triggered by you or automatically? (Command/Skill vs Hook)
2. Does it need Claude's intelligence? (Skill/Subagent vs Command/Hook)
3. Should it have restricted permissions? (Subagent vs Skill)
4. Do you have assets to bundle? (Skill vs Command)

## Integration with Existing Creators

This skill routes to specialized creators rather than duplicating their functionality:

### Creator Skills Reference

| Skill | Location | Key Resources |
|-------|----------|---------------|
| command-creator | `.claude/skills/command-creator/` | 6 templates, init/validate scripts |
| skill-developer | `.claude/skills/skill-developer/` | init/package scripts, structure guide |
| subagent-creator | `.claude/skills/subagent-creator/` | 7 templates, init/validate scripts |
| hooks-creator | `.claude/skills/hooks-creator/` | 5 event templates, test scripts |

### Workflow Integration

```
User Request
    │
    ▼
skill-generator-tool
    │
    ├─ Analyze intent
    ├─ Apply decision matrix
    ├─ Recommend tool type
    │
    ▼
Route to creator skill
    │
    ├─ command-creator
    ├─ skill-developer
    ├─ subagent-creator
    └─ hooks-creator
    │
    ▼
Tool created & validated
```

## Resources

### References
- **`decision-matrix.md`** - Detailed decision criteria and examples
- **`comparison-table.md`** - Side-by-side tool comparison

### Related Skills
- **command-creator** - Slash command creation
- **skill-developer** - Skill creation and packaging
- **subagent-creator** - Subagent definition
- **hooks-creator** - Hook script creation

### Official Documentation
- [Slash Commands](https://code.claude.com/docs/en/slash-commands)
- [Skills](https://code.claude.com/docs/en/skills)
- [Subagents](https://docs.anthropic.com/en/docs/claude-code/sub-agents)
- [Hooks](https://docs.anthropic.com/en/docs/claude-code/hooks)
- [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
- [Agent Skills Engineering Blog](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills)
- [Plugins](https://claude.com/blog/claude-code-plugins)

## Troubleshooting

### "Which tool type should I use?"
Use the decision matrix above. Key questions:
- Event-driven? → Hook
- User-invoked shortcut? → Command
- Domain expertise? → Skill
- Focused agent? → Subagent

### "Can I combine multiple tool types?"
Yes! Complex workflows often benefit from:
- Command as entry point
- Subagents for parallel work
- Hooks for automation
- Skills for domain knowledge

### "My tool isn't working"
1. Check file location and naming
2. Run validation script
3. Verify permissions/tools
4. Check logs for errors
5. Test with simple example first

### "Should I create a new tool or modify existing?"
Prefer modifying when:
- Existing tool covers 70%+ of need
- Change is incremental
- Team uses current version

Create new when:
- Significantly different purpose
- New domain/workflow
- Current tool is complex enough
