from app.domain.entities.conversation_entity import ConversationEntity


class ConversationMapper:
    @staticmethod
    def to_entity(model) -> ConversationEntity:
        return ConversationEntity(
            id=model.id,
            user_id=model.user_id,
            admin_id=model.admin_id,
            status=model.status.value if hasattr(model.status, 'value') else model.status,
            last_message_id=model.last_message_id,
            last_message_at=model.last_message_at,
            last_read_user_message_id=model.last_read_user_message_id,
            last_read_admin_message_id=model.last_read_admin_message_id,
            created_at=model.created_at,
            updated_at=model.updated_at,
        )
