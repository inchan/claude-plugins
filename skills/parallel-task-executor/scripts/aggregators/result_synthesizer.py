"""
Result Synthesizer - Synthesizes hybrid solutions from multiple approaches.

This module combines the best elements from multiple voting approaches into a hybrid solution.
"""

from typing import Dict, List, Any, Set
from dataclasses import dataclass


@dataclass
class ApproachElement:
    """Represents an element from a specific approach."""
    approach_id: str
    element_type: str  # function, class, pattern, etc.
    element_id: str
    content: Any
    score: float
    benefits: List[str]


class ResultSynthesizer:
    """Synthesizes hybrid solutions from multiple approaches."""

    def __init__(self):
        """Initialize result synthesizer."""
        self.selected_elements: List[ApproachElement] = []

    def synthesize(
        self,
        approaches: Dict[str, Any],
        criteria: Dict[str, float]
    ) -> Dict[str, Any]:
        """
        Synthesize hybrid solution from multiple approaches.

        Args:
            approaches: Dict of approach_id -> approach data
            criteria: Evaluation criteria with weights

        Returns:
            Synthesized solution with rationale
        """
        # Extract elements from each approach
        all_elements = self._extract_elements(approaches)

        # Score elements based on criteria
        scored_elements = self._score_elements(all_elements, criteria)

        # Select best elements (avoiding conflicts)
        selected = self._select_best_elements(scored_elements)

        # Combine into hybrid solution
        hybrid = self._combine_elements(selected)

        return {
            "hybrid_solution": hybrid,
            "elements_used": len(selected),
            "sources": self._get_sources(selected),
            "synthesis_rationale": self._generate_rationale(selected, criteria),
            "benefits": self._aggregate_benefits(selected)
        }

    def _extract_elements(self, approaches: Dict[str, Any]) -> List[ApproachElement]:
        """
        Extract individual elements from each approach.

        Args:
            approaches: Approach data

        Returns:
            List of elements
        """
        elements = []

        for approach_id, approach_data in approaches.items():
            # Extract functions
            functions = approach_data.get("functions", {})
            for func_id, func_data in functions.items():
                elements.append(
                    ApproachElement(
                        approach_id=approach_id,
                        element_type="function",
                        element_id=func_id,
                        content=func_data,
                        score=0.0,
                        benefits=func_data.get("benefits", [])
                    )
                )

            # Extract classes
            classes = approach_data.get("classes", {})
            for class_id, class_data in classes.items():
                elements.append(
                    ApproachElement(
                        approach_id=approach_id,
                        element_type="class",
                        element_id=class_id,
                        content=class_data,
                        score=0.0,
                        benefits=class_data.get("benefits", [])
                    )
                )

            # Extract patterns
            patterns = approach_data.get("patterns", {})
            for pattern_id, pattern_data in patterns.items():
                elements.append(
                    ApproachElement(
                        approach_id=approach_id,
                        element_type="pattern",
                        element_id=pattern_id,
                        content=pattern_data,
                        score=0.0,
                        benefits=pattern_data.get("benefits", [])
                    )
                )

        return elements

    def _score_elements(
        self,
        elements: List[ApproachElement],
        criteria: Dict[str, float]
    ) -> List[ApproachElement]:
        """
        Score elements based on evaluation criteria.

        Args:
            elements: List of elements to score
            criteria: Criteria with weights

        Returns:
            Elements with updated scores
        """
        for element in elements:
            # Calculate weighted score
            element_scores = element.content.get("scores", {})
            weighted_score = sum(
                element_scores.get(criterion, 5.0) * weight
                for criterion, weight in criteria.items()
            )
            element.score = weighted_score

        return elements

    def _select_best_elements(self, elements: List[ApproachElement]) -> List[ApproachElement]:
        """
        Select best elements while avoiding conflicts.

        Args:
            elements: Scored elements

        Returns:
            Selected elements
        """
        # Group elements by element_id
        grouped: Dict[str, List[ApproachElement]] = {}
        for element in elements:
            if element.element_id not in grouped:
                grouped[element.element_id] = []
            grouped[element.element_id].append(element)

        # Select best element from each group
        selected = []
        for element_id, candidates in grouped.items():
            # Choose candidate with highest score
            best = max(candidates, key=lambda e: e.score)
            selected.append(best)

        return selected

    def _combine_elements(self, elements: List[ApproachElement]) -> Dict[str, Any]:
        """
        Combine selected elements into hybrid solution.

        Args:
            elements: Selected elements

        Returns:
            Combined solution
        """
        hybrid = {
            "functions": {},
            "classes": {},
            "patterns": {},
            "imports": set(),
            "metadata": {}
        }

        for element in elements:
            if element.element_type == "function":
                hybrid["functions"][element.element_id] = element.content
            elif element.element_type == "class":
                hybrid["classes"][element.element_id] = element.content
            elif element.element_type == "pattern":
                hybrid["patterns"][element.element_id] = element.content

            # Collect imports
            element_imports = element.content.get("imports", [])
            hybrid["imports"].update(element_imports)

        # Convert imports set to list
        hybrid["imports"] = list(hybrid["imports"])

        return hybrid

    def _get_sources(self, elements: List[ApproachElement]) -> Dict[str, int]:
        """
        Get source distribution of selected elements.

        Args:
            elements: Selected elements

        Returns:
            Dict of approach_id -> count
        """
        sources = {}
        for element in elements:
            approach_id = element.approach_id
            sources[approach_id] = sources.get(approach_id, 0) + 1
        return sources

    def _generate_rationale(
        self,
        elements: List[ApproachElement],
        criteria: Dict[str, float]
    ) -> str:
        """
        Generate rationale for synthesis decisions.

        Args:
            elements: Selected elements
            criteria: Evaluation criteria

        Returns:
            Rationale string
        """
        sources = self._get_sources(elements)
        total_elements = len(elements)

        rationale = f"Synthesized hybrid solution from {len(sources)} approaches. "

        # Distribution
        distribution = ", ".join(
            f"{count} from {approach_id}"
            for approach_id, count in sources.items()
        )
        rationale += f"Distribution: {distribution}. "

        # Top criterion
        if criteria:
            top_criterion = max(criteria.items(), key=lambda x: x[1])
            rationale += f"Prioritized {top_criterion[0]} (weight: {top_criterion[1]})."

        return rationale

    def _aggregate_benefits(self, elements: List[ApproachElement]) -> List[str]:
        """
        Aggregate benefits from selected elements.

        Args:
            elements: Selected elements

        Returns:
            List of unique benefits
        """
        all_benefits: Set[str] = set()
        for element in elements:
            all_benefits.update(element.benefits)
        return sorted(all_benefits)

    def merge_implementations(
        self,
        implementations: Dict[str, str],
        strategy: str = "best_of_breed"
    ) -> str:
        """
        Merge multiple implementations into one.

        Args:
            implementations: Dict of approach -> code
            strategy: Merging strategy (best_of_breed, composite, layered)

        Returns:
            Merged implementation
        """
        if strategy == "best_of_breed":
            # Select best implementation as base
            # (In real implementation, would analyze code quality)
            return self._best_of_breed_merge(implementations)
        elif strategy == "composite":
            # Combine implementations side-by-side
            return self._composite_merge(implementations)
        elif strategy == "layered":
            # Layer implementations with abstraction
            return self._layered_merge(implementations)
        else:
            raise ValueError(f"Unknown merge strategy: {strategy}")

    def _best_of_breed_merge(self, implementations: Dict[str, str]) -> str:
        """Select single best implementation."""
        # Simplified: just take the longest implementation
        return max(implementations.values(), key=len)

    def _composite_merge(self, implementations: Dict[str, str]) -> str:
        """Combine implementations side-by-side."""
        merged_parts = []
        for approach, code in implementations.items():
            merged_parts.append(f"# {approach.upper()} APPROACH\n{code}")
        return "\n\n".join(merged_parts)

    def _layered_merge(self, implementations: Dict[str, str]) -> str:
        """Layer implementations with abstraction."""
        # Create abstraction layer
        abstraction = "# ABSTRACTION LAYER\nclass HybridSolution:\n    pass\n\n"

        # Add each implementation as a strategy
        strategies = []
        for approach, code in implementations.items():
            strategies.append(f"# {approach} strategy\n{code}")

        return abstraction + "\n\n".join(strategies)


def main():
    """Example usage of ResultSynthesizer."""
    synthesizer = ResultSynthesizer()

    # Example approaches
    approaches = {
        "functional": {
            "functions": {
                "process_data": {
                    "code": "def process_data(items): return [x * 2 for x in items]",
                    "scores": {"performance": 6, "readability": 9, "maintainability": 8},
                    "benefits": ["Immutable", "Pure function"],
                    "imports": ["typing"]
                }
            },
            "patterns": {
                "map_reduce": {
                    "code": "map/reduce pattern",
                    "scores": {"performance": 7, "readability": 8, "maintainability": 7},
                    "benefits": ["Composable", "Testable"]
                }
            }
        },
        "oop": {
            "classes": {
                "DataProcessor": {
                    "code": "class DataProcessor: ...",
                    "scores": {"performance": 7, "readability": 7, "maintainability": 9},
                    "benefits": ["Encapsulation", "Extensible"],
                    "imports": ["abc"]
                }
            }
        },
        "hybrid": {
            "functions": {
                "process_data": {
                    "code": "def process_data(items): return ProcessingEngine(items).execute()",
                    "scores": {"performance": 10, "readability": 7, "maintainability": 9},
                    "benefits": ["Fast", "Flexible"],
                    "imports": ["typing", "dataclasses"]
                }
            }
        }
    }

    # Synthesis criteria
    criteria = {
        "performance": 1.5,
        "readability": 1.0,
        "maintainability": 1.2
    }

    # Synthesize
    result = synthesizer.synthesize(approaches, criteria)

    print("Synthesis Result:")
    print(f"Elements used: {result['elements_used']}")
    print(f"Sources: {result['sources']}")
    print(f"Benefits: {', '.join(result['benefits'])}")
    print(f"\nRationale: {result['synthesis_rationale']}")


if __name__ == "__main__":
    main()
