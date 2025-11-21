#!/usr/bin/env bash
# Compatible with bash 3.2+ (macOS default)

# ============================================================================
# Skill Matching Validation Script
# ============================================================================
# Golden Dataset 기반 스킬 매칭 정확도 검증
# - Precision@3, Recall@3, MRR, Pass Rate 계산
# - MUST/SHOULD/MAY 요구사항 구분
# ============================================================================

set -eo pipefail

# Configuration
TEST_DATA="${TEST_DATA:-tests/skill-matching-golden.json}"
HOOK_SCRIPT="${HOOK_SCRIPT:-hooks/skill-activation-hook.sh}"
VERBOSE="${VERBOSE:-0}"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check dependencies
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is required${NC}"
    echo "Install: brew install jq (macOS) or apt-get install jq (Linux)"
    exit 1
fi

if [[ ! -f "$TEST_DATA" ]]; then
    echo -e "${RED}Error: Test data not found: $TEST_DATA${NC}"
    exit 1
fi

if [[ ! -f "$HOOK_SCRIPT" ]]; then
    echo -e "${RED}Error: Hook script not found: $HOOK_SCRIPT${NC}"
    exit 1
fi

# Initialize metrics
total_tests=0
passed_tests=0
precision_sum=0
recall_sum=0
mrr_sum=0

# Priority tracking (bash 3.2 compatible)
must_count=0
must_passed=0
should_count=0
should_passed=0
may_count=0
may_passed=0

# Results array
declare -a results=()

# ============================================================================
# Helper Functions
# ============================================================================

log_verbose() {
    if [[ "$VERBOSE" -eq 1 ]]; then
        echo -e "${BLUE}[DEBUG]${NC} $*" >&2
    fi
}

# Parse skill output from hook
# Input: hook output (multiline)
# Output: JSON array of skills ["plugin:skill1", "plugin:skill2", ...]
parse_skills() {
    local output="$1"
    echo "$output" | grep -oE "• [a-z0-9_-]+:[a-z0-9_-]+" | sed 's/• //' | jq -R -s -c 'split("\n") | map(select(length > 0))'
}

# Calculate Precision@3
# Args: predicted_skills_json expected_skills_json
calc_precision() {
    local predicted="$1"
    local expected="$2"

    local predicted_count=$(echo "$predicted" | jq 'length')
    if [[ "$predicted_count" -eq 0 ]]; then
        echo "0"
        return
    fi

    local top3=$(echo "$predicted" | jq -c '.[:3]')
    local top3_count=$(echo "$top3" | jq 'length')

    # Handle empty predictions
    if [[ "$top3_count" -eq 0 ]]; then
        echo "0"
        return
    fi

    local intersection=$(jq -n --argjson p "$top3" --argjson e "$expected" '
        ($p | map(select(. as $item | $e | index($item)))) | length
    ')

    # Precision = correct / actual_predicted_count (not hardcoded 3)
    echo "scale=2; $intersection / $top3_count" | bc
}

# Calculate Recall@3
# Args: predicted_skills_json expected_skills_json
calc_recall() {
    local predicted="$1"
    local expected="$2"

    local expected_count=$(echo "$expected" | jq 'length')
    if [[ "$expected_count" -eq 0 ]]; then
        echo "1.00"  # No expected skills = perfect recall
        return
    fi

    local top3=$(echo "$predicted" | jq -c '.[:3]')
    local intersection=$(jq -n --argjson p "$top3" --argjson e "$expected" '
        ($p | map(select(. as $item | $e | index($item)))) | length
    ')

    echo "scale=2; $intersection / $expected_count" | bc
}

# Calculate MRR (Mean Reciprocal Rank)
# Args: predicted_skills_json expected_skills_json
calc_mrr() {
    local predicted="$1"
    local expected="$2"

    local mrr=$(jq -n --argjson p "$predicted" --argjson e "$expected" '
        # Find first matching skill rank
        ($p | to_entries | map(select(.value as $v | $e | index($v))) | .[0] // null) as $first_match |
        if $first_match then
            1 / ($first_match.key + 1)
        else
            0
        end
    ')

    printf "%.2f" "$mrr"
}

# Check if test passes based on priority
# Args: precision recall priority
check_pass() {
    local precision="$1"
    local recall="$2"
    local priority="$3"

    case "$priority" in
        MUST)
            # MUST: Precision >= 0.67 AND Recall >= 0.67
            if (( $(echo "$precision >= 0.67" | bc -l) )) && (( $(echo "$recall >= 0.67" | bc -l) )); then
                echo "1"
            else
                echo "0"
            fi
            ;;
        SHOULD)
            # SHOULD: Precision >= 0.33 OR Recall >= 0.50
            if (( $(echo "$precision >= 0.33" | bc -l) )) || (( $(echo "$recall >= 0.50" | bc -l) )); then
                echo "1"
            else
                echo "0"
            fi
            ;;
        MAY)
            # MAY: Any result is acceptable
            echo "1"
            ;;
        *)
            echo "0"
            ;;
    esac
}

# ============================================================================
# Main Test Execution
# ============================================================================

echo -e "${BLUE}=== Skill Matching Validation ===${NC}"
echo "Test Data: $TEST_DATA"
echo "Hook Script: $HOOK_SCRIPT"
echo ""

# Read test cases
test_cases=$(jq -c '.test_cases[]' "$TEST_DATA")

while IFS= read -r test_case; do
    total_tests=$((total_tests + 1))

    # Parse test case
    test_id=$(echo "$test_case" | jq -r '.id')
    description=$(echo "$test_case" | jq -r '.notes // .category')
    input=$(echo "$test_case" | jq -r '.input')
    expected_skills=$(echo "$test_case" | jq -c '.expected_top3')
    priority=$(echo "$test_case" | jq -r '.priority')

    # Count by priority (bash 3.2 compatible)
    if [[ "$priority" == "MUST" ]]; then
        must_count=$((must_count + 1))
    elif [[ "$priority" == "SHOULD" ]]; then
        should_count=$((should_count + 1))
    elif [[ "$priority" == "MAY" ]]; then
        may_count=$((may_count + 1))
    fi

    log_verbose "Running test: $test_id - $description"
    log_verbose "Input: $input"

    # Execute hook with input
    hook_output=$(echo "$input" | bash "$HOOK_SCRIPT" 2>&1 || true)

    log_verbose "Hook output:"
    log_verbose "$hook_output"

    # Parse predicted skills
    predicted_skills=$(parse_skills "$hook_output")

    log_verbose "Predicted skills: $predicted_skills"
    log_verbose "Expected skills: $expected_skills"

    # Calculate metrics
    precision=$(calc_precision "$predicted_skills" "$expected_skills")
    recall=$(calc_recall "$predicted_skills" "$expected_skills")
    mrr=$(calc_mrr "$predicted_skills" "$expected_skills")

    # Check pass/fail
    pass=$(check_pass "$precision" "$recall" "$priority")

    if [[ "$pass" -eq 1 ]]; then
        passed_tests=$((passed_tests + 1))

        # Track passed by priority (bash 3.2 compatible)
        if [[ "$priority" == "MUST" ]]; then
            must_passed=$((must_passed + 1))
        elif [[ "$priority" == "SHOULD" ]]; then
            should_passed=$((should_passed + 1))
        elif [[ "$priority" == "MAY" ]]; then
            may_passed=$((may_passed + 1))
        fi

        status="${GREEN}✓ PASS${NC}"
    else
        status="${RED}✗ FAIL${NC}"
    fi

    # Accumulate for averages
    precision_sum=$(echo "$precision_sum + $precision" | bc)
    recall_sum=$(echo "$recall_sum + $recall" | bc)
    mrr_sum=$(echo "$mrr_sum + $mrr" | bc)

    # Format result line
    result_line=$(printf "%s [%s] %s (P: %.2f, R: %.2f, MRR: %.2f)" \
        "$test_id" "$priority" "$status" "$precision" "$recall" "$mrr")

    results+=("$result_line")

    # Print immediate result
    echo -e "$result_line"

    # Print predicted vs expected (if failed and verbose)
    if [[ "$pass" -eq 0 ]] && [[ "$VERBOSE" -eq 1 ]]; then
        echo -e "  ${YELLOW}Predicted:${NC} $(echo "$predicted_skills" | jq -r '.[:3] | join(", ")')"
        echo -e "  ${YELLOW}Expected:${NC}  $(echo "$expected_skills" | jq -r 'join(", ")')"
    fi

done <<< "$test_cases"

# ============================================================================
# Summary Report
# ============================================================================

echo ""
echo -e "${BLUE}=== Summary ===${NC}"

# Overall metrics
pass_rate=$(echo "scale=2; 100 * $passed_tests / $total_tests" | bc)
avg_precision=$(echo "scale=2; $precision_sum / $total_tests" | bc)
avg_recall=$(echo "scale=2; $recall_sum / $total_tests" | bc)
avg_mrr=$(echo "scale=2; $mrr_sum / $total_tests" | bc)

echo -e "Pass Rate: ${passed_tests}/${total_tests} (${pass_rate}%)"
echo -e "Avg Precision@3: ${avg_precision}"
echo -e "Avg Recall@3: ${avg_recall}"
echo -e "MRR: ${avg_mrr}"
echo ""

# Priority breakdown (bash 3.2 compatible)
echo -e "${BLUE}=== Priority Breakdown ===${NC}"

if [[ $must_count -gt 0 ]]; then
    must_rate=$(echo "scale=2; 100 * $must_passed / $must_count" | bc)
    echo -e "MUST: ${must_passed}/${must_count} (${must_rate}%)"
fi

if [[ $should_count -gt 0 ]]; then
    should_rate=$(echo "scale=2; 100 * $should_passed / $should_count" | bc)
    echo -e "SHOULD: ${should_passed}/${should_count} (${should_rate}%)"
fi

if [[ $may_count -gt 0 ]]; then
    may_rate=$(echo "scale=2; 100 * $may_passed / $may_count" | bc)
    echo -e "MAY: ${may_passed}/${may_count} (${may_rate}%)"
fi

# Exit code
if [[ "$passed_tests" -eq "$total_tests" ]]; then
    echo ""
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}Some tests failed.${NC}"
    exit 1
fi
