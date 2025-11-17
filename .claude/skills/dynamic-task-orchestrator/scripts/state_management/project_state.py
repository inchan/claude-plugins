"""
Project State

Tracks and manages overall project execution state.
"""

from typing import Dict, Any, List
from enum import Enum
from datetime import datetime


class ProjectPhase(Enum):
    """Project execution phases"""
    INITIALIZED = "initialized"
    ANALYZING = "analyzing"
    DESIGNING = "designing"
    IMPLEMENTING = "implementing"
    TESTING = "testing"
    DOCUMENTING = "documenting"
    OPTIMIZING = "optimizing"
    FINALIZING = "finalizing"
    COMPLETED = "completed"
    FAILED = "failed"


class ProjectState:
    """
    Maintains comprehensive project state throughout execution.
    """

    def __init__(self, project_definition: Dict[str, Any]):
        """
        Initialize project state.

        Args:
            project_definition: Initial project configuration
        """
        self.project_id = project_definition.get('task_id', self._generate_id())
        self.project_definition = project_definition
        self.phase = ProjectPhase.INITIALIZED
        self.start_time = datetime.utcnow()
        self.end_time = None

        # Execution tracking
        self.completed_phases = []
        self.active_workers = []
        self.completed_workers = []
        self.failed_workers = []

        # Deliverables
        self.deliverables = {
            'source_code': [],
            'tests': [],
            'documentation': [],
            'deployment': [],
            'artifacts': []
        }

        # Metrics
        self.metrics = {
            'total_tasks_executed': 0,
            'tasks_succeeded': 0,
            'tasks_failed': 0,
            'total_replans': 0,
            'total_artifacts_created': 0
        }

        # Decision log
        self.decisions = []

        # Issues and blockers
        self.issues = []
        self.blockers = []

    def transition_phase(self, new_phase: ProjectPhase):
        """
        Transition to a new project phase.

        Args:
            new_phase: New phase to transition to
        """
        if self.phase != ProjectPhase.COMPLETED and self.phase != ProjectPhase.FAILED:
            self.completed_phases.append({
                'phase': self.phase.value,
                'completed_at': datetime.utcnow().isoformat()
            })
            self.phase = new_phase

    def add_deliverable(self, category: str, path: str, metadata: Dict[str, Any] = None):
        """
        Add a project deliverable.

        Args:
            category: Deliverable category (source_code, tests, documentation, deployment)
            path: File path
            metadata: Optional metadata about the deliverable
        """
        if category in self.deliverables:
            deliverable = {
                'path': path,
                'created_at': datetime.utcnow().isoformat(),
                'metadata': metadata or {}
            }
            self.deliverables[category].append(deliverable)
            self.metrics['total_artifacts_created'] += 1

    def record_decision(self, decision: str, rationale: str, alternatives: List[str] = None):
        """
        Record an architecture or design decision.

        Args:
            decision: The decision made
            rationale: Why this decision was made
            alternatives: Other options considered
        """
        self.decisions.append({
            'decision': decision,
            'rationale': rationale,
            'alternatives': alternatives or [],
            'timestamp': datetime.utcnow().isoformat(),
            'phase': self.phase.value
        })

    def record_issue(self, issue: str, severity: str = 'medium', worker_id: str = None):
        """
        Record an issue or problem.

        Args:
            issue: Description of the issue
            severity: Issue severity (low/medium/high/critical)
            worker_id: Worker that encountered the issue
        """
        self.issues.append({
            'issue': issue,
            'severity': severity,
            'worker_id': worker_id,
            'timestamp': datetime.utcnow().isoformat(),
            'resolved': False
        })

    def record_blocker(self, blocker: str, worker_id: str = None):
        """
        Record a blocking issue.

        Args:
            blocker: Description of the blocker
            worker_id: Worker that is blocked
        """
        self.blockers.append({
            'blocker': blocker,
            'worker_id': worker_id,
            'timestamp': datetime.utcnow().isoformat(),
            'resolved': False
        })

    def resolve_issue(self, issue_index: int):
        """Mark an issue as resolved."""
        if 0 <= issue_index < len(self.issues):
            self.issues[issue_index]['resolved'] = True
            self.issues[issue_index]['resolved_at'] = datetime.utcnow().isoformat()

    def resolve_blocker(self, blocker_index: int):
        """Mark a blocker as resolved."""
        if 0 <= blocker_index < len(self.blockers):
            self.blockers[blocker_index]['resolved'] = True
            self.blockers[blocker_index]['resolved_at'] = datetime.utcnow().isoformat()

    def update_metrics(self, task_result: Dict[str, Any]):
        """
        Update project metrics based on task result.

        Args:
            task_result: Result from worker execution
        """
        self.metrics['total_tasks_executed'] += 1

        if task_result.get('success'):
            self.metrics['tasks_succeeded'] += 1
        else:
            self.metrics['tasks_failed'] += 1

    def mark_complete(self):
        """Mark project as completed."""
        self.phase = ProjectPhase.COMPLETED
        self.end_time = datetime.utcnow()

    def mark_failed(self, reason: str):
        """
        Mark project as failed.

        Args:
            reason: Failure reason
        """
        self.phase = ProjectPhase.FAILED
        self.end_time = datetime.utcnow()
        self.record_issue(f"Project failed: {reason}", severity='critical')

    def get_summary(self) -> Dict[str, Any]:
        """Get comprehensive project state summary."""
        duration = None
        if self.end_time:
            duration = (self.end_time - self.start_time).total_seconds()
        else:
            duration = (datetime.utcnow() - self.start_time).total_seconds()

        return {
            'project_id': self.project_id,
            'project_name': self.project_definition.get('name', 'Unknown'),
            'current_phase': self.phase.value,
            'start_time': self.start_time.isoformat(),
            'end_time': self.end_time.isoformat() if self.end_time else None,
            'duration_seconds': duration,
            'completed_phases': self.completed_phases,
            'deliverables': {
                category: len(items) for category, items in self.deliverables.items()
            },
            'metrics': self.metrics,
            'active_issues': len([i for i in self.issues if not i['resolved']]),
            'active_blockers': len([b for b in self.blockers if not b['resolved']]),
            'decisions_made': len(self.decisions)
        }

    def get_health_status(self) -> str:
        """
        Get project health status.

        Returns:
            Health status: 'healthy', 'at_risk', 'critical'
        """
        active_blockers = len([b for b in self.blockers if not b['resolved']])
        critical_issues = len([i for i in self.issues if not i['resolved'] and i['severity'] == 'critical'])
        failure_rate = self.metrics['tasks_failed'] / max(self.metrics['total_tasks_executed'], 1)

        if active_blockers > 0 or critical_issues > 0:
            return 'critical'
        elif failure_rate > 0.3 or self.metrics['total_replans'] > 5:
            return 'at_risk'
        else:
            return 'healthy'

    @staticmethod
    def _generate_id() -> str:
        """Generate unique project ID."""
        from uuid import uuid4
        return f"proj_{uuid4().hex[:8]}"

    def to_dict(self) -> Dict[str, Any]:
        """Convert project state to dictionary for serialization."""
        return {
            'project_id': self.project_id,
            'project_definition': self.project_definition,
            'phase': self.phase.value,
            'start_time': self.start_time.isoformat(),
            'end_time': self.end_time.isoformat() if self.end_time else None,
            'completed_phases': self.completed_phases,
            'deliverables': self.deliverables,
            'metrics': self.metrics,
            'decisions': self.decisions,
            'issues': self.issues,
            'blockers': self.blockers
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'ProjectState':
        """Restore project state from dictionary."""
        instance = cls(data['project_definition'])
        instance.project_id = data['project_id']
        instance.phase = ProjectPhase(data['phase'])
        instance.start_time = datetime.fromisoformat(data['start_time'])
        instance.end_time = datetime.fromisoformat(data['end_time']) if data['end_time'] else None
        instance.completed_phases = data['completed_phases']
        instance.deliverables = data['deliverables']
        instance.metrics = data['metrics']
        instance.decisions = data['decisions']
        instance.issues = data['issues']
        instance.blockers = data['blockers']
        return instance
