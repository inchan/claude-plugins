#!/bin/bash

# PostToolUse Hook Template
# Purpose: Automate tasks after tool execution completes
#
# Common use cases:
# - Code formatting (Prettier, Black, etc.)
# - Linting (ESLint, Stylelint, etc.)
# - Auto-staging git changes
# - Triggering related operations
#
# Note: PostToolUse hooks CANNOT block operations (they already happened)
#
# Exit codes:
#   0 - Success
#   Non-zero - Error (logged but doesn't affect the completed operation)
#
# To use this template:
# 1. Customize the automation logic below
# 2. Make executable: chmod +x post-tool-use.sh
# 3. Test: scripts/test_hook.sh post-tool-use.sh test-input.json
# 4. Register in Claude Code settings

set -e

# Optional: Enable debug logging
# DEBUG_LOG=~/.claude/hook-debug.log
# echo "=== PostToolUse Hook $(date) ===" >> "$DEBUG_LOG"

# Read JSON input from stdin
INPUT=$(cat)

# Optional: Log raw input for debugging
# echo "$INPUT" | jq . >> "$DEBUG_LOG"

# Extract tool information
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.parameters.file_path // empty')
RESULT=$(echo "$INPUT" | jq -r '.result // empty')

# Extract session information
PROJECT_DIR=$(echo "$INPUT" | jq -r '.session_info.project_dir // empty')

# ============================================================================
# CUSTOMIZE: Add your automation logic here
# ============================================================================

# Example 1: Auto-format JavaScript/TypeScript files with Prettier
# Uncomment and customize file extensions as needed
if [[ "$FILE_PATH" =~ \.(js|ts|tsx|jsx)$ ]]; then
  echo "Formatting $FILE_PATH with Prettier..." >&2

  # Try to format, but don't fail if Prettier isn't available
  if command -v npx &> /dev/null; then
    npx prettier --write "$FILE_PATH" 2>/dev/null || {
      echo "Warning: Prettier formatting failed for $FILE_PATH" >&2
    }
  fi
fi

# Example 2: Auto-lint CSS/SCSS files with Stylelint
# Uncomment to enable automatic fixing
# if [[ "$FILE_PATH" =~ \.(css|scss|less)$ ]]; then
#   echo "Linting $FILE_PATH with Stylelint..." >&2
#
#   if command -v npx &> /dev/null; then
#     npx stylelint --fix "$FILE_PATH" 2>/dev/null || {
#       echo "Warning: Stylelint failed for $FILE_PATH" >&2
#     }
#   fi
# fi

# Example 3: Auto-format Python files with Black
# if [[ "$FILE_PATH" =~ \.py$ ]]; then
#   echo "Formatting $FILE_PATH with Black..." >&2
#
#   if command -v black &> /dev/null; then
#     black "$FILE_PATH" 2>/dev/null || {
#       echo "Warning: Black formatting failed for $FILE_PATH" >&2
#     }
#   fi
# fi

# Example 4: Auto-stage Git changes
# Uncomment to automatically stage edited files
# if [ -n "$FILE_PATH" ] && [ -f "$FILE_PATH" ]; then
#   # Check if we're in a git repository
#   if git -C "$(dirname "$FILE_PATH")" rev-parse --git-dir > /dev/null 2>&1; then
#     echo "Staging $FILE_PATH..." >&2
#     git add "$FILE_PATH" 2>/dev/null || true
#   fi
# fi

# Example 5: Tool-specific automation
# case "$TOOL_NAME" in
#   Edit)
#     echo "File edited: $(basename "$FILE_PATH")" >&2
#     ;;
#
#   Write)
#     echo "File created: $(basename "$FILE_PATH")" >&2
#     # Maybe run additional setup for new files
#     ;;
#
#   Bash)
#     # Log bash commands
#     # COMMAND=$(echo "$INPUT" | jq -r '.parameters.command // empty')
#     # echo "$(date): $COMMAND" >> ~/.claude/bash-history.log
#     ;;
# esac

# Example 6: Update modification timestamp log
# if [ -n "$FILE_PATH" ]; then
#   echo "$(date): Modified $FILE_PATH" >> ~/.claude/modifications.log
# fi

# Example 7: Trigger file-specific actions
# case "$FILE_PATH" in
#   */package.json)
#     echo "package.json changed - consider running npm install" >&2
#     ;;
#
#   */requirements.txt)
#     echo "requirements.txt changed - consider running pip install" >&2
#     ;;
#
#   */.env*)
#     echo "Environment file changed - restart may be required" >&2
#     ;;
# esac

# ============================================================================
# END CUSTOMIZATION
# ============================================================================

# Success
exit 0
