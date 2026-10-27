"""Authenticated owner dietary history statistics."""

from datetime import date, datetime
from typing import Annotated
from zoneinfo import ZoneInfo

from fastapi import APIRouter, Query

from gramtree.accounts.deps import CurrentAuth
from gramtree.core.errors import ERROR_RESPONSES
from gramtree.deps import RedisDep, SessionDep
from gramtree.dietary_history import cache
from gramtree.dietary_history.schemas import DietaryPeriod, DietaryStatisticsOut
from gramtree.dietary_history.service import period_bounds, statistics

router = APIRouter(prefix="/dietary-history", tags=["dietary-history"])


@router.get(
    "/statistics",
    response_model=DietaryStatisticsOut,
    responses=ERROR_RESPONSES,
    operation_id="getDietaryStatistics",
)
def get_dietary_statistics(
    auth: CurrentAuth,
    session: SessionDep,
    redis: RedisDep,
    period: Annotated[DietaryPeriod, Query()] = "month",
    anchor: Annotated[
        date | None, Query(description="Account-local date; defaults to today")
    ] = None,
) -> DietaryStatisticsOut:
    local_anchor = anchor or datetime.now(ZoneInfo(auth.user.timezone)).date()
    bounds = period_bounds(period, local_anchor, auth.user.timezone)
    key = cache.cache_key(session, auth.user.id, period, bounds)
    cached = cache.get(redis, key)
    if cached is not None:
        return cached
    result = statistics(session, auth.user, period, local_anchor)
    cache.set_(redis, key, result)
    return result
