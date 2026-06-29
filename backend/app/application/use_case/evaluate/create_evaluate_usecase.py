from typing import Optional

from fastapi import HTTPException, status

from app.domain.repositories.evaluate_repository import EvaluateRepository


class CreateEvaluateUseCase:
    def __init__(self, evaluate_repository: EvaluateRepository):
        self._repo = evaluate_repository

    def execute(self, user_id: int, order_id: int,
                rate: int, content: Optional[str],
                image_urls: list[str]) -> dict:
        order = self._repo.get_order_info(order_id)
        if not order:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Đơn hàng không tồn tại",
            )
        if order["user_id"] != user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Bạn không có quyền đánh giá đơn hàng của người khác",
            )
        if order["status"] != "completed":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Chỉ có thể đánh giá đơn hàng đã hoàn thành",
            )

        if self._repo.exists_by_order_id(order_id):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Bạn đã đánh giá đơn hàng này rồi",
            )

        return self._repo.create_evaluate_with_images(
            data={
                "order_id": order_id,
                "user_id": user_id,
                "rate": rate,
                "content": content,
                "image": image_urls[0] if image_urls else None,
            },
            image_urls=image_urls,
        )
