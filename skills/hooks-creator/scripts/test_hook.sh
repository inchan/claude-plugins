#!/bin/bash

# Hook Tester - Test Claude Code hooks locally
#
# Usage:
#   test_hook.sh <hook-script> [test-input.json]
#
# Examples:
#   test_hook.sh ~/.claude/hooks/my-hook.sh
#   test_hook.sh ~/.claude/hooks/my-hook.sh test-input.json
#   test_hook.sh ~/.claude/hooks/my-hook.sh - < input.json

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

HOOK_FILE="$1"
INPUT_FILE="$2"

if [ -z "$HOOK_FILE" ]; then
  echo "Usage: test_hook.sh <hook-script> [test-input.json]"
  echo ""
  echo "Examples:"
  echo "  test_hook.sh ~/.claude/hooks/my-hook.sh"
  echo "  test_hook.sh ~/.claude/hooks/my-hook.sh test-input.json"
  echo "  cat test-input.json | test_hook.sh ~/.claude/hooks/my-hook.sh -"
  echo ""
  echo "If no input file is provided, a sample JSON will be used."
  exit 1
fi

# Check if hook file exists
if [ ! -f "$HOOK_FILE" ]; then
  echo -e "${RED}❌ Error: Hook file not found: $HOOK_FILE${NC}"
  exit 1
fi

# Check if hook is executable
if [ ! -x "$HOOK_FILE" ]; then
  echo -e "${YELLOW}⚠️  Warning: Hook file is not executable${NC}"
  echo "   Making it executable..."
  chmod +x "$HOOK_FILE"
fi

echo -e "${BLUE}🧪 Testing hook: $HOOK_FILE${NC}"
echo ""

# Determine input source
if [ -z "$INPUT_FILE" ]; then
  # Generate sample input based on hook type
  echo "No input file provided. Using sample JSON input..."
  echo ""

  # Default sample input
  TEST_INPUT='{
  "tool_name": "Edit",
  "parameters": {
    "file_path": "/path/to/test.js",
    "old_string": "const x = 1",
    "new_string": "const x = 2"
  },
  "session_info": {
    "project_dir": "/path/to/project",
    "session_id": "test-session-123"
  }
}'
elif [ "$INPUT_FILE" = "-" ]; then
  # Read from stdin
  echo "Reading input from stdin..."
  TEST_INPUT=$(cat)
else
  # Read from file
  if [ ! -f "$INPUT_FILE" ]; then
    echo -e "${RED}❌ Error: Input file not found: $INPUT_FILE${NC}"
    exit 1
  fi
  echo "Reading input from file: $INPUT_FILE"
  TEST_INPUT=$(cat "$INPUT_FILE")
fi

# Validate JSON
if ! echo "$TEST_INPUT" | jq . > /dev/null 2>&1; then
  echo -e "${RED}❌ Error: Invalid JSON input${NC}"
  echo ""
  echo "Input:"
  echo "$TEST_INPUT"
  exit 1
fi

echo -e "${GREEN}✅ Valid JSON input${NC}"
echo ""
echo "Input JSON:"
echo "$TEST_INPUT" | jq .
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Executing hook..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Create temporary files for output and errors
STDOUT_FILE=$(mktemp)
STDERR_FILE=$(mktemp)
EXIT_CODE=0

# Execute the hook
echo "$TEST_INPUT" | "$HOOK_FILE" > "$STDOUT_FILE" 2> "$STDERR_FILE" || EXIT_CODE=$?

# Display results
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Results:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Show exit code
if [ $EXIT_CODE -eq 0 ]; then
  echo -e "${GREEN}Exit Code: $EXIT_CODE (Success/Allow)${NC}"
elif [ $EXIT_CODE -eq 2 ]; then
  echo -e "${YELLOW}Exit Code: $EXIT_CODE (Block)${NC}"
else
  echo -e "${RED}Exit Code: $EXIT_CODE (Error)${NC}"
fi
echo ""

# Show stdout
if [ -s "$STDOUT_FILE" ]; then
  echo "Standard Output:"
  STDOUT_CONTENT=$(cat "$STDOUT_FILE")

  # Try to parse as JSON
  if echo "$STDOUT_CONTENT" | jq . > /dev/null 2>&1; then
    echo "$STDOUT_CONTENT" | jq .

    # Validate decision structure
    DECISION=$(echo "$STDOUT_CONTENT" | jq -r '.decision // empty')
    REASON=$(echo "$STDOUT_CONTENT" | jq -r '.reason // empty')

    if [ -n "$DECISION" ]; then
      echo ""
      echo -e "${BLUE}Decision: $DECISION${NC}"
      if [ -n "$REASON" ]; then
        echo -e "${BLUE}Reason: $REASON${NC}"
      fi
    fi
  else
    echo "$STDOUT_CONTENT"
  fi
  echo ""
else
  echo "Standard Output: (empty)"
  echo ""
fi

# Show stderr
if [ -s "$STDERR_FILE" ]; then
  echo -e "${YELLOW}Standard Error:${NC}"
  cat "$STDERR_FILE"
  echo ""
fi

# Clean up
rm -f "$STDOUT_FILE" "$STDERR_FILE"

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test Summary:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ $EXIT_CODE -eq 0 ]; then
  echo -e "${GREEN}✅ Hook executed successfully${NC}"
  echo ""
  echo "Interpretation: Operation would be ALLOWED"
  echo ""
  echo "Next steps:"
  echo "1. Test with different inputs to verify behavior"
  echo "2. Register the hook in Claude Code settings using /hooks"
  exit 0
elif [ $EXIT_CODE -eq 2 ]; then
  echo -e "${YELLOW}🛑 Hook blocked the operation${NC}"
  echo ""
  echo "Interpretation: Operation would be BLOCKED"
  echo ""
  echo "Next steps:"
  echo "1. Verify this is the expected behavior"
  echo "2. Test with different inputs"
  echo "3. Register the hook in Claude Code settings using /hooks"
  exit 0
else
  echo -e "${RED}❌ Hook failed with error${NC}"
  echo ""
  echo "Interpretation: Hook FAILED (operation would likely be allowed with warning)"
  echo ""
  echo "Next steps:"
  echo "1. Check the error output above"
  echo "2. Debug the hook script"
  echo "3. Run: scripts/validate_hook.sh $HOOK_FILE"
  exit 1
fi
