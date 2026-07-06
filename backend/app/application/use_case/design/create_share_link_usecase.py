import secrets

from fastapi import HTTPException, status

from app.core.config import settings
from app.domain.repositories.design_repository import DesignRepository


class CreateShareLinkUseCase:
    def __init__(self, design_repo: DesignRepository):
        self.design_repo = design_repo

    def execute(self, design_id: int, user_id: int) -> dict:
        design = self.design_repo.get_by_id_with_details(design_id)
        if not design:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Không tìm thấy thiết kế",
            )
        if design["user_id"] != user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Bạn không có quyền truy cập thiết kế này",
            )

        existing_share = next(iter(design.get("shares", [])), None)
        if existing_share:
            if not design["is_shared"]:
                self.design_repo.update(design_id, {"is_shared": True})
            return {"share_url": existing_share["public_url"]}

        token = secrets.token_urlsafe(24)
        base_url = settings.APP_RETURN_URL.rstrip("/")
        share_url = f"{base_url}/designs/{token}" if base_url else f"/designs/{token}"

        self.design_repo.create_share_link(
            design_id,
            {
                "share_token": token,
                "public_url": share_url,
            },
        )
        self.design_repo.update(design_id, {"is_shared": True})

        return {"share_url": share_url}
