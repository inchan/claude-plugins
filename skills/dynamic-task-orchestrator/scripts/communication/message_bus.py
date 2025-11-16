"""
Message Bus

Central message routing and delivery system for worker communication.
"""

from typing import Dict, Any, List, Callable, Optional
from queue import PriorityQueue
from .worker_protocol import WorkerMessage, MessageType, MessagePriority


class MessageBus:
    """
    Central message bus for routing messages between workers.
    """

    def __init__(self):
        """Initialize message bus."""
        self.message_queue = PriorityQueue()
        self.subscribers = {}  # worker_id -> callback
        self.message_history = []
        self.broadcast_subscribers = []  # Callbacks for broadcast messages

    def register_worker(self, worker_id: str, callback: Callable[[WorkerMessage], None]):
        """
        Register a worker to receive messages.

        Args:
            worker_id: Worker identifier
            callback: Function to call when messages arrive
        """
        self.subscribers[worker_id] = callback

    def unregister_worker(self, worker_id: str):
        """Unregister a worker."""
        if worker_id in self.subscribers:
            del self.subscribers[worker_id]

    def subscribe_to_broadcasts(self, callback: Callable[[WorkerMessage], None]):
        """
        Subscribe to broadcast messages.

        Args:
            callback: Function to call for broadcast messages
        """
        self.broadcast_subscribers.append(callback)

    def send_message(self, message: WorkerMessage):
        """
        Send a message through the bus.

        Args:
            message: Message to send
        """
        # Add to queue with priority
        priority = -message.priority.value  # Negative for higher priority first
        self.message_queue.put((priority, message))

        # Record in history
        self.message_history.append(message)

    def process_messages(self, max_messages: int = 100):
        """
        Process pending messages.

        Args:
            max_messages: Maximum number of messages to process
        """
        processed = 0

        while processed < max_messages and not self.message_queue.empty():
            try:
                _, message = self.message_queue.get_nowait()
                self._deliver_message(message)
                processed += 1
            except Exception as e:
                print(f"Error processing message: {e}")

        return processed

    def _deliver_message(self, message: WorkerMessage):
        """
        Deliver a message to its recipient.

        Args:
            message: Message to deliver
        """
        # Handle broadcast messages
        if message.recipient_id == 'broadcast':
            for callback in self.broadcast_subscribers:
                try:
                    callback(message)
                except Exception as e:
                    print(f"Error delivering broadcast message: {e}")
            message.mark_delivered()
            return

        # Deliver to specific recipient
        if message.recipient_id in self.subscribers:
            callback = self.subscribers[message.recipient_id]
            try:
                callback(message)
                message.mark_delivered()
            except Exception as e:
                print(f"Error delivering message to {message.recipient_id}: {e}")
        else:
            print(f"Warning: No subscriber found for {message.recipient_id}")

    def get_messages_for_worker(self, worker_id: str) -> List[WorkerMessage]:
        """
        Get all messages for a specific worker.

        Args:
            worker_id: Worker to get messages for

        Returns:
            List of messages
        """
        return [
            msg for msg in self.message_history
            if msg.recipient_id == worker_id
        ]

    def get_conversation(self, worker1_id: str, worker2_id: str) -> List[WorkerMessage]:
        """
        Get conversation between two workers.

        Args:
            worker1_id: First worker
            worker2_id: Second worker

        Returns:
            List of messages exchanged between workers
        """
        return [
            msg for msg in self.message_history
            if (msg.sender_id == worker1_id and msg.recipient_id == worker2_id) or
               (msg.sender_id == worker2_id and msg.recipient_id == worker1_id)
        ]

    def get_undelivered_messages(self) -> List[WorkerMessage]:
        """Get all undelivered messages."""
        return [msg for msg in self.message_history if not msg.delivered]

    def get_message_by_id(self, message_id: str) -> Optional[WorkerMessage]:
        """
        Find a message by ID.

        Args:
            message_id: Message identifier

        Returns:
            Message or None if not found
        """
        for msg in self.message_history:
            if msg.message_id == message_id:
                return msg
        return None

    def clear_history(self):
        """Clear message history."""
        self.message_history = []

    def get_statistics(self) -> Dict[str, Any]:
        """Get message bus statistics."""
        total_messages = len(self.message_history)
        delivered_messages = len([m for m in self.message_history if m.delivered])

        # Count by type
        by_type = {}
        for msg_type in MessageType:
            count = len([m for m in self.message_history if m.message_type == msg_type])
            by_type[msg_type.value] = count

        # Count by priority
        by_priority = {}
        for priority in MessagePriority:
            count = len([m for m in self.message_history if m.priority == priority])
            by_priority[priority.value] = count

        return {
            'total_messages': total_messages,
            'delivered_messages': delivered_messages,
            'undelivered_messages': total_messages - delivered_messages,
            'messages_by_type': by_type,
            'messages_by_priority': by_priority,
            'registered_workers': len(self.subscribers),
            'broadcast_subscribers': len(self.broadcast_subscribers)
        }


class WorkerCommunicationHub:
    """
    High-level interface for worker communication.
    """

    def __init__(self, message_bus: MessageBus):
        """
        Initialize communication hub.

        Args:
            message_bus: Message bus instance
        """
        self.message_bus = message_bus
        self.pending_requests = {}  # message_id -> callback

    def send_and_wait_for_response(
        self,
        message: WorkerMessage,
        timeout_seconds: int = 30
    ) -> Optional[WorkerMessage]:
        """
        Send a message and wait for response.

        Args:
            message: Request message to send
            timeout_seconds: How long to wait for response

        Returns:
            Response message or None if timeout
        """
        # This is a simplified synchronous implementation
        # Real implementation would use async or threading

        self.message_bus.send_message(message)
        self.message_bus.process_messages()

        # Look for response in message history
        for msg in reversed(self.message_bus.message_history):
            if msg.response_to == message.message_id:
                return msg

        return None

    def broadcast_and_collect_responses(
        self,
        message: WorkerMessage,
        expected_responses: int,
        timeout_seconds: int = 60
    ) -> List[WorkerMessage]:
        """
        Broadcast a message and collect responses.

        Args:
            message: Broadcast message
            expected_responses: Number of responses expected
            timeout_seconds: How long to wait

        Returns:
            List of response messages
        """
        self.message_bus.send_message(message)
        self.message_bus.process_messages()

        # Collect responses
        responses = []
        for msg in reversed(self.message_bus.message_history):
            if msg.response_to == message.message_id:
                responses.append(msg)
                if len(responses) >= expected_responses:
                    break

        return responses

    def query_worker(
        self,
        worker_id: str,
        query: str,
        filters: Dict[str, Any] = None
    ) -> Optional[Dict[str, Any]]:
        """
        Query a worker for information.

        Args:
            worker_id: Worker to query
            query: Query string
            filters: Optional filters

        Returns:
            Query results
        """
        from .worker_protocol import WorkerProtocol

        message = WorkerProtocol.create_query(
            sender_id='orchestrator',
            recipient_id=worker_id,
            query=query,
            filters=filters
        )

        response = self.send_and_wait_for_response(message)

        if response and response.content.get('success'):
            return response.content.get('data')

        return None
