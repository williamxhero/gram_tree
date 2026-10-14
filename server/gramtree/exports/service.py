"""Durable queue, independent daily quota and authenticated expiry-bound downloads."""

import hashlib
import hmac
import logging
import os
import tempfile
import uuid
from datetime import UTC, datetime, timedelta
from pathlib import Path
from typing import cast

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from gramtree.accounts.models import User, UserStatus
from gramtree.core.errors import ApiError, NotFound
from gramtree.exports import archive
from gramtree.exports.models import ExportJob
from gramtree.exports.schemas import ExportJobView
from gramtree.runtime_config import service as config
from gramtree.settings import Settings

logger = logging.getLogger("gramtree.exports")


def archive_path(settings: Settings, job_id: uuid.UUID) -> Path:
    return Path(settings.export_dir).resolve() / f"{job_id}.zip"


def signature(settings: Settings, job: ExportJob, expires: int) -> str:
    # Domain separation prevents reuse of tokens signed with the same deployment secret.
    payload = f"gramtree:export:v1:{job.owner_id}:{job.id}:{expires}".encode()
    return hmac.new(settings.auth_secret.encode(), payload, hashlib.sha256).hexdigest()


def view(job: ExportJob, settings: Settings, now: datetime) -> ExportJobView:
    status = job.status
    url = None
    if status == "completed" and job.expires_at:
        if now >= job.expires_at:
            status = "expired"
        else:
            expires = int(job.expires_at.timestamp())
            signed = signature(settings, job, expires)
            url = f"/v1/me/exports/{job.id}/download?expires={expires}&signature={signed}"
    return ExportJobView(
        id=job.id,
        status=cast("object", status),  # validated by Pydantic below
        created_at=job.created_at,
        completed_at=job.completed_at,
        expires_at=job.expires_at,
        download_url=url,
        error_code=job.error_code,
    )


def owned_job(session: Session, owner_id: uuid.UUID, job_id: uuid.UUID) -> ExportJob:
    job = session.scalar(
        select(ExportJob).where(ExportJob.id == job_id, ExportJob.owner_id == owner_id)
    )
    if job is None:
        raise NotFound()
    return job


def lock_owner(session: Session, owner_id: uuid.UUID) -> User:
    owner = session.scalar(select(User).where(User.id == owner_id).with_for_update())
    if owner is None or owner.status != UserStatus.active:
        raise NotFound()
    return owner


def create(session: Session, owner_id: uuid.UUID, now: datetime) -> ExportJob:
    # Every request locks the stable owner row, including concurrent first requests.
    # The durable job itself is the quota receipt, never a Redis ordinary-rate bucket.
    lock_owner(session, owner_id)
    start = now.astimezone(UTC).replace(hour=0, minute=0, second=0, microsecond=0)
    used = (
        session.scalar(
            select(func.count())
            .select_from(ExportJob)
            .where(
                ExportJob.owner_id == owner_id,
                ExportJob.created_at >= start,
                ExportJob.created_at < start + timedelta(days=1),
            )
        )
        or 0
    )
    if used >= int(config.get(session, "export.daily_limit")):
        raise ApiError(429, "export_daily_limit", "今天的导出次数已用完，请明天再试")
    job = ExportJob(owner_id=owner_id, created_at=now)
    session.add(job)
    session.commit()
    return job


def retry(session: Session, owner_id: uuid.UUID, job_id: uuid.UUID, now: datetime) -> ExportJob:
    del now
    lock_owner(session, owner_id)
    job = owned_job(session, owner_id, job_id)
    if job.status in ("pending", "processing"):
        return job
    if job.status != "failed":
        raise ApiError(409, "export_not_retryable", "只有失败的导出可以重试")
    if job.attempts >= int(config.get(session, "export.max_attempts")):
        raise ApiError(409, "export_retry_limit", "重试次数已用完，请重新发起导出")
    job.status, job.error_code = "pending", None
    session.commit()
    return job


def enqueue(job_id: uuid.UUID) -> None:
    from gramtree.tasks.jobs import run_data_exports

    try:
        run_data_exports.delay(str(job_id))
    except Exception:
        # Beat will drain the committed outbox; broker downtime never loses the request.
        logger.warning("export queue unavailable; durable job awaits periodic drain")


def run(
    session: Session, settings: Settings, now: datetime, job_id: uuid.UUID | None = None
) -> dict[str, int]:
    query = select(ExportJob.id).where(ExportJob.status == "pending").order_by(ExportJob.created_at)
    if job_id is not None:
        query = query.where(ExportJob.id == job_id)
    ids = list(session.scalars(query.limit(10)))
    # One transaction per job, row locks held through file publication. A process
    # crash rolls the claim back to pending; redelivery cannot duplicate an archive.
    session.rollback()
    completed = failed = 0
    for current_id in ids:
        job = session.get(ExportJob, current_id)
        if job is None:
            continue
        owner_id = job.owner_id
        session.rollback()
        owner = session.scalar(
            select(User).where(User.id == owner_id).with_for_update(skip_locked=True)
        )
        if owner is None:
            session.rollback()
            continue
        job = session.scalar(select(ExportJob).where(ExportJob.id == current_id).with_for_update())
        if job is None or job.status != "pending":
            session.rollback()
            continue
        if owner.status != UserStatus.active:
            archive_path(settings, job.id).unlink(missing_ok=True)
            job.status, job.error_code = "expired", None
            session.commit()
            continue
        job.status = "processing"
        job.attempts += 1
        session.flush()
        destination = archive_path(settings, job.id)
        temporary: Path | None = None
        try:
            destination.parent.mkdir(parents=True, exist_ok=True)
            with tempfile.NamedTemporaryFile(
                dir=destination.parent, prefix=f"{job.id}.", suffix=".tmp", delete=False
            ) as file:
                temporary = Path(file.name)
            archive.build(session, settings, owner, temporary, now)
            os.replace(temporary, destination)
            job.status, job.error_code = "completed", None
            job.completed_at = now
            job.expires_at = now + timedelta(
                seconds=int(config.get(session, "export.download_ttl_seconds"))
            )
            session.commit()
            completed += 1
        except Exception:
            # Do not retain exception text/SQL/JSON in a task record or logs.
            session.rollback()
            destination.unlink(missing_ok=True)
            job = session.get(ExportJob, current_id)
            if job is not None:
                job.status, job.error_code = "failed", "export_failed"
                job.attempts += 1
                session.commit()
            failed += 1
            logger.warning("export failed; retry available")
        finally:
            if temporary is not None:
                temporary.unlink(missing_ok=True)
    return {"completed": completed, "failed": failed}


def download(
    session: Session,
    settings: Settings,
    owner_id: uuid.UUID,
    job_id: uuid.UUID,
    expires: int,
    supplied_signature: str,
    now: datetime,
) -> Path:
    job = owned_job(session, owner_id, job_id)
    if job.status != "completed" or job.expires_at is None:
        raise ApiError(410, "export_unavailable", "导出文件尚未完成或已过期")
    if now >= job.expires_at or now.timestamp() >= expires:
        raise ApiError(410, "export_expired", "导出文件已过期，请重新导出")
    if expires != int(job.expires_at.timestamp()) or not hmac.compare_digest(
        signature(settings, job, expires),
        supplied_signature,
    ):
        raise ApiError(403, "invalid_export_signature", "下载地址无效")
    path = archive_path(settings, job.id)
    if not path.is_file():
        raise ApiError(410, "export_unavailable", "导出文件不可用，请重新导出")
    return path


def erase_owner_exports(session: Session, settings: Settings, owner_id: uuid.UUID) -> None:
    """Account erasure extension; caller already holds the owner lock."""
    for job in session.scalars(select(ExportJob).where(ExportJob.owner_id == owner_id)):
        archive_path(settings, job.id).unlink(missing_ok=True)
        job.status, job.error_code = "expired", None


def cleanup(session: Session, settings: Settings, now: datetime) -> dict[str, int]:
    ids = list(
        session.scalars(
            select(ExportJob.id).where(
                ExportJob.status == "completed",
                ExportJob.expires_at <= now,
            )
        )
    )
    removed = 0
    for job_id in ids:
        job = session.scalar(select(ExportJob).where(ExportJob.id == job_id).with_for_update())
        if (
            job is None
            or job.status != "completed"
            or job.expires_at is None
            or job.expires_at > now
        ):
            continue
        archive_path(settings, job.id).unlink(missing_ok=True)
        job.status = "expired"
        removed += 1
    session.commit()
    # Files whose account/job was cascaded away, plus abandoned crash tempfiles.
    root = Path(settings.export_dir).resolve()
    known = set(session.scalars(select(ExportJob.id)))
    for path in root.glob("*.zip"):
        try:
            owner_job = uuid.UUID(path.stem)
        except ValueError:
            continue
        if owner_job not in known:
            path.unlink(missing_ok=True)
            removed += 1
    for path in root.glob("*.tmp"):
        if path.stat().st_mtime < now.timestamp() - 86400:
            path.unlink(missing_ok=True)
    return {"removed": removed}
