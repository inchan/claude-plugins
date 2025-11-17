"""
DAG Builder - Constructs directed acyclic graph for execution planning.

This module builds a DAG from task dependencies and identifies parallel execution groups.
"""

from typing import Dict, List, Set, Any, Tuple
from dataclasses import dataclass
from collections import deque


@dataclass
class DAGNode:
    """Represents a node in the DAG."""
    id: str
    dependencies: Set[str]
    dependents: Set[str]
    level: int = 0  # Execution level (0 = no dependencies)


class DAG:
    """Directed Acyclic Graph for task execution planning."""

    def __init__(self):
        """Initialize empty DAG."""
        self.nodes: Dict[str, DAGNode] = {}
        self.edges: List[Tuple[str, str]] = []

    def add_node(self, node_id: str) -> None:
        """
        Add a node to the DAG.

        Args:
            node_id: Unique node identifier
        """
        if node_id not in self.nodes:
            self.nodes[node_id] = DAGNode(
                id=node_id,
                dependencies=set(),
                dependents=set()
            )

    def add_edge(self, from_node: str, to_node: str) -> None:
        """
        Add a directed edge to the DAG.

        Args:
            from_node: Source node (dependency)
            to_node: Target node (dependent)
        """
        # Ensure nodes exist
        self.add_node(from_node)
        self.add_node(to_node)

        # Add edge
        self.nodes[to_node].dependencies.add(from_node)
        self.nodes[from_node].dependents.add(to_node)
        self.edges.append((from_node, to_node))

    def has_nodes(self) -> bool:
        """Check if DAG has any nodes."""
        return len(self.nodes) > 0

    def nodes_with_no_dependencies(self) -> List[DAGNode]:
        """Get all nodes with no remaining dependencies."""
        return [node for node in self.nodes.values() if not node.dependencies]

    def remove_nodes(self, nodes: List[DAGNode]) -> None:
        """
        Remove nodes from DAG and update dependencies.

        Args:
            nodes: List of nodes to remove
        """
        for node in nodes:
            # Remove from dependents' dependency lists
            for dependent_id in node.dependents:
                if dependent_id in self.nodes:
                    self.nodes[dependent_id].dependencies.discard(node.id)

            # Remove node
            if node.id in self.nodes:
                del self.nodes[node.id]

    def longest_path(self) -> List[str]:
        """
        Calculate the longest path in the DAG (critical path).

        Returns:
            List of node IDs in the critical path
        """
        # Calculate levels using topological sort
        self._calculate_levels()

        # Find node with maximum level
        if not self.nodes:
            return []

        max_level_node = max(self.nodes.values(), key=lambda n: n.level)

        # Backtrack to find the path
        path = []
        current = max_level_node

        while current:
            path.append(current.id)

            # Find predecessor with max level
            predecessors = [
                self.nodes[dep_id]
                for dep_id in current.dependencies
                if dep_id in self.nodes
            ]

            if predecessors:
                current = max(predecessors, key=lambda n: n.level)
            else:
                current = None

        return list(reversed(path))

    def _calculate_levels(self) -> None:
        """Calculate execution level for each node using topological sort."""
        # Reset levels
        for node in self.nodes.values():
            node.level = 0

        # Topological sort with level calculation
        in_degree = {node_id: len(node.dependencies) for node_id, node in self.nodes.items()}
        queue = deque([node_id for node_id, degree in in_degree.items() if degree == 0])

        while queue:
            current_id = queue.popleft()
            current_node = self.nodes[current_id]

            for dependent_id in current_node.dependents:
                if dependent_id not in self.nodes:
                    continue

                dependent_node = self.nodes[dependent_id]

                # Update level (max of all predecessors + 1)
                dependent_node.level = max(dependent_node.level, current_node.level + 1)

                # Decrease in-degree
                in_degree[dependent_id] -= 1
                if in_degree[dependent_id] == 0:
                    queue.append(dependent_id)


class DAGBuilder:
    """Builds DAG from task dependencies."""

    def __init__(self):
        """Initialize DAG builder."""
        self.dag = DAG()

    def build_dag(self, tasks: List[Dict[str, Any]], dependencies: Dict[str, Set[str]]) -> DAG:
        """
        Build DAG from tasks and their dependencies.

        Args:
            tasks: List of task dictionaries with 'id' field
            dependencies: Map of task_id -> set of dependency task_ids

        Returns:
            Constructed DAG
        """
        # Add all task nodes
        for task in tasks:
            task_id = task.get("id", task.get("name", str(task)))
            self.dag.add_node(task_id)

        # Add dependency edges
        for task_id, deps in dependencies.items():
            for dep_id in deps:
                self.dag.add_edge(dep_id, task_id)

        return self.dag

    def identify_parallel_groups(self, dag: DAG) -> List[List[str]]:
        """
        Identify groups of tasks that can be executed in parallel.

        Args:
            dag: DAG to analyze

        Returns:
            List of execution waves, where each wave is a list of task IDs
        """
        parallel_groups = []
        dag_copy = self._copy_dag(dag)

        while dag_copy.has_nodes():
            # Get all nodes with no dependencies
            ready_nodes = dag_copy.nodes_with_no_dependencies()

            if not ready_nodes:
                # Circular dependency detected
                break

            # Add as parallel group
            parallel_groups.append([node.id for node in ready_nodes])

            # Remove completed nodes
            dag_copy.remove_nodes(ready_nodes)

        return parallel_groups

    def find_sync_points(self, dag: DAG) -> List[str]:
        """
        Find synchronization points (nodes with multiple dependencies).

        Args:
            dag: DAG to analyze

        Returns:
            List of node IDs that are sync points
        """
        return [
            node.id
            for node in dag.nodes.values()
            if len(node.dependencies) > 1
        ]

    def calculate_critical_path(self, dag: DAG) -> Dict[str, Any]:
        """
        Calculate critical path through the DAG.

        Args:
            dag: DAG to analyze

        Returns:
            Critical path information
        """
        path = dag.longest_path()

        return {
            "path": path,
            "length": len(path),
            "nodes": [dag.nodes[node_id] for node_id in path if node_id in dag.nodes]
        }

    def _copy_dag(self, dag: DAG) -> DAG:
        """Create a deep copy of the DAG."""
        new_dag = DAG()

        for node_id, node in dag.nodes.items():
            new_dag.add_node(node_id)
            new_dag.nodes[node_id].dependencies = node.dependencies.copy()
            new_dag.nodes[node_id].dependents = node.dependents.copy()
            new_dag.nodes[node_id].level = node.level

        new_dag.edges = dag.edges.copy()

        return new_dag


def main():
    """Example usage of DAGBuilder."""
    builder = DAGBuilder()

    # Example tasks
    tasks = [
        {"id": "task_a"},
        {"id": "task_b"},
        {"id": "task_c"},
        {"id": "task_d"},
        {"id": "task_e"}
    ]

    # Example dependencies
    # task_b depends on task_a
    # task_c depends on task_a
    # task_d depends on task_b and task_c
    # task_e depends on task_d
    dependencies = {
        "task_a": set(),
        "task_b": {"task_a"},
        "task_c": {"task_a"},
        "task_d": {"task_b", "task_c"},
        "task_e": {"task_d"}
    }

    # Build DAG
    dag = builder.build_dag(tasks, dependencies)

    # Identify parallel groups
    parallel_groups = builder.identify_parallel_groups(dag)
    print("Parallel execution groups:")
    for i, group in enumerate(parallel_groups):
        print(f"  Wave {i+1}: {group}")

    # Find sync points
    sync_points = builder.find_sync_points(dag)
    print(f"\nSync points: {sync_points}")

    # Calculate critical path
    critical_path = builder.calculate_critical_path(dag)
    print(f"\nCritical path: {critical_path['path']}")
    print(f"Critical path length: {critical_path['length']}")


if __name__ == "__main__":
    main()
