from fastapi import HTTPException, status

from app.domain.repositories.design_repository import DesignRepository


class GetDesignDetailUseCase:
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
        return design
