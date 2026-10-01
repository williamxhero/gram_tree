import logging
from functools import lru_cache

from redis import Redis
from sqlalchemy.orm import Session, sessionmaker

from gramtree.db import make_engine, make_session_factory
from gramtree.events import alerts as events_alerts
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


@celery_app.task(name="gramtree.tasks.jobs.drain_recipe_save_outbox")
def drain_recipe_save_outbox() -> int:
    """Retry committed recipe-save events left by a transient experience outage."""
    from sqlalchemy import distinct, select

    from gramtree.accounts.models import User
    from gramtree.recipes import service as recipes
    from gramtree.recipes.models import RecipeSaveOutbox

    settings = get_settings()
    redis = Redis.from_url(settings.redis_url)
    delivered = 0
    with _session_factory()() as session:
        owner_ids = list(
            session.scalars(
                select(distinct(RecipeSaveOutbox.owner_id)).where(
                    RecipeSaveOutbox.delivered_at.is_(None)
                )
            )
        )
        for owner_id in owner_ids:
            owner = session.get(User, owner_id)
            if owner is None:
                continue
            delivered += recipes._drain_save_events(session, redis, owner)
    return delivered


@celery_app.task(name="gramtree.tasks.jobs.check_api_alerts")
def check_api_alerts() -> dict[str, object]:
    redis = Redis.from_url(get_settings().redis_url)
    with _session_factory()() as session:
        return alerts.check_and_notify(session, redis)


@celery_app.task(name="gramtree.tasks.jobs.check_events_alerts")
def check_events_alerts() -> dict[str, object]:
    """事件上传重复率、拒收率超阈值时告警（SPEC-010.1 票 3）。"""
    redis = Redis.from_url(get_settings().redis_url)
    with _session_factory()() as session:
        return events_alerts.check_and_notify(session, redis)


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


@celery_app.task(name="gramtree.tasks.jobs.purge_expired_analytics_events")
def purge_expired_analytics_events(as_of: str | None = None) -> int:
    """清理超过保存期的产品埋点（SPEC-010.1 票 6，和经验层事件完全独立的通道）。"""
    from datetime import datetime

    from gramtree.analytics import service as analytics
    from gramtree.core.time import utcnow
    from gramtree.runtime_config import service as config

    now = datetime.fromisoformat(as_of) if as_of else utcnow()
    with _session_factory()() as session:
        retention = int(config.get(session, "analytics.retention_days"))
        return analytics.purge_expired(session, now, retention)


@celery_app.task(name="gramtree.tasks.jobs.purge_deleted_accounts")
def purge_deleted_accounts(as_of: str | None = None) -> int:
    """删除注销期限已到的账号的个人数据（SPEC-013.2）。"""
    from datetime import datetime

    from gramtree.accounts import service as accounts
    from gramtree.accounts.apple import AppleClient, HttpAppleTransport
    from gramtree.core.time import utcnow

    now = datetime.fromisoformat(as_of) if as_of else utcnow()
    apple = AppleClient(get_settings(), HttpAppleTransport())
    with _session_factory()() as session:
        return accounts.purge_due_accounts(session, apple, now)
