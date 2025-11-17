"""
Performance Evaluator

Evaluates algorithmic efficiency and resource utilization.
Reference implementation - apply this logic directly to user code.
"""

from typing import Dict, Any, List
import ast
import re


class PerformanceEvaluator:
    """Evaluate time/space complexity and response time."""

    def __init__(self, weight: float = 0.20, threshold: float = 0.85):
        self.weight = weight
        self.threshold = threshold

    def evaluate(self, artifact: Dict[str, Any]) -> Dict[str, Any]:
        """Evaluate performance dimension."""
        code = artifact.get('code', '')

        scores = {
            'time_complexity': self._evaluate_time_complexity(code),
            'space_complexity': self._evaluate_space_complexity(code),
            'response_time': self._evaluate_response_time(code)
        }

        total_score = sum(scores.values()) / len(scores)

        return {
            'dimension': 'performance',
            'score': total_score,
            'weight': self.weight,
            'threshold': self.threshold,
            'meets_threshold': total_score >= self.threshold,
            'sub_scores': scores,
            'feedback': self._generate_feedback(scores, code),
            'recommendations': self._generate_recommendations(scores, code)
        }

    def _evaluate_time_complexity(self, code: str) -> float:
        """
        Analyze algorithmic time complexity.

        Scoring guide:
        - O(1), O(log n), O(n): 1.0
        - O(n log n): 0.85
        - O(n²) with small n: 0.70
        - O(n²) with large n: 0.50
        - O(n³) or worse: 0.30
        """
        try:
            tree = ast.parse(code)

            # Detect nested loops (simple heuristic)
            max_nesting = self._count_loop_nesting(tree)

            if max_nesting == 0:
                return 1.0  # O(1) or O(n)
            elif max_nesting == 1:
                # Check for sorting operations
                if any(name in code for name in ['sort', 'sorted']):
                    return 0.85  # O(n log n)
                return 1.0  # O(n)
            elif max_nesting == 2:
                return 0.70  # O(n²)
            else:
                return 0.30  # O(n³) or worse

        except:
            return 0.5

    def _count_loop_nesting(self, tree: ast.AST, depth: int = 0) -> int:
        """Count maximum loop nesting depth."""
        max_depth = depth

        for node in ast.walk(tree):
            if isinstance(node, (ast.For, ast.While)):
                child_depth = self._count_loop_nesting(node, depth + 1)
                max_depth = max(max_depth, child_depth)

        return max_depth

    def _evaluate_space_complexity(self, code: str) -> float:
        """Evaluate memory usage efficiency."""
        # Simple heuristics for space complexity
        score = 1.0

        # Penalty for large data structure creation in loops
        if re.search(r'for.*:\s*\w+\s*=\s*\[.*\]', code):
            score *= 0.7

        # Penalty for excessive list comprehensions
        list_comp_count = code.count('[') + code.count('(')
        if list_comp_count > 5:
            score *= 0.8

        return max(0.3, score)

    def _evaluate_response_time(self, code: str) -> float:
        """Evaluate potential response time issues."""
        score = 1.0

        # Check for blocking operations
        blocking_patterns = [
            r'time\.sleep',
            r'input\(',
            r'\.wait\(',
        ]

        for pattern in blocking_patterns:
            if re.search(pattern, code):
                score *= 0.7

        # Check for database queries in loops (N+1 problem)
        if re.search(r'for.*:.*\.(execute|query|get|find)\(', code):
            score *= 0.5

        return max(0.3, score)

    def _generate_feedback(self, scores: Dict[str, float], code: str) -> List[str]:
        """Generate performance feedback."""
        feedback = []

        if scores['time_complexity'] < 0.85:
            feedback.append(
                "Time complexity issues detected. Consider optimizing "
                "nested loops or using more efficient algorithms."
            )

        if scores['space_complexity'] < 0.85:
            feedback.append(
                "Space complexity concerns. Review data structure usage "
                "and avoid unnecessary memory allocations in loops."
            )

        if scores['response_time'] < 0.85:
            feedback.append(
                "Response time bottlenecks found. Eliminate blocking "
                "operations and optimize database queries."
            )

        return feedback

    def _generate_recommendations(self, scores: Dict[str, float], code: str) -> List[str]:
        """Generate performance recommendations."""
        recommendations = []

        if scores['time_complexity'] < 0.90:
            recommendations.append("Replace nested loops with hash maps or sets where possible")
            recommendations.append("Consider using built-in functions (they're optimized in C)")

        if scores['space_complexity'] < 0.90:
            recommendations.append("Use generators instead of list comprehensions for large datasets")
            recommendations.append("Implement pagination for large result sets")

        if scores['response_time'] < 0.90:
            recommendations.append("Batch database queries to avoid N+1 problem")
            recommendations.append("Add caching for frequently accessed data")
            recommendations.append("Use asynchronous operations for I/O-bound tasks")

        return recommendations
