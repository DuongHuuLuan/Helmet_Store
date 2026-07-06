from typing import Optional

from fastapi import HTTPException, status

from app.domain.entities.user_entity import UserEntity
from app.domain.repositories.conversation_repository import ConversationRepository
from app.domain.repositories.message_repository import MessageRepository


class MarkReadUseCase:
    def __init__(self, conversation_repo: ConversationRepository,
                 message_repo: MessageRepository):
        self.conversation_repo = conversation_repo
        self.message_repo = message_repo

    def execute(self, conversation_id: int,
                current_user: UserEntity,
                message_id: Optional[int] = None) -> dict:
        conversation = self.conversation_repo.get_by_id(conversation_id)
        if not conversation:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Conversation not found",
            )
        if current_user.id not in (conversation.user_id, conversation.admin_id):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You are not a member of this conversation",
            )

        read_field = (
            "last_read_admin_message_id"
            if current_user.role == "admin"
            else "last_read_user_message_id"
        )

        latest_id = self.message_repo.get_latest_message_id(
            conversation_id,
            exclude_user_id=current_user.id,
            max_id=message_id,
        )

        current_read = getattr(conversation, read_field)
        next_read = current_read
        changed = False

        if latest_id is not None and (current_read is None or latest_id > current_read):
            self.conversation_repo.update(conversation_id, {read_field: latest_id})
            next_read = latest_id
            changed = True

        unread = self.message_repo.count_unread(
            conversation_id, current_user.id, next_read
        )

        return {
            "conversation_id": conversation.id,
            "last_read_message_id": next_read,
            "unread_count": unread,
            "changed": changed,
        }
