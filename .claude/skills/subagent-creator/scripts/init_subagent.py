#!/usr/bin/env python3
"""
Subagent Initialization Script

Creates a new subagent file with proper YAML frontmatter and optional template.
"""

import argparse
import os
import sys
from pathlib import Path


AVAILABLE_TEMPLATES = {
    'basic': 'Basic empty template',
    'code-reviewer': 'Code review specialist',
    'debugger': 'Debugging and error resolution',
    'architect': 'System design and architecture',
    'implementer': 'Code implementation',
    'researcher': 'Research and exploration',
    'tester': 'Testing and validation'
}


def get_template_path(template_name):
    """Get the full path to a template file."""
    script_dir = Path(__file__).parent
    skill_dir = script_dir.parent
    template_path = skill_dir / 'assets' / 'templates' / f'{template_name}.md'
    return template_path


def create_subagent(name, description, tools, model, location, template):
    """Create a new subagent file."""

    # Validate name format (lowercase + hyphens only)
    if not all(c.islower() or c == '-' for c in name):
        print(f"❌ Error: Subagent name must use lowercase letters and hyphens only")
        print(f"   Got: '{name}'")
        return False

    # Determine save location
    if location == 'project':
        agents_dir = Path('.claude/agents')
    else:  # user
        agents_dir = Path.home() / '.claude' / 'agents'

    # Create directory if it doesn't exist
    agents_dir.mkdir(parents=True, exist_ok=True)

    # Full file path
    file_path = agents_dir / f'{name}.md'

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
    frontmatter = f"""---
name: {name}
description: {description}"""

    if tools:
        frontmatter += f"\ntools: {tools}"

    if model:
        frontmatter += f"\nmodel: {model}"

    frontmatter += "\n---\n"

    # Create file content
    if template_content:
        content = frontmatter + "\n" + template_content + "\n"
    else:
        content = frontmatter + "\n# System Prompt\n\nTODO: Add your subagent's instructions here.\n\n## Role\n\n## Responsibilities\n\n## Guidelines\n\n"

    # Write file
    with open(file_path, 'w') as f:
        f.write(content)

    print(f"✅ Created subagent: {file_path}")
    print(f"\n📋 Configuration:")
    print(f"   Name: {name}")
    print(f"   Description: {description}")
    if tools:
        print(f"   Tools: {tools}")
    if model:
        print(f"   Model: {model}")
    if template:
        print(f"   Template: {template}")

    print(f"\n📝 Next steps:")
    print(f"   1. Edit the subagent file to customize the system prompt")
    print(f"   2. Test with: /agents command in Claude Code")
    print(f"   3. Validate with: python validate_subagent.py {file_path}")

    return True


def main():
    parser = argparse.ArgumentParser(
        description='Initialize a new Claude Code subagent',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=f"""
Examples:
  # Create basic subagent
  python init_subagent.py my-reviewer "Reviews code for quality" --location project

  # Create with specific tools
  python init_subagent.py my-tester "Runs and validates tests" --tools "Read,Bash,Grep" --location user

  # Create from template
  python init_subagent.py my-debugger "Finds and fixes bugs" --template debugger

Available templates:
{chr(10).join(f'  - {name}: {desc}' for name, desc in AVAILABLE_TEMPLATES.items())}
"""
    )

    parser.add_argument('name', help='Subagent name (lowercase + hyphens)')
    parser.add_argument('description', help='Description of when to invoke this subagent')
    parser.add_argument('--tools', help='Comma-separated tool list (optional)')
    parser.add_argument('--model', choices=['sonnet', 'opus', 'haiku', 'inherit'],
                       help='Model to use (optional)')
    parser.add_argument('--location', choices=['project', 'user'], default='project',
                       help='Where to create the subagent (default: project)')
    parser.add_argument('--template', choices=list(AVAILABLE_TEMPLATES.keys()),
                       help='Template to use (optional)')

    args = parser.parse_args()

    success = create_subagent(
        args.name,
        args.description,
        args.tools,
        args.model,
        args.location,
        args.template
    )

    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()
