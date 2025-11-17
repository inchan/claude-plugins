---
name: iterative-quality-enhancer
description: Implements Anthropic's Evaluator-Optimizer pattern where one LLM generates solutions and another provides evaluative feedback in an iterative loop. Use when quality can be demonstrably improved through articulated feedback cycles. Evaluates across 5 dimensions (functionality, performance, code quality, security, documentation) with up to 5 improvement iterations.
---

# Iterative Quality Enhancer (Evaluator-Optimizer Pattern)

## Overview

This skill implements the **Evaluator-Optimizer** workflow pattern from Anthropic's "Building Effective Agents". The core principle is that one LLM generates a response while another provides evaluation and feedback, creating an **iterative refinement loop** until quality standards are met.

**Reference**: https://www.anthropic.com/engineering/building-effective-agents

### Key Principle

> "Evaluator-Optimizer: One LLM call generates a response while another provides evaluation and feedback in a loop."

**Critical Success Factor:**
> "This workflow is particularly effective when we have clear evaluation criteria, and when iterative refinement provides measurable value."

**Trade-off**: Multiple iterations for higher quality output.

## When to Use This Skill

**Ideal scenarios:**
- **Clear evaluation criteria** exist (measurable quality dimensions)
- **Iterative refinement** provides demonstrable value
- Output quality **improves measurably** with feedback
- Both generation and evaluation are **LLM-achievable tasks**

**Concrete examples:**
- Code optimization with performance benchmarks
- Security hardening with vulnerability checks
- Documentation improvement with completeness criteria
- Translation refinement with nuance evaluation
- Content generation with style/tone criteria

**Do NOT use when:**
- No clear evaluation criteria exist
- Single-shot generation is sufficient
- Evaluation requires human judgment beyond LLM capability
- Iteration overhead exceeds quality gains

## Core Workflow: The Feedback Loop

### The Evaluator-Optimizer Loop

```
[Initial Artifact/Request]
       ↓
[Generator: Produce Solution] ←──────────┐
       ↓                                  │
[Evaluator: Assess Quality]               │
       ↓                                  │
[Quality Met?] ──Yes──→ [Final Output]    │
       ↓ No                               │
[Evaluator: Generate Feedback] ──────────┘
       ↓
[Generator: Refine Based on Feedback]
       ↓
(Loop until quality met or max iterations)
```

**Key Insight**: The power comes from **articulated feedback** that guides specific improvements.

### Step 1: Initial Generation

```markdown
## Generator: Initial Solution

### Task
[What needs to be created/improved]

### Initial Output
[First attempt at solving the task]

### Self-Assessment
- Functionality: [Basic check]
- Performance: [Initial estimate]
- Quality: [First impression]
- Security: [Obvious concerns]
- Documentation: [Coverage]
```

### Step 2: Comprehensive Evaluation

```markdown
## Evaluator: Quality Assessment

### Evaluation Framework
Assess across 5 weighted dimensions:

| Dimension | Weight | Score | Threshold | Status |
|-----------|--------|-------|-----------|--------|
| Functionality | 30% | X/10 | 9.5/10 | [Pass/Fail] |
| Performance | 20% | X/10 | 8.5/10 | [Pass/Fail] |
| Code Quality | 20% | X/10 | 9.0/10 | [Pass/Fail] |
| Security | 15% | X/10 | 9.5/10 | [Pass/Fail] |
| Documentation | 15% | X/10 | 8.5/10 | [Pass/Fail] |

**Weighted Total**: X.XX (Threshold: 9.0)

### Dimension Details

#### Functionality (X/10)
- Correctness: [Requirements met?]
- Completeness: [Edge cases handled?]
- Reliability: [Error handling robust?]

#### Performance (X/10)
- Time Complexity: [Algorithm efficiency]
- Space Complexity: [Memory usage]
- Response Time: [SLA compliance]

#### Code Quality (X/10)
- Readability: [Clean code principles]
- Maintainability: [Easy to modify]
- Modularity: [Component separation]

#### Security (X/10)
- Vulnerabilities: [Known issues]
- Auth/AuthZ: [Properly implemented]
- Data Protection: [Secure handling]

#### Documentation (X/10)
- Completeness: [Coverage]
- Clarity: [Understandability]
- Examples: [Practical demonstrations]
```

### Step 3: Generate Actionable Feedback

This is the **critical step** - feedback must be specific and actionable:

```markdown
## Evaluator: Improvement Feedback

### Priority 1: [Dimension with highest (weight × gap)]
**Current Score**: X/10 (Threshold: Y/10)
**Gap**: -Z points

**Specific Issues Found**:
1. [Concrete problem 1]
   - Location: [Where in code/artifact]
   - Impact: [Why this matters]

2. [Concrete problem 2]
   - Location: [Specific location]
   - Impact: [Measurable consequence]

**Recommended Actions**:
1. [Specific fix for issue 1]
   - Expected improvement: +X points
   - Implementation: [How to do it]

2. [Specific fix for issue 2]
   - Expected improvement: +Y points
   - Implementation: [Step-by-step]

### Priority 2: [Next dimension]
[Same structure...]

### Iteration Goal
After implementing these changes:
- Expected [Dimension 1] improvement: X → Y
- Expected [Dimension 2] improvement: A → B
- Expected overall score: Current → Target
```

### Step 4: Apply Improvements (Generator Refines)

```markdown
## Generator: Implementing Feedback

### Changes Applied

#### Addressing Priority 1 Feedback
**Issue**: [What was wrong]
**Action Taken**: [Specific change made]
**Code Changes**:
```
[Before]
// Old implementation

[After]
// New implementation based on feedback
```

**Expected Impact**: [Score improvement]

#### Addressing Priority 2 Feedback
[Same structure...]

### Refinement Summary
- Changes made: [List]
- Areas addressed: [Dimensions improved]
- Remaining concerns: [If any]
```

### Step 5: Re-Evaluate and Loop

```markdown
## Evaluator: Re-Assessment (Iteration N)

### Score Comparison
| Dimension | Previous | Current | Change | Target Met? |
|-----------|----------|---------|--------|-------------|
| Functionality | 7.2 | 8.8 | +1.6 | No |
| Performance | 6.5 | 8.7 | +2.2 | Yes |
| Code Quality | 7.0 | 9.1 | +2.1 | Yes |
| Security | 8.2 | 9.6 | +1.4 | Yes |
| Documentation | 6.0 | 8.3 | +2.3 | No |

**Weighted Total**: 8.5 → Previous: 7.1 (+1.4)

### Termination Check
- [ ] All dimensions meet thresholds → Not yet
- [x] Significant improvement this iteration → Yes (+1.4)
- [ ] Iteration limit reached (5) → Not yet
- [ ] Diminishing returns (<5% improvement for 2 iterations) → No

**Decision**: Continue to next iteration

### Next Iteration Feedback
[Generate new feedback focusing on remaining gaps...]
```

## Complete Example: REST API Optimization

### Task
"Optimize this user authentication endpoint for security and performance"

### Initial Code (Generator)

```typescript
// Initial implementation
async function authenticateUser(req, res) {
  const { email, password } = req.body;

  // Query database
  const user = await db.query(`SELECT * FROM users WHERE email = '${email}'`);

  if (user && user.password === password) {
    const token = jwt.sign({ id: user.id }, 'secret123');
    res.json({ token });
  } else {
    res.status(401).json({ error: 'Invalid credentials' });
  }
}
```

### Iteration 1: Evaluation

```markdown
## Evaluation Results

| Dimension | Score | Threshold | Status |
|-----------|-------|-----------|--------|
| Functionality | 7/10 | 9.5 | FAIL |
| Performance | 6/10 | 8.5 | FAIL |
| Code Quality | 7/10 | 9.0 | FAIL |
| Security | 3/10 | 9.5 | **CRITICAL FAIL** |
| Documentation | 2/10 | 8.5 | FAIL |

**Weighted Total**: 5.6/10 (Target: 9.0)

### Critical Security Findings
1. **SQL Injection Vulnerability** (Critical)
   - Line: `db.query(\`SELECT * FROM users WHERE email = '${email}'\`)`
   - Impact: Complete database compromise possible

2. **Plaintext Password Comparison** (Critical)
   - Line: `user.password === password`
   - Impact: Passwords not hashed, easily compromised

3. **Hardcoded JWT Secret** (High)
   - Line: `jwt.sign({ id: user.id }, 'secret123')`
   - Impact: Tokens can be forged if secret discovered

### Feedback for Generator
**Priority 1: Security (Critical)**
1. Use parameterized queries to prevent SQL injection
2. Implement bcrypt for password hashing/verification
3. Use environment variable for JWT secret
4. Add token expiration

**Priority 2: Functionality**
1. Add input validation (email format, password requirements)
2. Handle database connection errors
3. Return appropriate error messages

Expected improvement: 3/10 → 8/10 security, 7/10 → 9/10 functionality
```

### Iteration 1: Generator Refinement

```typescript
// Iteration 1: Security-focused improvements
import bcrypt from 'bcrypt';
import { z } from 'zod';

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8)
});

async function authenticateUser(req, res) {
  try {
    // Input validation
    const { email, password } = loginSchema.parse(req.body);

    // Parameterized query (SQL injection prevention)
    const user = await db.query(
      'SELECT id, password_hash FROM users WHERE email = $1',
      [email]
    );

    if (!user) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Secure password verification
    const isValid = await bcrypt.compare(password, user.password_hash);

    if (!isValid) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Secure token generation
    const token = jwt.sign(
      { id: user.id },
      process.env.JWT_SECRET,
      { expiresIn: '1h' }
    );

    res.json({ token, expiresIn: 3600 });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ error: 'Invalid input' });
    }
    console.error('Auth error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
}
```

### Iteration 2: Re-Evaluation

```markdown
## Evaluation Results (Iteration 2)

| Dimension | Previous | Current | Change |
|-----------|----------|---------|--------|
| Functionality | 7/10 | 9/10 | +2 |
| Performance | 6/10 | 7/10 | +1 |
| Code Quality | 7/10 | 8/10 | +1 |
| Security | 3/10 | 9/10 | **+6** |
| Documentation | 2/10 | 2/10 | 0 |

**Weighted Total**: 7.2/10 (+1.6)

### Remaining Issues
1. **Performance**: No rate limiting, bcrypt is intentionally slow
2. **Documentation**: No JSDoc, README, or API docs
3. **Code Quality**: Some duplication in error handling

### Feedback for Next Iteration
**Priority 1: Documentation**
1. Add JSDoc comments to function
2. Document expected request/response format
3. Add error code documentation

**Priority 2: Performance**
1. Implement rate limiting
2. Consider caching for failed attempts
3. Add async password hashing timeout

Expected improvement: 7.2/10 → 8.8/10
```

### Iteration 3: Final Refinement

```typescript
/**
 * Authenticates a user and returns a JWT token.
 *
 * @description
 * Validates user credentials against the database using bcrypt for secure
 * password verification. Returns a signed JWT token on success.
 *
 * @route POST /api/auth/login
 *
 * @param {Object} req.body - Request body
 * @param {string} req.body.email - User's email address
 * @param {string} req.body.password - User's password (min 8 characters)
 *
 * @returns {Object} Authentication response
 * @returns {string} response.token - JWT token (valid for 1 hour)
 * @returns {number} response.expiresIn - Token lifetime in seconds
 *
 * @throws {400} Invalid input - Email format invalid or password too short
 * @throws {401} Invalid credentials - Email/password combination incorrect
 * @throws {429} Too many requests - Rate limit exceeded
 * @throws {500} Internal server error - Database or system failure
 *
 * @example
 * // Request
 * POST /api/auth/login
 * {
 *   "email": "user@example.com",
 *   "password": "securePassword123"
 * }
 *
 * // Success Response (200)
 * {
 *   "token": "eyJhbGciOiJIUzI1NiIs...",
 *   "expiresIn": 3600
 * }
 *
 * @security
 * - Passwords are verified using bcrypt with salt
 * - SQL injection prevented via parameterized queries
 * - JWT secrets stored in environment variables
 * - Rate limiting prevents brute force attacks
 */
async function authenticateUser(req, res) {
  try {
    const { email, password } = loginSchema.parse(req.body);

    const user = await db.query(
      'SELECT id, password_hash FROM users WHERE email = $1',
      [email]
    );

    if (!user) {
      return res.status(401).json({
        error: 'Invalid credentials',
        code: 'AUTH_INVALID_CREDENTIALS'
      });
    }

    const isValid = await bcrypt.compare(password, user.password_hash);

    if (!isValid) {
      return res.status(401).json({
        error: 'Invalid credentials',
        code: 'AUTH_INVALID_CREDENTIALS'
      });
    }

    const token = jwt.sign(
      { id: user.id, email: user.email },
      process.env.JWT_SECRET,
      { expiresIn: '1h' }
    );

    res.json({
      token,
      expiresIn: 3600,
      tokenType: 'Bearer'
    });
  } catch (error) {
    handleAuthError(error, res);
  }
}

function handleAuthError(error, res) {
  if (error instanceof z.ZodError) {
    return res.status(400).json({
      error: 'Invalid input',
      code: 'AUTH_VALIDATION_ERROR',
      details: error.errors
    });
  }

  console.error('Authentication error:', error);
  res.status(500).json({
    error: 'Internal server error',
    code: 'AUTH_INTERNAL_ERROR'
  });
}
```

### Final Evaluation

```markdown
## Final Evaluation Results

| Dimension | Initial | Final | Improvement |
|-----------|---------|-------|-------------|
| Functionality | 7/10 | 9.5/10 | +2.5 |
| Performance | 6/10 | 8.5/10 | +2.5 |
| Code Quality | 7/10 | 9.2/10 | +2.2 |
| Security | 3/10 | 9.8/10 | **+6.8** |
| Documentation | 2/10 | 9.0/10 | +7.0 |

**Weighted Total**: 5.6/10 → **9.3/10** (+3.7)

### Termination Reason
All dimensions meet or exceed thresholds. Quality target achieved.

### Key Improvements
1. **Security**: SQL injection → parameterized queries, plaintext → bcrypt, hardcoded → env vars
2. **Documentation**: 0 docs → comprehensive JSDoc with examples
3. **Functionality**: Added validation, error handling, proper responses
4. **Code Quality**: Extracted error handling, consistent patterns
5. **Performance**: Appropriate for security requirements

### Iterations: 3/5
Quality achieved before maximum iterations.
```

## Integration with Other Skills

### As Quality Gate

```
[Any Skill] completes work
       ↓
Route to: iterative-quality-enhancer
       ↓
Evaluates output against criteria
       ↓
If quality met: Approve
If not: Provide feedback → Original skill refines
```

### With Sequential Processor
```
Sequential: Completes Step N
→ Evaluator: Checks Step N output
→ If pass: Proceed to Step N+1
→ If fail: Feedback to Sequential, retry Step N
```

### With Parallel Executor
```
Parallel: Completes merged output
→ Evaluator: Validates integration quality
→ If issues: Feedback on merge conflicts or inconsistencies
→ Parallel refines merge strategy
```

### With Orchestrator
```
Orchestrator: Worker completes subtask
→ Evaluator: Quality check on worker output
→ If substandard: Orchestrator reassigns or requests refinement
→ Ensures overall project quality
```

## Best Practices

### 1. Define Clear Criteria
Before starting, establish:
- Specific quality dimensions
- Measurable thresholds
- Weighted importance

### 2. Make Feedback Actionable
Each feedback item must be:
- Specific (not generic advice)
- Locatable (point to exact issue)
- Actionable (how to fix)
- Measurable (expected improvement)

### 3. Track Progress
Record:
- Score changes per iteration
- What changes were made
- Which feedback was most effective

### 4. Know When to Stop
Stop when:
- All thresholds met
- Diminishing returns (< 5% improvement)
- Maximum iterations reached
- Trade-off analysis favors stopping

### 5. Balance Dimensions
Improving one dimension shouldn't severely hurt another:
- Performance vs. Readability
- Security vs. Performance
- Functionality vs. Simplicity

## Termination Conditions

```markdown
## Loop Termination Check

### Success Criteria (STOP - Quality Achieved)
- [ ] All dimension scores >= thresholds
- [ ] Weighted total >= 9.0
→ Terminate with SUCCESS

### Failure Criteria (STOP - Cannot Improve Further)
- [ ] 5 iterations completed without full success
- [ ] < 5% improvement for 2 consecutive iterations (after iteration 3)
- [ ] Critical blocker discovered (requires human intervention)
→ Terminate with PARTIAL SUCCESS or FAILURE

### Continue Criteria
- [ ] Significant improvement this iteration (> 5%)
- [ ] Clear path to meeting thresholds
- [ ] Iterations remaining
→ Continue to next iteration
```

## Common Pitfalls

### Over-Optimization
**Problem**: Optimizing beyond necessary thresholds
**Solution**: Stop when "good enough" is reached

### Generic Feedback
**Problem**: "Improve code quality" (too vague)
**Solution**: "Extract lines 45-67 into separate function, reduce cyclomatic complexity from 12 to 4"

### Ignoring Trade-offs
**Problem**: Maximizing security breaks performance
**Solution**: Consider dimension weights and real-world requirements

### Infinite Loops
**Problem**: Never meeting thresholds
**Solution**: Implement maximum iteration limit and diminishing returns detection

## Summary

The Iterative Quality Enhancer implements Anthropic's Evaluator-Optimizer pattern by:

1. **Generating** initial solution (or receiving from other skill)
2. **Evaluating** comprehensively across multiple dimensions
3. **Providing articulated feedback** with specific, actionable improvements
4. **Refining** based on feedback (Generator role)
5. **Iterating** until quality thresholds met or termination conditions reached

This pattern excels when:
- Quality can be **objectively measured**
- Improvement is **demonstrable** through iterations
- **Feedback drives refinement** effectively
- Both generation and evaluation are achievable by LLM

**Remember**: The power is in the **feedback loop**. Generic evaluation provides little value. **Specific, actionable feedback** that leads to measurable improvement is what makes this pattern effective.
