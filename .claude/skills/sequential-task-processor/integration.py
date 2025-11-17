"""
Integration Module for Sequential Task Processor

Provides standard protocol interface for skill-to-skill communication
"""

import sys
from pathlib import Path
from typing import List, Dict, Any

# Add utils to path
utils_path = Path(__file__).parent.parent.parent.parent / "workspace" / "prodg" / ".agent_skills" / "utils"
sys.path.insert(0, str(utils_path))

from message_protocol import (
    Message,
    create_response,
    create_error,
    sequential_to_evaluator
)
from message_queue import MessageQueue
from logger import get_logger
from context_manager import get_project_context
from checkpoint_manager import CheckpointManager

logger = get_logger()


class SequentialIntegration:
    """
    Integration interface for Sequential Task Processor
    """

    def __init__(self):
        self.skill_id = "sequential"
        self.queue = MessageQueue()
        self.cache_dir = Path(".sequential_cache")

    def handle_message(self, message: Message) -> Message:
        """
        Handle incoming message

        Args:
            message: Incoming message

        Returns:
            Response message
        """
        action = message.data.get("action")

        try:
            if action == "execute_task":
                return self._execute_task(message)
            elif action == "reoptimize":
                return self._reoptimize(message)
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

    def _execute_task(self, message: Message) -> Message:
        """
        Execute task through sequential steps

        Args:
            message: Message containing task details

        Returns:
            Response message
        """
        task_id = message.task_id
        task_description = message.data.get("task_details", {}).get("description", "")
        requirements = message.data.get("task_details", {}).get("requirements", [])

        # Log task started
        logger.log_task_started(
            task_id=task_id,
            skill=self.skill_id,
            description=f"Sequential processing: {task_description}"
        )

        # Get project context
        project_id = message.context.get("project_id", "default")
        context = get_project_context(project_id)

        # Define sequential steps
        steps = self._define_steps(task_description)

        # Execute each step with validation
        completed_steps = []
        artifacts = {}

        for step_num, step_name in enumerate(steps, 1):
            logger.info(
                f"Executing step {step_num}/{len(steps)}: {step_name}",
                skill=self.skill_id,
                task_id=task_id
            )

            # Create checkpoint before step
            checkpoint_id = f"{task_id}_step_{step_num}"
            CheckpointManager(project_id).create_checkpoint(
                checkpoint_id=checkpoint_id,
                task_id=task_id,
                skill=self.skill_id,
                state={
                    "current_step": step_num,
                    "completed_steps": completed_steps,
                    "artifacts": artifacts
                }
            )

            # Execute step (mock implementation)
            step_result = self._execute_step(
                task_id=task_id,
                step_name=step_name,
                step_number=step_num,
                previous_artifacts=artifacts
            )

            # Validate step
            validation_result = self._validate_step(
                task_id=task_id,
                step_name=step_name,
                step_result=step_result
            )

            if not validation_result["passed"]:
                logger.warning(
                    f"Validation failed for step {step_name}",
                    skill=self.skill_id,
                    task_id=task_id,
                    data={"issues": validation_result.get("issues", [])}
                )

                # Return error response
                return create_error(
                    source_skill=self.skill_id,
                    target_skill=message.source_skill,
                    task_id=task_id,
                    error_code="VALIDATION_FAILED",
                    error_message=f"Step {step_name} validation failed",
                    details=validation_result,
                    recovery_suggestions=[
                        "Review validation issues",
                        "Correct the step output",
                        "Retry from checkpoint"
                    ],
                    correlation_id=message.message_id
                )

            # Step completed successfully
            completed_steps.append(step_name)
            artifacts[step_name] = step_result.get("artifact_path")

            # Log validation success
            logger.log_validation(
                task_id=task_id,
                skill=self.skill_id,
                step=step_name,
                passed=True
            )

        # All steps completed - send to evaluator
        evaluation_message = sequential_to_evaluator(
            task_id=task_id,
            artifacts=[
                {
                    "step": step,
                    "path": path,
                    "type": "documentation" if step == "documentation" else "code"
                }
                for step, path in artifacts.items()
            ],
            requirements={"original": requirements}
        )

        self.queue.send(evaluation_message)

        # Log task completed
        logger.log_task_completed(
            task_id=task_id,
            skill=self.skill_id,
            duration_ms=0,  # Would track actual duration
            artifacts=list(artifacts.values())
        )

        return create_response(
            source_skill=self.skill_id,
            target_skill=message.source_skill,
            action="task_completed",
            task_id=task_id,
            data={
                "status": "completed",
                "completed_steps": completed_steps,
                "artifacts": artifacts,
                "next_skill_recommendation": "evaluator"
            },
            correlation_id=message.message_id
        )

    def _define_steps(self, task_description: str) -> List[str]:
        """
        Define sequential steps for the task

        Args:
            task_description: Task description

        Returns:
            List of step names
        """
        # Standard sequence
        return [
            "analysis",
            "design",
            "implementation",
            "testing",
            "documentation"
        ]

    def _execute_step(
        self,
        task_id: str,
        step_name: str,
        step_number: int,
        previous_artifacts: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Execute a single step

        Args:
            task_id: Task identifier
            step_name: Step name
            step_number: Step number
            previous_artifacts: Artifacts from previous steps

        Returns:
            Step result
        """
        # Mock implementation
        artifact_path = self.cache_dir / task_id / f"{step_name}.md"
        artifact_path.parent.mkdir(parents=True, exist_ok=True)

        # Would actually generate step output here
        content = f"# {step_name.capitalize()}\n\nStep {step_number} output"
        artifact_path.write_text(content)

        return {
            "step": step_name,
            "step_number": step_number,
            "artifact_path": str(artifact_path),
            "status": "completed"
        }

    def _validate_step(
        self,
        task_id: str,
        step_name: str,
        step_result: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Validate step output

        Args:
            task_id: Task identifier
            step_name: Step name
            step_result: Step result

        Returns:
            Validation result
        """
        # Mock validation
        return {
            "passed": True,
            "step": step_name,
            "issues": []
        }

    def _reoptimize(self, message: Message) -> Message:
        """
        Reoptimize based on evaluator feedback

        Args:
            message: Message with optimization feedback

        Returns:
            Response message
        """
        task_id = message.task_id
        feedback = message.data.get("evaluation_results", {})
        improvements = message.data.get("required_improvements", [])

        logger.info(
            f"Reoptimizing task based on feedback",
            skill=self.skill_id,
            task_id=task_id,
            data={"improvements": len(improvements)}
        )

        # Would implement actual reoptimization here
        # For now, just acknowledge

        return create_response(
            source_skill=self.skill_id,
            target_skill=message.source_skill,
            action="reoptimization_complete",
            task_id=task_id,
            data={"status": "reoptimized"},
            correlation_id=message.message_id
        )

    def process_incoming_messages(self, limit: int = 10) -> int:
        """
        Process incoming messages from queue

        Args:
            limit: Maximum number of messages to process

        Returns:
            Number of messages processed
        """
        messages = self.queue.receive(target_skill=self.skill_id, limit=limit)
        processed = 0

        for message in messages:
            response = self.handle_message(message)

            # Send response
            self.queue.send(response)

            # Acknowledge original message
            self.queue.acknowledge(message)

            processed += 1

        return processed


def create_sequential_integration() -> SequentialIntegration:
    """
    Factory function to create sequential integration

    Returns:
        SequentialIntegration instance
    """
    return SequentialIntegration()
