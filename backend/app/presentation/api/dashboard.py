from typing import List

from fastapi import APIRouter, Depends

from app.presentation.api.deps import require_admin
from app.domain.entities.user_entity import UserEntity as User
from app.application.dto.dashboard_dto import DashboardActivityItemOut, DashboardSummaryOut
from app.application.use_case.dashboard.get_dashboard_summary_usecase import GetDashboardSummaryUseCase
from app.application.use_case.dashboard.get_dashboard_activity_usecase import GetDashboardActivityUseCase
from app.shared.dependencies import get_dashboard_summary_use_case, get_dashboard_activity_use_case

router = APIRouter(prefix="/dashboard", tags=["Dashboard"])


@router.get("/summary", response_model=DashboardSummaryOut)
def get_summary(
    use_case: GetDashboardSummaryUseCase = Depends(get_dashboard_summary_use_case),
    current_admin: User = Depends(require_admin),
):
    return use_case.execute()


@router.get("/activity", response_model=List[DashboardActivityItemOut])
def get_activity(
    limit: int = 6,
    use_case: GetDashboardActivityUseCase = Depends(get_dashboard_activity_use_case),
    current_admin: User = Depends(require_admin),
):
    return use_case.execute(limit=limit)
