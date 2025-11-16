# Hook Security Guide

Hooks execute automatically with your current environment's credentials. This guide covers essential security practices for developing and deploying Claude Code hooks.

## ⚠️ Critical Warning

**Hooks run with your full system permissions.** Malicious or poorly written hooks can:
- Access sensitive files and credentials
- Execute arbitrary commands
- Modify or delete data
- Expose secrets to external services
- Compromise your development environment

**Always review hooks before registering them**, especially those from external sources.

---

## Security Principles

### 1. Principle of Least Privilege

Run hooks with the minimum permissions necessary.

**✅ Good:**
```bash
# Read-only check
if [ ! -r "$FILE_PATH" ]; then
  exit 2
fi
```

**❌ Bad:**
```bash
# Don't run hooks as root or with sudo
sudo rm -rf "$FILE_PATH"  # NEVER DO THIS
```

### 2. Input Validation

Never trust input data without validation.

**✅ Good:**
```bash
FILE_PATH=$(echo "$INPUT" | jq -r '.parameters.file_path // empty')

# Validate file path
if [ -z "$FILE_PATH" ]; then
  echo "Error: Empty file path"
  exit 1
fi

# Ensure it's within project directory
if [[ "$FILE_PATH" != "$PROJECT_DIR"* ]]; then
  cat <<EOF
{
  "decision": "block",
  "reason": "File path outside project directory"
}
EOF
  exit 2
fi
```

**❌ Bad:**
```bash
# Using input without validation
FILE_PATH=$1  # Unsafe
rm "$FILE_PATH"  # Could delete anything!
```

### 3. Secure Command Execution

Avoid command injection vulnerabilities.

**✅ Good:**
```bash
# Use variables properly quoted
npx eslint "$FILE_PATH"

# Or use arrays for commands
FILES=()
while IFS= read -r file; do
  FILES+=("$file")
done < <(echo "$CHANGED_FILES")

npx eslint "${FILES[@]}"
```

**❌ Bad:**
```bash
# Command injection risk
eval "npx eslint $FILE_PATH"

# Unsafe variable expansion
COMMAND="rm $USER_INPUT"
$COMMAND  # User could inject "; rm -rf /"
```

### 4. Secret Protection

Never log, expose, or hardcode sensitive data.

**✅ Good:**
```bash
# Use environment variables
API_KEY="${CLAUDE_HOOK_API_KEY}"

# Don't log sensitive data
echo "API call completed" >> hook.log
```

**❌ Bad:**
```bash
# Hardcoded credentials
API_KEY="sk-1234567890abcdef"  # NEVER DO THIS

# Logging sensitive data
echo "API_KEY: $API_KEY" >> hook.log  # EXPOSED!

# Including secrets in errors
cat <<EOF
{
  "decision": "block",
  "reason": "Auth failed with key: $API_KEY"
}
EOF
```

---

## Common Vulnerabilities

### 1. Path Traversal

**Vulnerability:**
```bash
FILE_PATH=$(echo "$INPUT" | jq -r '.parameters.file_path')
cat "$FILE_PATH"  # Could read any file on system!
```

**Fix:**
```bash
FILE_PATH=$(echo "$INPUT" | jq -r '.parameters.file_path // empty')
PROJECT_DIR=$(echo "$INPUT" | jq -r '.session_info.project_dir // empty')

# Normalize and validate path
REAL_PATH=$(realpath "$FILE_PATH" 2>/dev/null || echo "")
REAL_PROJECT=$(realpath "$PROJECT_DIR" 2>/dev/null || echo "")

if [[ "$REAL_PATH" != "$REAL_PROJECT"* ]]; then
  cat <<EOF
{
  "decision": "block",
  "reason": "Access denied: path outside project"
}
EOF
  exit 2
fi
```

### 2. Command Injection

**Vulnerability:**
```bash
COMMAND=$(echo "$INPUT" | jq -r '.parameters.command')
bash -c "$COMMAND"  # User controls entire command!
```

**Fix:**
```bash
COMMAND=$(echo "$INPUT" | jq -r '.parameters.command // empty')

# Validate against allowlist
ALLOWED_COMMANDS=("npm test" "npm build" "git status")
COMMAND_ALLOWED=false

for allowed in "${ALLOWED_COMMANDS[@]}"; do
  if [[ "$COMMAND" == "$allowed" ]]; then
    COMMAND_ALLOWED=true
    break
  fi
done

if [ "$COMMAND_ALLOWED" = false ]; then
  cat <<EOF
{
  "decision": "block",
  "reason": "Command not in allowlist"
}
EOF
  exit 2
fi
```

### 3. Insecure Temporary Files

**Vulnerability:**
```bash
# Predictable temp file
echo "secret data" > /tmp/hook-output.txt  # World-readable!
```

**Fix:**
```bash
# Secure temp file with proper permissions
TEMP_FILE=$(mktemp)
chmod 600 "$TEMP_FILE"

echo "secret data" > "$TEMP_FILE"

# Clean up
trap "rm -f $TEMP_FILE" EXIT
```

### 4. Infinite Loops

**Vulnerability:**
```bash
# Stop hook that modifies files triggers itself again
#!/bin/bash
set -e
INPUT=$(cat)

# This will loop forever!
echo "// comment" >> file.js
```

**Fix:**
```bash
#!/bin/bash
set -e
INPUT=$(cat)

# Check if hook is already running
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
  exit 0
fi

echo "// comment" >> file.js
```

### 5. Unquoted Variables

**Vulnerability:**
```bash
# Files with spaces will break
for file in $FILES; do
  cat $file  # Fails on "my file.txt"
done
```

**Fix:**
```bash
# Properly quote variables
while IFS= read -r file; do
  cat "$file"
done < <(echo "$FILES")
```

---

## Security Checklist

Use this checklist before deploying a hook:

### Input Validation
- [ ] All JSON inputs are parsed with `jq`
- [ ] Empty/null values are handled gracefully
- [ ] File paths are validated against project directory
- [ ] User-provided data is never directly executed

### Command Safety
- [ ] No use of `eval`
- [ ] No unquoted variables in commands
- [ ] No direct shell command construction from user input
- [ ] Commands use absolute paths or are in allowlist

### Secrets & Credentials
- [ ] No hardcoded passwords, tokens, or API keys
- [ ] Sensitive data is not logged
- [ ] Secrets are loaded from environment variables
- [ ] Error messages don't expose sensitive information

### File Operations
- [ ] File paths are validated and sanitized
- [ ] Temporary files use secure creation (`mktemp`)
- [ ] Temporary files have restrictive permissions (600 or 700)
- [ ] Temporary files are cleaned up (`trap` or explicit removal)

### Error Handling
- [ ] `set -e` is used to fail fast
- [ ] Exit codes are used correctly (0=success, 2=block)
- [ ] Errors are handled gracefully
- [ ] Debug output doesn't expose sensitive data

### Loop Prevention
- [ ] Stop/SubagentStop hooks check `stop_hook_active` flag
- [ ] Hooks don't trigger themselves
- [ ] Infinite loop scenarios are considered

### Testing
- [ ] Hook is tested with valid inputs
- [ ] Hook is tested with invalid/malicious inputs
- [ ] Hook is validated with `validate_hook.sh`
- [ ] Security implications are reviewed

---

## Secure Coding Patterns

### Pattern 1: Safe File Access

```bash
#!/bin/bash
set -e

INPUT=$(cat)

# Extract and validate
PROJECT_DIR=$(echo "$INPUT" | jq -r '.session_info.project_dir // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.parameters.file_path // empty')

# Validation
if [ -z "$PROJECT_DIR" ] || [ -z "$FILE_PATH" ]; then
  echo "Error: Missing required fields" >&2
  exit 1
fi

# Canonicalize paths
REAL_FILE=$(realpath "$FILE_PATH" 2>/dev/null || echo "")
REAL_PROJECT=$(realpath "$PROJECT_DIR" 2>/dev/null || echo "")

# Security check
if [ -z "$REAL_FILE" ] || [ -z "$REAL_PROJECT" ]; then
  exit 2
fi

if [[ "$REAL_FILE" != "$REAL_PROJECT"* ]]; then
  cat <<EOF
{
  "decision": "block",
  "reason": "File access outside project directory denied"
}
EOF
  exit 2
fi

# Now safe to use
cat "$REAL_FILE"
```

### Pattern 2: Safe Command Execution

```bash
#!/bin/bash
set -e

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.parameters.command // empty')

# Define allowlist
declare -A SAFE_COMMANDS=(
  ["test"]="npm test"
  ["build"]="npm run build"
  ["lint"]="npx eslint ."
)

# Extract command name (first word)
COMMAND_NAME=$(echo "$COMMAND" | awk '{print $1}')

# Check allowlist
if [ -z "${SAFE_COMMANDS[$COMMAND_NAME]}" ]; then
  cat <<EOF
{
  "decision": "block",
  "reason": "Command '$COMMAND_NAME' not allowed"
}
EOF
  exit 2
fi

# Execute safely
${SAFE_COMMANDS[$COMMAND_NAME]}
```

### Pattern 3: Secure Logging

```bash
#!/bin/bash
set -e

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.parameters.file_path // empty')

# Extract filename only (not full path which may contain sensitive info)
FILENAME=$(basename "$FILE_PATH")

# Safe logging (no sensitive data)
echo "$(date +%Y-%m-%d\ %H:%M:%S) - File modified: $FILENAME" >> ~/.claude/hook-audit.log

# NEVER log:
# - Full file paths (may contain usernames)
# - File contents
# - Environment variables
# - Command parameters
```

### Pattern 4: Secure External API Calls

```bash
#!/bin/bash
set -e

INPUT=$(cat)

# Load API key from environment
API_KEY="${CLAUDE_HOOK_API_KEY}"

if [ -z "$API_KEY" ]; then
  echo "Error: API key not configured" >&2
  exit 1
fi

# Make API call securely
RESPONSE=$(curl -s -H "Authorization: Bearer $API_KEY" \
  https://api.example.com/endpoint)

# Don't log response if it may contain sensitive data
# Don't include API key in error messages
if [ $? -ne 0 ]; then
  echo "Error: API call failed" >&2
  exit 1
fi
```

---

## Environment Security

### Recommended Environment Variables

Store configuration in environment variables, not in hook scripts:

```bash
# In your shell rc file (.bashrc, .zshrc)
export CLAUDE_HOOK_API_KEY="your-key-here"
export CLAUDE_HOOK_LOG_LEVEL="info"
export CLAUDE_HOOK_ALLOWED_PATHS="/path/to/projects"
```

Use in hooks:
```bash
API_KEY="${CLAUDE_HOOK_API_KEY}"
LOG_LEVEL="${CLAUDE_HOOK_LOG_LEVEL:-info}"
```

### Protect Hook Files

```bash
# Make hooks readable/executable only by owner
chmod 700 ~/.claude/hooks
chmod 700 ~/.claude/hooks/*.sh

# Or more restrictive
chmod 600 ~/.claude/hooks/*.sh
chmod +x ~/.claude/hooks/*.sh
```

---

## Review Process

Before deploying hooks to production:

1. **Self-review** using this security checklist
2. **Peer review** for critical hooks
3. **Test in isolated environment** first
4. **Run automated validation**: `scripts/validate_hook.sh`
5. **Monitor initial deployments** for unexpected behavior

---

## External Hooks Warning

**Never run hooks from untrusted sources without thorough review.**

If using third-party hooks:
1. Read the entire script line by line
2. Understand what every command does
3. Check for hardcoded credentials
4. Verify no external network calls to unknown endpoints
5. Test in isolated environment first
6. Consider forking and maintaining your own version

---

## Incident Response

If you suspect a hook has been compromised:

1. **Immediately disable** the hook in settings
2. **Rotate credentials** that may have been exposed
3. **Review logs** for suspicious activity
4. **Audit recent changes** made by Claude Code
5. **Report** if you believe it's a security issue with Claude Code itself

---

## Additional Resources

- [OWASP Command Injection](https://owasp.org/www-community/attacks/Command_Injection)
- [Bash Security Best Practices](https://mywiki.wooledge.org/BashGuide/Practices)
- [CWE-78: OS Command Injection](https://cwe.mitre.org/data/definitions/78.html)

---

Remember: **Security is not optional**. Take the time to write secure hooks, and your future self will thank you.
