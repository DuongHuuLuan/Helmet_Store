from abc import ABC, abstractmethod

from app.application.dto.statistics_dto import StatisticsFilterParams


class StatisticsRepository(ABC):
    @abstractmethod
    def get_overview(self, filters: StatisticsFilterParams) -> dict: ...

    @abstractmethod
    def get_revenue_series(self, filters: StatisticsFilterParams) -> dict: ...

    @abstractmethod
    def get_order_mix(self, filters: StatisticsFilterParams) -> dict: ...

    @abstractmethod
    def get_top_products(self, filters: StatisticsFilterParams) -> dict: ...

    @abstractmethod
    def get_payment_mix(self, filters: StatisticsFilterParams) -> dict: ...

    @abstractmethod
    def get_reviews_summary(self, filters: StatisticsFilterParams) -> dict: ...

    @abstractmethod
    def get_alerts(self, filters: StatisticsFilterParams) -> dict: ...
