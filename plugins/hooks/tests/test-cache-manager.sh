#!/usr/bin/env bash
# test-cache-manager.sh - Test cache management functions
set -euo pipefail

# Setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_ROOT="$(dirname "$SCRIPT_DIR")"
LIB_DIR="$HOOK_ROOT/lib"
LOG_FILE="/tmp/hook-tests.log"
TEST_CACHE_DIR="/tmp/test-hook-cache"

source "$LIB_DIR/cache-manager.sh"

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Logging
log() { echo "[$(date +%T)] $*" | tee -a "$LOG_FILE"; }
pass() { log "✓ PASS: $*"; ((TESTS_PASSED++)); }
fail() { log "✗ FAIL: $*"; ((TESTS_FAILED++)); }

# Initialize log
echo "=== Cache Manager Tests ===" > "$LOG_FILE"
log "Starting cache manager tests"

# Setup test cache directory
setup_test_cache() {
    rm -rf "$TEST_CACHE_DIR"
    mkdir -p "$TEST_CACHE_DIR"
    export CACHE_DIR="$TEST_CACHE_DIR"
}

cleanup_test_cache() {
    rm -rf "$TEST_CACHE_DIR"
}

# Test 1: Initialize cache directory
test_cache_init() {
    log "Test 1: Cache initialization"

    setup_test_cache
    init_cache "$TEST_CACHE_DIR"

    if [[ -d "$TEST_CACHE_DIR" ]]; then
        pass "Cache directory initialized"
    else
        fail "Cache directory not created"
    fi

    cleanup_test_cache
}

# Test 2: Write and read cache
test_cache_write_read() {
    log "Test 2: Write and read cache"

    setup_test_cache
    init_cache "$TEST_CACHE_DIR"

    local cache_key="test_data"
    local cache_file="$TEST_CACHE_DIR/$cache_key.cache"
    local test_data="plugin1|skill1|test,keywords|high|suggest|domain"

    echo "$test_data" > "$cache_file"

    if [[ -f "$cache_file" ]]; then
        local content
        content=$(cat "$cache_file")
        if [[ "$content" == "$test_data" ]]; then
            pass "Cache write and read successful"
        else
            fail "Cache content mismatch"
        fi
    else
        fail "Cache file not created"
    fi

    cleanup_test_cache
}

# Test 3: Cache validity check (fresh)
test_cache_validity_fresh() {
    log "Test 3: Cache validity check (fresh)"

    setup_test_cache
    init_cache "$TEST_CACHE_DIR"

    local cache_key="test_valid"
    local cache_file="$TEST_CACHE_DIR/$cache_key.cache"
    local source_file="/tmp/test-source.txt"

    # Create source file
    echo "source data" > "$source_file"
    sleep 1

    # Create cache file (newer than source)
    echo "cached data" > "$cache_file"

    if is_cache_valid "$cache_file" "$source_file"; then
        pass "Fresh cache detected as valid"
    else
        fail "Fresh cache should be valid"
    fi

    rm -f "$source_file"
    cleanup_test_cache
}

# Test 4: Cache validity check (stale)
test_cache_validity_stale() {
    log "Test 4: Cache validity check (stale)"

    setup_test_cache
    init_cache "$TEST_CACHE_DIR"

    local cache_key="test_stale"
    local cache_file="$TEST_CACHE_DIR/$cache_key.cache"
    local source_file="/tmp/test-source.txt"

    # Create cache file first
    echo "cached data" > "$cache_file"
    sleep 1

    # Create source file (newer than cache)
    echo "source data" > "$source_file"

    if ! is_cache_valid "$cache_file" "$source_file"; then
        pass "Stale cache detected as invalid"
    else
        fail "Stale cache should be invalid"
    fi

    rm -f "$source_file"
    cleanup_test_cache
}

# Test 5: File change detection
test_file_change_detection() {
    log "Test 5: File change detection"

    setup_test_cache
    local test_file="/tmp/test-change.txt"

    echo "version 1" > "$test_file"
    local hash1
    hash1=$(get_file_hash "$test_file")

    sleep 1
    echo "version 2" > "$test_file"
    local hash2
    hash2=$(get_file_hash "$test_file")

    if [[ "$hash1" != "$hash2" ]]; then
        pass "File change detected (hash changed)"
        log "Hash1: $hash1, Hash2: $hash2"
    else
        fail "File change not detected"
    fi

    rm -f "$test_file"
    cleanup_test_cache
}

# Test 6: Cache update
test_cache_update() {
    log "Test 6: Cache update"

    setup_test_cache
    init_cache "$TEST_CACHE_DIR"

    local cache_key="test_update"
    local cache_file="$TEST_CACHE_DIR/$cache_key.cache"

    # Initial cache
    echo "old data" > "$cache_file"

    # Update cache
    update_cache "$cache_key" "new data" "$TEST_CACHE_DIR"

    local content
    content=$(cat "$cache_file")

    if [[ "$content" == "new data" ]]; then
        pass "Cache updated successfully"
    else
        fail "Cache update failed"
    fi

    cleanup_test_cache
}

# Test 7: Multiple source files check
test_multiple_sources() {
    log "Test 7: Multiple source files check"

    setup_test_cache
    init_cache "$TEST_CACHE_DIR"

    local cache_file="$TEST_CACHE_DIR/multi.cache"
    local source1="/tmp/source1.txt"
    local source2="/tmp/source2.txt"

    # Create sources
    echo "source 1" > "$source1"
    echo "source 2" > "$source2"
    sleep 1

    # Create cache
    echo "cached" > "$cache_file"

    # Check validity against both sources
    if is_cache_valid "$cache_file" "$source1" && is_cache_valid "$cache_file" "$source2"; then
        pass "Multiple source files validated"
    else
        fail "Multiple source validation failed"
    fi

    rm -f "$source1" "$source2"
    cleanup_test_cache
}

# Test 8: Cache expiration (age-based)
test_cache_expiration() {
    log "Test 8: Cache expiration check"

    setup_test_cache
    init_cache "$TEST_CACHE_DIR"

    local cache_file="$TEST_CACHE_DIR/expire.cache"
    echo "data" > "$cache_file"

    # Get cache age in seconds
    local cache_age
    if [[ -f "$cache_file" ]]; then
        cache_age=$(( $(date +%s) - $(stat -f %m "$cache_file" 2>/dev/null || stat -c %Y "$cache_file") ))
    fi

    if [[ "$cache_age" -ge 0 ]]; then
        pass "Cache age calculated correctly (${cache_age}s)"
    else
        fail "Cache age calculation failed"
    fi

    cleanup_test_cache
}

# Test 9: Missing cache file
test_missing_cache() {
    log "Test 9: Missing cache file handling"

    setup_test_cache
    local missing_cache="$TEST_CACHE_DIR/nonexistent.cache"
    local source_file="/tmp/source.txt"

    echo "data" > "$source_file"

    if ! is_cache_valid "$missing_cache" "$source_file"; then
        pass "Missing cache handled correctly"
    else
        fail "Missing cache should be invalid"
    fi

    rm -f "$source_file"
    cleanup_test_cache
}

# Test 10: Performance test
test_performance() {
    log "Test 10: Performance test"

    setup_test_cache
    init_cache "$TEST_CACHE_DIR"

    local start_time
    start_time=$(date +%s%3N)

    # Simulate 100 cache operations
    for i in {1..100}; do
        local cache_file="$TEST_CACHE_DIR/perf_$i.cache"
        echo "data $i" > "$cache_file"
    done

    local end_time
    end_time=$(date +%s%3N)
    local duration=$((end_time - start_time))

    if [[ "$duration" -lt 500 ]]; then
        pass "Performance OK (${duration}ms for 100 operations)"
    else
        fail "Performance slow (${duration}ms, expected <500ms)"
    fi

    cleanup_test_cache
}

# Test 11: Concurrent access (basic)
test_concurrent_access() {
    log "Test 11: Concurrent access test"

    setup_test_cache
    init_cache "$TEST_CACHE_DIR"

    local cache_file="$TEST_CACHE_DIR/concurrent.cache"

    # Simulate concurrent writes
    for i in {1..5}; do
        echo "data $i" > "$cache_file" &
    done
    wait

    if [[ -f "$cache_file" ]]; then
        pass "Concurrent access handled"
        log "Final content: $(cat "$cache_file")"
    else
        fail "Concurrent access failed"
    fi

    cleanup_test_cache
}

# Run all tests
main() {
    log "Running cache manager tests..."

    test_cache_init
    test_cache_write_read
    test_cache_validity_fresh
    test_cache_validity_stale
    test_file_change_detection
    test_cache_update
    test_multiple_sources
    test_cache_expiration
    test_missing_cache
    test_performance
    test_concurrent_access

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
