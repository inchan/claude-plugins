"""
System Architect Worker

Specialized worker for designing system architecture and technical specifications.
"""

from typing import Dict, Any, List
from .base_worker import BaseWorker, WorkerStatus


class ArchitectWorker(BaseWorker):
    """
    Worker specialized in system design and architecture.
    """

    def __init__(self):
        super().__init__(
            worker_id="system_architect",
            name="System Architect Worker"
        )

    def execute(self, task: Dict[str, Any], context: Dict[str, Any]) -> Dict[str, Any]:
        """
        Design system architecture and specifications.

        Args:
            task: Should contain:
                - design_type: 'api', 'database', 'component', 'full_architecture'
                - requirements: List of functional requirements
                - constraints: Technical constraints

        Returns:
            Architecture design with specs, diagrams, and decisions
        """
        self.update_status(WorkerStatus.WORKING)
        self.current_task = task

        try:
            design_type = task.get('design_type', 'full_architecture')
            requirements = task.get('requirements', [])

            design_result = {
                'success': True,
                'output': {
                    'design_type': design_type,
                    'architecture': self._design_architecture(requirements, context),
                    'api_specs': self._design_api(requirements, context),
                    'database_schema': self._design_database(requirements, context),
                    'technology_stack': self._select_technologies(requirements, context),
                    'architecture_decisions': self._document_decisions(requirements, context)
                },
                'artifacts': [],
                'next_steps': [
                    'Use Code Developer to implement designed architecture',
                    'Review architecture with stakeholders if in Guided mode'
                ],
                'errors': []
            }

            # Create architecture documentation artifacts
            artifacts = [
                f"architecture_{task.get('task_id', 'unknown')}.md",
                f"api_spec_{task.get('task_id', 'unknown')}.yaml",
                f"database_schema_{task.get('task_id', 'unknown')}.sql"
            ]
            design_result['artifacts'] = artifacts
            for artifact in artifacts:
                self.record_artifact(artifact)

            self.record_task_completion(task, design_result)
            self.update_status(WorkerStatus.COMPLETED)

            return design_result

        except Exception as e:
            self.update_status(WorkerStatus.FAILED)
            return {
                'success': False,
                'output': None,
                'artifacts': [],
                'next_steps': ['Review error and retry design'],
                'errors': [str(e)]
            }

    def validate_task(self, task: Dict[str, Any]) -> tuple[bool, str]:
        """Validate if task is appropriate for architecture design."""
        if 'design_type' not in task and 'requirements' not in task:
            return False, "Task must include 'design_type' or 'requirements'"
        return True, ""

    def get_capabilities(self) -> List[str]:
        """Return architect capabilities."""
        return [
            'component_design',
            'api_specification',
            'database_modeling',
            'architecture_decision_records',
            'technology_selection',
            'system_diagram_creation'
        ]

    def get_triggers(self) -> List[str]:
        """Return triggers that activate architect."""
        return [
            'new_project',
            'architecture_change',
            'system_design',
            'api_design',
            'database_design'
        ]

    def _design_architecture(self, requirements: List[str], context: Dict[str, Any]) -> Dict[str, Any]:
        """Design overall system architecture."""
        return {
            'pattern': 'layered',  # or 'microservices', 'mvc', etc.
            'components': [],
            'layers': ['presentation', 'business', 'data'],
            'communication': 'REST'
        }

    def _design_api(self, requirements: List[str], context: Dict[str, Any]) -> Dict[str, Any]:
        """Design API endpoints and contracts."""
        return {
            'endpoints': [],
            'authentication': 'JWT',
            'data_format': 'JSON',
            'versioning': 'URL-based'
        }

    def _design_database(self, requirements: List[str], context: Dict[str, Any]) -> Dict[str, Any]:
        """Design database schema."""
        return {
            'database_type': 'relational',
            'tables': [],
            'relationships': [],
            'indexes': []
        }

    def _select_technologies(self, requirements: List[str], context: Dict[str, Any]) -> Dict[str, Any]:
        """Select appropriate technology stack."""
        return {
            'backend': 'Node.js/Express',
            'frontend': 'React',
            'database': 'PostgreSQL',
            'deployment': 'Docker'
        }

    def _document_decisions(self, requirements: List[str], context: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Document architecture decision records (ADRs)."""
        return []
