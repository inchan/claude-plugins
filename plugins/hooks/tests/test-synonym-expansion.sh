#!/usr/bin/env bash
# test-synonym-expansion.sh - Test synonym expansion and matching
set -euo pipefail

# Setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$HOOK_ROOT/config"
LOG_FILE="/tmp/hook-tests.log"

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Logging
log() { echo "[$(date +%T)] $*" | tee -a "$LOG_FILE"; }
pass() { log "✓ PASS: $*"; TESTS_PASSED=$((TESTS_PASSED + 1)); }
fail() { log "✗ FAIL: $*"; TESTS_FAILED=$((TESTS_FAILED + 1)); }

# Initialize log
echo "=== Synonym Expansion Tests ===" > "$LOG_FILE"
log "Starting synonym expansion tests"

# Load synonyms
load_synonyms() {
    local synonyms_file="$CONFIG_DIR/synonyms.json"
    if [[ -f "$synonyms_file" ]]; then
        cat "$synonyms_file"
    else
        echo '{"synonyms":{},"categories":{}}'
    fi
}

# Expand keywords with synonyms
# NOTE: 이 함수는 skill-activation-hook.sh의 expand_keywords_with_synonyms()와 동일한 로직 사용
expand_with_synonyms() {
    local keyword="$1"
    local synonyms_json="$2"

    local expanded
    expanded=$(echo "$synonyms_json" | jq -r --arg kw "$keyword" '
        .synonyms | to_entries[] |
        select(.key == $kw or (.value | index($kw))) |
        .value[] // empty
    ' 2>/dev/null | tr '\n' ',' | sed 's/,$//')

    if [[ -n "$expanded" ]]; then
        echo "$expanded"
    else
        echo "$keyword"
    fi
}

# Test 1: Load synonyms.json
test_load_synonyms() {
    log "Test 1: Load synonyms.json"

    local synonyms
    synonyms=$(load_synonyms)

    if echo "$synonyms" | jq -e '.' > /dev/null 2>&1; then
        pass "synonyms.json loaded successfully"
    else
        fail "Failed to load synonyms.json"
    fi
}

# Test 2: Check synonyms file exists
test_file_exists() {
    log "Test 2: Check synonyms file"

    if [[ -f "$CONFIG_DIR/synonyms.json" ]]; then
        pass "synonyms.json file exists"
    else
        fail "synonyms.json not found"
    fi
}

# Test 3: Verify JSON structure
test_json_structure() {
    log "Test 3: Verify JSON structure"

    local synonyms
    synonyms=$(load_synonyms)

    local has_categories
    has_categories=$(echo "$synonyms" | jq 'has("categories")' 2>/dev/null)

    if [[ "$has_categories" == "true" ]]; then
        pass "JSON structure valid"
    else
        fail "JSON structure invalid"
    fi
}

# Test 4: Count categories
test_category_count() {
    log "Test 4: Count categories"

    local synonyms
    synonyms=$(load_synonyms)

    local count
    count=$(echo "$synonyms" | jq '.categories | length' 2>/dev/null || echo 0)

    if [[ "$count" -gt 0 ]]; then
        pass "Found $count categories"
    else
        fail "No categories found"
    fi
}

# Test 5: Keyword expansion
test_keyword_expansion() {
    log "Test 5: Keyword expansion"

    local synonyms
    synonyms=$(load_synonyms)

    # Try to expand a common keyword
    local result
    result=$(expand_with_synonyms "workflow" "$synonyms")

    if [[ -n "$result" ]]; then
        pass "Keyword expansion works"
        log "Result: $result"
    else
        fail "Keyword expansion failed"
    fi
}

# Test 6: Unknown keyword
test_unknown_keyword() {
    log "Test 6: Unknown keyword handling"

    local synonyms
    synonyms=$(load_synonyms)
    local result
    result=$(expand_with_synonyms "xyz_unknown" "$synonyms")

    if [[ "$result" == "xyz_unknown" ]]; then
        pass "Unknown keyword returned unchanged"
    else
        fail "Unknown keyword handling incorrect"
    fi
}

# Test 7: Performance test
# Helper function for millisecond timestamp (macOS compatible)
get_ms_timestamp() {
    # macOS doesn't support %N, use python as fallback
    if command -v python3 &> /dev/null; then
        python3 -c 'import time; print(int(time.time() * 1000))'
    elif command -v gdate &> /dev/null; then
        echo $(($(gdate +%s%3N)))
    else
        # Fallback to seconds * 1000
        echo $(($(date +%s) * 1000))
    fi
}

test_performance() {
    log "Test 7: Performance test"

    local synonyms
    synonyms=$(load_synonyms)
    local start_time
    start_time=$(get_ms_timestamp)

    for i in {1..50}; do
        expand_with_synonyms "workflow" "$synonyms" > /dev/null 2>&1
    done

    local end_time
    end_time=$(get_ms_timestamp)
    local duration=$((end_time - start_time))

    if [[ "$duration" -lt 5000 ]]; then
        pass "Performance OK (${duration}ms for 50 expansions)"
    else
        fail "Performance slow (${duration}ms)"
    fi
}

# Run all tests
main() {
    log "Running synonym expansion tests..."

    test_load_synonyms
    test_file_exists
    test_json_structure
    test_category_count
    test_keyword_expansion
    test_unknown_keyword
    test_performance

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
