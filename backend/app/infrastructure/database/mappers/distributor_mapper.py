from app.domain.entities.distributor_entity import DistributorEntity


class DistributorMapper:
    @staticmethod
    def to_entity(model) -> DistributorEntity:
        return DistributorEntity(
            id=model.id,
            name=model.name,
            email=model.email,
            address=model.address,
        )
