from app.domain.entities.conversation_entity import ConversationEntity
from app.domain.entities.user_entity import UserEntity
from app.domain.repositories.conversation_repository import ConversationRepository
from app.domain.repositories.message_repository import MessageRepository


class ListConversationsUseCase:
    def __init__(self, conversation_repo: ConversationRepository,
                 message_repo: MessageRepository):
        self.conversation_repo = conversation_repo
        self.message_repo = message_repo

    def execute(self, current_user: UserEntity) -> list[ConversationEntity]:
        if current_user.role == "admin":
            conversations = self.conversation_repo.list_by_admin_id(current_user.id)
        else:
            conversations = self.conversation_repo.list_by_user_id(current_user.id)

        if not conversations:
            return conversations

        read_field = (
            "last_read_admin_message_id"
            if current_user.role == "admin"
            else "last_read_user_message_id"
        )

        last_read_map = {}
        for c in conversations:
            last_read_map[c.id] = getattr(c, read_field)

        unread_rows = self.message_repo.count_unread_bulk(
            [c.id for c in conversations],
            current_user.id,
            last_read_map,
        )

        for c in conversations:
            c.last_read_message_id = getattr(c, read_field)
            c.unread_count = unread_rows.get(c.id, 0)

        return conversations
