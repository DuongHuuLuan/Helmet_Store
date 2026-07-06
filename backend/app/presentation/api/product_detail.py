from typing import List
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session, joinedload
from app.infrastructure.database.session import get_db
from app.infrastructure.database.models.product_detail import ProductDetail
from app.infrastructure.database.models.size import Size
from app.infrastructure.database.models.color import Color
from app.application.dto.product_detail_dto import ColorCreate, ColorOut, SizeCreate, SizeOut, SizeUpdate, ProductDetailCreate, ProductDetailUpdate, ProductDetailOut
from app.presentation.api.deps import require_admin
from app.domain.entities.user_entity import UserEntity as User
from app.shared.dependencies import (
    get_colors_use_case,
    get_color_by_id_use_case,
    create_color_use_case,
    update_color_use_case,
    delete_color_use_case,
    get_sizes_use_case,
    get_size_by_id_use_case,
    create_size_use_case,
    update_size_use_case,
    delete_size_use_case,
    get_create_product_detail_use_case,
    get_update_product_detail_use_case,
    get_delete_product_detail_use_case,
)
from app.application.use_case.color.get_colors_usecase import GetColorsUseCase
from app.application.use_case.color.get_color_by_id_usecase import GetColorByIdUseCase
from app.application.use_case.color.create_color_usecase import CreateColorUseCase
from app.application.use_case.color.update_color_usecase import UpdateColorUseCase
from app.application.use_case.color.delete_color_usecase import DeleteColorUseCase
from app.application.use_case.size.get_sizes_usecase import GetSizesUseCase
from app.application.use_case.size.get_size_by_id_usecase import GetSizeByIdUseCase
from app.application.use_case.size.create_size_usecase import CreateSizeUseCase
from app.application.use_case.size.update_size_usecase import UpdateSizeUseCase
from app.application.use_case.size.delete_size_usecase import DeleteSizeUseCase
from app.application.use_case.product_detail.create_product_detail_usecase import CreateProductDetailUseCase
from app.application.use_case.product_detail.update_product_detail_usecase import UpdateProductDetailUseCase
from app.application.use_case.product_detail.delete_product_detail_usecase import DeleteProductDetailUseCase

router = APIRouter(prefix="/product-details", tags=["Product Details"])


def _get_detail_model(db: Session, detail_id: int):
    return (
        db.query(ProductDetail)
        .options(
            joinedload(ProductDetail.color),
            joinedload(ProductDetail.size),
        )
        .filter(ProductDetail.id == detail_id)
        .first()
    )


@router.post("/colors", response_model=ColorOut, status_code=status.HTTP_201_CREATED)
def create_color(
    color_in: ColorCreate,
    use_case: CreateColorUseCase = Depends(create_color_use_case),
    current_admin: User = Depends(require_admin),
):
    entity = use_case.execute(name=color_in.name, hexcode=color_in.hexcode)
    return ColorOut(id=entity.id, name=entity.name, hexcode=entity.hexcode)


@router.get("/colors", response_model=List[ColorOut])
def get_all_colors(
    use_case: GetColorsUseCase = Depends(get_colors_use_case),
):
    entities = use_case.execute()
    return [ColorOut(id=e.id, name=e.name, hexcode=e.hexcode) for e in entities]


@router.post("/sizes", response_model=SizeOut, status_code=status.HTTP_201_CREATED)
def create_size(
    size_in: SizeCreate,
    use_case: CreateSizeUseCase = Depends(create_size_use_case),
    current_admin: User = Depends(require_admin),
):
    entity = use_case.execute(size=size_in.size)
    return SizeOut(id=entity.id, size=entity.size)


@router.get("/sizes", response_model=List[SizeOut])
def get_all_sizes(
    use_case: GetSizesUseCase = Depends(get_sizes_use_case),
):
    entities = use_case.execute()
    return [SizeOut(id=e.id, size=e.size) for e in entities]


@router.put("/sizes/{size_id}", response_model=SizeOut)
def update_size(
    size_id: int,
    size_in: SizeUpdate,
    use_case: UpdateSizeUseCase = Depends(update_size_use_case),
    current_admin: User = Depends(require_admin),
):
    entity = use_case.execute(id=size_id, size=size_in.size)
    return SizeOut(id=entity.id, size=entity.size)


@router.delete("/sizes/{size_id}", status_code=status.HTTP_200_OK)
def delete_size(
    size_id: int,
    use_case: DeleteSizeUseCase = Depends(delete_size_use_case),
    current_admin: User = Depends(require_admin),
):
    use_case.execute(id=size_id)
    return {"message": "Đã xóa size thành công"}


@router.post("/{product_id}", response_model=ProductDetailOut)
def add_product_detail(
    product_id: int,
    product_detail_in: ProductDetailCreate,
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
    use_case: CreateProductDetailUseCase = Depends(get_create_product_detail_use_case),
):
    entity = use_case.execute(product_id=product_id, data=product_detail_in)
    model = _get_detail_model(db, entity.id)
    if not model:
        from fastapi import HTTPException
        raise HTTPException(status_code=500, detail="Lỗi tạo biến thể sản phẩm")
    return model


@router.put("/{product_detail_id}", response_model=ProductDetailOut)
def update_product_detail(
    product_detail_id: int,
    product_detail_in: ProductDetailUpdate,
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
    use_case: UpdateProductDetailUseCase = Depends(get_update_product_detail_use_case),
):
    data = product_detail_in.model_dump(exclude_unset=True)
    use_case.execute(detail_id=product_detail_id, data=data)
    model = _get_detail_model(db, product_detail_id)
    return model


@router.delete("/{product_detail_id}", status_code=status.HTTP_200_OK)
def delete_product_detail(
    product_detail_id: int,
    current_admin: User = Depends(require_admin),
    use_case: DeleteProductDetailUseCase = Depends(get_delete_product_detail_use_case),
):
    return use_case.execute(detail_id=product_detail_id)
