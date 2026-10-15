import uuid

from fastapi import APIRouter, Query
from fastapi.responses import FileResponse
from sqlalchemy import select

from gramtree.accounts import service as accounts
from gramtree.accounts.deps import CurrentAuth
from gramtree.core.clock import ClockDep
from gramtree.core.errors import ERROR_RESPONSES
from gramtree.deps import SessionDep, SettingsDep
from gramtree.exports import service
from gramtree.exports.models import ExportJob
from gramtree.exports.schemas import ExportJobList, ExportJobView

router = APIRouter(prefix="/me/exports", tags=["exports"], responses=ERROR_RESPONSES)


@router.post("", response_model=ExportJobView, status_code=202)
def start_export(
    auth: CurrentAuth, session: SessionDep, settings: SettingsDep, clock: ClockDep
) -> ExportJobView:
    now = clock()
    accounts.require_recent_reauth(session, auth.device_session, now)
    job = service.create(session, auth.user.id, now)
    service.enqueue(job.id)
    return service.view(job, settings, now)


@router.get("", response_model=ExportJobList)
def list_exports(
    auth: CurrentAuth, session: SessionDep, settings: SettingsDep, clock: ClockDep
) -> ExportJobList:
    rows = session.scalars(
        select(ExportJob)
        .where(ExportJob.owner_id == auth.user.id)
        .order_by(ExportJob.created_at.desc(), ExportJob.id.desc())
        .limit(100)
    )
    return ExportJobList(items=[service.view(row, settings, clock()) for row in rows])


@router.get("/{job_id}", response_model=ExportJobView)
def get_export(
    job_id: uuid.UUID,
    auth: CurrentAuth,
    session: SessionDep,
    settings: SettingsDep,
    clock: ClockDep,
) -> ExportJobView:
    return service.view(service.owned_job(session, auth.user.id, job_id), settings, clock())


@router.post("/{job_id}/retry", response_model=ExportJobView, status_code=202)
def retry_export(
    job_id: uuid.UUID,
    auth: CurrentAuth,
    session: SessionDep,
    settings: SettingsDep,
    clock: ClockDep,
) -> ExportJobView:
    now = clock()
    accounts.require_recent_reauth(session, auth.device_session, now)
    job = service.retry(session, auth.user.id, job_id, now)
    service.enqueue(job.id)
    return service.view(job, settings, now)


@router.get(
    "/{job_id}/download",
    response_class=FileResponse,
    responses={
        200: {"content": {"application/zip": {"schema": {"type": "string", "format": "binary"}}}}
    },
)
def download_export(
    job_id: uuid.UUID,
    auth: CurrentAuth,
    session: SessionDep,
    settings: SettingsDep,
    clock: ClockDep,
    expires: int = Query(ge=0),
    signature: str = Query(min_length=64, max_length=64),
) -> FileResponse:
    path = service.download(session, settings, auth.user.id, job_id, expires, signature, clock())
    return FileResponse(
        path,
        media_type="application/zip",
        filename=f"gramtree-export-{job_id}.zip",
        headers={
            "Cache-Control": "no-store",
            "Pragma": "no-cache",
            "X-Content-Type-Options": "nosniff",
        },
    )
