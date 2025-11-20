# Tool Creator Skills - Quick Reference

**Status**: 4 skills analyzed  
**Date**: 2025-11-19  
**Saved Analysis**: `/docs/analysis-tool-creators.md`

---

## Skills Overview

| Skill | Artifact | Location | Templates | Init Script |
|-------|----------|----------|-----------|------------|
| **command-creator** | `.md` file | `.claude/commands/` | 6 patterns | init_command.py |
| **skill-developer** | Directory | `.claude/skills/` | 4 structures | init_skill.py |
| **hooks-creator** | `.sh` script | `.claude/hooks/` | 9 events | init_hook.py |
| **subagent-creator** | `.md` file | `.claude/agents/` | 7 roles | init_subagent.py |

---

## Key Findings

### Architecture Consistency ✅
All 4 skills follow **identical initialization pattern**:
1. Parse arguments
2. Validate input format
3. Load template (if specified)
4. Generate YAML frontmatter
5. Create file/directory
6. Show success + next steps

### Shared Patterns (10 total)
1. Consistent file location logic (project vs user)
2. Unified template loading (assets/templates/)
3. YAML frontmatter building pattern
4. File validation approach
5. Error reporting with emoji (✅⚠️❌)
6. Argument parsing (mostly argparse)
7. Directory organization (.claude/*)
8. Template naming (kebab-case)
9. Metadata concepts (name, description)
10. Documentation structure (SKILL.md + references)

### Code Reuse Opportunities
**High Priority** (1000+ lines could be shared):
- File location logic
- Template loading
- YAML frontmatter building
- File validation

**Medium Priority**:
- Error reporting
- Argument parsing
- Next steps display

---

## File Locations (Absolute Paths)

### Command Creator
- **SKILL.md**: `/home/user/cc-skills/.claude/skills/command-creator/SKILL.md`
- **Init Script**: `/home/user/cc-skills/.claude/skills/command-creator/scripts/init_command.py`
- **Templates**: `/home/user/cc-skills/.claude/skills/command-creator/assets/templates/`
- **References**: `/home/user/cc-skills/.claude/skills/command-creator/references/`

### Skill Developer
- **SKILL.md**: `/home/user/cc-skills/.claude/skills/skill-developer/SKILL.md`
- **Init Script**: `/home/user/cc-skills/.claude/skills/skill-developer/scripts/init_skill.py`
- **Validation**: `/home/user/cc-skills/.claude/skills/skill-developer/scripts/quick_validate.py`
- **Packaging**: `/home/user/cc-skills/.claude/skills/skill-developer/scripts/package_skill.py`

### Hooks Creator
- **SKILL.md**: `/home/user/cc-skills/.claude/skills/hooks-creator/SKILL.md`
- **Init Script**: `/home/user/cc-skills/.claude/skills/hooks-creator/scripts/init_hook.py`
- **Templates**: `/home/user/cc-skills/.claude/skills/hooks-creator/assets/templates/`
- **References**: `/home/user/cc-skills/.claude/skills/hooks-creator/references/`

### Subagent Creator
- **SKILL.md**: `/home/user/cc-skills/.claude/skills/subagent-creator/SKILL.md`
- **Init Script**: `/home/user/cc-skills/.claude/skills/subagent-creator/scripts/init_subagent.py`
- **Templates**: `/home/user/cc-skills/.claude/skills/subagent-creator/assets/templates/`
- **References**: `/home/user/cc-skills/.claude/skills/subagent-creator/references/`

---

## Template Overview

### Commands (6 templates)
- `basic.md` - Minimal structure
- `simple-action.md` - Single action
- `workflow.md` - Multi-step
- `prompt-expansion.md` - Long prompt
- `agent-caller.md` - Subagent delegation
- `full-power.md` - Complex multi-feature

### Skills (4 structural patterns)
- **Workflow-Based** - Sequential processes
- **Task-Based** - Tool collections
- **Reference/Guidelines** - Standards
- **Capabilities-Based** - Integrated systems

### Hooks (9 event types)
- PreToolUse, PostToolUse
- Stop, UserPromptSubmit
- Notification
- SessionStart, SessionEnd
- PreCompact, SubagentStop

### Subagents (7 role templates)
- `basic.md` - Custom
- `code-reviewer.md` - Code review
- `debugger.md` - Bug fixing
- `architect.md` - Design
- `implementer.md` - Implementation
- `researcher.md` - Research
- `tester.md` - Testing

---

## YAML Frontmatter Patterns

### Commands
```yaml
description: Brief description
allowed-tools: Tool1, Tool2, Bash(git:*)
argument-hint: [args]
model: claude-3-5-haiku-20241022
disable-model-invocation: false
```

### Skills
```yaml
name: skill-name
description: What it does and when to use
```

### Subagents
```yaml
name: subagent-name
description: When to use this
tools: Read, Grep, Glob
model: sonnet
```

### Hooks
(Event type in filename, not frontmatter)
```bash
#!/bin/bash
# Event: PreToolUse, PostToolUse, Stop, etc.
```

---

## Initialization Script Usage

### Commands
```bash
python3 init_command.py <name> "<description>" \
  --template <template> \
  --allowed-tools "Tools" \
  --location project|user
```

### Skills
```bash
python3 init_skill.py <skill-name> --path <output-directory>
```

### Hooks
```bash
python3 init_hook.py <hook-name> --event <event-type> --path <output-dir>
```

### Subagents
```bash
python3 init_subagent.py <name> "<description>" \
  --template <template> \
  --tools "Tools" \
  --location project|user
```

---

## Validation & Testing

### Available Tools
| Skill | Validator | Tester |
|-------|-----------|--------|
| Commands | validate_command.py | N/A |
| Skills | package_skill.py | N/A |
| Hooks | validate_hook.sh | test_hook.sh |
| Subagents | validate_subagent.py | N/A |

### Validation Output Pattern
```
✅ Pass: All checks successful
⚠️  Warning: Non-critical issues
❌ Error: Must fix before using
```

---

## Registration Status

**Current**: None of the 4 tools are registered in skill-rules.json
**Impact**: Available via `/Skill` but don't auto-trigger

### Recommended Registration
Add to `.claude/skills/skill-rules.json`:

```json
{
  "command-creator": {
    "keywords": ["create command", "slash command"],
    "intentPatterns": ["(create|add).*?command"]
  },
  "skill-developer": {
    "keywords": ["create skill", "new skill", "skill development"],
    "intentPatterns": ["(create|add|build|develop).*?skill"]
  },
  "hooks-creator": {
    "keywords": ["create hook"],
    "intentPatterns": ["(create|add).*?hook"]
  },
  "subagent-creator": {
    "keywords": ["create subagent", "new agent"],
    "intentPatterns": ["(create|add).*?(subagent|agent)"]
  }
}
```

---

## Best Practices Summary

### All Tools Enforce
- Single-responsibility design
- Permission hygiene (minimal tool access)
- Clear action-oriented naming
- Kebab-case naming convention
- Proper description format

### Consistent Features
- Project vs user scope
- Template system
- YAML metadata
- Error handling with context
- Next steps guidance

---

## Unified Generator Recommendation

### Why Unification Makes Sense
- ✅ 1000+ lines of duplicated code
- ✅ Identical initialization pattern
- ✅ Same file/directory logic
- ✅ Common YAML handling
- ✅ Similar validation approach

### Proposed Architecture
```
unified-tool-generator/
├── core/
│   ├── file_handler.py          # File I/O, paths
│   ├── validator.py             # Shared validation
│   ├── frontmatter.py           # YAML handling
│   └── template_loader.py       # Template system
├── tools/
│   ├── command_tool.py          # Commands
│   ├── skill_tool.py            # Skills
│   ├── hook_tool.py             # Hooks
│   └── subagent_tool.py         # Subagents
└── unified_init.py              # Single entry point
```

### Benefits
- Reduce code by ~50%
- Improve maintainability
- Consistent improvements
- Unified learning curve
- Support new artifact types easily

---

## Quick Links

- **Full Analysis**: `/docs/analysis-tool-creators.md`
- **Command Creator**: `.claude/skills/command-creator/SKILL.md`
- **Skill Developer**: `.claude/skills/skill-developer/SKILL.md`
- **Hooks Creator**: `.claude/skills/hooks-creator/SKILL.md`
- **Subagent Creator**: `.claude/skills/subagent-creator/SKILL.md`

---

## Next Steps

1. Review full analysis document
2. Consider unified generator implementation
3. Register tools in skill-rules.json
4. Create integration tests
5. Document shared utilities pattern

---

**Last Updated**: 2025-11-19  
**Analysis Scope**: Comprehensive feature/pattern analysis  
**Quality**: Production-ready, well-documented code
