from app.domain.entities.color_entity import ColorEntity
from app.infrastructure.database.models.color import Color


class ColorMapper:
    @staticmethod
    def to_entity(model: Color) -> ColorEntity:
        return ColorEntity(
            id=model.id,
            name=model.name,
            hexcode=model.hexcode,
        )

    @staticmethod
    def to_model(entity: ColorEntity) -> Color:
        return Color(
            id=entity.id,
            name=entity.name,
            hexcode=entity.hexcode,
        )
