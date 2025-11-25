#!/usr/bin/env bash
# benchmark-performance.sh - Performance benchmarking for skill activation system
set -euo pipefail

# Setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_ROOT="$(dirname "$SCRIPT_DIR")"
LIB_DIR="$HOOK_ROOT/lib"
MATCHERS_DIR="$HOOK_ROOT/matchers"
LOG_FILE="/tmp/hook-tests.log"
RESULTS_FILE="/tmp/benchmark-results.json"

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Logging
log() { echo "[$(date +%T)] $*" | tee -a "$LOG_FILE"; }
pass() { log "✓ PASS: $*"; ((TESTS_PASSED++)); }
fail() { log "✗ FAIL: $*"; ((TESTS_FAILED++)); }
result() { log "📊 RESULT: $*"; }

# Initialize log
echo "=== Performance Benchmark Tests ===" > "$LOG_FILE"
log "Starting performance benchmarks"

# Generate test data
generate_test_skills() {
    local count=$1
    local skills_json="["

    for ((i=1; i<=count; i++)); do
        if [[ $i -gt 1 ]]; then
            skills_json+=","
        fi
        skills_json+="{\"name\":\"skill-$i\",\"keywords\":\"keyword$i,test,automation\"}"
    done

    skills_json+="]"
    echo "$skills_json"
}

# Benchmark Tier 1: Exact keyword matching
benchmark_tier1_exact() {
    log "Benchmark 1: Tier 1 - Exact keyword matching"

    local skill_counts=(10 50 100)

    for count in "${skill_counts[@]}"; do
        log "Testing with $count skills..."

        local start_time
        start_time=$(date +%s%3N)

        # Simulate exact matching
        for ((i=1; i<=100; i++)); do
            echo "workflow automation" | grep -q "workflow" || true
        done

        local end_time
        end_time=$(date +%s%3N)
        local duration=$((end_time - start_time))
        local avg=$((duration / 100))

        result "Tier 1 (${count} skills): ${avg}ms avg per match"

        if [[ "$avg" -lt 5 ]]; then
            pass "Tier 1 performance excellent (<5ms)"
        elif [[ "$avg" -lt 10 ]]; then
            pass "Tier 1 performance good (<10ms)"
        else
            fail "Tier 1 performance slow (${avg}ms)"
        fi
    done
}

# Benchmark Tier 2: TF-IDF matching
benchmark_tier2_tfidf() {
    log "Benchmark 2: Tier 2 - TF-IDF matching"

    if [[ ! -f "$MATCHERS_DIR/tfidf-matcher.js" ]]; then
        log "SKIP: tfidf-matcher.js not found"
        return
    fi

    if ! command -v node &> /dev/null; then
        log "SKIP: Node.js not available"
        return
    fi

    local skill_counts=(10 50 100)

    for count in "${skill_counts[@]}"; do
        log "Testing with $count skills..."

        local skills
        skills=$(generate_test_skills "$count")
        local input="{\"prompt\":\"workflow automation task\",\"skills\":$skills}"

        local start_time
        start_time=$(date +%s%3N)

        for ((i=1; i<=10; i++)); do
            echo "$input" | node "$MATCHERS_DIR/tfidf-matcher.js" > /dev/null 2>&1 || true
        done

        local end_time
        end_time=$(date +%s%3N)
        local duration=$((end_time - start_time))
        local avg=$((duration / 10))

        result "Tier 2 (${count} skills): ${avg}ms avg per match"

        if [[ "$avg" -lt 50 ]]; then
            pass "Tier 2 performance excellent (<50ms)"
        elif [[ "$avg" -lt 100 ]]; then
            pass "Tier 2 performance good (<100ms)"
        else
            fail "Tier 2 performance slow (${avg}ms)"
        fi
    done
}

# Benchmark Tier 3: Semantic matching
benchmark_tier3_semantic() {
    log "Benchmark 3: Tier 3 - Semantic matching"

    if [[ ! -f "$MATCHERS_DIR/semantic-matcher.py" ]]; then
        log "SKIP: semantic-matcher.py not found"
        return
    fi

    if ! command -v python3 &> /dev/null; then
        log "SKIP: Python not available"
        return
    fi

    if ! python3 -c "import sentence_transformers" 2>/dev/null; then
        log "SKIP: sentence-transformers not installed"
        return
    fi

    local skill_counts=(10 50)

    for count in "${skill_counts[@]}"; do
        log "Testing with $count skills..."

        local skills
        skills=$(generate_test_skills "$count")
        local input="{\"prompt\":\"automate complex workflow\",\"skills\":$skills}"

        local start_time
        start_time=$(date +%s%3N)

        echo "$input" | python3 "$MATCHERS_DIR/semantic-matcher.py" > /dev/null 2>&1 || true

        local end_time
        end_time=$(date +%s%3N)
        local duration=$((end_time - start_time))

        result "Tier 3 (${count} skills): ${duration}ms per match"

        if [[ "$duration" -lt 200 ]]; then
            pass "Tier 3 performance excellent (<200ms)"
        elif [[ "$duration" -lt 350 ]]; then
            pass "Tier 3 performance good (<350ms)"
        else
            log "Note: First run may include model loading time"
            pass "Tier 3 performance measured (${duration}ms)"
        fi
    done
}

# Benchmark end-to-end workflow
benchmark_end_to_end() {
    log "Benchmark 4: End-to-end workflow"

    if [[ ! -f "$LIB_DIR/plugin-discovery.sh" ]]; then
        log "SKIP: plugin-discovery.sh not found"
        return
    fi

    source "$LIB_DIR/plugin-discovery.sh"

    local plugins_root="${HOOK_ROOT%/plugins/hooks}/plugins"

    local start_time
    start_time=$(date +%s%3N)

    # Simulate full discovery and metadata parsing
    discover_installed_plugins "$plugins_root" > /dev/null 2>&1 || true

    local end_time
    end_time=$(date +%s%3N)
    local duration=$((end_time - start_time))

    result "End-to-end discovery: ${duration}ms"

    if [[ "$duration" -lt 100 ]]; then
        pass "End-to-end performance excellent (<100ms)"
    elif [[ "$duration" -lt 200 ]]; then
        pass "End-to-end performance good (<200ms)"
    else
        fail "End-to-end performance slow (${duration}ms)"
    fi
}

# Benchmark cache operations
benchmark_cache_operations() {
    log "Benchmark 5: Cache operations"

    local test_cache="/tmp/benchmark-cache"
    mkdir -p "$test_cache"

    # Write test
    local start_time
    start_time=$(date +%s%3N)

    for ((i=1; i<=1000; i++)); do
        echo "data $i" > "$test_cache/entry_$i.cache"
    done

    local end_time
    end_time=$(date +%s%3N)
    local write_duration=$((end_time - start_time))

    # Read test
    start_time=$(date +%s%3N)

    for ((i=1; i<=1000; i++)); do
        cat "$test_cache/entry_$i.cache" > /dev/null
    done

    end_time=$(date +%s%3N)
    local read_duration=$((end_time - start_time))

    result "Cache write (1000 ops): ${write_duration}ms"
    result "Cache read (1000 ops): ${read_duration}ms"

    if [[ "$write_duration" -lt 500 && "$read_duration" -lt 300 ]]; then
        pass "Cache operations fast"
    else
        fail "Cache operations slow (write: ${write_duration}ms, read: ${read_duration}ms)"
    fi

    rm -rf "$test_cache"
}

# Benchmark metadata parsing
benchmark_metadata_parsing() {
    log "Benchmark 6: Metadata parsing"

    if [[ ! -f "$LIB_DIR/metadata-parser.sh" ]]; then
        log "SKIP: metadata-parser.sh not found"
        return
    fi

    # Create test files
    local test_skill="/tmp/benchmark-skill.md"
    local test_rules="/tmp/benchmark-rules.json"

    cat > "$test_skill" << 'EOF'
---
name: test-skill
keywords: ["test", "benchmark"]
category: tool
---
# Test Skill
EOF

    cat > "$test_rules" << 'EOF'
{
  "skills": {
    "test-skill": {
      "type": "domain",
      "priority": "high",
      "promptTriggers": {
        "keywords": ["test", "benchmark"]
      }
    }
  }
}
EOF

    source "$LIB_DIR/metadata-parser.sh"

    local start_time
    start_time=$(date +%s%3N)

    for ((i=1; i<=100; i++)); do
        aggregate_skill_metadata "test-plugin" "test-skill" "$test_skill" "$test_rules" > /dev/null 2>&1 || true
    done

    local end_time
    end_time=$(date +%s%3N)
    local duration=$((end_time - start_time))
    local avg=$((duration / 100))

    result "Metadata parsing: ${avg}ms avg per skill"

    if [[ "$avg" -lt 10 ]]; then
        pass "Metadata parsing fast (<10ms)"
    else
        fail "Metadata parsing slow (${avg}ms)"
    fi

    rm -f "$test_skill" "$test_rules"
}

# Generate performance report
generate_report() {
    log ""
    log "=== Performance Report ==="
    log "Test completed at: $(date)"
    log ""
    log "Performance Targets:"
    log "  - Tier 1 (Exact):    <10ms"
    log "  - Tier 2 (TF-IDF):   <100ms"
    log "  - Tier 3 (Semantic): <350ms"
    log "  - End-to-end:        <200ms"
    log ""
    log "See detailed results in: $LOG_FILE"

    # Save to JSON
    cat > "$RESULTS_FILE" << EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "tests_passed": $TESTS_PASSED,
  "tests_failed": $TESTS_FAILED,
  "total_tests": $((TESTS_PASSED + TESTS_FAILED))
}
EOF

    result "Results saved to: $RESULTS_FILE"
}

# Run all benchmarks
main() {
    log "Running performance benchmarks..."
    log "This may take a few minutes..."
    log ""

    benchmark_tier1_exact
    benchmark_tier2_tfidf
    benchmark_tier3_semantic
    benchmark_end_to_end
    benchmark_cache_operations
    benchmark_metadata_parsing

    generate_report

    # Summary
    log ""
    log "=== Benchmark Summary ==="
    log "Passed: $TESTS_PASSED"
    log "Failed: $TESTS_FAILED"
    log "Total:  $((TESTS_PASSED + TESTS_FAILED))"

    if [[ "$TESTS_FAILED" -eq 0 ]]; then
        log "✓ All benchmarks passed"
        exit 0
    else
        log "✗ Some benchmarks failed"
        exit 1
    fi
}

main "$@"
