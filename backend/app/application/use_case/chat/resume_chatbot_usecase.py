import json

from fastapi import HTTPException, status

from app.domain.entities.message_entity import MessageEntity
from app.domain.entities.user_entity import UserEntity
from app.domain.repositories.conversation_repository import ConversationRepository
from app.domain.repositories.message_repository import MessageRepository


class ResumeChatbotUseCase:
    def __init__(self, conversation_repo: ConversationRepository,
                 message_repo: MessageRepository):
        self.conversation_repo = conversation_repo
        self.message_repo = message_repo

    def execute(self, conversation_id: int,
                current_user: UserEntity) -> MessageEntity:
        if current_user.role != "admin":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Bạn không có quyền bật lại trợ lý AI cho cuộc hội thoại này",
            )

        conversation = self.conversation_repo.get_by_id(conversation_id)
        if not conversation:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Conversation not found",
            )
        if current_user.id != conversation.admin_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Bạn không có quyền bật lại trợ lý AI cho cuộc hội thoại này",
            )

        self.conversation_repo.update(conversation_id, {"status": "open"})

        metadata = json.dumps({
            "sender_role": "system",
            "payload": {
                "kind": "handoff_notice",
                "notice_code": "bot_resumed",
                "notice_message": "Trợ lý AI đã được kích hoạt lại cho cuộc trò chuyện này.",
            },
        }, ensure_ascii=False)

        message = self.message_repo.create({
            "conversation_id": conversation.id,
            "user_id": current_user.id,
            "type": "system",
            "content": "Trợ lý AI đã được bật lại. Bạn có thể tiếp tục hỏi để được hỗ trợ nhanh hơn.",
            "metadata_json": metadata,
        })

        self.conversation_repo.update(conversation.id, {
            "last_message_id": message.id,
            "last_message_at": message.created_at,
        })

        return self.message_repo.get_by_id(message.id)
