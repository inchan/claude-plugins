"""
Feedback Generator

Generates actionable, prioritized feedback from evaluation results.
"""

from typing import Dict, Any, List


class FeedbackGenerator:
    """
    Generate prioritized, actionable feedback from evaluation results.

    Feedback prioritization formula:
    priority = (threshold - score) × dimension_weight
    """

    def generate(
        self,
        evaluation_results: List[Dict[str, Any]],
        iteration: int
    ) -> List[Dict[str, Any]]:
        """
        Generate prioritized feedback from evaluation results.

        Args:
            evaluation_results: List of dimension evaluation results
            iteration: Current iteration number

        Returns:
            List of prioritized feedback items
        """
        feedback_items = []

        for result in evaluation_results:
            dimension = result['dimension']
            score = result['score']
            threshold = result['threshold']
            weight = result['weight']
            dimension_feedback = result.get('feedback', [])

            # Calculate priority (gap × weight)
            gap = max(0, threshold - score)
            priority = gap * weight

            if gap > 0:
                for item in dimension_feedback:
                    feedback_items.append({
                        'dimension': dimension,
                        'priority': priority,
                        'score': score,
                        'threshold': threshold,
                        'gap': gap,
                        'issue': item,
                        'recommendations': result.get('recommendations', []),
                        'iteration': iteration
                    })

        # Sort by priority (highest first)
        feedback_items.sort(key=lambda x: x['priority'], reverse=True)

        return feedback_items

    def format_feedback(self, feedback_items: List[Dict[str, Any]]) -> str:
        """
        Format feedback for display.

        Returns:
            Formatted feedback string
        """
        if not feedback_items:
            return "✅ All quality thresholds met!"

        output = ["## Prioritized Feedback\n"]

        for i, item in enumerate(feedback_items, 1):
            dimension = item['dimension'].replace('_', ' ').title()
            score = item['score']
            threshold = item['threshold']
            issue = item['issue']

            output.append(f"### Priority {i} - {dimension} ({score:.2f}/{threshold:.2f})")
            output.append(f"- **Issue:** {issue}")

            if item['recommendations']:
                output.append("- **Recommendations:**")
                for rec in item['recommendations'][:3]:  # Top 3 recommendations
                    output.append(f"  - {rec}")

            output.append("")

        return "\n".join(output)


class PriorityCalculator:
    """
    Calculate optimization priorities based on impact analysis.

    Priority factors:
    1. Dimension weight
    2. Gap from threshold
    3. Ease of fix
    4. Risk of change
    """

    def calculate_priority(
        self,
        dimension: str,
        score: float,
        threshold: float,
        weight: float,
        ease_of_fix: float = 0.5
    ) -> float:
        """
        Calculate optimization priority.

        Args:
            dimension: Quality dimension name
            score: Current dimension score
            threshold: Dimension threshold
            weight: Dimension weight
            ease_of_fix: Estimated ease of fixing (0-1)

        Returns:
            Priority score (higher = more urgent)
        """
        gap = max(0, threshold - score)

        # Base priority: gap × weight
        base_priority = gap * weight

        # Adjust for ease of fix (easier fixes get slight boost)
        adjusted_priority = base_priority * (0.8 + 0.4 * ease_of_fix)

        # Critical threshold violations get significant boost
        if score < 0.5:
            adjusted_priority *= 1.5

        return adjusted_priority


# Example feedback format
FEEDBACK_TEMPLATE = """
Priority {priority} - {dimension} ({score:.2f}/{threshold:.2f}):
- Issue: {issue}
- Action: {action}
- Expected Impact: {expected_impact}
- Difficulty: {difficulty}
"""

# Impact estimation guide
IMPACT_GUIDE = {
    'security': {
        'sql_injection': {'impact': '+0.20', 'difficulty': 'Easy'},
        'weak_hashing': {'impact': '+0.20', 'difficulty': 'Medium'},
        'no_auth': {'impact': '+0.15', 'difficulty': 'Hard'}
    },
    'performance': {
        'n_plus_1': {'impact': '+0.25', 'difficulty': 'Medium'},
        'nested_loops': {'impact': '+0.20', 'difficulty': 'Medium'},
        'no_caching': {'impact': '+0.10', 'difficulty': 'Easy'}
    },
    'code_quality': {
        'long_function': {'impact': '+0.10', 'difficulty': 'Medium'},
        'duplication': {'impact': '+0.08', 'difficulty': 'Easy'},
        'poor_naming': {'impact': '+0.05', 'difficulty': 'Easy'}
    }
}
