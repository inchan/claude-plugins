"""
Worker Selector

Intelligent worker selection and task-worker matching algorithms.
"""

from typing import Dict, Any, List, Optional


class WorkerSelector:
    """
    Selects optimal workers for tasks based on capabilities and context.
    """

    def __init__(self, workers: Dict[str, Any]):
        """
        Initialize selector with available workers.

        Args:
            workers: Dictionary of worker instances
        """
        self.workers = workers
        self.worker_profiles = self._build_worker_profiles()

    def _build_worker_profiles(self) -> Dict[str, Dict[str, Any]]:
        """Build capability profiles for each worker."""
        profiles = {}

        for worker_id, worker in self.workers.items():
            profiles[worker_id] = {
                'capabilities': worker.get_capabilities(),
                'triggers': worker.get_triggers(),
                'performance_history': [],
                'load': 0
            }

        return profiles

    def select_for_task(self, task: Dict[str, Any], context: Dict[str, Any]) -> Optional[str]:
        """
        Select best worker for a specific task.

        Args:
            task: Task definition
            context: Execution context

        Returns:
            Worker ID or None if no suitable worker
        """
        task_type = task.get('type', '')
        task_keywords = task.get('keywords', [])

        # Match by task type first
        for worker_id, profile in self.worker_profiles.items():
            if task_type in worker_id or task_type in profile['capabilities']:
                return worker_id

        # Match by triggers
        for worker_id, profile in self.worker_profiles.items():
            triggers = profile['triggers']
            if any(trigger in str(task) for trigger in triggers):
                return worker_id

        # Match by keywords
        for worker_id, profile in self.worker_profiles.items():
            capabilities = profile['capabilities']
            if any(keyword in str(capabilities) for keyword in task_keywords):
                return worker_id

        return None

    def select_optimal_workers(
        self,
        available_tasks: List[Dict[str, Any]],
        context: Dict[str, Any],
        max_parallel: int = 1
    ) -> List[str]:
        """
        Select optimal workers for parallel execution.

        Args:
            available_tasks: Tasks ready for execution
            context: Execution context
            max_parallel: Maximum number of parallel workers

        Returns:
            List of worker IDs to execute
        """
        selected = []

        for task in available_tasks[:max_parallel]:
            worker_id = self.select_for_task(task, context)
            if worker_id and worker_id not in selected:
                selected.append(worker_id)

        return selected

    def rank_workers_for_task(self, task: Dict[str, Any]) -> List[tuple[str, float]]:
        """
        Rank all workers by suitability for task.

        Returns:
            List of (worker_id, score) tuples sorted by score
        """
        scores = []

        for worker_id, profile in self.worker_profiles.items():
            score = self._calculate_match_score(task, profile)
            scores.append((worker_id, score))

        return sorted(scores, key=lambda x: x[1], reverse=True)

    def _calculate_match_score(self, task: Dict[str, Any], profile: Dict[str, Any]) -> float:
        """
        Calculate how well a worker matches a task.

        Returns:
            Score from 0.0 to 1.0
        """
        score = 0.0

        # Check capabilities match
        task_str = str(task).lower()
        for capability in profile['capabilities']:
            if capability.lower() in task_str:
                score += 0.3

        # Check trigger match
        for trigger in profile['triggers']:
            if trigger.lower() in task_str:
                score += 0.4

        # Consider worker load (prefer less loaded workers)
        load_penalty = min(profile['load'] * 0.1, 0.5)
        score -= load_penalty

        return min(score, 1.0)

    def update_worker_performance(self, worker_id: str, task_result: Dict[str, Any]):
        """
        Update worker performance history.

        Args:
            worker_id: Worker ID
            task_result: Result of task execution
        """
        if worker_id in self.worker_profiles:
            profile = self.worker_profiles[worker_id]
            profile['performance_history'].append({
                'success': task_result.get('success', False),
                'execution_time': task_result.get('execution_time', 0)
            })

            # Update load
            profile['load'] = max(0, profile['load'] - 1)

    def assign_task(self, worker_id: str):
        """Increment worker load when assigning a task."""
        if worker_id in self.worker_profiles:
            self.worker_profiles[worker_id]['load'] += 1

    def get_worker_status(self) -> Dict[str, Any]:
        """Get current status of all workers."""
        status = {}

        for worker_id, worker in self.workers.items():
            profile = self.worker_profiles[worker_id]
            status[worker_id] = {
                'status': worker.status.value,
                'load': profile['load'],
                'tasks_completed': len(worker.completed_tasks),
                'performance_avg': self._calculate_avg_performance(profile)
            }

        return status

    @staticmethod
    def _calculate_avg_performance(profile: Dict[str, Any]) -> float:
        """Calculate average performance score for a worker."""
        history = profile['performance_history']
        if not history:
            return 1.0

        success_rate = sum(1 for h in history if h['success']) / len(history)
        return success_rate
