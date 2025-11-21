#!/bin/bash
# Integration test suite for multi-plugin architecture
#
# Tests:
# 1. Plugin JSON validity
# 2. skill-rules.json structure
# 3. Hook aggregation logic
# 4. Skill file existence
# 5. Marketplace JSON validity
# 6. Cross-plugin independence

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

TESTS_PASSED=0
TESTS_FAILED=0
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo -e "${BLUE}=== Multi-Plugin Integration Tests ===${NC}\n"
echo -e "Repository: ${REPO_ROOT}\n"

# Helper functions
pass_test() {
    echo -e "${GREEN}✓${NC} $1"
    ((TESTS_PASSED++))
}

fail_test() {
    echo -e "${RED}✗${NC} $1"
    echo -e "  ${RED}Error:${NC} $2"
    ((TESTS_FAILED++))
}

# Test 1: Validate all plugin.json files
echo -e "${YELLOW}Test Suite 1: Plugin JSON Validation${NC}"
for plugin_dir in "${REPO_ROOT}/plugins/"*/; do
    plugin_name=$(basename "$plugin_dir")
    plugin_json="${plugin_dir}.claude-plugin/plugin.json"

    if [[ -f "$plugin_json" ]]; then
        if node -e "JSON.parse(require('fs').readFileSync('${plugin_json}'))" 2>/dev/null; then
            pass_test "Plugin JSON valid: $plugin_name"
        else
            fail_test "Plugin JSON invalid: $plugin_name" "JSON parse error"
        fi
    else
        fail_test "Plugin JSON missing: $plugin_name" "File not found: $plugin_json"
    fi
done
echo ""

# Test 2: Validate all skill-rules.json files
echo -e "${YELLOW}Test Suite 2: Skill Rules Validation${NC}"
for rules_file in "${REPO_ROOT}/plugins/"*/skills/skill-rules.json; do
    if [[ -f "$rules_file" ]]; then
        plugin_name=$(basename "$(dirname "$(dirname "$rules_file")")")

        if node -e "JSON.parse(require('fs').readFileSync('${rules_file}'))" 2>/dev/null; then
            # Check structure
            if node -e "
                const rules = JSON.parse(require('fs').readFileSync('${rules_file}'));
                if (!rules.skills || typeof rules.skills !== 'object') {
                    process.exit(1);
                }
            " 2>/dev/null; then
                pass_test "Skill rules valid: $plugin_name"
            else
                fail_test "Skill rules structure invalid: $plugin_name" "Missing or invalid 'skills' object"
            fi
        else
            fail_test "Skill rules invalid JSON: $plugin_name" "JSON parse error"
        fi
    fi
done
echo ""

# Test 3: Verify skill file existence
echo -e "${YELLOW}Test Suite 3: Skill File Existence${NC}"
for rules_file in "${REPO_ROOT}/plugins/"*/skills/skill-rules.json; do
    if [[ -f "$rules_file" ]]; then
        plugin_name=$(basename "$(dirname "$(dirname "$rules_file")")")
        skills_dir=$(dirname "$rules_file")

        # Extract skill names from skill-rules.json
        skill_names=$(node -e "
            const rules = JSON.parse(require('fs').readFileSync('${rules_file}'));
            console.log(Object.keys(rules.skills).join('\n'));
        " 2>/dev/null)

        while IFS= read -r skill_name; do
            [[ -z "$skill_name" ]] && continue

            skill_file="${skills_dir}/${skill_name}/SKILL.md"
            if [[ -f "$skill_file" ]]; then
                pass_test "Skill file exists: ${plugin_name}:${skill_name}"
            else
                fail_test "Skill file missing: ${plugin_name}:${skill_name}" "Expected: $skill_file"
            fi
        done <<< "$skill_names"
    fi
done
echo ""

# Test 4: Validate marketplace.json
echo -e "${YELLOW}Test Suite 4: Marketplace JSON Validation${NC}"
marketplace_json="${REPO_ROOT}/.claude-plugin/marketplace.json"

if [[ -f "$marketplace_json" ]]; then
    if node -e "JSON.parse(require('fs').readFileSync('${marketplace_json}'))" 2>/dev/null; then
        pass_test "Marketplace JSON valid"

        # Check plugins array
        plugin_count=$(node -e "
            const mp = JSON.parse(require('fs').readFileSync('${marketplace_json}'));
            console.log(mp.plugins ? mp.plugins.length : 0);
        " 2>/dev/null)

        if [[ $plugin_count -gt 0 ]]; then
            pass_test "Marketplace contains $plugin_count plugins"
        else
            fail_test "Marketplace plugins array empty or missing" "Expected at least 1 plugin"
        fi
    else
        fail_test "Marketplace JSON invalid" "JSON parse error"
    fi
else
    fail_test "Marketplace JSON missing" "File not found: $marketplace_json"
fi
echo ""

# Test 5: Test hook aggregation logic
echo -e "${YELLOW}Test Suite 5: Hook Aggregation Logic${NC}"
hook_script="${REPO_ROOT}/hooks/skill-activation-hook.sh"

if [[ -f "$hook_script" ]]; then
    pass_test "Hook script exists"

    # Check for multi-plugin support patterns
    if grep -q "plugins/\*/" "$hook_script"; then
        pass_test "Hook has multi-plugin directory scanning"
    else
        fail_test "Hook missing multi-plugin support" "No 'plugins/*/' pattern found"
    fi

    if grep -q "plugin_name=" "$hook_script"; then
        pass_test "Hook extracts plugin names"
    else
        fail_test "Hook missing plugin name extraction" "No 'plugin_name=' found"
    fi

    # Test execution (dry run)
    if echo "test prompt" | bash "$hook_script" >/dev/null 2>&1; then
        pass_test "Hook executes without errors"
    else
        fail_test "Hook execution failed" "Script returned non-zero exit code"
    fi
else
    fail_test "Hook script missing" "File not found: $hook_script"
fi
echo ""

# Test 6: Cross-plugin independence
echo -e "${YELLOW}Test Suite 6: Cross-Plugin Independence${NC}"
for plugin_dir in "${REPO_ROOT}/plugins/"*/; do
    plugin_name=$(basename "$plugin_dir")

    # Check for Skill() calls referencing other plugins' skills
    if grep -r "Skill(\"" "${plugin_dir}skills/" 2>/dev/null | grep -v "^Binary" | grep -v "// Example:" > /dev/null; then
        # Extract calls and check if they reference external plugins
        external_calls=$(grep -rh "Skill(\"" "${plugin_dir}skills/" 2>/dev/null | \
                        grep -v "^Binary" | \
                        grep -v "// Example:" | \
                        sed -n 's/.*Skill("\([^"]*\)".*/\1/p')

        has_external=false
        while IFS= read -r call; do
            [[ -z "$call" ]] && continue
            if [[ ! -f "${plugin_dir}skills/${call}/SKILL.md" ]]; then
                has_external=true
                break
            fi
        done <<< "$external_calls"

        if $has_external; then
            fail_test "Plugin has external dependencies: $plugin_name" "Found Skill() calls to other plugins"
        else
            pass_test "Plugin is independent: $plugin_name"
        fi
    else
        pass_test "Plugin is independent: $plugin_name (no Skill calls)"
    fi
done
echo ""

# Test 7: Version consistency
echo -e "${YELLOW}Test Suite 7: Version Consistency${NC}"
marketplace_version=$(node -e "
    const mp = JSON.parse(require('fs').readFileSync('${marketplace_json}'));
    console.log(mp.version || 'unknown');
" 2>/dev/null)

echo -e "Marketplace version: ${BLUE}${marketplace_version}${NC}"

for plugin_dir in "${REPO_ROOT}/plugins/"*/; do
    plugin_name=$(basename "$plugin_dir")
    plugin_json="${plugin_dir}.claude-plugin/plugin.json"

    if [[ -f "$plugin_json" ]]; then
        plugin_version=$(node -e "
            const p = JSON.parse(require('fs').readFileSync('${plugin_json}'));
            console.log(p.version || 'unknown');
        " 2>/dev/null)

        if [[ "$plugin_version" == "$marketplace_version" ]]; then
            pass_test "Version matches: $plugin_name ($plugin_version)"
        else
            fail_test "Version mismatch: $plugin_name" "Plugin: $plugin_version, Marketplace: $marketplace_version"
        fi
    fi
done
echo ""

# Test 8: README documentation
echo -e "${YELLOW}Test Suite 8: Documentation Completeness${NC}"
for plugin_dir in "${REPO_ROOT}/plugins/"*/; do
    plugin_name=$(basename "$plugin_dir")
    readme="${plugin_dir}README.md"

    if [[ -f "$readme" ]]; then
        pass_test "README exists: $plugin_name"
    else
        fail_test "README missing: $plugin_name" "Expected: $readme"
    fi
done
echo ""

# Summary
echo -e "${BLUE}=== Test Summary ===${NC}"
TOTAL_TESTS=$((TESTS_PASSED + TESTS_FAILED))
echo -e "Total tests: ${TOTAL_TESTS}"
echo -e "${GREEN}Passed: ${TESTS_PASSED}${NC}"
echo -e "${RED}Failed: ${TESTS_FAILED}${NC}"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    exit 1
fi
