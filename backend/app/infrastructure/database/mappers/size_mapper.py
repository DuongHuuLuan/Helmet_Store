from app.domain.entities.size_entity import SizeEntity
from app.infrastructure.database.models.size import Size


class SizeMapper:
    @staticmethod
    def to_entity(model: Size) -> SizeEntity:
        return SizeEntity(
            id=model.id,
            size=model.size,
        )

    @staticmethod
    def to_model(entity: SizeEntity) -> Size:
        return Size(
            id=entity.id,
            size=entity.size,
        )
