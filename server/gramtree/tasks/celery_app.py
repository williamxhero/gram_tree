"""后台任务进程和定时调度。

启动：
    celery -A gramtree.tasks.celery_app worker --beat -l info
新任务写在 gramtree/tasks/ 下，定时任务在 beat_schedule 里登记。
"""

from celery import Celery
from celery.schedules import crontab

from gramtree.settings import get_settings


def make_celery() -> Celery:
    settings = get_settings()
    app = Celery("gramtree", broker=settings.redis_url, backend=settings.redis_url)
    app.conf.update(
        timezone="UTC",
        enable_utc=True,
        task_serializer="json",
        result_serializer="json",
        accept_content=["json"],
        broker_connection_retry_on_startup=True,
        include=["gramtree.tasks.jobs"],
        beat_schedule={
            # 样板：每 10 分钟写一次心跳，证明定时任务链路可用
            "heartbeat": {
                "task": "gramtree.tasks.jobs.record_heartbeat",
                "schedule": 600.0,
                "args": ("beat",),
            },
            # 每天 UTC 19:00（北京时间凌晨 3 点）备份数据库
            "backup-database": {
                "task": "gramtree.tasks.jobs.backup_database",
                "schedule": crontab(hour=19, minute=0),
            },
            # 每天 UTC 20:00（北京时间凌晨 4 点）删除注销到期账号的个人数据
            "purge-deleted-accounts": {
                "task": "gramtree.tasks.jobs.purge_deleted_accounts",
                "schedule": crontab(hour=20, minute=0),
            },
            # 每天 UTC 20:30 清理超过保存期的产品埋点（和经验层事件完全独立的通道）
            "purge-expired-analytics-events": {
                "task": "gramtree.tasks.jobs.purge_expired_analytics_events",
                "schedule": crontab(hour=20, minute=30),
            },
            # 每分钟检查一次接口错误率和耗时，超阈值就告警
            "check-api-alerts": {
                "task": "gramtree.tasks.jobs.check_api_alerts",
                "schedule": 60.0,
            },
            # 每分钟检查一次事件上传重复率、拒收率，超阈值就告警
            "check-events-alerts": {
                "task": "gramtree.tasks.jobs.check_events_alerts",
                "schedule": 60.0,
            },
        },
    )
    return app


celery_app = make_celery()
app = celery_app
