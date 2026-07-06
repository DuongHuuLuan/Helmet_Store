from typing import Optional

from sqlalchemy.orm import Session, selectinload
from sqlalchemy import or_

from app.infrastructure.database.mappers.design_mapper import DesignMapper
from app.domain.entities.design_entity import DesignEntity
from app.domain.repositories.design_repository import DesignRepository
from app.infrastructure.database.models.design import Design
from app.infrastructure.database.models.design_layer import DesignLayer
from app.infrastructure.database.models.design_share import DesignShare
from app.infrastructure.database.models.sticker import Sticker


class DesignRepositoryImpl(DesignRepository):
    def __init__(self, db: Session):
        self.db = db

    def _query(self):
        return self.db.query(Design).options(
            selectinload(Design.layers),
            selectinload(Design.shares),
        )

    def get_by_id(self, id: int) -> Optional[DesignEntity]:
        model = self._query().filter(Design.id == id).first()
        if not model:
            return None
        return DesignMapper.to_entity(model)

    def get_by_user_id(self, user_id: int) -> list[DesignEntity]:
        models = (
            self._query()
            .filter(Design.user_id == user_id)
            .order_by(Design.created_at.desc(), Design.id.desc())
            .all()
        )
        return [DesignMapper.to_entity(m) for m in models]

    def create(self, data: dict) -> DesignEntity:
        model = Design(**data)
        self.db.add(model)
        self.db.flush()
        self.db.refresh(model)
        return DesignMapper.to_entity(model)

    def update(self, id: int, data: dict) -> DesignEntity:
        model = self._query().filter(Design.id == id).first()
        if not model:
            return None

        layers_data = data.pop("layers", None)

        for key, value in data.items():
            setattr(model, key, value)

        if layers_data is not None:
            for existing_layer in list(model.layers):
                self.db.delete(existing_layer)
            self.db.flush()

            for layer_data in layers_data:
                self.db.add(DesignLayer(design_id=model.id, **layer_data))

        self.db.flush()
        return DesignMapper.to_entity(model)

    def validate_stickers(self, sticker_ids: list[int], user_id: int) -> tuple[list, list[int]]:
        normalized_ids = list(dict.fromkeys(sticker_ids))
        stickers = (
            self.db.query(Sticker)
            .filter(Sticker.id.in_(normalized_ids))
            .filter(
                or_(
                    Sticker.owner_user_id.is_(None),
                    Sticker.owner_user_id == user_id,
                )
            )
            .all()
        )
        found_ids = {s.id for s in stickers}
        missing = [sid for sid in normalized_ids if sid not in found_ids]
        return stickers, missing

    def create_with_layers(self, user_id: int, design_data: dict, layers_data: list[dict]) -> dict:
        design = Design(user_id=user_id, **design_data)
        self.db.add(design)
        self.db.flush()

        for layer_data in layers_data:
            self.db.add(DesignLayer(design_id=design.id, **layer_data))

        self.db.flush()
        return self.get_by_id_with_details(design.id)

    def get_by_id_with_details(self, id: int) -> Optional[dict]:
        model = self._query().filter(Design.id == id).first()
        if not model:
            return None
        return self._model_to_dict(model)

    def get_by_user_id_with_details(self, user_id: int) -> list[dict]:
        models = (
            self._query()
            .filter(Design.user_id == user_id)
            .order_by(Design.created_at.desc(), Design.id.desc())
            .all()
        )
        return [self._model_to_dict(m) for m in models]

    def create_share_link(self, design_id: int, share_data: dict) -> dict:
        share = DesignShare(design_id=design_id, **share_data)
        self.db.add(share)
        self.db.flush()
        return {"share_url": share_data["public_url"]}

    def _model_to_dict(self, model: Design) -> dict:
        return {
            "id": model.id,
            "user_id": model.user_id,
            "product_id": model.product_id,
            "product_detail_id": model.product_detail_id,
            "name": model.name,
            "base_image_url": model.base_image_url,
            "preview_image_url": model.preview_image_url,
            "is_shared": model.is_shared,
            "created_at": model.created_at.isoformat() if model.created_at else None,
            "updated_at": model.updated_at.isoformat() if model.updated_at else None,
            "layers": [
                {
                    "id": layer.id,
                    "design_id": layer.design_id,
                    "sticker_id": layer.sticker_id,
                    "image_url": layer.image_url,
                    "x": layer.x,
                    "y": layer.y,
                    "scale": layer.scale,
                    "rotation": layer.rotation,
                    "z_index": layer.z_index,
                    "view_image_key": layer.view_image_key,
                    "tint_color_value": layer.tint_color_value,
                    "crop_left": layer.crop_left,
                    "crop_top": layer.crop_top,
                    "crop_right": layer.crop_right,
                    "crop_bottom": layer.crop_bottom,
                }
                for layer in (model.layers or [])
            ],
            "shares": [
                {
                    "id": share.id,
                    "design_id": share.design_id,
                    "share_token": share.share_token,
                    "public_url": share.public_url,
                    "created_at": share.created_at.isoformat() if share.created_at else None,
                    "expires_at": share.expires_at.isoformat() if share.expires_at else None,
                }
                for share in (model.shares or [])
            ],
        }
