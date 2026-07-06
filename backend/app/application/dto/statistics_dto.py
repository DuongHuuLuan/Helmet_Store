from enum import Enum
from typing import List

from pydantic import BaseModel


class StatisticsRange(str, Enum):
    LAST_7_DAYS = "7d"
    LAST_30_DAYS = "30d"
    MONTH = "month"
    QUARTER = "quarter"


class StatisticsScope(str, Enum):
    OVERVIEW = "overview"
    SALES = "sales"
    REVIEWS = "reviews"


class StatisticsOrderStatus(str, Enum):
    ALL = "all"
    PENDING = "pending"
    SHIPPING = "shipping"
    COMPLETED = "completed"
    CANCELLED = "cancelled"


class StatisticsFilterParams(BaseModel):
    range: StatisticsRange = StatisticsRange.LAST_30_DAYS
    order_status: StatisticsOrderStatus = StatisticsOrderStatus.ALL
    scope: StatisticsScope = StatisticsScope.OVERVIEW


class StatisticsOverviewOut(BaseModel):
    revenue: float
    orders: int
    average_order_value: float
    completion_rate: int
    pending_orders: int
    pending_reviews: int


class StatisticsRevenuePointOut(BaseModel):
    label: str
    value: float


class StatisticsRevenueSeriesOut(BaseModel):
    items: List[StatisticsRevenuePointOut]


class StatisticsOrderMixItemOut(BaseModel):
    status: str
    label: str
    count: int
    share: int


class StatisticsOrderMixOut(BaseModel):
    items: List[StatisticsOrderMixItemOut]


class StatisticsPaymentMixItemOut(BaseModel):
    method: str
    label: str
    count: int
    revenue: float
    share: int


class StatisticsPaymentMixOut(BaseModel):
    items: List[StatisticsPaymentMixItemOut]


class StatisticsTopProductItemOut(BaseModel):
    name: str
    category: str
    sold: int
    revenue: float
    note: str = ""


class StatisticsTopProductsOut(BaseModel):
    items: List[StatisticsTopProductItemOut]


class StatisticsReviewRateItemOut(BaseModel):
    rate: int
    count: int
    share: int


class StatisticsReviewsSummaryOut(BaseModel):
    total_reviews: int
    average_rating: float
    pending_replies: int
    items: List[StatisticsReviewRateItemOut]


class StatisticsAlertItemOut(BaseModel):
    title: str
    text: str
    action: str
    to: str


class StatisticsAlertsOut(BaseModel):
    items: List[StatisticsAlertItemOut]
