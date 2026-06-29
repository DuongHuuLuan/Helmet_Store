from fastapi import APIRouter, UploadFile, File, Depends, Form
from app.presentation.api.deps import require_admin
from app.domain.entities.user_entity import UserEntity as User
from app.shared.dependencies import get_upload_image_use_case
from app.application.use_case.image.upload_image_usecase import UploadImageUseCase

router = APIRouter(prefix="/images", tags=["Images"])

@router.post("/upload")
def upload_image(
    file: UploadFile = File(...),
    folder: str = Form(default="helmet_shop/products"),
    current_admin: User = Depends(require_admin),
    use_case: UploadImageUseCase = Depends(get_upload_image_use_case),
):
    return use_case.execute(file=file, folder=folder)
