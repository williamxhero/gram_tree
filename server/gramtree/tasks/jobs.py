import logging
from functools import lru_cache

from redis import Redis
from sqlalchemy.orm import Session, sessionmaker

from gramtree.db import make_engine, make_session_factory
from gramtree.examples.models import TaskHeartbeat
from gramtree.observability import alerts
from gramtree.settings import get_settings
from gramtree.tasks.celery_app import celery_app

logger = logging.getLogger("gramtree.tasks")


@lru_cache
def _session_factory() -> sessionmaker[Session]:
    return make_session_factory(make_engine(get_settings().database_url))


@celery_app.task(name="gramtree.tasks.jobs.record_heartbeat")
def record_heartbeat(source: str) -> str:
    with _session_factory()() as session:
        row = TaskHeartbeat(source=source)
        session.add(row)
        session.commit()
        logger.info("heartbeat recorded", extra={"source": source, "heartbeat_id": str(row.id)})
        return str(row.id)


@celery_app.task(name="gramtree.tasks.jobs.check_api_alerts")
def check_api_alerts() -> dict[str, object]:
    redis = Redis.from_url(get_settings().redis_url)
    with _session_factory()() as session:
        return alerts.check_and_notify(session, redis)


@celery_app.task(name="gramtree.tasks.jobs.backup_database")
def backup_database() -> str:
    from pathlib import Path

    from gramtree.ops import backup
    from gramtree.runtime_config import service as config

    settings = get_settings()
    path = backup.run_backup(settings.database_url, Path(settings.backup_dir))
    with _session_factory()() as session:
        retention = int(config.get(session, "ops.backup_retention_days"))
    backup.prune_local(Path(settings.backup_dir), retention)
    if settings.backup_remote:
        backup.upload(path, settings.backup_remote)
        backup.prune_remote(settings.backup_remote, retention)
    return str(path)
