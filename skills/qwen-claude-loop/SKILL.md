---
name: qwen-claude-loop
description: Orchestrates a dual-AI engineering loop where Qwen implements code solutions, while Claude Code validates and reviews, with continuous feedback for optimal code quality
---

# Qwen-Claude Engineering Loop Skill

## Core Workflow Philosophy
This skill implements a balanced engineering loop with reversed roles:
- **Claude Code**: Planning, validation, and code review
- **Qwen**: Code implementation and execution
- **Continuous Review**: Each AI reviews the other's work
- **Context Handoff**: Always maintain context between handoffs

## Phase 1: Planning with Claude Code
1. Start by creating a detailed plan for the task
2. Break down the implementation into clear steps
3. Document assumptions and potential issues
4. Output the plan in a structured format

## Phase 2: Implementation Request to Qwen
1. Ask user (via `AskUserQuestion`):
   - Model: Use default `qwen2.5-coder` or specify custom model
   - Implementation style: `concise`, `standard`, or `detailed`
2. Send the plan to Qwen for implementation:
```bash
   echo "Implement the following plan with working code:

   [Claude's plan here]

   Requirements:
   - Provide complete, working code
   - Include error handling
   - Follow best practices
   - Add inline comments for complex logic

   Output format:
   - File paths with full code
   - Explanation of implementation decisions
   - Any assumptions made" | qwen -p
```
3. Capture Qwen's implementation output

## Phase 3: Claude's Code Review
After receiving Qwen's implementation:
1. Claude analyzes the code for:
   - Logic correctness
   - Edge case handling
   - Security vulnerabilities
   - Performance issues
   - Code quality and best practices
   - Adherence to the original plan
2. Document findings in structured format:
   - ✅ What works well
   - ⚠️ Potential issues
   - 🔴 Critical problems
   - 💡 Improvement suggestions

## Phase 4: Feedback Loop
If Claude finds issues:
1. Summarize review findings to the user
2. Ask user (via `AskUserQuestion`): "Should I ask Qwen to revise the implementation, or should I apply fixes myself?"
3. If user chooses Qwen revision:
   - Send detailed feedback to Qwen for re-implementation
   - Repeat Phase 2-3
4. If user chooses Claude fixes:
   - Proceed to Phase 5

## Phase 5: Application and Integration
Depending on user choice:

**Option A: Claude applies fixes directly**
1. Claude uses Edit/Write tools to apply necessary corrections
2. Document all changes made
3. Keep Qwen's good parts, fix only the issues

**Option B: Request Qwen revision**
1. Send comprehensive feedback to Qwen:
```bash
   echo "Please revise your implementation based on this review:

   Original implementation:
   [Qwen's code]

   Issues found:
   - [Critical issues list]
   - [Warnings list]
   - [Suggestions list]

   Please provide updated implementation addressing these concerns." | qwen -p
```
2. Receive updated implementation
3. Claude reviews again (return to Phase 3)

## Phase 6: Final Validation
1. After implementation is finalized (by Qwen or Claude):
2. Claude performs final quality check:
   - All requirements met
   - No critical issues remain
   - Code is ready for use
3. Apply the code to actual files using Edit/Write tools
4. Document the complete implementation

## Recovery When Issues Are Found
When Claude's review identifies problems in Qwen's code:
1. Provide detailed, constructive feedback
2. Choose resolution path (Qwen revision vs Claude fix)
3. If Qwen revises: validate the updated implementation
4. If Claude fixes: apply corrections and document changes
5. Repeat until quality standards are met

When Qwen's implementation has errors:
1. Claude provides specific error analysis
2. Request targeted fixes from Qwen or apply directly
3. Validate the corrected implementation
4. Continue until code works correctly

## Best Practices
- **Claude creates comprehensive plans** before asking Qwen to implement
- **Qwen implements** based on detailed specifications
- **Claude reviews thoroughly** - never skip code review
- **Maintain clear context** in all Qwen requests
- **Document all decisions** and changes made
- **Iterate until perfect** - use the feedback loop fully

## Command Reference
| Phase | Command Pattern | Purpose |
|-------|----------------|---------|
| Plan | Claude creates detailed plan | Architecture and requirements |
| Request implementation | `echo "implement: [plan]" \| qwen -p` | Qwen implements the code |
| Review code | Claude analyzes Qwen's output | Claude validates implementation |
| Request revision | `echo "revise: [feedback]" \| qwen -p` | Qwen fixes based on review |
| Apply fixes | Claude uses Edit/Write tools | Claude applies corrections directly |
| Final validation | Claude performs quality check | Ensure all requirements met |
| Deploy | Claude uses Edit/Write tools | Apply final code to files |

## Error Handling
1. Stop on non-zero exit codes from Qwen CLI
2. If Qwen's implementation has issues, Claude provides structured review
3. Ask user for resolution path via `AskUserQuestion`:
   - Let Qwen revise the implementation
   - Claude applies fixes directly
   - Modify the plan and restart
4. Before major changes, confirm approach with user:
   - Significant architectural changes
   - Multiple files affected
   - Breaking changes required

## Qwen CLI Configuration
- **Default Model**: qwen2.5-coder (optimized for code tasks)
- **Prompt Format**: Use `-p` flag for prompt input via stdin
- **Model Selection**: Use `-m <model>` to specify different Qwen variants
- **Output**: Plain text response (parsed by Claude)

## Requirements
- Qwen CLI must be installed and accessible in PATH
- Test with: `qwen --version` or `qwen --help`
- Ensure Qwen CLI is working: `echo "test" | qwen -p`

## The Perfect Loop
```
Plan (Claude) → Implement (Qwen) → Review (Claude) →
Feedback → Revise (Qwen) OR Fix (Claude) →
Validate (Claude) → Deploy (Claude) → Repeat until perfect
```

This creates a self-correcting, high-quality engineering system where:
- **Claude** handles planning, code review, quality assurance, and final deployment
- **Qwen** provides code implementation based on specifications
