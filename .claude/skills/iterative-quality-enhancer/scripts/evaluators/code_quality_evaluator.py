"""Code Quality Evaluator - Readability, maintainability, modularity evaluation."""

from typing import Dict, Any, List
import ast


class CodeQualityEvaluator:
    """Evaluate code quality: readability, maintainability, modularity."""

    def __init__(self, weight: float = 0.20, threshold: float = 0.90):
        self.weight = weight
        self.threshold = threshold

    def evaluate(self, artifact: Dict[str, Any]) -> Dict[str, Any]:
        """Evaluate code quality dimension."""
        code = artifact.get('code', '')

        scores = {
            'readability': self._evaluate_readability(code),
            'maintainability': self._evaluate_maintainability(code),
            'modularity': self._evaluate_modularity(code)
        }

        total_score = sum(scores.values()) / len(scores)

        return {
            'dimension': 'code_quality',
            'score': total_score,
            'weight': self.weight,
            'threshold': self.threshold,
            'meets_threshold': total_score >= self.threshold,
            'sub_scores': scores,
            'feedback': self._generate_feedback(scores, code),
            'recommendations': self._generate_recommendations(scores, code)
        }

    def _evaluate_readability(self, code: str) -> float:
        """Check naming, formatting, comments."""
        score = 1.0

        try:
            tree = ast.parse(code)

            # Check for descriptive names (> 2 chars)
            short_names = 0
            total_names = 0

            for node in ast.walk(tree):
                if isinstance(node, ast.Name):
                    total_names += 1
                    if len(node.id) <= 2 and node.id not in ['i', 'j', 'k', 'x', 'y']:
                        short_names += 1

            if total_names > 0:
                score *= (1 - short_names / total_names)

            # Check for comments
            comment_lines = code.count('#')
            code_lines = len([l for l in code.split('\n') if l.strip()])
            if code_lines > 0:
                comment_ratio = comment_lines / code_lines
                if comment_ratio < 0.1:
                    score *= 0.8

        except:
            score = 0.5

        return max(0.3, score)

    def _evaluate_maintainability(self, code: str) -> float:
        """Check function length, complexity."""
        score = 1.0

        try:
            tree = ast.parse(code)

            for node in ast.walk(tree):
                if isinstance(node, ast.FunctionDef):
                    # Check function length
                    func_lines = len(node.body)
                    if func_lines > 50:
                        score *= 0.6
                    elif func_lines > 30:
                        score *= 0.8

                    # Check cyclomatic complexity (simplified)
                    complexity = self._calculate_complexity(node)
                    if complexity > 20:
                        score *= 0.6
                    elif complexity > 10:
                        score *= 0.85

        except:
            score = 0.5

        return max(0.3, score)

    def _calculate_complexity(self, node: ast.FunctionDef) -> int:
        """Calculate cyclomatic complexity."""
        complexity = 1
        for child in ast.walk(node):
            if isinstance(child, (ast.If, ast.While, ast.For, ast.ExceptHandler)):
                complexity += 1
        return complexity

    def _evaluate_modularity(self, code: str) -> float:
        """Check function organization and reusability."""
        score = 1.0

        try:
            tree = ast.parse(code)

            functions = [n for n in ast.walk(tree) if isinstance(n, ast.FunctionDef)]

            if not functions:
                score *= 0.5  # No functions = poor modularity
            elif len(functions) == 1:
                score *= 0.7  # Single function might be too monolithic

        except:
            score = 0.5

        return max(0.3, score)

    def _generate_feedback(self, scores: Dict[str, float], code: str) -> List[str]:
        """Generate code quality feedback."""
        feedback = []

        if scores['readability'] < 0.90:
            feedback.append("Readability issues: Use descriptive variable names and add comments")

        if scores['maintainability'] < 0.90:
            feedback.append("Maintainability concerns: Reduce function length and complexity")

        if scores['modularity'] < 0.90:
            feedback.append("Modularity gaps: Break code into smaller, reusable functions")

        return feedback

    def _generate_recommendations(self, scores: Dict[str, float], code: str) -> List[str]:
        """Generate code quality recommendations."""
        recommendations = []

        if scores['readability'] < 0.90:
            recommendations.append("Use descriptive names (avoid single letters except in loops)")
            recommendations.append("Add docstrings to all functions")

        if scores['maintainability'] < 0.90:
            recommendations.append("Keep functions under 50 lines")
            recommendations.append("Reduce cyclomatic complexity to < 10")

        if scores['modularity'] < 0.90:
            recommendations.append("Extract repeated code into functions")
            recommendations.append("Follow Single Responsibility Principle")

        return recommendations
