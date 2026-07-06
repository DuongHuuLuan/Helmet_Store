from app.application.dto.statistics_dto import StatisticsFilterParams
from app.domain.repositories.statistics_repository import StatisticsRepository


class GetStatisticsRevenueSeriesUseCase:
    def __init__(self, repo: StatisticsRepository):
        self._repo = repo

    def execute(self, filters: StatisticsFilterParams) -> dict:
        return self._repo.get_revenue_series(filters)
