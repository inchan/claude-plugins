"""
Evaluator modules for multi-dimensional quality assessment.

This package contains evaluators for each quality dimension:
- Functionality: Correctness, completeness, reliability
- Performance: Time/space complexity, response time
- Code Quality: Readability, maintainability, modularity
- Security: Vulnerabilities, auth/authz, data protection
- Documentation: Completeness, clarity, examples

Usage:
    from evaluators import FunctionalityEvaluator, PerformanceEvaluator

    func_eval = FunctionalityEvaluator()
    score = func_eval.evaluate(code_artifact)
"""

from typing import Dict, Any, Protocol


class Evaluator(Protocol):
    """
    Base protocol for all evaluators.

    All evaluators must implement the evaluate() method that returns
    a score between 0.0 and 1.0 along with detailed feedback.
    """

    def evaluate(self, artifact: Any) -> Dict[str, Any]:
        """
        Evaluate artifact and return score with feedback.

        Args:
            artifact: Code, documentation, or other artifact to evaluate

        Returns:
            Dictionary containing:
                - score: float between 0.0 and 1.0
                - feedback: list of issues found
                - recommendations: list of improvement suggestions
        """
        ...
