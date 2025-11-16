"""
Base Worker Interface

Defines the base interface and common functionality for all specialized workers
in the Dynamic Task Orchestrator system.
"""

from abc import ABC, abstractmethod
from typing import Dict, Any, List
from enum import Enum


class WorkerStatus(Enum):
    """Worker execution status"""
    IDLE = "idle"
    WORKING = "working"
    COMPLETED = "completed"
    FAILED = "failed"
    BLOCKED = "blocked"


class BaseWorker(ABC):
    """
    Abstract base class for all specialized workers.

    Each worker must implement:
    - execute(): Main task execution logic
    - validate_task(): Task validation before execution
    - get_capabilities(): Return worker capabilities
    """

    def __init__(self, worker_id: str, name: str):
        """
        Initialize base worker.

        Args:
            worker_id: Unique identifier for this worker
            name: Human-readable worker name
        """
        self.worker_id = worker_id
        self.name = name
        self.status = WorkerStatus.IDLE
        self.current_task = None
        self.completed_tasks = []
        self.artifacts_created = []
        self.execution_history = []

    @abstractmethod
    def execute(self, task: Dict[str, Any], context: Dict[str, Any]) -> Dict[str, Any]:
        """
        Execute the assigned task.

        Args:
            task: Task definition with objectives, inputs, and constraints
            context: Shared execution context from orchestrator

        Returns:
            Result dictionary with:
                - success: bool
                - output: Any (task-specific output)
                - artifacts: List[str] (files/resources created)
                - next_steps: List[str] (recommendations for orchestrator)
                - errors: List[str] (if any)
        """
        pass

    @abstractmethod
    def validate_task(self, task: Dict[str, Any]) -> tuple[bool, str]:
        """
        Validate if this worker can handle the task.

        Args:
            task: Task definition to validate

        Returns:
            Tuple of (is_valid, error_message)
        """
        pass

    @abstractmethod
    def get_capabilities(self) -> List[str]:
        """
        Return list of capabilities this worker provides.

        Returns:
            List of capability identifiers
        """
        pass

    def get_triggers(self) -> List[str]:
        """
        Return list of triggers that activate this worker.

        Returns:
            List of trigger keywords/patterns
        """
        return []

    def update_status(self, status: WorkerStatus):
        """Update worker status."""
        self.status = status

    def record_artifact(self, artifact_path: str):
        """Record an artifact created by this worker."""
        if artifact_path not in self.artifacts_created:
            self.artifacts_created.append(artifact_path)

    def record_task_completion(self, task: Dict[str, Any], result: Dict[str, Any]):
        """Record completed task in history."""
        self.completed_tasks.append(task.get('task_id', 'unknown'))
        self.execution_history.append({
            'task_id': task.get('task_id', 'unknown'),
            'task_type': task.get('type', 'unknown'),
            'result': result,
            'timestamp': self._get_timestamp()
        })

    def get_summary(self) -> Dict[str, Any]:
        """Get worker execution summary."""
        return {
            'worker_id': self.worker_id,
            'name': self.name,
            'status': self.status.value,
            'tasks_completed': len(self.completed_tasks),
            'artifacts_created': self.artifacts_created,
            'capabilities': self.get_capabilities(),
            'triggers': self.get_triggers()
        }

    def reset(self):
        """Reset worker to initial state."""
        self.status = WorkerStatus.IDLE
        self.current_task = None
        self.completed_tasks = []
        self.artifacts_created = []
        self.execution_history = []

    @staticmethod
    def _get_timestamp() -> str:
        """Get current timestamp as ISO string."""
        from datetime import datetime
        return datetime.utcnow().isoformat()

    def __repr__(self):
        return f"{self.__class__.__name__}(id={self.worker_id}, status={self.status.value})"
