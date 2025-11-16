"""
Quality Report Generator

Generates comprehensive quality enhancement reports.
"""

from typing import Dict, Any, List
from datetime import datetime


class ReportGenerator:
    """Generate comprehensive quality enhancement reports."""

    def generate_report(
        self,
        initial_evaluation: Dict[str, Any],
        final_evaluation: Dict[str, Any],
        optimization_history: List[Dict[str, Any]],
        artifact_info: Dict[str, Any]
    ) -> str:
        """
        Generate final quality report.

        Args:
            initial_evaluation: Initial evaluation results
            final_evaluation: Final evaluation results
            optimization_history: History of all optimization iterations
            artifact_info: Information about the artifact

        Returns:
            Markdown formatted report
        """
        report_sections = []

        # Header
        report_sections.append(self._generate_header(artifact_info))

        # Executive Summary
        report_sections.append(self._generate_executive_summary(
            initial_evaluation,
            final_evaluation,
            optimization_history
        ))

        # Dimension Analysis
        report_sections.append(self._generate_dimension_analysis(
            initial_evaluation,
            final_evaluation
        ))

        # Optimization Journey
        report_sections.append(self._generate_optimization_journey(
            optimization_history
        ))

        # Applied Optimizations
        report_sections.append(self._generate_applied_optimizations(
            optimization_history
        ))

        # Recommendations
        report_sections.append(self._generate_recommendations(
            final_evaluation
        ))

        return "\n\n".join(report_sections)

    def _generate_header(self, artifact_info: Dict[str, Any]) -> str:
        """Generate report header."""
        artifact_type = artifact_info.get('type', 'Unknown')
        artifact_path = artifact_info.get('path', 'N/A')
        timestamp = datetime.utcnow().isoformat()

        return f"""# Quality Enhancement Report

**Artifact Type:** {artifact_type}
**Artifact Path:** {artifact_path}
**Generated:** {timestamp}

---"""

    def _generate_executive_summary(
        self,
        initial_eval: Dict[str, Any],
        final_eval: Dict[str, Any],
        history: List[Dict[str, Any]]
    ) -> str:
        """Generate executive summary."""
        initial_score = initial_eval.get('total_score', 0)
        final_score = final_eval.get('total_score', 0)
        improvement = final_score - initial_score
        iterations = len(history)

        # Extract key improvements
        key_improvements = []
        for iteration in history:
            changes = iteration.get('changes', [])
            key_improvements.extend([c.get('description') for c in changes[:2]])

        improvements_list = "\n".join(f"- {imp}" for imp in key_improvements[:5])

        return f"""## Executive Summary

- **Initial Quality Score:** {initial_score:.2f} ({initial_score*100:.0f}%)
- **Final Quality Score:** {final_score:.2f} ({final_score*100:.0f}%)
- **Total Improvement:** +{improvement:.2f} ({improvement*100:.0f} percentage points)
- **Iterations Completed:** {iterations}

### Key Improvements
{improvements_list}"""

    def _generate_dimension_analysis(
        self,
        initial_eval: Dict[str, Any],
        final_eval: Dict[str, Any]
    ) -> str:
        """Generate dimension-by-dimension analysis."""
        sections = ["## Dimension Analysis\n"]

        dimensions = ['functionality', 'performance', 'code_quality', 'security', 'documentation']

        for dimension in dimensions:
            initial = initial_eval.get(dimension, {})
            final = final_eval.get(dimension, {})

            initial_score = initial.get('score', 0)
            final_score = final.get('score', 0)
            threshold = final.get('threshold', 0)
            improvement = final_score - initial_score

            status = "✅ MEETS THRESHOLD" if final_score >= threshold else "⚠️ BELOW THRESHOLD"

            sections.append(f"""### {dimension.replace('_', ' ').title()}: {final_score:.2f} (threshold: {threshold:.2f}) {status}

**Initial Score:** {initial_score:.2f}
**Final Score:** {final_score:.2f}
**Improvement:** +{improvement:.2f}

**Analysis:** {self._analyze_dimension(dimension, initial_score, final_score, threshold)}""")

        return "\n\n".join(sections)

    def _analyze_dimension(
        self,
        dimension: str,
        initial: float,
        final: float,
        threshold: float
    ) -> str:
        """Analyze a specific dimension."""
        if final >= threshold:
            return f"Successfully met quality threshold through targeted optimizations."
        elif final > initial:
            return f"Improved but still below threshold. Additional work needed."
        else:
            return f"No improvement in this dimension. May require different approach."

    def _generate_optimization_journey(
        self,
        history: List[Dict[str, Any]]
    ) -> str:
        """Generate iteration-by-iteration optimization journey."""
        sections = ["## Optimization Journey\n"]

        for i, iteration in enumerate(history, 1):
            focus = iteration.get('focus', 'Unknown')
            changes = iteration.get('changes', [])
            scores = iteration.get('evaluation', {})

            changes_list = "\n".join(f"  - {c.get('description')}" for c in changes[:3])

            sections.append(f"""### Iteration {i}

**Focus:** {focus}

**Changes Made:**
{changes_list}

**Impact:** Score improved from {scores.get('previous', 0):.2f} to {scores.get('current', 0):.2f}""")

        return "\n\n".join(sections)

    def _generate_applied_optimizations(
        self,
        history: List[Dict[str, Any]]
    ) -> str:
        """Generate detailed list of all optimizations."""
        sections = ["## Applied Optimizations\n"]

        all_changes = []
        for i, iteration in enumerate(history, 1):
            changes = iteration.get('changes', [])
            for change in changes:
                all_changes.append({
                    'iteration': i,
                    'target': change.get('type'),
                    'description': change.get('description'),
                    'impact': change.get('impact', 'Unknown')
                })

        if all_changes:
            table = ["| Iteration | Target | Description | Impact |",
                    "|-----------|--------|-------------|--------|"]

            for change in all_changes:
                table.append(f"| {change['iteration']} | {change['target']} | {change['description']} | {change['impact']} |")

            sections.append("\n".join(table))
        else:
            sections.append("No optimizations were applied.")

        return "\n\n".join(sections)

    def _generate_recommendations(
        self,
        final_eval: Dict[str, Any]
    ) -> str:
        """Generate future recommendations."""
        sections = ["## Recommendations\n"]

        recommendations = []

        # Check each dimension for unmet thresholds
        dimensions = ['functionality', 'performance', 'code_quality', 'security', 'documentation']

        for dimension in dimensions:
            dim_eval = final_eval.get(dimension, {})
            score = dim_eval.get('score', 0)
            threshold = dim_eval.get('threshold', 0)

            if score < threshold:
                dim_recs = dim_eval.get('recommendations', [])
                recommendations.extend(dim_recs[:2])

        # Add general recommendations
        recommendations.extend([
            "Consider adding integration tests for critical workflows",
            "Implement continuous quality monitoring",
            "Schedule regular security audits"
        ])

        for i, rec in enumerate(recommendations[:8], 1):
            sections.append(f"{i}. {rec}")

        return "\n".join(sections)


# Report template constants
REPORT_TEMPLATE = """
# Quality Enhancement Report

## Executive Summary
- Initial Quality Score: {initial_score}
- Final Quality Score: {final_score}
- Iterations: {iterations}

## Dimension Analysis
{dimension_analysis}

## Optimization Journey
{optimization_journey}

## Recommendations
{recommendations}
"""
