from pydantic import BaseModel


class DashboardSummaryOut(BaseModel):
    orders_today: int
    revenue_today: float
    total_users: int
    total_products: int

class DashboardActivityItemOut(BaseModel):
    title: str
    meta: str
    tag: str
    tone: str