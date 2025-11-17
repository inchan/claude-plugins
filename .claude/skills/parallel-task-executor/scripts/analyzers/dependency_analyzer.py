"""
Dependency Analyzer - Extracts dependencies from code and builds dependency graph.

This module analyzes code to identify dependencies between tasks and components.
"""

import ast
import re
from typing import Dict, List, Set, Any
from dataclasses import dataclass


@dataclass
class Dependency:
    """Represents a dependency between two components."""
    source: str
    target: str
    dependency_type: str  # import, function_call, variable_reference
    line_number: int = 0


class DependencyAnalyzer:
    """Analyzes code to extract dependencies."""

    def __init__(self):
        """Initialize dependency analyzer."""
        self.dependencies: List[Dependency] = []

    def analyze_python_file(self, file_path: str, content: str) -> List[Dependency]:
        """
        Analyze Python file to extract dependencies.

        Args:
            file_path: Path to the file
            content: File content

        Returns:
            List of dependencies
        """
        dependencies = []

        try:
            tree = ast.parse(content)
            dependencies.extend(self._extract_imports(tree, file_path))
            dependencies.extend(self._extract_function_calls(tree, file_path))
            dependencies.extend(self._extract_variable_references(tree, file_path))
        except SyntaxError:
            # If parsing fails, use regex-based fallback
            dependencies.extend(self._extract_imports_regex(content, file_path))

        return dependencies

    def analyze_javascript_file(self, file_path: str, content: str) -> List[Dependency]:
        """
        Analyze JavaScript/TypeScript file to extract dependencies.

        Args:
            file_path: Path to the file
            content: File content

        Returns:
            List of dependencies
        """
        dependencies = []

        # Extract ES6 imports
        import_pattern = r'import\s+.*?\s+from\s+[\'"](.+?)[\'"]'
        for match in re.finditer(import_pattern, content):
            target = match.group(1)
            dependencies.append(
                Dependency(
                    source=file_path,
                    target=target,
                    dependency_type="import"
                )
            )

        # Extract require() calls
        require_pattern = r'require\([\'"](.+?)[\'"]\)'
        for match in re.finditer(require_pattern, content):
            target = match.group(1)
            dependencies.append(
                Dependency(
                    source=file_path,
                    target=target,
                    dependency_type="require"
                )
            )

        return dependencies

    def _extract_imports(self, tree: ast.AST, source: str) -> List[Dependency]:
        """Extract import dependencies from AST."""
        dependencies = []

        for node in ast.walk(tree):
            if isinstance(node, ast.Import):
                for alias in node.names:
                    dependencies.append(
                        Dependency(
                            source=source,
                            target=alias.name,
                            dependency_type="import",
                            line_number=node.lineno
                        )
                    )
            elif isinstance(node, ast.ImportFrom):
                module = node.module or ""
                dependencies.append(
                    Dependency(
                        source=source,
                        target=module,
                        dependency_type="import",
                        line_number=node.lineno
                    )
                )

        return dependencies

    def _extract_function_calls(self, tree: ast.AST, source: str) -> List[Dependency]:
        """Extract function call dependencies from AST."""
        dependencies = []

        for node in ast.walk(tree):
            if isinstance(node, ast.Call):
                if isinstance(node.func, ast.Name):
                    dependencies.append(
                        Dependency(
                            source=source,
                            target=node.func.id,
                            dependency_type="function_call",
                            line_number=node.lineno
                        )
                    )
                elif isinstance(node.func, ast.Attribute):
                    # Handle method calls like obj.method()
                    if isinstance(node.func.value, ast.Name):
                        target = f"{node.func.value.id}.{node.func.attr}"
                        dependencies.append(
                            Dependency(
                                source=source,
                                target=target,
                                dependency_type="function_call",
                                line_number=node.lineno
                            )
                        )

        return dependencies

    def _extract_variable_references(self, tree: ast.AST, source: str) -> List[Dependency]:
        """Extract variable reference dependencies from AST."""
        dependencies = []

        for node in ast.walk(tree):
            if isinstance(node, ast.Name) and isinstance(node.ctx, ast.Load):
                # Variable is being read
                dependencies.append(
                    Dependency(
                        source=source,
                        target=node.id,
                        dependency_type="variable_reference",
                        line_number=node.lineno
                    )
                )

        return dependencies

    def _extract_imports_regex(self, content: str, source: str) -> List[Dependency]:
        """Fallback regex-based import extraction."""
        dependencies = []

        # Match import statements
        import_pattern = r'^import\s+(\w+)'
        from_pattern = r'^from\s+([\w.]+)\s+import'

        for i, line in enumerate(content.split('\n'), 1):
            for pattern in [import_pattern, from_pattern]:
                match = re.match(pattern, line.strip())
                if match:
                    dependencies.append(
                        Dependency(
                            source=source,
                            target=match.group(1),
                            dependency_type="import",
                            line_number=i
                        )
                    )

        return dependencies

    def build_dependency_map(self, files: Dict[str, str]) -> Dict[str, Set[str]]:
        """
        Build a dependency map from multiple files.

        Args:
            files: Dict of file_path -> content

        Returns:
            Dict of file_path -> set of dependencies
        """
        dependency_map = {}

        for file_path, content in files.items():
            if file_path.endswith('.py'):
                deps = self.analyze_python_file(file_path, content)
            elif file_path.endswith(('.js', '.ts', '.jsx', '.tsx')):
                deps = self.analyze_javascript_file(file_path, content)
            else:
                deps = []

            # Convert to set of target files
            dep_set = {dep.target for dep in deps if dep.target in files}
            dependency_map[file_path] = dep_set

        return dependency_map

    def detect_circular_dependencies(self, dependency_map: Dict[str, Set[str]]) -> List[List[str]]:
        """
        Detect circular dependencies in the dependency map.

        Args:
            dependency_map: Map of file -> dependencies

        Returns:
            List of circular dependency chains
        """
        cycles = []
        visited = set()

        def dfs(node: str, path: List[str]) -> None:
            if node in path:
                # Found a cycle
                cycle_start = path.index(node)
                cycle = path[cycle_start:] + [node]
                cycles.append(cycle)
                return

            if node in visited:
                return

            visited.add(node)
            path.append(node)

            for neighbor in dependency_map.get(node, set()):
                dfs(neighbor, path.copy())

        for node in dependency_map:
            dfs(node, [])

        return cycles


def main():
    """Example usage of DependencyAnalyzer."""
    analyzer = DependencyAnalyzer()

    # Example Python code
    python_code = """
import os
from typing import List

def process_data(items: List[str]) -> None:
    result = compute(items)
    print(result)
"""

    dependencies = analyzer.analyze_python_file("example.py", python_code)

    print("Dependencies found:")
    for dep in dependencies:
        print(f"  {dep.source} -> {dep.target} ({dep.dependency_type})")

    # Example dependency map
    files = {
        "module_a.py": "import module_b\nfrom module_c import func",
        "module_b.py": "import module_c",
        "module_c.py": ""
    }

    dep_map = analyzer.build_dependency_map(files)
    print("\nDependency map:")
    for file, deps in dep_map.items():
        print(f"  {file} depends on: {deps}")

    cycles = analyzer.detect_circular_dependencies(dep_map)
    if cycles:
        print(f"\nCircular dependencies detected: {cycles}")


if __name__ == "__main__":
    main()
