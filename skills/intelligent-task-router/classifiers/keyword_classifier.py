"""
Keyword-based Task Classification
Analyzes task requests using keyword matching to identify primary and secondary categories.
"""

import re
import yaml
from pathlib import Path
from typing import Dict, List, Tuple


class KeywordClassifier:
    """Classifies tasks based on keyword matching."""

    def __init__(self, categories_path: str = None):
        """
        Initialize the classifier with categories from YAML file.

        Args:
            categories_path: Path to categories.yaml file
        """
        if categories_path is None:
            # Default path relative to this file
            base_path = Path(__file__).parent.parent
            categories_path = base_path / "routing_rules" / "categories.yaml"

        with open(categories_path, 'r', encoding='utf-8') as f:
            self.config = yaml.safe_load(f)

        self.categories = self.config['categories']

    def extract_keywords(self, text: str) -> List[str]:
        """
        Extract meaningful keywords from text.

        Args:
            text: Input text to analyze

        Returns:
            List of extracted keywords
        """
        # Convert to lowercase for matching
        text = text.lower()

        # Split into words
        words = re.findall(r'\b\w+\b', text)

        return words

    def calculate_category_scores(self, text: str) -> Dict[str, float]:
        """
        Calculate matching scores for each category.

        Args:
            text: Input text to analyze

        Returns:
            Dictionary of category names and their scores
        """
        text_lower = text.lower()
        scores = {}

        for category_name, category_data in self.categories.items():
            keywords = category_data['keywords']
            matches = sum(1 for keyword in keywords if keyword.lower() in text_lower)

            # Normalize by number of keywords
            score = matches / len(keywords) if keywords else 0.0
            scores[category_name] = score

        return scores

    def classify(self, text: str, threshold: float = 0.1) -> Tuple[str, List[str], float]:
        """
        Classify task into primary and secondary categories.

        Args:
            text: Task description
            threshold: Minimum score threshold for classification

        Returns:
            Tuple of (primary_category, secondary_categories, confidence)
        """
        scores = self.calculate_category_scores(text)

        # Sort categories by score
        sorted_categories = sorted(scores.items(), key=lambda x: x[1], reverse=True)

        # Get primary category
        primary_category = sorted_categories[0][0] if sorted_categories else "unknown"
        primary_score = sorted_categories[0][1] if sorted_categories else 0.0

        # Get secondary categories (above threshold but not primary)
        secondary_categories = [
            cat for cat, score in sorted_categories[1:]
            if score >= threshold
        ]

        # Calculate confidence based on primary score and gap to second
        if len(sorted_categories) > 1:
            gap = primary_score - sorted_categories[1][1]
            confidence = min(primary_score + gap, 1.0)
        else:
            confidence = primary_score

        return primary_category, secondary_categories, confidence


def main():
    """Example usage of KeywordClassifier."""
    classifier = KeywordClassifier()

    test_cases = [
        "버그를 수정해주세요",
        "새로운 로그인 기능을 개발하고 테스트도 작성해주세요",
        "코드를 리팩토링하고 성능을 최적화해주세요",
        "데이터베이스 보안 취약점을 수정해주세요"
    ]

    for text in test_cases:
        primary, secondary, confidence = classifier.classify(text)
        print(f"\n입력: {text}")
        print(f"주 카테고리: {primary}")
        print(f"부 카테고리: {secondary}")
        print(f"신뢰도: {confidence:.2f}")


if __name__ == "__main__":
    main()
