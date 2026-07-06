import json

from fastapi import HTTPException, status

from app.domain.entities.message_entity import MessageEntity
from app.domain.entities.user_entity import UserEntity
from app.domain.repositories.conversation_repository import ConversationRepository
from app.domain.repositories.message_repository import MessageRepository


class ClaimHandoffUseCase:
    def __init__(self, conversation_repo: ConversationRepository,
                 message_repo: MessageRepository):
        self.conversation_repo = conversation_repo
        self.message_repo = message_repo

    def execute(self, conversation_id: int,
                current_user: UserEntity) -> MessageEntity:
        if current_user.role != "admin":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Bạn không có quyền tiếp nhận cuộc hội thoại này",
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
                detail="Bạn không có quyền tiếp nhận cuộc hội thoại này",
            )

        if conversation.status == "open":
            self.conversation_repo.update(conversation_id, {"status": "closed"})
        elif conversation.status != "closed":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Cuộc hội thoại này không thể tiếp nhận lúc này",
            )

        metadata = json.dumps({
            "sender_role": "system",
            "payload": {
                "kind": "handoff_notice",
                "notice_code": "human_handoff_claimed",
                "notice_message": "Tư vấn viên đã tiếp nhận cuộc trò chuyện này.",
            },
        }, ensure_ascii=False)

        message = self.message_repo.create({
            "conversation_id": conversation.id,
            "user_id": current_user.id,
            "type": "system",
            "content": "Tư vấn viên đã tham gia cuộc trò chuyện và sẽ hỗ trợ bạn trực tiếp.",
            "metadata_json": metadata,
        })

        self.conversation_repo.update(conversation.id, {
            "last_message_id": message.id,
            "last_message_at": message.created_at,
        })

        return self.message_repo.get_by_id(message.id)
