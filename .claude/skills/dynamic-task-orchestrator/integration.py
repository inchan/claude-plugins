"""
Integration Module for Dynamic Task Orchestrator

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
    orchestrator_to_worker
)
from message_queue import MessageQueue
from logger import get_logger

logger = get_logger()


class OrchestratorIntegration:
    """
    Integration interface for Dynamic Task Orchestrator
    """

    def __init__(self):
        self.skill_id = "orchestrator"
        self.queue = MessageQueue()

    def handle_message(self, message: Message) -> Message:
        """Handle incoming message"""
        action = message.data.get("action")

        try:
            if action == "execute_task":
                return self._orchestrate_task(message)
            elif action == "worker_complete":
                return self._handle_worker_complete(message)
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

    def _orchestrate_task(self, message: Message) -> Message:
        """Orchestrate complex task across workers"""
        task_id = message.task_id
        task_description = message.data.get("task_details", {}).get("description", "")

        logger.log_task_started(
            task_id=task_id,
            skill=self.skill_id,
            description=f"Orchestrating: {task_description}"
        )

        # Decompose into subtasks
        subtasks = self._decompose_task(task_description)

        # Assign to workers
        for i, subtask in enumerate(subtasks):
            worker_message = orchestrator_to_worker(
                worker_type=subtask["worker_type"],
                subtask_id=f"{task_id}_subtask_{i}",
                subtask_description=subtask["description"],
                dependencies=subtask.get("dependencies", [])
            )
            self.queue.send(worker_message)

            logger.log_skill_interaction(
                source=self.skill_id,
                target=subtask["worker_type"],
                action="assign_subtask",
                task_id=task_id,
                success=True
            )

        return create_response(
            source_skill=self.skill_id,
            target_skill=message.source_skill,
            action="orchestration_started",
            task_id=task_id,
            data={"subtasks": len(subtasks), "workers_assigned": len(subtasks)},
            correlation_id=message.message_id
        )

    def _decompose_task(self, task_description: str) -> list:
        """Decompose task into subtasks"""
        # Mock decomposition
        return [
            {"worker_type": "sequential", "description": "Analyze requirements", "dependencies": []},
            {"worker_type": "sequential", "description": "Design architecture", "dependencies": ["analyze"]},
            {"worker_type": "parallel", "description": "Implement components", "dependencies": ["design"]}
        ]

    def _handle_worker_complete(self, message: Message) -> Message:
        """Handle worker completion notification"""
        task_id = message.task_id

        logger.info(
            f"Worker completed subtask",
            skill=self.skill_id,
            task_id=task_id
        )

        return create_response(
            source_skill=self.skill_id,
            target_skill=message.source_skill,
            action="acknowledged",
            task_id=task_id,
            data={"status": "acknowledged"},
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


def create_orchestrator_integration() -> OrchestratorIntegration:
    """Factory function"""
    return OrchestratorIntegration()
