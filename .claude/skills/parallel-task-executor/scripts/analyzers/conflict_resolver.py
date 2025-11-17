"""
Conflict Resolver - Detects and resolves conflicts in parallel execution results.

This module handles conflicts that arise when merging results from parallel executions.
"""

import difflib
from typing import Dict, List, Set, Any, Tuple
from dataclasses import dataclass
from enum import Enum


class ConflictType(Enum):
    """Types of conflicts that can occur."""
    FILE_CONTENT = "file_content"
    IMPORT = "import"
    TYPE = "type"
    LOGIC = "logic"
    NONE = "none"


@dataclass
class Conflict:
    """Represents a conflict between parallel execution results."""
    conflict_type: ConflictType
    location: str
    version_a: Any
    version_b: Any
    resolution: Any = None
    resolved: bool = False
    manual_review_required: bool = False


class ConflictResolver:
    """Detects and resolves conflicts from parallel execution."""

    def __init__(self):
        """Initialize conflict resolver."""
        self.conflicts: List[Conflict] = []

    def detect_conflicts(self, results: Dict[str, Any]) -> List[Conflict]:
        """
        Detect conflicts in parallel execution results.

        Args:
            results: Dictionary of worker_id -> execution result

        Returns:
            List of detected conflicts
        """
        conflicts = []

        # Check for file content conflicts
        file_conflicts = self._detect_file_conflicts(results)
        conflicts.extend(file_conflicts)

        # Check for import conflicts
        import_conflicts = self._detect_import_conflicts(results)
        conflicts.extend(import_conflicts)

        # Check for type conflicts
        type_conflicts = self._detect_type_conflicts(results)
        conflicts.extend(type_conflicts)

        self.conflicts = conflicts
        return conflicts

    def resolve_conflicts(self, conflicts: List[Conflict]) -> List[Conflict]:
        """
        Automatically resolve conflicts where possible.

        Args:
            conflicts: List of conflicts to resolve

        Returns:
            List of conflicts with resolutions
        """
        for conflict in conflicts:
            if conflict.conflict_type == ConflictType.FILE_CONTENT:
                self._resolve_file_conflict(conflict)
            elif conflict.conflict_type == ConflictType.IMPORT:
                self._resolve_import_conflict(conflict)
            elif conflict.conflict_type == ConflictType.TYPE:
                self._resolve_type_conflict(conflict)
            elif conflict.conflict_type == ConflictType.LOGIC:
                # Logic conflicts require manual review
                conflict.manual_review_required = True

        return conflicts

    def _detect_file_conflicts(self, results: Dict[str, Any]) -> List[Conflict]:
        """Detect conflicts in file contents."""
        conflicts = []

        # Group results by file path
        files_by_path: Dict[str, List[Tuple[str, str]]] = {}
        for worker_id, result in results.items():
            files = result.get("files", {})
            for file_path, content in files.items():
                if file_path not in files_by_path:
                    files_by_path[file_path] = []
                files_by_path[file_path].append((worker_id, content))

        # Check for conflicts (multiple different versions of same file)
        for file_path, versions in files_by_path.items():
            if len(versions) > 1:
                # Compare all versions
                unique_versions = {}
                for worker_id, content in versions:
                    content_hash = hash(content)
                    if content_hash not in unique_versions:
                        unique_versions[content_hash] = (worker_id, content)

                # If multiple unique versions exist, there's a conflict
                if len(unique_versions) > 1:
                    version_list = list(unique_versions.values())
                    conflicts.append(
                        Conflict(
                            conflict_type=ConflictType.FILE_CONTENT,
                            location=file_path,
                            version_a=version_list[0][1],
                            version_b=version_list[1][1] if len(version_list) > 1 else None
                        )
                    )

        return conflicts

    def _detect_import_conflicts(self, results: Dict[str, Any]) -> List[Conflict]:
        """Detect conflicts in import statements."""
        conflicts = []

        # Collect all imports from each worker
        imports_by_worker: Dict[str, Set[str]] = {}
        for worker_id, result in results.items():
            imports = set(result.get("imports", []))
            imports_by_worker[worker_id] = imports

        # Check for conflicting imports (same module, different versions)
        # This is a simplified check; real implementation would parse versions
        all_imports = set()
        for imports in imports_by_worker.values():
            all_imports.update(imports)

        # For now, no import conflicts detected (would need version parsing)

        return conflicts

    def _detect_type_conflicts(self, results: Dict[str, Any]) -> List[Conflict]:
        """Detect conflicts in type definitions."""
        conflicts = []

        # Group type definitions by name
        types_by_name: Dict[str, List[Tuple[str, str]]] = {}
        for worker_id, result in results.items():
            types = result.get("types", {})
            for type_name, type_def in types.items():
                if type_name not in types_by_name:
                    types_by_name[type_name] = []
                types_by_name[type_name].append((worker_id, type_def))

        # Check for conflicts (same type name, different definitions)
        for type_name, versions in types_by_name.items():
            if len(versions) > 1:
                unique_defs = set(type_def for _, type_def in versions)
                if len(unique_defs) > 1:
                    conflicts.append(
                        Conflict(
                            conflict_type=ConflictType.TYPE,
                            location=type_name,
                            version_a=versions[0][1],
                            version_b=versions[1][1] if len(versions) > 1 else None
                        )
                    )

        return conflicts

    def _resolve_file_conflict(self, conflict: Conflict) -> None:
        """
        Resolve file content conflict using three-way merge.

        Args:
            conflict: File content conflict to resolve
        """
        version_a = conflict.version_a
        version_b = conflict.version_b

        if not isinstance(version_a, str) or not isinstance(version_b, str):
            conflict.manual_review_required = True
            return

        # Calculate similarity
        similarity = difflib.SequenceMatcher(None, version_a, version_b).ratio()

        if similarity > 0.9:
            # Very similar, use longer version
            conflict.resolution = version_a if len(version_a) > len(version_b) else version_b
            conflict.resolved = True
        elif similarity < 0.3:
            # Very different, require manual review
            conflict.manual_review_required = True
        else:
            # Moderate difference, attempt merge
            merged = self._merge_text(version_a, version_b)
            if merged:
                conflict.resolution = merged
                conflict.resolved = True
            else:
                conflict.manual_review_required = True

    def _resolve_import_conflict(self, conflict: Conflict) -> None:
        """
        Resolve import conflict by deduplication and ordering.

        Args:
            conflict: Import conflict to resolve
        """
        # Deduplicate imports
        imports_a = set(str(conflict.version_a).split('\n'))
        imports_b = set(str(conflict.version_b).split('\n'))

        # Union of all imports
        all_imports = sorted(imports_a | imports_b)

        conflict.resolution = '\n'.join(all_imports)
        conflict.resolved = True

    def _resolve_type_conflict(self, conflict: Conflict) -> None:
        """
        Resolve type conflict using union types or explicit casting.

        Args:
            conflict: Type conflict to resolve
        """
        type_a = conflict.version_a
        type_b = conflict.version_b

        # If types are compatible, create union type
        if self._are_types_compatible(type_a, type_b):
            conflict.resolution = f"{type_a} | {type_b}"
            conflict.resolved = True
        else:
            # Incompatible types require manual review
            conflict.manual_review_required = True

    def _merge_text(self, text_a: str, text_b: str) -> str:
        """
        Merge two text versions using line-by-line diff.

        Args:
            text_a: First version
            text_b: Second version

        Returns:
            Merged text, or empty string if merge fails
        """
        lines_a = text_a.split('\n')
        lines_b = text_b.split('\n')

        # Use difflib to find differences
        diff = difflib.unified_diff(lines_a, lines_b, lineterm='')

        merged_lines = []
        for line in diff:
            if not line.startswith('---') and not line.startswith('+++') and not line.startswith('@@'):
                # Keep all changes (additive merge)
                if line.startswith('+'):
                    merged_lines.append(line[1:])
                elif not line.startswith('-'):
                    merged_lines.append(line)

        return '\n'.join(merged_lines) if merged_lines else ""

    def _are_types_compatible(self, type_a: str, type_b: str) -> bool:
        """
        Check if two types are compatible for union.

        Args:
            type_a: First type
            type_b: Second type

        Returns:
            True if types can be unioned
        """
        # Simplified check - in real implementation would parse type syntax
        basic_types = {'string', 'number', 'boolean', 'null', 'undefined'}
        return type_a in basic_types and type_b in basic_types

    def get_unresolved_conflicts(self) -> List[Conflict]:
        """Get list of conflicts requiring manual review."""
        return [c for c in self.conflicts if c.manual_review_required or not c.resolved]

    def get_resolved_conflicts(self) -> List[Conflict]:
        """Get list of automatically resolved conflicts."""
        return [c for c in self.conflicts if c.resolved and not c.manual_review_required]


def main():
    """Example usage of ConflictResolver."""
    resolver = ConflictResolver()

    # Example results from parallel workers
    results = {
        "worker_1": {
            "files": {
                "utils.py": "def helper():\n    return 42",
                "types.ts": "type User = { id: number; name: string }"
            },
            "imports": ["os", "sys"],
            "types": {"User": "{ id: number; name: string }"}
        },
        "worker_2": {
            "files": {
                "utils.py": "def helper():\n    return 43",  # Different implementation
                "types.ts": "type User = { id: string; name: string }"  # Different type
            },
            "imports": ["os", "json"],
            "types": {"User": "{ id: string; name: string }"}
        }
    }

    # Detect conflicts
    conflicts = resolver.detect_conflicts(results)
    print(f"Detected {len(conflicts)} conflicts:")
    for conflict in conflicts:
        print(f"  - {conflict.conflict_type.value} at {conflict.location}")

    # Resolve conflicts
    resolved = resolver.resolve_conflicts(conflicts)
    print(f"\nResolved: {len(resolver.get_resolved_conflicts())}")
    print(f"Manual review required: {len(resolver.get_unresolved_conflicts())}")


if __name__ == "__main__":
    main()
