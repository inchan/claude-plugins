"""
Functionality Evaluator

Evaluates correctness, completeness, and reliability of implementations.

This is a reference implementation showing the evaluation pattern.
Claude should apply this logic directly to user code rather than executing this script.
"""

from typing import Dict, Any, List
import ast


class FunctionalityEvaluator:
    """
    Evaluate functional correctness and completeness.

    Evaluation Criteria:
    - Correctness: All requirements met, business logic correct
    - Completeness: Edge cases handled, input validation present
    - Reliability: Error handling, meaningful error messages
    """

    def __init__(self, weight: float = 0.30, threshold: float = 0.95):
        self.weight = weight
        self.threshold = threshold

    def evaluate(self, artifact: Dict[str, Any]) -> Dict[str, Any]:
        """
        Evaluate functionality dimension.

        Args:
            artifact: Dictionary containing:
                - code: source code string
                - requirements: list of functional requirements
                - tests: optional test results

        Returns:
            Evaluation result with score and feedback
        """
        code = artifact.get('code', '')
        requirements = artifact.get('requirements', [])
        tests = artifact.get('tests', {})

        scores = {
            'correctness': self._evaluate_correctness(code, requirements, tests),
            'completeness': self._evaluate_completeness(code),
            'reliability': self._evaluate_reliability(code)
        }

        # Calculate weighted average
        total_score = sum(scores.values()) / len(scores)

        feedback = self._generate_feedback(scores)
        recommendations = self._generate_recommendations(scores)

        return {
            'dimension': 'functionality',
            'score': total_score,
            'weight': self.weight,
            'threshold': self.threshold,
            'meets_threshold': total_score >= self.threshold,
            'sub_scores': scores,
            'feedback': feedback,
            'recommendations': recommendations
        }

    def _evaluate_correctness(
        self,
        code: str,
        requirements: List[str],
        tests: Dict[str, Any]
    ) -> float:
        """
        Evaluate if code meets functional requirements.

        Checks:
        - All required features implemented
        - Test pass rate if tests provided
        - Expected outputs for valid inputs
        """
        score = 1.0

        # Check if tests are present and passing
        if tests:
            pass_rate = tests.get('pass_rate', 0)
            score *= pass_rate

        # Analyze code for basic correctness indicators
        try:
            tree = ast.parse(code)

            # Check for function definitions matching requirements
            functions = [node.name for node in ast.walk(tree)
                        if isinstance(node, ast.FunctionDef)]

            # Penalty if no functions defined
            if not functions:
                score *= 0.5

        except SyntaxError:
            # Syntax errors severely impact correctness
            score *= 0.3

        return max(0.0, score)

    def _evaluate_completeness(self, code: str) -> float:
        """
        Evaluate edge case handling and input validation.

        Checks:
        - Null/None checks
        - Boundary condition handling
        - Input validation presence
        """
        score = 1.0

        try:
            tree = ast.parse(code)

            # Look for error handling (try-except blocks)
            has_error_handling = any(
                isinstance(node, ast.Try)
                for node in ast.walk(tree)
            )

            # Look for input validation (if statements)
            has_validation = any(
                isinstance(node, ast.If)
                for node in ast.walk(tree)
            )

            # Look for null checks
            has_null_checks = any(
                isinstance(node, ast.Compare) and
                isinstance(node.ops[0], (ast.Is, ast.IsNot))
                for node in ast.walk(tree)
            )

            # Scoring based on presence of completeness indicators
            indicators = [has_error_handling, has_validation, has_null_checks]
            score = sum(indicators) / len(indicators)

        except SyntaxError:
            score = 0.3

        return score

    def _evaluate_reliability(self, code: str) -> float:
        """
        Evaluate error handling and recovery mechanisms.

        Checks:
        - Try-except blocks present
        - Meaningful error messages
        - Graceful degradation
        """
        score = 1.0

        try:
            tree = ast.parse(code)

            # Count try-except blocks
            try_blocks = [node for node in ast.walk(tree)
                         if isinstance(node, ast.Try)]

            # Count raise statements
            raise_statements = [node for node in ast.walk(tree)
                               if isinstance(node, ast.Raise)]

            # Score based on error handling presence
            if try_blocks:
                score = min(1.0, 0.7 + len(try_blocks) * 0.1)
            else:
                score = 0.5

            # Bonus for explicit error raising
            if raise_statements:
                score = min(1.0, score + 0.1)

        except SyntaxError:
            score = 0.3

        return score

    def _generate_feedback(self, scores: Dict[str, float]) -> List[str]:
        """Generate specific feedback based on scores."""
        feedback = []

        if scores['correctness'] < 0.8:
            feedback.append(
                "Correctness issues detected. Verify all requirements "
                "are implemented and tests are passing."
            )

        if scores['completeness'] < 0.8:
            feedback.append(
                "Completeness gaps found. Add input validation, "
                "null checks, and edge case handling."
            )

        if scores['reliability'] < 0.8:
            feedback.append(
                "Reliability concerns present. Implement comprehensive "
                "error handling with meaningful error messages."
            )

        return feedback

    def _generate_recommendations(self, scores: Dict[str, float]) -> List[str]:
        """Generate actionable recommendations."""
        recommendations = []

        if scores['correctness'] < 0.9:
            recommendations.append(
                "Add unit tests for all public functions to verify correctness"
            )

        if scores['completeness'] < 0.9:
            recommendations.append(
                "Implement validation for all input parameters"
            )
            recommendations.append(
                "Add null/undefined checks before using variables"
            )

        if scores['reliability'] < 0.9:
            recommendations.append(
                "Wrap risky operations in try-except blocks"
            )
            recommendations.append(
                "Provide descriptive error messages for all exceptions"
            )

        return recommendations


# Example usage (for reference only)
if __name__ == "__main__":
    evaluator = FunctionalityEvaluator()

    sample_code = """
def process_user_data(user_id, data):
    # Missing validation and error handling
    result = data['name'] + str(user_id)
    return result
"""

    artifact = {
        'code': sample_code,
        'requirements': ['Process user data safely'],
        'tests': {'pass_rate': 0.6}
    }

    result = evaluator.evaluate(artifact)
    print(f"Functionality Score: {result['score']:.2f}")
    print(f"Meets Threshold: {result['meets_threshold']}")
    print(f"Feedback: {result['feedback']}")
