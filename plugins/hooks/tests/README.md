# Skill Activation Hook Tests

Comprehensive test suite for the skill activation hook system.

## Test Scripts

### 1. test-global-discovery.sh
**Purpose**: Tests plugin and skill discovery functions

**Tests**:
- ✅ Discover installed plugins from `~/.claude/plugins/`
- ✅ Find SKILL.md files in plugin directories
- ✅ Locate skill-rules.json files
- ✅ Handle missing/malformed plugin structures
- ✅ Performance: < 100ms

**Usage**:
```bash
./test-global-discovery.sh
```

### 2. test-yaml-parsing.sh
**Purpose**: Tests YAML frontmatter and metadata parsing

**Tests**:
- ✅ Parse standard YAML frontmatter
- ✅ Handle multiline descriptions
- ✅ Handle missing fields gracefully
- ✅ Support Korean (UTF-8) characters
- ✅ Parse skill-rules.json
- ✅ Aggregate metadata from YAML + JSON
- ✅ Performance: < 50ms

**Usage**:
```bash
./test-yaml-parsing.sh
```

### 3. test-plugin-discovery.sh
**Purpose**: Tests plugin and skill discovery functions

**Tests**:
- ✅ Discover installed plugins
- ✅ Find SKILL.md files in plugins
- ✅ Verify output format (plugin|skill|path)
- ✅ Check SKILL.md file existence
- ✅ Multiple plugins discovery
- ✅ Empty directory handling
- ✅ Performance: < 1000ms

**Usage**:
```bash
./test-plugin-discovery.sh
```

### 4. test-metadata-parser.sh
**Purpose**: Tests YAML frontmatter and metadata parsing

**Tests**:
- ✅ Parse YAML frontmatter from SKILL.md
- ✅ Parse skill-rules.json
- ✅ Aggregate skill metadata (pipe-separated)
- ✅ Handle missing frontmatter
- ✅ Handle malformed JSON
- ✅ Extract keywords from combined sources
- ✅ Output format validation
- ✅ Performance: < 10ms per parse

**Usage**:
```bash
./test-metadata-parser.sh
```

### 5. test-cache-manager.sh
**Purpose**: Tests cache management functions

**Tests**:
- ✅ Cache directory initialization
- ✅ Write and read cache
- ✅ Cache validity check (fresh)
- ✅ Cache validity check (stale)
- ✅ File change detection
- ✅ Cache update
- ✅ Multiple source files check
- ✅ Cache expiration (age-based)
- ✅ Missing cache file handling
- ✅ Concurrent access
- ✅ Performance: < 5ms per operation

**Usage**:
```bash
./test-cache-manager.sh
```

### 6. test-synonym-expansion.sh
**Purpose**: Tests synonym expansion and matching

**Tests**:
- ✅ Load synonyms.json
- ✅ Check file exists
- ✅ Verify JSON structure
- ✅ Count categories
- ✅ Keyword expansion
- ✅ Unknown keyword handling
- ✅ Performance: < 20ms per expansion

**Usage**:
```bash
./test-synonym-expansion.sh
```

### 7. test-tfidf-matching.sh
**Purpose**: Tests TF-IDF based skill matching

**Tests**:
- ✅ Verify tfidf-matcher.js exists
- ✅ Check Node.js availability
- ✅ Basic TF-IDF matching
- ✅ Score calculation
- ✅ Ranking order
- ✅ Empty prompt handling
- ✅ No matching skills
- ✅ Multiple keyword overlap
- ✅ JSON output format
- ✅ Performance: < 100ms

**Dependencies**:
- Node.js v14+
- npm packages: (see matchers/package.json)

**Usage**:
```bash
cd ../matchers && npm install
./test-tfidf-matching.sh
```

### 8. test-semantic-matching.sh
**Purpose**: Tests semantic matching with embeddings

**Tests**:
- ✅ Verify semantic-matcher.py exists
- ✅ Check Python availability
- ✅ Check Python dependencies
- ✅ Basic semantic matching
- ✅ Korean prompt support
- ✅ Similarity score calculation
- ✅ Empty prompt handling
- ✅ JSON output format
- ✅ Model caching
- ✅ Performance: < 350ms (after model load)

**Dependencies**:
- Python 3.8+
- pip packages: `sentence-transformers`, `numpy`

**Usage**:
```bash
cd ../matchers && pip install -r requirements.txt
./test-semantic-matching.sh
```

### 9. benchmark-performance.sh
**Purpose**: Comprehensive performance benchmarking

**Benchmarks**:
- **Tier 1 (Exact)**: Exact keyword matching
- **Tier 2 (TF-IDF)**: Statistical matching
- **Tier 3 (Semantic)**: Embedding similarity
- **End-to-end**: Full discovery workflow
- **Cache Operations**: Read/write performance
- **Metadata Parsing**: YAML + JSON parsing

**Test Scales**:
- 10 skills, 50 skills, 100 skills

**Metrics**:
- Average time per operation
- Total duration
- Performance report (JSON)

**Targets**:
- Tier 1: < 10ms
- Tier 2: < 100ms
- Tier 3: < 350ms
- End-to-end: < 200ms

**Usage**:
```bash
./benchmark-performance.sh
```

## Running All Tests

```bash
# Make scripts executable
chmod +x *.sh

# Run all tests
./run-all-tests.sh
```

## Test Output Format

All tests follow a consistent output format:

```
============================================
Test Name
============================================

  [TEST] Test case description ... PASS
  [TEST] Another test case ... FAIL
    Error: Detailed error message

============================================
Test Summary
============================================

  Total:  10
  Passed: 9
  Failed: 1

✓ ALL TESTS PASSED  (or ✗ TESTS FAILED)
```

## Test Fixtures

Tests create temporary fixtures in `./fixtures/` directory:
- Mock plugin structures
- Sample SKILL.md files
- Test skill-rules.json
- Benchmark test data

Fixtures are automatically cleaned up after each test.

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Test Skill Activation Hooks

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.10'

      - name: Install dependencies
        run: |
          cd plugins/hooks/matchers
          npm install
          pip install -r requirements.txt

      - name: Run tests
        run: |
          cd plugins/hooks/tests
          chmod +x *.sh
          ./run-all-tests.sh
```

## Performance Expectations

| Component | Target | Test Scale | Notes |
|-----------|--------|------------|-------|
| Plugin Discovery | < 1000ms | All plugins | Depends on plugin count |
| Metadata Parsing | < 10ms | Per skill | YAML + JSON parsing |
| Cache Operations | < 5ms | Per operation | Read/write |
| Synonym Expansion | < 20ms | Per expansion | With jq |
| TF-IDF Matching | < 100ms | 10-100 skills | Node.js required |
| Semantic Matching | < 350ms | 10-50 skills | After model load |
| End-to-end | < 200ms | Full pipeline | Discovery + matching |

## Troubleshooting

### Tests Failing: Node.js not found

**Solution**:
```bash
# macOS
brew install node

# Ubuntu
apt-get install nodejs npm
```

### Tests Failing: Python dependencies

**Solution**:
```bash
cd plugins/hooks/matchers
pip3 install -r requirements.txt
```

### Tests Failing: jq not found

**Solution**:
```bash
# macOS
brew install jq

# Ubuntu
apt-get install jq
```

### Semantic Matcher Slow on First Run

**Expected**: First run loads the sentence-transformers model (~100MB download + initialization)

**Solution**: Run once to cache model:
```bash
cd plugins/hooks/matchers
python3 semantic-matcher.py --test
```

### Permission Denied

**Solution**:
```bash
chmod +x plugins/hooks/tests/*.sh
```

## Development Workflow

### Adding New Tests

1. Create `test-new-feature.sh`
2. Follow existing test structure:
   - Setup fixtures
   - Define test functions
   - Print summary
   - Cleanup
3. Add to `run-all-tests.sh`
4. Update this README

### Test-Driven Development

```bash
# Watch mode (re-run on file change)
watch -n 2 ./test-tfidf-ranking.sh

# Run specific test
./test-yaml-parsing.sh

# Run with verbose output
bash -x ./test-global-discovery.sh
```

## Contributing

When adding new functionality to the skill activation hook:

1. Write tests first
2. Ensure tests pass locally
3. Add performance benchmarks if applicable
4. Update documentation

## Version History

### v2.0.0 (2025-11-24)
- ✅ Complete test suite overhaul
- ✅ 9 comprehensive test scripts
- ✅ New tests: plugin-discovery, metadata-parser, cache-manager
- ✅ Performance benchmarking
- ✅ CI/CD ready

### v1.0.0 (2025-11-23)
- ✅ Initial test suite
- ✅ Basic functionality tests

## License

MIT License

## Author

**inchan** - [GitHub](https://github.com/inchan)
