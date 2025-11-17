#!/bin/bash

# PreToolUse Hook Template
# Purpose: Validate operations before they execute (can block operations)
#
# Common use cases:
# - File protection (block edits to sensitive files)
# - Permission validation
# - Input sanitization
# - Pre-condition checking
#
# Exit codes:
#   0 - Allow the operation
#   2 - Block the operation
#
# To use this template:
# 1. Customize the validation logic below
# 2. Make executable: chmod +x pre-tool-use.sh
# 3. Test: scripts/test_hook.sh pre-tool-use.sh test-input.json
# 4. Register in Claude Code settings

set -e

# Optional: Enable debug logging
# DEBUG_LOG=~/.claude/hook-debug.log
# echo "=== PreToolUse Hook $(date) ===" >> "$DEBUG_LOG"

# Read JSON input from stdin
INPUT=$(cat)

# Optional: Log raw input for debugging
# echo "$INPUT" | jq . >> "$DEBUG_LOG"

# Extract tool information
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.parameters.file_path // empty')
COMMAND=$(echo "$INPUT" | jq -r '.parameters.command // empty')

# Extract session information
PROJECT_DIR=$(echo "$INPUT" | jq -r '.session_info.project_dir // empty')

# ============================================================================
# CUSTOMIZE: Add your validation logic here
# ============================================================================

# Example 1: Protect sensitive files
# Uncomment and customize patterns as needed
if [[ "$FILE_PATH" == *".env"* ]] || \
   [[ "$FILE_PATH" == *"secrets"* ]] || \
   [[ "$FILE_PATH" == *".git/"* ]]; then
  cat <<EOF
{
  "decision": "block",
  "reason": "Modifying sensitive files (.env, secrets, .git) is not allowed for security."
}
EOF
  exit 2
fi

# Example 2: Require confirmation for destructive commands
# Uncomment to block dangerous rm commands
# if [[ "$COMMAND" == *"rm -rf"* ]]; then
#   cat <<EOF
# {
#   "decision": "block",
#   "reason": "Destructive 'rm -rf' commands require manual execution for safety."
# }
# EOF
#   exit 2
# fi

# Example 3: Enforce file path restrictions
# Uncomment to ensure files are within project directory
# if [ -n "$FILE_PATH" ] && [ -n "$PROJECT_DIR" ]; then
#   REAL_FILE=$(realpath "$FILE_PATH" 2>/dev/null || echo "")
#   REAL_PROJECT=$(realpath "$PROJECT_DIR" 2>/dev/null || echo "")
#
#   if [[ "$REAL_FILE" != "$REAL_PROJECT"* ]]; then
#     cat <<EOF
# {
#   "decision": "block",
#   "reason": "File access outside project directory is not allowed."
# }
# EOF
#     exit 2
#   fi
# fi

# Example 4: Tool-specific validation
# case "$TOOL_NAME" in
#   Edit|Write)
#     # Validate file operations
#     if [[ "$FILE_PATH" == *"package.json"* ]]; then
#       echo "Warning: Modifying package.json" >&2
#     fi
#     ;;
#
#   Bash)
#     # Validate bash commands
#     if [[ "$COMMAND" == *"sudo"* ]]; then
#       cat <<EOF
# {
#   "decision": "block",
#   "reason": "Commands with 'sudo' require manual execution."
# }
# EOF
#       exit 2
#     fi
#     ;;
# esac

# ============================================================================
# END CUSTOMIZATION
# ============================================================================

# Allow the operation
exit 0
