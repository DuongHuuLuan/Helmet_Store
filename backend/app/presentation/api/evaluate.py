from typing import List, Optional

import cloudinary.uploader
from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException, status
from fastapi.params import Query

from app.core.config import settings
from app.presentation.api.deps import require_admin, require_user
from app.domain.entities.user_entity import UserEntity as User
from app.infrastructure.database.models.user import UserRole
from app.application.dto.evaluate_dto import (
    EvaluateOut,
    EvaluateReplyCreate,
    EvaluatePaginationOut,
    EvaluateProductPaginationOut,
)
from app.shared.dependencies import (
    get_create_evaluate_use_case,
    get_admin_evaluations_use_case,
    get_evaluate_by_id_use_case,
    get_evaluate_by_order_use_case,
    get_my_evaluations_use_case,
    get_product_evaluations_use_case,
    get_reply_evaluate_use_case,
    CreateEvaluateUseCase,
    GetAdminEvaluationsUseCase,
    GetEvaluateByIdUseCase,
    GetEvaluateByOrderUseCase,
    GetMyEvaluationsUseCase,
    GetProductEvaluationsUseCase,
    ReplyEvaluateUseCase,
)

router = APIRouter(prefix="/evaluates", tags=["Evaluates"])

MAX_EVALUATE_IMAGES = 5


def _upload_evaluate_images_to_cloudinary(files: List[UploadFile]) -> List[dict]:
    uploaded_images: List[dict] = []
    uploaded_public_ids: List[str] = []
    try:
        for file in files:
            result = cloudinary.uploader.upload(
                file.file,
                folder=settings.EVALUATE_IMAGE_CLOUDINARY_FOLDER,
                resource_type="image",
            )
            image_url = result.get("secure_url")
            public_id = result.get("public_id")
            if not image_url:
                raise HTTPException(
                    status_code=status.HTTP_502_BAD_GATEWAY,
                    detail="Cloudinary không trả về ảnh hợp lệ",
                )
            uploaded_images.append({"url": image_url, "public_id": public_id})
            if public_id:
                uploaded_public_ids.append(public_id)
    except HTTPException:
        for public_id in uploaded_public_ids:
            try:
                cloudinary.uploader.destroy(public_id)
            except Exception:
                pass
        raise
    except Exception as exc:
        for public_id in uploaded_public_ids:
            try:
                cloudinary.uploader.destroy(public_id)
            except Exception:
                pass
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Không thể tải ảnh đánh giá lên Cloudinary: {exc}",
        ) from exc

    return uploaded_images


@router.get("/admin", response_model=EvaluatePaginationOut)
def get_admin_evaluations(
    page: int = Query(1, ge=1),
    per_page: int = Query(8, ge=1, le=100),
    has_reply: Optional[bool] = Query(None),
    order_id: Optional[int] = Query(None, ge=1),
    current_admin: User = Depends(require_admin),
    use_case: GetAdminEvaluationsUseCase = Depends(get_admin_evaluations_use_case),
):
    return use_case.execute(
        page=page,
        per_page=per_page,
        has_reply=has_reply,
        order_id=order_id,
    )


@router.get("/my", response_model=EvaluatePaginationOut)
def get_my_evaluations(
    page: int = Query(1, ge=1),
    per_page: int = Query(8, ge=1, le=100),
    current_user: User = Depends(require_user),
    use_case: GetMyEvaluationsUseCase = Depends(get_my_evaluations_use_case),
):
    return use_case.execute(
        user_id=current_user.id,
        page=page,
        per_page=per_page,
    )


@router.get("/order/{order_id}", response_model=EvaluateOut)
def get_evaluate_by_order(
    order_id: int,
    current_user: User = Depends(require_user),
    use_case: GetEvaluateByOrderUseCase = Depends(get_evaluate_by_order_use_case),
):
    return use_case.execute(
        order_id=order_id,
        user_id=current_user.id,
        is_admin=current_user.role == UserRole.ADMIN,
    )


@router.get("/product/{product_id}", response_model=EvaluateProductPaginationOut)
def get_product_evaluations(
    product_id: int,
    page: int = Query(1, ge=1),
    per_page: int = Query(3, ge=1, le=100),
    use_case: GetProductEvaluationsUseCase = Depends(get_product_evaluations_use_case),
):
    return use_case.execute(
        product_id=product_id,
        page=page,
        per_page=per_page,
    )


@router.get("/{evaluate_id}", response_model=EvaluateOut)
def get_evaluate_detail(
    evaluate_id: int,
    current_user: User = Depends(require_user),
    use_case: GetEvaluateByIdUseCase = Depends(get_evaluate_by_id_use_case),
):
    return use_case.execute(
        evaluate_id=evaluate_id,
        user_id=current_user.id,
        is_admin=current_user.role == UserRole.ADMIN,
    )


@router.post("/{order_id}", response_model=EvaluateOut, status_code=status.HTTP_201_CREATED)
async def post_evaluate(
    order_id: int,
    rate: int = Form(..., ge=1, le=5),
    content: Optional[str] = Form(None),
    images: Optional[List[UploadFile]] = File(default=None),
    current_user: User = Depends(require_user),
    use_case: CreateEvaluateUseCase = Depends(get_create_evaluate_use_case),
):
    uploaded_files = images or []

    if len(uploaded_files) > MAX_EVALUATE_IMAGES:
        raise HTTPException(status_code=400, detail=f"Chỉ được tải tối đa {MAX_EVALUATE_IMAGES} ảnh")

    for image in uploaded_files:
        if not image.content_type or not image.content_type.startswith("image/"):
            raise HTTPException(status_code=400, detail="Tất cả file tải lên phải là ảnh")

    uploaded_images = _upload_evaluate_images_to_cloudinary(uploaded_files)
    image_urls = [img["url"] for img in uploaded_images]
    public_ids = [img["public_id"] for img in uploaded_images if img.get("public_id")]

    try:
        return use_case.execute(
            user_id=current_user.id,
            order_id=order_id,
            rate=rate,
            content=content,
            image_urls=image_urls,
        )
    except Exception:
        for public_id in public_ids:
            try:
                cloudinary.uploader.destroy(public_id)
            except Exception:
                pass
        raise


@router.post("/{evaluate_id}/reply", response_model=EvaluateOut)
def reply_evaluate(
    evaluate_id: int,
    payload: EvaluateReplyCreate,
    current_admin: User = Depends(require_admin),
    use_case: ReplyEvaluateUseCase = Depends(get_reply_evaluate_use_case),
):
    return use_case.execute(
        evaluate_id=evaluate_id,
        admin_id=current_admin.id,
        admin_reply=payload.admin_reply,
    )
