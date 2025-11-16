# Code Review and Optimization - Voting Mode Example

This example demonstrates using the parallel-task-executor skill in **voting mode** to evaluate multiple implementation approaches and select the optimal solution through weighted scoring.

## Scenario

**User Request:** "Optimize the search algorithm for finding users by email in our database with 1M+ records"

**Analysis:** Multiple valid approaches exist with different tradeoffs. Use voting mode to implement each approach and evaluate based on performance, readability, and maintainability.

## Voting Configuration

```json
{
  "task_id": "search-optimization-001",
  "mode": "voting",
  "main_task": {
    "description": "Optimize user search by email",
    "evaluation_criteria": [
      "performance",
      "code_quality",
      "maintainability"
    ]
  },
  "voters": ["functional", "imperative", "hybrid"],
  "aggregation": "weighted_score",
  "weights": {
    "performance": 1.5,
    "code_quality": 1.0,
    "maintainability": 1.2
  },
  "timeout_seconds": 300
}
```

## Voter Implementations

### Voter 1: Functional Approach

**Philosophy:** Immutable data structures, pure functions, composable operations

```javascript
// functional-search.js
const R = require('ramda');

// Pure function for email matching
const matchesEmail = (targetEmail) => (user) =>
  user.email.toLowerCase() === targetEmail.toLowerCase();

// Composable search function
const searchUserByEmail = (users, email) =>
  R.compose(
    R.head,
    R.filter(matchesEmail(email))
  )(users);

// Lazy evaluation for large datasets
const searchUserLazy = (userStream, email) =>
  userStream
    .filter(matchesEmail(email))
    .take(1)
    .toArray();

// Higher-order function for different search strategies
const createSearcher = (indexFn) => (dataset, query) =>
  R.compose(
    R.prop('value'),
    R.find(R.propEq('key', query)),
    R.map(user => ({ key: indexFn(user), value: user }))
  )(dataset);

const searchByEmail = createSearcher(R.prop('email'));

module.exports = { searchUserByEmail, searchUserLazy, searchByEmail };
```

**Benchmark Results:**
```
Dataset: 1,000,000 users
Average search time: 245ms
Memory usage: 82MB (constant)
Cache hit rate: N/A
```

**Scores:**
- Performance: 6/10 (linear search, no optimization)
- Code Quality: 9/10 (clean, composable, testable)
- Maintainability: 8/10 (easy to understand, modify)

### Voter 2: Imperative Approach

**Philosophy:** Direct iteration, early termination, mutable state for optimization

```javascript
// imperative-search.js

// Optimized loop with early exit
function searchUserByEmail(users, email) {
  const normalizedEmail = email.toLowerCase();

  for (let i = 0; i < users.length; i++) {
    if (users[i].email.toLowerCase() === normalizedEmail) {
      return users[i];
    }
  }

  return null;
}

// Binary search on sorted array
function searchUserBinary(sortedUsers, email) {
  let left = 0;
  let right = sortedUsers.length - 1;
  const normalizedEmail = email.toLowerCase();

  while (left <= right) {
    const mid = Math.floor((left + right) / 2);
    const midEmail = sortedUsers[mid].email.toLowerCase();

    if (midEmail === normalizedEmail) {
      return sortedUsers[mid];
    } else if (midEmail < normalizedEmail) {
      left = mid + 1;
    } else {
      right = mid - 1;
    }
  }

  return null;
}

// Indexed search with preprocessing
class UserSearchIndex {
  constructor(users) {
    this.index = new Map();
    this.buildIndex(users);
  }

  buildIndex(users) {
    for (const user of users) {
      this.index.set(user.email.toLowerCase(), user);
    }
  }

  search(email) {
    return this.index.get(email.toLowerCase()) || null;
  }
}

module.exports = { searchUserByEmail, searchUserBinary, UserSearchIndex };
```

**Benchmark Results:**
```
Dataset: 1,000,000 users
Average search time: 178ms (linear), 12ms (binary), 0.8ms (indexed)
Memory usage: 156MB (indexed approach)
Cache hit rate: N/A
```

**Scores:**
- Performance: 8/10 (fast with optimizations, but requires preprocessing)
- Code Quality: 6/10 (procedural, less composable)
- Maintainability: 7/10 (straightforward but more complex)

### Voter 3: Hybrid Approach

**Philosophy:** Hash map for O(1) lookup, lazy evaluation, functional interfaces with imperative internals

```javascript
// hybrid-search.js

class EmailSearchEngine {
  constructor(options = {}) {
    this.cache = new Map();
    this.cacheSize = options.cacheSize || 1000;
    this.cacheHits = 0;
    this.cacheMisses = 0;
  }

  // Build hash map index (one-time cost)
  async buildIndex(userIterator) {
    const index = new Map();

    for await (const user of userIterator) {
      const normalizedEmail = user.email.toLowerCase();
      index.set(normalizedEmail, user);
    }

    return index;
  }

  // Search with LRU cache
  search(index, email) {
    const normalizedEmail = email.toLowerCase();

    // Check cache first
    if (this.cache.has(normalizedEmail)) {
      this.cacheHits++;
      return this.cache.get(normalizedEmail);
    }

    // Cache miss - search index
    this.cacheMisses++;
    const user = index.get(normalizedEmail) || null;

    // Update cache (LRU eviction)
    if (user && this.cache.size >= this.cacheSize) {
      const firstKey = this.cache.keys().next().value;
      this.cache.delete(firstKey);
    }

    if (user) {
      this.cache.set(normalizedEmail, user);
    }

    return user;
  }

  // Functional composition for complex queries
  createQuery() {
    return {
      where: (predicate) => ({
        and: (predicate2) => ({
          execute: (index) => {
            const results = [];
            for (const user of index.values()) {
              if (predicate(user) && predicate2(user)) {
                results.push(user);
              }
            }
            return results;
          }
        }),
        execute: (index) => {
          const results = [];
          for (const user of index.values()) {
            if (predicate(user)) {
              results.push(user);
            }
          }
          return results;
        }
      })
    };
  }

  getStats() {
    return {
      cacheHits: this.cacheHits,
      cacheMisses: this.cacheMisses,
      hitRate: this.cacheHits / (this.cacheHits + this.cacheMisses)
    };
  }
}

module.exports = { EmailSearchEngine };
```

**Benchmark Results:**
```
Dataset: 1,000,000 users
Index build time: 850ms (one-time)
Average search time: 0.3ms (cached), 0.9ms (uncached)
Memory usage: 180MB (index + cache)
Cache hit rate: 87% (typical workload)
```

**Scores:**
- Performance: 10/10 (O(1) lookup with caching)
- Code Quality: 7/10 (good balance of clarity and optimization)
- Maintainability: 9/10 (well-structured, testable, extensible)

## Voting Results

### Score Aggregation

```json
{
  "vote_distribution": {
    "functional": {
      "performance": 6.0,
      "code_quality": 9.0,
      "maintainability": 8.0,
      "weighted_total": 18.9
    },
    "imperative": {
      "performance": 8.0,
      "code_quality": 6.0,
      "maintainability": 7.0,
      "weighted_total": 18.4
    },
    "hybrid": {
      "performance": 10.0,
      "code_quality": 7.0,
      "maintainability": 9.0,
      "weighted_total": 25.8
    }
  },
  "winner": "hybrid",
  "consensus_score": 0.72,
  "margin": 6.9
}
```

### Winner Analysis

**Winner: Hybrid Approach**

**Strengths:**
- Best performance (10/10): O(1) lookup with 87% cache hit rate
- Strong maintainability (9/10): Clean API, testable, extensible
- Acceptable code quality (7/10): Well-structured despite complexity

**Why it won:**
- Performance weight (1.5x) heavily favored the O(1) lookup
- High maintainability score (1.2x weight) added significant value
- Only 2 points behind functional in code quality, but 4 points ahead in performance

**Comparison with runner-up (Functional):**
- 6.9 points ahead in weighted score
- 4 points better in performance (critical criterion)
- 1 point better in maintainability
- 2 points behind in code quality (acceptable tradeoff)

## Implementation Decision

### Selected Approach: Hybrid with Refinements

Based on voting results, implement the hybrid approach with the following refinements:

```javascript
// final-implementation.js
const { EmailSearchEngine } = require('./hybrid-search');

class UserRepository {
  constructor(database) {
    this.database = database;
    this.searchEngine = new EmailSearchEngine({
      cacheSize: 1000
    });
    this.indexReady = false;
  }

  async initialize() {
    // Build index on startup
    const userIterator = this.database.users.find().cursor();
    this.index = await this.searchEngine.buildIndex(userIterator);
    this.indexReady = true;
  }

  async findByEmail(email) {
    if (!this.indexReady) {
      throw new Error('Index not ready. Call initialize() first.');
    }

    return this.searchEngine.search(this.index, email);
  }

  // Maintain index on updates
  async updateUser(userId, updates) {
    const user = await this.database.users.updateOne(
      { _id: userId },
      { $set: updates }
    );

    // Update index if email changed
    if (updates.email) {
      this.index.set(updates.email.toLowerCase(), user);
    }

    return user;
  }

  getPerformanceStats() {
    return this.searchEngine.getStats();
  }
}

module.exports = { UserRepository };
```

## Testing Results

### Performance Tests

```javascript
// test/performance.test.js
describe('User Search Performance', () => {
  it('should handle 1M users with sub-millisecond search', async () => {
    const repo = new UserRepository(db);
    await repo.initialize();

    const start = Date.now();
    const user = await repo.findByEmail('test@example.com');
    const duration = Date.now() - start;

    expect(duration).toBeLessThan(2); // < 2ms
    expect(user).toBeDefined();
  });

  it('should maintain high cache hit rate', async () => {
    // Simulate realistic workload
    for (let i = 0; i < 10000; i++) {
      const randomEmail = emails[Math.floor(Math.random() * 100)]; // 100 popular emails
      await repo.findByEmail(randomEmail);
    }

    const stats = repo.getPerformanceStats();
    expect(stats.hitRate).toBeGreaterThan(0.8); // > 80%
  });
});
```

### Integration Tests

All three approaches passed integration tests, confirming functional correctness.

## Key Takeaways

1. **Voting Enabled Informed Decision**: Comparing three valid approaches revealed the optimal solution
2. **Weighted Criteria Matched Business Needs**: Performance was prioritized (1.5x weight) due to scale requirements
3. **Consensus Score (0.72)**: Moderate agreement indicates each approach had merits
4. **Hybrid Won by Balancing Tradeoffs**: Best performance without sacrificing maintainability

## Execution Metrics

```json
{
  "execution_summary": {
    "total_voters": 3,
    "execution_time": "4.2 min",
    "aggregation_method": "weighted_score"
  },
  "performance_comparison": {
    "functional": "245ms avg",
    "imperative": "0.8ms avg (indexed)",
    "hybrid": "0.3ms avg (cached)"
  },
  "decision_confidence": "high",
  "recommendation": "Proceed with hybrid approach"
}
```

## Conclusion

Voting mode enabled objective comparison of three implementation philosophies. The hybrid approach won by delivering optimal performance (critical for 1M+ records) while maintaining good code quality and excellent maintainability. The weighted scoring reflected business priorities and led to a data-driven decision.

This example demonstrates how voting mode is ideal for:
- Architecture decisions with multiple valid approaches
- Performance optimization where tradeoffs must be evaluated
- Situations where team consensus is needed
- Code review scenarios requiring objective comparison
