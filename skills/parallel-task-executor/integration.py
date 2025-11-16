"""
Integration Module for Parallel Task Executor

Provides standard protocol interface for skill-to-skill communication
"""

import sys
from pathlib import Path

# Add utils to path
utils_path = Path(__file__).parent.parent.parent.parent / "workspace" / "prodg" / ".agent_skills" / "utils"
sys.path.insert(0, str(utils_path))

from message_protocol import (
    Message,
    create_response,
    create_error,
    parallel_aggregation_request
)
from message_queue import MessageQueue
from logger import get_logger

logger = get_logger()


class ParallelIntegration:
    """
    Integration interface for Parallel Task Executor
    """

    def __init__(self):
        self.skill_id = "parallel"
        self.queue = MessageQueue()

    def handle_message(self, message: Message) -> Message:
        """Handle incoming message"""
        action = message.data.get("action")

        try:
            if action == "execute_task":
                return self._execute_parallel(message)
            elif action == "aggregate_results":
                return self._aggregate_results(message)
            else:
                return create_error(
                    source_skill=self.skill_id,
                    target_skill=message.source_skill,
                    task_id=message.task_id,
                    error_code="UNKNOWN_ACTION",
                    error_message=f"Unknown action: {action}",
                    correlation_id=message.message_id
                )

        except Exception as e:
            logger.error(
                f"Error handling message: {e}",
                skill=self.skill_id,
                task_id=message.task_id
            )

            return create_error(
                source_skill=self.skill_id,
                target_skill=message.source_skill,
                task_id=message.task_id,
                error_code="EXECUTION_ERROR",
                error_message=str(e),
                correlation_id=message.message_id
            )

    def _execute_parallel(self, message: Message) -> Message:
        """Execute task in parallel mode"""
        task_id = message.task_id
        mode = message.data.get("execution_mode", "sectioning")

        logger.log_task_started(
            task_id=task_id,
            skill=self.skill_id,
            description=f"Parallel execution ({mode})"
        )

        # Mock parallel execution
        results = [
            {"worker": 1, "status": "completed", "output": {}},
            {"worker": 2, "status": "completed", "output": {}},
            {"worker": 3, "status": "completed", "output": {}}
        ]

        # Send to evaluator for aggregation
        agg_message = parallel_aggregation_request(
            task_id=task_id,
            execution_mode=mode,
            results=results
        )
        self.queue.send(agg_message)

        logger.log_task_completed(
            task_id=task_id,
            skill=self.skill_id,
            duration_ms=0
        )

        return create_response(
            source_skill=self.skill_id,
            target_skill=message.source_skill,
            action="parallel_complete",
            task_id=task_id,
            data={"results": results, "mode": mode},
            correlation_id=message.message_id
        )

    def _aggregate_results(self, message: Message) -> Message:
        """Aggregate parallel results"""
        task_id = message.task_id
        results = message.data.get("results", [])

        # Mock aggregation
        merged_result = {"status": "aggregated", "count": len(results)}

        return create_response(
            source_skill=self.skill_id,
            target_skill=message.source_skill,
            action="aggregation_complete",
            task_id=task_id,
            data={"merged_result": merged_result},
            correlation_id=message.message_id
        )

    def process_incoming_messages(self, limit: int = 10) -> int:
        """Process incoming messages"""
        messages = self.queue.receive(target_skill=self.skill_id, limit=limit)
        processed = 0

        for message in messages:
            response = self.handle_message(message)
            self.queue.send(response)
            self.queue.acknowledge(message)
            processed += 1

        return processed


def create_parallel_integration() -> ParallelIntegration:
    """Factory function"""
    return ParallelIntegration()
