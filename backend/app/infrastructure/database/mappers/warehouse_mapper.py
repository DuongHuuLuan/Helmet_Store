from app.domain.entities.warehouse_entity import WarehouseEntity, WarehouseDetailEntity


class WarehouseMapper:
    @staticmethod
    def to_entity(model) -> WarehouseEntity:
        return WarehouseEntity(
            id=model.id,
            address=model.address,
            capacity=model.capacity,
            created_at=model.created_at,
            updated_at=model.updated_at,
        )


class WarehouseDetailMapper:
    @staticmethod
    def to_entity(model) -> WarehouseDetailEntity:
        return WarehouseDetailEntity(
            id=model.id,
            warehouse_id=model.warehouse_id,
            product_id=model.product_id,
            color_id=model.color_id,
            size_id=model.size_id,
            quantity=model.quantity,
        )
