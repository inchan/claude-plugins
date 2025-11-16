"""
Progress Tracker - Tracks execution progress and performance metrics.

This module monitors parallel execution progress and collects performance metrics.
"""

import time
from typing import Dict, List, Any, Optional
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum


class TaskStatus(Enum):
    """Status of a task."""
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"


@dataclass
class TaskProgress:
    """Progress information for a single task."""
    task_id: str
    status: TaskStatus = TaskStatus.PENDING
    start_time: Optional[float] = None
    end_time: Optional[float] = None
    progress_percent: float = 0.0
    message: str = ""
    error: Optional[str] = None
    metadata: Dict[str, Any] = field(default_factory=dict)

    @property
    def duration(self) -> Optional[float]:
        """Calculate task duration in seconds."""
        if self.start_time is None:
            return None
        end = self.end_time or time.time()
        return end - self.start_time

    @property
    def is_complete(self) -> bool:
        """Check if task is complete."""
        return self.status in [TaskStatus.COMPLETED, TaskStatus.FAILED, TaskStatus.CANCELLED]


class ProgressTracker:
    """Tracks progress of parallel task execution."""

    def __init__(self):
        """Initialize progress tracker."""
        self.tasks: Dict[str, TaskProgress] = {}
        self.start_time: Optional[float] = None
        self.end_time: Optional[float] = None
        self.metrics: Dict[str, Any] = {}

    def start_tracking(self) -> None:
        """Start tracking execution."""
        self.start_time = time.time()

    def end_tracking(self) -> None:
        """End tracking execution."""
        self.end_time = time.time()

    def add_task(self, task_id: str, metadata: Dict[str, Any] = None) -> None:
        """
        Add a new task to track.

        Args:
            task_id: Unique task identifier
            metadata: Optional task metadata
        """
        self.tasks[task_id] = TaskProgress(
            task_id=task_id,
            metadata=metadata or {}
        )

    def start_task(self, task_id: str) -> None:
        """
        Mark task as started.

        Args:
            task_id: Task identifier
        """
        if task_id in self.tasks:
            task = self.tasks[task_id]
            task.status = TaskStatus.RUNNING
            task.start_time = time.time()

    def update_task(self, task_id: str, progress: float, message: str = "") -> None:
        """
        Update task progress.

        Args:
            task_id: Task identifier
            progress: Progress percentage (0-100)
            message: Optional progress message
        """
        if task_id in self.tasks:
            task = self.tasks[task_id]
            task.progress_percent = min(100.0, max(0.0, progress))
            task.message = message

    def complete_task(self, task_id: str, result: Any = None) -> None:
        """
        Mark task as completed.

        Args:
            task_id: Task identifier
            result: Optional task result
        """
        if task_id in self.tasks:
            task = self.tasks[task_id]
            task.status = TaskStatus.COMPLETED
            task.end_time = time.time()
            task.progress_percent = 100.0
            if result is not None:
                task.metadata["result"] = result

    def fail_task(self, task_id: str, error: str) -> None:
        """
        Mark task as failed.

        Args:
            task_id: Task identifier
            error: Error message
        """
        if task_id in self.tasks:
            task = self.tasks[task_id]
            task.status = TaskStatus.FAILED
            task.end_time = time.time()
            task.error = error

    def cancel_task(self, task_id: str) -> None:
        """
        Mark task as cancelled.

        Args:
            task_id: Task identifier
        """
        if task_id in self.tasks:
            task = self.tasks[task_id]
            task.status = TaskStatus.CANCELLED
            task.end_time = time.time()

    def get_overall_progress(self) -> Dict[str, Any]:
        """
        Get overall execution progress.

        Returns:
            Overall progress information
        """
        total_tasks = len(self.tasks)
        if total_tasks == 0:
            return {
                "overall_percent": 0.0,
                "completed": 0,
                "running": 0,
                "pending": 0,
                "failed": 0
            }

        completed = sum(1 for t in self.tasks.values() if t.status == TaskStatus.COMPLETED)
        running = sum(1 for t in self.tasks.values() if t.status == TaskStatus.RUNNING)
        pending = sum(1 for t in self.tasks.values() if t.status == TaskStatus.PENDING)
        failed = sum(1 for t in self.tasks.values() if t.status == TaskStatus.FAILED)

        # Calculate overall progress percentage
        total_progress = sum(t.progress_percent for t in self.tasks.values())
        overall_percent = total_progress / total_tasks if total_tasks > 0 else 0.0

        return {
            "overall_percent": round(overall_percent, 1),
            "completed": completed,
            "running": running,
            "pending": pending,
            "failed": failed,
            "total": total_tasks
        }

    def get_performance_metrics(self) -> Dict[str, Any]:
        """
        Get performance metrics for completed tasks.

        Returns:
            Performance metrics
        """
        completed_tasks = [t for t in self.tasks.values() if t.status == TaskStatus.COMPLETED]

        if not completed_tasks:
            return {
                "avg_duration": 0.0,
                "min_duration": 0.0,
                "max_duration": 0.0,
                "total_duration": 0.0
            }

        durations = [t.duration for t in completed_tasks if t.duration is not None]

        if not durations:
            return {
                "avg_duration": 0.0,
                "min_duration": 0.0,
                "max_duration": 0.0,
                "total_duration": 0.0
            }

        return {
            "avg_duration": sum(durations) / len(durations),
            "min_duration": min(durations),
            "max_duration": max(durations),
            "total_duration": sum(durations),
            "tasks_completed": len(completed_tasks)
        }

    def get_execution_summary(self) -> Dict[str, Any]:
        """
        Get comprehensive execution summary.

        Returns:
            Execution summary
        """
        progress = self.get_overall_progress()
        metrics = self.get_performance_metrics()

        total_duration = 0.0
        if self.start_time and self.end_time:
            total_duration = self.end_time - self.start_time
        elif self.start_time:
            total_duration = time.time() - self.start_time

        return {
            "progress": progress,
            "metrics": metrics,
            "total_duration": total_duration,
            "start_time": datetime.fromtimestamp(self.start_time).isoformat() if self.start_time else None,
            "end_time": datetime.fromtimestamp(self.end_time).isoformat() if self.end_time else None,
            "is_complete": all(t.is_complete for t in self.tasks.values()),
            "success_rate": self._calculate_success_rate()
        }

    def _calculate_success_rate(self) -> float:
        """Calculate success rate of completed tasks."""
        completed = [t for t in self.tasks.values() if t.is_complete]
        if not completed:
            return 0.0

        successful = sum(1 for t in completed if t.status == TaskStatus.COMPLETED)
        return (successful / len(completed)) * 100.0

    def get_task_details(self, task_id: str) -> Optional[Dict[str, Any]]:
        """
        Get detailed information about a specific task.

        Args:
            task_id: Task identifier

        Returns:
            Task details or None if not found
        """
        if task_id not in self.tasks:
            return None

        task = self.tasks[task_id]
        return {
            "task_id": task.task_id,
            "status": task.status.value,
            "progress": task.progress_percent,
            "message": task.message,
            "duration": task.duration,
            "error": task.error,
            "metadata": task.metadata
        }

    def get_running_tasks(self) -> List[str]:
        """Get list of currently running task IDs."""
        return [
            task_id
            for task_id, task in self.tasks.items()
            if task.status == TaskStatus.RUNNING
        ]

    def get_failed_tasks(self) -> List[Dict[str, Any]]:
        """Get list of failed tasks with error details."""
        return [
            {
                "task_id": task.task_id,
                "error": task.error,
                "duration": task.duration,
                "metadata": task.metadata
            }
            for task in self.tasks.values()
            if task.status == TaskStatus.FAILED
        ]

    def export_report(self) -> str:
        """
        Export execution report as formatted string.

        Returns:
            Formatted report
        """
        summary = self.get_execution_summary()

        report = "=" * 50 + "\n"
        report += "PARALLEL EXECUTION REPORT\n"
        report += "=" * 50 + "\n\n"

        # Progress
        progress = summary["progress"]
        report += f"Overall Progress: {progress['overall_percent']}%\n"
        report += f"  Completed: {progress['completed']}/{progress['total']}\n"
        report += f"  Running: {progress['running']}\n"
        report += f"  Pending: {progress['pending']}\n"
        report += f"  Failed: {progress['failed']}\n\n"

        # Metrics
        metrics = summary["metrics"]
        report += "Performance Metrics:\n"
        report += f"  Avg Duration: {metrics['avg_duration']:.2f}s\n"
        report += f"  Min Duration: {metrics['min_duration']:.2f}s\n"
        report += f"  Max Duration: {metrics['max_duration']:.2f}s\n"
        report += f"  Total Duration: {metrics['total_duration']:.2f}s\n\n"

        # Summary
        report += f"Total Execution Time: {summary['total_duration']:.2f}s\n"
        report += f"Success Rate: {summary['success_rate']:.1f}%\n"

        # Failed tasks
        failed = self.get_failed_tasks()
        if failed:
            report += "\nFailed Tasks:\n"
            for task in failed:
                report += f"  - {task['task_id']}: {task['error']}\n"

        return report


def main():
    """Example usage of ProgressTracker."""
    tracker = ProgressTracker()
    tracker.start_tracking()

    # Add tasks
    task_ids = ["task_1", "task_2", "task_3", "task_4"]
    for task_id in task_ids:
        tracker.add_task(task_id, metadata={"type": "parallel_task"})

    # Simulate execution
    for task_id in task_ids:
        tracker.start_task(task_id)
        time.sleep(0.1)

        tracker.update_task(task_id, 50.0, "Processing...")
        time.sleep(0.1)

        if task_id != "task_3":
            tracker.complete_task(task_id, result={"success": True})
        else:
            tracker.fail_task(task_id, "Simulated error")

    tracker.end_tracking()

    # Print summary
    summary = tracker.get_execution_summary()
    print(tracker.export_report())


if __name__ == "__main__":
    main()
