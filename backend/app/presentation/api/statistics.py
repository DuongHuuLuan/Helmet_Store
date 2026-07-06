from fastapi import APIRouter, Depends, Query
from fastapi.responses import Response

from app.presentation.api.deps import require_admin
from app.domain.entities.user_entity import UserEntity as User
from app.application.dto.statistics_dto import (
    StatisticsAlertsOut,
    StatisticsFilterParams,
    StatisticsOrderMixOut,
    StatisticsOrderStatus,
    StatisticsOverviewOut,
    StatisticsPaymentMixOut,
    StatisticsRange,
    StatisticsRevenueSeriesOut,
    StatisticsReviewsSummaryOut,
    StatisticsScope,
    StatisticsTopProductsOut,
)
from app.application.use_case.statistics.get_statistics_overview_usecase import GetStatisticsOverviewUseCase
from app.application.use_case.statistics.get_statistics_revenue_series_usecase import GetStatisticsRevenueSeriesUseCase
from app.application.use_case.statistics.get_statistics_order_mix_usecase import GetStatisticsOrderMixUseCase
from app.application.use_case.statistics.get_statistics_top_products_usecase import GetStatisticsTopProductsUseCase
from app.application.use_case.statistics.get_statistics_payment_mix_usecase import GetStatisticsPaymentMixUseCase
from app.application.use_case.statistics.get_statistics_reviews_summary_usecase import GetStatisticsReviewsSummaryUseCase
from app.application.use_case.statistics.get_statistics_alerts_usecase import GetStatisticsAlertsUseCase
from app.application.use_case.statistics.export_statistics_pdf_usecase import ExportStatisticsPdfUseCase
from app.shared.dependencies import (
    get_statistics_overview_use_case,
    get_statistics_revenue_series_use_case,
    get_statistics_order_mix_use_case,
    get_statistics_top_products_use_case,
    get_statistics_payment_mix_use_case,
    get_statistics_reviews_summary_use_case,
    get_statistics_alerts_use_case,
    export_statistics_pdf_use_case,
)

router = APIRouter(prefix="/statistics", tags=["Statistics"])


def get_statistics_filters(
    range: StatisticsRange = Query(StatisticsRange.LAST_30_DAYS),
    order_status: StatisticsOrderStatus = Query(StatisticsOrderStatus.ALL),
    scope: StatisticsScope = Query(StatisticsScope.OVERVIEW),
) -> StatisticsFilterParams:
    return StatisticsFilterParams(
        range=range,
        order_status=order_status,
        scope=scope,
    )


@router.get("/overview", response_model=StatisticsOverviewOut)
def get_overview(
    filters: StatisticsFilterParams = Depends(get_statistics_filters),
    use_case: GetStatisticsOverviewUseCase = Depends(get_statistics_overview_use_case),
    current_admin: User = Depends(require_admin),
):
    return use_case.execute(filters)


@router.get("/revenue-series", response_model=StatisticsRevenueSeriesOut)
def get_revenue_series(
    filters: StatisticsFilterParams = Depends(get_statistics_filters),
    use_case: GetStatisticsRevenueSeriesUseCase = Depends(get_statistics_revenue_series_use_case),
    current_admin: User = Depends(require_admin),
):
    return use_case.execute(filters)


@router.get("/order-mix", response_model=StatisticsOrderMixOut)
def get_order_mix(
    filters: StatisticsFilterParams = Depends(get_statistics_filters),
    use_case: GetStatisticsOrderMixUseCase = Depends(get_statistics_order_mix_use_case),
    current_admin: User = Depends(require_admin),
):
    return use_case.execute(filters)


@router.get("/top-products", response_model=StatisticsTopProductsOut)
def get_top_products(
    filters: StatisticsFilterParams = Depends(get_statistics_filters),
    use_case: GetStatisticsTopProductsUseCase = Depends(get_statistics_top_products_use_case),
    current_admin: User = Depends(require_admin),
):
    return use_case.execute(filters)


@router.get("/payment-mix", response_model=StatisticsPaymentMixOut)
def get_payment_mix(
    filters: StatisticsFilterParams = Depends(get_statistics_filters),
    use_case: GetStatisticsPaymentMixUseCase = Depends(get_statistics_payment_mix_use_case),
    current_admin: User = Depends(require_admin),
):
    return use_case.execute(filters)


@router.get("/reviews-summary", response_model=StatisticsReviewsSummaryOut)
def get_reviews_summary(
    filters: StatisticsFilterParams = Depends(get_statistics_filters),
    use_case: GetStatisticsReviewsSummaryUseCase = Depends(get_statistics_reviews_summary_use_case),
    current_admin: User = Depends(require_admin),
):
    return use_case.execute(filters)


@router.get("/alerts", response_model=StatisticsAlertsOut)
def get_alerts(
    filters: StatisticsFilterParams = Depends(get_statistics_filters),
    use_case: GetStatisticsAlertsUseCase = Depends(get_statistics_alerts_use_case),
    current_admin: User = Depends(require_admin),
):
    return use_case.execute(filters)


@router.get("/export/pdf")
def export_statistics_pdf(
    filters: StatisticsFilterParams = Depends(get_statistics_filters),
    use_case: ExportStatisticsPdfUseCase = Depends(export_statistics_pdf_use_case),
    current_admin: User = Depends(require_admin),
):
    pdf_bytes, filename = use_case.execute(filters)
    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )
