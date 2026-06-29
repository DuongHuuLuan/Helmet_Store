from dataclasses import dataclass
from datetime import datetime
from decimal import Decimal
from typing import Optional


@dataclass
class VnPayTransactionEntity:
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
    created_at: Optional[datetime] = None
