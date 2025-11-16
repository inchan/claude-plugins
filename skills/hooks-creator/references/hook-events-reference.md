# Hook Events Reference

This document provides comprehensive reference information for all Claude Code hook events, including input/output JSON schemas, real-world examples, and usage patterns.

## Table of Contents

- [PreToolUse](#pretooluse)
- [PostToolUse](#posttooluse)
- [Stop](#stop)
- [SubagentStop](#subagentstop)
- [UserPromptSubmit](#userpromptsubmit)
- [Notification](#notification)
- [SessionStart](#sessionstart)
- [SessionEnd](#sessionend)
- [PreCompact](#precompact)

---

## PreToolUse

Executes **before** a tool runs. Can block the operation by returning exit code 2 or JSON decision.

### When to Use
- File protection (blocking edits to sensitive files)
- Permission validation
- Input sanitization
- Pre-conditions checking

### Input Schema

```json
{
  "tool_name": "string",           // Name of the tool being called
  "parameters": {                  // Tool-specific parameters
    "file_path": "string",         // For Edit/Write/Read tools
    "old_string": "string",        // For Edit tool
    "new_string": "string",        // For Edit tool
    "content": "string",           // For Write tool
    "command": "string",           // For Bash tool
    // ... other tool-specific fields
  },
  "session_info": {
    "project_dir": "string",
    "session_id": "string",
    "user_id": "string"
  }
}
```

### Output Options

**Option 1: Exit Code**
- `0` - Allow the operation
- `2` - Block the operation

**Option 2: JSON Decision**
```json
{
  "decision": "allow|block",
  "reason": "string (required if blocking)"
}
```

### Real-World Examples

#### Example 1: Protect Sensitive Files

```bash
#!/bin/bash
set -e

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.parameters.file_path // empty')

# Block .env and secrets files
if [[ "$FILE_PATH" == *".env"* ]] || [[ "$FILE_PATH" == *"secrets"* ]]; then
  cat <<EOF
{
  "decision": "block",
  "reason": "Modifying .env or secrets files is not allowed for security reasons."
}
EOF
  exit 2
fi

exit 0
```

#### Example 2: Require Confirmation for Deletions

```bash
#!/bin/bash
set -e

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.parameters.command // empty')

# Block dangerous rm commands
if [[ "$COMMAND" == *"rm -rf"* ]]; then
  cat <<EOF
{
  "decision": "block",
  "reason": "Destructive 'rm -rf' commands require manual execution for safety."
}
EOF
  exit 2
fi

exit 0
```

---

## PostToolUse

Executes **after** a tool completes successfully. Cannot block the operation (it already happened).

### When to Use
- Code formatting after edits
- Linting after code changes
- Auto-staging git changes
- Triggering related operations

### Input Schema

```json
{
  "tool_name": "string",
  "parameters": {
    // Same as PreToolUse
  },
  "result": "string|object",       // The result returned by the tool
  "session_info": {
    "project_dir": "string",
    "session_id": "string"
  }
}
```

### Output Options

**Exit Code Only**
- `0` - Success
- Non-zero - Error (logged but doesn't affect the completed operation)

### Real-World Examples

#### Example 1: Auto-format JavaScript/TypeScript

```bash
#!/bin/bash
set -e

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.parameters.file_path // empty')

# Format JS/TS files with Prettier
if [[ "$FILE_PATH" =~ \.(js|ts|tsx|jsx)$ ]]; then
  echo "Formatting $FILE_PATH with Prettier..."
  npx prettier --write "$FILE_PATH" 2>/dev/null || true
fi

exit 0
```

#### Example 2: Run ESLint After Edit

```bash
#!/bin/bash
set -e

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.parameters.file_path // empty')

if [[ "$FILE_PATH" =~ \.(js|ts)$ ]]; then
  echo "Running ESLint on $FILE_PATH..."
  npx eslint --fix "$FILE_PATH" 2>/dev/null || {
    echo "ESLint found issues (not blocking)"
  }
fi

exit 0
```

#### Example 3: Auto-stage Git Changes

```bash
#!/bin/bash
set -e

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.parameters.file_path // empty')

if [ -n "$FILE_PATH" ]; then
  git add "$FILE_PATH" 2>/dev/null || true
  echo "Staged $FILE_PATH"
fi

exit 0
```

---

## Stop

Executes when Claude **finishes responding** to a user message.

### When to Use
- Running test suites after code generation
- Building the project
- Updating documentation
- Triggering CI/CD pipelines
- Running linters on all changed files

### Input Schema

```json
{
  "changed_files": ["string"],     // List of files modified in this session
  "tools_used": ["string"],        // List of tools that were called
  "session_info": {
    "project_dir": "string",
    "session_id": "string"
  },
  "stop_hook_active": boolean      // True if hook is already running (prevent loops)
}
```

### Output Options

**Option 1: Exit Code**
- `0` - Success
- `2` - Block (prevents Claude from continuing)

**Option 2: JSON Decision**
```json
{
  "decision": "allow|block",
  "reason": "string"
}
```

### Real-World Examples

#### Example 1: Lint and Translate (from OfficeMail project)

```bash
#!/bin/bash
set -e

INPUT=$(cat)

# Prevent infinite loops
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
  exit 0
fi

# Get changed files
CHANGED_FILES=$(git status --porcelain | grep -E '^\s*[MAU]' | awk '{print $2}' || true)

if [ -z "$CHANGED_FILES" ]; then
  exit 0
fi

# Run ESLint on JS/TS files
JS_FILES=$(echo "$CHANGED_FILES" | grep -E '\.(js|jsx|ts|tsx)$' || true)
if [ -n "$JS_FILES" ]; then
  echo "Running ESLint..."
  if ! npx eslint --quiet $JS_FILES; then
    cat <<EOF
{
  "decision": "block",
  "reason": "ESLint errors found. Run 'yarn eslint --fix' to fix."
}
EOF
    exit 2
  fi
fi

# Run Stylelint on CSS files
CSS_FILES=$(echo "$CHANGED_FILES" | grep -E '\.(css|scss|less)$' || true)
if [ -n "$CSS_FILES" ]; then
  echo "Running Stylelint..."
  if ! npx stylelint $CSS_FILES; then
    cat <<EOF
{
  "decision": "block",
  "reason": "Stylelint errors found. Run 'yarn stylelint --fix' to fix."
}
EOF
    exit 2
  fi
fi

exit 0
```

#### Example 2: Run Tests After Code Changes

```bash
#!/bin/bash
set -e

INPUT=$(cat)
CHANGED_FILES=$(echo "$INPUT" | jq -r '.changed_files[]? // empty')

# Check if any source files changed
SRC_FILES=$(echo "$CHANGED_FILES" | grep "^src/" || true)

if [ -n "$SRC_FILES" ]; then
  echo "Running tests..."
  if ! npm test; then
    cat <<EOF
{
  "decision": "block",
  "reason": "Tests failed. Please fix before proceeding."
}
EOF
    exit 2
  fi
fi

exit 0
```

---

## SubagentStop

Executes when a **subagent finishes** its task.

### When to Use
- Validating subagent results
- Logging subagent actions
- Triggering follow-up actions based on subagent type

### Input Schema

```json
{
  "subagent_type": "string",       // Type of subagent (e.g., "code-reviewer")
  "result": "string|object",       // Result returned by subagent
  "session_info": {
    "project_dir": "string",
    "session_id": "string"
  }
}
```

### Output Options

**Exit Code** or **JSON Decision** (same as Stop)

### Real-World Example

```bash
#!/bin/bash
set -e

INPUT=$(cat)
SUBAGENT_TYPE=$(echo "$INPUT" | jq -r '.subagent_type // empty')

echo "Subagent $SUBAGENT_TYPE completed"

# Log subagent activity
echo "$(date): $SUBAGENT_TYPE" >> ~/.claude/subagent-log.txt

exit 0
```

---

## UserPromptSubmit

Executes when a **user submits a prompt**.

### When to Use
- Prompt validation
- Adding contextual information automatically
- Logging user requests
- Blocking certain types of requests

### Input Schema

```json
{
  "prompt": "string",              // The user's prompt text
  "session_info": {
    "project_dir": "string",
    "session_id": "string"
  }
}
```

### Output Options

**Exit Code** or **JSON with modified prompt**

```json
{
  "prompt": "string",              // Modified prompt (optional)
  "reason": "string"               // Explanation for modification
}
```

### Real-World Examples

#### Example 1: Block Destructive Prompts

```bash
#!/bin/bash
set -e

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty')

# Block prompts with "delete all"
if [[ "$PROMPT" == *"delete all"* ]]; then
  cat <<EOF
{
  "decision": "block",
  "reason": "Bulk deletion operations require manual confirmation."
}
EOF
  exit 2
fi

exit 0
```

#### Example 2: Log User Requests

```bash
#!/bin/bash
set -e

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty')

# Log to file
echo "$(date): ${PROMPT:0:100}..." >> ~/.claude/prompts-log.txt

exit 0
```

---

## Notification

Executes when Claude **sends a notification**.

### When to Use
- Desktop notifications
- Logging important events
- Triggering external alerts (Slack, email, etc.)

### Input Schema

```json
{
  "notification_type": "string",   // Type of notification
  "message": "string",             // Notification message
  "session_info": {
    "project_dir": "string",
    "session_id": "string"
  }
}
```

### Output Options

**Exit Code Only** (0 = success)

### Real-World Example

```bash
#!/bin/bash
set -e

INPUT=$(cat)
MESSAGE=$(echo "$INPUT" | jq -r '.message // empty')

# Send macOS notification
osascript -e "display notification \"$MESSAGE\" with title \"Claude Code\""

exit 0
```

---

## SessionStart

Executes at the **start** of a Claude Code session.

### When to Use
- Initializing project-specific environment
- Loading configuration
- Starting development servers
- Session logging

### Input Schema

```json
{
  "project_dir": "string",
  "session_info": {
    "session_id": "string",
    "user_id": "string"
  }
}
```

### Output Options

**Exit Code Only**

### Real-World Example

```bash
#!/bin/bash
set -e

INPUT=$(cat)
PROJECT_DIR=$(echo "$INPUT" | jq -r '.project_dir // empty')

echo "Session started: $PROJECT_DIR" >> ~/.claude/session-log.txt

# Load Node version if .nvmrc exists
if [ -f "$PROJECT_DIR/.nvmrc" ]; then
  echo "Loading Node version from .nvmrc..."
fi

exit 0
```

---

## SessionEnd

Executes at the **end** of a Claude Code session.

### When to Use
- Cleaning up temporary resources
- Stopping development servers
- Saving session state
- Session logging

### Input Schema

Same as SessionStart

### Real-World Example

```bash
#!/bin/bash
set -e

INPUT=$(cat)
PROJECT_DIR=$(echo "$INPUT" | jq -r '.project_dir // empty')

# Clean up temporary files
if [ -d "$PROJECT_DIR/.tmp" ]; then
  rm -rf "$PROJECT_DIR/.tmp"
fi

echo "Session ended: $PROJECT_DIR" >> ~/.claude/session-log.txt

exit 0
```

---

## PreCompact

Executes **before context compaction** (when context window needs to be reduced).

### When to Use
- Saving important context before it's removed
- Triggering backups
- Logging context state

### Input Schema

```json
{
  "context_size": number,          // Current context size
  "session_info": {
    "project_dir": "string",
    "session_id": "string"
  }
}
```

### Output Options

**Exit Code Only**

### Real-World Example

```bash
#!/bin/bash
set -e

INPUT=$(cat)
CONTEXT_SIZE=$(echo "$INPUT" | jq -r '.context_size // 0')

echo "Context compaction triggered. Size: $CONTEXT_SIZE" >> ~/.claude/compact-log.txt

# Backup context
BACKUP_FILE=~/.claude/context-backup-$(date +%s).json
echo "$INPUT" > "$BACKUP_FILE"

exit 0
```

---

## Common Patterns

### Pattern 1: Infinite Loop Prevention

Always check for `stop_hook_active` in Stop and SubagentStop hooks:

```bash
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
  exit 0
fi
```

### Pattern 2: Error Handling

Use `set -e` and handle errors gracefully:

```bash
#!/bin/bash
set -e

# ... hook logic ...

# Graceful fallback for non-critical operations
npx prettier --write "$FILE" 2>/dev/null || true
```

### Pattern 3: JSON Output

Always use heredoc for clean JSON formatting:

```bash
cat <<EOF
{
  "decision": "block",
  "reason": "Your reason here"
}
EOF
```

### Pattern 4: Debugging

Add optional debug logging:

```bash
# Debug logging (comment out when not needed)
echo "DEBUG: $TOOL_NAME on $FILE_PATH" >> ~/.claude/hook-debug.log
```

---

## Testing Your Hooks

Use the provided test script:

```bash
scripts/test_hook.sh ~/.claude/hooks/my-hook.sh test-input.json
```

Create test input files for each event type to validate behavior.
