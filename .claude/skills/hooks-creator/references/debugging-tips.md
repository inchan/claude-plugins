# Hook Debugging Tips

Debugging hooks can be challenging since they run automatically in the background. This guide provides strategies, tools, and techniques for troubleshooting hook issues.

## Quick Debugging Checklist

When a hook isn't working:

1. ✅ Is the hook file executable? (`chmod +x hook.sh`)
2. ✅ Is the shebang correct? (`#!/bin/bash`)
3. ✅ Does it have syntax errors? (`bash -n hook.sh`)
4. ✅ Is `jq` installed? (`which jq`)
5. ✅ Is the hook registered correctly in settings?
6. ✅ Does it work with test input? (`scripts/test_hook.sh hook.sh`)

---

## Debugging Strategies

### Strategy 1: Add Debug Logging

The simplest way to debug hooks is adding log statements:

```bash
#!/bin/bash
set -e

# Create debug log file
DEBUG_LOG=~/.claude/hook-debug.log

# Log start
echo "=== Hook started at $(date) ===" >> "$DEBUG_LOG"

# Read input
INPUT=$(cat)

# Log raw input
echo "Raw input: $INPUT" >> "$DEBUG_LOG"

# Parse fields
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.parameters.file_path // empty')

# Log parsed values
echo "Tool: $TOOL_NAME" >> "$DEBUG_LOG"
echo "File: $FILE_PATH" >> "$DEBUG_LOG"

# Your hook logic here
if [[ "$FILE_PATH" == *.js ]]; then
  echo "JavaScript file detected" >> "$DEBUG_LOG"
  npx eslint "$FILE_PATH" >> "$DEBUG_LOG" 2>&1 || {
    echo "ESLint failed" >> "$DEBUG_LOG"
    exit 2
  }
fi

echo "=== Hook completed ===" >> "$DEBUG_LOG"
exit 0
```

**View logs:**
```bash
tail -f ~/.claude/hook-debug.log
```

### Strategy 2: Use set -x for Execution Tracing

Enable bash tracing to see every command execution:

```bash
#!/bin/bash
set -e
set -x  # Enable tracing

INPUT=$(cat)
# ... rest of hook
```

**Redirect trace to file:**
```bash
#!/bin/bash
set -e

# Redirect trace to debug file
exec 2>> ~/.claude/hook-trace.log
set -x

INPUT=$(cat)
# ... rest of hook
```

### Strategy 3: Test Locally with Sample Input

Use the test script with realistic input:

```bash
# Create test input
cat > test-input.json <<EOF
{
  "tool_name": "Edit",
  "parameters": {
    "file_path": "/path/to/test.js",
    "old_string": "const x = 1",
    "new_string": "const x = 2"
  },
  "session_info": {
    "project_dir": "/path/to/project"
  }
}
EOF

# Test the hook
scripts/test_hook.sh ~/.claude/hooks/my-hook.sh test-input.json
```

### Strategy 4: Incremental Development

Build hooks incrementally:

**Step 1: Basic structure**
```bash
#!/bin/bash
set -e
INPUT=$(cat)
echo "Hook running" >&2
exit 0
```

**Step 2: Add JSON parsing**
```bash
#!/bin/bash
set -e
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
echo "Tool: $TOOL_NAME" >&2
exit 0
```

**Step 3: Add logic**
```bash
#!/bin/bash
set -e
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

if [ "$TOOL_NAME" = "Edit" ]; then
  echo "Edit detected" >&2
fi

exit 0
```

---

## Common Issues and Solutions

### Issue 1: Hook Not Executing

**Symptoms:**
- Hook doesn't seem to run at all
- No output or logs

**Diagnosis:**
```bash
# Check if file exists
ls -la ~/.claude/hooks/my-hook.sh

# Check permissions
stat ~/.claude/hooks/my-hook.sh

# Check registration
cat ~/.claude/settings.json | jq '.hooks'
```

**Solutions:**
1. Make sure the hook file is executable:
   ```bash
   chmod +x ~/.claude/hooks/my-hook.sh
   ```

2. Verify registration in settings:
   ```json
   {
     "hooks": {
       "PostToolUse": {
         "Edit": [
           {
             "command": "/Users/username/.claude/hooks/my-hook.sh"
           }
         ]
       }
     }
   }
   ```

3. Use absolute paths in settings, not relative paths or `~`

### Issue 2: JSON Parsing Errors

**Symptoms:**
- Hook fails immediately
- `jq` errors in output

**Diagnosis:**
```bash
# Test with sample input
echo '{"tool_name":"Edit"}' | ~/.claude/hooks/my-hook.sh

# Check if jq is installed
which jq
jq --version
```

**Solutions:**
1. Install jq if missing:
   ```bash
   # macOS
   brew install jq

   # Linux
   sudo apt-get install jq
   ```

2. Handle empty/null values:
   ```bash
   # Bad
   TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name')

   # Good
   TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
   ```

3. Validate JSON before parsing:
   ```bash
   if ! echo "$INPUT" | jq . > /dev/null 2>&1; then
     echo "Invalid JSON input" >&2
     exit 1
   fi
   ```

### Issue 3: Exit Codes Not Working

**Symptoms:**
- Returning exit code 2 doesn't block operations
- Operations proceed despite hook "blocking"

**Diagnosis:**
```bash
# Test exit code manually
echo '{}' | ~/.claude/hooks/my-hook.sh
echo "Exit code: $?"
```

**Solutions:**
1. Make sure you're using the right exit codes:
   - `0` = Allow/Success
   - `2` = Block (for PreToolUse, Stop, etc.)
   - Other = Error

2. Don't exit with 2 in hooks that can't block (PostToolUse):
   ```bash
   # PostToolUse can't block
   if [ $? -ne 0 ]; then
     echo "Warning: operation failed" >&2
     exit 0  # Not exit 2
   fi
   ```

3. For blocking, also provide JSON reason:
   ```bash
   cat <<EOF
   {
     "decision": "block",
     "reason": "Your reason here"
   }
   EOF
   exit 2
   ```

### Issue 4: Infinite Loops (Stop Hooks)

**Symptoms:**
- Claude Code becomes unresponsive
- Hook keeps triggering itself
- High CPU usage

**Diagnosis:**
```bash
# Check if hook modifies files
grep -E "(echo|sed|>)" ~/.claude/hooks/stop-hook.sh

# Check for stop_hook_active check
grep "stop_hook_active" ~/.claude/hooks/stop-hook.sh
```

**Solutions:**
1. Always check the `stop_hook_active` flag:
   ```bash
   STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
   if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
     exit 0
   fi
   ```

2. Avoid modifying files in Stop hooks, or be very careful:
   ```bash
   # Bad - will loop forever
   echo "// Updated" >> file.js

   # Good - only run if flag is false
   if [ "$STOP_HOOK_ACTIVE" != "true" ]; then
     echo "// Updated" >> file.js
   fi
   ```

### Issue 5: File Path Issues

**Symptoms:**
- Hook can't find files
- "No such file or directory" errors

**Diagnosis:**
```bash
# Add debug logging
FILE_PATH=$(echo "$INPUT" | jq -r '.parameters.file_path // empty')
echo "Looking for: $FILE_PATH" >> ~/hook-debug.log
ls -la "$FILE_PATH" >> ~/hook-debug.log 2>&1
```

**Solutions:**
1. Handle both relative and absolute paths:
   ```bash
   FILE_PATH=$(echo "$INPUT" | jq -r '.parameters.file_path // empty')
   PROJECT_DIR=$(echo "$INPUT" | jq -r '.session_info.project_dir // empty')

   # Make path absolute if relative
   if [[ "$FILE_PATH" != /* ]]; then
     FILE_PATH="$PROJECT_DIR/$FILE_PATH"
   fi
   ```

2. Resolve symlinks and normalize paths:
   ```bash
   REAL_PATH=$(realpath "$FILE_PATH" 2>/dev/null || echo "$FILE_PATH")
   ```

3. Check if file exists before operating:
   ```bash
   if [ ! -f "$FILE_PATH" ]; then
     echo "File not found: $FILE_PATH" >&2
     exit 1
   fi
   ```

### Issue 6: Tool Matcher Not Working

**Symptoms:**
- Hook doesn't run for expected tools
- Runs for wrong tools

**Diagnosis:**
Check your hook registration:

```json
{
  "hooks": {
    "PostToolUse": {
      "Edit": [...],           // Only Edit tool
      "Edit,Write": [...],     // Edit OR Write
      "*": [...]               // All tools
    }
  }
}
```

**Solutions:**
1. Use correct tool names (case-sensitive):
   - `Edit`, `Write`, `Read`, `Bash`, `Glob`, `Grep`

2. Multiple tools use comma separation (no spaces):
   ```json
   "Edit,Write,Bash": [...]
   ```

3. Use `*` for all tools:
   ```json
   "*": [...]
   ```

4. Add debug logging to see what tool triggered:
   ```bash
   TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
   echo "Triggered by: $TOOL_NAME" >> ~/hook-debug.log
   ```

---

## Advanced Debugging Techniques

### Technique 1: Capture Full Hook Execution

Create a wrapper script that logs everything:

```bash
#!/bin/bash
# wrapper-hook.sh

HOOK_FILE="$1"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE=~/.claude/hook-logs/execution-$TIMESTAMP.log

{
  echo "=== Hook Execution Log ==="
  echo "Time: $(date)"
  echo "Hook: $HOOK_FILE"
  echo "Input:"

  # Save and show input
  INPUT=$(cat)
  echo "$INPUT" | jq .

  echo ""
  echo "=== Hook Output ==="

  # Run actual hook and capture output
  echo "$INPUT" | "$HOOK_FILE" 2>&1
  EXIT_CODE=$?

  echo ""
  echo "=== Exit Code: $EXIT_CODE ==="

} | tee "$LOG_FILE"

exit $EXIT_CODE
```

Register the wrapper instead:
```json
{
  "command": "/path/to/wrapper-hook.sh /path/to/actual-hook.sh"
}
```

### Technique 2: Conditional Debugging

Only debug when environment variable is set:

```bash
#!/bin/bash
set -e

INPUT=$(cat)

# Debug mode
if [ "$CLAUDE_HOOK_DEBUG" = "true" ]; then
  DEBUG_LOG=~/.claude/hook-debug.log
  echo "=== Debug Log $(date) ===" >> "$DEBUG_LOG"
  echo "$INPUT" | jq . >> "$DEBUG_LOG"
fi

# Rest of hook...
```

Enable debugging:
```bash
export CLAUDE_HOOK_DEBUG=true
```

### Technique 3: Mock External Dependencies

For hooks that call external tools, create mock versions:

```bash
#!/bin/bash
set -e

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.parameters.file_path // empty')

# Mock eslint in test mode
if [ "$HOOK_TEST_MODE" = "true" ]; then
  echo "MOCK: Would run eslint on $FILE_PATH"
  exit 0
fi

# Real execution
npx eslint "$FILE_PATH"
```

### Technique 4: Bisect Hook Logic

Comment out sections to isolate issues:

```bash
#!/bin/bash
set -e

INPUT=$(cat)

# Section 1: Parse input
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
# exit 0  # Uncomment to test only Section 1

# Section 2: Extract file path
FILE_PATH=$(echo "$INPUT" | jq -r '.parameters.file_path // empty')
# exit 0  # Uncomment to test through Section 2

# Section 3: Validate
if [[ "$FILE_PATH" == *.js ]]; then
  # exit 0  # Uncomment to test through Section 3

  # Section 4: Execute
  npx eslint "$FILE_PATH"
fi

exit 0
```

---

## Debugging Tools

### Tool 1: Hook Execution Tracer

Create a tracer to see all hook executions:

```bash
#!/bin/bash
# ~/.claude/hooks/tracer.sh

LOG_FILE=~/.claude/hook-trace.log

{
  echo "$(date +%H:%M:%S) | Hook triggered"
  cat | tee >(jq '.' >> "$LOG_FILE")
} | "$@"
```

### Tool 2: Input JSON Validator

Validate hook input before processing:

```bash
validate_input() {
  local input="$1"

  if ! echo "$input" | jq . > /dev/null 2>&1; then
    echo "ERROR: Invalid JSON" >&2
    return 1
  fi

  # Check required fields
  local tool_name=$(echo "$input" | jq -r '.tool_name // empty')
  if [ -z "$tool_name" ]; then
    echo "WARNING: Missing tool_name" >&2
  fi

  return 0
}

# Usage
INPUT=$(cat)
validate_input "$INPUT" || exit 1
```

### Tool 3: Test Input Generator

Generate realistic test inputs:

```bash
# generate-test-input.sh
#!/bin/bash

EVENT_TYPE="$1"

case "$EVENT_TYPE" in
  PreToolUse|PostToolUse)
    cat <<EOF
{
  "tool_name": "Edit",
  "parameters": {
    "file_path": "$(pwd)/test.js",
    "old_string": "const x = 1",
    "new_string": "const x = 2"
  },
  "session_info": {
    "project_dir": "$(pwd)",
    "session_id": "test-123"
  }
}
EOF
    ;;

  Stop)
    cat <<EOF
{
  "changed_files": ["test.js", "test2.js"],
  "tools_used": ["Edit", "Write"],
  "session_info": {
    "project_dir": "$(pwd)",
    "session_id": "test-123"
  },
  "stop_hook_active": false
}
EOF
    ;;

  *)
    echo "Unknown event type: $EVENT_TYPE"
    exit 1
    ;;
esac
```

Usage:
```bash
./generate-test-input.sh Stop | scripts/test_hook.sh my-hook.sh -
```

---

## Performance Debugging

### Measure Hook Execution Time

```bash
#!/bin/bash
set -e

START_TIME=$(date +%s%N)

INPUT=$(cat)

# Your hook logic here

END_TIME=$(date +%s%N)
DURATION=$(( (END_TIME - START_TIME) / 1000000 ))

echo "Hook execution time: ${DURATION}ms" >> ~/.claude/hook-perf.log

exit 0
```

### Identify Slow Operations

```bash
#!/bin/bash
set -e

time_operation() {
  local name="$1"
  shift
  local start=$(date +%s%N)

  "$@"

  local end=$(date +%s%N)
  local duration=$(( (end - start) / 1000000 ))
  echo "$name: ${duration}ms" >> ~/.claude/hook-perf.log
}

INPUT=$(cat)

time_operation "JSON parsing" echo "$INPUT" | jq .
time_operation "ESLint" npx eslint file.js

exit 0
```

---

## Getting Help

If you're still stuck:

1. **Review logs:** Check `~/.claude/hook-debug.log`
2. **Test in isolation:** Use `scripts/test_hook.sh`
3. **Validate structure:** Run `scripts/validate_hook.sh`
4. **Check documentation:** Review `hook-events-reference.md`
5. **Simplify:** Remove complexity until it works
6. **Compare with templates:** Check `assets/templates/`

Remember: Most hook issues are simple - missing permissions, incorrect paths, or JSON parsing errors. Start with the basics!
