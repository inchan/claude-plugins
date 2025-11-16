---
name: hooks-creator
description: Guide for creating Claude Code hooks. This skill should be used when users want to create, modify, or troubleshoot hooks that automate actions at specific points in Claude Code's workflow, such as validating code before commits, running linters after edits, or protecting sensitive files.
---

# Hooks Creator

## Overview

This skill provides comprehensive guidance for creating and managing Claude Code hooks. Hooks are event-driven shell commands that execute automatically at specific points in Claude's workflow, enabling validation, automation, and integration with development tools.

## What Are Hooks?

Claude Code hooks are user-defined shell commands that execute in response to specific events during Claude's operation. They provide deterministic control over Claude Code's behavior by:

- **Validating** operations before they execute (e.g., blocking edits to protected files)
- **Automating** tasks after operations complete (e.g., running formatters after code edits)
- **Integrating** with external tools (e.g., triggering CI/CD pipelines)
- **Enforcing** project standards (e.g., code quality checks, security scans)

Hooks can be configured at three levels:
1. **User level** (~/.claude/settings.json) - Apply to all projects
2. **Project level** (.claude/settings.json) - Apply to specific projects
3. **Local level** (.claude/local.json) - Apply to current workspace only

## When to Use This Skill

Use this skill when:
- Creating new hooks to automate repetitive tasks
- Setting up code quality enforcement (linters, formatters)
- Implementing file protection or access control
- Integrating Claude Code with external tools or APIs
- Debugging existing hooks that aren't working as expected
- Learning about available hook events and their capabilities

**Example triggers:**
- "Create a hook to run ESLint after editing JavaScript files"
- "Set up a pre-commit hook that blocks changes to .env files"
- "Build a stop hook that runs tests after code generation"
- "How do I debug my PostToolUse hook?"

## Hook Creation Workflow

Follow this systematic approach to create effective hooks:

### 1. Identify the Event

Determine which hook event best fits your use case:

- **PreToolUse**: Validate or block operations before they execute
- **PostToolUse**: Run automation after tool execution completes
- **Stop**: Execute tasks when Claude finishes a response
- **UserPromptSubmit**: Validate or modify user prompts
- **Notification**: Respond to system notifications
- **SessionStart/SessionEnd**: Initialize or clean up resources

Refer to `references/hook-events-reference.md` for detailed information about each event type and their input/output formats.

### 2. Choose Implementation Approach

**Command Hooks** (for deterministic operations):
```bash
# Simple exit code approach
command: "npx eslint --quiet $file"
```

**Prompt-Based Hooks** (for context-aware decisions):
```json
{
  "prompt": "Review this file path and decide if modification should be allowed",
  "model": "haiku"
}
```

### 3. Initialize Hook Template

Use the provided script to generate a starter template:

```bash
scripts/init_hook.py <hook-name> --event <event-type> --path <output-dir>
```

This creates a properly structured hook script with:
- Event-specific JSON parsing
- Input validation
- Error handling
- Security best practices
- Helpful comments

### 4. Implement Hook Logic

Edit the generated template to add your specific logic:

```bash
#!/bin/bash
set -e

# Read JSON input
INPUT=$(cat)

# Extract relevant fields
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.parameters.file_path // empty')

# Implement your logic here
if [[ "$FILE_PATH" == *".env"* ]]; then
  cat <<EOF
{
  "decision": "block",
  "reason": "Modifying .env files is not allowed"
}
EOF
  exit 2
fi

exit 0
```

### 5. Test Hook Locally

Before registering, test your hook script:

```bash
scripts/test_hook.sh <hook-script> <test-event-json>
```

This validates:
- JSON parsing correctness
- Exit code handling
- Output format (for JSON responses)
- Error scenarios

### 6. Register Hook

Add the hook to your settings file using the `/hooks` command or manual configuration:

```json
{
  "hooks": {
    "PreToolUse": {
      "Edit": [
        {
          "command": "/path/to/your/hook.sh"
        }
      ]
    }
  }
}
```

### 7. Verify and Iterate

Test the hook in real scenarios:
1. Trigger the relevant event
2. Check hook execution in Claude Code output
3. Review logs for errors or unexpected behavior
4. Iterate on the implementation as needed

Refer to `references/debugging-tips.md` for troubleshooting strategies.

## Hook Events Reference

### PreToolUse
Executes **before** a tool runs. Can block the operation.

**Common uses:**
- File protection (block edits to sensitive files)
- Permission checks
- Input validation

**Input includes:** `tool_name`, `parameters`, `session_info`

**Output:** Exit code (0=allow, 2=block) or JSON decision

---

### PostToolUse
Executes **after** a tool completes successfully.

**Common uses:**
- Code formatting (run Prettier after Edit)
- Linting (run ESLint after Write)
- Git operations (auto-stage changes)

**Input includes:** `tool_name`, `parameters`, `result`, `session_info`

**Output:** Exit code (0=success)

---

### Stop
Executes when Claude **finishes responding** to a user message.

**Common uses:**
- Running test suites after code generation
- Updating documentation
- Triggering builds or deployments

**Input includes:** `session_info`, `changed_files`, `tools_used`

**Output:** Exit code or JSON with decision to block/allow

---

### UserPromptSubmit
Executes when a **user submits a prompt**.

**Common uses:**
- Prompt validation
- Adding context automatically
- Logging user requests

**Input includes:** `prompt`, `session_info`

**Output:** Exit code or modified prompt

---

### Notification
Executes when Claude **sends a notification**.

**Common uses:**
- Desktop notifications
- Logging important events
- Triggering external alerts

**Input includes:** `notification_type`, `message`, `session_info`

**Output:** Exit code

---

### SessionStart / SessionEnd
Executes at **session lifecycle boundaries**.

**Common uses:**
- Initializing project-specific environment
- Cleaning up temporary resources
- Session logging

**Input includes:** `session_info`, `project_dir`

**Output:** Exit code

---

### PreCompact
Executes **before context compaction**.

**Common uses:**
- Saving important context
- Triggering backups

**Input includes:** `session_info`, `context_size`

**Output:** Exit code

---

### SubagentStop
Executes when a **subagent finishes**.

**Common uses:**
- Validating subagent results
- Logging subagent actions

**Input includes:** `subagent_type`, `session_info`, `result`

**Output:** Exit code or JSON decision

For comprehensive input/output formats and examples, see `references/hook-events-reference.md`.

## Quick Examples

### Example 1: Lint Changed Files on Stop

```bash
#!/bin/bash
set -e

INPUT=$(cat)

# Extract changed files
CHANGED_FILES=$(echo "$INPUT" | jq -r '.changed_files[]? // empty' | grep -E '\.(js|ts)$' || true)

if [ -z "$CHANGED_FILES" ]; then
  exit 0
fi

# Run ESLint
if ! npx eslint --quiet $CHANGED_FILES; then
  cat <<EOF
{
  "decision": "block",
  "reason": "ESLint errors found. Please fix before proceeding."
}
EOF
  exit 2
fi

exit 0
```

**Registration:**
```json
{
  "hooks": {
    "Stop": {
      "*": [
        {
          "command": "~/.claude/hooks/lint-on-stop.sh"
        }
      ]
    }
  }
}
```

### Example 2: Protect Sensitive Files (PreToolUse)

```bash
#!/bin/bash
set -e

INPUT=$(cat)

# Extract file path
FILE_PATH=$(echo "$INPUT" | jq -r '.parameters.file_path // empty')

# Check if it's a sensitive file
if [[ "$FILE_PATH" == *".env"* ]] || [[ "$FILE_PATH" == *"secrets"* ]]; then
  cat <<EOF
{
  "decision": "block",
  "reason": "Modifying sensitive files (.env, secrets) is not allowed."
}
EOF
  exit 2
fi

exit 0
```

**Registration:**
```json
{
  "hooks": {
    "PreToolUse": {
      "Edit,Write": [
        {
          "command": "~/.claude/hooks/protect-sensitive.sh"
        }
      ]
    }
  }
}
```

### Example 3: Auto-format After Edit (PostToolUse)

```bash
#!/bin/bash
set -e

INPUT=$(cat)

# Extract file path and check extension
FILE_PATH=$(echo "$INPUT" | jq -r '.parameters.file_path // empty')

if [[ "$FILE_PATH" =~ \.(js|ts|tsx)$ ]]; then
  echo "Formatting $FILE_PATH with Prettier..."
  npx prettier --write "$FILE_PATH"
fi

exit 0
```

**Registration:**
```json
{
  "hooks": {
    "PostToolUse": {
      "Edit,Write": [
        {
          "command": "~/.claude/hooks/auto-format.sh"
        }
      ]
    }
  }
}
```

## Security Best Practices

Hooks execute automatically with your current environment's credentials. Always follow these security guidelines:

1. **Validate all inputs** - Never trust data from JSON input without validation
2. **Use absolute paths** - Avoid relative paths that could be manipulated
3. **Limit permissions** - Run hooks with minimal required privileges
4. **Avoid sensitive data** - Don't log passwords, tokens, or API keys
5. **Review before use** - Always inspect hooks before registration, especially from external sources

Refer to `references/security-guide.md` for comprehensive security considerations.

## Resources

### scripts/

**init_hook.py** - Generate new hook templates
```bash
scripts/init_hook.py my-lint-hook --event PostToolUse --path ~/.claude/hooks
```

**validate_hook.sh** - Validate hook script structure and security
```bash
scripts/validate_hook.sh ~/.claude/hooks/my-hook.sh
```

**test_hook.sh** - Test hooks locally with sample input
```bash
scripts/test_hook.sh ~/.claude/hooks/my-hook.sh test-input.json
```

### references/

**hook-events-reference.md** - Comprehensive reference for all hook events with detailed input/output JSON schemas and real-world examples.

**security-guide.md** - Security best practices, common vulnerabilities, and checklist for hook development.

**debugging-tips.md** - Troubleshooting strategies, logging techniques, and common issues with solutions.

### assets/

**templates/** - Ready-to-use hook templates for common scenarios:
- `pre-tool-use.sh` - File validation and protection
- `post-tool-use.sh` - Code formatting and linting
- `stop.sh` - End-of-response automation
- `user-prompt-submit.sh` - Prompt validation
- `notification.sh` - Event notifications

These templates include comments explaining each section and can be customized for specific needs.

## Additional Tips

- **Start simple**: Begin with basic exit code hooks before using JSON responses
- **Test thoroughly**: Use `test_hook.sh` to validate behavior before registration
- **Use logging**: Add `echo "DEBUG: ..."` statements to help troubleshoot
- **Check exit codes**: Remember: 0 = success/allow, 2 = block, other = error
- **Leverage jq**: The `jq` tool is essential for parsing JSON input reliably
- **Infinite loop prevention**: Check for `stop_hook_active` flag to avoid hook recursion

For detailed examples and advanced techniques, explore the bundled templates in `assets/templates/`.
