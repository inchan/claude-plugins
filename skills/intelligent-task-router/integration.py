"""
Integration Module for Intelligent Task Router

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
    router_to_skill
)
from message_queue import MessageQueue
from logger import get_logger
from context_manager import get_project_context

logger = get_logger()


class RouterIntegration:
    """
    Integration interface for Intelligent Task Router
    """

    def __init__(self):
        self.skill_id = "router"
        self.queue = MessageQueue()

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
            if action == "classify_task":
                return self._classify_task(message)
            elif action == "route_task":
                return self._route_task(message)
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

    def _classify_task(self, message: Message) -> Message:
        """
        Classify a task

        Args:
            message: Message containing task description

        Returns:
            Response with classification results
        """
        task_description = message.data.get("task_description", "")

        # Log task started
        logger.log_task_started(
            task_id=message.task_id,
            skill=self.skill_id,
            description=f"Classifying task: {task_description}"
        )

        # TODO: Implement actual classification logic
        # This would use the keyword_classifier, intent_classifier, and complexity_analyzer

        # Mock classification result
        classification = {
            "primary": "feature_development",
            "secondary": ["documentation"],
            "confidence": 0.85,
            "intent": "create",
            "complexity_score": 0.75,
            "estimated_minutes": 90
        }

        return create_response(
            source_skill=self.skill_id,
            target_skill=message.source_skill,
            action="classification_result",
            task_id=message.task_id,
            data={"classification": classification},
            correlation_id=message.message_id
        )

    def _route_task(self, message: Message) -> Message:
        """
        Route a task to the optimal skill

        Args:
            message: Message containing task and classification

        Returns:
            Response with routing decision
        """
        task_description = message.data.get("task_description", "")
        classification = message.data.get("classification", {})

        # Log task
        logger.log_task_started(
            task_id=message.task_id,
            skill=self.skill_id,
            description=f"Routing task: {task_description}"
        )

        # Determine target skill based on classification
        complexity = classification.get("complexity_score", 0.5)
        category = classification.get("primary", "feature_development")

        target_skill = self._select_target_skill(category, complexity)

        # Create routing decision
        routing_decision = {
            "target_skill": target_skill,
            "category": category,
            "complexity": complexity,
            "model": self._select_model(complexity),
            "priority": "medium"
        }

        # Log routing decision
        logger.log_skill_interaction(
            source=self.skill_id,
            target=target_skill,
            action="route_task",
            task_id=message.task_id,
            success=True
        )

        # Send message to target skill
        routed_message = router_to_skill(
            target_skill=target_skill,
            task_description=task_description,
            task_id=message.task_id,
            category=category,
            complexity=complexity,
            requirements=message.data.get("requirements", []),
            constraints=message.context.get("constraints", [])
        )

        self.queue.send(routed_message)

        return create_response(
            source_skill=self.skill_id,
            target_skill=message.source_skill,
            action="routing_complete",
            task_id=message.task_id,
            data={"routing_decision": routing_decision},
            correlation_id=message.message_id
        )

    def _select_target_skill(self, category: str, complexity: float) -> str:
        """
        Select target skill based on category and complexity

        Args:
            category: Task category
            complexity: Complexity score (0.0-1.0)

        Returns:
            Target skill ID
        """
        # Complex feature development → orchestrator
        if complexity > 0.7 and category == "feature_development":
            return "orchestrator"

        # Sequential tasks
        if category in ["bug_fix", "security", "documentation"]:
            return "sequential"

        # Parallel tasks
        if category in ["testing", "data_processing"]:
            return "parallel"

        # Default to sequential
        return "sequential"

    def _select_model(self, complexity: float) -> str:
        """
        Select model based on complexity

        Args:
            complexity: Complexity score (0.0-1.0)

        Returns:
            Model name
        """
        if complexity < 0.5:
            return "claude-3-haiku"
        elif complexity < 0.7:
            return "claude-3-sonnet"
        else:
            return "claude-3-opus"

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


def create_router_integration() -> RouterIntegration:
    """
    Factory function to create router integration

    Returns:
        RouterIntegration instance
    """
    return RouterIntegration()
