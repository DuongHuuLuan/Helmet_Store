from fastapi import APIRouter, Depends, File, HTTPException, Request, UploadFile, status
from typing import List, Optional
from pydantic import ValidationError

import cloudinary.uploader
from app.presentation.api.utils import (
    extract_replace_images_map,
    extract_view_image_key_map,
    extract_uploads,
    is_upload_file,
    normalize_view_image_key,
    parse_int,
    parse_int_list,
    upload_images_to_cloudinary,
)
from app.application.dto.product_dto import ProductCreate, ProductOut, ProductPaginationOut
from app.domain.entities.user_entity import UserEntity as User
from app.presentation.api.deps import require_admin, require_user
from app.shared.dependencies import (
    get_product_by_id_use_case,
    get_products_use_case,
    get_create_product_use_case,
    get_update_product_use_case,
    get_delete_product_use_case,
    get_ensure_delete_use_case,
    get_add_images_use_case,
    get_delete_all_images_use_case,
    get_delete_image_use_case,
    get_replace_image_use_case,
    get_update_view_image_key_use_case,
    CreateProductUseCase,
    GetProductByIdUseCase,
    GetProductsUseCase,
    UpdateProductUseCase,
    DeleteProductUseCase,
    EnsureDeleteUseCase,
    AddImagesUseCase,
    DeleteAllImagesUseCase,
    DeleteImageUseCase,
    ReplaceImageUseCase,
    UpdateViewImageKeyUseCase,
)

router = APIRouter(prefix="/products", tags=["Products"])


def _parse_form_product_fields(form):
    def _get_str(key):
        value = form.get(key)
        if is_upload_file(value):
            return None
        if value is None:
            return None
        value = str(value).strip()
        return value or None

    description = _get_str("description") or _get_str("des")
    return {
        "name": _get_str("name"),
        "description": description,
        "unit": _get_str("unit"),
        "category_id": parse_int(_get_str("category_id")),
    }


async def _update_product_from_request(
    product_id: int,
    request: Request,
    get_product_uc: GetProductByIdUseCase,
    update_uc: UpdateProductUseCase,
    delete_all_images_uc: DeleteAllImagesUseCase,
    add_images_uc: AddImagesUseCase,
    delete_image_uc: DeleteImageUseCase,
    replace_image_uc: ReplaceImageUseCase,
    update_view_key_uc: UpdateViewImageKeyUseCase = None,
):
    from app.application.dto.product_dto import ProductCreate
    content_type = request.headers.get("content-type", "")
    if "multipart/form-data" in content_type or "application/x-www-form-urlencoded" in content_type:
        form = await request.form()
        payload = _parse_form_product_fields(form)
        existing = get_product_uc.execute(product_id)

        if not payload.get("name"):
            payload["name"] = existing["name"]
        if payload.get("description") is None:
            payload["description"] = existing.get("description")
        if not payload.get("unit"):
            payload["unit"] = existing["unit"]
        if payload.get("category_id") is None:
            payload["category_id"] = existing["category_id"]

        try:
            product_in = ProductCreate(**payload)
        except ValidationError as exc:
            raise HTTPException(status_code=422, detail=exc.errors())

        update_uc.execute(product_id, product_in.model_dump(exclude={"images", "product_details"}))

        replace_images = extract_replace_images_map(form)
        view_image_key_updates = extract_view_image_key_map(form)
        remove_ids = parse_int_list(form.getlist("remove_image_ids[]"))
        if replace_images:
            replace_ids = set(replace_images.keys())
            remove_ids = [image_id for image_id in remove_ids if image_id not in replace_ids]

        for image_id in remove_ids:
            delete_image_uc.execute(image_id)

        for image_id, file in replace_images.items():
            replace_image_uc.execute(image_id, file, product_id=product_id)

        if update_view_key_uc:
            for image_id, view_image_key in view_image_key_updates.items():
                if image_id in remove_ids:
                    continue
                update_view_key_uc.execute(image_id, view_image_key, product_id=product_id)

        new_files = extract_uploads(form.getlist("images[]"))
        color_ids = [parse_int(value) for value in form.getlist("image_color_ids[]")]
        view_image_keys = [
            normalize_view_image_key(value)
            for value in form.getlist("new_view_image_keys[]")
        ]
        uploaded = upload_images_to_cloudinary(new_files, color_ids, view_image_keys)
        if uploaded:
            add_images_uc.execute(product_id=product_id, images=uploaded)

        return get_product_uc.execute(product_id)

    data = await request.json()
    try:
        product_in = ProductCreate(**data)
    except ValidationError as exc:
        raise HTTPException(status_code=422, detail=exc.errors())

    update_uc.execute(product_id, product_in.model_dump(exclude={"images", "product_details"}))

    if product_in.images is not None:
        delete_all_images_uc.execute(product_id)
        add_images_uc.execute(
            product_id=product_id,
            images=[img.model_dump() for img in product_in.images],
        )

    return get_product_uc.execute(product_id)


@router.get("/", response_model=ProductPaginationOut)
def get_all_product(
    page: int = 1,
    per_page: Optional[int] = None,
    q: str = None,
    use_case: GetProductsUseCase = Depends(get_products_use_case),
):
    return use_case.execute(page=page, per_page=per_page, keyword=q)


@router.get("/category/{category_id}", response_model=ProductPaginationOut)
def get_product_category(
    category_id: int,
    page: int = 1,
    per_page: Optional[int] = None,
    q: str = None,
    use_case: GetProductsUseCase = Depends(get_products_use_case),
):
    return use_case.execute(
        page=page, per_page=per_page, keyword=q, category_id=category_id,
    )


@router.post("/", response_model=ProductOut, status_code=status.HTTP_201_CREATED)
async def create_product(
    request: Request,
    current_admin: User = Depends(require_admin),
    create_uc: CreateProductUseCase = Depends(get_create_product_use_case),
    get_uc: GetProductByIdUseCase = Depends(get_product_by_id_use_case),
    add_images_uc: AddImagesUseCase = Depends(get_add_images_use_case),
):
    content_type = request.headers.get("content-type", "")
    if "multipart/form-data" in content_type or "application/x-www-form-urlencoded" in content_type:
        form = await request.form()
        payload = _parse_form_product_fields(form)

        if not payload.get("name") or not payload.get("unit") or payload.get("category_id") is None:
            raise HTTPException(status_code=422, detail="Missing required fields")

        try:
            product_in = ProductCreate(**payload)
        except ValidationError as exc:
            raise HTTPException(status_code=422, detail=exc.errors())

        entity = create_uc.execute(product_in)

        files = extract_uploads(form.getlist("images[]"))
        color_ids = [parse_int(value) for value in form.getlist("image_color_ids[]")]
        view_image_keys = [
            normalize_view_image_key(value)
            for value in form.getlist("new_view_image_keys[]")
        ]
        uploaded = upload_images_to_cloudinary(files, color_ids, view_image_keys)
        if uploaded:
            add_images_uc.execute(product_id=entity.id, images=uploaded)

        return get_uc.execute(entity.id)

    data = await request.json()
    try:
        product_in = ProductCreate(**data)
    except ValidationError as exc:
        raise HTTPException(status_code=422, detail=exc.errors())

    entity = create_uc.execute(product_in)
    if product_in.images:
        add_images_uc.execute(
            product_id=entity.id,
            images=[img.model_dump() for img in product_in.images],
        )

    return get_uc.execute(entity.id)


@router.get("/{product_id}", response_model=ProductOut)
def get_product(
    product_id: int,
    use_case: GetProductByIdUseCase = Depends(get_product_by_id_use_case),
):
    return use_case.execute(product_id)


@router.put("/{product_id}", response_model=ProductOut)
async def update_product(
    product_id: int,
    request: Request,
    current_admin: User = Depends(require_admin),
    get_uc: GetProductByIdUseCase = Depends(get_product_by_id_use_case),
    update_uc: UpdateProductUseCase = Depends(get_update_product_use_case),
    delete_all_images_uc: DeleteAllImagesUseCase = Depends(get_delete_all_images_use_case),
    add_images_uc: AddImagesUseCase = Depends(get_add_images_use_case),
    delete_image_uc: DeleteImageUseCase = Depends(get_delete_image_use_case),
    replace_image_uc: ReplaceImageUseCase = Depends(get_replace_image_use_case),
    update_view_key_uc: UpdateViewImageKeyUseCase = Depends(get_update_view_image_key_use_case),
):
    return await _update_product_from_request(
        product_id, request,
        get_uc, update_uc, delete_all_images_uc, add_images_uc,
        delete_image_uc, replace_image_uc, update_view_key_uc,
    )


@router.post("/{product_id}", response_model=ProductOut)
async def update_product_post(
    product_id: int,
    request: Request,
    current_admin: User = Depends(require_admin),
    get_uc: GetProductByIdUseCase = Depends(get_product_by_id_use_case),
    update_uc: UpdateProductUseCase = Depends(get_update_product_use_case),
    delete_all_images_uc: DeleteAllImagesUseCase = Depends(get_delete_all_images_use_case),
    add_images_uc: AddImagesUseCase = Depends(get_add_images_use_case),
    delete_image_uc: DeleteImageUseCase = Depends(get_delete_image_use_case),
    replace_image_uc: ReplaceImageUseCase = Depends(get_replace_image_use_case),
    update_view_key_uc: UpdateViewImageKeyUseCase = Depends(get_update_view_image_key_use_case),
):
    return await _update_product_from_request(
        product_id, request,
        get_uc, update_uc, delete_all_images_uc, add_images_uc,
        delete_image_uc, replace_image_uc, update_view_key_uc,
    )


@router.delete("/{product_id}", status_code=status.HTTP_200_OK)
def delete_product(
    product_id: int,
    current_admin: User = Depends(require_admin),
    ensure_uc: EnsureDeleteUseCase = Depends(get_ensure_delete_use_case),
    delete_all_images_uc: DeleteAllImagesUseCase = Depends(get_delete_all_images_use_case),
    delete_uc: DeleteProductUseCase = Depends(get_delete_product_use_case),
):
    ensure_uc.execute(product_id)
    delete_all_images_uc.execute(product_id)
    result = delete_uc.execute(product_id, skip_validate=True)
    return result


@router.post("/{product_id}/images")
def upload_product_images(
    product_id: int,
    files: List[UploadFile] = File(...),
    current_admin: User = Depends(require_admin),
    add_images_uc: AddImagesUseCase = Depends(get_add_images_use_case),
):
    if not files:
        raise HTTPException(status_code=400, detail="Không có file nào")

    uploaded = []
    for f in files:
        r = cloudinary.uploader.upload(f.file, folder="helmet_shop/products")
        uploaded.append({"url": r["secure_url"], "public_id": r["public_id"]})

    entities = add_images_uc.execute(product_id, uploaded)

    return {
        "count": len(entities),
        "items": [
            {"id": e.id, "url": e.url, "public_id": e.public_id}
            for e in entities
        ],
    }
