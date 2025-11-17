"""
Orchestration Engine

Main orchestration logic for coordinating workers and managing project execution.
"""

from typing import Dict, Any, List
from enum import Enum
import sys
import os

# Add parent directory to path for worker imports
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from workers.base_worker import WorkerStatus
from workers.code_analyzer_worker import CodeAnalyzerWorker
from workers.architect_worker import ArchitectWorker
from workers.developer_worker import DeveloperWorker
from workers.tester_worker import TesterWorker
from workers.documenter_worker import DocumenterWorker
from workers.optimizer_worker import OptimizerWorker


class ProjectStatus(Enum):
    """Project execution status"""
    INITIALIZED = "initialized"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    FAILED = "failed"
    REQUIRES_REVIEW = "requires_review"
    PARTIAL = "partial"


class OrchestrationMode(Enum):
    """Orchestration execution modes"""
    AUTONOMOUS = "autonomous"  # Full automation
    GUIDED = "guided"  # Seek approval for major decisions
    COLLABORATIVE = "collaborative"  # Frequent user checkpoints


class DynamicOrchestrator:
    """
    Main orchestrator that coordinates specialized workers to complete complex projects.

    Implements the Orchestrator-Workers pattern from Anthropic's framework.
    """

    def __init__(self):
        """Initialize orchestrator with all specialized workers."""
        self.workers = self._initialize_workers()
        self.project_state = None
        self.execution_context = {}
        self.task_history = []
        self.replanning_count = 0

    def _initialize_workers(self) -> Dict[str, Any]:
        """Initialize all specialized workers."""
        return {
            'code_analyzer': CodeAnalyzerWorker(),
            'architect': ArchitectWorker(),
            'developer': DeveloperWorker(),
            'tester': TesterWorker(),
            'documenter': DocumenterWorker(),
            'optimizer': OptimizerWorker()
        }

    def orchestrate_project(self, project: Dict[str, Any]) -> Dict[str, Any]:
        """
        Main orchestration entry point.

        Args:
            project: Project definition with:
                - task_id: Unique identifier
                - name: Project name
                - type: Project type (web_app, cli_tool, library, api, full_stack)
                - requirements: List of requirements
                - constraints: List of constraints
                - existing_code: Optional path to existing code
                - orchestration_mode: autonomous/guided/collaborative

        Returns:
            Execution summary with deliverables and worker contributions
        """
        from datetime import datetime
        start_time = datetime.utcnow()

        # Initialize project state
        self.project_state = {
            'status': ProjectStatus.INITIALIZED,
            'project': project,
            'deliverables': {
                'source_code': [],
                'tests': [],
                'documentation': [],
                'deployment': []
            }
        }

        mode = OrchestrationMode(project.get('orchestration_mode', 'autonomous'))

        # Phase 1: Project Analysis
        print(f"🚀 Starting orchestration for: {project.get('name')}")
        print(f"   Mode: {mode.value}")

        analysis = self._deep_analyze_project(project)
        self.execution_context['analysis'] = analysis

        # Phase 2: Create Execution Plan
        execution_plan = self._create_adaptive_plan(analysis, project)
        self.execution_context['plan'] = execution_plan

        # Phase 3: Execute with Dynamic Adaptation
        self.project_state['status'] = ProjectStatus.IN_PROGRESS

        while not self._is_project_complete():
            # Assess current state
            current_state = self._assess_current_state()

            # Select optimal workers for next phase
            selected_workers = self._select_optimal_workers(current_state, execution_plan)

            if not selected_workers:
                print("⚠️  No more workers to execute. Project may be incomplete.")
                break

            # Execute worker tasks
            for worker_id in selected_workers:
                worker = self.workers[worker_id]
                task = self._generate_worker_task(worker_id, current_state, execution_plan)

                print(f"   → {worker.name} executing: {task.get('type', 'unknown task')}")

                result = worker.execute(task, self.execution_context)

                # Integrate result
                self._integrate_result(worker_id, result)

                # Check if replanning needed
                if self._needs_replanning(result, execution_plan):
                    print(f"   ↻ Replanning required based on {worker.name} output")
                    execution_plan = self._replan(execution_plan, result)
                    self.replanning_count += 1

            # Checkpoint progress
            self._checkpoint_progress()

        # Phase 4: Finalization
        final_summary = self._finalize_project(start_time)

        return final_summary

    def _deep_analyze_project(self, project: Dict[str, Any]) -> Dict[str, Any]:
        """Perform deep project analysis."""
        analysis = {
            'project_type': project.get('type', 'unknown'),
            'complexity': self._estimate_complexity(project),
            'required_workers': [],
            'estimated_subtasks': 0,
            'has_existing_code': 'existing_code' in project
        }

        # Determine which workers are needed
        if analysis['has_existing_code']:
            analysis['required_workers'].append('code_analyzer')

        # Always need architect for new projects
        if not analysis['has_existing_code'] or 'migration' in str(project.get('requirements', [])).lower():
            analysis['required_workers'].append('architect')

        # Core workers always needed
        analysis['required_workers'].extend(['developer', 'tester', 'documenter'])

        # Optional workers based on project
        requirements_str = str(project.get('requirements', [])).lower()
        if 'performance' in requirements_str or 'optimization' in requirements_str:
            analysis['required_workers'].append('optimizer')

        analysis['estimated_subtasks'] = len(analysis['required_workers']) * len(project.get('requirements', []))

        return analysis

    def _estimate_complexity(self, project: Dict[str, Any]) -> str:
        """Estimate project complexity (low/medium/high)."""
        requirements_count = len(project.get('requirements', []))
        constraints_count = len(project.get('constraints', []))

        total_factors = requirements_count + constraints_count

        if total_factors <= 3:
            return 'low'
        elif total_factors <= 7:
            return 'medium'
        else:
            return 'high'

    def _create_adaptive_plan(self, analysis: Dict[str, Any], project: Dict[str, Any]) -> Dict[str, Any]:
        """Create initial execution plan."""
        return {
            'phases': [],
            'current_phase': 0,
            'worker_sequence': analysis['required_workers'],
            'dependencies': {},
            'completed_tasks': []
        }

    def _assess_current_state(self) -> Dict[str, Any]:
        """Assess current project state."""
        return {
            'status': self.project_state['status'],
            'completed_workers': [w for w, worker in self.workers.items() if worker.status == WorkerStatus.COMPLETED],
            'deliverables': self.project_state['deliverables']
        }

    def _select_optimal_workers(self, current_state: Dict[str, Any], plan: Dict[str, Any]) -> List[str]:
        """Select next workers to execute."""
        completed = set(current_state['completed_workers'])
        remaining = [w for w in plan['worker_sequence'] if w not in completed]

        # Return first uncompleted worker (sequential execution for now)
        return [remaining[0]] if remaining else []

    def _generate_worker_task(self, worker_id: str, state: Dict[str, Any], plan: Dict[str, Any]) -> Dict[str, Any]:
        """Generate specific task for worker."""
        project = self.project_state['project']

        # Generate task based on worker type
        task = {
            'task_id': f"{worker_id}_{len(self.task_history)}",
            'worker_id': worker_id,
            'type': worker_id,
            'project_context': project
        }

        # Worker-specific task configuration
        if worker_id == 'code_analyzer':
            task['codebase_path'] = project.get('existing_code', '.')
            task['analysis_type'] = 'full'

        elif worker_id == 'architect':
            task['design_type'] = 'full_architecture'
            task['requirements'] = project.get('requirements', [])
            task['constraints'] = project.get('constraints', [])

        elif worker_id == 'developer':
            task['task_type'] = 'feature'
            task['specification'] = self.execution_context.get('architecture', {})

        elif worker_id == 'tester':
            task['test_type'] = 'unit'
            task['code_under_test'] = self.project_state['deliverables']['source_code']

        elif worker_id == 'documenter':
            task['doc_type'] = 'readme'
            task['target'] = self.project_state['deliverables']

        elif worker_id == 'optimizer':
            task['optimization_type'] = 'general'
            task['target_code'] = self.project_state['deliverables']['source_code']

        return task

    def _integrate_result(self, worker_id: str, result: Dict[str, Any]):
        """Integrate worker result into project state."""
        if result.get('success'):
            # Add artifacts to deliverables
            artifacts = result.get('artifacts', [])

            for artifact in artifacts:
                if 'test' in artifact.lower():
                    self.project_state['deliverables']['tests'].append(artifact)
                elif any(ext in artifact.lower() for ext in ['.md', 'readme', 'doc']):
                    self.project_state['deliverables']['documentation'].append(artifact)
                elif any(ext in artifact.lower() for ext in ['docker', 'config', 'deploy']):
                    self.project_state['deliverables']['deployment'].append(artifact)
                else:
                    self.project_state['deliverables']['source_code'].append(artifact)

            # Store worker output in context
            self.execution_context[worker_id] = result.get('output', {})

        # Record in history
        self.task_history.append({
            'worker_id': worker_id,
            'result': result
        })

    def _needs_replanning(self, result: Dict[str, Any], plan: Dict[str, Any]) -> bool:
        """Determine if replanning is needed based on result."""
        # Replan if worker found unexpected issues or dependencies
        errors = result.get('errors', [])
        if errors:
            return True

        # Replan if worker recommends additional work
        next_steps = result.get('next_steps', [])
        if any('required' in step.lower() or 'must' in step.lower() for step in next_steps):
            return True

        return False

    def _replan(self, current_plan: Dict[str, Any], trigger_result: Dict[str, Any]) -> Dict[str, Any]:
        """Adapt execution plan based on new information."""
        # Simple replanning: add recommended workers to sequence
        updated_plan = current_plan.copy()

        # Extract worker recommendations from next_steps
        # In real implementation, would parse next_steps more intelligently

        return updated_plan

    def _checkpoint_progress(self):
        """Save current progress checkpoint."""
        # In real implementation, would save state to disk
        pass

    def _is_project_complete(self) -> bool:
        """Check if project is complete."""
        if self.project_state['status'] in [ProjectStatus.COMPLETED, ProjectStatus.FAILED]:
            return True

        # Check if all required workers have completed
        analysis = self.execution_context.get('analysis', {})
        required_workers = set(analysis.get('required_workers', []))
        completed_workers = set(
            w for w, worker in self.workers.items()
            if worker.status == WorkerStatus.COMPLETED
        )

        if required_workers.issubset(completed_workers):
            self.project_state['status'] = ProjectStatus.COMPLETED
            return True

        return False

    def _finalize_project(self, start_time) -> Dict[str, Any]:
        """Finalize project and generate summary."""
        from datetime import datetime
        end_time = datetime.utcnow()
        duration = end_time - start_time

        # Collect worker contributions
        worker_contributions = {}
        for worker_id, worker in self.workers.items():
            summary = worker.get_summary()
            if summary['tasks_completed'] > 0:
                worker_contributions[worker_id] = {
                    'tasks_completed': summary['tasks_completed'],
                    'artifacts_created': summary['artifacts_created']
                }

        return {
            'task_id': self.project_state['project'].get('task_id', 'unknown'),
            'execution_summary': {
                'total_workers_used': len(worker_contributions),
                'total_subtasks': len(self.task_history),
                'execution_time': str(duration),
                'replanning_count': self.replanning_count
            },
            'project_deliverables': self.project_state['deliverables'],
            'worker_contributions': worker_contributions,
            'next_skill_recommendation': 'evaluator',
            'project_state': self.project_state['status'].value
        }
