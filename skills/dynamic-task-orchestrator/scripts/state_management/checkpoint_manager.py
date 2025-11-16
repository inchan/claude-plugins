"""
Checkpoint Manager

Manages progress checkpoints for recovery and rollback.
"""

from typing import Dict, Any, List, Optional
from datetime import datetime
import json
import os


class CheckpointManager:
    """
    Creates and manages execution checkpoints for recovery.
    """

    def __init__(self, checkpoint_dir: str = '.orchestrator_checkpoints'):
        """
        Initialize checkpoint manager.

        Args:
            checkpoint_dir: Directory to store checkpoints
        """
        self.checkpoint_dir = checkpoint_dir
        self.checkpoints = []
        self.auto_checkpoint_interval = 5  # Checkpoint every N tasks

    def create_checkpoint(
        self,
        project_state: Any,
        context: Dict[str, Any],
        worker_states: Dict[str, Any],
        checkpoint_type: str = 'auto'
    ) -> str:
        """
        Create a checkpoint of current execution state.

        Args:
            project_state: ProjectState instance
            context: Execution context
            worker_states: States of all workers
            checkpoint_type: Type of checkpoint ('auto', 'manual', 'before_replan')

        Returns:
            Checkpoint ID
        """
        checkpoint_id = self._generate_checkpoint_id()

        checkpoint_data = {
            'checkpoint_id': checkpoint_id,
            'timestamp': datetime.utcnow().isoformat(),
            'type': checkpoint_type,
            'project_state': project_state.to_dict() if hasattr(project_state, 'to_dict') else project_state,
            'context': context,
            'worker_states': worker_states
        }

        self.checkpoints.append(checkpoint_data)

        # Optionally save to disk
        if self.checkpoint_dir:
            self._save_checkpoint_to_disk(checkpoint_id, checkpoint_data)

        return checkpoint_id

    def get_checkpoint(self, checkpoint_id: str) -> Optional[Dict[str, Any]]:
        """
        Retrieve a checkpoint by ID.

        Args:
            checkpoint_id: Checkpoint identifier

        Returns:
            Checkpoint data or None if not found
        """
        # Try memory first
        for checkpoint in self.checkpoints:
            if checkpoint['checkpoint_id'] == checkpoint_id:
                return checkpoint

        # Try disk
        if self.checkpoint_dir:
            return self._load_checkpoint_from_disk(checkpoint_id)

        return None

    def get_latest_checkpoint(self) -> Optional[Dict[str, Any]]:
        """Get the most recent checkpoint."""
        if self.checkpoints:
            return self.checkpoints[-1]

        # Try loading from disk
        if self.checkpoint_dir:
            return self._load_latest_checkpoint_from_disk()

        return None

    def restore_checkpoint(self, checkpoint_id: str) -> Optional[Dict[str, Any]]:
        """
        Restore execution state from a checkpoint.

        Args:
            checkpoint_id: Checkpoint to restore

        Returns:
            Restored state data
        """
        checkpoint = self.get_checkpoint(checkpoint_id)

        if checkpoint:
            return {
                'project_state': checkpoint['project_state'],
                'context': checkpoint['context'],
                'worker_states': checkpoint['worker_states']
            }

        return None

    def list_checkpoints(self, checkpoint_type: str = None) -> List[Dict[str, Any]]:
        """
        List all checkpoints, optionally filtered by type.

        Args:
            checkpoint_type: Optional filter by checkpoint type

        Returns:
            List of checkpoint summaries
        """
        checkpoints = self.checkpoints.copy()

        # Also load from disk
        if self.checkpoint_dir:
            disk_checkpoints = self._list_disk_checkpoints()
            checkpoints.extend(disk_checkpoints)

        if checkpoint_type:
            checkpoints = [cp for cp in checkpoints if cp['type'] == checkpoint_type]

        # Return summaries
        return [
            {
                'checkpoint_id': cp['checkpoint_id'],
                'timestamp': cp['timestamp'],
                'type': cp['type']
            }
            for cp in checkpoints
        ]

    def should_checkpoint(self, tasks_since_last: int) -> bool:
        """
        Determine if a checkpoint should be created.

        Args:
            tasks_since_last: Number of tasks since last checkpoint

        Returns:
            True if checkpoint should be created
        """
        return tasks_since_last >= self.auto_checkpoint_interval

    def cleanup_old_checkpoints(self, keep_count: int = 10):
        """
        Remove old checkpoints, keeping only the most recent ones.

        Args:
            keep_count: Number of recent checkpoints to keep
        """
        if len(self.checkpoints) > keep_count:
            removed = self.checkpoints[:-keep_count]
            self.checkpoints = self.checkpoints[-keep_count:]

            # Remove from disk
            if self.checkpoint_dir:
                for checkpoint in removed:
                    self._delete_checkpoint_from_disk(checkpoint['checkpoint_id'])

    def _generate_checkpoint_id(self) -> str:
        """Generate unique checkpoint ID."""
        timestamp = datetime.utcnow().strftime('%Y%m%d_%H%M%S')
        return f"checkpoint_{timestamp}_{len(self.checkpoints)}"

    def _save_checkpoint_to_disk(self, checkpoint_id: str, checkpoint_data: Dict[str, Any]):
        """Save checkpoint to disk."""
        if not os.path.exists(self.checkpoint_dir):
            os.makedirs(self.checkpoint_dir)

        file_path = os.path.join(self.checkpoint_dir, f"{checkpoint_id}.json")

        try:
            with open(file_path, 'w') as f:
                json.dump(checkpoint_data, f, indent=2)
        except Exception as e:
            print(f"Warning: Failed to save checkpoint to disk: {e}")

    def _load_checkpoint_from_disk(self, checkpoint_id: str) -> Optional[Dict[str, Any]]:
        """Load checkpoint from disk."""
        file_path = os.path.join(self.checkpoint_dir, f"{checkpoint_id}.json")

        if not os.path.exists(file_path):
            return None

        try:
            with open(file_path, 'r') as f:
                return json.load(f)
        except Exception as e:
            print(f"Warning: Failed to load checkpoint from disk: {e}")
            return None

    def _load_latest_checkpoint_from_disk(self) -> Optional[Dict[str, Any]]:
        """Load the most recent checkpoint from disk."""
        if not os.path.exists(self.checkpoint_dir):
            return None

        try:
            checkpoint_files = [
                f for f in os.listdir(self.checkpoint_dir)
                if f.endswith('.json')
            ]

            if not checkpoint_files:
                return None

            # Sort by filename (which includes timestamp)
            checkpoint_files.sort(reverse=True)
            latest_file = checkpoint_files[0]

            with open(os.path.join(self.checkpoint_dir, latest_file), 'r') as f:
                return json.load(f)
        except Exception as e:
            print(f"Warning: Failed to load latest checkpoint: {e}")
            return None

    def _list_disk_checkpoints(self) -> List[Dict[str, Any]]:
        """List all checkpoints stored on disk."""
        if not os.path.exists(self.checkpoint_dir):
            return []

        checkpoints = []

        try:
            checkpoint_files = [
                f for f in os.listdir(self.checkpoint_dir)
                if f.endswith('.json')
            ]

            for file_name in checkpoint_files:
                file_path = os.path.join(self.checkpoint_dir, file_name)
                with open(file_path, 'r') as f:
                    checkpoint_data = json.load(f)
                    checkpoints.append(checkpoint_data)
        except Exception as e:
            print(f"Warning: Failed to list disk checkpoints: {e}")

        return checkpoints

    def _delete_checkpoint_from_disk(self, checkpoint_id: str):
        """Delete a checkpoint file from disk."""
        file_path = os.path.join(self.checkpoint_dir, f"{checkpoint_id}.json")

        if os.path.exists(file_path):
            try:
                os.remove(file_path)
            except Exception as e:
                print(f"Warning: Failed to delete checkpoint: {e}")
