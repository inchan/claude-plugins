---
name: parallel-task-executor
description: Implements Anthropic's Parallelization pattern with two modes - Sectioning (independent subtasks in parallel) and Voting (multiple approaches evaluated). Use when tasks decompose into independent units or when comparing implementation strategies. Delivers 2-10x speedup or consensus-based decisions.
---

# Parallel Task Executor (Parallelization Pattern)

## Overview

This skill implements the **Parallelization** workflow pattern from Anthropic's "Building Effective Agents". The core principle is to execute LLM tasks simultaneously and programmatically aggregate results, using either **Sectioning** (split work) or **Voting** (multiple approaches).

**Reference**: https://www.anthropic.com/engineering/building-effective-agents

### Key Principle

> "Parallelization: LLMs can sometimes work simultaneously on a task and have their outputs aggregated programmatically."

**Two Manifestations:**

1. **Sectioning**: "Breaking a task into independent subtasks run in parallel"
2. **Voting**: "Running the same task multiple times to get diverse outputs"

**Trade-off**: Additional compute cost for speed (sectioning) or confidence (voting).

## When to Use This Skill

### Use Sectioning Mode When:
- Task breaks into **independent subtasks** (no dependencies)
- Speed is critical (deadline pressure)
- Components can be **merged programmatically**
- Work spans multiple domains (frontend + backend + database)

**Examples:**
- Build microservices architecture (3-5 services in parallel)
- Run test suite (unit + integration + e2e concurrently)
- Create documentation (API docs + user guide + tutorials)
- Deploy multi-region infrastructure

### Use Voting Mode When:
- **Multiple valid approaches** exist
- Need **confidence** in the solution
- Evaluating **trade-offs** between strategies
- Detecting **bugs or vulnerabilities** (diverse perspectives)

**Examples:**
- Code review (security + performance + maintainability perspectives)
- Algorithm selection (functional vs. imperative vs. hybrid)
- Content generation (different tones/styles)
- Risk assessment (multiple analyst perspectives)

### Do NOT Use When:
- Task is inherently sequential (strong dependencies)
- Overhead exceeds benefit (simple tasks)
- Limited resources (compute/memory constraints)
- Results cannot be merged programmatically

## Sectioning Mode Workflow

### Step 1: Task Decomposition

Identify independent subtasks:

```markdown
## Sectioning Analysis: [Main Task]

### Main Task
[Full task description]

### Independent Subtasks
1. **Subtask A**: [Description] - Dependencies: None
2. **Subtask B**: [Description] - Dependencies: None
3. **Subtask C**: [Description] - Dependencies: None

### Dependency Graph
```
[A] ──┐
[B] ──┼──→ [Merge] → [Final Output]
[C] ──┘
```

### Parallelization Plan
- **Parallel Execution**: A, B, C (simultaneously)
- **Sync Point**: After all complete
- **Merge Strategy**: [How to combine results]
- **Expected Speedup**: 3x (3 tasks, 1 time unit)
```

### Step 2: Parallel Execution

Execute all independent subtasks simultaneously:

```markdown
## Parallel Execution

### Worker 1: [Subtask A]
**Status**: In Progress
**Output**: [Result A]

### Worker 2: [Subtask B]
**Status**: In Progress
**Output**: [Result B]

### Worker 3: [Subtask C]
**Status**: In Progress
**Output**: [Result C]

### Sync Point
**All workers completed**: Yes
**Ready for merge**: Yes
```

### Step 3: Result Aggregation

Merge results from parallel workers:

```markdown
## Merge Results

### Inputs
- Worker 1 output: [Result A]
- Worker 2 output: [Result B]
- Worker 3 output: [Result C]

### Merge Process
1. **Import consolidation**: Deduplicate shared dependencies
2. **Interface alignment**: Ensure consistent API contracts
3. **Configuration unification**: Single config file
4. **Integration testing**: Verify merged system works

### Conflicts Detected
- [Conflict 1]: How resolved
- [Conflict 2]: How resolved

### Final Output
[Integrated result with all components working together]
```

## Voting Mode Workflow

### Step 1: Define Evaluation Criteria

```markdown
## Voting Setup: [Task]

### Task
[Task to be solved with multiple approaches]

### Evaluation Criteria (Weighted)
1. **Performance**: 40% weight - Execution speed, memory usage
2. **Readability**: 30% weight - Code clarity, maintainability
3. **Robustness**: 30% weight - Error handling, edge cases

### Voting Strategies
- Strategy A: [Approach description]
- Strategy B: [Approach description]
- Strategy C: [Approach description]

### Success Threshold
- Minimum score: 70/100
- Consensus requirement: 2/3 voters agree on key aspects
```

### Step 2: Execute Multiple Approaches

```markdown
## Voting Execution

### Voter 1: [Strategy A - e.g., Functional Approach]
**Implementation**:
[Code/solution using this approach]

**Self-Assessment**:
- Performance: 7/10
- Readability: 9/10
- Robustness: 8/10

### Voter 2: [Strategy B - e.g., Object-Oriented Approach]
**Implementation**:
[Code/solution using this approach]

**Self-Assessment**:
- Performance: 8/10
- Readability: 7/10
- Robustness: 8/10

### Voter 3: [Strategy C - e.g., Hybrid Approach]
**Implementation**:
[Code/solution using this approach]

**Self-Assessment**:
- Performance: 9/10
- Readability: 8/10
- Robustness: 9/10
```

### Step 3: Aggregate and Select Winner

```markdown
## Vote Aggregation

### Scoring Matrix
| Voter | Performance (40%) | Readability (30%) | Robustness (30%) | Total |
|-------|-------------------|-------------------|-------------------|-------|
| A (Functional) | 7 × 0.4 = 2.8 | 9 × 0.3 = 2.7 | 8 × 0.3 = 2.4 | 7.9 |
| B (OOP) | 8 × 0.4 = 3.2 | 7 × 0.3 = 2.1 | 8 × 0.3 = 2.4 | 7.7 |
| C (Hybrid) | 9 × 0.4 = 3.6 | 8 × 0.3 = 2.4 | 9 × 0.3 = 2.7 | 8.7 |

### Winner
**Strategy C (Hybrid)** with score 8.7/10

### Rationale
- Highest performance score (critical for this use case)
- Good readability (above threshold)
- Best robustness (handles edge cases)

### Consensus Points
- All approaches agree on: [common patterns]
- Key differentiator: [what made winner stand out]

### Final Decision
[Chosen approach with justification]
```

## Complete Example: Full-Stack Application (Sectioning)

### Task
"Build a full-stack e-commerce product catalog with React frontend, Node.js backend, and PostgreSQL database"

### Sectioning Analysis

```markdown
## Parallelization Plan

### Independent Subtasks
1. **Frontend**: React product catalog UI
2. **Backend**: Node.js REST API
3. **Database**: PostgreSQL schema and migrations

### Dependency Check
- Frontend ← (needs API endpoints) → Wait for interface definition
- Backend ← (needs DB schema) → Wait for schema definition
- Database ← (independent) → Can start immediately

### Execution Strategy
1. **Phase 1 (Parallel)**: Define contracts first
   - API interface (endpoints, types)
   - Database schema (tables, relations)
2. **Phase 2 (Parallel)**: Implement against contracts
   - Worker 1: Frontend against API contract
   - Worker 2: Backend against DB schema
   - Worker 3: Database setup
3. **Phase 3**: Integration merge
```

### Parallel Execution

```markdown
## Worker Execution

### Worker 1: Frontend (React)
**Task**: Build product catalog UI

**Output**:
```typescript
// ProductCatalog.tsx
import { useState, useEffect } from 'react';
import { Product } from '../types';
import { api } from '../services/api';

export const ProductCatalog = () => {
  const [products, setProducts] = useState<Product[]>([]);

  useEffect(() => {
    api.get('/products').then(setProducts);
  }, []);

  return (
    <div className="grid grid-cols-3 gap-4">
      {products.map(product => (
        <ProductCard key={product.id} product={product} />
      ))}
    </div>
  );
};
```

**Status**: Complete
**Files Generated**: 5 components, API client, types

---

### Worker 2: Backend (Node.js)
**Task**: Build REST API endpoints

**Output**:
```typescript
// routes/products.ts
import express from 'express';
import { db } from '../db';

const router = express.Router();

router.get('/products', async (req, res) => {
  const products = await db.query('SELECT * FROM products');
  res.json(products.rows);
});

router.get('/products/:id', async (req, res) => {
  const { id } = req.params;
  const product = await db.query('SELECT * FROM products WHERE id = $1', [id]);
  res.json(product.rows[0]);
});

export default router;
```

**Status**: Complete
**Files Generated**: 3 route files, controllers, middleware

---

### Worker 3: Database (PostgreSQL)
**Task**: Create schema and migrations

**Output**:
```sql
-- migrations/001_create_products.sql
CREATE TABLE products (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  price DECIMAL(10,2) NOT NULL,
  image_url VARCHAR(500),
  category VARCHAR(100),
  stock_quantity INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_products_price ON products(price);
```

**Status**: Complete
**Files Generated**: 3 migrations, seed data, connection config
```

### Merge Results

```markdown
## Integration Merge

### Conflicts Detected
1. **Port Conflict**: Frontend dev server (3000) vs Backend server (3000)
   - Resolution: Backend → 3001, Frontend proxy config updated

2. **Type Mismatch**: Frontend expects `imageUrl`, Backend returns `image_url`
   - Resolution: Added camelCase transformer in API client

3. **Missing CORS**: Frontend blocked by CORS policy
   - Resolution: Added CORS middleware to backend

### Merged Configuration
```yaml
# docker-compose.yml
services:
  frontend:
    build: ./frontend
    ports: ["3000:3000"]
    environment:
      - REACT_APP_API_URL=http://localhost:3001

  backend:
    build: ./backend
    ports: ["3001:3001"]
    environment:
      - DATABASE_URL=postgres://user:pass@db:5432/catalog
    depends_on: [db]

  db:
    image: postgres:14
    environment:
      - POSTGRES_DB=catalog
```

### Final Output
- **Complete application** ready to run with `docker-compose up`
- **Execution time**: 15 minutes (vs 45 minutes sequential)
- **Speedup factor**: 3x
- **Integration tests**: Passing
```

## Complete Example: Algorithm Selection (Voting)

### Task
"Implement efficient search algorithm for finding users by email in database with 1M+ records"

### Voting Setup

```markdown
## Algorithm Comparison

### Evaluation Criteria
- **Performance** (50%): Query time for 1M records
- **Memory** (25%): RAM usage during operation
- **Maintainability** (25%): Code clarity and future changes

### Strategies to Compare
1. Linear scan with early termination
2. Binary search with sorted index
3. Hash table with O(1) lookup
```

### Voter Implementations

```markdown
### Voter 1: Linear Scan
```python
def find_by_email_linear(users, email):
    for user in users:
        if user.email == email:
            return user
    return None
```
- Time: O(n) worst case, O(n/2) average
- Memory: O(1)
- Readability: High

---

### Voter 2: Binary Search
```python
def find_by_email_binary(sorted_users, email):
    left, right = 0, len(sorted_users) - 1
    while left <= right:
        mid = (left + right) // 2
        if sorted_users[mid].email == email:
            return sorted_users[mid]
        elif sorted_users[mid].email < email:
            left = mid + 1
        else:
            right = mid - 1
    return None
```
- Time: O(log n)
- Memory: O(1), but requires sorted data
- Readability: Medium

---

### Voter 3: Hash Table
```python
class UserIndex:
    def __init__(self, users):
        self.email_index = {u.email: u for u in users}

    def find_by_email(self, email):
        return self.email_index.get(email)
```
- Time: O(1) average
- Memory: O(n) for index
- Readability: High
```

### Aggregation

```markdown
## Scoring Results

### Benchmark Data (1M records)
| Approach | Query Time | Memory Usage | Code Lines |
|----------|-----------|--------------|------------|
| Linear | 450ms | 1MB | 4 lines |
| Binary | 0.02ms | 1MB + sorting | 12 lines |
| Hash | 0.001ms | 150MB | 8 lines |

### Weighted Scores
| Voter | Performance (50%) | Memory (25%) | Maintainability (25%) | Total |
|-------|-------------------|--------------|------------------------|-------|
| Linear | 3/10 | 10/10 | 9/10 | 5.75 |
| Binary | 8/10 | 8/10 | 7/10 | 7.75 |
| Hash | 10/10 | 4/10 | 9/10 | 8.25 |

### Winner: Hash Table
**Score**: 8.25/10
**Rationale**:
- Fastest query time (critical for UX)
- Memory cost acceptable (150MB for 1M users)
- Simple, maintainable code

### Recommendation
Use hash table approach with lazy loading:
- Index only active users initially
- Build index on startup or first query
- Consider LRU cache for memory optimization
```

## Integration with Other Skills

### From Router
```
Router identifies: "This task has 3 independent components"
→ Routes to: parallel-task-executor (sectioning mode)
```

### To Evaluator
```
Parallel execution complete
→ Send merged results to: iterative-quality-enhancer
→ Request: "Evaluate integration quality and suggest improvements"
```

### With Sequential Processor
```
Each parallel worker can use sequential processing internally:
Worker 1: [Sequential steps for component A]
Worker 2: [Sequential steps for component B]
Worker 3: [Sequential steps for component C]
```

### With Orchestrator
```
Orchestrator: "I need 3 services built"
→ Delegates to: parallel-task-executor
→ Parallel builds all 3
→ Returns to: orchestrator for overall coordination
```

## Best Practices

### 1. Verify Independence
Before parallelizing, confirm subtasks truly have no dependencies:
- No shared state
- No sequential data flow
- No mutual exclusion requirements

### 2. Define Clear Contracts
When splitting work:
- API interfaces before implementation
- Shared types/schemas upfront
- Clear integration points

### 3. Plan Merge Strategy
Know how results will combine:
- File merging rules
- Conflict resolution strategy
- Integration testing approach

### 4. Monitor Speedup
Track actual vs. expected speedup:
- If < 1.5x, reconsider parallelization
- Overhead costs (context, merge) matter

### 5. Use Voting for Uncertainty
When unsure of best approach:
- Define clear criteria
- Weight criteria by importance
- Document decision rationale

### 6. Respect Resource Limits
Don't over-parallelize:
- 2-10 workers is typical range
- More workers ≠ more speedup
- Memory and CPU constraints matter

## Performance Characteristics

### Sectioning Mode
- **Ideal speedup**: N times (N parallel tasks)
- **Realistic speedup**: 2-5x (overhead costs)
- **Overhead sources**: Task distribution, result merging, conflict resolution

### Voting Mode
- **Value**: Confidence in decision, not speed
- **Typical voters**: 3-5 approaches
- **Cost**: 3-5x compute for single decision
- **Benefit**: Higher quality solution

### When to Avoid
| Scenario | Reason |
|----------|--------|
| Strong dependencies | Can't parallelize |
| Simple task (<5 min) | Overhead exceeds benefit |
| Resource constrained | Memory/CPU limits |
| Real-time response needed | Merge adds latency |

## Summary

The Parallel Task Executor implements Anthropic's Parallelization pattern by:

1. **Sectioning**: Breaking independent work into parallel units
2. **Executing**: Running multiple workers simultaneously
3. **Aggregating**: Merging results programmatically
4. **Voting**: Comparing multiple approaches for best solution
5. **Selecting**: Choosing optimal approach based on criteria

This pattern excels when:
- Tasks decompose into truly independent subtasks (Sectioning)
- Multiple valid solutions exist and need evaluation (Voting)
- Speed or confidence matters more than compute cost

**Remember**: Parallelization trades **compute cost** for **speed** (sectioning) or **confidence** (voting). Only use when the trade-off is worthwhile.
