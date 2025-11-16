---
name: sequential-task-processor
description: This skill should be used when handling complex, multi-step software development tasks that require systematic decomposition, sequential execution with validation gates, and artifact generation. Implements Anthropic's Prompt Chaining pattern from "Building Effective Agents" to break down requests like "Build a React dashboard", "Create a REST API", or "Implement user authentication" into 3-7 sequential steps with validation between each stage.
---

# Sequential Task Processor

## Overview

Implement a prompt chaining workflow that decomposes complex software development tasks into sequential, validated steps. This skill transforms monolithic requests into manageable stages where each step's output becomes the next step's input, with validation gates ensuring quality at each transition.

Based on Anthropic's "Building Effective Agents" engineering principles, this approach reduces errors, improves code quality, and makes complex implementations more reliable by catching issues early in the development chain.

## When to Use This Skill

Apply this skill when:
- The task requires multiple distinct phases (analysis, design, implementation, testing, documentation)
- Each phase produces artifacts that inform subsequent phases
- Validation checkpoints would prevent downstream errors
- The task complexity benefits from incremental progress tracking
- Integration with orchestrator or evaluator skills is needed

**Examples of suitable tasks:**
- "Build a React dashboard application with user authentication"
- "Create a REST API for a booking system"
- "Implement a data processing pipeline with validation"
- "Refactor a monolithic service into microservices"

## Workflow: Sequential Task Processing

### 1. Task Intake and Decomposition

When receiving a task, analyze and decompose it into 3-7 sequential steps following this standard pattern:

**Standard Step Sequence:**
1. **Analysis** - Requirements gathering and clarification
2. **Design** - Architecture and technical specifications
3. **Implementation** - Code development
4. **Testing** - Verification and validation
5. **Documentation** - Final documentation and handoff

Adapt the sequence based on task characteristics. Some tasks may require additional steps (e.g., "Migration Planning") or fewer steps (e.g., skip "Testing" for documentation-only tasks).

### 2. Step Execution Pattern

For each step in the sequence:

**A. Load Step Context**
- Read the previous step's output artifact from `.sequential_cache/`
- Load the appropriate template from `assets/templates/`
- Review the step's validation criteria from `config.json`

**B. Execute Step Logic**
- Process input using the step-specific template structure
- Generate the required output artifact
- Ensure all validation criteria can be checked

**C. Save Step Output**
- Write the output artifact to `.sequential_cache/[task_id]/[step_name].md`
- Format: Markdown with clear section headers
- Include metadata: timestamp, task_id, step_number, status

**D. Run Validation Gate**
- Execute `scripts/step_validator.py [task_id] [step_name]`
- Check against criteria defined in `config.json`
- Log validation results to `.sequential_cache/[task_id]/validation_log.json`

**E. Gate Decision**
- **Pass**: Proceed to next step
- **Fail**: Return to step execution with validation feedback
- **Blocked**: Pause and request user input for clarification

### 3. Artifact Management

Create and maintain a cache directory structure:

```
.sequential_cache/
└── [task_id]/
    ├── requirements.md       # Step 1 output
    ├── architecture.md       # Step 2 output
    ├── implementation/       # Step 3 output (may include code files)
    ├── test_results.md       # Step 4 output
    ├── documentation.md      # Step 5 output
    └── validation_log.json   # All validation results
```

**Artifact Format:**
```markdown
---
task_id: "task_20241111_001"
step: "design"
step_number: 2
timestamp: "2024-11-11T09:15:00Z"
status: "completed"
validation: "passed"
---

# [Step Name]: [Task Description]

## Input Summary
[Summary of input from previous step]

## [Main Content Sections]
[Step-specific content following template structure]

## Output Artifacts
[List of generated files/documents]

## Validation Checklist
- [x] Criterion 1
- [x] Criterion 2
```

## Configuration: config.json

The `config.json` file defines step templates, validation rules, and integration settings:

**Structure:**
```json
{
  "version": "1.0.0",
  "default_steps": [
    {
      "name": "analysis",
      "template": "assets/templates/requirements.md.tmpl",
      "validation": {
        "required_sections": ["Overview", "Requirements", "Constraints"],
        "min_requirements": 3,
        "completeness_check": true
      }
    },
    {
      "name": "design",
      "template": "assets/templates/architecture.md.tmpl",
      "validation": {
        "required_sections": ["Architecture", "Components", "Data Flow"],
        "consistency_check": true
      }
    },
    {
      "name": "implementation",
      "validation": {
        "compile_check": true,
        "lint_check": true,
        "required_files": ["main source file"]
      }
    },
    {
      "name": "testing",
      "validation": {
        "test_execution": true,
        "min_coverage": 70,
        "required_tests": ["unit", "integration"]
      }
    },
    {
      "name": "documentation",
      "template": "assets/templates/validation.md.tmpl",
      "validation": {
        "required_sections": ["Usage", "API Reference"],
        "completeness_check": true
      }
    }
  ],
  "validation_gates": {
    "strict_mode": false,
    "allow_skip": false,
    "retry_limit": 3
  },
  "integration": {
    "accepts_from": ["router", "orchestrator"],
    "sends_to": ["evaluator"],
    "parallel_compatible": true
  }
}
```

## Step Validation

Use `scripts/step_validator.py` to validate each step's output:

**Usage:**
```bash
python3 scripts/step_validator.py [task_id] [step_name] [--config config.json]
```

**Validation Types:**

1. **Completeness Check** - All required sections present
2. **Consistency Check** - Output aligns with input requirements
3. **Format Check** - Proper markdown structure and metadata
4. **Compile/Lint Check** - For implementation steps (language-specific)
5. **Test Execution** - For testing steps
6. **Coverage Check** - Test coverage meets minimum threshold

**Validator Output:**
```json
{
  "task_id": "task_20241111_001",
  "step": "design",
  "timestamp": "2024-11-11T09:20:00Z",
  "status": "passed",
  "checks": [
    {"name": "completeness", "passed": true},
    {"name": "consistency", "passed": true}
  ],
  "issues": [],
  "recommendation": "proceed"
}
```

## Integration with Other Skills

### Input Format (from Router/Orchestrator)

```json
{
  "task_id": "task_20241111_001",
  "task_description": "Build a React dashboard with authentication",
  "from_skill": "router",
  "priority": "high",
  "context": {
    "user_requirements": "...",
    "constraints": ["Use TypeScript", "Material-UI"]
  }
}
```

### Output Format (to Evaluator)

```json
{
  "task_id": "task_20241111_001",
  "status": "completed",
  "completed_steps": ["analysis", "design", "implementation", "testing", "documentation"],
  "artifacts": {
    "requirements": ".sequential_cache/task_20241111_001/requirements.md",
    "architecture": ".sequential_cache/task_20241111_001/architecture.md",
    "code": ".sequential_cache/task_20241111_001/implementation/",
    "tests": ".sequential_cache/task_20241111_001/test_results.md",
    "docs": ".sequential_cache/task_20241111_001/documentation.md"
  },
  "validation_log": ".sequential_cache/task_20241111_001/validation_log.json",
  "next_skill_recommendation": "evaluator",
  "metrics": {
    "total_steps": 5,
    "validation_passes": 5,
    "validation_retries": 1,
    "total_duration_minutes": 45
  }
}
```

### Skill Interaction Patterns

**1. Router → Sequential Processor**
- Router classifies complex task
- Sends to Sequential Processor with context
- Processor decomposes and executes

**2. Sequential Processor → Evaluator**
- Processor completes all steps
- Sends artifacts to Evaluator for quality assessment
- Evaluator provides feedback for iteration

**3. Orchestrator ↔ Sequential Processor**
- Orchestrator assigns task to Processor as a worker
- Processor reports progress at each step
- Orchestrator monitors and may intervene

**4. Sequential Processor ↔ Parallel Processor**
- Independent steps run in parallel
- Results merge at integration points
- Sequential order maintained where dependencies exist

## Templates

Templates guide artifact creation and ensure consistency:

### requirements.md.tmpl
Guides requirements analysis step - see `assets/templates/requirements.md.tmpl` for structure.

**Key Sections:**
- Task Overview
- Functional Requirements
- Non-Functional Requirements
- Constraints and Assumptions
- Success Criteria

### architecture.md.tmpl
Guides design step - see `assets/templates/architecture.md.tmpl` for structure.

**Key Sections:**
- System Architecture
- Component Breakdown
- Data Models
- API Contracts
- Technology Stack

### validation.md.tmpl
Guides documentation step - see `assets/templates/validation.md.tmpl` for structure.

**Key Sections:**
- Validation Checklist
- Test Results Summary
- Documentation Completeness
- Deployment Readiness

## Examples

See `examples/web_app_example.md` for a complete walkthrough of processing "Build a React dashboard application" through all sequential steps with validation gates.

**Example demonstrates:**
- Task decomposition into 5 steps
- Artifact generation at each step
- Validation gate checks
- Error handling and retry
- Final output format

## Resources

### scripts/
- `step_validator.py` - Validates step outputs against configured criteria

### assets/templates/
- `requirements.md.tmpl` - Requirements analysis template
- `architecture.md.tmpl` - Architecture design template
- `validation.md.tmpl` - Validation checklist template

### examples/
- `web_app_example.md` - Complete example: React dashboard implementation

## Best Practices

1. **Keep Steps Focused** - Each step should have a clear, single purpose
2. **Validate Early** - Run validation immediately after step completion
3. **Preserve Context** - Always include input summary in output artifacts
4. **Log Everything** - Maintain comprehensive validation logs
5. **Handle Failures Gracefully** - Provide clear feedback on validation failures
6. **Use Templates Consistently** - Follow template structures for all artifacts
7. **Clean Up** - Archive or delete `.sequential_cache/` after task completion

## Error Handling

**Validation Failure:**
- Log specific validation errors
- Provide remediation guidance
- Retry with corrections (up to retry_limit)
- Escalate to user if repeated failures

**Step Execution Errors:**
- Capture error details
- Save partial output
- Mark step as "failed" in validation log
- Suggest recovery actions

**Integration Errors:**
- Validate input format from other skills
- Return clear error messages
- Maintain compatibility with skill contract
