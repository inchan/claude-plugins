#!/bin/bash
# Test Runner: Execute All Tests
# Runs all test scripts and generates summary report
#
# v1.0.0

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test results
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
FAILED_TESTS=()

print_header() {
    echo ""
    echo "========================================================"
    echo "$1"
    echo "========================================================"
}

run_test_script() {
    local script="$1"
    local name=$(basename "$script" .sh)

    echo ""
    echo -e "${BLUE}▶ Running: $name${NC}"
    echo "--------------------------------------------------------"

    ((TESTS_RUN++))

    if bash "$script"; then
        echo -e "${GREEN}✓ $name PASSED${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ $name FAILED${NC}"
        ((TESTS_FAILED++))
        FAILED_TESTS+=("$name")
        return 1
    fi
}

# Main execution
main() {
    print_header "Skill Activation Hook Test Suite"
    echo "Running all tests..."
    echo ""
    echo "Test Suite:"
    echo "  1. test-global-discovery.sh      - Plugin & skill discovery"
    echo "  2. test-yaml-parsing.sh          - YAML frontmatter parsing"
    echo "  3. test-synonym-expansion.sh     - Synonym dictionary expansion"
    echo "  4. test-tfidf-ranking.sh         - TF-IDF skill ranking"
    echo "  5. test-semantic-matching.sh     - Semantic similarity matching"
    echo "  6. benchmark-performance.sh      - Performance benchmarks"

    # Make all scripts executable
    chmod +x "$SCRIPT_DIR"/*.sh

    # Run each test
    run_test_script "$SCRIPT_DIR/test-global-discovery.sh" || true
    run_test_script "$SCRIPT_DIR/test-yaml-parsing.sh" || true
    run_test_script "$SCRIPT_DIR/test-synonym-expansion.sh" || true
    run_test_script "$SCRIPT_DIR/test-tfidf-ranking.sh" || true
    run_test_script "$SCRIPT_DIR/test-semantic-matching.sh" || true
    run_test_script "$SCRIPT_DIR/benchmark-performance.sh" || true

    # Print summary
    print_header "Test Suite Summary"

    echo ""
    echo "  Total Tests:  $TESTS_RUN"
    echo -e "  Passed:       ${GREEN}$TESTS_PASSED${NC}"
    echo -e "  Failed:       ${RED}$TESTS_FAILED${NC}"

    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo ""
        echo -e "${RED}Failed Tests:${NC}"
        for test in "${FAILED_TESTS[@]}"; do
            echo "  - $test"
        done
        echo ""
        echo -e "${RED}✗ TEST SUITE FAILED${NC}"
        exit 1
    else
        echo ""
        echo -e "${GREEN}✓ ALL TESTS PASSED${NC}"
        exit 0
    fi
}

# Run tests
main
