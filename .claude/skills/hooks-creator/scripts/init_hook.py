#!/usr/bin/env python3
"""
Hook Initializer - Creates a new Claude Code hook from template

Usage:
    init_hook.py <hook-name> --event <event-type> --path <path>

Examples:
    init_hook.py my-lint-hook --event PostToolUse --path ~/.claude/hooks
    init_hook.py protect-files --event PreToolUse --path ./.claude/hooks
    init_hook.py auto-test --event Stop --path ~/.claude/hooks
"""

import sys
from pathlib import Path


# Hook event types
VALID_EVENTS = [
    'PreToolUse',
    'PostToolUse',
    'Stop',
    'SubagentStop',
    'UserPromptSubmit',
    'Notification',
    'SessionStart',
    'SessionEnd',
    'PreCompact'
]

# Base template with event-specific placeholders
HOOK_TEMPLATE_BASE = """#!/bin/bash

# Claude Code {event_type} Hook
# {description}

set -e

# Read JSON input from stdin
INPUT=$(cat)

{event_specific_parsing}

{event_specific_logic}

# Success - allow the operation
exit 0
"""

# Event-specific parsing and logic templates
EVENT_TEMPLATES = {
    'PreToolUse': {
        'description': 'Executes before a tool runs. Can block the operation.',
        'parsing': '''# Extract tool information
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.parameters.file_path // empty')

# Debug logging (optional)
# echo "PreToolUse: $TOOL_NAME on $FILE_PATH" >> ~/.claude/hook-debug.log''',
        'logic': '''# Example: Block edits to sensitive files
# Uncomment and customize as needed
# if [[ "$FILE_PATH" == *".env"* ]] || [[ "$FILE_PATH" == *"secrets"* ]]; then
#   cat <<EOF
# {
#   "decision": "block",
#   "reason": "Modifying sensitive files is not allowed."
# }
# EOF
#   exit 2
# fi

# TODO: Add your validation logic here'''
    },
    'PostToolUse': {
        'description': 'Executes after a tool completes successfully.',
        'parsing': '''# Extract tool information
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.parameters.file_path // empty')

# Debug logging (optional)
# echo "PostToolUse: $TOOL_NAME completed for $FILE_PATH" >> ~/.claude/hook-debug.log''',
        'logic': '''# Example: Auto-format code files
# Uncomment and customize as needed
# if [[ "$FILE_PATH" =~ \\.(js|ts|tsx|jsx)$ ]]; then
#   echo "Formatting $FILE_PATH..."
#   npx prettier --write "$FILE_PATH" 2>/dev/null || true
# fi

# TODO: Add your post-processing logic here'''
    },
    'Stop': {
        'description': 'Executes when Claude finishes responding to a user message.',
        'parsing': '''# Extract session information
CHANGED_FILES=$(echo "$INPUT" | jq -r '.changed_files[]? // empty')
TOOLS_USED=$(echo "$INPUT" | jq -r '.tools_used[]? // empty')

# Debug logging (optional)
# echo "Stop hook triggered. Changed files: $CHANGED_FILES" >> ~/.claude/hook-debug.log''',
        'logic': '''# Example: Run linter on changed JavaScript/TypeScript files
# Uncomment and customize as needed
# JS_FILES=$(echo "$CHANGED_FILES" | grep -E '\\.(js|ts|tsx|jsx)$' || true)
# if [ -n "$JS_FILES" ]; then
#   echo "Running ESLint on changed files..."
#   if ! npx eslint --quiet $JS_FILES 2>/dev/null; then
#     cat <<EOF
# {
#   "decision": "block",
#   "reason": "ESLint errors found. Please fix before proceeding."
# }
# EOF
#     exit 2
#   fi
# fi

# TODO: Add your stop hook logic here'''
    },
    'SubagentStop': {
        'description': 'Executes when a subagent finishes.',
        'parsing': '''# Extract subagent information
SUBAGENT_TYPE=$(echo "$INPUT" | jq -r '.subagent_type // empty')
SUBAGENT_RESULT=$(echo "$INPUT" | jq -r '.result // empty')

# Debug logging (optional)
# echo "SubagentStop: $SUBAGENT_TYPE completed" >> ~/.claude/hook-debug.log''',
        'logic': '''# Example: Validate subagent results
# Uncomment and customize as needed
# if [[ "$SUBAGENT_TYPE" == "code-reviewer" ]]; then
#   # Add validation logic
#   echo "Code review completed"
# fi

# TODO: Add your subagent validation logic here'''
    },
    'UserPromptSubmit': {
        'description': 'Executes when a user submits a prompt.',
        'parsing': '''# Extract prompt information
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty')

# Debug logging (optional)
# echo "UserPromptSubmit: ${PROMPT:0:50}..." >> ~/.claude/hook-debug.log''',
        'logic': '''# Example: Validate or log user prompts
# Uncomment and customize as needed
# if [[ "$PROMPT" == *"delete all"* ]]; then
#   cat <<EOF
# {
#   "decision": "block",
#   "reason": "Destructive operations require confirmation."
# }
# EOF
#   exit 2
# fi

# TODO: Add your prompt validation logic here'''
    },
    'Notification': {
        'description': 'Executes when Claude sends a notification.',
        'parsing': '''# Extract notification information
NOTIFICATION_TYPE=$(echo "$INPUT" | jq -r '.notification_type // empty')
MESSAGE=$(echo "$INPUT" | jq -r '.message // empty')

# Debug logging (optional)
# echo "Notification: $NOTIFICATION_TYPE - $MESSAGE" >> ~/.claude/hook-debug.log''',
        'logic': '''# Example: Send desktop notification
# Uncomment and customize as needed (macOS)
# if [[ "$NOTIFICATION_TYPE" == "important" ]]; then
#   osascript -e "display notification \\"$MESSAGE\\" with title \\"Claude Code\\""
# fi

# TODO: Add your notification handling logic here'''
    },
    'SessionStart': {
        'description': 'Executes at the start of a Claude Code session.',
        'parsing': '''# Extract session information
PROJECT_DIR=$(echo "$INPUT" | jq -r '.project_dir // empty')

# Debug logging (optional)
# echo "SessionStart: $PROJECT_DIR" >> ~/.claude/hook-debug.log''',
        'logic': '''# Example: Initialize project environment
# Uncomment and customize as needed
# if [ -f "$PROJECT_DIR/.nvmrc" ]; then
#   echo "Loading Node version from .nvmrc..."
#   # nvm use
# fi

# TODO: Add your session initialization logic here'''
    },
    'SessionEnd': {
        'description': 'Executes at the end of a Claude Code session.',
        'parsing': '''# Extract session information
PROJECT_DIR=$(echo "$INPUT" | jq -r '.project_dir // empty')

# Debug logging (optional)
# echo "SessionEnd: $PROJECT_DIR" >> ~/.claude/hook-debug.log''',
        'logic': '''# Example: Clean up temporary resources
# Uncomment and customize as needed
# if [ -d "$PROJECT_DIR/.tmp" ]; then
#   rm -rf "$PROJECT_DIR/.tmp"
# fi

# TODO: Add your session cleanup logic here'''
    },
    'PreCompact': {
        'description': 'Executes before context compaction.',
        'parsing': '''# Extract context information
CONTEXT_SIZE=$(echo "$INPUT" | jq -r '.context_size // empty')

# Debug logging (optional)
# echo "PreCompact: Context size $CONTEXT_SIZE" >> ~/.claude/hook-debug.log''',
        'logic': '''# Example: Save important context before compaction
# Uncomment and customize as needed
# BACKUP_FILE="~/.claude/context-backup-$(date +%s).json"
# echo "$INPUT" > "$BACKUP_FILE"

# TODO: Add your pre-compaction logic here'''
    }
}


def title_case_hook_name(hook_name):
    """Convert hyphenated hook name to Title Case for display."""
    return ' '.join(word.capitalize() for word in hook_name.split('-'))


def generate_hook_script(hook_name, event_type):
    """
    Generate a hook script based on event type.

    Args:
        hook_name: Name of the hook
        event_type: Type of hook event

    Returns:
        Hook script content as string
    """
    if event_type not in EVENT_TEMPLATES:
        raise ValueError(f"Unknown event type: {event_type}")

    template = EVENT_TEMPLATES[event_type]

    return HOOK_TEMPLATE_BASE.format(
        event_type=event_type,
        description=template['description'],
        event_specific_parsing=template['parsing'],
        event_specific_logic=template['logic']
    )


def init_hook(hook_name, event_type, path):
    """
    Initialize a new hook script.

    Args:
        hook_name: Name of the hook
        event_type: Type of hook event
        path: Path where the hook should be created

    Returns:
        Path to created hook file, or None if error
    """
    # Validate event type
    if event_type not in VALID_EVENTS:
        print(f"❌ Error: Invalid event type: {event_type}")
        print(f"   Valid events: {', '.join(VALID_EVENTS)}")
        return None

    # Determine hook file path
    hook_dir = Path(path).expanduser().resolve()
    hook_file = hook_dir / f"{hook_name}.sh"

    # Check if file already exists
    if hook_file.exists():
        print(f"❌ Error: Hook file already exists: {hook_file}")
        return None

    # Create directory if it doesn't exist
    try:
        hook_dir.mkdir(parents=True, exist_ok=True)
        print(f"✅ Ensured directory exists: {hook_dir}")
    except Exception as e:
        print(f"❌ Error creating directory: {e}")
        return None

    # Generate hook script
    try:
        hook_content = generate_hook_script(hook_name, event_type)
        hook_file.write_text(hook_content)
        hook_file.chmod(0o755)  # Make executable
        print(f"✅ Created hook script: {hook_file}")
    except Exception as e:
        print(f"❌ Error creating hook script: {e}")
        return None

    # Print next steps
    print(f"\n✅ Hook '{hook_name}' initialized successfully!")
    print(f"\nEvent type: {event_type}")
    print(f"Location: {hook_file}")
    print("\nNext steps:")
    print(f"1. Edit {hook_file} to implement your hook logic")
    print("2. Test the hook using: scripts/test_hook.sh")
    print("3. Register the hook in your Claude Code settings using /hooks command")
    print("\nExample registration:")
    print(f'''{{
  "hooks": {{
    "{event_type}": {{
      "*": [
        {{
          "command": "{hook_file}"
        }}
      ]
    }}
  }}
}}''')

    return hook_file


def main():
    if len(sys.argv) < 6 or sys.argv[2] != '--event' or sys.argv[4] != '--path':
        print("Usage: init_hook.py <hook-name> --event <event-type> --path <path>")
        print("\nValid event types:")
        for event in VALID_EVENTS:
            print(f"  - {event}")
        print("\nExamples:")
        print("  init_hook.py my-lint-hook --event PostToolUse --path ~/.claude/hooks")
        print("  init_hook.py protect-files --event PreToolUse --path ./.claude/hooks")
        print("  init_hook.py auto-test --event Stop --path ~/.claude/hooks")
        sys.exit(1)

    hook_name = sys.argv[1]
    event_type = sys.argv[3]
    path = sys.argv[5]

    print(f"🚀 Initializing hook: {hook_name}")
    print(f"   Event type: {event_type}")
    print(f"   Location: {path}")
    print()

    result = init_hook(hook_name, event_type, path)

    if result:
        sys.exit(0)
    else:
        sys.exit(1)


if __name__ == "__main__":
    main()
