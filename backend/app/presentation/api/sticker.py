from typing import Optional

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status

from app.presentation.api.deps import get_current_user_optional, require_admin, require_user
from app.domain.entities.user_entity import UserEntity as User
from app.application.dto.sticker_dto import (
    AiStickerGenerateIn,
    AiStickerTranscriptionOut,
    RemoveBackgroundIn,
    RemoveBackgroundOut,
    StickerAdminOut,
    StickerAdminPaginationOut,
    StickerCreate,
    StickerListOut,
    StickerOut,
    StickerUpdate,
)
from app.shared.dependencies import (
    get_sticker_catalog_use_case,
    get_admin_stickers_use_case,
    get_admin_sticker_use_case,
    get_system_sticker_use_case,
    get_create_sticker_use_case,
    get_update_sticker_use_case,
    get_delete_sticker_use_case,
    get_generate_ai_sticker_use_case,
    get_transcribe_ai_sticker_voice_use_case,
)
from app.application.use_case.sticker.get_sticker_catalog_usecase import GetStickerCatalogUseCase
from app.application.use_case.sticker.get_admin_stickers_usecase import GetAdminStickersUseCase
from app.application.use_case.sticker.get_admin_sticker_usecase import GetAdminStickerUseCase
from app.application.use_case.sticker.get_system_sticker_usecase import GetSystemStickerUseCase
from app.application.use_case.sticker.create_sticker_usecase import CreateStickerUseCase
from app.application.use_case.sticker.update_sticker_usecase import UpdateStickerUseCase
from app.application.use_case.sticker.delete_sticker_usecase import DeleteStickerUseCase
from app.application.use_case.sticker.generate_ai_sticker_usecase import GenerateAiStickerUseCase
from app.application.use_case.sticker.transcribe_ai_sticker_voice_usecase import TranscribeAiStickerVoiceUseCase

router = APIRouter(prefix="/stickers", tags=["Stickers"])


@router.get("/", response_model=StickerListOut)
def get_sticker_catalog(
    current_user: User | None = Depends(get_current_user_optional),
    use_case: GetStickerCatalogUseCase = Depends(get_sticker_catalog_use_case),
):
    items = use_case.execute(
        user_id=current_user.id if current_user else None,
    )
    return {"items": items}


@router.get("/admin", response_model=StickerAdminPaginationOut)
def get_admin_stickers(
    page: int = 1,
    per_page: Optional[int] = None,
    q: Optional[str] = None,
    category: Optional[str] = None,
    scope: Optional[str] = "system",
    current_admin: User = Depends(require_admin),
    use_case: GetAdminStickersUseCase = Depends(get_admin_stickers_use_case),
):
    return use_case.execute(
        page=page,
        per_page=per_page,
        keyword=q,
        category=category,
        scope=scope,
    )


@router.get("/admin/{sticker_id}", response_model=StickerAdminOut)
def get_admin_sticker(
    sticker_id: int,
    current_admin: User = Depends(require_admin),
    use_case: GetAdminStickerUseCase = Depends(get_admin_sticker_use_case),
):
    return use_case.execute(sticker_id=sticker_id)


@router.get("/admin/system/{sticker_id}", response_model=StickerAdminOut)
def get_system_sticker(
    sticker_id: int,
    current_admin: User = Depends(require_admin),
    use_case: GetSystemStickerUseCase = Depends(get_system_sticker_use_case),
):
    return use_case.execute(sticker_id=sticker_id)


@router.post("/admin/system", response_model=StickerAdminOut, status_code=status.HTTP_201_CREATED)
def create_system_sticker(
    sticker_in: StickerCreate,
    current_admin: User = Depends(require_admin),
    use_case: CreateStickerUseCase = Depends(get_create_sticker_use_case),
):
    return use_case.execute(sticker_in=sticker_in)


@router.put("/admin/system/{sticker_id}", response_model=StickerAdminOut)
def update_system_sticker(
    sticker_id: int,
    sticker_in: StickerUpdate,
    current_admin: User = Depends(require_admin),
    use_case: UpdateStickerUseCase = Depends(get_update_sticker_use_case),
):
    return use_case.execute(sticker_id=sticker_id, sticker_in=sticker_in)


@router.delete("/admin/system/{sticker_id}", status_code=status.HTTP_200_OK)
def delete_system_sticker(
    sticker_id: int,
    current_admin: User = Depends(require_admin),
    use_case: DeleteStickerUseCase = Depends(get_delete_sticker_use_case),
):
    return use_case.execute(sticker_id=sticker_id)


@router.post("/generate", response_model=StickerOut, status_code=status.HTTP_201_CREATED)
def generate_ai_sticker(
    sticker_in: AiStickerGenerateIn,
    current_user: User = Depends(require_user),
    use_case: GenerateAiStickerUseCase = Depends(get_generate_ai_sticker_use_case),
):
    return use_case.execute(user_id=current_user.id, sticker_in=sticker_in)


@router.post("/transcribe-voice", response_model=AiStickerTranscriptionOut, status_code=status.HTTP_200_OK)
async def transcribe_ai_sticker_voice(
    audio: UploadFile = File(...),
    current_user: User = Depends(require_user),
    use_case: TranscribeAiStickerVoiceUseCase = Depends(get_transcribe_ai_sticker_voice_use_case),
):
    audio_bytes = await audio.read()
    prompt = use_case.execute(
        filename=audio.filename or "ai-sticker-voice.m4a",
        content_type=audio.content_type,
        audio_bytes=audio_bytes,
    )
    return {"prompt": prompt}
