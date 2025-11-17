#!/bin/bash

# Notification Hook Template
# Purpose: Respond to notifications sent by Claude Code
#
# Common use cases:
# - Desktop notifications
# - Logging important events
# - Triggering external alerts (Slack, email, etc.)
# - Custom notification handling
#
# Exit codes:
#   0 - Success
#   Non-zero - Error (logged but doesn't affect notification)
#
# To use this template:
# 1. Customize the notification handling logic below
# 2. Make executable: chmod +x notification.sh
# 3. Test: scripts/test_hook.sh notification.sh test-input.json
# 4. Register in Claude Code settings

set -e

# Optional: Enable debug logging
# DEBUG_LOG=~/.claude/hook-debug.log
# echo "=== Notification Hook $(date) ===" >> "$DEBUG_LOG"

# Read JSON input from stdin
INPUT=$(cat)

# Optional: Log raw input for debugging
# echo "$INPUT" | jq . >> "$DEBUG_LOG"

# Extract notification information
NOTIFICATION_TYPE=$(echo "$INPUT" | jq -r '.notification_type // empty')
MESSAGE=$(echo "$INPUT" | jq -r '.message // empty')
SEVERITY=$(echo "$INPUT" | jq -r '.severity // "info"')

# Extract session information
PROJECT_DIR=$(echo "$INPUT" | jq -r '.session_info.project_dir // empty')

# ============================================================================
# CUSTOMIZE: Add your notification handling logic here
# ============================================================================

# Example 1: macOS Desktop Notifications
# Uncomment to enable desktop notifications on macOS
# if command -v osascript &> /dev/null; then
#   # Escape special characters in message
#   ESCAPED_MESSAGE=$(echo "$MESSAGE" | sed 's/"/\\"/g')
#
#   osascript -e "display notification \"$ESCAPED_MESSAGE\" with title \"Claude Code\" subtitle \"$NOTIFICATION_TYPE\""
# fi

# Example 2: Linux Desktop Notifications (notify-send)
# Uncomment to enable desktop notifications on Linux
# if command -v notify-send &> /dev/null; then
#   notify-send "Claude Code: $NOTIFICATION_TYPE" "$MESSAGE"
# fi

# Example 3: Log notifications to file
# LOG_FILE=~/.claude/notifications.log
# echo "$(date) | $NOTIFICATION_TYPE | $MESSAGE" >> "$LOG_FILE"

# Example 4: Severity-based handling
# case "$SEVERITY" in
#   error)
#     # Critical notifications - maybe send to Slack or email
#     echo "🚨 ERROR: $MESSAGE" >&2
#
#     # Play sound on macOS
#     # if command -v afplay &> /dev/null; then
#     #   afplay /System/Library/Sounds/Basso.aiff
#     # fi
#     ;;
#
#   warning)
#     echo "⚠️  WARNING: $MESSAGE" >&2
#     ;;
#
#   info)
#     echo "ℹ️  INFO: $MESSAGE" >&2
#     ;;
#
#   *)
#     echo "📣 $NOTIFICATION_TYPE: $MESSAGE" >&2
#     ;;
# esac

# Example 5: Send to Slack
# Uncomment and configure webhook URL
# if [ -n "$SLACK_WEBHOOK_URL" ]; then
#   PAYLOAD=$(cat <<EOF
# {
#   "text": "Claude Code Notification",
#   "attachments": [
#     {
#       "color": "good",
#       "fields": [
#         {
#           "title": "$NOTIFICATION_TYPE",
#           "value": "$MESSAGE",
#           "short": false
#         }
#       ]
#     }
#   ]
# }
# EOF
# )
#
#   curl -X POST -H 'Content-type: application/json' \
#     --data "$PAYLOAD" \
#     "$SLACK_WEBHOOK_URL" 2>/dev/null || true
# fi

# Example 6: Send email notification
# Uncomment and configure email settings
# if command -v mail &> /dev/null; then
#   echo "$MESSAGE" | mail -s "Claude Code: $NOTIFICATION_TYPE" your@email.com
# fi

# Example 7: Type-specific handling
# case "$NOTIFICATION_TYPE" in
#   task_completed)
#     echo "✅ Task completed: $MESSAGE"
#     # Maybe show desktop notification
#     ;;
#
#   error_occurred)
#     echo "❌ Error: $MESSAGE"
#     # Send to error tracking service
#     ;;
#
#   user_input_needed)
#     echo "⏸️  Waiting for input: $MESSAGE"
#     # Show prominent notification
#     # osascript -e "display dialog \"$MESSAGE\" buttons {\"OK\"} default button 1"
#     ;;
#
#   *)
#     echo "📬 $NOTIFICATION_TYPE: $MESSAGE"
#     ;;
# esac

# Example 8: Write to system log
# if command -v logger &> /dev/null; then
#   logger -t "claude-code" "[$NOTIFICATION_TYPE] $MESSAGE"
# fi

# Example 9: Trigger webhook
# if [ -n "$WEBHOOK_URL" ]; then
#   PAYLOAD=$(cat <<EOF
# {
#   "type": "$NOTIFICATION_TYPE",
#   "message": "$MESSAGE",
#   "project": "$PROJECT_DIR",
#   "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
# }
# EOF
# )
#
#   curl -X POST \
#     -H "Content-Type: application/json" \
#     -d "$PAYLOAD" \
#     "$WEBHOOK_URL" 2>/dev/null || true
# fi

# Example 10: Conditional notifications based on project
# PROJECT_NAME=$(basename "$PROJECT_DIR")
#
# case "$PROJECT_NAME" in
#   production-*)
#     # Always notify for production projects
#     echo "🏭 PRODUCTION: $MESSAGE" >&2
#     # Send to monitoring service
#     ;;
#
#   test-*|dev-*)
#     # Less verbose for test/dev projects
#     # echo "🧪 DEV: $MESSAGE" >&2
#     ;;
#
#   *)
#     # Default handling
#     echo "$MESSAGE" >&2
#     ;;
# esac

# Example 11: Rate limiting notifications
# Prevent notification spam
# LAST_NOTIFICATION_FILE=~/.claude/last-notification
# CURRENT_TIME=$(date +%s)
#
# if [ -f "$LAST_NOTIFICATION_FILE" ]; then
#   LAST_TIME=$(cat "$LAST_NOTIFICATION_FILE")
#   TIME_DIFF=$((CURRENT_TIME - LAST_TIME))
#
#   # Skip if less than 5 seconds since last notification
#   if [ $TIME_DIFF -lt 5 ]; then
#     exit 0
#   fi
# fi
#
# echo "$CURRENT_TIME" > "$LAST_NOTIFICATION_FILE"

# Example 12: Custom notification formatting
# Format message with timestamp and color
# TIMESTAMP=$(date +"%H:%M:%S")
# COLORED_MESSAGE=$(cat <<EOF
# 🔔 [$TIMESTAMP] Claude Code
# Type: $NOTIFICATION_TYPE
# Message: $MESSAGE
# EOF
# )
#
# echo "$COLORED_MESSAGE" >&2

# ============================================================================
# END CUSTOMIZATION
# ============================================================================

# Success
exit 0
