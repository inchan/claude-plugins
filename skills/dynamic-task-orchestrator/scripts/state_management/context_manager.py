"""
Context Manager

Manages shared execution context across workers.
"""

from typing import Dict, Any, List, Optional


class ContextManager:
    """
    Manages shared context that workers use for coordination.
    """

    def __init__(self):
        """Initialize context manager."""
        self.global_context = {}
        self.worker_contexts = {}
        self.shared_knowledge = {}
        self.context_version = 0

    def initialize_context(self, project: Dict[str, Any]) -> Dict[str, Any]:
        """
        Initialize execution context for a project.

        Args:
            project: Project definition

        Returns:
            Initial context dictionary
        """
        self.global_context = {
            'project': project,
            'project_type': project.get('type'),
            'requirements': project.get('requirements', []),
            'constraints': project.get('constraints', []),
            'naming_conventions': {},
            'technology_stack': {},
            'architecture_decisions': [],
            'shared_patterns': [],
            'shared_dependencies': []
        }

        self.context_version = 1
        return self.get_context()

    def get_context(self, worker_id: str = None) -> Dict[str, Any]:
        """
        Get execution context for a worker.

        Args:
            worker_id: Optional specific worker ID

        Returns:
            Context dictionary
        """
        context = self.global_context.copy()

        if worker_id and worker_id in self.worker_contexts:
            # Merge worker-specific context
            context.update(self.worker_contexts[worker_id])

        # Add shared knowledge
        context['shared_knowledge'] = self.shared_knowledge.copy()
        context['context_version'] = self.context_version

        return context

    def update_context(self, updates: Dict[str, Any], worker_id: str = None):
        """
        Update execution context.

        Args:
            updates: Context updates to apply
            worker_id: Worker making the update
        """
        if worker_id:
            # Store worker-specific updates
            if worker_id not in self.worker_contexts:
                self.worker_contexts[worker_id] = {}
            self.worker_contexts[worker_id].update(updates)

        # Update global context with important updates
        for key in ['technology_stack', 'architecture_decisions', 'naming_conventions']:
            if key in updates:
                self.global_context[key] = updates[key]

        self.context_version += 1

    def share_knowledge(self, key: str, value: Any, source_worker: str):
        """
        Share knowledge across all workers.

        Args:
            key: Knowledge key
            value: Knowledge value
            source_worker: Worker sharing the knowledge
        """
        self.shared_knowledge[key] = {
            'value': value,
            'source': source_worker,
            'version': self.context_version
        }
        self.context_version += 1

    def get_shared_knowledge(self, key: str) -> Optional[Any]:
        """Get shared knowledge by key."""
        knowledge = self.shared_knowledge.get(key)
        return knowledge['value'] if knowledge else None

    def record_decision(self, decision: str, rationale: str, worker_id: str):
        """
        Record an architecture decision.

        Args:
            decision: Decision made
            rationale: Reasoning behind decision
            worker_id: Worker that made the decision
        """
        self.global_context.setdefault('architecture_decisions', []).append({
            'decision': decision,
            'rationale': rationale,
            'worker': worker_id,
            'version': self.context_version
        })
        self.context_version += 1

    def set_naming_convention(self, category: str, convention: str):
        """
        Set a naming convention to be followed by all workers.

        Args:
            category: Convention category (files, functions, classes, etc.)
            convention: Convention specification
        """
        self.global_context.setdefault('naming_conventions', {})[category] = convention
        self.context_version += 1

    def set_technology(self, category: str, technology: str, version: str = None):
        """
        Set a technology choice to be used by all workers.

        Args:
            category: Technology category (backend, frontend, database, etc.)
            technology: Technology name
            version: Optional version specification
        """
        tech_spec = {'name': technology}
        if version:
            tech_spec['version'] = version

        self.global_context.setdefault('technology_stack', {})[category] = tech_spec
        self.context_version += 1

    def add_pattern(self, pattern_name: str, pattern_spec: Dict[str, Any]):
        """
        Add a shared pattern for workers to follow.

        Args:
            pattern_name: Pattern identifier
            pattern_spec: Pattern specification
        """
        self.global_context.setdefault('shared_patterns', []).append({
            'name': pattern_name,
            'spec': pattern_spec,
            'version': self.context_version
        })
        self.context_version += 1

    def add_dependency(self, dependency: str, purpose: str):
        """
        Record a shared dependency.

        Args:
            dependency: Dependency identifier
            purpose: Why this dependency is needed
        """
        self.global_context.setdefault('shared_dependencies', []).append({
            'dependency': dependency,
            'purpose': purpose,
            'version': self.context_version
        })
        self.context_version += 1

    def get_context_summary(self) -> Dict[str, Any]:
        """Get summary of current context state."""
        return {
            'version': self.context_version,
            'project_type': self.global_context.get('project_type'),
            'technology_stack': self.global_context.get('technology_stack', {}),
            'decisions_count': len(self.global_context.get('architecture_decisions', [])),
            'patterns_count': len(self.global_context.get('shared_patterns', [])),
            'dependencies_count': len(self.global_context.get('shared_dependencies', [])),
            'shared_knowledge_count': len(self.shared_knowledge),
            'worker_contexts_count': len(self.worker_contexts)
        }

    def sync_workers(self, worker_ids: List[str]) -> Dict[str, Dict[str, Any]]:
        """
        Synchronize context across multiple workers.

        Args:
            worker_ids: List of worker IDs to sync

        Returns:
            Dictionary of contexts for each worker
        """
        synced_contexts = {}

        for worker_id in worker_ids:
            synced_contexts[worker_id] = self.get_context(worker_id)

        return synced_contexts

    def clear_worker_context(self, worker_id: str):
        """Clear worker-specific context."""
        if worker_id in self.worker_contexts:
            del self.worker_contexts[worker_id]

    def reset(self):
        """Reset context manager to initial state."""
        self.global_context = {}
        self.worker_contexts = {}
        self.shared_knowledge = {}
        self.context_version = 0
