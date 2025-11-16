#!/usr/bin/env python3
"""
Step Validator for Sequential Task Processor

Validates step outputs against configured criteria from config.json.
Performs checks like completeness, consistency, format, and more.

Usage:
    python3 step_validator.py <task_id> <step_name> [--config <config_path>]

Example:
    python3 step_validator.py task_20241111_001 analysis
    python3 step_validator.py task_20241111_001 design --config ../config.json
"""

import argparse
import json
import os
import re
import sys
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Any, Tuple


class StepValidator:
    """Validates step outputs against configured validation rules."""

    def __init__(self, config_path: str = None):
        """Initialize validator with configuration."""
        if config_path is None:
            # Default to config.json in skill root
            script_dir = Path(__file__).parent
            config_path = script_dir.parent / "config.json"

        self.config = self._load_config(config_path)
        self.validation_results = {
            "checks": [],
            "issues": [],
            "passed": True
        }

    def _load_config(self, config_path: Path) -> Dict:
        """Load configuration from config.json."""
        try:
            with open(config_path, 'r') as f:
                return json.load(f)
        except FileNotFoundError:
            print(f"Error: Config file not found at {config_path}")
            sys.exit(1)
        except json.JSONDecodeError as e:
            print(f"Error: Invalid JSON in config file: {e}")
            sys.exit(1)

    def _get_step_config(self, step_name: str) -> Dict:
        """Get configuration for a specific step."""
        for step in self.config.get("default_steps", []):
            if step["name"] == step_name:
                return step

        print(f"Error: Step '{step_name}' not found in config")
        sys.exit(1)

    def _read_artifact(self, artifact_path: Path) -> Tuple[str, Dict]:
        """Read artifact file and extract frontmatter and content."""
        try:
            with open(artifact_path, 'r', encoding='utf-8') as f:
                content = f.read()

            # Extract YAML frontmatter
            frontmatter = {}
            main_content = content

            if content.startswith('---'):
                parts = content.split('---', 2)
                if len(parts) >= 3:
                    frontmatter_text = parts[1].strip()
                    main_content = parts[2].strip()

                    # Parse simple YAML (key: value pairs)
                    for line in frontmatter_text.split('\n'):
                        if ':' in line:
                            key, value = line.split(':', 1)
                            frontmatter[key.strip()] = value.strip().strip('"')

            return main_content, frontmatter

        except FileNotFoundError:
            print(f"Error: Artifact not found at {artifact_path}")
            sys.exit(1)
        except Exception as e:
            print(f"Error reading artifact: {e}")
            sys.exit(1)

    def _check_completeness(self, content: str, required_sections: List[str]) -> bool:
        """Check if all required sections are present."""
        check_name = "completeness"
        missing_sections = []

        for section in required_sections:
            # Look for section headers (## Section Name)
            pattern = rf'^##\s+{re.escape(section)}\s*$'
            if not re.search(pattern, content, re.MULTILINE | re.IGNORECASE):
                missing_sections.append(section)

        passed = len(missing_sections) == 0

        self.validation_results["checks"].append({
            "name": check_name,
            "passed": passed,
            "details": f"Required sections: {len(required_sections)}, Found: {len(required_sections) - len(missing_sections)}"
        })

        if not passed:
            self.validation_results["issues"].append({
                "severity": "error",
                "check": check_name,
                "message": f"Missing required sections: {', '.join(missing_sections)}"
            })
            self.validation_results["passed"] = False

        return passed

    def _check_format(self, content: str, frontmatter: Dict) -> bool:
        """Check if markdown format and frontmatter are correct."""
        check_name = "format"
        issues = []

        # Check frontmatter required fields
        required_frontmatter = ["task_id", "step", "timestamp", "status"]
        for field in required_frontmatter:
            if field not in frontmatter:
                issues.append(f"Missing frontmatter field: {field}")

        # Check if content has proper markdown structure
        if not re.search(r'^#\s+.+', content, re.MULTILINE):
            issues.append("Missing main heading (# Title)")

        passed = len(issues) == 0

        self.validation_results["checks"].append({
            "name": check_name,
            "passed": passed,
            "details": "Markdown structure and frontmatter validation"
        })

        if not passed:
            for issue in issues:
                self.validation_results["issues"].append({
                    "severity": "error",
                    "check": check_name,
                    "message": issue
                })
            self.validation_results["passed"] = False

        return passed

    def _check_min_requirements(self, content: str, min_count: int) -> bool:
        """Check if minimum number of requirements are present."""
        check_name = "min_requirements"

        # Count requirement items (lines starting with FR-, bullets, or numbered items)
        requirement_patterns = [
            r'^\s*[-*]\s+.+',  # Bullet points
            r'^\s*\d+\.\s+.+',  # Numbered lists
            r'FR-\d+',  # Requirement IDs
        ]

        count = 0
        for pattern in requirement_patterns:
            matches = re.findall(pattern, content, re.MULTILINE)
            count = max(count, len(matches))

        passed = count >= min_count

        self.validation_results["checks"].append({
            "name": check_name,
            "passed": passed,
            "details": f"Found {count} requirements, minimum required: {min_count}"
        })

        if not passed:
            self.validation_results["issues"].append({
                "severity": "error",
                "check": check_name,
                "message": f"Insufficient requirements: found {count}, need at least {min_count}"
            })
            self.validation_results["passed"] = False

        return passed

    def _check_consistency(self, content: str, frontmatter: Dict) -> bool:
        """Check consistency between sections and references."""
        check_name = "consistency"
        issues = []

        # Check if Input Summary section references previous step
        if "## Input Summary" in content:
            input_section = re.search(
                r'## Input Summary\s*\n(.+?)(?=\n##|\Z)',
                content,
                re.DOTALL
            )
            if input_section:
                input_text = input_section.group(1).strip()
                if len(input_text) < 50:
                    issues.append("Input Summary is too brief (less than 50 characters)")

        # Check if validation checklist exists and has items
        if "## Validation Checklist" in content:
            checklist = re.findall(r'- \[[ x]\]', content)
            if len(checklist) == 0:
                issues.append("Validation Checklist has no items")

        passed = len(issues) == 0

        self.validation_results["checks"].append({
            "name": check_name,
            "passed": passed,
            "details": "Content consistency validation"
        })

        if not passed:
            for issue in issues:
                self.validation_results["issues"].append({
                    "severity": "warning",
                    "check": check_name,
                    "message": issue
                })
            # Consistency issues are warnings, not failures

        return True  # Don't fail on consistency warnings

    def _check_references_previous_step(self, content: str) -> bool:
        """Check if document references previous step's output."""
        check_name = "references_previous_step"

        # Look for references to previous steps
        references_found = (
            "Input Summary" in content or
            "Source:" in content or
            "Step 1" in content or
            "requirements.md" in content
        )

        passed = references_found

        self.validation_results["checks"].append({
            "name": check_name,
            "passed": passed,
            "details": "Verification of previous step references"
        })

        if not passed:
            self.validation_results["issues"].append({
                "severity": "warning",
                "check": check_name,
                "message": "Document should reference previous step's output"
            })

        return True  # Warning only

    def validate_step(self, task_id: str, step_name: str) -> Dict:
        """Validate a specific step's output."""
        step_config = self._get_step_config(step_name)
        validation_rules = step_config.get("validation", {})

        # Determine artifact path
        cache_dir = Path(self.config["cache_settings"]["cache_directory"])
        task_dir = cache_dir / task_id

        # Get output file name
        output_file = step_config.get("output_file")
        if output_file:
            artifact_path = task_dir / output_file
        else:
            # Try common patterns
            artifact_path = task_dir / f"{step_name}.md"

        # Read artifact
        content, frontmatter = self._read_artifact(artifact_path)

        # Run validation checks based on rules
        if validation_rules.get("completeness_check"):
            required_sections = validation_rules.get("required_sections", [])
            self._check_completeness(content, required_sections)

        if validation_rules.get("format_check"):
            self._check_format(content, frontmatter)

        if "min_requirements" in validation_rules:
            min_count = validation_rules["min_requirements"]
            self._check_min_requirements(content, min_count)

        if validation_rules.get("consistency_check"):
            self._check_consistency(content, frontmatter)

        if validation_rules.get("references_previous_step"):
            self._check_references_previous_step(content)

        # Compile results
        result = {
            "task_id": task_id,
            "step": step_name,
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "status": "passed" if self.validation_results["passed"] else "failed",
            "checks": self.validation_results["checks"],
            "issues": self.validation_results["issues"],
            "recommendation": "proceed" if self.validation_results["passed"] else "retry"
        }

        return result

    def save_validation_log(self, task_id: str, result: Dict):
        """Save validation results to log file."""
        cache_dir = Path(self.config["cache_settings"]["cache_directory"])
        task_dir = cache_dir / task_id
        log_file = task_dir / self.config["logging"]["log_file"]

        # Create directory if it doesn't exist
        task_dir.mkdir(parents=True, exist_ok=True)

        # Load existing log or create new
        if log_file.exists():
            with open(log_file, 'r') as f:
                log_data = json.load(f)
        else:
            log_data = {
                "task_id": task_id,
                "validations": []
            }

        # Append new validation result
        log_data["validations"].append(result)

        # Save log
        with open(log_file, 'w') as f:
            json.dump(log_data, f, indent=2)

        print(f"Validation log updated: {log_file}")


def main():
    """Main entry point for step validator."""
    parser = argparse.ArgumentParser(
        description="Validate step outputs for Sequential Task Processor"
    )
    parser.add_argument("task_id", help="Task ID")
    parser.add_argument("step_name", help="Step name to validate")
    parser.add_argument(
        "--config",
        help="Path to config.json",
        default=None
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Verbose output"
    )

    args = parser.parse_args()

    # Initialize validator
    validator = StepValidator(args.config)

    # Run validation
    print(f"Validating {args.step_name} for task {args.task_id}...")
    result = validator.validate_step(args.task_id, args.step_name)

    # Save to log
    validator.save_validation_log(args.task_id, result)

    # Print results
    print("\n" + "="*60)
    print(f"Validation Result: {result['status'].upper()}")
    print("="*60)

    print(f"\nChecks Run: {len(result['checks'])}")
    for check in result['checks']:
        status = "✅ PASS" if check['passed'] else "❌ FAIL"
        print(f"  {status} - {check['name']}: {check['details']}")

    if result['issues']:
        print(f"\nIssues Found: {len(result['issues'])}")
        for issue in result['issues']:
            severity_icon = "🔴" if issue['severity'] == 'error' else "🟡"
            print(f"  {severity_icon} [{issue['severity'].upper()}] {issue['message']}")

    print(f"\nRecommendation: {result['recommendation'].upper()}")
    print("="*60 + "\n")

    # Exit with appropriate code
    sys.exit(0 if result['status'] == 'passed' else 1)


if __name__ == "__main__":
    main()
