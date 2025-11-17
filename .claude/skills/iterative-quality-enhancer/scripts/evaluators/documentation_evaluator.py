"""Documentation Evaluator - Completeness, clarity, examples."""

from typing import Dict, Any, List
import ast
import re


class DocumentationEvaluator:
    """Evaluate documentation: completeness, clarity, examples."""

    def __init__(self, weight: float = 0.15, threshold: float = 0.85):
        self.weight = weight
        self.threshold = threshold

    def evaluate(self, artifact: Dict[str, Any]) -> Dict[str, Any]:
        """Evaluate documentation dimension."""
        code = artifact.get('code', '')
        readme = artifact.get('readme', '')

        scores = {
            'completeness': self._check_completeness(code, readme),
            'clarity': self._check_clarity(code, readme),
            'examples': self._check_examples(code, readme)
        }

        total_score = sum(scores.values()) / len(scores)

        return {
            'dimension': 'documentation',
            'score': total_score,
            'weight': self.weight,
            'threshold': self.threshold,
            'meets_threshold': total_score >= self.threshold,
            'sub_scores': scores,
            'feedback': self._generate_feedback(scores),
            'recommendations': self._generate_recommendations(scores)
        }

    def _check_completeness(self, code: str, readme: str) -> float:
        """Check documentation completeness."""
        score = 0.0

        try:
            tree = ast.parse(code)

            # Check for docstrings
            functions = [n for n in ast.walk(tree) if isinstance(n, ast.FunctionDef)]
            if functions:
                documented = sum(1 for f in functions if ast.get_docstring(f))
                score = documented / len(functions)

            # Bonus for README
            if readme:
                score = min(1.0, score + 0.2)

        except:
            score = 0.3

        return score

    def _check_clarity(self, code: str, readme: str) -> float:
        """Check documentation clarity."""
        score = 1.0

        # Check for meaningful docstrings (not just placeholder text)
        docstrings = re.findall(r'"""(.*?)"""', code, re.DOTALL)
        placeholder_words = ['todo', 'tbd', 'fixme', 'xxx']

        for docstring in docstrings:
            if any(word in docstring.lower() for word in placeholder_words):
                score *= 0.7
            if len(docstring.strip()) < 10:
                score *= 0.8

        return max(0.3, score)

    def _check_examples(self, code: str, readme: str) -> float:
        """Check for usage examples."""
        score = 0.5  # Default neutral

        # Look for example code in docstrings or README
        has_examples = (
            'example' in code.lower() or
            'usage' in code.lower() or
            '>>>' in code or
            'example' in readme.lower()
        )

        if has_examples:
            score = 0.9

        return score

    def _generate_feedback(self, scores: Dict[str, float]) -> List[str]:
        """Generate documentation feedback."""
        feedback = []

        if scores['completeness'] < 0.85:
            feedback.append("Documentation incomplete: Add docstrings to all public functions")

        if scores['clarity'] < 0.85:
            feedback.append("Documentation clarity issues: Replace placeholder text")

        if scores['examples'] < 0.85:
            feedback.append("Missing usage examples: Add practical code examples")

        return feedback

    def _generate_recommendations(self, scores: Dict[str, float]) -> List[str]:
        """Generate documentation recommendations."""
        recommendations = []

        if scores['completeness'] < 0.90:
            recommendations.append("Add docstrings with Args, Returns, and Raises sections")
            recommendations.append("Create README with project overview and setup instructions")

        if scores['clarity'] < 0.90:
            recommendations.append("Write clear, concise descriptions")
            recommendations.append("Use proper grammar and formatting")

        if scores['examples'] < 0.90:
            recommendations.append("Include code examples in docstrings")
            recommendations.append("Add usage examples in README")
            recommendations.append("Provide common use cases")

        return recommendations
