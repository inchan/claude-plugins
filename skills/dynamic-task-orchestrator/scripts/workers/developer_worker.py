"""
Code Developer Worker

Specialized worker for implementing features, fixing bugs, and writing production code.
"""

from typing import Dict, Any, List
from .base_worker import BaseWorker, WorkerStatus


class DeveloperWorker(BaseWorker):
    """
    Worker specialized in code implementation.
    """

    def __init__(self):
        super().__init__(
            worker_id="code_developer",
            name="Code Developer Worker"
        )

    def execute(self, task: Dict[str, Any], context: Dict[str, Any]) -> Dict[str, Any]:
        """
        Implement features or fix bugs.

        Args:
            task: Should contain:
                - task_type: 'feature', 'bug_fix', 'integration', 'refactor'
                - specification: Detailed implementation spec
                - files_to_modify: Optional list of files to change

        Returns:
            Implementation results with code and integration notes
        """
        self.update_status(WorkerStatus.WORKING)
        self.current_task = task

        try:
            task_type = task.get('task_type', 'feature')
            specification = task.get('specification', {})

            implementation_result = {
                'success': True,
                'output': {
                    'task_type': task_type,
                    'files_created': self._implement_code(specification, context),
                    'files_modified': [],
                    'integration_points': self._identify_integrations(specification, context),
                    'dependencies_added': []
                },
                'artifacts': [],
                'next_steps': [
                    'Use Test Engineer to create tests for this implementation',
                    'Use Code Reviewer for quality check (if available)'
                ],
                'errors': []
            }

            # Record code artifacts
            files_created = implementation_result['output']['files_created']
            implementation_result['artifacts'] = files_created
            for file_path in files_created:
                self.record_artifact(file_path)

            self.record_task_completion(task, implementation_result)
            self.update_status(WorkerStatus.COMPLETED)

            return implementation_result

        except Exception as e:
            self.update_status(WorkerStatus.FAILED)
            return {
                'success': False,
                'output': None,
                'artifacts': [],
                'next_steps': ['Review error and retry implementation'],
                'errors': [str(e)]
            }

    def validate_task(self, task: Dict[str, Any]) -> tuple[bool, str]:
        """Validate if task is appropriate for development."""
        if 'specification' not in task and 'task_type' not in task:
            return False, "Task must include 'specification' or 'task_type'"
        return True, ""

    def get_capabilities(self) -> List[str]:
        """Return developer capabilities."""
        return [
            'feature_implementation',
            'bug_fixing',
            'integration',
            'code_review',
            'refactoring',
            'dependency_management'
        ]

    def get_triggers(self) -> List[str]:
        """Return triggers that activate developer."""
        return [
            'implementation_needed',
            'code_generation',
            'bug_fix',
            'feature_request',
            'integration_task'
        ]

    def _implement_code(self, specification: Dict[str, Any], context: Dict[str, Any]) -> List[str]:
        """Implement code based on specification."""
        # Implementation would use Write/Edit tools to create actual code
        return []  # List of file paths created

    def _identify_integrations(self, specification: Dict[str, Any], context: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Identify integration points with other components."""
        return []
