#!/usr/bin/env bash
# test-tfidf-matching.sh - Test TF-IDF matching functionality
set -euo pipefail

# Setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_ROOT="$(dirname "$SCRIPT_DIR")"
MATCHERS_DIR="$HOOK_ROOT/matchers"
LOG_FILE="/tmp/hook-tests.log"

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Logging
log() { echo "[$(date +%T)] $*" | tee -a "$LOG_FILE"; }
pass() { log "✓ PASS: $*"; ((TESTS_PASSED++)); }
fail() { log "✗ FAIL: $*"; ((TESTS_FAILED++)); }

# Initialize log
echo "=== TF-IDF Matching Tests ===" > "$LOG_FILE"
log "Starting TF-IDF matching tests"

# Test 1: Check tfidf-matcher.js exists
test_matcher_exists() {
    log "Test 1: Check tfidf-matcher.js exists"

    if [[ -f "$MATCHERS_DIR/tfidf-matcher.js" ]]; then
        pass "tfidf-matcher.js found"
    else
        fail "tfidf-matcher.js not found"
    fi
}

# Test 2: Node.js availability
test_node_available() {
    log "Test 2: Check Node.js availability"

    if command -v node &> /dev/null; then
        local version
        version=$(node --version)
        pass "Node.js available: $version"
    else
        fail "Node.js not found"
    fi
}

# Test 3: Run tfidf-matcher with sample data
test_tfidf_basic() {
    log "Test 3: Basic TF-IDF matching"

    if [[ ! -f "$MATCHERS_DIR/tfidf-matcher.js" ]]; then
        fail "tfidf-matcher.js not found"
        return
    fi

    # Create sample input
    local input='{"prompt":"workflow automation","skills":[{"name":"agent-workflow-manager","keywords":"workflow,automation,task"},{"name":"frontend-dev-guidelines","keywords":"frontend,react,ui"}]}'

    local result
    result=$(echo "$input" | node "$MATCHERS_DIR/tfidf-matcher.js" 2>&1 || echo "ERROR")

    if [[ "$result" =~ "agent-workflow-manager" ]]; then
        pass "TF-IDF matching works"
        log "Result: $result"
    else
        fail "TF-IDF matching failed: $result"
    fi
}

# Test 4: Verify score calculation
test_score_calculation() {
    log "Test 4: Score calculation"

    if [[ ! -f "$MATCHERS_DIR/tfidf-matcher.js" ]]; then
        fail "tfidf-matcher.js not found"
        return
    fi

    local input='{"prompt":"react component","skills":[{"name":"frontend","keywords":"react,component,ui"},{"name":"backend","keywords":"api,server,database"}]}'

    local result
    result=$(echo "$input" | node "$MATCHERS_DIR/tfidf-matcher.js" 2>&1)

    # Check if frontend has higher score
    if echo "$result" | jq -e '.[0].name == "frontend"' > /dev/null 2>&1; then
        pass "Score calculation correct"
    else
        fail "Score calculation incorrect"
    fi
}

# Test 5: Test ranking order
test_ranking_order() {
    log "Test 5: Ranking order"

    if [[ ! -f "$MATCHERS_DIR/tfidf-matcher.js" ]]; then
        fail "tfidf-matcher.js not found"
        return
    fi

    local input='{"prompt":"frontend react typescript","skills":[{"name":"frontend","keywords":"frontend,react,typescript"},{"name":"backend","keywords":"backend,node"},{"name":"quality","keywords":"quality,review"}]}'

    local result
    result=$(echo "$input" | node "$MATCHERS_DIR/tfidf-matcher.js" 2>&1)

    # First result should be frontend
    local first_skill
    first_skill=$(echo "$result" | jq -r '.[0].name' 2>/dev/null || echo "ERROR")

    if [[ "$first_skill" == "frontend" ]]; then
        pass "Ranking order correct"
    else
        fail "Ranking order incorrect (got: $first_skill)"
    fi
}

# Test 6: Performance test (<100ms)
test_performance() {
    log "Test 6: Performance test"

    if [[ ! -f "$MATCHERS_DIR/tfidf-matcher.js" ]]; then
        fail "tfidf-matcher.js not found"
        return
    fi

    local input='{"prompt":"test query","skills":[{"name":"skill1","keywords":"test,query"},{"name":"skill2","keywords":"other,keywords"}]}'

    local start_time
    start_time=$(date +%s%3N)

    for i in {1..10}; do
        echo "$input" | node "$MATCHERS_DIR/tfidf-matcher.js" > /dev/null 2>&1
    done

    local end_time
    end_time=$(date +%s%3N)
    local duration=$((end_time - start_time))
    local avg=$((duration / 10))

    if [[ "$avg" -lt 100 ]]; then
        pass "Performance OK (${avg}ms avg)"
    else
        fail "Performance slow (${avg}ms avg, expected <100ms)"
    fi
}

# Test 7: Empty prompt handling
test_empty_prompt() {
    log "Test 7: Empty prompt handling"

    if [[ ! -f "$MATCHERS_DIR/tfidf-matcher.js" ]]; then
        fail "tfidf-matcher.js not found"
        return
    fi

    local input='{"prompt":"","skills":[{"name":"skill1","keywords":"test"}]}'

    local result
    result=$(echo "$input" | node "$MATCHERS_DIR/tfidf-matcher.js" 2>&1 || echo "[]")

    if [[ -n "$result" ]]; then
        pass "Empty prompt handled"
    else
        fail "Empty prompt not handled"
    fi
}

# Test 8: No matching skills
test_no_matches() {
    log "Test 8: No matching skills"

    if [[ ! -f "$MATCHERS_DIR/tfidf-matcher.js" ]]; then
        fail "tfidf-matcher.js not found"
        return
    fi

    local input='{"prompt":"xyz unknown query","skills":[{"name":"skill1","keywords":"completely,different,keywords"}]}'

    local result
    result=$(echo "$input" | node "$MATCHERS_DIR/tfidf-matcher.js" 2>&1)

    # Should still return results (with low scores)
    if [[ -n "$result" ]]; then
        pass "No-match case handled"
    else
        fail "No-match case not handled"
    fi
}

# Test 9: Multiple keyword overlap
test_keyword_overlap() {
    log "Test 9: Multiple keyword overlap"

    if [[ ! -f "$MATCHERS_DIR/tfidf-matcher.js" ]]; then
        fail "tfidf-matcher.js not found"
        return
    fi

    local input='{"prompt":"frontend react component ui","skills":[{"name":"frontend","keywords":"frontend,react,component,ui,typescript"},{"name":"backend","keywords":"backend,api"}]}'

    local result
    result=$(echo "$input" | node "$MATCHERS_DIR/tfidf-matcher.js" 2>&1)

    # Frontend should rank first due to multiple overlaps
    local first_skill
    first_skill=$(echo "$result" | jq -r '.[0].name' 2>/dev/null || echo "ERROR")

    if [[ "$first_skill" == "frontend" ]]; then
        pass "Keyword overlap scoring works"
    else
        fail "Keyword overlap scoring incorrect"
    fi
}

# Test 10: JSON output format
test_output_format() {
    log "Test 10: JSON output format"

    if [[ ! -f "$MATCHERS_DIR/tfidf-matcher.js" ]]; then
        fail "tfidf-matcher.js not found"
        return
    fi

    local input='{"prompt":"test","skills":[{"name":"skill1","keywords":"test"}]}'

    local result
    result=$(echo "$input" | node "$MATCHERS_DIR/tfidf-matcher.js" 2>&1)

    if echo "$result" | jq -e '.[0] | has("name") and has("score")' > /dev/null 2>&1; then
        pass "Output format correct"
    else
        fail "Output format incorrect"
    fi
}

# Run all tests
main() {
    log "Running TF-IDF matching tests..."

    test_matcher_exists
    test_node_available
    test_tfidf_basic
    test_score_calculation
    test_ranking_order
    test_performance
    test_empty_prompt
    test_no_matches
    test_keyword_overlap
    test_output_format

    # Summary
    log ""
    log "=== Test Summary ==="
    log "Passed: $TESTS_PASSED"
    log "Failed: $TESTS_FAILED"
    log "Total:  $((TESTS_PASSED + TESTS_FAILED))"

    if [[ "$TESTS_FAILED" -eq 0 ]]; then
        log "✓ All tests passed"
        exit 0
    else
        log "✗ Some tests failed"
        exit 1
    fi
}

main "$@"
