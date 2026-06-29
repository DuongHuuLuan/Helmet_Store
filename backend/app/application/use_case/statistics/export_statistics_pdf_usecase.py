from app.application.dto.statistics_dto import StatisticsFilterParams
from app.application.statistics.export_service import StatisticsExportService
from app.domain.repositories.statistics_repository import StatisticsRepository


class ExportStatisticsPdfUseCase:
    def __init__(self, repo: StatisticsRepository):
        self._repo = repo

    def execute(self, filters: StatisticsFilterParams) -> tuple[bytes, str]:
        return StatisticsExportService.export_pdf(self._repo, filters)
