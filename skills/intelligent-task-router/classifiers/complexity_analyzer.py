"""
Task Complexity Analysis
Analyzes task complexity based on multiple factors including scope, dependencies, and technical depth.
"""

import re
import yaml
from pathlib import Path
from typing import Dict, List, Tuple


class ComplexityAnalyzer:
    """Analyzes task complexity using multiple heuristics."""

    def __init__(self, categories_path: str = None):
        """
        Initialize the complexity analyzer.

        Args:
            categories_path: Path to categories.yaml file
        """
        if categories_path is None:
            base_path = Path(__file__).parent.parent
            categories_path = base_path / "routing_rules" / "categories.yaml"

        with open(categories_path, 'r', encoding='utf-8') as f:
            self.config = yaml.safe_load(f)

        self.complexity_indicators = self.config.get('complexity_indicators', {})

    def analyze_scope(self, text: str) -> float:
        """
        Analyze the scope of the task (single file vs. system-wide).

        Args:
            text: Task description

        Returns:
            Scope score (0.0 to 1.0)
        """
        text_lower = text.lower()
        score = 0.3  # Base score

        # Check for high complexity indicators
        high_indicators = self.complexity_indicators.get('high', [])
        for indicator in high_indicators:
            if indicator.lower() in text_lower:
                score += 0.3

        # Check for medium complexity indicators
        medium_indicators = self.complexity_indicators.get('medium', [])
        for indicator in medium_indicators:
            if indicator.lower() in text_lower:
                score += 0.15

        # Check for low complexity indicators
        low_indicators = self.complexity_indicators.get('low', [])
        for indicator in low_indicators:
            if indicator.lower() in text_lower:
                score -= 0.1

        return min(max(score, 0.0), 1.0)

    def analyze_dependencies(self, text: str) -> float:
        """
        Analyze task dependencies and interconnections.

        Args:
            text: Task description

        Returns:
            Dependency score (0.0 to 1.0)
        """
        text_lower = text.lower()
        score = 0.2  # Base score

        # Indicators of dependencies
        dependency_keywords = [
            '통합', '연동', '연결', 'integrate', 'connect', 'link',
            '의존', 'depend', 'require',
            '여러', '다양한', 'multiple', 'various',
            '전체', '모든', 'all', 'entire'
        ]

        for keyword in dependency_keywords:
            if keyword.lower() in text_lower:
                score += 0.15

        return min(score, 1.0)

    def analyze_technical_depth(self, text: str) -> float:
        """
        Analyze the technical depth required.

        Args:
            text: Task description

        Returns:
            Technical depth score (0.0 to 1.0)
        """
        text_lower = text.lower()
        score = 0.3  # Base score

        # Advanced technical keywords
        advanced_keywords = [
            '아키텍처', '설계', 'architecture', 'design',
            '알고리즘', 'algorithm',
            '동시성', '병렬', 'concurrency', 'parallel',
            '분산', 'distributed',
            '보안', 'security',
            '성능', 'performance',
            '최적화', 'optimization'
        ]

        for keyword in advanced_keywords:
            if keyword.lower() in text_lower:
                score += 0.1

        return min(score, 1.0)

    def estimate_effort(self, text: str) -> Tuple[str, int]:
        """
        Estimate effort level and time.

        Args:
            text: Task description

        Returns:
            Tuple of (effort_level, estimated_minutes)
        """
        complexity = self.calculate_complexity(text)

        if complexity < 0.3:
            return "low", 15
        elif complexity < 0.6:
            return "medium", 45
        elif complexity < 0.8:
            return "high", 90
        else:
            return "very_high", 180

    def calculate_complexity(self, text: str, category: str = None) -> float:
        """
        Calculate overall complexity score.

        Args:
            text: Task description
            category: Optional category for weighted calculation

        Returns:
            Complexity score (0.0 to 1.0)
        """
        scope_score = self.analyze_scope(text)
        dependency_score = self.analyze_dependencies(text)
        technical_score = self.analyze_technical_depth(text)

        # Weighted average
        base_complexity = (
            scope_score * 0.4 +
            dependency_score * 0.3 +
            technical_score * 0.3
        )

        # Apply category weight if provided
        if category:
            categories = self.config.get('categories', {})
            category_data = categories.get(category, {})
            category_weight = category_data.get('complexity_weight', 0.5)

            # Blend base complexity with category weight
            final_complexity = (base_complexity * 0.7) + (category_weight * 0.3)
        else:
            final_complexity = base_complexity

        return min(max(final_complexity, 0.0), 1.0)

    def analyze(self, text: str, category: str = None) -> Dict[str, any]:
        """
        Perform complete complexity analysis.

        Args:
            text: Task description
            category: Optional category for context

        Returns:
            Dictionary containing detailed complexity analysis
        """
        complexity = self.calculate_complexity(text, category)
        effort_level, estimated_minutes = self.estimate_effort(text)

        return {
            'complexity_score': complexity,
            'scope_score': self.analyze_scope(text),
            'dependency_score': self.analyze_dependencies(text),
            'technical_depth_score': self.analyze_technical_depth(text),
            'effort_level': effort_level,
            'estimated_minutes': estimated_minutes
        }


def main():
    """Example usage of ComplexityAnalyzer."""
    analyzer = ComplexityAnalyzer()

    test_cases = [
        ("간단한 버그 수정해주세요", None),
        ("여러 모듈에 걸친 리팩토링을 해주세요", "refactoring"),
        ("전체 시스템 아키텍처를 재설계해주세요", "feature_development"),
        ("단일 파일의 주석을 추가해주세요", "documentation")
    ]

    for text, category in test_cases:
        result = analyzer.analyze(text, category)
        print(f"\n입력: {text}")
        print(f"카테고리: {category or 'N/A'}")
        print(f"복잡도 점수: {result['complexity_score']:.2f}")
        print(f"노력 수준: {result['effort_level']}")
        print(f"예상 시간: {result['estimated_minutes']}분")


if __name__ == "__main__":
    main()
