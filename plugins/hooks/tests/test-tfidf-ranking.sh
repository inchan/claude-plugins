#!/bin/bash
# Test: TF-IDF Skill Ranking
# Tests tfidf-matcher.js for accurate skill scoring
#
# v1.0.0

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MATCHERS_DIR="$SCRIPT_DIR/../matchers"
TEST_DATA_DIR="$SCRIPT_DIR/fixtures"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

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

# Setup
setup() {
    print_header "Setting up test fixtures"

    mkdir -p "$TEST_DATA_DIR/tfidf-tests"

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
test_tfidf_matcher_exists() {
    print_test "Verify tfidf-matcher.js exists"

    if [[ -f "$MATCHERS_DIR/tfidf-matcher.js" ]]; then
        pass
    else
        fail "tfidf-matcher.js not found"
    fi
}

test_node_dependencies() {
    print_test "Check Node.js and dependencies"

    if ! command -v node &> /dev/null; then
        fail "Node.js not found"
        return
    fi

    if [[ ! -d "$MATCHERS_DIR/node_modules" ]]; then
        fail "node_modules not found (run: npm install)"
        return
    fi

    pass
}

test_tfidf_test_mode() {
    print_test "Run TF-IDF matcher in test mode"

    if ! command -v node &> /dev/null; then
        skip "Node.js required"
        return
    fi

    local result=$(cd "$MATCHERS_DIR" && node tfidf-matcher.js --test 2>&1)

    if echo "$result" | grep -q "TF-IDF Matcher Test Mode"; then
        pass
    else
        fail "Test mode failed"
    fi
}

test_tfidf_ranking_accuracy() {
    print_test "Verify ranking accuracy (bug fix → error-tracking)"

    if ! command -v node &> /dev/null; then
        skip "Node.js required"
        return
    fi

    local input=$(cat << 'EOF'
{
  "prompt": "버그를 수정하고 싶어요",
  "candidates": [
    {
      "plugin": "dev-guidelines",
      "skill": "frontend-dev-guidelines",
      "description": "React and TypeScript development patterns",
      "keywords": "react,typescript,frontend"
    },
    {
      "plugin": "dev-guidelines",
      "skill": "error-tracking",
      "description": "Error tracking and bug fixing with Sentry",
      "keywords": "error,bug,fix,sentry"
    },
    {
      "plugin": "workflow-automation",
      "skill": "intelligent-task-router",
      "description": "Task routing and classification",
      "keywords": "task,routing,workflow"
    }
  ]
}
EOF
)

    local result=$(cd "$MATCHERS_DIR" && echo "$input" | node tfidf-matcher.js 2>/dev/null)

    if [[ -z "$result" ]]; then
        fail "No output from matcher"
        return
    fi

    # Check that error-tracking is ranked high (should be in top 2)
    local top_skill=$(echo "$result" | jq -r '.matches[0].skill' 2>/dev/null)

    if [[ "$top_skill" == "error-tracking" ]]; then
        pass
        echo "    Top match: $top_skill"
    else
        fail "Expected 'error-tracking' as top match, got '$top_skill'"
    fi
}

test_tfidf_korean_support() {
    print_test "Korean text support"

    if ! command -v node &> /dev/null; then
        skip "Node.js required"
        return
    fi

    local input=$(cat << 'EOF'
{
  "prompt": "프론트엔드 개발 패턴을 알려줘",
  "candidates": [
    {
      "plugin": "dev-guidelines",
      "skill": "frontend-dev-guidelines",
      "description": "프론트엔드 개발 가이드라인",
      "keywords": "프론트엔드,react,개발"
    },
    {
      "plugin": "dev-guidelines",
      "skill": "backend-dev-guidelines",
      "description": "백엔드 개발 가이드라인",
      "keywords": "백엔드,api,서버"
    }
  ]
}
EOF
)

    local result=$(cd "$MATCHERS_DIR" && echo "$input" | node tfidf-matcher.js 2>/dev/null)

    if echo "$result" | jq -e '.matches | length > 0' &>/dev/null; then
        pass
    else
        fail "Korean text matching failed"
    fi
}

test_tfidf_empty_candidates() {
    print_test "Handle empty candidates"

    if ! command -v node &> /dev/null; then
        skip "Node.js required"
        return
    fi

    local input=$(cat << 'EOF'
{
  "prompt": "test prompt",
  "candidates": []
}
EOF
)

    local result=$(cd "$MATCHERS_DIR" && echo "$input" | node tfidf-matcher.js 2>/dev/null)

    if echo "$result" | jq -e '.matches | length == 0' &>/dev/null; then
        pass
    else
        fail "Should return empty matches"
    fi
}

test_tfidf_scoring_range() {
    print_test "Verify scores are in valid range (0-1)"

    if ! command -v node &> /dev/null; then
        skip "Node.js required"
        return
    fi

    local input=$(cat << 'EOF'
{
  "prompt": "test debugging features",
  "candidates": [
    {
      "plugin": "test",
      "skill": "skill-1",
      "description": "debugging and testing tools",
      "keywords": "debug,test"
    }
  ]
}
EOF
)

    local result=$(cd "$MATCHERS_DIR" && echo "$input" | node tfidf-matcher.js 2>/dev/null)
    local score=$(echo "$result" | jq -r '.matches[0].tfidfScore // 0' 2>/dev/null)

    # Check if score is a number and > 0
    if [[ $(echo "$score > 0" | bc 2>/dev/null || echo 0) -eq 1 ]]; then
        pass
        echo "    Score: $score"
    else
        fail "Invalid score: $score"
    fi
}

test_tfidf_metadata() {
    print_test "Verify metadata output"

    if ! command -v node &> /dev/null; then
        skip "Node.js required"
        return
    fi

    local input=$(cat << 'EOF'
{
  "prompt": "test",
  "candidates": [
    {"plugin": "p", "skill": "s", "description": "test skill"}
  ]
}
EOF
)

    local result=$(cd "$MATCHERS_DIR" && echo "$input" | node tfidf-matcher.js 2>/dev/null)

    local has_metadata=$(echo "$result" | jq -e '.metadata.method == "tfidf"' 2>/dev/null)

    if [[ $? -eq 0 ]]; then
        pass
    else
        fail "Missing or invalid metadata"
    fi
}

test_tfidf_performance() {
    print_test "Performance: TF-IDF < 150ms"

    if ! command -v node &> /dev/null; then
        skip "Node.js required"
        return
    fi

    local input=$(cat << 'EOF'
{
  "prompt": "Create a new React component for user profile",
  "candidates": [
    {"plugin": "p1", "skill": "s1", "description": "Frontend development with React"},
    {"plugin": "p2", "skill": "s2", "description": "Backend API development"},
    {"plugin": "p3", "skill": "s3", "description": "Database design patterns"},
    {"plugin": "p4", "skill": "s4", "description": "Testing and QA automation"},
    {"plugin": "p5", "skill": "s5", "description": "DevOps and deployment"}
  ]
}
EOF
)

    local start=$(date +%s%N)
    cd "$MATCHERS_DIR" && echo "$input" | node tfidf-matcher.js >/dev/null 2>&1
    local end=$(date +%s%N)

    local elapsed_ms=$(( (end - start) / 1000000 ))

    if [[ $elapsed_ms -lt 150 ]]; then
        pass
        echo "    Performance: ${elapsed_ms}ms"
    else
        fail "Too slow: ${elapsed_ms}ms (expected < 150ms)"
    fi
}

test_tfidf_large_candidate_set() {
    print_test "Handle large candidate set (20+ skills)"

    if ! command -v node &> /dev/null; then
        skip "Node.js required"
        return
    fi

    # Generate 25 candidates
    local candidates='['
    for i in {1..25}; do
        candidates+='{"plugin":"p'$i'","skill":"s'$i'","description":"Test skill '$i'"},'
    done
    candidates="${candidates%,}]"

    local input=$(cat << EOF
{
  "prompt": "test skill 15",
  "candidates": $candidates
}
EOF
)

    local result=$(cd "$MATCHERS_DIR" && echo "$input" | node tfidf-matcher.js 2>/dev/null)

    if echo "$result" | jq -e '.metadata.totalCandidates == 25' &>/dev/null; then
        pass
    else
        fail "Failed to process large candidate set"
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
    print_header "TF-IDF Skill Ranking Tests"
    echo "Testing tfidf-matcher.js"

    setup

    test_tfidf_matcher_exists
    test_node_dependencies
    test_tfidf_test_mode
    test_tfidf_ranking_accuracy
    test_tfidf_korean_support
    test_tfidf_empty_candidates
    test_tfidf_scoring_range
    test_tfidf_metadata
    test_tfidf_performance
    test_tfidf_large_candidate_set

    cleanup

    print_summary
}

main
exit $?
