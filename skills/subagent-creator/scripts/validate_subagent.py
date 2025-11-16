#!/usr/bin/env python3
"""
Subagent Validation Script

Validates subagent markdown files for correct YAML frontmatter and structure.
"""

import argparse
import re
import sys
from pathlib import Path


REQUIRED_FIELDS = ['name', 'description']
OPTIONAL_FIELDS = ['tools', 'model']
VALID_MODELS = ['sonnet', 'opus', 'haiku', 'inherit']

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
    if not content.startswith('---'):
        return None, ValidationError('error', 'File must start with YAML frontmatter (---)')

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


def validate_name(name):
    """Validate subagent name format."""
    errors = []

    if not name:
        errors.append(ValidationError('error', 'Missing required field: name'))
        return errors

    # Check for lowercase + hyphens only
    if not re.match(r'^[a-z][a-z0-9-]*$', name):
        errors.append(ValidationError('error', f'Name must use lowercase letters, numbers, and hyphens only. Got: "{name}"'))

    # Check for valid length
    if len(name) < 3:
        errors.append(ValidationError('warning', f'Name is very short: "{name}"'))
    if len(name) > 50:
        errors.append(ValidationError('warning', f'Name is very long: "{name}"'))

    # Check for proper naming convention
    if name.startswith('-') or name.endswith('-'):
        errors.append(ValidationError('error', 'Name cannot start or end with hyphen'))

    if '--' in name:
        errors.append(ValidationError('warning', 'Name contains consecutive hyphens'))

    return errors


def validate_description(description):
    """Validate description field."""
    errors = []

    if not description:
        errors.append(ValidationError('error', 'Missing required field: description'))
        return errors

    # Remove quotes if present
    description = description.strip('"\'')

    if len(description) < 10:
        errors.append(ValidationError('warning', f'Description is too short ({len(description)} chars). Should be at least 10 characters.'))

    if len(description) > 200:
        errors.append(ValidationError('warning', f'Description is very long ({len(description)} chars). Consider keeping it under 200 characters.'))

    # Check for action-oriented language
    action_words = ['when', 'for', 'to', 'helps', 'handles', 'manages', 'reviews', 'implements', 'debugs', 'tests']
    if not any(word in description.lower() for word in action_words):
        errors.append(ValidationError('warning', 'Description should be action-oriented (e.g., "Use when...", "For handling...", "Helps to...")'))

    return errors


def validate_tools(tools_str):
    """Validate tools field."""
    errors = []

    if not tools_str:
        return errors  # Optional field

    # Remove quotes and split
    tools_str = tools_str.strip('"\'')
    tools = [t.strip() for t in tools_str.split(',')]

    for tool in tools:
        if tool not in KNOWN_TOOLS:
            errors.append(ValidationError('warning', f'Unknown tool: "{tool}". Known tools: {", ".join(KNOWN_TOOLS)}'))

    if len(tools) == 0:
        errors.append(ValidationError('warning', 'Tools field is empty. Either specify tools or omit the field to inherit all tools.'))

    return errors


def validate_model(model):
    """Validate model field."""
    errors = []

    if not model:
        return errors  # Optional field

    model = model.strip('"\'')

    if model not in VALID_MODELS:
        errors.append(ValidationError('error', f'Invalid model: "{model}". Valid options: {", ".join(VALID_MODELS)}'))

    return errors


def validate_subagent_file(file_path):
    """Validate a subagent markdown file."""
    errors = []

    # Check file exists
    path = Path(file_path)
    if not path.exists():
        return [ValidationError('error', f'File not found: {file_path}')]

    # Check file extension
    if path.suffix != '.md':
        errors.append(ValidationError('warning', f'File should have .md extension. Got: {path.suffix}'))

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

    # Validate required fields
    for field in REQUIRED_FIELDS:
        if field not in yaml_dict:
            errors.append(ValidationError('error', f'Missing required field: {field}'))

    # Validate individual fields
    if 'name' in yaml_dict:
        errors.extend(validate_name(yaml_dict['name']))

    if 'description' in yaml_dict:
        errors.extend(validate_description(yaml_dict['description']))

    if 'tools' in yaml_dict:
        errors.extend(validate_tools(yaml_dict['tools']))

    if 'model' in yaml_dict:
        errors.extend(validate_model(yaml_dict['model']))

    # Check for unknown fields
    all_fields = REQUIRED_FIELDS + OPTIONAL_FIELDS
    for key in yaml_dict:
        if key not in all_fields:
            errors.append(ValidationError('warning', f'Unknown field: {key}'))

    # Validate content after frontmatter
    parts = content.split('---', 2)
    if len(parts) >= 3:
        body = parts[2].strip()
        if len(body) < 20:
            errors.append(ValidationError('warning', 'Subagent body is very short. Add detailed instructions.'))

        if 'TODO' in body:
            errors.append(ValidationError('warning', 'Subagent contains TODO items. Complete before using.'))

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
        description='Validate Claude Code subagent markdown files',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Validate a single subagent
  python validate_subagent.py .claude/agents/my-reviewer.md

  # Validate all project subagents
  python validate_subagent.py .claude/agents/*.md

  # Validate all user subagents
  python validate_subagent.py ~/.claude/agents/*.md
"""
    )

    parser.add_argument('files', nargs='+', help='Subagent file(s) to validate')
    parser.add_argument('--strict', action='store_true', help='Treat warnings as errors')

    args = parser.parse_args()

    all_valid = True

    for file_path in args.files:
        errors = validate_subagent_file(file_path)

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
