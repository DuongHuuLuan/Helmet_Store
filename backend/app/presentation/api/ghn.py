from fastapi import APIRouter, Depends, HTTPException

from app.presentation.api.deps import require_user
from app.domain.entities.user_entity import UserEntity as User
from app.application.dto.ghn_dto import GhnFeeRequest, GhnFeeOut, GhnCreateOrderRequest, GhnShipmentOut
from app.shared.dependencies import get_ghn_service
from app.infrastructure.external.ghn.service import GhnService

router = APIRouter(prefix="/ghn", tags=["GHN"])


@router.post("/fee", response_model=GhnFeeOut)
def calculate_fee(
    payload: GhnFeeRequest,
    current_user: User = Depends(require_user),
    ghn_service: GhnService = Depends(get_ghn_service),
):
    result = ghn_service.calculate_fee(
        order_id=payload.order_id,
        to_district_id=payload.to_district_id,
        to_ward_code=payload.to_ward_code,
        service_id=payload.service_id,
        service_type_id=payload.service_type_id,
        insurance_value=payload.insurance_value,
    )
    return {
        "total": result["total"],
        "service_fee": result["service_fee"],
        "insurance_fee": result["insurance_fee"],
    }


@router.post("/create-order", response_model=GhnShipmentOut)
def create_ghn_order(
    payload: GhnCreateOrderRequest,
    current_user: User = Depends(require_user),
    ghn_service: GhnService = Depends(get_ghn_service),
):
    shipment = ghn_service.create_order(
        order_id=payload.order_id,
        to_district_id=payload.to_district_id,
        to_ward_code=payload.to_ward_code,
        service_id=payload.service_id,
        service_type_id=payload.service_type_id,
        note=payload.note,
        required_note=payload.required_note,
        cod_amount=payload.cod_amount,
        insurance_value=payload.insurance_value,
    )
    return shipment


@router.get("/order/{order_id}", response_model=GhnShipmentOut)
def get_ghn_status(
    order_id: int,
    current_user: User = Depends(require_user),
    ghn_service: GhnService = Depends(get_ghn_service),
):
    return ghn_service.get_shipment_status(order_id, current_user.id)


@router.post("/webhook")
def ghn_webhook(
    payload: dict,
    ghn_service: GhnService = Depends(get_ghn_service),
):
    return ghn_service.handle_webhook(payload)


@router.get("/provinces")
def list_provinces(current_user: User = Depends(require_user)):
    return GhnService.get_provinces()


@router.get("/districts/{province_id}")
def list_districts(province_id: int, current_user: User = Depends(require_user)):
    return GhnService.get_districts(province_id)


@router.get("/wards/{district_id}")
def list_wards(district_id: int, current_user: User = Depends(require_user)):
    return GhnService.get_wards(district_id)


@router.get("/services")
def list_services(to_district_id: int, current_user: User = Depends(require_user)):
    return GhnService.get_services(to_district_id)
