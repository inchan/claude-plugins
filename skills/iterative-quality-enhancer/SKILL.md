---
name: iterative-quality-enhancer
description: Implement the Evaluator-Optimizer pattern to iteratively evaluate and optimize code and deliverables across 5 quality dimensions (functionality, performance, code quality, security, documentation). Use when code quality improvement, performance optimization, security hardening, or comprehensive quality assurance is needed. Supports integration with sequential, parallel, orchestrator, and router skills as a quality gate.
---

# Iterative Quality Enhancer

## Overview

Implement the Evaluator-Optimizer pattern from Anthropic's "Building Effective Agents" to systematically improve code and deliverables through iterative evaluation and optimization. Evaluate artifacts across 5 comprehensive quality dimensions, generate targeted feedback, and apply optimization strategies in up to 5 iterations until quality thresholds are met.

## When to Use This Skill

Activate this skill when:

- Code quality improvement is needed for existing implementations
- Performance optimization is required for slow or inefficient code
- Security hardening is needed to address vulnerabilities
- Comprehensive quality assurance before production deployment
- Refactoring legacy code to modern standards
- Serving as a quality gate for other skills (sequential, parallel, orchestrator, router)
- Users explicitly request "optimize," "improve quality," "enhance security," or similar quality-focused actions

## Core Workflow

### 1. Initialization

Start by understanding the artifact to be enhanced:

1. Identify the artifact type: code, documentation, architecture, or full project
2. Load the artifact and understand its context
3. Clarify requirements (functional, non-functional, quality targets)
4. Determine optimization focus: balanced, performance, security, or quality

Example user requests:
- "Optimize this REST API for performance and security"
- "Improve the quality of this legacy code module"
- "Enhance this documentation for completeness and clarity"

### 2. Multi-Dimensional Evaluation

Execute comprehensive evaluation across 5 dimensions using the evaluation framework in `references/evaluation_config.json`:

**Functionality (weight: 0.30, threshold: 0.95)**
- Correctness: All requirements met
- Completeness: Edge cases handled
- Reliability: Error handling robustness

Evaluation methods:
- Execute unit tests if present, or recommend creating them
- Verify integration test coverage
- Analyze edge case handling

**Performance (weight: 0.20, threshold: 0.85)**
- Time complexity: O(n log n) or better
- Space complexity: Memory efficiency
- Response time: Meets performance SLAs

Evaluation methods:
- Analyze algorithmic complexity
- Recommend benchmarking approaches
- Identify performance bottlenecks

**Code Quality (weight: 0.20, threshold: 0.90)**
- Readability: Clean code principles
- Maintainability: Easy to modify and extend
- Modularity: Proper component separation

Evaluation methods:
- Apply static code analysis principles
- Calculate cyclomatic complexity
- Detect code smells (duplication, long functions, etc.)

**Security (weight: 0.15, threshold: 0.95)**
- Vulnerability-free: No known security issues
- Authentication/Authorization: Proper implementation
- Data protection: Secure data handling

Evaluation methods:
- Check for common vulnerabilities (SQL injection, XSS, CSRF, etc.)
- Verify OWASP Top 10 compliance
- Review authentication and authorization patterns

**Documentation (weight: 0.15, threshold: 0.85)**
- Completeness: Comprehensive coverage
- Clarity: Easy to understand
- Examples: Practical usage demonstrations

Evaluation methods:
- Check documentation coverage
- Validate API documentation completeness
- Verify example code execution

### 3. Iterative Optimization Loop

Execute up to 5 optimization iterations following this process:

```
For each iteration (max 5):
  1. Evaluate artifact across all dimensions
  2. Calculate weighted total score
  3. Check termination conditions:
     - All dimension thresholds met → SUCCESS
     - No significant improvement (< 5%) after 3+ iterations → STOP
  4. Generate prioritized feedback for failing dimensions
  5. Select optimization strategy based on feedback
  6. Apply targeted optimizations
  7. Record iteration history
  8. Proceed to next iteration
```

**Termination Conditions:**
- All dimension scores meet their thresholds
- Total weighted score ≥ 0.90
- No improvement > 5% for 2 consecutive iterations (after minimum 3 iterations)
- Maximum 5 iterations reached

### 4. Feedback Generation

Generate actionable, prioritized feedback:

1. **Identify failing dimensions:** Dimensions below threshold, sorted by (weight × gap)
2. **Provide specific issues:** Concrete problems, not generic advice
3. **Suggest concrete actions:** Executable improvements with expected impact
4. **Prioritize by impact:** Focus on high-weight dimensions first

Example feedback format:
```
Priority 1 - Functionality (0.72/0.95):
- Issue: Missing error handling for null inputs in processData()
- Action: Add null checks and throw descriptive errors
- Expected impact: +0.15 functionality score

Priority 2 - Security (0.82/0.95):
- Issue: SQL query vulnerable to injection in getUserById()
- Action: Use parameterized queries instead of string concatenation
- Expected impact: +0.13 security score
```

### 5. Optimization Strategies

Apply targeted optimization strategies based on evaluation results:

**Algorithm Optimization** (for performance issues):
- Improve time complexity (e.g., O(n²) → O(n log n))
- Optimize space complexity
- Implement caching strategies
- Use more efficient data structures

**Code Refactoring** (for code quality issues):
- Apply design patterns (Strategy, Factory, Observer, etc.)
- Follow SOLID principles
- Eliminate code duplication (DRY principle)
- Extract long functions into smaller units
- Improve naming and structure

**Performance Tuning** (for response time issues):
- Identify and remove bottlenecks
- Optimize resource usage (CPU, memory, I/O)
- Introduce asynchronous processing
- Implement parallel execution where appropriate

**Security Hardening** (for security issues):
- Patch known vulnerabilities
- Strengthen input validation
- Implement proper authentication/authorization
- Add encryption for sensitive data
- Follow OWASP guidelines

**Documentation Enhancement** (for documentation issues):
- Add missing docstrings/comments
- Create comprehensive README
- Provide usage examples
- Document API endpoints
- Add inline code explanations

### 6. Final Report Generation

After optimization completes, generate a comprehensive quality report:

```markdown
# Quality Enhancement Report

## Executive Summary
- Initial Quality Score: X.XX (XX%)
- Final Quality Score: Y.YY (YY%)
- Iterations Completed: N
- Key Improvements: [list major improvements]

## Dimension Analysis

### Functionality: X.XX (threshold: 0.95)
[Detailed analysis of functionality improvements]

### Performance: X.XX (threshold: 0.85)
[Detailed analysis of performance improvements]

### Code Quality: X.XX (threshold: 0.90)
[Detailed analysis of code quality improvements]

### Security: X.XX (threshold: 0.95)
[Detailed analysis of security improvements]

### Documentation: X.XX (threshold: 0.85)
[Detailed analysis of documentation improvements]

## Optimization Journey

### Iteration 1
- Focus: [primary optimization target]
- Changes: [specific changes made]
- Impact: [score improvements]

[Repeat for each iteration]

## Applied Optimizations
[Detailed list of all optimizations with before/after comparisons]

## Recommendations
[Future improvement suggestions if thresholds not fully met]
```

## Integration with Other Skills

This skill serves as a quality gate for other skills:

**Sequential Task Processor:**
- Evaluate each task's output before proceeding to the next
- Ensure cumulative quality across the workflow
- Provide feedback for task refinement

**Parallel Task Executor:**
- Validate merged results from parallel executions
- Ensure no quality degradation from parallelization
- Verify integration points between parallel components

**Orchestrator:**
- Quality-check worker outputs before aggregation
- Ensure consistency across distributed components
- Validate final orchestrated result

**Router:**
- Provide quality feedback to improve routing decisions
- Evaluate routed task outcomes
- Help router learn from quality patterns

## Input/Output Format

### Input
```json
{
  "task_id": "unique-task-identifier",
  "artifact": {
    "type": "code|documentation|architecture|full_project",
    "path": "path/to/artifact",
    "metadata": {
      "language": "python|javascript|etc",
      "framework": "framework-name"
    }
  },
  "requirements": {
    "functional": ["requirement1", "requirement2"],
    "non_functional": ["requirement1", "requirement2"],
    "quality_targets": {
      "functionality": 0.95,
      "performance": 0.85,
      "code_quality": 0.90,
      "security": 0.95,
      "documentation": 0.85
    }
  },
  "from_skill": "sequential|parallel|orchestrator|router|null",
  "optimization_focus": "balanced|performance|security|quality"
}
```

### Output
```json
{
  "task_id": "unique-task-identifier",
  "optimization_summary": {
    "initial_score": 0.72,
    "final_score": 0.94,
    "iterations": 3,
    "improvements_made": [
      "Fixed SQL injection vulnerability",
      "Optimized algorithm from O(n²) to O(n log n)",
      "Added comprehensive error handling",
      "Enhanced API documentation"
    ]
  },
  "dimension_scores": {
    "functionality": 0.96,
    "performance": 0.88,
    "code_quality": 0.92,
    "security": 0.98,
    "documentation": 0.86
  },
  "applied_optimizations": [
    {
      "iteration": 1,
      "target": "security",
      "action": "parameterized_queries",
      "impact": "+0.16 security score"
    },
    {
      "iteration": 2,
      "target": "performance",
      "action": "algorithm_optimization",
      "impact": "+0.15 performance score"
    },
    {
      "iteration": 3,
      "target": "functionality",
      "action": "error_handling_enhancement",
      "impact": "+0.12 functionality score"
    }
  ],
  "final_artifact": "path/to/optimized/artifact",
  "quality_report": "path/to/quality_report.md",
  "recommendations": [
    "Consider implementing caching for frequently accessed data",
    "Add integration tests for critical workflows"
  ]
}
```

## Practical Examples

### Example 1: REST API Optimization

**User request:** "Optimize this REST API endpoint for performance and security"

**Process:**
1. Load the API endpoint code
2. Initial evaluation reveals:
   - Functionality: 0.88 (missing edge case handling)
   - Performance: 0.65 (N+1 query problem)
   - Security: 0.70 (no input validation)
3. Iteration 1: Fix security issues (input validation, SQL injection prevention)
4. Iteration 2: Optimize performance (batch queries, add caching)
5. Iteration 3: Complete functionality (edge case handling)
6. Final scores: All dimensions > thresholds
7. Generate quality report with before/after comparisons

### Example 2: Legacy Code Refactoring

**User request:** "Improve the quality of this legacy authentication module"

**Process:**
1. Load authentication module code
2. Initial evaluation reveals:
   - Code Quality: 0.55 (high complexity, code smells)
   - Security: 0.72 (weak password hashing)
   - Documentation: 0.40 (minimal comments)
3. Iteration 1: Refactor into smaller functions, apply design patterns
4. Iteration 2: Upgrade to modern password hashing (bcrypt/argon2)
5. Iteration 3: Add comprehensive documentation and examples
6. Iteration 4: Further refactoring based on diminishing returns analysis
7. Final optimization with detailed improvement history

## Resources

### references/
- `evaluation_config.json`: Complete evaluation framework with dimensions, weights, thresholds, and criteria
- `api_optimization_example.md`: Detailed walkthrough of REST API optimization process
- `security_enhancement_example.md`: Step-by-step security hardening scenario

### scripts/
The scripts directory contains evaluation, optimization, and analysis modules. These are reference implementations showing the structure and logic of each component. When optimizing code, apply these patterns and principles directly rather than executing the scripts.

**Structure:**
- `evaluators/`: Dimension-specific evaluation logic
- `optimizers/`: Targeted optimization strategies
- `analyzers/`: Static and dynamic analysis tools
- `feedback/`: Feedback generation and prioritization
- `reports/`: Quality report generation

**Note:** These scripts demonstrate the evaluation and optimization patterns. Apply their logic directly to user code rather than calling them as external tools.

## Best Practices

1. **Start with evaluation:** Always evaluate before optimizing
2. **Prioritize by impact:** Focus on high-weight dimensions first
3. **Be specific:** Provide concrete, actionable feedback
4. **Track progress:** Record all changes and their impacts
5. **Know when to stop:** Don't over-optimize if thresholds are met
6. **Document changes:** Explain what was changed and why
7. **Provide evidence:** Show before/after comparisons and metrics
8. **Consider trade-offs:** Sometimes optimizing one dimension affects another

## Limitations

- Evaluation is qualitative and based on code analysis, not execution metrics
- Some performance metrics require actual benchmarking
- Security evaluation follows best practices but doesn't replace professional security audits
- Automated testing is recommended but not executed by this skill
- Complex architectural issues may require human judgment

## Version

1.0.0
