#!/usr/bin/env python3
"""
Command Validation Script

Validates slash command markdown files for correct YAML frontmatter and structure.
"""

import argparse
import re
import sys
from pathlib import Path


OPTIONAL_FIELDS = ['allowed-tools', 'argument-hint', 'description', 'model', 'disable-model-invocation']

# Common Claude Code tools
KNOWN_TOOLS = [
    'Read', 'Write', 'Edit', 'Bash', 'Grep', 'Glob', 'Task',
    'WebFetch', 'WebSearch', 'TodoWrite', 'AskUserQuestion',
    'Skill', 'SlashCommand', 'NotebookEdit', 'BashOutput', 'KillShell',
    'ExitPlanMode', 'ListMcpResourcesTool', 'ReadMcpResourceTool'
]


class ValidationError:
    def __init__(self, severity, message):
        self.severity = severity  # 'error' or 'warning'
        self.message = message


def parse_yaml_frontmatter(content):
    """Extract and parse YAML frontmatter."""
    if not content.strip():
        return {}, None  # Empty file, no frontmatter is OK

    # Frontmatter is optional for commands
    if not content.startswith('---'):
        return {}, None  # No frontmatter is OK

    parts = content.split('---', 2)
    if len(parts) < 3:
        return None, ValidationError('error', 'YAML frontmatter not properly closed with ---')

    frontmatter = parts[1].strip()
    yaml_dict = {}

    for line in frontmatter.split('\n'):
        line = line.strip()
        if not line or line.startswith('#'):
            continue

        if ':' not in line:
            continue

        key, value = line.split(':', 1)
        key = key.strip()
        value = value.strip()

        yaml_dict[key] = value

    return yaml_dict, None


def validate_command_name(filename):
    """Validate command name (derived from filename)."""
    errors = []

    # Remove .md extension
    name = filename[:-3] if filename.endswith('.md') else filename

    # Check for lowercase + hyphens only
    if not re.match(r'^[a-z][a-z0-9-]*$', name):
        errors.append(ValidationError('error', f'Command name (filename) must use lowercase letters, numbers, and hyphens only. Got: "{name}"'))

    # Check for valid length
    if len(name) < 2:
        errors.append(ValidationError('warning', f'Command name is very short: "{name}"'))
    if len(name) > 50:
        errors.append(ValidationError('warning', f'Command name is very long: "{name}"'))

    # Check for proper naming convention
    if name.startswith('-') or name.endswith('-'):
        errors.append(ValidationError('error', 'Command name cannot start or end with hyphen'))

    if '--' in name:
        errors.append(ValidationError('warning', 'Command name contains consecutive hyphens'))

    return errors


def validate_description(description):
    """Validate description field."""
    errors = []

    if not description:
        return errors  # Optional field

    # Remove quotes if present
    description = description.strip('"\'')

    if len(description) < 5:
        errors.append(ValidationError('warning', f'Description is too short ({len(description)} chars). Should be at least 5 characters.'))

    if len(description) > 200:
        errors.append(ValidationError('warning', f'Description is very long ({len(description)} chars). Consider keeping it under 200 characters.'))

    return errors


def validate_allowed_tools(tools_str):
    """Validate allowed-tools field."""
    errors = []

    if not tools_str:
        return errors  # Optional field

    # Remove quotes
    tools_str = tools_str.strip('"\'')

    # Check for tool patterns like "Bash(git:*)" or just "Bash"
    tool_patterns = [t.strip() for t in tools_str.split(',')]

    for pattern in tool_patterns:
        # Extract base tool name (before parenthesis if any)
        base_tool = pattern.split('(')[0].strip()

        if base_tool and base_tool not in KNOWN_TOOLS:
            errors.append(ValidationError('warning', f'Unknown tool: "{base_tool}". Known tools: {", ".join(KNOWN_TOOLS)}'))

    return errors


def validate_argument_hint(hint):
    """Validate argument-hint field."""
    errors = []

    if not hint:
        return errors  # Optional field

    hint = hint.strip('"\'')

    # Should be short and in brackets
    if not (hint.startswith('[') and hint.endswith(']')):
        errors.append(ValidationError('warning', f'Argument hint should be in brackets like "[file]" or "[message]". Got: "{hint}"'))

    return errors


def validate_model(model):
    """Validate model field."""
    errors = []

    if not model:
        return errors  # Optional field

    model = model.strip('"\'')

    # Model can be a specific model ID or shorthand
    # Just warn if it looks unusual
    valid_shorthands = ['sonnet', 'opus', 'haiku']
    if model not in valid_shorthands and not model.startswith('claude-'):
        errors.append(ValidationError('warning', f'Model value looks unusual: "{model}". Expected shorthand (sonnet/opus/haiku) or full model ID (claude-...)'))

    return errors


def validate_disable_model_invocation(value):
    """Validate disable-model-invocation field."""
    errors = []

    if not value:
        return errors  # Optional field

    value = value.strip('"\'').lower()

    if value not in ['true', 'false']:
        errors.append(ValidationError('error', f'disable-model-invocation must be true or false. Got: "{value}"'))

    return errors


def validate_command_body(body):
    """Validate command body content."""
    errors = []

    if len(body.strip()) < 10:
        errors.append(ValidationError('warning', 'Command body is very short. Add instructions or prompts.'))

    if 'TODO' in body:
        errors.append(ValidationError('warning', 'Command contains TODO items. Complete before using.'))

    # Check for argument placeholders
    if '$ARGUMENTS' in body:
        # Good practice
        pass

    # Check for positional arguments
    positional_args = re.findall(r'\$\d+', body)
    if positional_args:
        # Verify they're in order
        arg_numbers = sorted([int(arg[1:]) for arg in positional_args])
        if arg_numbers != list(range(1, len(arg_numbers) + 1)):
            errors.append(ValidationError('warning', f'Positional arguments should be sequential starting from $1. Found: {positional_args}'))

    # Check for bash execution syntax
    bash_executions = re.findall(r'!\s*\w+', body)
    if bash_executions and 'allowed-tools' not in body:
        errors.append(ValidationError('warning', 'Command uses !bash syntax but no allowed-tools specified in frontmatter'))

    # Check for file references
    file_refs = re.findall(r'@[\w/.-]+', body)
    if file_refs:
        # Just informational, this is fine
        pass

    return errors


def validate_command_file(file_path):
    """Validate a command markdown file."""
    errors = []

    # Check file exists
    path = Path(file_path)
    if not path.exists():
        return [ValidationError('error', f'File not found: {file_path}')]

    # Check file extension
    if path.suffix != '.md':
        errors.append(ValidationError('error', f'Command file must have .md extension. Got: {path.suffix}'))
        return errors

    # Validate filename (becomes command name)
    errors.extend(validate_command_name(path.name))

    # Read file content
    try:
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception as e:
        return [ValidationError('error', f'Failed to read file: {e}')]

    # Parse YAML frontmatter
    yaml_dict, error = parse_yaml_frontmatter(content)
    if error:
        return [error]

    # Validate individual fields
    if 'description' in yaml_dict:
        errors.extend(validate_description(yaml_dict['description']))

    if 'allowed-tools' in yaml_dict:
        errors.extend(validate_allowed_tools(yaml_dict['allowed-tools']))

    if 'argument-hint' in yaml_dict:
        errors.extend(validate_argument_hint(yaml_dict['argument-hint']))

    if 'model' in yaml_dict:
        errors.extend(validate_model(yaml_dict['model']))

    if 'disable-model-invocation' in yaml_dict:
        errors.extend(validate_disable_model_invocation(yaml_dict['disable-model-invocation']))

    # Check for unknown fields
    for key in yaml_dict:
        if key not in OPTIONAL_FIELDS:
            errors.append(ValidationError('warning', f'Unknown frontmatter field: {key}'))

    # Validate content after frontmatter
    if content.startswith('---'):
        parts = content.split('---', 2)
        if len(parts) >= 3:
            body = parts[2]
            errors.extend(validate_command_body(body))
    else:
        # No frontmatter, entire content is body
        errors.extend(validate_command_body(content))

    return errors


def print_validation_results(file_path, errors):
    """Print validation results."""
    if not errors:
        print(f"✅ {file_path}")
        print("   All validation checks passed!")
        return True

    has_errors = any(e.severity == 'error' for e in errors)
    has_warnings = any(e.severity == 'warning' for e in errors)

    if has_errors:
        print(f"❌ {file_path}")
    elif has_warnings:
        print(f"⚠️  {file_path}")

    # Print errors first
    for error in errors:
        if error.severity == 'error':
            print(f"   ❌ ERROR: {error.message}")

    # Then warnings
    for error in errors:
        if error.severity == 'warning':
            print(f"   ⚠️  WARNING: {error.message}")

    return not has_errors


def main():
    parser = argparse.ArgumentParser(
        description='Validate Claude Code slash command markdown files',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Validate a single command
  python3 validate_command.py .claude/commands/optimize.md

  # Validate all project commands
  python3 validate_command.py .claude/commands/*.md

  # Validate all user commands
  python3 validate_command.py ~/.claude/commands/*.md

  # Validate with strict mode (warnings as errors)
  python3 validate_command.py --strict .claude/commands/*.md
"""
    )

    parser.add_argument('files', nargs='+', help='Command file(s) to validate')
    parser.add_argument('--strict', action='store_true', help='Treat warnings as errors')

    args = parser.parse_args()

    all_valid = True

    for file_path in args.files:
        errors = validate_command_file(file_path)

        if args.strict and any(e.severity == 'warning' for e in errors):
            # Convert warnings to errors in strict mode
            for error in errors:
                if error.severity == 'warning':
                    error.severity = 'error'

        is_valid = print_validation_results(file_path, errors)
        if not is_valid:
            all_valid = False

        print()  # Blank line between files

    if all_valid:
        print("✅ All validations passed!")
        sys.exit(0)
    else:
        print("❌ Validation failed!")
        sys.exit(1)


if __name__ == '__main__':
    main()
