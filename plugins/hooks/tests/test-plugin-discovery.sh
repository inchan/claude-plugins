#!/usr/bin/env bash
# test-plugin-discovery.sh - Test plugin and skill discovery functions
set -euo pipefail

# Setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_ROOT="$(dirname "$SCRIPT_DIR")"
LIB_DIR="$HOOK_ROOT/lib"
LOG_FILE="/tmp/hook-tests.log"

source "$LIB_DIR/plugin-discovery.sh"

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Logging
log() { echo "[$(date +%T)] $*" | tee -a "$LOG_FILE"; }
pass() { log "✓ PASS: $*"; ((TESTS_PASSED++)); }
fail() { log "✗ FAIL: $*"; ((TESTS_FAILED++)); }

# Initialize log
echo "=== Plugin Discovery Tests ===" > "$LOG_FILE"
log "Starting plugin discovery tests"

# Test 1: discover_installed_plugins finds plugins
test_discover_plugins() {
    log "Test 1: discover_installed_plugins"

    local plugins_root="${HOOK_ROOT%/plugins/hooks}/plugins"
    local result
    result=$(discover_installed_plugins "$plugins_root")

    if [[ -n "$result" ]]; then
        local count
        count=$(echo "$result" | wc -l | tr -d ' ')
        pass "Found $count plugins"
        log "Plugins: $result"
    else
        fail "No plugins found"
    fi
}

# Test 2: discover_plugin_skills finds SKILL.md files
test_discover_skills() {
    log "Test 2: discover_plugin_skills"

    local plugins_root="${HOOK_ROOT%/plugins/hooks}/plugins"
    local plugin_name="workflow-automation"
    local plugin_path="$plugins_root/$plugin_name"

    if [[ -d "$plugin_path" ]]; then
        local result
        result=$(discover_plugin_skills "$plugin_name" "$plugin_path")

        if [[ -n "$result" ]]; then
            local count
            count=$(echo "$result" | wc -l | tr -d ' ')
            pass "Found $count skills in $plugin_name"
            log "Sample skills: $(echo "$result" | head -3)"
        else
            fail "No skills found in $plugin_name"
        fi
    else
        fail "Plugin not found: $plugin_path"
    fi
}

# Test 3: Verify output format (plugin_name|skill_name|skill_path)
test_output_format() {
    log "Test 3: Output format verification"

    local plugins_root="${HOOK_ROOT%/plugins/hooks}/plugins"
    local plugin_name="workflow-automation"
    local plugin_path="$plugins_root/$plugin_name"

    if [[ -d "$plugin_path" ]]; then
        local result
        result=$(discover_plugin_skills "$plugin_name" "$plugin_path" | head -1)

        # Count pipe separators
        local pipe_count
        pipe_count=$(echo "$result" | tr -cd '|' | wc -c | tr -d ' ')

        if [[ "$pipe_count" -eq 2 ]]; then
            pass "Output format is correct (3 fields)"
            log "Sample: $result"
        else
            fail "Output format incorrect (expected 2 pipes, got $pipe_count)"
        fi
    else
        fail "Plugin not found: $plugin_path"
    fi
}

# Test 4: Check SKILL.md file existence
test_skill_file_exists() {
    log "Test 4: SKILL.md file existence"

    local plugins_root="${HOOK_ROOT%/plugins/hooks}/plugins"
    local result
    result=$(discover_installed_plugins "$plugins_root" | head -1)
    local plugin_name
    plugin_name=$(echo "$result" | cut -d'|' -f1)
    local plugin_path
    plugin_path=$(echo "$result" | cut -d'|' -f2)

    local skills
    skills=$(discover_plugin_skills "$plugin_name" "$plugin_path")

    if [[ -n "$skills" ]]; then
        local first_skill
        first_skill=$(echo "$skills" | head -1)
        local skill_path
        skill_path=$(echo "$first_skill" | cut -d'|' -f3)

        if [[ -f "$skill_path" ]]; then
            pass "SKILL.md file exists: $skill_path"
        else
            fail "SKILL.md file not found: $skill_path"
        fi
    else
        fail "No skills to test"
    fi
}

# Test 5: Multiple plugins discovery
test_multiple_plugins() {
    log "Test 5: Multiple plugins discovery"

    local plugins_root="${HOOK_ROOT%/plugins/hooks}/plugins"
    local plugins
    plugins=$(discover_installed_plugins "$plugins_root")
    local count
    count=$(echo "$plugins" | wc -l | tr -d ' ')

    if [[ "$count" -ge 3 ]]; then
        pass "Multiple plugins discovered ($count plugins)"
    else
        fail "Expected at least 3 plugins, got $count"
    fi
}

# Test 6: Empty directory handling
test_empty_directory() {
    log "Test 6: Empty directory handling"

    local temp_dir="/tmp/test-empty-plugins"
    mkdir -p "$temp_dir"

    local result
    result=$(discover_installed_plugins "$temp_dir" || echo "")

    if [[ -z "$result" ]]; then
        pass "Empty directory handled correctly"
    else
        fail "Empty directory should return empty result"
    fi

    rm -rf "$temp_dir"
}

# Test 7: Performance test (should be fast)
test_performance() {
    log "Test 7: Performance test"

    local plugins_root="${HOOK_ROOT%/plugins/hooks}/plugins"
    local start_time
    start_time=$(date +%s%3N)

    discover_installed_plugins "$plugins_root" > /dev/null

    local end_time
    end_time=$(date +%s%3N)
    local duration=$((end_time - start_time))

    if [[ "$duration" -lt 1000 ]]; then
        pass "Performance OK (${duration}ms)"
    else
        fail "Performance slow (${duration}ms, expected <1000ms)"
    fi
}

# Run all tests
main() {
    log "Running plugin discovery tests..."

    test_discover_plugins
    test_discover_skills
    test_output_format
    test_skill_file_exists
    test_multiple_plugins
    test_empty_directory
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
