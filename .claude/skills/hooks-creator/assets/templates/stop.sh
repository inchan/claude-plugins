#!/bin/bash

# Stop Hook Template
# Purpose: Execute tasks when Claude finishes responding to a user message
#
# Common use cases:
# - Running test suites after code generation
# - Linting all changed files
# - Building the project
# - Updating documentation
# - Triggering CI/CD pipelines
#
# Exit codes:
#   0 - Success (allow Claude to continue)
#   2 - Block (prevent Claude from continuing)
#
# IMPORTANT: Always check stop_hook_active to prevent infinite loops!
#
# To use this template:
# 1. Customize the automation logic below
# 2. Make executable: chmod +x stop.sh
# 3. Test: scripts/test_hook.sh stop.sh test-input.json
# 4. Register in Claude Code settings

set -e

# Optional: Enable debug logging
# DEBUG_LOG=~/.claude/hook-debug.log
# echo "=== Stop Hook $(date) ===" >> "$DEBUG_LOG"

# Read JSON input from stdin
INPUT=$(cat)

# ============================================================================
# CRITICAL: Prevent infinite loops
# ============================================================================

# Always check this flag first!
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
  # Hook is already running, exit immediately to prevent loop
  exit 0
fi

# ============================================================================
# Extract information from input
# ============================================================================

# Get list of changed files
CHANGED_FILES=$(echo "$INPUT" | jq -r '.changed_files[]? // empty')

# Get list of tools that were used
TOOLS_USED=$(echo "$INPUT" | jq -r '.tools_used[]? // empty')

# Get session information
PROJECT_DIR=$(echo "$INPUT" | jq -r '.session_info.project_dir // empty')

# Optional: Log for debugging
# echo "Changed files: $CHANGED_FILES" >> "$DEBUG_LOG"
# echo "Tools used: $TOOLS_USED" >> "$DEBUG_LOG"

# ============================================================================
# CUSTOMIZE: Add your automation logic here
# ============================================================================

# Skip if no files were changed
if [ -z "$CHANGED_FILES" ]; then
  echo "No files changed, skipping hook" >&2
  exit 0
fi

# Example 1: Run linters on changed files
# Uncomment and customize as needed

# Lint JavaScript/TypeScript files
JS_FILES=$(echo "$CHANGED_FILES" | grep -E '\.(js|ts|tsx|jsx)$' || true)
if [ -n "$JS_FILES" ]; then
  echo "Running ESLint on changed JavaScript/TypeScript files..." >&2

  if command -v npx &> /dev/null; then
    # Run ESLint in quiet mode (errors only)
    if ! echo "$JS_FILES" | xargs npx eslint --quiet 2>/dev/null; then
      cat <<EOF
{
  "decision": "block",
  "reason": "ESLint errors found in changed files. Run 'npx eslint --fix' to fix automatically, or fix manually."
}
EOF
      exit 2
    fi
    echo "✅ ESLint passed" >&2
  fi
fi

# Lint CSS/SCSS files
# CSS_FILES=$(echo "$CHANGED_FILES" | grep -E '\.(css|scss|less)$' || true)
# if [ -n "$CSS_FILES" ]; then
#   echo "Running Stylelint on changed CSS files..." >&2
#
#   if command -v npx &> /dev/null; then
#     if ! echo "$CSS_FILES" | xargs npx stylelint 2>/dev/null; then
#       cat <<EOF
# {
#   "decision": "block",
#   "reason": "Stylelint errors found. Run 'npx stylelint --fix' to fix automatically."
# }
# EOF
#       exit 2
#     fi
#     echo "✅ Stylelint passed" >&2
#   fi
# fi

# Example 2: Run tests if source files changed
# SRC_FILES=$(echo "$CHANGED_FILES" | grep "^src/" || true)
# if [ -n "$SRC_FILES" ]; then
#   echo "Running tests..." >&2
#
#   if command -v npm &> /dev/null; then
#     if ! npm test 2>&1 | grep -q "PASS"; then
#       cat <<EOF
# {
#   "decision": "block",
#   "reason": "Tests failed. Please fix failing tests before proceeding."
# }
# EOF
#       exit 2
#     fi
#     echo "✅ Tests passed" >&2
#   fi
# fi

# Example 3: Build the project
# if command -v npm &> /dev/null; then
#   echo "Building project..." >&2
#
#   if ! npm run build > /dev/null 2>&1; then
#     cat <<EOF
# {
#   "decision": "block",
#   "reason": "Build failed. Please fix build errors before proceeding."
# }
# EOF
#     exit 2
#   fi
#   echo "✅ Build successful" >&2
# fi

# Example 4: Check for i18n updates
# Check if any files using i18n were modified
# I18N_FILES=$(echo "$CHANGED_FILES" | xargs grep -l -E '\bt\(|i18Key\(' 2>/dev/null || true)
# if [ -n "$I18N_FILES" ]; then
#   echo "Files using i18n were modified:" >&2
#   echo "$I18N_FILES" | head -3 >&2
#   echo "" >&2
#   echo "💡 Consider running: yarn i18n-extract" >&2
# fi

# Example 5: Conditional checks based on tools used
# if echo "$TOOLS_USED" | grep -q "Write"; then
#   echo "New files were created" >&2
#   # Maybe run additional setup
# fi
#
# if echo "$TOOLS_USED" | grep -q "Bash"; then
#   echo "Bash commands were executed" >&2
#   # Maybe verify the results
# fi

# Example 6: File-specific triggers
# case "$CHANGED_FILES" in
#   *package.json*)
#     echo "⚠️  package.json changed - you may need to run: npm install" >&2
#     ;;
#
#   *requirements.txt*)
#     echo "⚠️  requirements.txt changed - you may need to run: pip install -r requirements.txt" >&2
#     ;;
#
#   *.env*)
#     echo "⚠️  Environment file changed - restart may be required" >&2
#     ;;
# esac

# ============================================================================
# END CUSTOMIZATION
# ============================================================================

# All checks passed
echo "✅ All checks passed" >&2
exit 0
