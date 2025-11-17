"""
Adaptive Planner

Dynamic replanning engine that adjusts execution plans based on feedback.
"""

from typing import Dict, Any, List


class AdaptivePlanner:
    """
    Dynamically adjusts execution plans based on real-time feedback and discoveries.
    """

    def __init__(self):
        """Initialize adaptive planner."""
        self.replan_history = []
        self.complexity_adjustments = []

    def create_initial_plan(self, analysis: Dict[str, Any], project: Dict[str, Any]) -> Dict[str, Any]:
        """
        Create initial execution plan.

        Args:
            analysis: Project analysis results
            project: Project definition

        Returns:
            Execution plan with phases, tasks, and dependencies
        """
        plan = {
            'version': 1,
            'phases': self._plan_phases(analysis, project),
            'current_phase_index': 0,
            'task_queue': [],
            'dependencies': {},
            'contingencies': [],
            'estimated_completion': None
        }

        # Build task queue from phases
        for phase in plan['phases']:
            plan['task_queue'].extend(phase.get('tasks', []))

        return plan

    def replan(self, current_plan: Dict[str, Any], trigger: Dict[str, Any]) -> Dict[str, Any]:
        """
        Adjust plan based on new information or issues.

        Args:
            current_plan: Current execution plan
            trigger: Event or result that triggered replanning

        Returns:
            Updated execution plan
        """
        replan_reason = self._analyze_replan_trigger(trigger)

        updated_plan = current_plan.copy()
        updated_plan['version'] += 1

        # Record replan event
        self.replan_history.append({
            'version': updated_plan['version'],
            'reason': replan_reason,
            'trigger': trigger
        })

        # Apply replanning strategy
        if replan_reason == 'unexpected_dependency':
            updated_plan = self._handle_new_dependency(updated_plan, trigger)
        elif replan_reason == 'task_failure':
            updated_plan = self._handle_task_failure(updated_plan, trigger)
        elif replan_reason == 'scope_change':
            updated_plan = self._handle_scope_change(updated_plan, trigger)
        elif replan_reason == 'bottleneck':
            updated_plan = self._handle_bottleneck(updated_plan, trigger)

        return updated_plan

    def assess_complexity(self, current_state: Dict[str, Any], plan: Dict[str, Any]) -> str:
        """
        Reassess project complexity based on progress.

        Returns:
            Complexity level: 'low', 'medium', 'high'
        """
        completed_tasks = len([t for t in plan['task_queue'] if t.get('completed', False)])
        total_tasks = len(plan['task_queue'])
        replan_count = len(self.replan_history)

        # If replanned multiple times or many tasks remaining, increase complexity
        if replan_count > 3 or (completed_tasks / max(total_tasks, 1)) < 0.3:
            return 'high'
        elif replan_count > 1:
            return 'medium'
        else:
            return 'low'

    def suggest_task_reallocation(self, plan: Dict[str, Any], worker_status: Dict[str, Any]) -> List[Dict[str, Any]]:
        """
        Suggest task reallocations based on worker performance.

        Returns:
            List of reallocation suggestions
        """
        reallocations = []

        # Find overloaded workers
        for worker_id, status in worker_status.items():
            if status.get('load', 0) > 3:
                # Suggest moving tasks to less loaded workers
                reallocations.append({
                    'from_worker': worker_id,
                    'reason': 'overloaded',
                    'suggested_action': 'redistribute_tasks'
                })

        return reallocations

    def _plan_phases(self, analysis: Dict[str, Any], project: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Plan execution phases based on analysis."""
        phases = []

        required_workers = analysis.get('required_workers', [])

        # Create phases for each worker
        if 'code_analyzer' in required_workers:
            phases.append({
                'name': 'Analysis',
                'workers': ['code_analyzer'],
                'tasks': [{'type': 'analyze_codebase'}]
            })

        if 'architect' in required_workers:
            phases.append({
                'name': 'Design',
                'workers': ['architect'],
                'tasks': [{'type': 'design_architecture'}]
            })

        if 'developer' in required_workers:
            phases.append({
                'name': 'Implementation',
                'workers': ['developer'],
                'tasks': [{'type': 'implement_features'}]
            })

        if 'tester' in required_workers:
            phases.append({
                'name': 'Testing',
                'workers': ['tester'],
                'tasks': [{'type': 'create_tests'}, {'type': 'run_tests'}]
            })

        if 'documenter' in required_workers:
            phases.append({
                'name': 'Documentation',
                'workers': ['documenter'],
                'tasks': [{'type': 'create_documentation'}]
            })

        if 'optimizer' in required_workers:
            phases.append({
                'name': 'Optimization',
                'workers': ['optimizer'],
                'tasks': [{'type': 'optimize_performance'}]
            })

        return phases

    @staticmethod
    def _analyze_replan_trigger(trigger: Dict[str, Any]) -> str:
        """Analyze why replanning was triggered."""
        errors = trigger.get('errors', [])
        next_steps = trigger.get('next_steps', [])

        if errors:
            return 'task_failure'
        elif any('dependency' in step.lower() for step in next_steps):
            return 'unexpected_dependency'
        elif any('scope' in step.lower() for step in next_steps):
            return 'scope_change'
        elif any('bottleneck' in step.lower() for step in next_steps):
            return 'bottleneck'
        else:
            return 'general_adjustment'

    def _handle_new_dependency(self, plan: Dict[str, Any], trigger: Dict[str, Any]) -> Dict[str, Any]:
        """Handle discovery of new dependencies."""
        # Add dependency tasks to queue
        plan['contingencies'].append({
            'type': 'new_dependency',
            'action': 'added_tasks'
        })
        return plan

    def _handle_task_failure(self, plan: Dict[str, Any], trigger: Dict[str, Any]) -> Dict[str, Any]:
        """Handle task failures."""
        # Retry strategy
        plan['contingencies'].append({
            'type': 'task_failure',
            'action': 'retry_with_adjustments'
        })
        return plan

    def _handle_scope_change(self, plan: Dict[str, Any], trigger: Dict[str, Any]) -> Dict[str, Any]:
        """Handle scope changes."""
        plan['contingencies'].append({
            'type': 'scope_change',
            'action': 'updated_phases'
        })
        return plan

    def _handle_bottleneck(self, plan: Dict[str, Any], trigger: Dict[str, Any]) -> Dict[str, Any]:
        """Handle detected bottlenecks."""
        plan['contingencies'].append({
            'type': 'bottleneck',
            'action': 'parallelized_tasks'
        })
        return plan
