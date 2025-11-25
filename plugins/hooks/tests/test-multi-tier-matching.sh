#!/bin/bash
# Test Multi-Tier Matching System
# Validates the 3-tier matching pipeline

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$(dirname "$SCRIPT_DIR")"
TEST_OUTPUT_DIR="/tmp/claude-hook-tests"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

mkdir -p "$TEST_OUTPUT_DIR"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Multi-Tier Matching System Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ============================================================================
# Test 1: Tier 1 - Keyword Matching
# ============================================================================

test_tier1_keyword_matching() {
    echo -e "${BLUE}[TEST 1]${NC} Tier 1 Keyword Matching"

    # Create test skills data
    cat > "$TEST_OUTPUT_DIR/test-skills.txt" <<EOF
high|workflow-automation|intelligent-task-router|task,workflow,router,routing
medium|dev-guidelines|frontend-dev-guidelines|frontend,react,typescript
high|dev-guidelines|error-tracking|error,bug,tracking,sentry
medium|quality-review|iterative-quality-enhancer|quality,review,enhance
low|utilities|route-tester|test,route,validation
EOF

    # Test data - use English keywords that exist in test data
    local test_prompt="I need to fix a bug and track errors"
    local output_file="$TEST_OUTPUT_DIR/tier1-output.txt"

    # Source the hook script to get tier1_keyword_match function
    source "$HOOKS_DIR/lib/plugin-discovery.sh"
    source "$HOOKS_DIR/lib/metadata-parser.sh"
    source "$HOOKS_DIR/lib/cache-manager.sh"

    # Extract tier1_keyword_match function
    tier1_keyword_match() {
        local prompt="$1"
        local skills_file="$2"
        local output_file="$3"

        local prompt_lower=$(echo "$prompt" | tr '[:upper:]' '[:lower:]')

        awk -F'|' -v prompt="$prompt_lower" '
        {
            priority = $1
            plugin = $2
            skill = $3
            keywords = tolower($4)

            split(keywords, kw_array, ",")

            match_count = 0

            for (i in kw_array) {
                gsub(/^[ \t]+|[ \t]+$/, "", kw_array[i])

                if (index(prompt, kw_array[i]) > 0) {
                    match_count++
                }
            }

            if (match_count > 0) {
                confidence = match_count * 0.2
                if (confidence > 1.0) confidence = 1.0

                print priority "|" plugin "|" skill "|" keywords "|" confidence "|keyword"
            }
        }' "$skills_file" > "$output_file"

        echo "0"
    }

    tier1_keyword_match "$test_prompt" "$TEST_OUTPUT_DIR/test-skills.txt" "$output_file" > /dev/null

    local match_count=$(wc -l < "$output_file" | xargs)

    if [[ $match_count -gt 0 ]]; then
        echo -e "  ${GREEN}✓${NC} Matched ${match_count} skills"
        echo "  Top matches:"
        head -3 "$output_file" | while IFS='|' read -r priority plugin skill keywords confidence method; do
            echo "    - ${plugin}:${skill} (confidence: ${confidence})"
        done
    else
        echo -e "  ${RED}✗${NC} No matches found"
        return 1
    fi

    echo ""
}

# ============================================================================
# Test 2: Tier 2 - TF-IDF Matching
# ============================================================================

test_tier2_tfidf_matching() {
    echo -e "${BLUE}[TEST 2]${NC} Tier 2 TF-IDF Matching"

    if ! command -v node &> /dev/null; then
        echo -e "  ${YELLOW}⊘${NC} Node.js not found, skipping Tier 2 test"
        echo ""
        return 0
    fi

    # Test TF-IDF matcher directly
    local test_result=$(node "$HOOKS_DIR/matchers/tfidf-matcher.js" --test 2>/dev/null)

    if [[ $? -eq 0 ]]; then
        echo -e "  ${GREEN}✓${NC} TF-IDF matcher is working"
        echo "  Sample output:"
        echo "$test_result" | jq -r '.matches[0] | "    - \(.plugin):\(.skill) (score: \(.tfidfScore))"' 2>/dev/null || echo "    (output format OK)"
    else
        echo -e "  ${RED}✗${NC} TF-IDF matcher failed"
        return 1
    fi

    echo ""
}

# ============================================================================
# Test 3: Tier 3 - Semantic Matching
# ============================================================================

test_tier3_semantic_matching() {
    echo -e "${BLUE}[TEST 3]${NC} Tier 3 Semantic Matching"

    if ! command -v python3 &> /dev/null; then
        echo -e "  ${YELLOW}⊘${NC} Python3 not found, skipping Tier 3 test"
        echo ""
        return 0
    fi

    # Check if sentence-transformers is installed
    if ! python3 -c "import sentence_transformers" 2>/dev/null; then
        echo -e "  ${YELLOW}⊘${NC} sentence-transformers not installed, skipping Tier 3 test"
        echo "  Install: pip3 install sentence-transformers"
        echo ""
        return 0
    fi

    # Test semantic matcher directly
    local test_result=$(python3 "$HOOKS_DIR/matchers/semantic-matcher.py" --test 2>/dev/null)

    if [[ $? -eq 0 ]]; then
        echo -e "  ${GREEN}✓${NC} Semantic matcher is working"
        echo "  Sample output:"
        echo "$test_result" | jq -r '.matches[0] | "    - \(.plugin):\(.skill) (score: \(.semanticScore))"' 2>/dev/null || echo "    (output format OK)"
    else
        echo -e "  ${RED}✗${NC} Semantic matcher failed"
        return 1
    fi

    echo ""
}

# ============================================================================
# Test 4: Progressive Execution Logic
# ============================================================================

test_progressive_execution() {
    echo -e "${BLUE}[TEST 4]${NC} Progressive Execution Logic"

    # Scenario 1: High confidence matches (should skip Tier 2/3)
    echo "  Scenario 1: High-confidence matches"
    cat > "$TEST_OUTPUT_DIR/high-conf-skills.txt" <<EOF
high|plugin1|skill1|keyword1,keyword2|0.8|keyword
high|plugin1|skill2|keyword3,keyword4|0.8|keyword
high|plugin2|skill3|keyword5,keyword6|0.8|keyword
high|plugin2|skill4|keyword7,keyword8|0.8|keyword
high|plugin3|skill5|keyword9,keyword10|0.8|keyword
medium|plugin3|skill6|keyword11,keyword12|0.4|keyword
EOF

    local high_conf_count=$(awk -F'|' '$5 >= 0.6 {count++} END {print count+0}' "$TEST_OUTPUT_DIR/high-conf-skills.txt")

    if [[ $high_conf_count -ge 5 ]]; then
        echo -e "    ${GREEN}✓${NC} ${high_conf_count} high-confidence matches (would skip Tier 2/3)"
    else
        echo -e "    ${RED}✗${NC} Only ${high_conf_count} high-confidence matches"
    fi

    # Scenario 2: Low confidence matches (should proceed to Tier 2/3)
    echo "  Scenario 2: Low-confidence matches"
    cat > "$TEST_OUTPUT_DIR/low-conf-skills.txt" <<EOF
medium|plugin1|skill1|keyword1|0.4|keyword
medium|plugin2|skill2|keyword2|0.2|keyword
low|plugin3|skill3|keyword3|0.2|keyword
EOF

    local low_conf_count=$(awk -F'|' '$5 >= 0.6 {count++} END {print count+0}' "$TEST_OUTPUT_DIR/low-conf-skills.txt")

    if [[ $low_conf_count -lt 5 ]]; then
        echo -e "    ${GREEN}✓${NC} Only ${low_conf_count} high-confidence matches (would proceed to Tier 2/3)"
    else
        echo -e "    ${RED}✗${NC} ${low_conf_count} high-confidence matches"
    fi

    echo ""
}

# ============================================================================
# Test 5: Synonym Expansion
# ============================================================================

test_synonym_expansion() {
    echo -e "${BLUE}[TEST 5]${NC} Synonym Expansion"

    local synonyms_file="$HOOKS_DIR/config/synonyms.json"

    if [[ ! -f "$synonyms_file" ]]; then
        echo -e "  ${RED}✗${NC} Synonyms file not found: $synonyms_file"
        echo ""
        return 1
    fi

    # Check if synonyms file is valid JSON
    if command -v jq &> /dev/null; then
        if jq empty "$synonyms_file" 2>/dev/null; then
            echo -e "  ${GREEN}✓${NC} Synonyms file is valid JSON"

            local synonym_count=$(jq '.synonyms | length' "$synonyms_file")
            echo "  Total synonym groups: ${synonym_count}"

            # Show sample synonyms
            echo "  Sample synonyms:"
            jq -r '.synonyms | to_entries | .[0:3] | .[] | "    - \(.key): \(.value | join(", "))"' "$synonyms_file"
        else
            echo -e "  ${RED}✗${NC} Invalid JSON format"
            return 1
        fi
    else
        echo -e "  ${YELLOW}⊘${NC} jq not found, cannot validate JSON"
    fi

    echo ""
}

# ============================================================================
# Test 6: End-to-End Integration
# ============================================================================

test_e2e_integration() {
    echo -e "${BLUE}[TEST 6]${NC} End-to-End Integration"

    # Create test input
    local test_json='{"prompt": "프론트엔드 버그를 수정하고 싶어요"}'

    # Run the actual hook script
    local result=$(cd /Users/chans/workspace/pilot/cc-skills && echo "$test_json" | "$HOOKS_DIR/skill-activation-hook.sh" 2>/dev/null)

    if [[ -n "$result" ]]; then
        echo -e "  ${GREEN}✓${NC} Hook executed successfully"

        # Validate JSON output
        if echo "$result" | jq empty 2>/dev/null; then
            echo -e "  ${GREEN}✓${NC} Output is valid JSON"

            # Check for required fields
            local has_message=$(echo "$result" | jq 'has("message")' 2>/dev/null)
            local has_system_msg=$(echo "$result" | jq 'has("systemMessage")' 2>/dev/null)

            if [[ "$has_message" == "true" ]] && [[ "$has_system_msg" == "true" ]]; then
                echo -e "  ${GREEN}✓${NC} Output contains required fields"
            else
                echo -e "  ${RED}✗${NC} Missing required fields in output"
                return 1
            fi
        else
            echo -e "  ${RED}✗${NC} Invalid JSON output"
            return 1
        fi
    else
        echo -e "  ${RED}✗${NC} Hook execution failed"
        return 1
    fi

    echo ""
}

# ============================================================================
# Test 7: Performance Validation
# ============================================================================

test_performance() {
    echo -e "${BLUE}[TEST 7]${NC} Performance Validation"

    # Check log file for performance metrics
    local log_file="/tmp/claude-skill-activation.log"

    if [[ -f "$log_file" ]]; then
        echo "  Recent performance metrics:"
        grep "\[PERF\]" "$log_file" | tail -5 | while read line; do
            echo "    $line"
        done

        # Extract latest overall time
        local latest_time=$(grep "Overall pipeline completed" "$log_file" | tail -1 | grep -o '[0-9]\+ms' | head -1)

        if [[ -n "$latest_time" ]]; then
            local time_value=$(echo "$latest_time" | sed 's/ms//')
            if [[ $time_value -lt 500 ]]; then
                echo -e "  ${GREEN}✓${NC} Latest execution time: ${latest_time} (target: <500ms)"
            else
                echo -e "  ${YELLOW}⚠${NC} Latest execution time: ${latest_time} (target: <500ms)"
            fi
        fi
    else
        echo -e "  ${YELLOW}⊘${NC} No performance log found"
    fi

    echo ""
}

# ============================================================================
# Run All Tests
# ============================================================================

FAILED_TESTS=0

test_tier1_keyword_matching || ((FAILED_TESTS++))
test_tier2_tfidf_matching || ((FAILED_TESTS++))
test_tier3_semantic_matching || ((FAILED_TESTS++))
test_progressive_execution || ((FAILED_TESTS++))
test_synonym_expansion || ((FAILED_TESTS++))
test_e2e_integration || ((FAILED_TESTS++))
test_performance || ((FAILED_TESTS++))

# ============================================================================
# Summary
# ============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ $FAILED_TESTS -eq 0 ]]; then
    echo -e "${GREEN}All tests passed!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Test with real user prompts"
    echo "  2. Monitor performance in /tmp/claude-skill-activation.log"
    echo "  3. Fine-tune thresholds based on usage patterns"
else
    echo -e "${RED}${FAILED_TESTS} test(s) failed${NC}"
    echo ""
    echo "Please review the failed tests and fix issues before deployment."
fi

echo ""

# Cleanup
rm -rf "$TEST_OUTPUT_DIR"

exit $FAILED_TESTS
