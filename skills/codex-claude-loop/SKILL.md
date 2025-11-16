---
name: codex-claude-loop
description: Orchestrates a dual-AI engineering loop where Claude Code plans and implements, while Codex validates and reviews, with continuous feedback for optimal code quality
---

# Codex-Claude Engineering Loop Skill

## Core Workflow Philosophy
This skill implements a balanced engineering loop:
- **Claude Code**: Architecture, planning, and execution
- **Codex**: Validation and code review
- **Continuous Review**: Each AI reviews the other's work
- **Context Handoff**: Always continue with whoever last cleaned up
- **Smart Decomposition**: Automatically split complex tasks to maintain review quality

## Phase 0: Complexity Assessment
Before starting any task, evaluate its complexity to determine if decomposition is needed:

1. **Assess Complexity Factors**:
   - Number of files to be modified (>5 files = high complexity)
   - Scope of changes (architecture changes, cross-module refactoring = high complexity)
   - Logic complexity (complex algorithms, multiple edge cases = high complexity)
   - Number of dependencies between changes

2. **Calculate Complexity Score**:
   - Low (0-2 factors): Proceed normally
   - Medium (3-4 factors): Consider decomposition
   - High (5+ factors): Strongly recommend decomposition

3. **Propose Decomposition** (if complexity is Medium or High):
   - Ask user via `AskUserQuestion` whether to decompose the task
   - If yes, proceed to Phase 1.5
   - If no, proceed to Phase 1 but warn about potential long review times

## Phase 1: Planning with Claude Code
1. Start by creating a detailed plan for the task
2. Break down the implementation into clear steps
3. Document assumptions and potential issues
4. Output the plan in a structured format

## Phase 1.5: Task Decomposition (When Approved)
When user approves task decomposition, split the work into manageable sub-tasks:

1. **Identify Natural Boundaries**:
   - By file/module (e.g., "Update authentication module", "Refactor user service")
   - By feature (e.g., "Add login validation", "Implement password reset")
   - By layer (e.g., "Update data models", "Update API endpoints", "Update UI")

2. **Create Sub-Task List**:
   - Each sub-task should be independently reviewable
   - Define dependencies between sub-tasks (which must be done first)
   - Estimate complexity of each sub-task (should be "Low" individually)

3. **Execution Strategy**:
   - Process sub-tasks in dependency order
   - For each sub-task, run the full loop: Plan (Phase 1) → Validate (Phase 2) → Execute (Phase 4) → Review (Phase 5)
   - Use `TodoWrite` tool to track progress across sub-tasks
   - Mark sub-tasks as completed before moving to the next

4. **Progress Tracking Format**:
   ```
   Task Decomposition Plan:
   [✓] Sub-task 1: Description (COMPLETED)
   [→] Sub-task 2: Description (IN PROGRESS)
   [ ] Sub-task 3: Description (PENDING)
   [ ] Sub-task 4: Description (PENDING - depends on 2)
   ```

## Phase 2: Plan Validation with Codex
1. Ask user (via `AskUserQuestion`): 
   - Model: `gpt-5` or `gpt-5-codex`
   - Reasoning effort: `low`, `medium`, or `high`
2. Send the plan to Codex for validation:
```bash
   echo "Review this implementation plan and identify any issues:
   [Claude's plan here]
   
   Check for:
   - Logic errors
   - Missing edge cases
   - Architecture flaws
   - Security concerns" | codex exec -m  --config model_reasoning_effort="" --sandbox read-only
```
3. Capture Codex's feedback

## Phase 3: Feedback Loop
If Codex finds issues:
1. Summarize Codex's concerns to the user
2. Refine the plan based on feedback
3. Ask user (via `AskUserQuestion`): "Should I revise the plan and re-validate, or proceed with fixes?"
4. Repeat Phase 2 if needed

## Phase 4: Execution
Once the plan is validated:
1. **If task was decomposed** (Phase 1.5):
   - Display current sub-task progress using the tracking format
   - Implement only the current sub-task
   - After completion, mark sub-task as done via `TodoWrite`
   - Move to next sub-task and repeat from Phase 1

2. **For each implementation** (sub-task or full task):
   - Use available tools (Edit, Write, Read, etc.)
   - Execute each step carefully with proper error handling
   - Document what was implemented
   - Keep changes focused and reviewable

3. **Progress Communication**:
   - For decomposed tasks, always show: "Working on [X/N]: [Sub-task name]"
   - Provide context on what's remaining after each completion

## Phase 5: Cross-Review After Changes
After every change:
1. Send Claude's implementation to Codex for review:
   - Bug detection
   - Performance issues
   - Best practices validation
   - Security vulnerabilities
2. Claude analyzes Codex's feedback and decides:
   - Apply fixes immediately if issues are critical
   - Discuss with user if architectural changes needed
   - Document decisions made

## Phase 6: Iterative Improvement
1. After Codex review, Claude applies necessary fixes
2. For significant changes, send back to Codex for re-validation
3. Continue the loop until code quality standards are met
4. Use `codex exec resume --last` to continue validation sessions:
```bash
   echo "Review the updated implementation" | codex exec resume --last
```
   **Note**: Resume inherits all settings (model, reasoning, sandbox) from original session

## Recovery When Issues Are Found
When Codex identifies problems:
1. Claude analyzes the root cause
2. Implements fixes using available tools
3. Sends updated code back to Codex for verification
4. Repeats until validation passes

When implementation errors occur:
1. Claude reviews the error/issue
2. Adjusts implementation strategy
3. Re-validates with Codex before proceeding

## Best Practices
- **Always assess complexity first** (Phase 0) before diving into implementation
- **Decompose when recommended** - it saves time in the long run
- **Always validate plans** before execution
- **Never skip cross-review** after changes
- **Maintain clear handoff** between AIs
- **Document who did what** for context
- **Use resume** to preserve session state
- **Track sub-tasks diligently** with TodoWrite when decomposed
- **Keep sub-tasks independent** for easier review and rollback

## Command Reference
| Phase | Command Pattern | Purpose |
|-------|----------------|---------|
| Assess complexity | Analyze task scope and factors | Determine if decomposition needed |
| Ask to decompose | `AskUserQuestion` | Get user approval for task splitting |
| Track sub-tasks | `TodoWrite` with sub-task list | Maintain progress visibility |
| Validate plan | `echo "plan" \| codex exec --sandbox read-only` | Check logic before coding |
| Implement | Claude uses Edit/Write/Read tools | Claude implements the validated plan |
| Review code | `echo "review changes" \| codex exec --sandbox read-only` | Codex validates Claude's implementation |
| Continue review | `echo "next step" \| codex exec resume --last` | Continue validation session |
| Apply fixes | Claude uses Edit/Write tools | Claude fixes issues found by Codex |
| Re-validate | `echo "verify fixes" \| codex exec resume --last` | Codex re-checks after fixes |

## Error Handling
1. Stop on non-zero exit codes from Codex
2. Summarize Codex feedback and ask for direction via `AskUserQuestion`
3. Before implementing changes, confirm approach with user if:
   - Significant architectural changes needed
   - Multiple files will be affected
   - Breaking changes are required
4. When Codex warnings appear, Claude evaluates severity and decides next steps

## The Perfect Loop

### Simple Tasks (Low Complexity)
```
Plan (Claude) → Validate Plan (Codex) → Feedback →
Implement (Claude) → Review Code (Codex) → self-critique(Codex) →
Fix Issues (Claude) → Re-validate (Codex) → Repeat until perfect
```

### Complex Tasks (Medium/High Complexity)
```
Assess Complexity (Claude) → Ask User to Decompose →
Decompose into Sub-tasks (Claude) →
For Each Sub-task:
  └─> Plan (Claude) → Validate (Codex) →
      Implement (Claude) → Review (Codex) → self-critique(Codex) →
      Fix (Claude) → Re-validate (Codex) →
      Mark Complete → Next Sub-task
All Sub-tasks Complete → Task Done
```

This creates a self-correcting, high-quality engineering system where:
- **Claude** handles all code implementation and modifications
- **Codex** provides validation, review, and quality assurance
- **Decomposition** keeps reviews manageable and context focused
- **TodoWrite** tracks progress across complex multi-step implementations