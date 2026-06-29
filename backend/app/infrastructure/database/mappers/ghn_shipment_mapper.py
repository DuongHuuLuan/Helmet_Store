from app.domain.entities.ghn_shipment_entity import GhnShipmentEntity


class GhnShipmentMapper:
    @staticmethod
    def to_entity(model) -> GhnShipmentEntity:
        return GhnShipmentEntity(
            id=model.id,
            order_id=model.order_id,
            ghn_order_code=model.ghn_order_code,
            status=model.status,
            service_id=model.service_id,
            service_type_id=model.service_type_id,
            from_name=model.from_name,
            from_phone=model.from_phone,
            from_address=model.from_address,
            from_ward_code=model.from_ward_code,
            from_district_id=model.from_district_id,
            to_name=model.to_name,
            to_phone=model.to_phone,
            to_address=model.to_address,
            to_ward_code=model.to_ward_code,
            to_district_id=model.to_district_id,
            weight=model.weight,
            length=model.length,
            width=model.width,
            height=model.height,
            cod_amount=model.cod_amount,
            insurance_value=model.insurance_value,
            shipping_fee=model.shipping_fee,
            expected_delivery_time=model.expected_delivery_time,
            leadtime=model.leadtime,
            tracking_url=model.tracking_url,
            note=model.note,
            raw_request=model.raw_request,
            raw_response=model.raw_response,
            created_at=model.created_at,
            updated_at=model.updated_at,
        )
