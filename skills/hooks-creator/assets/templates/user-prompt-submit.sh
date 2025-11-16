#!/bin/bash

# UserPromptSubmit Hook Template
# Purpose: Execute tasks when a user submits a prompt
#
# Common use cases:
# - Prompt validation
# - Adding contextual information automatically
# - Logging user requests
# - Blocking certain types of requests
# - Prompt enrichment
#
# Exit codes:
#   0 - Allow the prompt
#   2 - Block the prompt
#
# Output options:
#   1. Exit code only (0 or 2)
#   2. JSON with modified prompt (optional)
#
# To use this template:
# 1. Customize the validation/enrichment logic below
# 2. Make executable: chmod +x user-prompt-submit.sh
# 3. Test: scripts/test_hook.sh user-prompt-submit.sh test-input.json
# 4. Register in Claude Code settings

set -e

# Optional: Enable debug logging
# DEBUG_LOG=~/.claude/hook-debug.log
# echo "=== UserPromptSubmit Hook $(date) ===" >> "$DEBUG_LOG"

# Read JSON input from stdin
INPUT=$(cat)

# Optional: Log raw input for debugging
# echo "$INPUT" | jq . >> "$DEBUG_LOG"

# Extract prompt text
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty')

# Extract session information
PROJECT_DIR=$(echo "$INPUT" | jq -r '.session_info.project_dir // empty')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_info.session_id // empty')

# Optional: Log prompt (first 100 chars only for privacy)
# echo "$(date): ${PROMPT:0:100}..." >> ~/.claude/prompts-log.txt

# ============================================================================
# CUSTOMIZE: Add your validation/enrichment logic here
# ============================================================================

# Example 1: Block prompts with destructive keywords
# Uncomment to enable
# if [[ "$PROMPT" == *"delete all"* ]] || \
#    [[ "$PROMPT" == *"remove everything"* ]] || \
#    [[ "$PROMPT" == *"wipe out"* ]]; then
#   cat <<EOF
# {
#   "decision": "block",
#   "reason": "Bulk destructive operations require manual confirmation for safety."
# }
# EOF
#   exit 2
# fi

# Example 2: Validate command requests
# if [[ "$PROMPT" == *"run"* ]] || [[ "$PROMPT" == *"execute"* ]]; then
#   # Check for dangerous commands
#   if [[ "$PROMPT" == *"rm -rf"* ]] || [[ "$PROMPT" == *"sudo"* ]]; then
#     cat <<EOF
# {
#   "decision": "block",
#   "reason": "Destructive or privileged commands require manual execution."
# }
# EOF
#     exit 2
#   fi
# fi

# Example 3: Enforce project context
# Require certain keywords for specific projects
# if [[ "$PROJECT_DIR" == *"/production"* ]]; then
#   # In production projects, require explicit confirmation
#   if [[ "$PROMPT" != *"confirmed"* ]] && \
#      [[ "$PROMPT" == *"deploy"* || "$PROMPT" == *"publish"* ]]; then
#     cat <<EOF
# {
#   "decision": "block",
#   "reason": "Production deployments must include 'confirmed' keyword for safety."
# }
# EOF
#     exit 2
#   fi
# fi

# Example 4: Add contextual information to prompt (enrichment)
# Uncomment to automatically add project context
# PROJECT_NAME=$(basename "$PROJECT_DIR")
# ENRICHED_PROMPT="$PROMPT

# [Auto-added context: Project '$PROJECT_NAME']"

# Output modified prompt
# cat <<EOF
# {
#   "prompt": $(echo "$ENRICHED_PROMPT" | jq -Rs .),
#   "reason": "Added project context automatically"
# }
# EOF
# exit 0

# Example 5: Rate limiting (simple implementation)
# LOG_FILE=~/.claude/prompt-timestamps.log
# CURRENT_TIME=$(date +%s)
# echo "$CURRENT_TIME" >> "$LOG_FILE"
#
# # Check prompts in last minute
# RECENT_COUNT=$(tail -100 "$LOG_FILE" | awk -v cutoff=$((CURRENT_TIME - 60)) '$1 > cutoff' | wc -l)
#
# if [ "$RECENT_COUNT" -gt 10 ]; then
#   cat <<EOF
# {
#   "decision": "block",
#   "reason": "Too many prompts in short time. Please wait a moment."
# }
# EOF
#   exit 2
# fi

# Example 6: Content filtering
# if [[ "$PROMPT" =~ (password|token|secret|api.key|apikey) ]]; then
#   # Warn about potentially sharing secrets
#   echo "⚠️  Warning: Prompt may contain sensitive information" >&2
#   # But don't block, just warn
# fi

# Example 7: Require approval for file operations
# if [[ "$PROMPT" == *"delete"* ]] || \
#    [[ "$PROMPT" == *"remove"* ]] || \
#    [[ "$PROMPT" == *"overwrite"* ]]; then
#
#   # Check if prompt includes confirmation phrase
#   if [[ "$PROMPT" != *"I confirm"* ]] && [[ "$PROMPT" != *"confirmed"* ]]; then
#     cat <<EOF
# {
#   "decision": "block",
#   "reason": "File deletion/modification requests require confirmation. Add 'I confirm' to your prompt."
# }
# EOF
#     exit 2
#   fi
# fi

# Example 8: Log specific types of requests
# case "$PROMPT" in
#   *"create"*|*"generate"*|*"build"*)
#     echo "$(date): CREATE - ${PROMPT:0:50}..." >> ~/.claude/creative-requests.log
#     ;;
#
#   *"fix"*|*"debug"*|*"error"*)
#     echo "$(date): DEBUG - ${PROMPT:0:50}..." >> ~/.claude/debug-requests.log
#     ;;
#
#   *"explain"*|*"how"*|*"what"*|*"why"*)
#     echo "$(date): QUESTION - ${PROMPT:0:50}..." >> ~/.claude/questions.log
#     ;;
# esac

# Example 9: Auto-add best practices reminder
# if [[ "$PROMPT" == *"create component"* ]] || \
#    [[ "$PROMPT" == *"new component"* ]]; then
#   ENRICHED_PROMPT="$PROMPT

# Remember to:
# - Add TypeScript types
# - Include error handling
# - Write unit tests"
#
#   cat <<EOF
# {
#   "prompt": $(echo "$ENRICHED_PROMPT" | jq -Rs .),
#   "reason": "Added component best practices reminder"
# }
# EOF
#   exit 0
# fi

# ============================================================================
# END CUSTOMIZATION
# ============================================================================

# Allow the prompt as-is
exit 0
