# Tool Creator Skills - Architecture & Relationships

---

## Overall Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Claude Code Artifact System                   │
└─────────────────────────────────────────────────────────────────┘
                               │
        ┌──────────────────────┼──────────────────────┐
        │                      │                      │
        ▼                      ▼                      ▼
┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│   Slash Commands │  │      Skills      │  │   Hook Scripts   │
│  (.claude/       │  │  (.claude/       │  │  (.claude/       │
│   commands/)     │  │   skills/)       │  │   hooks/)        │
└──────────────────┘  └──────────────────┘  └──────────────────┘
        │                      │                      │
        └──────────────────────┼──────────────────────┘
                               │
                               ▼
                    ┌──────────────────────┐
                    │    Subagents         │
                    │  (.claude/agents/)   │
                    └──────────────────────┘


┌─────────────────────────────────────────────────────────────────┐
│                    Tool Creator Skills Layer                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐    │
│  │   command-     │  │  skill-developer │  │ hooks-creator  │    │
│  │   creator      │  │                │  │                │    │
│  └────────────────┘  └────────────────┘  └────────────────┘    │
│           │                  │                    │              │
│           └──────────────────┼────────────────────┘              │
│                              │                                   │
│  ┌────────────────┐──────────────────┐──────────────────┐      │
│  │ subagent-      │ Command/Skill/   │ Hook-specific    │      │
│  │ creator        │ Subagent-specific│ templates        │      │
│  └────────────────┴──────────────────┴──────────────────┘      │
│                              │                                   │
│                    ┌─────────┴──────────┐                        │
│                    │ Shared Core Logic  │                        │
│                    │ (extraction needed)│                        │
│                    └───────────────────┘                         │
│                              │                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Utilities Layer (Current: Duplicated)                   │  │
│  ├──────────────────────────────────────────────────────────┤  │
│  │ • File path resolution (project vs user)                 │  │
│  │ • Template loading & processing                          │  │
│  │ • YAML frontmatter generation                            │  │
│  │ • Input validation (names, formats)                      │  │
│  │ • Error handling & user feedback                         │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Initialization Flow (Unified Pattern)

```
                          User Input
                             │
                             ▼
                    ┌─────────────────┐
                    │ Parse Arguments │
                    │ (argparse)      │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────────┐
                    │ Validate Input      │
                    │ • Name format       │
                    │ • Required fields   │
                    │ • File conflicts    │
                    └────────┬────────────┘
                             │
                             ▼
                    ┌─────────────────────┐
                    │ Load Template       │
                    │ (if specified)      │
                    │ assets/templates/   │
                    └────────┬────────────┘
                             │
                             ▼
                    ┌─────────────────────┐
                    │ Build YAML          │
                    │ Frontmatter         │
                    │ • name/description  │
                    │ • metadata fields   │
                    └────────┬────────────┘
                             │
                             ▼
                    ┌─────────────────────┐
                    │ Merge Content       │
                    │ frontmatter + body  │
                    └────────┬────────────┘
                             │
                             ▼
                    ┌─────────────────────┐
                    │ Create File/Dir     │
                    │ Set permissions     │
                    │ (.claude/*)         │
                    └────────┬────────────┘
                             │
                             ▼
                    ┌─────────────────────┐
                    │ Report Success      │
                    │ • Configuration     │
                    │ • Next steps        │
                    │ • Usage examples    │
                    └─────────────────────┘
```

---

## File & Directory Structure

```
.claude/
│
├── commands/                          ← Commands (6 template types)
│   ├── basic.md                       ├─ basic
│   ├── format.md                      ├─ simple-action
│   ├── dev/                           ├─ workflow
│   │   └── review-pr.md               ├─ prompt-expansion
│   └── ...                            ├─ agent-caller
│                                      └─ full-power
│
├── skills/                            ← Skills (4 structural types)
│   ├── skill-developer/                 ├─ workflow-based
│   ├── command-creator/               ├─ task-based
│   │   ├── SKILL.md                   ├─ reference/guidelines
│   │   ├── scripts/                   └─ capabilities-based
│   │   ├── assets/templates/
│   │   └── references/
│   └── ...
│
├── agents/                            ← Subagents (7 role templates)
│   ├── code-reviewer.md               ├─ basic
│   ├── api-implementer.md             ├─ code-reviewer
│   └── ...                            ├─ debugger
│                                      ├─ architect
│                                      ├─ implementer
│                                      ├─ researcher
│                                      └─ tester
│
└── hooks/                             ← Hooks (9 event types)
    ├── lint-on-stop.sh                ├─ PreToolUse
    ├── format-on-edit.sh              ├─ PostToolUse
    └── ...                            ├─ Stop
                                       ├─ UserPromptSubmit
                                       ├─ Notification
                                       ├─ SessionStart/End
                                       ├─ PreCompact
                                       └─ SubagentStop

settings.local.json                    ← Hook registration
```

---

## Data Flow: Command Creation Example

```
User: "Create a slash command for code review"
                        │
                        ▼
    ┌───────────────────────────────────────┐
    │ Skill: command-creator                │
    │ Triggers on keywords: create command  │
    └───────────────────────────────────────┘
                        │
                        ▼
    ┌───────────────────────────────────────┐
    │ Clarifying Questions:                 │
    │ • Template? (workflow)                │
    │ • Tools? (Bash, Git)                  │
    │ • Arguments? (PR number)              │
    └───────────────────────────────────────┘
                        │
                        ▼
    ┌───────────────────────────────────────┐
    │ init_command.py                       │
    │ • Parse args                          │
    │ • Validate: review-pr ✓               │
    │ • Load: workflow.md                   │
    │ • Build YAML frontmatter              │
    │ • Generate .claude/commands/          │
    │   review-pr.md                        │
    └───────────────────────────────────────┘
                        │
                        ▼
    ┌───────────────────────────────────────┐
    │ Generated Command:                    │
    │ .claude/commands/review-pr.md         │
    │                                       │
    │ ---                                   │
    │ description: Review PR changes        │
    │ allowed-tools: Bash(git:*),Read,Grep │
    │ argument-hint: [pr-number]            │
    │ ---                                   │
    │                                       │
    │ # PR Review Workflow                  │
    │ [template content]                    │
    └───────────────────────────────────────┘
                        │
                        ▼
    ┌───────────────────────────────────────┐
    │ User Customizes:                      │
    │ • Edit .claude/commands/review-pr.md  │
    │ • Add project-specific checks         │
    │ • Test with: /review-pr 123           │
    │ • Validate: validate_command.py       │
    └───────────────────────────────────────┘
```

---

## Template Inheritance Pattern

```
asset/templates/{type}.md
         │
         ├─ YAML Frontmatter
         │  (placeholder, gets replaced)
         │
         └─ Content
            (kept, optionally modified)
                │
                ▼
         ┌──────────────────────┐
         │ Load Template        │
         │ Split on '---'       │
         │ Extract content[2]   │
         └──────────────────────┘
                │
                ▼
         ┌──────────────────────┐
         │ Generate Frontmatter │
         │ From CLI arguments   │
         └──────────────────────┘
                │
                ▼
         ┌──────────────────────┐
         │ Combine & Write      │
         │ ---                  │
         │ [generated YAML]     │
         │ ---                  │
         │ [template content]   │
         └──────────────────────┘
```

---

## Validation Architecture

```
All Artifacts
      │
      ├─ YAML Validation
      │  ├─ Frontmatter format
      │  ├─ Required fields
      │  └─ Field format
      │
      ├─ Name Validation
      │  ├─ Lowercase + hyphens
      │  ├─ Length check
      │  └─ No conflicts
      │
      ├─ Content Validation
      │  ├─ Tool existence (commands/agents)
      │  ├─ Event type (hooks)
      │  └─ Structure completeness
      │
      └─ Output
         ├─ ✅ Pass (all checks)
         ├─ ⚠️  Warning (non-critical)
         └─ ❌ Error (must fix)
```

---

## Shared Utilities (Current State: Duplicated)

```
All 4 Scripts (~1000 lines duplicated)
│
├─ Path Resolution
│  ├─ Project location: .claude/{type}/
│  ├─ User location: ~/.claude/{type}/
│  └─ Namespace handling: .claude/{type}/namespace/
│
├─ Template Loading
│  ├─ Locate: assets/templates/{name}.md
│  ├─ Parse: Split on '---'
│  ├─ Extract: content[2] (body)
│  └─ Handle: Missing templates
│
├─ YAML Building
│  ├─ Parse CLI arguments
│  ├─ Map to YAML fields
│  ├─ Validate field values
│  └─ Format as YAML block
│
├─ File Operations
│  ├─ Create directories
│  ├─ Check existence
│  ├─ Set permissions (chmod)
│  └─ Write content
│
├─ Validation
│  ├─ Name format (lowercase-hyphen)
│  ├─ Required fields
│  ├─ Tool names
│  └─ Event types
│
├─ Error Handling
│  ├─ Argument validation
│  ├─ File conflicts
│  ├─ Permission errors
│  └─ Helpful messages
│
└─ User Feedback
   ├─ Success summary
   ├─ Configuration display
   ├─ Next steps
   └─ Emoji indicators (✅⚠️❌)
```

---

## Proposed Unified Architecture

```
unified-tool-generator/
│
├── core/                              ← Shared Utilities
│   ├── file_handler.py
│   │   ├─ get_artifact_path()
│   │   ├─ ensure_directory()
│   │   ├─ write_artifact()
│   │   └─ check_conflicts()
│   │
│   ├── validator.py
│   │   ├─ validate_name()
│   │   ├─ validate_metadata()
│   │   ├─ validate_tools()
│   │   └─ ValidationResult
│   │
│   ├── frontmatter.py
│   │   ├─ build_yaml()
│   │   ├─ parse_yaml()
│   │   ├─ merge_content()
│   │   └─ YamlSchema
│   │
│   └── template_loader.py
│       ├─ load_template()
│       ├─ extract_body()
│       ├─ find_template()
│       └─ TemplateNotFound
│
├── tools/                             ← Tool-Specific Logic
│   ├── command_tool.py
│   │   ├─ CommandConfig
│   │   ├─ validate_command()
│   │   └─ COMMAND_TEMPLATES
│   │
│   ├── skill_tool.py
│   │   ├─ SkillConfig
│   │   ├─ create_skill_directory()
│   │   └─ SKILL_PATTERNS
│   │
│   ├── hook_tool.py
│   │   ├─ HookConfig
│   │   ├─ generate_hook_script()
│   │   └─ EVENT_TEMPLATES
│   │
│   └── subagent_tool.py
│       ├─ SubagentConfig
│       ├─ validate_subagent()
│       └─ SUBAGENT_TEMPLATES
│
├── unified_init.py                    ← Single Entry Point
│   ├─ ArgumentParser (unified)
│   ├─ Tool dispatcher
│   └─ Error handling
│
└── utils.py                           ← Shared Utilities
    ├─ format_success()
    ├─ format_error()
    ├─ print_next_steps()
    └─ EMOJI_MAP
```

---

## Integration Points

### Skill Activation (UserPromptSubmit Hook)
```
User: "Create a slash command"
  │
  ▼
skill-activation-prompt.ts
  │
  ├─ Analyze: "create" + "command"
  ├─ Match: skill-rules.json patterns
  │
  ▼
Suggest: command-creator skill
  │
  ▼
User Invokes: /Skill command-creator
```

### Command/Subagent Interaction
```
Slash Command
  │
  ├─ Can call: Task tool
  │
  ▼
Invoke Subagent
  │
  ├─ Read response
  ├─ Format results
  │
  ▼
Return to user
```

### Hook Registration
```
Generated Hook
  │
  ├─ User manually adds to:
  │  .claude/settings.local.json
  │
  ├─ Or uses /hooks command
  │
  ▼
Hook System Loads
  │
  ├─ Registers trigger
  ├─ Validates script
  │
  ▼
Event Triggered
  │
  ├─ Executes hook
  ├─ Parses JSON input
  │
  ▼
Decision/Action
```

---

## Quality & Testing Strategy

```
Tool Creator Artifacts
         │
         ├─ Static Analysis
         │  ├─ YAML validation
         │  ├─ Naming conventions
         │  ├─ Syntax checking
         │  └─ validate_*.py scripts
         │
         ├─ Runtime Testing
         │  ├─ Actual command execution
         │  ├─ Hook event simulation
         │  ├─ Subagent invocation
         │  └─ test_hook.sh
         │
         ├─ Integration Testing
         │  ├─ Artifact creation flow
         │  ├─ Template loading
         │  ├─ File system operations
         │  └─ Error handling
         │
         └─ Best Practices
            ├─ Permission hygiene
            ├─ Naming consistency
            ├─ Documentation quality
            └─ Example sufficiency
```

---

## Current State vs. Unified Target

```
CURRENT STATE (4 Separate Tools)
┌─────────────────────────────────────┐
│ command-creator  skill-developer      │
├─────────────────────────────────────┤
│ init_command.py  init_skill.py      │
│ validate_        package_            │
│ (200+ lines)     (300+ lines)        │
├─────────────────────────────────────┤
│ Duplicated Code:                    │
│ • Path resolution                   │
│ • Template loading                  │
│ • YAML generation                   │
│ (estimated 60-70% overlap)          │
└─────────────────────────────────────┘

UNIFIED TARGET
┌─────────────────────────────────────┐
│ Unified Tool Generator              │
├─────────────────────────────────────┤
│ core/                               │
│ ├─ file_handler.py (shared)        │
│ ├─ validator.py (shared)           │
│ ├─ frontmatter.py (shared)         │
│ └─ template_loader.py (shared)     │
├─────────────────────────────────────┤
│ tools/                              │
│ ├─ command_tool.py (specialized)   │
│ ├─ skill_tool.py (specialized)     │
│ ├─ hook_tool.py (specialized)      │
│ └─ subagent_tool.py (specialized)  │
├─────────────────────────────────────┤
│ unified_init.py (single interface) │
│                                     │
│ Result: 40-50% code reduction      │
│ Better maintainability             │
│ Easier to extend                   │
└─────────────────────────────────────┘
```

---

**Last Updated**: 2025-11-19  
**Architecture Version**: 1.0  
**Status**: Documented, ready for implementation
