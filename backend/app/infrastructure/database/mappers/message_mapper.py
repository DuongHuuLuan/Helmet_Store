from app.domain.entities.message_entity import MessageEntity, MessageMediaEntity


class MessageMapper:
    @staticmethod
    def to_entity(model) -> MessageEntity:
        return MessageEntity(
            id=model.id,
            conversation_id=model.conversation_id,
            user_id=model.user_id,
            type=model.type.value if hasattr(model.type, 'value') else model.type,
            content=model.content,
            metadata_json=model.metadata_json,
            client_msg_id=model.client_msg_id,
            created_at=model.created_at,
            updated_at=model.updated_at,
            deleted_at=model.deleted_at,
        )


class MessageMediaMapper:
    @staticmethod
    def to_entity(model) -> MessageMediaEntity:
        return MessageMediaEntity(
            id=model.id,
            message_id=model.message_id,
            path=model.path,
            media_type=model.media_type.value if hasattr(model.media_type, 'value') else model.media_type,
            created_at=model.created_at,
        )
