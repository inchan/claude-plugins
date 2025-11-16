"""
Worker Protocol

Defines communication protocol for inter-worker communication.
"""

from typing import Dict, Any, List, Optional
from enum import Enum
from datetime import datetime


class MessageType(Enum):
    """Types of inter-worker messages"""
    REQUEST = "request"
    RESPONSE = "response"
    NOTIFICATION = "notification"
    QUERY = "query"
    BROADCAST = "broadcast"


class MessagePriority(Enum):
    """Message priority levels"""
    LOW = 1
    NORMAL = 2
    HIGH = 3
    URGENT = 4


class WorkerMessage:
    """
    Standard message format for worker communication.
    """

    def __init__(
        self,
        message_type: MessageType,
        sender_id: str,
        recipient_id: str,
        content: Dict[str, Any],
        priority: MessagePriority = MessagePriority.NORMAL
    ):
        """
        Initialize a worker message.

        Args:
            message_type: Type of message
            sender_id: ID of sending worker
            recipient_id: ID of receiving worker (or 'broadcast' for all)
            content: Message payload
            priority: Message priority
        """
        self.message_id = self._generate_message_id()
        self.message_type = message_type
        self.sender_id = sender_id
        self.recipient_id = recipient_id
        self.content = content
        self.priority = priority
        self.timestamp = datetime.utcnow()
        self.delivered = False
        self.response_to = None  # ID of message this is responding to

    def mark_delivered(self):
        """Mark message as delivered."""
        self.delivered = True

    def set_response_to(self, message_id: str):
        """Set which message this is responding to."""
        self.response_to = message_id

    def to_dict(self) -> Dict[str, Any]:
        """Convert message to dictionary."""
        return {
            'message_id': self.message_id,
            'message_type': self.message_type.value,
            'sender_id': self.sender_id,
            'recipient_id': self.recipient_id,
            'content': self.content,
            'priority': self.priority.value,
            'timestamp': self.timestamp.isoformat(),
            'delivered': self.delivered,
            'response_to': self.response_to
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'WorkerMessage':
        """Create message from dictionary."""
        message = cls(
            message_type=MessageType(data['message_type']),
            sender_id=data['sender_id'],
            recipient_id=data['recipient_id'],
            content=data['content'],
            priority=MessagePriority(data['priority'])
        )
        message.message_id = data['message_id']
        message.timestamp = datetime.fromisoformat(data['timestamp'])
        message.delivered = data['delivered']
        message.response_to = data.get('response_to')
        return message

    @staticmethod
    def _generate_message_id() -> str:
        """Generate unique message ID."""
        from uuid import uuid4
        return f"msg_{uuid4().hex[:12]}"


class WorkerProtocol:
    """
    Defines protocol for worker-to-worker communication.
    """

    @staticmethod
    def create_request(
        sender_id: str,
        recipient_id: str,
        request_type: str,
        parameters: Dict[str, Any]
    ) -> WorkerMessage:
        """
        Create a request message.

        Args:
            sender_id: Requesting worker
            recipient_id: Worker to handle request
            request_type: Type of request
            parameters: Request parameters

        Returns:
            Request message
        """
        content = {
            'request_type': request_type,
            'parameters': parameters
        }

        return WorkerMessage(
            message_type=MessageType.REQUEST,
            sender_id=sender_id,
            recipient_id=recipient_id,
            content=content,
            priority=MessagePriority.NORMAL
        )

    @staticmethod
    def create_response(
        sender_id: str,
        recipient_id: str,
        request_message_id: str,
        response_data: Dict[str, Any],
        success: bool = True
    ) -> WorkerMessage:
        """
        Create a response message.

        Args:
            sender_id: Responding worker
            recipient_id: Original requester
            request_message_id: ID of request being responded to
            response_data: Response payload
            success: Whether request was successful

        Returns:
            Response message
        """
        content = {
            'success': success,
            'data': response_data
        }

        message = WorkerMessage(
            message_type=MessageType.RESPONSE,
            sender_id=sender_id,
            recipient_id=recipient_id,
            content=content,
            priority=MessagePriority.NORMAL
        )
        message.set_response_to(request_message_id)

        return message

    @staticmethod
    def create_notification(
        sender_id: str,
        recipient_id: str,
        notification_type: str,
        data: Dict[str, Any]
    ) -> WorkerMessage:
        """
        Create a notification message.

        Args:
            sender_id: Notifying worker
            recipient_id: Worker to notify (or 'broadcast')
            notification_type: Type of notification
            data: Notification data

        Returns:
            Notification message
        """
        content = {
            'notification_type': notification_type,
            'data': data
        }

        return WorkerMessage(
            message_type=MessageType.NOTIFICATION,
            sender_id=sender_id,
            recipient_id=recipient_id,
            content=content,
            priority=MessagePriority.LOW
        )

    @staticmethod
    def create_query(
        sender_id: str,
        recipient_id: str,
        query: str,
        filters: Dict[str, Any] = None
    ) -> WorkerMessage:
        """
        Create a query message.

        Args:
            sender_id: Querying worker
            recipient_id: Worker to query
            query: Query string
            filters: Optional query filters

        Returns:
            Query message
        """
        content = {
            'query': query,
            'filters': filters or {}
        }

        return WorkerMessage(
            message_type=MessageType.QUERY,
            sender_id=sender_id,
            recipient_id=recipient_id,
            content=content,
            priority=MessagePriority.NORMAL
        )

    @staticmethod
    def create_broadcast(
        sender_id: str,
        announcement_type: str,
        data: Dict[str, Any]
    ) -> WorkerMessage:
        """
        Create a broadcast message to all workers.

        Args:
            sender_id: Broadcasting worker
            announcement_type: Type of announcement
            data: Broadcast data

        Returns:
            Broadcast message
        """
        content = {
            'announcement_type': announcement_type,
            'data': data
        }

        return WorkerMessage(
            message_type=MessageType.BROADCAST,
            sender_id=sender_id,
            recipient_id='broadcast',
            content=content,
            priority=MessagePriority.NORMAL
        )


# Common protocol messages

class ProtocolMessages:
    """
    Common protocol message templates.
    """

    @staticmethod
    def request_architecture_info(sender_id: str) -> WorkerMessage:
        """Request architecture information from architect."""
        return WorkerProtocol.create_request(
            sender_id=sender_id,
            recipient_id='architect',
            request_type='get_architecture',
            parameters={}
        )

    @staticmethod
    def request_code_review(sender_id: str, code_paths: List[str]) -> WorkerMessage:
        """Request code review."""
        return WorkerProtocol.create_request(
            sender_id=sender_id,
            recipient_id='developer',
            request_type='review_code',
            parameters={'code_paths': code_paths}
        )

    @staticmethod
    def notify_task_complete(sender_id: str, task_id: str, artifacts: List[str]) -> WorkerMessage:
        """Notify that a task is complete."""
        return WorkerProtocol.create_broadcast(
            sender_id=sender_id,
            announcement_type='task_complete',
            data={
                'task_id': task_id,
                'artifacts': artifacts
            }
        )

    @staticmethod
    def query_shared_knowledge(sender_id: str, key: str) -> WorkerMessage:
        """Query shared knowledge base."""
        return WorkerProtocol.create_query(
            sender_id=sender_id,
            recipient_id='orchestrator',
            query='get_shared_knowledge',
            filters={'key': key}
        )
