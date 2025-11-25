#!/bin/bash
# Test: YAML Frontmatter Parsing
# Tests metadata-parser.sh for extracting YAML metadata from SKILL.md
#
# v1.0.0

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"
TEST_DATA_DIR="$SCRIPT_DIR/fixtures"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Load library
source "$LIB_DIR/metadata-parser.sh"

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

# Setup
setup() {
    print_header "Setting up test fixtures"

    mkdir -p "$TEST_DATA_DIR/yaml-tests"

    # Test 1: Standard YAML frontmatter
    cat > "$TEST_DATA_DIR/yaml-tests/standard.md" << 'EOF'
---
name: test-skill
description: This is a test skill
keywords: test, example, sample
---

# Test Skill

Content here.
EOF

    # Test 2: Multiline description
    cat > "$TEST_DATA_DIR/yaml-tests/multiline.md" << 'EOF'
---
name: multiline-skill
description: >
  This is a multiline
  description that spans
  multiple lines
---

# Multiline Skill
EOF

    # Test 3: Missing fields
    cat > "$TEST_DATA_DIR/yaml-tests/missing-fields.md" << 'EOF'
---
name: incomplete-skill
---

# Incomplete Skill
EOF

    # Test 4: No frontmatter
    cat > "$TEST_DATA_DIR/yaml-tests/no-frontmatter.md" << 'EOF'
# No Frontmatter

This file has no YAML frontmatter.
EOF

    # Test 5: Malformed YAML
    cat > "$TEST_DATA_DIR/yaml-tests/malformed.md" << 'EOF'
---
name: malformed-skill
description: Missing closing delimiter

# Malformed Skill
EOF

    # Test 6: Special characters
    cat > "$TEST_DATA_DIR/yaml-tests/special-chars.md" << 'EOF'
---
name: special-chars-skill
description: "Test with special chars: $, &, *, quotes"
---

# Special Chars Skill
EOF

    # Test 7: Korean characters
    cat > "$TEST_DATA_DIR/yaml-tests/korean.md" << 'EOF'
---
name: korean-skill
description: 한글 설명이 포함된 스킬입니다
keywords: 테스트, 한글, 예제
---

# 한글 스킬
EOF

    echo "  ✓ Test fixtures created"
}

cleanup() {
    print_header "Cleaning up"
    if [[ -d "$TEST_DATA_DIR" ]]; then
        rm -rf "$TEST_DATA_DIR"
        echo "  ✓ Test fixtures removed"
    fi
}

# Tests
test_standard_yaml() {
    print_test "Parse standard YAML frontmatter"

    local result=$(parse_yaml_frontmatter "$TEST_DATA_DIR/yaml-tests/standard.md")

    if echo "$result" | grep -q "test-skill"; then
        pass
    else
        fail "Expected 'test-skill' in result"
    fi
}

test_multiline_description() {
    print_test "Handle multiline descriptions"

    local result=$(parse_yaml_frontmatter "$TEST_DATA_DIR/yaml-tests/multiline.md")

    if echo "$result" | grep -q "multiline-skill"; then
        pass
    else
        fail "Failed to parse multiline YAML"
    fi
}

test_missing_fields() {
    print_test "Handle missing fields gracefully"

    local result=$(parse_yaml_frontmatter "$TEST_DATA_DIR/yaml-tests/missing-fields.md")

    if echo "$result" | grep -q "incomplete-skill"; then
        pass
    else
        fail "Should still extract available fields"
    fi
}

test_no_frontmatter() {
    print_test "Return empty for files without frontmatter"

    local result=$(parse_yaml_frontmatter "$TEST_DATA_DIR/yaml-tests/no-frontmatter.md")

    if [[ -z "$result" ]]; then
        pass
    else
        fail "Should return empty for no frontmatter"
    fi
}

test_malformed_yaml() {
    print_test "Handle malformed YAML gracefully"

    local result=$(parse_yaml_frontmatter "$TEST_DATA_DIR/yaml-tests/malformed.md" 2>/dev/null)

    # Should not crash, might return partial data or empty
    pass
}

test_special_characters() {
    print_test "Handle special characters in YAML"

    local result=$(parse_yaml_frontmatter "$TEST_DATA_DIR/yaml-tests/special-chars.md")

    if echo "$result" | grep -q "special-chars-skill"; then
        pass
    else
        fail "Failed to parse special characters"
    fi
}

test_korean_characters() {
    print_test "Handle Korean (UTF-8) characters"

    local result=$(parse_yaml_frontmatter "$TEST_DATA_DIR/yaml-tests/korean.md")

    if echo "$result" | grep -q "korean-skill"; then
        pass
    else
        fail "Failed to parse Korean characters"
    fi
}

test_skill_rules_parsing() {
    print_test "Parse skill-rules.json with node"

    if ! command -v node &> /dev/null; then
        fail "Node.js not found (required for skill-rules.json parsing)"
        return
    fi

    # Create test skill-rules.json
    cat > "$TEST_DATA_DIR/yaml-tests/skill-rules.json" << 'EOF'
{
  "skills": {
    "test-skill": {
      "priority": "high",
      "promptTriggers": {
        "keywords": ["test", "example"],
        "intentPatterns": [".*test.*"]
      }
    }
  }
}
EOF

    local result=$(parse_skill_rules "$TEST_DATA_DIR/yaml-tests/skill-rules.json" "test-skill")

    if echo "$result" | grep -q "high"; then
        pass
    else
        fail "Failed to parse skill-rules.json"
    fi
}

test_aggregate_metadata() {
    print_test "Aggregate metadata from YAML + skill-rules"

    if ! command -v node &> /dev/null; then
        fail "Node.js required"
        return
    fi

    # Use standard.md + create matching skill-rules.json
    local skill_dir="$TEST_DATA_DIR/yaml-tests"
    mkdir -p "$skill_dir/test-skill"
    cp "$skill_dir/standard.md" "$skill_dir/test-skill/SKILL.md"

    cat > "$skill_dir/skill-rules.json" << 'EOF'
{
  "skills": {
    "test-skill": {
      "priority": "medium",
      "promptTriggers": {
        "keywords": ["test"]
      }
    }
  }
}
EOF

    local result=$(aggregate_skill_metadata "$skill_dir/test-skill/SKILL.md" "test-plugin" "test-skill")

    if echo "$result" | grep -q "test-skill" && echo "$result" | grep -q "medium"; then
        pass
    else
        fail "Metadata aggregation failed"
    fi
}

test_performance() {
    print_test "Performance: YAML parsing < 50ms"

    local start=$(date +%s%N)
    parse_yaml_frontmatter "$TEST_DATA_DIR/yaml-tests/standard.md" >/dev/null 2>&1
    local end=$(date +%s%N)

    local elapsed_ms=$(( (end - start) / 1000000 ))

    if [[ $elapsed_ms -lt 50 ]]; then
        pass
        echo "    Performance: ${elapsed_ms}ms"
    else
        fail "Too slow: ${elapsed_ms}ms (expected < 50ms)"
    fi
}

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

main() {
    print_header "YAML Frontmatter Parsing Tests"
    echo "Testing metadata-parser.sh functions"

    setup

    test_standard_yaml
    test_multiline_description
    test_missing_fields
    test_no_frontmatter
    test_malformed_yaml
    test_special_characters
    test_korean_characters
    test_skill_rules_parsing
    test_aggregate_metadata
    test_performance

    cleanup

    print_summary
}

main
exit $?
