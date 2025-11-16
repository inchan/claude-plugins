"""
Voting Executor - Implements multi-approach voting for optimal solution selection.

This module executes the same task using multiple approaches and aggregates
results to select the optimal solution based on evaluation criteria.
"""

import json
import time
from typing import Dict, List, Any, Optional
from dataclasses import dataclass
from concurrent.futures import ThreadPoolExecutor, as_completed


@dataclass
class Voter:
    """Represents a single voting approach."""
    id: str
    approach: str  # functional, oop, reactive, etc.
    description: str
    status: str = "pending"
    result: Optional[Any] = None
    scores: Dict[str, float] = None
    execution_time: float = 0.0

    def __post_init__(self):
        if self.scores is None:
            self.scores = {}


class VotingExecutor:
    """Executes multiple approaches and selects optimal solution through voting."""

    def __init__(self, config: Dict[str, Any]):
        """
        Initialize voting executor with configuration.

        Args:
            config: Configuration dict with parallelism settings
        """
        self.config = config
        self.max_workers = config.get("parallelism", {}).get("max_workers", 10)
        self.timeout = config.get("timeouts", {}).get("default_task", 180)

    def execute(self, main_task: Dict[str, Any]) -> Dict[str, Any]:
        """
        Execute task using multiple approaches and vote on best solution.

        Args:
            main_task: Task description with evaluation criteria

        Returns:
            Voting results with winner and decision rationale
        """
        start_time = time.time()

        # Create voters for different approaches
        voters = self._create_voters(main_task)

        # Execute all voters in parallel
        self._execute_voters(voters)

        # Score each voter based on evaluation criteria
        self._score_voters(voters, main_task.get("evaluation_criteria", []))

        # Aggregate votes and select winner
        winner = self._select_winner(voters, main_task.get("aggregation", "weighted_score"))

        execution_time = time.time() - start_time

        return {
            "task_id": main_task.get("task_id", "unknown"),
            "execution_summary": {
                "total_voters": len(voters),
                "execution_time": f"{execution_time:.1f}s",
                "aggregation_method": main_task.get("aggregation", "weighted_score")
            },
            "results": {
                "mode": "voting",
                "winner": winner.approach,
                "winner_details": {
                    "approach": winner.approach,
                    "description": winner.description,
                    "scores": winner.scores,
                    "total_score": sum(winner.scores.values()),
                    "result": winner.result
                },
                "vote_distribution": {
                    voter.approach: {
                        "scores": voter.scores,
                        "total": sum(voter.scores.values())
                    }
                    for voter in voters
                },
                "consensus_score": self._calculate_consensus(voters),
                "all_approaches": [
                    {
                        "approach": voter.approach,
                        "status": voter.status,
                        "execution_time": voter.execution_time
                    }
                    for voter in voters
                ]
            },
            "decision_rationale": self._generate_rationale(winner, voters)
        }

    def _create_voters(self, main_task: Dict[str, Any]) -> List[Voter]:
        """
        Create voters for different approaches.

        Args:
            main_task: Task description

        Returns:
            List of Voter objects
        """
        voter_approaches = main_task.get("voters", ["functional", "oop", "reactive"])
        voters = []

        for approach in voter_approaches:
            voter = Voter(
                id=f"voter_{approach}",
                approach=approach,
                description=f"{approach.capitalize()} implementation approach"
            )
            voters.append(voter)

        return voters

    def _execute_voters(self, voters: List[Voter]) -> None:
        """
        Execute all voters in parallel.

        Args:
            voters: List of voters to execute
        """
        max_workers = min(len(voters), self.max_workers)

        with ThreadPoolExecutor(max_workers=max_workers) as executor:
            futures = {
                executor.submit(self._execute_voter, voter): voter
                for voter in voters
            }

            for future in as_completed(futures):
                voter = futures[future]
                try:
                    future.result()
                except Exception as e:
                    voter.status = "failed"
                    voter.result = {"error": str(e)}

    def _execute_voter(self, voter: Voter) -> None:
        """
        Execute a single voter approach.

        Args:
            voter: Voter to execute
        """
        start_time = time.time()
        voter.status = "running"

        try:
            # Simulate voter execution
            # In real implementation, this would spawn Task tool with specific approach
            voter.result = {
                "approach": voter.approach,
                "implementation": f"Implemented using {voter.approach} paradigm",
                "code": f"# {voter.approach} implementation code here"
            }
            voter.status = "completed"
        except Exception as e:
            voter.status = "failed"
            voter.result = {"error": str(e)}
        finally:
            voter.execution_time = time.time() - start_time

    def _score_voters(self, voters: List[Voter], criteria: List[str]) -> None:
        """
        Score each voter based on evaluation criteria.

        Args:
            voters: List of voters to score
            criteria: Evaluation criteria (performance, readability, maintainability, etc.)
        """
        default_criteria = ["performance", "readability", "maintainability"]
        if not criteria:
            criteria = default_criteria

        for voter in voters:
            if voter.status == "completed":
                # Simulate scoring (in real implementation, would run benchmarks/analysis)
                voter.scores = self._simulate_scores(voter.approach, criteria)

    def _simulate_scores(self, approach: str, criteria: List[str]) -> Dict[str, float]:
        """
        Simulate scoring for demonstration purposes.

        Args:
            approach: Voting approach
            criteria: Evaluation criteria

        Returns:
            Dict of criterion -> score (0-10)
        """
        # Predefined score patterns for common approaches
        score_patterns = {
            "functional": {"performance": 6, "readability": 9, "maintainability": 8},
            "oop": {"performance": 7, "readability": 7, "maintainability": 8},
            "reactive": {"performance": 8, "readability": 6, "maintainability": 7},
            "imperative": {"performance": 8, "readability": 6, "maintainability": 7},
            "hybrid": {"performance": 10, "readability": 7, "maintainability": 9}
        }

        pattern = score_patterns.get(approach, {})
        return {criterion: pattern.get(criterion, 7) for criterion in criteria}

    def _select_winner(self, voters: List[Voter], aggregation: str) -> Voter:
        """
        Select winner based on aggregation method.

        Args:
            voters: List of voters with scores
            aggregation: Aggregation method (weighted_score, consensus, balanced)

        Returns:
            Winning voter
        """
        completed_voters = [v for v in voters if v.status == "completed"]

        if not completed_voters:
            raise ValueError("No completed voters to select from")

        if aggregation == "weighted_score":
            return max(completed_voters, key=lambda v: sum(v.scores.values()))
        elif aggregation == "consensus":
            # Select voter with most consistent scores
            return max(completed_voters, key=lambda v: min(v.scores.values()))
        else:  # balanced
            # Select voter with best average score
            return max(completed_voters, key=lambda v: sum(v.scores.values()) / len(v.scores))

    def _calculate_consensus(self, voters: List[Voter]) -> float:
        """
        Calculate consensus score (0-1) based on score agreement.

        Args:
            voters: List of voters with scores

        Returns:
            Consensus score
        """
        completed_voters = [v for v in voters if v.status == "completed"]
        if len(completed_voters) < 2:
            return 1.0

        # Calculate variance in total scores
        total_scores = [sum(v.scores.values()) for v in completed_voters]
        mean_score = sum(total_scores) / len(total_scores)
        variance = sum((s - mean_score) ** 2 for s in total_scores) / len(total_scores)

        # Convert variance to consensus (lower variance = higher consensus)
        max_variance = 100  # Theoretical maximum variance
        consensus = max(0.0, 1.0 - (variance / max_variance))

        return round(consensus, 2)

    def _generate_rationale(self, winner: Voter, all_voters: List[Voter]) -> str:
        """
        Generate decision rationale explaining why winner was selected.

        Args:
            winner: Winning voter
            all_voters: All voters

        Returns:
            Rationale string
        """
        winner_total = sum(winner.scores.values())
        rationale = f"Selected {winner.approach} approach (score: {winner_total:.1f}). "

        # Find strongest criteria
        best_criterion = max(winner.scores.items(), key=lambda x: x[1])
        rationale += f"Strongest in {best_criterion[0]} ({best_criterion[1]}/10). "

        # Compare to runner-up
        completed = [v for v in all_voters if v.status == "completed" and v != winner]
        if completed:
            runner_up = max(completed, key=lambda v: sum(v.scores.values()))
            runner_up_total = sum(runner_up.scores.values())
            margin = winner_total - runner_up_total
            rationale += f"Margin over {runner_up.approach}: {margin:.1f} points."

        return rationale


def main():
    """Example usage of VotingExecutor."""
    config = {
        "parallelism": {"max_workers": 5},
        "timeouts": {"default_task": 180}
    }

    executor = VotingExecutor(config)

    main_task = {
        "task_id": "algorithm-001",
        "description": "Optimize search algorithm",
        "voters": ["functional", "imperative", "hybrid"],
        "evaluation_criteria": ["performance", "readability", "maintainability"],
        "aggregation": "weighted_score"
    }

    result = executor.execute(main_task)
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
