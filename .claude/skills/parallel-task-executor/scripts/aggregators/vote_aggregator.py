"""
Vote Aggregator - Aggregates voting results with weighted scoring.

This module aggregates results from multiple voting approaches to select the best solution.
"""

from typing import Dict, List, Any
from dataclasses import dataclass
from enum import Enum


class AggregationMethod(Enum):
    """Methods for aggregating votes."""
    WEIGHTED_SCORE = "weighted_score"
    CONSENSUS = "consensus"
    BALANCED = "balanced"
    MAJORITY = "majority"


@dataclass
class VoteCandidate:
    """Represents a voting candidate (approach)."""
    id: str
    approach: str
    scores: Dict[str, float]
    result: Any
    metadata: Dict[str, Any] = None

    def __post_init__(self):
        if self.metadata is None:
            self.metadata = {}

    @property
    def total_score(self) -> float:
        """Calculate total score across all criteria."""
        return sum(self.scores.values())

    @property
    def average_score(self) -> float:
        """Calculate average score."""
        return self.total_score / len(self.scores) if self.scores else 0.0


class VoteAggregator:
    """Aggregates voting results to select optimal solution."""

    def __init__(self, weights: Dict[str, float] = None):
        """
        Initialize vote aggregator.

        Args:
            weights: Optional weights for scoring criteria
        """
        self.weights = weights or {}

    def aggregate(
        self,
        candidates: List[VoteCandidate],
        method: AggregationMethod = AggregationMethod.WEIGHTED_SCORE
    ) -> Dict[str, Any]:
        """
        Aggregate votes and select winner.

        Args:
            candidates: List of voting candidates
            method: Aggregation method to use

        Returns:
            Aggregation result with winner and analysis
        """
        if not candidates:
            raise ValueError("No candidates to aggregate")

        if method == AggregationMethod.WEIGHTED_SCORE:
            winner = self._weighted_score_aggregation(candidates)
        elif method == AggregationMethod.CONSENSUS:
            winner = self._consensus_aggregation(candidates)
        elif method == AggregationMethod.BALANCED:
            winner = self._balanced_aggregation(candidates)
        elif method == AggregationMethod.MAJORITY:
            winner = self._majority_aggregation(candidates)
        else:
            raise ValueError(f"Unknown aggregation method: {method}")

        return {
            "winner": winner,
            "method": method.value,
            "vote_distribution": self._calculate_vote_distribution(candidates),
            "consensus_score": self._calculate_consensus_score(candidates),
            "ranking": self._rank_candidates(candidates, method),
            "analysis": self._generate_analysis(winner, candidates, method)
        }

    def _weighted_score_aggregation(self, candidates: List[VoteCandidate]) -> VoteCandidate:
        """
        Select winner using weighted scoring.

        Args:
            candidates: List of candidates

        Returns:
            Winning candidate
        """
        # Apply weights to scores
        weighted_candidates = []
        for candidate in candidates:
            weighted_score = sum(
                score * self.weights.get(criterion, 1.0)
                for criterion, score in candidate.scores.items()
            )
            candidate.metadata["weighted_score"] = weighted_score
            weighted_candidates.append((weighted_score, candidate))

        # Select candidate with highest weighted score
        return max(weighted_candidates, key=lambda x: x[0])[1]

    def _consensus_aggregation(self, candidates: List[VoteCandidate]) -> VoteCandidate:
        """
        Select winner based on consensus (most consistent scores).

        Args:
            candidates: List of candidates

        Returns:
            Winning candidate
        """
        # Calculate consistency (lower variance = higher consistency)
        for candidate in candidates:
            scores = list(candidate.scores.values())
            mean_score = sum(scores) / len(scores)
            variance = sum((s - mean_score) ** 2 for s in scores) / len(scores)
            candidate.metadata["consistency"] = 1.0 / (1.0 + variance)

        # Select candidate with highest consistency
        return max(candidates, key=lambda c: c.metadata["consistency"])

    def _balanced_aggregation(self, candidates: List[VoteCandidate]) -> VoteCandidate:
        """
        Select winner using balanced scoring (best average).

        Args:
            candidates: List of candidates

        Returns:
            Winning candidate
        """
        # Select candidate with highest average score
        return max(candidates, key=lambda c: c.average_score)

    def _majority_aggregation(self, candidates: List[VoteCandidate]) -> VoteCandidate:
        """
        Select winner that wins most criteria.

        Args:
            candidates: List of candidates

        Returns:
            Winning candidate
        """
        # Count wins per candidate
        criteria_winners: Dict[str, str] = {}
        all_criteria = set()
        for candidate in candidates:
            all_criteria.update(candidate.scores.keys())

        for criterion in all_criteria:
            # Find winner for this criterion
            winner = max(
                candidates,
                key=lambda c: c.scores.get(criterion, 0.0)
            )
            criteria_winners[criterion] = winner.id

        # Count wins per candidate
        win_counts = {}
        for candidate in candidates:
            wins = sum(1 for winner_id in criteria_winners.values() if winner_id == candidate.id)
            win_counts[candidate.id] = wins

        # Select candidate with most wins
        winner_id = max(win_counts.items(), key=lambda x: x[1])[0]
        return next(c for c in candidates if c.id == winner_id)

    def _calculate_vote_distribution(self, candidates: List[VoteCandidate]) -> Dict[str, Any]:
        """Calculate vote distribution statistics."""
        return {
            candidate.approach: {
                "scores": candidate.scores,
                "total": candidate.total_score,
                "average": candidate.average_score
            }
            for candidate in candidates
        }

    def _calculate_consensus_score(self, candidates: List[VoteCandidate]) -> float:
        """
        Calculate consensus score (0-1) based on agreement.

        Args:
            candidates: List of candidates

        Returns:
            Consensus score
        """
        if len(candidates) < 2:
            return 1.0

        # Calculate variance in total scores
        total_scores = [c.total_score for c in candidates]
        mean_score = sum(total_scores) / len(total_scores)
        variance = sum((s - mean_score) ** 2 for s in total_scores) / len(total_scores)

        # Convert variance to consensus (lower variance = higher consensus)
        max_variance = 100.0
        consensus = max(0.0, 1.0 - (variance / max_variance))

        return round(consensus, 2)

    def _rank_candidates(
        self,
        candidates: List[VoteCandidate],
        method: AggregationMethod
    ) -> List[Dict[str, Any]]:
        """
        Rank all candidates.

        Args:
            candidates: List of candidates
            method: Aggregation method used

        Returns:
            List of ranked candidates with scores
        """
        if method == AggregationMethod.WEIGHTED_SCORE:
            sorted_candidates = sorted(
                candidates,
                key=lambda c: c.metadata.get("weighted_score", c.total_score),
                reverse=True
            )
        elif method == AggregationMethod.CONSENSUS:
            sorted_candidates = sorted(
                candidates,
                key=lambda c: c.metadata.get("consistency", 0.0),
                reverse=True
            )
        else:
            sorted_candidates = sorted(
                candidates,
                key=lambda c: c.total_score,
                reverse=True
            )

        return [
            {
                "rank": i + 1,
                "approach": candidate.approach,
                "total_score": candidate.total_score,
                "average_score": candidate.average_score,
                "scores": candidate.scores
            }
            for i, candidate in enumerate(sorted_candidates)
        ]

    def _generate_analysis(
        self,
        winner: VoteCandidate,
        all_candidates: List[VoteCandidate],
        method: AggregationMethod
    ) -> str:
        """Generate analysis explaining the selection."""
        analysis = f"Selected {winner.approach} using {method.value} method. "

        # Winner's strengths
        best_criterion = max(winner.scores.items(), key=lambda x: x[1])
        analysis += f"Strongest in {best_criterion[0]} ({best_criterion[1]:.1f}/10). "

        # Comparison with runner-up
        other_candidates = [c for c in all_candidates if c.id != winner.id]
        if other_candidates:
            runner_up = max(other_candidates, key=lambda c: c.total_score)
            margin = winner.total_score - runner_up.total_score
            analysis += f"Margin over {runner_up.approach}: {margin:.1f} points."

        return analysis


def main():
    """Example usage of VoteAggregator."""
    # Create voting candidates
    candidates = [
        VoteCandidate(
            id="func_1",
            approach="functional",
            scores={"performance": 6.0, "readability": 9.0, "maintainability": 8.0},
            result={"code": "functional implementation"}
        ),
        VoteCandidate(
            id="oop_1",
            approach="oop",
            scores={"performance": 7.0, "readability": 7.0, "maintainability": 8.0},
            result={"code": "OOP implementation"}
        ),
        VoteCandidate(
            id="hybrid_1",
            approach="hybrid",
            scores={"performance": 10.0, "readability": 7.0, "maintainability": 9.0},
            result={"code": "hybrid implementation"}
        )
    ]

    # Aggregate with weighted scoring
    aggregator = VoteAggregator(weights={"performance": 1.5, "readability": 1.0, "maintainability": 1.2})
    result = aggregator.aggregate(candidates, method=AggregationMethod.WEIGHTED_SCORE)

    print(f"Winner: {result['winner'].approach}")
    print(f"Consensus score: {result['consensus_score']}")
    print(f"\nRanking:")
    for rank_info in result['ranking']:
        print(f"  {rank_info['rank']}. {rank_info['approach']} (score: {rank_info['total_score']:.1f})")
    print(f"\nAnalysis: {result['analysis']}")


if __name__ == "__main__":
    main()
