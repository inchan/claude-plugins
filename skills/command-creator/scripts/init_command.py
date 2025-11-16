#!/usr/bin/env python3
"""
Command Initialization Script

Creates a new slash command file with proper YAML frontmatter and optional template.
"""

import argparse
import os
import sys
from pathlib import Path


AVAILABLE_TEMPLATES = {
    'basic': 'Basic empty template',
    'simple-action': 'Single action execution (format, lint, etc.)',
    'workflow': 'Multi-step workflow process',
    'prompt-expansion': 'Long prompt abbreviation',
    'agent-caller': 'Subagent invocation command',
    'full-power': 'Complex multi-feature command'
}


def get_template_path(template_name):
    """Get the full path to a template file."""
    script_dir = Path(__file__).parent
    skill_dir = script_dir.parent
    template_path = skill_dir / 'assets' / 'templates' / f'{template_name}.md'
    return template_path


def create_command(name, description, location, template, namespace, allowed_tools,
                   argument_hint, model, disable_invocation):
    """Create a new slash command file."""

    # Validate name format (lowercase + hyphens only, no extension)
    if name.endswith('.md'):
        name = name[:-3]

    if not all(c.islower() or c == '-' for c in name):
        print(f"❌ Error: Command name must use lowercase letters and hyphens only")
        print(f"   Got: '{name}'")
        return False

    # Determine save location
    if location == 'project':
        commands_dir = Path('.claude/commands')
    else:  # user
        commands_dir = Path.home() / '.claude' / 'commands'

    # Add namespace subdirectory if specified
    if namespace:
        commands_dir = commands_dir / namespace

    # Create directory if it doesn't exist
    commands_dir.mkdir(parents=True, exist_ok=True)

    # Full file path
    file_path = commands_dir / f'{name}.md'

    # Check if file already exists
    if file_path.exists():
        response = input(f"⚠️  File already exists: {file_path}\n   Overwrite? (y/N): ")
        if response.lower() != 'y':
            print("❌ Cancelled")
            return False

    # Load template if specified
    template_content = ""
    if template:
        template_path = get_template_path(template)
        if template_path.exists():
            with open(template_path, 'r') as f:
                # Skip YAML frontmatter from template
                content = f.read()
                if content.startswith('---'):
                    parts = content.split('---', 2)
                    if len(parts) >= 3:
                        template_content = parts[2].strip()
                else:
                    template_content = content.strip()
        else:
            print(f"⚠️  Warning: Template '{template}' not found, using basic template")

    # Build YAML frontmatter
    frontmatter_parts = []

    if description:
        frontmatter_parts.append(f"description: {description}")

    if allowed_tools:
        frontmatter_parts.append(f"allowed-tools: {allowed_tools}")

    if argument_hint:
        frontmatter_parts.append(f"argument-hint: {argument_hint}")

    if model:
        frontmatter_parts.append(f"model: {model}")

    if disable_invocation:
        frontmatter_parts.append("disable-model-invocation: true")

    # Only add frontmatter if there are fields to include
    if frontmatter_parts:
        frontmatter = "---\n" + "\n".join(frontmatter_parts) + "\n---\n"
    else:
        frontmatter = ""

    # Create file content
    if template_content:
        content = frontmatter + "\n" + template_content + "\n"
    else:
        # Basic template
        content = frontmatter + "\n# Command: /" + name + "\n\nTODO: Add your command instructions here.\n\n"

    # Write file
    with open(file_path, 'w') as f:
        f.write(content)

    print(f"✅ Created slash command: {file_path}")
    print(f"\n📋 Configuration:")
    print(f"   Command: /{name}")
    if namespace:
        print(f"   Namespace: {namespace}")
    if description:
        print(f"   Description: {description}")
    if allowed_tools:
        print(f"   Allowed tools: {allowed_tools}")
    if argument_hint:
        print(f"   Argument hint: {argument_hint}")
    if model:
        print(f"   Model: {model}")
    if template:
        print(f"   Template: {template}")

    print(f"\n📝 Next steps:")
    print(f"   1. Edit the command file to customize the prompt")
    print(f"   2. Test with: /{name} in Claude Code")
    print(f"   3. Validate with: python3 validate_command.py {file_path}")

    return True


def main():
    parser = argparse.ArgumentParser(
        description='Initialize a new Claude Code slash command',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=f"""
Examples:
  # Create basic command
  python3 init_command.py optimize "Optimize code for performance" --location project

  # Create with specific tools and arguments
  python3 init_command.py fix-issue "Find and fix issue #$ARGUMENTS" \\
    --allowed-tools "Read,Edit,Bash" --argument-hint "[issue-number]" --location project

  # Create from template in a namespace
  python3 init_command.py review "Review code changes" \\
    --template workflow --namespace dev --location project

  # Create command that calls a subagent
  python3 init_command.py security-scan "Run security analysis" \\
    --template agent-caller --location user

Available templates:
{chr(10).join(f'  - {name}: {desc}' for name, desc in AVAILABLE_TEMPLATES.items())}
"""
    )

    parser.add_argument('name', help='Command name (lowercase + hyphens, without /)')
    parser.add_argument('description', nargs='?', help='Brief description of the command')
    parser.add_argument('--location', choices=['project', 'user'], default='project',
                       help='Where to create the command (default: project)')
    parser.add_argument('--template', choices=list(AVAILABLE_TEMPLATES.keys()),
                       help='Template to use (optional)')
    parser.add_argument('--namespace', help='Subdirectory for command organization (optional)')
    parser.add_argument('--allowed-tools', help='Allowed tools (e.g., "Bash, Read, Edit")')
    parser.add_argument('--argument-hint', help='Hint for command arguments (e.g., "[file]")')
    parser.add_argument('--model', help='Model override (e.g., claude-3-5-haiku-20241022)')
    parser.add_argument('--disable-invocation', action='store_true',
                       help='Disable automatic SlashCommand tool invocation')

    args = parser.parse_args()

    success = create_command(
        args.name,
        args.description,
        args.location,
        args.template,
        args.namespace,
        args.allowed_tools,
        args.argument_hint,
        args.model,
        args.disable_invocation
    )

    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()
