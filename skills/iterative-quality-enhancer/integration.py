"""
Integration Module for Iterative Quality Enhancer

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
    evaluator_feedback
)
from message_queue import MessageQueue
from logger import get_logger

logger = get_logger()


class EvaluatorIntegration:
    """
    Integration interface for Iterative Quality Enhancer
    """

    def __init__(self):
        self.skill_id = "evaluator"
        self.queue = MessageQueue()

    def handle_message(self, message: Message) -> Message:
        """Handle incoming message"""
        action = message.data.get("action")

        try:
            if action == "evaluate_artifacts":
                return self._evaluate_artifacts(message)
            elif action == "aggregate_results":
                return self._aggregate_parallel_results(message)
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

    def _evaluate_artifacts(self, message: Message) -> Message:
        """Evaluate artifacts across quality dimensions"""
        task_id = message.task_id
        artifacts = message.data.get("artifacts", [])

        logger.log_task_started(
            task_id=task_id,
            skill=self.skill_id,
            description=f"Evaluating {len(artifacts)} artifacts"
        )

        # Mock evaluation across dimensions
        evaluation_results = {
            "total_score": 0.88,
            "dimensions": {
                "functionality": 0.92,
                "performance": 0.85,
                "code_quality": 0.90,
                "security": 0.95,
                "documentation": 0.82
            },
            "passed": True
        }

        # Check if improvements needed
        improvements_needed = []
        for dim, score in evaluation_results["dimensions"].items():
            threshold = self._get_threshold(dim)
            if score < threshold:
                improvements_needed.append({
                    "dimension": dim,
                    "current_score": score,
                    "threshold": threshold,
                    "gap": threshold - score,
                    "suggestions": [f"Improve {dim}"]
                })

        # Determine next action
        if improvements_needed:
            next_action = "reoptimize"
            evaluation_results["passed"] = False
        else:
            next_action = "complete"

        # Log optimization if improvements made
        if not improvements_needed:
            logger.log_optimization(
                task_id=task_id,
                skill=self.skill_id,
                iteration=1,
                dimension="overall",
                score_before=0.75,
                score_after=evaluation_results["total_score"]
            )

        # Send feedback to source skill
        feedback_message = evaluator_feedback(
            target_skill=message.source_skill,
            task_id=task_id,
            evaluation_results=evaluation_results,
            required_improvements=improvements_needed,
            next_action=next_action,
            correlation_id=message.message_id
        )

        self.queue.send(feedback_message)

        logger.log_task_completed(
            task_id=task_id,
            skill=self.skill_id,
            duration_ms=0,
            metrics=evaluation_results
        )

        return create_response(
            source_skill=self.skill_id,
            target_skill=message.source_skill,
            action="evaluation_complete",
            task_id=task_id,
            data={
                "evaluation_results": evaluation_results,
                "improvements_needed": improvements_needed,
                "next_action": next_action
            },
            correlation_id=message.message_id
        )

    def _aggregate_parallel_results(self, message: Message) -> Message:
        """Aggregate results from parallel execution"""
        task_id = message.task_id
        results = message.data.get("results", [])
        execution_mode = message.data.get("execution_mode", "voting")

        logger.info(
            f"Aggregating {len(results)} parallel results ({execution_mode})",
            skill=self.skill_id,
            task_id=task_id
        )

        # Mock aggregation
        if execution_mode == "voting":
            # Select best result
            best_result = results[0] if results else {}
            aggregated = {
                "selected_approach": "approach_1",
                "score": 0.90,
                "rationale": "Best performance/quality tradeoff"
            }
        else:  # sectioning
            # Merge results
            aggregated = {
                "merged": True,
                "conflicts_resolved": 2,
                "sections": len(results)
            }

        return create_response(
            source_skill=self.skill_id,
            target_skill=message.source_skill,
            action="aggregation_complete",
            task_id=task_id,
            data={"aggregated_result": aggregated, "mode": execution_mode},
            correlation_id=message.message_id
        )

    def _get_threshold(self, dimension: str) -> float:
        """Get quality threshold for dimension"""
        thresholds = {
            "functionality": 0.95,
            "performance": 0.85,
            "code_quality": 0.90,
            "security": 0.95,
            "documentation": 0.85
        }
        return thresholds.get(dimension, 0.85)

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


def create_evaluator_integration() -> EvaluatorIntegration:
    """Factory function"""
    return EvaluatorIntegration()
