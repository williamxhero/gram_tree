from typing import Literal

from fastapi import APIRouter, Request
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from sqlalchemy import text

from gramtree.deps import RedisDep, SessionDep

router = APIRouter(tags=["health"])

CheckStatus = Literal["ok", "fail"]


class HealthChecks(BaseModel):
    api: CheckStatus
    database: CheckStatus
    redis: CheckStatus


class HealthResponse(BaseModel):
    status: Literal["ok", "unhealthy"]
    checks: HealthChecks


@router.get(
    "/health",
    response_model=HealthResponse,
    responses={503: {"model": HealthResponse, "description": "有组件不可用"}},
    summary="健康检查：服务、数据库、Redis 是否可用",
)
def health(request: Request, session: SessionDep, redis: RedisDep) -> JSONResponse:
    database: CheckStatus = "ok"
    try:
        session.execute(text("SELECT 1"))
    except Exception:
        database = "fail"
    redis_status: CheckStatus = "ok"
    try:
        redis.ping()
    except Exception:
        redis_status = "fail"
    checks = HealthChecks(api="ok", database=database, redis=redis_status)
    healthy = database == "ok" and redis_status == "ok"
    body = HealthResponse(status="ok" if healthy else "unhealthy", checks=checks)
    return JSONResponse(body.model_dump(), status_code=200 if healthy else 503)
