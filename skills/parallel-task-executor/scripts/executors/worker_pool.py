"""
Worker Pool - Dynamic worker pool management with auto-scaling.

This module manages a pool of workers that can be dynamically scaled
based on task complexity and resource availability.
"""

import time
import psutil
from typing import Dict, List, Any, Callable, Optional
from dataclasses import dataclass
from concurrent.futures import ThreadPoolExecutor, Future
from threading import Lock


@dataclass
class WorkerMetrics:
    """Metrics for a single worker."""
    worker_id: str
    tasks_completed: int = 0
    total_execution_time: float = 0.0
    avg_execution_time: float = 0.0
    failures: int = 0
    last_heartbeat: float = 0.0


class WorkerPool:
    """Dynamic worker pool with auto-scaling and monitoring."""

    def __init__(self, config: Dict[str, Any]):
        """
        Initialize worker pool with configuration.

        Args:
            config: Configuration dict with parallelism and resource settings
        """
        self.config = config
        self.min_workers = config.get("parallelism", {}).get("min_workers", 2)
        self.max_workers = config.get("parallelism", {}).get("max_workers", 10)
        self.default_workers = config.get("parallelism", {}).get("default_workers", 5)

        self.max_memory_mb = config.get("resources", {}).get("max_memory_mb", 4096)
        self.cpu_threshold = config.get("resources", {}).get("cpu_threshold", 0.8)

        self.current_workers = self.default_workers
        self.metrics: Dict[str, WorkerMetrics] = {}
        self.lock = Lock()

        self.executor: Optional[ThreadPoolExecutor] = None

    def __enter__(self):
        """Context manager entry."""
        self.executor = ThreadPoolExecutor(max_workers=self.current_workers)
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit."""
        if self.executor:
            self.executor.shutdown(wait=True)

    def submit(self, fn: Callable, *args, **kwargs) -> Future:
        """
        Submit a task to the worker pool.

        Args:
            fn: Function to execute
            *args: Positional arguments for function
            **kwargs: Keyword arguments for function

        Returns:
            Future object
        """
        if not self.executor:
            raise RuntimeError("WorkerPool not initialized. Use as context manager.")

        worker_id = f"worker_{len(self.metrics)}"

        # Create metrics for new worker if needed
        with self.lock:
            if worker_id not in self.metrics:
                self.metrics[worker_id] = WorkerMetrics(
                    worker_id=worker_id,
                    last_heartbeat=time.time()
                )

        # Wrap function to track metrics
        def wrapped_fn(*args, **kwargs):
            return self._execute_with_metrics(worker_id, fn, *args, **kwargs)

        return self.executor.submit(wrapped_fn, *args, **kwargs)

    def _execute_with_metrics(self, worker_id: str, fn: Callable, *args, **kwargs) -> Any:
        """
        Execute function and track metrics.

        Args:
            worker_id: Worker identifier
            fn: Function to execute
            *args: Positional arguments
            **kwargs: Keyword arguments

        Returns:
            Function result
        """
        start_time = time.time()

        try:
            result = fn(*args, **kwargs)

            # Update success metrics
            with self.lock:
                metrics = self.metrics[worker_id]
                metrics.tasks_completed += 1
                execution_time = time.time() - start_time
                metrics.total_execution_time += execution_time
                metrics.avg_execution_time = (
                    metrics.total_execution_time / metrics.tasks_completed
                )
                metrics.last_heartbeat = time.time()

            return result

        except Exception as e:
            # Update failure metrics
            with self.lock:
                metrics = self.metrics[worker_id]
                metrics.failures += 1
                metrics.last_heartbeat = time.time()
            raise e

    def auto_scale(self, task_complexity: str = "medium") -> None:
        """
        Automatically scale worker pool based on task complexity and resources.

        Args:
            task_complexity: Complexity level (low, medium, high)
        """
        # Check resource availability
        memory_available = self._check_memory_available()
        cpu_available = self._check_cpu_available()

        # Calculate optimal worker count
        if task_complexity == "low":
            optimal_workers = self.min_workers
        elif task_complexity == "high":
            optimal_workers = self.max_workers
        else:
            optimal_workers = self.default_workers

        # Adjust based on resource availability
        if not memory_available or not cpu_available:
            optimal_workers = max(self.min_workers, optimal_workers // 2)

        # Scale worker pool
        if optimal_workers != self.current_workers:
            self._scale_to(optimal_workers)

    def _scale_to(self, target_workers: int) -> None:
        """
        Scale worker pool to target size.

        Args:
            target_workers: Target number of workers
        """
        target_workers = max(self.min_workers, min(target_workers, self.max_workers))

        if target_workers != self.current_workers:
            # Recreate executor with new size
            if self.executor:
                self.executor.shutdown(wait=False)

            self.current_workers = target_workers
            self.executor = ThreadPoolExecutor(max_workers=target_workers)

    def _check_memory_available(self) -> bool:
        """
        Check if sufficient memory is available.

        Returns:
            True if memory is available
        """
        try:
            memory = psutil.virtual_memory()
            used_mb = memory.used / (1024 * 1024)
            return used_mb < self.max_memory_mb
        except Exception:
            return True  # Assume available if check fails

    def _check_cpu_available(self) -> bool:
        """
        Check if CPU usage is below threshold.

        Returns:
            True if CPU is available
        """
        try:
            cpu_percent = psutil.cpu_percent(interval=0.1)
            return cpu_percent < (self.cpu_threshold * 100)
        except Exception:
            return True  # Assume available if check fails

    def get_metrics(self) -> Dict[str, Any]:
        """
        Get current worker pool metrics.

        Returns:
            Metrics dictionary
        """
        with self.lock:
            total_tasks = sum(m.tasks_completed for m in self.metrics.values())
            total_failures = sum(m.failures for m in self.metrics.values())
            avg_time = (
                sum(m.avg_execution_time for m in self.metrics.values()) / len(self.metrics)
                if self.metrics else 0
            )

            return {
                "current_workers": self.current_workers,
                "total_tasks_completed": total_tasks,
                "total_failures": total_failures,
                "avg_execution_time": avg_time,
                "worker_utilization": self._calculate_utilization(),
                "workers": [
                    {
                        "id": m.worker_id,
                        "tasks_completed": m.tasks_completed,
                        "avg_time": m.avg_execution_time,
                        "failures": m.failures
                    }
                    for m in self.metrics.values()
                ]
            }

    def _calculate_utilization(self) -> float:
        """
        Calculate worker utilization rate.

        Returns:
            Utilization (0-1)
        """
        if not self.metrics:
            return 0.0

        active_workers = sum(
            1 for m in self.metrics.values()
            if time.time() - m.last_heartbeat < 5.0  # Active in last 5 seconds
        )

        return active_workers / self.current_workers if self.current_workers > 0 else 0.0

    def check_stuck_workers(self, timeout: int = 30) -> List[str]:
        """
        Identify workers that appear to be stuck.

        Args:
            timeout: Timeout in seconds to consider worker stuck

        Returns:
            List of stuck worker IDs
        """
        current_time = time.time()
        stuck_workers = []

        with self.lock:
            for worker_id, metrics in self.metrics.items():
                if current_time - metrics.last_heartbeat > timeout:
                    stuck_workers.append(worker_id)

        return stuck_workers


def main():
    """Example usage of WorkerPool."""
    config = {
        "parallelism": {
            "min_workers": 2,
            "max_workers": 10,
            "default_workers": 5
        },
        "resources": {
            "max_memory_mb": 4096,
            "cpu_threshold": 0.8
        }
    }

    def sample_task(task_id: int) -> str:
        """Sample task for testing."""
        time.sleep(0.1)  # Simulate work
        return f"Task {task_id} completed"

    # Use worker pool
    with WorkerPool(config) as pool:
        # Submit tasks
        futures = [pool.submit(sample_task, i) for i in range(10)]

        # Auto-scale based on complexity
        pool.auto_scale(task_complexity="high")

        # Wait for results
        results = [f.result() for f in futures]

        # Get metrics
        metrics = pool.get_metrics()
        print("Worker Pool Metrics:")
        print(f"  Workers: {metrics['current_workers']}")
        print(f"  Tasks completed: {metrics['total_tasks_completed']}")
        print(f"  Utilization: {metrics['worker_utilization']:.2%}")
        print(f"  Avg execution time: {metrics['avg_execution_time']:.3f}s")


if __name__ == "__main__":
    main()
