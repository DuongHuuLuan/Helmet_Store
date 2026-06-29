from typing import Optional

from fastapi import HTTPException, status

from app.domain.entities.message_entity import MessageEntity
from app.domain.entities.user_entity import UserEntity
from app.domain.repositories.conversation_repository import ConversationRepository
from app.domain.repositories.message_repository import MessageRepository


class ListMessagesUseCase:
    def __init__(self, conversation_repo: ConversationRepository,
                 message_repo: MessageRepository):
        self.conversation_repo = conversation_repo
        self.message_repo = message_repo

    def execute(self, conversation_id: int,
                current_user: UserEntity,
                cursor: Optional[int] = None,
                limit: int = 20) -> tuple[list[MessageEntity], Optional[int]]:
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

        return self.message_repo.list_by_conversation_id(
            conversation_id, cursor=cursor, limit=limit
        )
