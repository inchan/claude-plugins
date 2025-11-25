#!/usr/bin/env bash
# test-metadata-parser.sh - Test metadata parsing functions
set -euo pipefail

# Setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_ROOT="$(dirname "$SCRIPT_DIR")"
LIB_DIR="$HOOK_ROOT/lib"
LOG_FILE="/tmp/hook-tests.log"

source "$LIB_DIR/metadata-parser.sh"

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Logging
log() { echo "[$(date +%T)] $*" | tee -a "$LOG_FILE"; }
pass() { log "✓ PASS: $*"; ((TESTS_PASSED++)); }
fail() { log "✗ FAIL: $*"; ((TESTS_FAILED++)); }

# Initialize log
echo "=== Metadata Parser Tests ===" > "$LOG_FILE"
log "Starting metadata parser tests"

# Test 1: Parse YAML frontmatter from SKILL.md
test_parse_yaml_frontmatter() {
    log "Test 1: Parse YAML frontmatter"

    # Create temporary test file
    local temp_file="/tmp/test-skill.md"
    cat > "$temp_file" << 'EOF'
---
name: test-skill
keywords: ["testing", "validation"]
category: tool
priority: high
---

# Test Skill Content
EOF

    local result
    result=$(parse_skill_frontmatter "$temp_file")

    if [[ "$result" =~ "test-skill" && "$result" =~ "testing" ]]; then
        pass "YAML frontmatter parsed correctly"
        log "Result: $result"
    else
        fail "YAML frontmatter parsing failed"
    fi

    rm -f "$temp_file"
}

# Test 2: Parse skill-rules.json
test_parse_skill_rules() {
    log "Test 2: Parse skill-rules.json"

    # Create temporary test file
    local temp_file="/tmp/test-skill-rules.json"
    cat > "$temp_file" << 'EOF'
{
  "skills": {
    "test-skill": {
      "type": "domain",
      "enforcement": "suggest",
      "priority": "high",
      "promptTriggers": {
        "keywords": ["test", "validate"],
        "intentPatterns": ["^test.*", ".*validation.*"]
      }
    }
  }
}
EOF

    local result
    result=$(parse_skill_rules "$temp_file" "test-skill")

    if [[ "$result" =~ "test" && "$result" =~ "high" ]]; then
        pass "skill-rules.json parsed correctly"
        log "Result: $result"
    else
        fail "skill-rules.json parsing failed"
    fi

    rm -f "$temp_file"
}

# Test 3: Aggregate skill metadata (pipe-separated output)
test_aggregate_metadata() {
    log "Test 3: Aggregate skill metadata"

    # Create temporary files
    local temp_skill="/tmp/test-skill.md"
    local temp_rules="/tmp/test-skill-rules.json"

    cat > "$temp_skill" << 'EOF'
---
name: test-skill
keywords: ["testing"]
category: tool
---
# Test
EOF

    cat > "$temp_rules" << 'EOF'
{
  "skills": {
    "test-skill": {
      "type": "domain",
      "enforcement": "suggest",
      "priority": "high",
      "promptTriggers": {
        "keywords": ["test"],
        "intentPatterns": ["^test.*"]
      }
    }
  }
}
EOF

    local result
    result=$(aggregate_skill_metadata "test-plugin" "test-skill" "$temp_skill" "$temp_rules")

    # Check pipe-separated format
    local pipe_count
    pipe_count=$(echo "$result" | tr -cd '|' | wc -c | tr -d ' ')

    if [[ "$pipe_count" -ge 5 ]]; then
        pass "Metadata aggregated with correct format"
        log "Result: $result"
    else
        fail "Metadata aggregation format incorrect (got $pipe_count pipes)"
    fi

    rm -f "$temp_skill" "$temp_rules"
}

# Test 4: Handle missing YAML frontmatter
test_missing_frontmatter() {
    log "Test 4: Handle missing frontmatter"

    local temp_file="/tmp/test-no-frontmatter.md"
    cat > "$temp_file" << 'EOF'
# Test Skill Without Frontmatter

This is a skill without YAML frontmatter.
EOF

    local result
    result=$(parse_skill_frontmatter "$temp_file" || echo "EMPTY")

    if [[ "$result" == "EMPTY" || -z "$result" ]]; then
        pass "Missing frontmatter handled correctly"
    else
        fail "Should handle missing frontmatter gracefully"
    fi

    rm -f "$temp_file"
}

# Test 5: Handle malformed JSON
test_malformed_json() {
    log "Test 5: Handle malformed JSON"

    local temp_file="/tmp/test-malformed.json"
    cat > "$temp_file" << 'EOF'
{
  "skills": {
    "test-skill": {
      "type": "domain",
      "enforcement": "suggest"
      # missing comma
    }
  }
}
EOF

    local result
    result=$(parse_skill_rules "$temp_file" "test-skill" 2>&1 || echo "ERROR")

    if [[ "$result" =~ "ERROR" ]]; then
        pass "Malformed JSON handled with error"
    else
        fail "Should error on malformed JSON"
    fi

    rm -f "$temp_file"
}

# Test 6: Extract keywords from combined sources
test_keyword_extraction() {
    log "Test 6: Keyword extraction"

    local temp_skill="/tmp/test-skill.md"
    local temp_rules="/tmp/test-skill-rules.json"

    cat > "$temp_skill" << 'EOF'
---
name: test-skill
keywords: ["frontend", "react"]
---
EOF

    cat > "$temp_rules" << 'EOF'
{
  "skills": {
    "test-skill": {
      "promptTriggers": {
        "keywords": ["typescript", "component"],
        "intentPatterns": []
      }
    }
  }
}
EOF

    local result
    result=$(aggregate_skill_metadata "test-plugin" "test-skill" "$temp_skill" "$temp_rules")

    # Should contain keywords from both sources
    if [[ "$result" =~ "frontend" && "$result" =~ "typescript" ]]; then
        pass "Keywords extracted from both sources"
    else
        fail "Keyword extraction incomplete"
    fi

    rm -f "$temp_skill" "$temp_rules"
}

# Test 7: Performance test
test_performance() {
    log "Test 7: Performance test"

    local temp_skill="/tmp/test-skill.md"
    local temp_rules="/tmp/test-skill-rules.json"

    cat > "$temp_skill" << 'EOF'
---
name: test-skill
keywords: ["test"]
category: tool
---
# Test
EOF

    cat > "$temp_rules" << 'EOF'
{
  "skills": {
    "test-skill": {
      "type": "domain",
      "priority": "high",
      "promptTriggers": {
        "keywords": ["test"],
        "intentPatterns": []
      }
    }
  }
}
EOF

    local start_time
    start_time=$(date +%s%3N)

    for i in {1..100}; do
        aggregate_skill_metadata "test-plugin" "test-skill" "$temp_skill" "$temp_rules" > /dev/null
    done

    local end_time
    end_time=$(date +%s%3N)
    local duration=$((end_time - start_time))
    local avg=$((duration / 100))

    if [[ "$avg" -lt 10 ]]; then
        pass "Performance OK (${avg}ms avg per parse)"
    else
        fail "Performance slow (${avg}ms avg, expected <10ms)"
    fi

    rm -f "$temp_skill" "$temp_rules"
}

# Test 8: Output format validation
test_output_format() {
    log "Test 8: Output format validation"

    local temp_skill="/tmp/test-skill.md"
    local temp_rules="/tmp/test-skill-rules.json"

    cat > "$temp_skill" << 'EOF'
---
name: test-skill
keywords: ["test"]
---
EOF

    cat > "$temp_rules" << 'EOF'
{
  "skills": {
    "test-skill": {
      "type": "domain",
      "priority": "high",
      "promptTriggers": {
        "keywords": ["test"],
        "intentPatterns": []
      }
    }
  }
}
EOF

    local result
    result=$(aggregate_skill_metadata "test-plugin" "test-skill" "$temp_skill" "$temp_rules")

    # Expected format: plugin|skill|keywords|priority|enforcement|type
    IFS='|' read -ra fields <<< "$result"
    local field_count=${#fields[@]}

    if [[ "$field_count" -ge 6 ]]; then
        pass "Output format has required fields ($field_count fields)"
        log "Fields: ${fields[*]}"
    else
        fail "Output format incorrect ($field_count fields, expected ≥6)"
    fi

    rm -f "$temp_skill" "$temp_rules"
}

# Run all tests
main() {
    log "Running metadata parser tests..."

    test_parse_yaml_frontmatter
    test_parse_skill_rules
    test_aggregate_metadata
    test_missing_frontmatter
    test_malformed_json
    test_keyword_extraction
    test_performance
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
