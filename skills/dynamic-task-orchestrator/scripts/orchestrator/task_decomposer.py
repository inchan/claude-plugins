"""
Task Decomposer

Algorithms for decomposing complex projects into manageable subtasks.
"""

from typing import Dict, Any, List


class TaskDecomposer:
    """
    Decomposes complex projects into worker-specific subtasks.
    """

    @staticmethod
    def decompose_project(project: Dict[str, Any]) -> List[Dict[str, Any]]:
        """
        Break down project into atomic subtasks.

        Args:
            project: Project definition

        Returns:
            List of subtask definitions
        """
        subtasks = []
        project_type = project.get('type', 'unknown')
        requirements = project.get('requirements', [])

        # Decompose based on project type
        if project_type == 'web_app':
            subtasks = TaskDecomposer._decompose_web_app(project, requirements)
        elif project_type == 'api':
            subtasks = TaskDecomposer._decompose_api(project, requirements)
        elif project_type == 'cli_tool':
            subtasks = TaskDecomposer._decompose_cli(project, requirements)
        elif project_type == 'library':
            subtasks = TaskDecomposer._decompose_library(project, requirements)
        elif project_type == 'full_stack':
            subtasks = TaskDecomposer._decompose_full_stack(project, requirements)
        else:
            # Generic decomposition
            subtasks = TaskDecomposer._decompose_generic(project, requirements)

        return subtasks

    @staticmethod
    def _decompose_web_app(project: Dict[str, Any], requirements: List[str]) -> List[Dict[str, Any]]:
        """Decompose web application project."""
        return [
            {'phase': 'analysis', 'worker': 'code_analyzer', 'if': 'existing_code' in project},
            {'phase': 'design', 'worker': 'architect', 'tasks': ['frontend_architecture', 'backend_architecture', 'database_design']},
            {'phase': 'implementation', 'worker': 'developer', 'tasks': ['backend_api', 'frontend_components', 'integration']},
            {'phase': 'testing', 'worker': 'tester', 'tasks': ['unit_tests', 'integration_tests']},
            {'phase': 'documentation', 'worker': 'documenter', 'tasks': ['api_docs', 'user_guide', 'readme']},
        ]

    @staticmethod
    def _decompose_api(project: Dict[str, Any], requirements: List[str]) -> List[Dict[str, Any]]:
        """Decompose API project."""
        return [
            {'phase': 'analysis', 'worker': 'code_analyzer', 'if': 'existing_code' in project},
            {'phase': 'design', 'worker': 'architect', 'tasks': ['api_specification', 'data_models', 'authentication']},
            {'phase': 'implementation', 'worker': 'developer', 'tasks': ['endpoints', 'middleware', 'error_handling']},
            {'phase': 'testing', 'worker': 'tester', 'tasks': ['endpoint_tests', 'integration_tests']},
            {'phase': 'documentation', 'worker': 'documenter', 'tasks': ['api_reference', 'openapi_spec']},
        ]

    @staticmethod
    def _decompose_cli(project: Dict[str, Any], requirements: List[str]) -> List[Dict[str, Any]]:
        """Decompose CLI tool project."""
        return [
            {'phase': 'design', 'worker': 'architect', 'tasks': ['command_structure', 'argument_parsing']},
            {'phase': 'implementation', 'worker': 'developer', 'tasks': ['commands', 'utilities', 'cli_interface']},
            {'phase': 'testing', 'worker': 'tester', 'tasks': ['command_tests', 'integration_tests']},
            {'phase': 'documentation', 'worker': 'documenter', 'tasks': ['usage_guide', 'readme']},
        ]

    @staticmethod
    def _decompose_library(project: Dict[str, Any], requirements: List[str]) -> List[Dict[str, Any]]:
        """Decompose library project."""
        return [
            {'phase': 'design', 'worker': 'architect', 'tasks': ['api_design', 'module_structure']},
            {'phase': 'implementation', 'worker': 'developer', 'tasks': ['core_functionality', 'utilities']},
            {'phase': 'testing', 'worker': 'tester', 'tasks': ['unit_tests', 'coverage_analysis']},
            {'phase': 'documentation', 'worker': 'documenter', 'tasks': ['api_reference', 'examples', 'readme']},
        ]

    @staticmethod
    def _decompose_full_stack(project: Dict[str, Any], requirements: List[str]) -> List[Dict[str, Any]]:
        """Decompose full-stack project."""
        return [
            {'phase': 'analysis', 'worker': 'code_analyzer', 'if': 'existing_code' in project},
            {'phase': 'design', 'worker': 'architect', 'tasks': ['system_architecture', 'api_design', 'database_design', 'frontend_architecture']},
            {'phase': 'backend', 'worker': 'developer', 'tasks': ['api_endpoints', 'business_logic', 'database']},
            {'phase': 'frontend', 'worker': 'developer', 'tasks': ['components', 'state_management', 'routing']},
            {'phase': 'integration', 'worker': 'developer', 'tasks': ['api_integration', 'authentication']},
            {'phase': 'testing', 'worker': 'tester', 'tasks': ['backend_tests', 'frontend_tests', 'e2e_tests']},
            {'phase': 'documentation', 'worker': 'documenter', 'tasks': ['api_docs', 'user_guide', 'deployment_guide']},
        ]

    @staticmethod
    def _decompose_generic(project: Dict[str, Any], requirements: List[str]) -> List[Dict[str, Any]]:
        """Generic decomposition for unknown project types."""
        return [
            {'phase': 'analysis', 'worker': 'code_analyzer', 'if': 'existing_code' in project},
            {'phase': 'design', 'worker': 'architect'},
            {'phase': 'implementation', 'worker': 'developer'},
            {'phase': 'testing', 'worker': 'tester'},
            {'phase': 'documentation', 'worker': 'documenter'},
        ]

    @staticmethod
    def estimate_effort(subtasks: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        Estimate effort for subtasks.

        Returns:
            Effort estimates with task counts and estimated time
        """
        total_tasks = len(subtasks)
        total_phases = len(set(task.get('phase', 'unknown') for task in subtasks))

        # Simple estimation: 30 min per task
        estimated_minutes = total_tasks * 30

        return {
            'total_subtasks': total_tasks,
            'total_phases': total_phases,
            'estimated_time_minutes': estimated_minutes,
            'estimated_time_hours': round(estimated_minutes / 60, 1)
        }

    @staticmethod
    def identify_dependencies(subtasks: List[Dict[str, Any]]) -> Dict[str, List[str]]:
        """
        Identify dependencies between subtasks.

        Returns:
            Dependency graph {task_id: [depends_on_task_ids]}
        """
        dependencies = {}

        for i, task in enumerate(subtasks):
            task_id = f"task_{i}"
            dependencies[task_id] = []

            # Simple rule: each task depends on previous phase tasks
            if i > 0:
                prev_task = subtasks[i-1]
                if task.get('phase') != prev_task.get('phase'):
                    dependencies[task_id].append(f"task_{i-1}")

        return dependencies
