# CC-Skills Hooks Plugin

Skill activation hooks for CC-Skills plugins - Auto-suggests relevant skills based on user prompts.

## Overview

This plugin provides **UserPromptSubmit** hooks that:
- Aggregates `skill-rules.json` from all CC-Skills plugins
- Analyzes user prompts for keywords and intent patterns
- Suggests relevant skills based on priority (critical > high > medium > low)

## Installation

When installing the CC-Skills marketplace:

```bash
# Add marketplace
/plugin marketplace add inchan/cc-skills

# Install hooks plugin (required for auto-activation)
/plugin install cc-skills-hooks@inchan-cc-skills

# Install other plugins as needed
/plugin install workflow-automation@inchan-cc-skills
/plugin install dev-guidelines@inchan-cc-skills
# ...
```

## How It Works

### 1. Hook Trigger
- **Event**: `UserPromptSubmit`
- **Execution**: Before every user prompt is processed

### 2. Skill Aggregation
The hook scans all installed CC-Skills plugins:

```bash
${REPO_ROOT}/plugins/*/skills/skill-rules.json
```

### 3. Pattern Matching
For each skill in `skill-rules.json`:
- Matches **keywords** in user prompt
- Matches **intentPatterns** (regex) in user prompt
- Assigns priority score (critical=4, high=3, medium=2, low=1)

### 4. Skill Suggestion
Outputs suggestions to Claude:

```
[SKILL SUGGESTIONS]
Priority: high
- frontend-dev-guidelines (React/TypeScript development)
- error-tracking (Sentry v8 patterns)
```

## Files

| File | Description |
|------|-------------|
| `plugin.json` | Plugin metadata |
| `hooks.json` | Hook configuration |
| `skill-activation-hook.sh` | Main hook script |
| `stop-hook-lint-and-translate.sh` | Stop hook (optional) |

## Configuration

### hooks.json

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/skill-activation-hook.sh"
          }
        ]
      }
    ]
  }
}
```

### Environment Variables

- `${CLAUDE_PLUGIN_ROOT}`: Plugin root directory
- `${REPO_ROOT}`: Repository root (auto-detected)

## Logging

Hook execution logs are written to:

```
/tmp/claude-skill-activation.log
```

Example log:
```
[2025-11-21 10:30:15] Multi-plugin skill-activation-hook executed
[DEBUG] Repository root: /home/user/.claude/plugins/inchan-cc-skills
[DEBUG] User prompt: Create a React component
[DEBUG] Found: /home/user/.claude/plugins/inchan-cc-skills/plugins/dev-guidelines/skills/skill-rules.json
[DEBUG] Total skill-rules.json files: 7
[INFO] Suggesting skill: frontend-dev-guidelines (priority: high)
```

## Dependencies

- **Bash** (shell script execution)
- **jq** (JSON parsing, optional but recommended)

## Compatibility

- Claude Code v1.0.0+
- Multi-plugin architecture (v2.0.0+)

## Troubleshooting

### Hook Not Executing

1. **Check plugin installation**:
   ```bash
   /plugin list
   # Should show "cc-skills-hooks"
   ```

2. **Verify script permissions**:
   ```bash
   ls -l ~/.claude/plugins/inchan-cc-skills/hooks/skill-activation-hook.sh
   # Should show -rwxr-xr-x (executable)
   ```

3. **Check logs**:
   ```bash
   tail -f /tmp/claude-skill-activation.log
   ```

### Skills Not Suggested

1. **Verify skill-rules.json exists**:
   ```bash
   find ~/.claude/plugins/inchan-cc-skills/plugins -name skill-rules.json
   ```

2. **Check keyword matches**:
   - Open relevant `skill-rules.json`
   - Verify keywords and intentPatterns

3. **Check priority**:
   - Only `suggest` enforcement shows suggestions
   - `block` and `warn` are reserved for future use

## Version History

### v2.0.0 (2025-11-21)
- ✅ Separated hooks into standalone plugin
- ✅ Multi-plugin architecture support
- ✅ Updated `${CLAUDE_PLUGIN_ROOT}` path references

### v1.4.0 (2025-11-20)
- Initial hooks implementation

## License

MIT License

## Author

**inchan** - [GitHub](https://github.com/inchan)
