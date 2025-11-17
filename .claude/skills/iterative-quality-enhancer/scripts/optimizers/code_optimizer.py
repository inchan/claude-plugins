"""
Code Optimizer

Applies targeted optimizations based on evaluation feedback.
Reference implementation - apply these patterns to user code directly.
"""

from typing import Dict, Any, List


class CodeOptimizer:
    """
    Apply code optimizations targeting specific quality dimensions.

    Optimization strategies:
    - Refactoring: Improve code structure
    - Algorithm optimization: Improve performance
    - Security hardening: Fix vulnerabilities
    - Documentation enhancement: Add/improve docs
    """

    def optimize(
        self,
        artifact: Dict[str, Any],
        feedback: List[Dict[str, Any]],
        strategy: str = 'balanced'
    ) -> Dict[str, Any]:
        """
        Apply optimizations based on feedback.

        Args:
            artifact: Code artifact to optimize
            feedback: Prioritized feedback from evaluators
            strategy: Optimization focus (balanced, performance, security, quality)

        Returns:
            Optimized artifact with changes documented
        """
        code = artifact.get('code', '')
        changes = []

        # Sort feedback by priority
        sorted_feedback = sorted(
            feedback,
            key=lambda x: x.get('priority', 0),
            reverse=True
        )

        for item in sorted_feedback:
            dimension = item.get('dimension')
            issue = item.get('issue')

            if dimension == 'security':
                code, change = self._apply_security_fix(code, issue)
                if change:
                    changes.append(change)

            elif dimension == 'performance':
                code, change = self._apply_performance_optimization(code, issue)
                if change:
                    changes.append(change)

            elif dimension == 'code_quality':
                code, change = self._apply_refactoring(code, issue)
                if change:
                    changes.append(change)

            elif dimension == 'functionality':
                code, change = self._add_error_handling(code, issue)
                if change:
                    changes.append(change)

        return {
            'code': code,
            'changes': changes,
            'optimizations_applied': len(changes)
        }

    def _apply_security_fix(self, code: str, issue: str) -> tuple:
        """Apply security-related fixes."""
        # This is a reference implementation
        # In practice, Claude should analyze the specific issue and fix it
        return code, {
            'type': 'security_fix',
            'issue': issue,
            'description': 'Security vulnerability patched'
        }

    def _apply_performance_optimization(self, code: str, issue: str) -> tuple:
        """Apply performance optimizations."""
        return code, {
            'type': 'performance_optimization',
            'issue': issue,
            'description': 'Performance bottleneck optimized'
        }

    def _apply_refactoring(self, code: str, issue: str) -> tuple:
        """Apply code quality refactoring."""
        return code, {
            'type': 'refactoring',
            'issue': issue,
            'description': 'Code structure improved'
        }

    def _add_error_handling(self, code: str, issue: str) -> tuple:
        """Add error handling."""
        return code, {
            'type': 'error_handling',
            'issue': issue,
            'description': 'Error handling added'
        }


# Optimization strategies guide
OPTIMIZATION_STRATEGIES = {
    'algorithm_optimization': {
        'description': 'Improve algorithmic efficiency',
        'techniques': [
            'Replace O(n²) with O(n log n) algorithms',
            'Use hash maps for O(1) lookups',
            'Implement caching for repeated calculations',
            'Use appropriate data structures (set, dict, heap)'
        ]
    },
    'code_refactoring': {
        'description': 'Improve code structure and readability',
        'techniques': [
            'Extract long functions into smaller ones',
            'Apply design patterns (Strategy, Factory, etc.)',
            'Follow SOLID principles',
            'Remove code duplication (DRY)',
            'Improve naming and organization'
        ]
    },
    'security_hardening': {
        'description': 'Fix security vulnerabilities',
        'techniques': [
            'Use parameterized queries (prevent SQL injection)',
            'Implement input validation',
            'Replace weak hashing (bcrypt/argon2)',
            'Add authentication/authorization',
            'Remove hardcoded secrets'
        ]
    },
    'performance_tuning': {
        'description': 'Optimize runtime performance',
        'techniques': [
            'Eliminate N+1 queries',
            'Add database indexing',
            'Implement connection pooling',
            'Use asynchronous operations',
            'Add caching layer'
        ]
    },
    'documentation_enhancement': {
        'description': 'Improve documentation',
        'techniques': [
            'Add docstrings to all public functions',
            'Create comprehensive README',
            'Add usage examples',
            'Document API endpoints',
            'Add inline comments for complex logic'
        ]
    }
}
