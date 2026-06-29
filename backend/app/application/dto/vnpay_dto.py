from decimal import Decimal
from pydantic import BaseModel
from typing import Optional


class VnpayCreateRequest(BaseModel):
    order_id: int
    bank_code: Optional[str] = None
    locale: Optional[str] = "vn"


class VnpayPaymentUrlOut(BaseModel):
    payment_url: str


class VnpayTransactionOut(BaseModel):
    id: int
    order_id: int
    txn_ref: str
    amount: Decimal
    response_code: Optional[str] = None
    status: Optional[str] = None
    transaction_no: Optional[str] = None
    bank_code: Optional[str] = None
    pay_date: Optional[str] = None
    message: Optional[str] = None

    class Config:
        from_attributes = True
