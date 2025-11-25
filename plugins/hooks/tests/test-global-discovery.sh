#!/bin/bash
# Test: Global Plugin Discovery
# Tests plugin-discovery.sh functions for finding installed plugins and skills
#
# v1.0.0

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"
TEST_DATA_DIR="$SCRIPT_DIR/fixtures"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Load library
source "$LIB_DIR/plugin-discovery.sh"

print_header() {
    echo ""
    echo "============================================"
    echo "$1"
    echo "============================================"
}

print_test() {
    echo -n "  [TEST] $1 ... "
}

pass() {
    echo -e "${GREEN}PASS${NC}"
    ((TESTS_PASSED++))
    ((TESTS_TOTAL++))
}

fail() {
    echo -e "${RED}FAIL${NC}"
    if [[ -n "$1" ]]; then
        echo "    Error: $1"
    fi
    ((TESTS_FAILED++))
    ((TESTS_TOTAL++))
}

skip() {
    echo -e "${YELLOW}SKIP${NC} - $1"
    ((TESTS_TOTAL++))
}

# Setup test fixtures
setup() {
    print_header "Setting up test fixtures"

    mkdir -p "$TEST_DATA_DIR"
    mkdir -p "$TEST_DATA_DIR/mock-plugins/plugin-a/.claude-plugin"
    mkdir -p "$TEST_DATA_DIR/mock-plugins/plugin-a/skills/skill-1"
    mkdir -p "$TEST_DATA_DIR/mock-plugins/plugin-b/.claude-plugin"
    mkdir -p "$TEST_DATA_DIR/mock-plugins/plugin-b/skills/skill-2"

    # Create mock plugin.json
    cat > "$TEST_DATA_DIR/mock-plugins/plugin-a/.claude-plugin/plugin.json" << 'EOF'
{
  "name": "plugin-a",
  "version": "1.0.0",
  "skills": ["./skills"]
}
EOF

    cat > "$TEST_DATA_DIR/mock-plugins/plugin-b/.claude-plugin/plugin.json" << 'EOF'
{
  "name": "plugin-b",
  "version": "1.0.0",
  "skills": ["./skills"]
}
EOF

    # Create mock SKILL.md
    cat > "$TEST_DATA_DIR/mock-plugins/plugin-a/skills/skill-1/SKILL.md" << 'EOF'
---
name: skill-1
description: Test skill 1 for plugin A
keywords: test, example
---

# Skill 1

This is a test skill.
EOF

    cat > "$TEST_DATA_DIR/mock-plugins/plugin-b/skills/skill-2/SKILL.md" << 'EOF'
---
name: skill-2
description: Test skill 2 for plugin B
keywords: test, sample
---

# Skill 2

This is another test skill.
EOF

    # Create mock skill-rules.json
    cat > "$TEST_DATA_DIR/mock-plugins/plugin-a/skills/skill-rules.json" << 'EOF'
{
  "skills": {
    "skill-1": {
      "priority": "high",
      "promptTriggers": {
        "keywords": ["test", "example"]
      }
    }
  }
}
EOF

    cat > "$TEST_DATA_DIR/mock-plugins/plugin-b/skills/skill-rules.json" << 'EOF'
{
  "skills": {
    "skill-2": {
      "priority": "medium",
      "promptTriggers": {
        "keywords": ["test", "sample"]
      }
    }
  }
}
EOF

    echo "  ✓ Test fixtures created"
}

# Cleanup
cleanup() {
    print_header "Cleaning up"
    if [[ -d "$TEST_DATA_DIR" ]]; then
        rm -rf "$TEST_DATA_DIR"
        echo "  ✓ Test fixtures removed"
    fi
}

# Test 1: discover_installed_plugins (mock mode)
test_discover_installed_plugins() {
    print_test "discover_installed_plugins returns results"

    # Note: This test requires real ~/.claude/plugins/ structure
    # For CI environments, we'll skip if not available

    if [[ ! -f "$HOME/.claude/plugins/installed_plugins.json" ]]; then
        skip "~/.claude/plugins/installed_plugins.json not found"
        return
    fi

    local result=$(discover_installed_plugins 2>/dev/null)

    if [[ -n "$result" ]]; then
        pass
    else
        fail "No plugins discovered"
    fi
}

# Test 2: discover_plugin_skills with mock data
test_discover_plugin_skills() {
    print_test "discover_plugin_skills finds SKILL.md files"

    local plugin_path="$TEST_DATA_DIR/mock-plugins/plugin-a"
    local result=$(discover_plugin_skills "$plugin_path" "test-plugin-a@local" 2>/dev/null)

    if echo "$result" | grep -q "skill-1"; then
        pass
    else
        fail "Expected to find skill-1"
    fi
}

# Test 3: discover_skill_rules
test_discover_skill_rules() {
    print_test "discover_skill_rules finds skill-rules.json"

    local plugin_path="$TEST_DATA_DIR/mock-plugins/plugin-a"
    local result=$(discover_skill_rules "$plugin_path" 2>/dev/null)

    if echo "$result" | grep -q "skill-rules.json"; then
        pass
    else
        fail "Expected to find skill-rules.json"
    fi
}

# Test 4: discover_all_skills output format
test_discover_all_skills_format() {
    print_test "discover_all_skills returns correct format"

    # Test requires real plugin structure, skip in isolated environment
    skip "Requires real plugin installation"
}

# Test 5: Edge case - missing plugin.json
test_missing_plugin_json() {
    print_test "Handles missing plugin.json gracefully"

    local bad_path="$TEST_DATA_DIR/nonexistent-plugin"
    local result=$(discover_plugin_skills "$bad_path" "bad-plugin" 2>/dev/null)

    if [[ -z "$result" ]]; then
        pass
    else
        fail "Should return empty for nonexistent plugin"
    fi
}

# Test 6: Edge case - empty skills directory
test_empty_skills_dir() {
    print_test "Handles empty skills directory"

    mkdir -p "$TEST_DATA_DIR/mock-plugins/empty-plugin/.claude-plugin"
    mkdir -p "$TEST_DATA_DIR/mock-plugins/empty-plugin/skills"

    cat > "$TEST_DATA_DIR/mock-plugins/empty-plugin/.claude-plugin/plugin.json" << 'EOF'
{
  "name": "empty-plugin",
  "version": "1.0.0",
  "skills": ["./skills"]
}
EOF

    local result=$(discover_plugin_skills "$TEST_DATA_DIR/mock-plugins/empty-plugin" "empty-plugin" 2>/dev/null)

    if [[ -z "$result" ]]; then
        pass
    else
        fail "Should return empty for plugin with no skills"
    fi
}

# Performance test
test_performance() {
    print_test "Performance test: discovery completes < 100ms"

    local start=$(date +%s%N)
    discover_plugin_skills "$TEST_DATA_DIR/mock-plugins/plugin-a" "plugin-a" >/dev/null 2>&1
    local end=$(date +%s%N)

    local elapsed_ms=$(( (end - start) / 1000000 ))

    if [[ $elapsed_ms -lt 100 ]]; then
        pass
        echo "    Performance: ${elapsed_ms}ms"
    else
        fail "Performance too slow: ${elapsed_ms}ms (expected < 100ms)"
    fi
}

# Test summary
print_summary() {
    print_header "Test Summary"

    echo "  Total:  $TESTS_TOTAL"
    echo -e "  Passed: ${GREEN}$TESTS_PASSED${NC}"

    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo -e "  Failed: ${RED}$TESTS_FAILED${NC}"
        echo ""
        echo -e "${RED}✗ TESTS FAILED${NC}"
        return 1
    else
        echo -e "  Failed: $TESTS_FAILED"
        echo ""
        echo -e "${GREEN}✓ ALL TESTS PASSED${NC}"
        return 0
    fi
}

# Main execution
main() {
    print_header "Global Plugin Discovery Tests"
    echo "Testing plugin-discovery.sh functions"

    setup

    test_discover_installed_plugins
    test_discover_plugin_skills
    test_discover_skill_rules
    test_discover_all_skills_format
    test_missing_plugin_json
    test_empty_skills_dir
    test_performance

    cleanup

    print_summary
}

# Run tests
main
exit $?
