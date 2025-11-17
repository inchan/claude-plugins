#!/bin/bash

# Hook Validator - Validates Claude Code hook scripts
#
# Usage:
#   validate_hook.sh <hook-script-path>
#
# Example:
#   validate_hook.sh ~/.claude/hooks/my-hook.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

HOOK_FILE="$1"
ERRORS=0
WARNINGS=0

if [ -z "$HOOK_FILE" ]; then
  echo "Usage: validate_hook.sh <hook-script-path>"
  echo ""
  echo "Example:"
  echo "  validate_hook.sh ~/.claude/hooks/my-hook.sh"
  exit 1
fi

echo "🔍 Validating hook: $HOOK_FILE"
echo ""

# 1. Check if file exists
if [ ! -f "$HOOK_FILE" ]; then
  echo -e "${RED}❌ Error: File does not exist${NC}"
  exit 1
fi

# 2. Check if file is executable
if [ ! -x "$HOOK_FILE" ]; then
  echo -e "${RED}❌ Error: File is not executable${NC}"
  echo "   Run: chmod +x $HOOK_FILE"
  ((ERRORS++))
else
  echo -e "${GREEN}✅ File is executable${NC}"
fi

# 3. Check shebang
FIRST_LINE=$(head -n 1 "$HOOK_FILE")
if [[ ! "$FIRST_LINE" =~ ^#! ]]; then
  echo -e "${RED}❌ Error: Missing shebang (#!/bin/bash or #!/usr/bin/env bash)${NC}"
  ((ERRORS++))
elif [[ "$FIRST_LINE" =~ (bash|sh) ]]; then
  echo -e "${GREEN}✅ Valid shebang found${NC}"
else
  echo -e "${YELLOW}⚠️  Warning: Non-bash shebang detected${NC}"
  ((WARNINGS++))
fi

# 4. Check for set -e (error handling)
if ! grep -q "set -e" "$HOOK_FILE"; then
  echo -e "${YELLOW}⚠️  Warning: 'set -e' not found (recommended for error handling)${NC}"
  ((WARNINGS++))
else
  echo -e "${GREEN}✅ Error handling enabled (set -e)${NC}"
fi

# 5. Check for JSON input reading
if ! grep -q "INPUT.*cat" "$HOOK_FILE"; then
  echo -e "${YELLOW}⚠️  Warning: Standard input reading pattern not found${NC}"
  echo "   Expected: INPUT=\$(cat)"
  ((WARNINGS++))
else
  echo -e "${GREEN}✅ JSON input reading pattern found${NC}"
fi

# 6. Check for jq usage
if grep -q "jq" "$HOOK_FILE"; then
  # Check if jq is installed
  if ! command -v jq &> /dev/null; then
    echo -e "${RED}❌ Error: Script uses jq but it's not installed${NC}"
    echo "   Install: brew install jq (macOS) or apt-get install jq (Linux)"
    ((ERRORS++))
  else
    echo -e "${GREEN}✅ jq usage detected and jq is installed${NC}"
  fi
fi

# 7. Security checks
echo ""
echo "🔒 Security checks:"

# Check for hardcoded passwords/tokens
if grep -iE "(password|token|secret|api_key|apikey).*=.*['\"][^'\"]+['\"]" "$HOOK_FILE" | grep -v "^#"; then
  echo -e "${RED}❌ Security: Potential hardcoded credentials detected${NC}"
  ((ERRORS++))
else
  echo -e "${GREEN}✅ No hardcoded credentials found${NC}"
fi

# Check for dangerous commands
DANGEROUS_CMDS=("rm -rf /" "chmod 777" "eval" "$(curl" "wget.*|.*sh")
for cmd in "${DANGEROUS_CMDS[@]}"; do
  if grep -q "$cmd" "$HOOK_FILE" | grep -v "^#"; then
    echo -e "${YELLOW}⚠️  Warning: Potentially dangerous command found: $cmd${NC}"
    ((WARNINGS++))
  fi
done

# Check for unquoted variables
if grep -E '\$[A-Z_]+[^"' "$HOOK_FILE" | grep -v "^#" | grep -v "jq" > /dev/null 2>&1; then
  echo -e "${YELLOW}⚠️  Warning: Unquoted variables detected (may cause issues with spaces)${NC}"
  ((WARNINGS++))
fi

# 8. Syntax check (if bash)
if [[ "$FIRST_LINE" =~ bash ]]; then
  echo ""
  echo "🔧 Syntax check:"
  if bash -n "$HOOK_FILE" 2>/dev/null; then
    echo -e "${GREEN}✅ No syntax errors found${NC}"
  else
    echo -e "${RED}❌ Syntax errors detected:${NC}"
    bash -n "$HOOK_FILE"
    ((ERRORS++))
  fi
fi

# 9. Check for proper exit codes
if ! grep -q "exit 0" "$HOOK_FILE"; then
  echo -e "${YELLOW}⚠️  Warning: No explicit 'exit 0' found${NC}"
  ((WARNINGS++))
fi

# 10. Check for infinite loop prevention (for Stop hooks)
if grep -q "stop_hook_active" "$HOOK_FILE"; then
  echo -e "${GREEN}✅ Infinite loop prevention found${NC}"
else
  if [[ "$HOOK_FILE" == *"stop"* ]] || [[ "$HOOK_FILE" == *"Stop"* ]]; then
    echo -e "${YELLOW}⚠️  Warning: Stop hook without infinite loop prevention${NC}"
    echo "   Consider checking for stop_hook_active flag"
    ((WARNINGS++))
  fi
fi

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Validation Summary:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
  echo -e "${GREEN}🎉 Perfect! No errors or warnings found.${NC}"
  echo ""
  echo "Next steps:"
  echo "1. Test the hook: scripts/test_hook.sh $HOOK_FILE test-input.json"
  echo "2. Register in Claude Code settings using /hooks command"
  exit 0
elif [ $ERRORS -eq 0 ]; then
  echo -e "${YELLOW}⚠️  $WARNINGS warning(s) found (hook may still work)${NC}"
  echo ""
  echo "Consider addressing the warnings above."
  echo ""
  echo "Next steps:"
  echo "1. Test the hook: scripts/test_hook.sh $HOOK_FILE test-input.json"
  echo "2. Register in Claude Code settings using /hooks command"
  exit 0
else
  echo -e "${RED}❌ $ERRORS error(s) and $WARNINGS warning(s) found${NC}"
  echo ""
  echo "Please fix the errors before using this hook."
  exit 1
fi
