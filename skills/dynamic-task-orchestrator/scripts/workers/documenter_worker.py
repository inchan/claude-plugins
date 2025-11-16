"""
Documentation Writer Worker

Specialized worker for generating clear, comprehensive documentation.
"""

from typing import Dict, Any, List
from .base_worker import BaseWorker, WorkerStatus


class DocumenterWorker(BaseWorker):
    """
    Worker specialized in documentation generation.
    """

    def __init__(self):
        super().__init__(
            worker_id="doc_writer",
            name="Documentation Writer Worker"
        )

    def execute(self, task: Dict[str, Any], context: Dict[str, Any]) -> Dict[str, Any]:
        """
        Generate documentation.

        Args:
            task: Should contain:
                - doc_type: 'api', 'user_guide', 'readme', 'code_comments'
                - target: What to document (code, API, features)

        Returns:
            Documentation files and content
        """
        self.update_status(WorkerStatus.WORKING)
        self.current_task = task

        try:
            doc_type = task.get('doc_type', 'readme')
            target = task.get('target', {})

            doc_result = {
                'success': True,
                'output': {
                    'doc_type': doc_type,
                    'documentation_created': self._create_documentation(doc_type, target, context),
                    'api_reference': self._generate_api_docs(target, context) if doc_type == 'api' else None,
                    'user_guide': self._generate_user_guide(target, context) if doc_type == 'user_guide' else None,
                    'code_comments_added': self._add_code_comments(target, context) if doc_type == 'code_comments' else []
                },
                'artifacts': [],
                'next_steps': [
                    'Review documentation for clarity and completeness',
                    'Update documentation when features change'
                ],
                'errors': []
            }

            # Record documentation artifacts
            doc_files = doc_result['output']['documentation_created']
            doc_result['artifacts'] = doc_files
            for doc_file in doc_files:
                self.record_artifact(doc_file)

            self.record_task_completion(task, doc_result)
            self.update_status(WorkerStatus.COMPLETED)

            return doc_result

        except Exception as e:
            self.update_status(WorkerStatus.FAILED)
            return {
                'success': False,
                'output': None,
                'artifacts': [],
                'next_steps': ['Review error and retry documentation'],
                'errors': [str(e)]
            }

    def validate_task(self, task: Dict[str, Any]) -> tuple[bool, str]:
        """Validate if task is appropriate for documentation."""
        if 'doc_type' not in task and 'target' not in task:
            return False, "Task must include 'doc_type' or 'target'"
        return True, ""

    def get_capabilities(self) -> List[str]:
        """Return documenter capabilities."""
        return [
            'api_documentation',
            'user_guides',
            'code_comments',
            'readme_creation',
            'tutorial_writing',
            'troubleshooting_guides'
        ]

    def get_triggers(self) -> List[str]:
        """Return triggers that activate documenter."""
        return [
            'feature_complete',
            'documentation_gap',
            'api_change',
            'release',
            'onboarding_needed'
        ]

    def _create_documentation(self, doc_type: str, target: Dict[str, Any], context: Dict[str, Any]) -> List[str]:
        """Create documentation files."""
        # Implementation would use Write tool to create markdown/other docs
        return []  # List of documentation file paths

    def _generate_api_docs(self, target: Dict[str, Any], context: Dict[str, Any]) -> Dict[str, Any]:
        """Generate API reference documentation."""
        return {
            'endpoints': [],
            'schemas': [],
            'examples': []
        }

    def _generate_user_guide(self, target: Dict[str, Any], context: Dict[str, Any]) -> Dict[str, Any]:
        """Generate user guide documentation."""
        return {
            'installation': '',
            'quickstart': '',
            'usage': '',
            'troubleshooting': ''
        }

    def _add_code_comments(self, target: Dict[str, Any], context: Dict[str, Any]) -> List[str]:
        """Add inline code comments."""
        # Implementation would use Edit tool to add comments to code
        return []  # List of files with comments added
