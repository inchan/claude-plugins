"""
Code Merger - Merges code files with import deduplication.

This module intelligently merges code files from parallel execution results.
"""

import re
from typing import Dict, List, Set, Any
from dataclasses import dataclass


@dataclass
class MergeResult:
    """Result of a merge operation."""
    merged_content: str
    imports_deduplicated: int
    conflicts_found: int
    files_merged: int


class CodeMerger:
    """Merges code files from parallel execution."""

    def __init__(self):
        """Initialize code merger."""
        pass

    def merge_python_files(self, files: Dict[str, str]) -> MergeResult:
        """
        Merge multiple Python files into one.

        Args:
            files: Dict of filename -> content

        Returns:
            MergeResult with merged content
        """
        all_imports = set()
        all_code = []
        conflicts = 0

        for filename, content in files.items():
            imports, code = self._split_imports_and_code(content, language="python")
            all_imports.update(imports)
            all_code.append(f"# From {filename}\n{code}")

        # Sort imports
        sorted_imports = self._sort_python_imports(all_imports)

        # Combine
        merged_content = "\n".join(sorted_imports) + "\n\n" + "\n\n".join(all_code)

        return MergeResult(
            merged_content=merged_content,
            imports_deduplicated=len(all_imports),
            conflicts_found=conflicts,
            files_merged=len(files)
        )

    def merge_javascript_files(self, files: Dict[str, str]) -> MergeResult:
        """
        Merge multiple JavaScript/TypeScript files into one.

        Args:
            files: Dict of filename -> content

        Returns:
            MergeResult with merged content
        """
        all_imports = set()
        all_code = []
        conflicts = 0

        for filename, content in files.items():
            imports, code = self._split_imports_and_code(content, language="javascript")
            all_imports.update(imports)
            all_code.append(f"// From {filename}\n{code}")

        # Sort imports
        sorted_imports = sorted(all_imports)

        # Combine
        merged_content = "\n".join(sorted_imports) + "\n\n" + "\n\n".join(all_code)

        return MergeResult(
            merged_content=merged_content,
            imports_deduplicated=len(all_imports),
            conflicts_found=conflicts,
            files_merged=len(files)
        )

    def merge_files_by_type(self, files: Dict[str, str]) -> Dict[str, MergeResult]:
        """
        Merge files grouped by file type.

        Args:
            files: Dict of filename -> content

        Returns:
            Dict of file_type -> MergeResult
        """
        # Group files by extension
        grouped: Dict[str, Dict[str, str]] = {}
        for filename, content in files.items():
            ext = self._get_file_extension(filename)
            if ext not in grouped:
                grouped[ext] = {}
            grouped[ext][filename] = content

        # Merge each group
        results = {}
        for ext, file_group in grouped.items():
            if ext == ".py":
                results[ext] = self.merge_python_files(file_group)
            elif ext in [".js", ".ts", ".jsx", ".tsx"]:
                results[ext] = self.merge_javascript_files(file_group)
            else:
                # Generic merge for other file types
                results[ext] = self._merge_generic(file_group)

        return results

    def _split_imports_and_code(self, content: str, language: str) -> tuple[Set[str], str]:
        """
        Split content into imports and code sections.

        Args:
            content: File content
            language: Programming language (python, javascript)

        Returns:
            Tuple of (imports set, code string)
        """
        lines = content.split('\n')
        imports = set()
        code_lines = []

        in_import_section = True

        for line in lines:
            stripped = line.strip()

            if language == "python":
                is_import = stripped.startswith(('import ', 'from '))
            elif language == "javascript":
                is_import = stripped.startswith(('import ', 'const ')) and 'require(' in stripped
            else:
                is_import = False

            if is_import and in_import_section:
                imports.add(line)
            else:
                if stripped and not is_import:
                    in_import_section = False
                code_lines.append(line)

        code = '\n'.join(code_lines).strip()
        return imports, code

    def _sort_python_imports(self, imports: Set[str]) -> List[str]:
        """
        Sort Python imports according to PEP 8.

        Args:
            imports: Set of import statements

        Returns:
            Sorted list of import statements
        """
        standard_lib = []
        third_party = []
        local = []

        # Python standard library modules (simplified list)
        stdlib_modules = {
            'os', 'sys', 'json', 'time', 're', 'math', 'random',
            'collections', 'itertools', 'functools', 'typing'
        }

        for imp in imports:
            # Extract module name
            if imp.startswith('import '):
                module = imp.split()[1].split('.')[0]
            elif imp.startswith('from '):
                module = imp.split()[1].split('.')[0]
            else:
                module = ""

            if module in stdlib_modules:
                standard_lib.append(imp)
            elif module.startswith('.'):
                local.append(imp)
            else:
                third_party.append(imp)

        # Sort each group and combine
        result = []
        if standard_lib:
            result.extend(sorted(standard_lib))
            result.append("")
        if third_party:
            result.extend(sorted(third_party))
            result.append("")
        if local:
            result.extend(sorted(local))

        return result

    def _get_file_extension(self, filename: str) -> str:
        """Get file extension including the dot."""
        if '.' in filename:
            return '.' + filename.rsplit('.', 1)[1]
        return ""

    def _merge_generic(self, files: Dict[str, str]) -> MergeResult:
        """
        Generic merge for non-code files.

        Args:
            files: Dict of filename -> content

        Returns:
            MergeResult with concatenated content
        """
        merged_parts = []
        for filename, content in files.items():
            merged_parts.append(f"--- {filename} ---\n{content}")

        merged_content = "\n\n".join(merged_parts)

        return MergeResult(
            merged_content=merged_content,
            imports_deduplicated=0,
            conflicts_found=0,
            files_merged=len(files)
        )

    def deduplicate_imports(self, content: str, language: str) -> str:
        """
        Deduplicate imports in a code file.

        Args:
            content: File content
            language: Programming language

        Returns:
            Content with deduplicated imports
        """
        imports, code = self._split_imports_and_code(content, language)

        if language == "python":
            sorted_imports = self._sort_python_imports(imports)
        else:
            sorted_imports = sorted(imports)

        return "\n".join(sorted_imports) + "\n\n" + code


def main():
    """Example usage of CodeMerger."""
    merger = CodeMerger()

    # Example Python files
    python_files = {
        "module_a.py": """import os
import sys
from typing import List

def func_a():
    return [1, 2, 3]
""",
        "module_b.py": """import os
import json
from typing import Dict

def func_b():
    return {"key": "value"}
"""
    }

    # Merge Python files
    result = merger.merge_python_files(python_files)
    print("Merged Python files:")
    print(result.merged_content)
    print(f"\nImports deduplicated: {result.imports_deduplicated}")
    print(f"Files merged: {result.files_merged}")

    # Example JavaScript files
    js_files = {
        "module_a.js": """import React from 'react';
import { useState } from 'react';

export function ComponentA() {
  return <div>A</div>;
}
""",
        "module_b.js": """import React from 'react';
import { useEffect } from 'react';

export function ComponentB() {
  return <div>B</div>;
}
"""
    }

    # Merge JavaScript files
    js_result = merger.merge_javascript_files(js_files)
    print("\n\nMerged JavaScript files:")
    print(js_result.merged_content)


if __name__ == "__main__":
    main()
