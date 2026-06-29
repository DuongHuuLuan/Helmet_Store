from typing import Optional

from fastapi import HTTPException, status

from app.domain.entities.conversation_entity import ConversationEntity
from app.domain.entities.user_entity import UserEntity
from app.domain.repositories.conversation_repository import ConversationRepository
from app.domain.repositories.user_repository import UserRepository


class CreateConversationUseCase:
    def __init__(self, conversation_repo: ConversationRepository,
                 user_repo: UserRepository):
        self.conversation_repo = conversation_repo
        self.user_repo = user_repo

    def execute(self, current_user: UserEntity,
                user_id: Optional[int] = None,
                admin_id: Optional[int] = None) -> ConversationEntity:
        if current_user.role == "admin":
            if user_id is None:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Admin must provide user_id to open chat",
                )
            target_user = self.user_repo.get_by_id(user_id)
            if not target_user or target_user.role != "user":
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Invalid user_id",
                )
            target_user_id = user_id
            target_admin_id = current_user.id
        elif current_user.role == "user":
            target_user_id = current_user.id
            if admin_id is None:
                target_admin = self.user_repo.get_first_by_role("admin")
                if not target_admin:
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail="No admin account is available for chat",
                    )
                target_admin_id = target_admin.id
            else:
                target_admin = self.user_repo.get_by_id(admin_id)
                if not target_admin or target_admin.role != "admin":
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail="Invalid admin_id",
                    )
                target_admin_id = admin_id
        else:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You do not have permission to create a conversation",
            )

        existing = self.conversation_repo.get_by_user_admin(
            target_user_id, target_admin_id
        )
        if existing:
            return existing

        return self.conversation_repo.create({
            "user_id": target_user_id,
            "admin_id": target_admin_id,
        })
