"""事件上传重复率、拒收率超过阈值时告警（SPEC-010.1 票 3）。

阈值、窗口都是服务端配置项（`events.alert_*`），改了立刻生效。发送走
`gramtree.observability.alerts.notify` 的同一套接收方式和地址（`ops.alert_channel`/
`ops.alert_target`），和接口层的 `gramtree.observability.alerts.check_and_notify`
是两条独立的检查、各自的窗口去重 key，互不影响。
"""

import logging

from redis import Redis
from sqlalchemy.orm import Session

from gramtree.events import metrics
from gramtree.observability import alerts
from gramtree.runtime_config import service as config

logger = logging.getLogger("gramtree.events.alerts")


def check_and_notify(session: Session, redis: Redis, now: float | None = None) -> dict[str, object]:
    minutes = int(config.get(session, "events.alert_window_minutes"))
    stats = metrics.window(redis, minutes, now=now)
    problems: list[str] = []
    if stats.total >= int(config.get(session, "events.alert_min_events")):
        max_dup = float(config.get(session, "events.alert_duplicate_rate"))
        if stats.duplicate_rate > max_dup:
            problems.append(f"事件重复率 {stats.duplicate_rate:.1%} 超过阈值 {max_dup:.1%}")
        max_reject = float(config.get(session, "events.alert_reject_rate"))
        if stats.reject_rate > max_reject:
            problems.append(f"事件拒收率 {stats.reject_rate:.1%} 超过阈值 {max_reject:.1%}")

    sent = False
    if problems:
        logger.error(
            "events pipeline alert",
            extra={
                "problems": problems,
                "total": stats.total,
                "accepted": stats.accepted,
                "duplicate": stats.duplicate,
                "rejected": stats.rejected,
                "avg_delay_ms": stats.avg_delay_ms,
            },
        )
        # 同一窗口内不重复发；key 和接口层告警各自独立
        if redis.set("alerts:events:sent", "1", nx=True, ex=minutes * 60):
            sent = alerts.notify(session, "味谱事件管道告警", "\n".join(problems))
    return {
        "total": stats.total,
        "accepted": stats.accepted,
        "duplicate": stats.duplicate,
        "rejected": stats.rejected,
        "avg_delay_ms": stats.avg_delay_ms,
        "problems": problems,
        "sent": sent,
    }
