"""接口出错率或耗时超过阈值时告警。

阈值、窗口和接收方式都是服务端配置项（ops.alert_*），改了立刻生效。
同一种告警在一个窗口内只发一次。
"""

import logging
import smtplib
from email.message import EmailMessage

import httpx
from redis import Redis
from sqlalchemy.orm import Session

from gramtree.observability import metrics
from gramtree.runtime_config import service as config
from gramtree.settings import get_settings

logger = logging.getLogger("gramtree.alerts")


def check_and_notify(session: Session, redis: Redis, now: float | None = None) -> dict[str, object]:
    minutes = int(config.get(session, "ops.alert_window_minutes"))
    stats = metrics.window(redis, minutes, now=now)
    problems: list[str] = []
    if stats.total >= int(config.get(session, "ops.alert_min_requests")):
        max_rate = float(config.get(session, "ops.alert_error_rate"))
        if stats.error_rate > max_rate:
            problems.append(f"接口错误率 {stats.error_rate:.1%} 超过阈值 {max_rate:.1%}")
        max_p95 = int(config.get(session, "ops.alert_p95_ms"))
        if stats.p95_ms > max_p95:
            problems.append(f"接口耗时 p95 {stats.p95_ms:.0f}ms 超过阈值 {max_p95}ms")

    sent = False
    if problems:
        logger.error(
            "api alert",
            extra={
                "problems": problems,
                "total": stats.total,
                "errors": stats.errors,
                "p95_ms": stats.p95_ms,
            },
        )
        # 同一窗口内不重复发
        if redis.set("alerts:api:sent", "1", nx=True, ex=minutes * 60):
            sent = _send(session, "味谱接口告警", "\n".join(problems))
    return {
        "total": stats.total,
        "errors": stats.errors,
        "p95_ms": stats.p95_ms,
        "problems": problems,
        "sent": sent,
    }


def notify(session: Session, subject: str, body: str) -> bool:
    """供其他模块（比如事件管道发现的一次性异常）直接发一条自定义告警。

    走同一套接收方式和地址（ops.alert_channel/ops.alert_target），但不做窗口去重——
    调用方按自己的场景决定要不要限流，这里只负责把消息送出去。
    """
    return _send(session, subject, body)


def _send(session: Session, subject: str, body: str) -> bool:
    channel = config.get(session, "ops.alert_channel")
    target = str(config.get(session, "ops.alert_target"))
    if channel == "none" or not target:
        return False
    try:
        if channel == "webhook":
            httpx.post(target, json={"title": subject, "text": body}, timeout=5).raise_for_status()
            return True
        if channel == "email":
            smtp_url = get_settings().smtp_host
            if not smtp_url:
                logger.warning("alert channel is email but GRAMTREE_SMTP_HOST is empty")
                return False
            message = EmailMessage()
            message["Subject"] = subject
            message["From"] = get_settings().smtp_from
            message["To"] = target
            message.set_content(body)
            with smtplib.SMTP(smtp_url, get_settings().smtp_port, timeout=10) as smtp:
                smtp.send_message(message)
            return True
    except Exception:
        logger.exception("failed to send alert", extra={"channel": channel})
    return False
