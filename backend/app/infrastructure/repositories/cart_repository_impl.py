from typing import Optional

from fastapi import HTTPException
from sqlalchemy.orm import Session, joinedload, selectinload
from sqlalchemy import func

from app.infrastructure.database.mappers.cart_mapper import CartMapper
from app.domain.entities.cart_entity import CartEntity, CartDetailEntity
from app.domain.repositories.cart_repository import CartRepository
from app.infrastructure.database.models.cart import Cart
from app.infrastructure.database.models.cart_detail import CartDetail
from app.infrastructure.database.models.product_detail import ProductDetail
from app.infrastructure.database.models.product import Product
from app.infrastructure.database.models.design import Design
from app.infrastructure.database.models.warehouse import WarehouseDetail
from app.infrastructure.database.models.image_url import ImageURL


class CartRepositoryImpl(CartRepository):
    def __init__(self, db: Session):
        self.db = db

    def get_or_create(self, user_id: int) -> CartEntity:
        cart = self.db.query(Cart).filter(Cart.user_id == user_id).first()
        if not cart:
            cart = Cart(user_id=user_id)
            self.db.add(cart)
            self.db.commit()
            self.db.refresh(cart)
        return CartMapper.to_entity(cart)

    def get_by_user_id(self, user_id: int) -> Optional[CartEntity]:
        cart = self.db.query(Cart).filter(Cart.user_id == user_id).first()
        if not cart:
            return None
        return CartMapper.to_entity(cart)

    def find_existing_detail(self, cart_id: int, product_detail_id: int,
                              design_id: Optional[int]) -> Optional[CartDetailEntity]:
        query = self.db.query(CartDetail).filter(
            CartDetail.cart_id == cart_id,
            CartDetail.product_detail_id == product_detail_id,
        )
        if design_id is None:
            query = query.filter(CartDetail.design_id.is_(None))
        else:
            query = query.filter(CartDetail.design_id == design_id)
        model = query.first()
        if not model:
            return None
        return CartDetailEntity(
            id=model.id, cart_id=model.cart_id,
            product_detail_id=model.product_detail_id,
            design_id=model.design_id, quantity=model.quantity,
        )

    def add_detail(self, cart_id: int, product_detail_id: int,
                    design_id: Optional[int], quantity: int) -> CartDetailEntity:
        model = CartDetail(
            cart_id=cart_id,
            product_detail_id=product_detail_id,
            design_id=design_id,
            quantity=quantity,
        )
        self.db.add(model)
        self.db.commit()
        self.db.refresh(model)
        return CartDetailEntity(
            id=model.id, cart_id=model.cart_id,
            product_detail_id=model.product_detail_id,
            design_id=model.design_id, quantity=model.quantity,
        )

    def update_detail_quantity(self, detail_id: int, quantity: int) -> None:
        self.db.query(CartDetail).filter(CartDetail.id == detail_id).update({"quantity": quantity})
        self.db.commit()

    def delete_detail(self, detail_id: int) -> None:
        model = self.db.query(CartDetail).filter(CartDetail.id == detail_id).first()
        if model:
            self.db.delete(model)
            self.db.commit()

    def get_detail_by_id(self, detail_id: int) -> Optional[CartDetailEntity]:
        model = self.db.query(CartDetail).filter(CartDetail.id == detail_id).first()
        if not model:
            return None
        return CartDetailEntity(
            id=model.id, cart_id=model.cart_id,
            product_detail_id=model.product_detail_id,
            design_id=model.design_id, quantity=model.quantity,
        )

    def get_product_detail_by_id(self, id: int) -> Optional[dict]:
        model = self.db.query(ProductDetail).filter(ProductDetail.id == id).first()
        if not model:
            return None
        return {
            "id": model.id, "product_id": model.product_id,
            "color_id": model.color_id, "size_id": model.size_id,
            "price": model.price, "is_active": model.is_active,
        }

    def get_design_by_id(self, id: int) -> Optional[dict]:
        model = self.db.query(Design).filter(Design.id == id).first()
        if not model:
            return None
        return {
            "id": model.id, "user_id": model.user_id,
            "product_id": model.product_id,
        }

    def get_cart_response(self, user_id: int) -> dict:
        cart = (
            self.db.query(Cart)
            .options(
                selectinload(Cart.cart_details)
                    .joinedload(CartDetail.product_detail)
                    .joinedload(ProductDetail.color),
                selectinload(Cart.cart_details)
                    .joinedload(CartDetail.product_detail)
                    .joinedload(ProductDetail.size),
                selectinload(Cart.cart_details)
                    .joinedload(CartDetail.product_detail)
                    .joinedload(ProductDetail.product)
                    .selectinload(Product.product_images),
                selectinload(Cart.cart_details).joinedload(CartDetail.design),
            )
            .filter(Cart.user_id == user_id)
            .first()
        )

        if not cart:
            cart = Cart(user_id=user_id)
            self.db.add(cart)
            self.db.commit()
            self.db.refresh(cart)
            return {
                "id": cart.id, "user_id": user_id,
                "cart_details": [], "total_price": 0,
                "can_checkout": True,
            }

        total = 0
        can_checkout = True
        details = []

        for cd in cart.cart_details:
            pd = cd.product_detail
            price = pd.price or 0
            total += price * cd.quantity

            product = getattr(pd, "product", None) if pd else None
            color_id = pd.color.id if getattr(pd, "color", None) else None

            image_url = self._pick_primary_image(
                list(product.product_images or []) if product else [],
                color_id,
            )

            design = getattr(cd, "design", None)
            stock = self._get_total_stock_for_product(pd)
            status_data = self._resolve_status(pd, stock, cd.quantity)

            detail = {
                "id": cd.id,
                "product_detail_id": cd.product_detail_id,
                "design_id": cd.design_id,
                "quantity": cd.quantity,
                "product_detail": {
                    "id": pd.id,
                    "color": {"id": pd.color.id, "name": pd.color.name, "hexcode": pd.color.hexcode} if getattr(pd, "color", None) else None,
                    "size": {"id": pd.size.id, "size": pd.size.size} if getattr(pd, "size", None) else None,
                    "price": pd.price,
                    "is_active": pd.is_active,
                } if pd else None,
                "product_id": product.id if product else 0,
                "product_name": product.name if product else "",
                "image_url": image_url,
                "design_name": getattr(design, "name", None),
                "design_preview_image_url": getattr(design, "preview_image_url", None),
                "is_active": status_data["is_active"],
                "available_stock": stock,
                "cart_status": status_data["cart_status"],
                "status_message": status_data["status_message"],
                "can_checkout": status_data["can_checkout"],
            }
            details.append(detail)
            if not detail["can_checkout"]:
                can_checkout = False

        return {
            "id": cart.id, "user_id": user_id,
            "cart_details": details,
            "total_price": float(total),
            "can_checkout": can_checkout,
        }

    def add_to_cart(self, user_id: int, product_detail_id: int,
                    design_id: Optional[int], quantity: int) -> dict:
        cart = self.db.query(Cart).filter(Cart.user_id == user_id).first()
        if not cart:
            cart = Cart(user_id=user_id)
            self.db.add(cart)
            self.db.commit()
            self.db.refresh(cart)

        product_detail = self.db.query(ProductDetail).filter(
            ProductDetail.id == product_detail_id
        ).first()
        if not product_detail:
            raise HTTPException(status_code=404, detail="Sản phẩm không tồn tại")
        if not product_detail.is_active:
            raise HTTPException(status_code=400, detail="Biến thể sản phẩm đã ngừng bán")

        normalized_design_id = None
        if design_id is not None and design_id > 0:
            design = self.db.query(Design).filter(Design.id == design_id).first()
            if not design:
                raise HTTPException(status_code=404, detail="Thiết kế không tồn tại")
            if design.user_id != user_id:
                raise HTTPException(status_code=403, detail="Bạn không có quyền dùng thiết kế này")
            if design.product_id != product_detail.product_id:
                raise HTTPException(
                    status_code=400,
                    detail="Thiết kế không thuộc biến thể sản phẩm đã chọn",
                )
            normalized_design_id = design.id

        stock = self._get_total_stock_for_product(product_detail)
        if stock < quantity:
            raise HTTPException(status_code=400, detail=f"Chỉ còn {stock} sản phẩm trong kho")

        existing = self.find_existing_detail(cart.id, product_detail_id, normalized_design_id)
        if existing:
            new_qty = existing.quantity + quantity
            if stock < new_qty:
                raise HTTPException(status_code=400, detail="Tổng số lượng vượt quá tồn kho")
            self.update_detail_quantity(existing.id, new_qty)
        else:
            self.add_detail(cart.id, product_detail_id, normalized_design_id, quantity)

        return self.get_cart_response(user_id)

    def update_cart_detail(self, user_id: int, cart_detail_id: int, new_quantity: int) -> dict:
        cart = self.db.query(Cart).filter(Cart.user_id == user_id).first()
        if not cart:
            raise HTTPException(status_code=404, detail="Giỏ hàng trống")

        detail = self.db.query(CartDetail).filter(
            CartDetail.id == cart_detail_id,
            CartDetail.cart_id == cart.id,
        ).first()
        if not detail:
            raise HTTPException(status_code=404, detail="Không tìm thấy món hàng trong giỏ")

        product_detail = detail.product_detail
        if not product_detail.is_active:
            raise HTTPException(
                status_code=400,
                detail="Sản phẩm trong giỏ đã ngừng bán, vui lòng xóa khỏi giỏ hàng",
            )

        stock = self._get_total_stock_for_product(product_detail)
        if stock < new_quantity:
            raise HTTPException(status_code=400, detail=f"Kho chỉ còn {stock} sản phẩm")

        self.update_detail_quantity(cart_detail_id, new_quantity)
        return self.get_cart_response(user_id)

    def delete_cart_detail(self, user_id: int, cart_detail_id: int) -> dict:
        cart = self.db.query(Cart).filter(Cart.user_id == user_id).first()
        if not cart:
            raise HTTPException(status_code=404, detail="Giỏ hàng trống")

        detail = self.db.query(CartDetail).filter(
            CartDetail.id == cart_detail_id,
            CartDetail.cart_id == cart.id,
        ).first()
        if not detail:
            raise HTTPException(status_code=404, detail="Không tìm thấy món hàng trong giỏ hàng")

        self.db.delete(detail)
        self.db.commit()
        return {"message": "Đã xóa sản phẩm khỏi giỏ hàng"}

    def _pick_primary_image(self, images: list, color_id: Optional[int] = None) -> Optional[str]:
        if not images:
            return None

        def _pick_from_bucket(bucket):
            if not bucket:
                return None
            front = next(
                (img for img in bucket if str(getattr(img, "view_image_key", "") or "").strip() == "front-left"),
                None,
            )
            if front:
                return getattr(front, "url", None)
            generic = next(
                (img for img in bucket if not str(getattr(img, "view_image_key", "") or "").strip()),
                None,
            )
            return getattr(generic or bucket[0], "url", None)

        by_color = [img for img in images if getattr(img, "color_id", None) == color_id]
        if by_color:
            return _pick_from_bucket(by_color)

        commons = [img for img in images if getattr(img, "color_id", None) is None]
        if commons:
            return _pick_from_bucket(commons)

        return _pick_from_bucket(images)

    def _get_total_stock_for_product(self, product_detail) -> int:
        if not product_detail:
            return 0
        result = (
            self.db.query(func.coalesce(func.sum(WarehouseDetail.quantity), 0))
            .filter(
                WarehouseDetail.product_id == product_detail.product_id,
                WarehouseDetail.size_id == product_detail.size_id,
                WarehouseDetail.color_id == product_detail.color_id,
            )
            .scalar()
        )
        return int(result)

    def _resolve_status(self, pd, stock, quantity):
        if not pd or not pd.is_active:
            return {"is_active": False, "cart_status": "inactive", "status_message": "Sản phẩm đã ngừng bán", "can_checkout": False}
        if stock <= 0:
            return {"is_active": True, "cart_status": "out_of_stock", "status_message": "Sản phẩm đã hết hàng", "can_checkout": False}
        if quantity > stock:
            return {"is_active": True, "cart_status": "insufficient_stock", "status_message": f"Chỉ còn {stock} sản phẩm trong kho", "can_checkout": False}
        return {"is_active": True, "cart_status": "ok", "status_message": None, "can_checkout": True}
