"""经验层事件管道的业务指标：上传量、重复率、拒收率、上传延迟（SPEC-010.1 票 3）。

和 `gramtree.observability.metrics`（接口层：所有接口共用的耗时、5xx 错误率）不是
一回事——这里存的是"每次上传批次"的业务结果，只有 `events.router.upload_events`
会写，接入 SPEC-013.1 的监控，也供 `gramtree.events.alerts` 的告警任务读。

按分钟分桶存在 Redis 里，多个 API 进程共享；Redis 不可用时只丢指标，不影响接口本身。
"""

import logging
import time
from dataclasses import dataclass
from typing import cast

from redis import Redis

logger = logging.getLogger("gramtree.events.metrics")

_PREFIX = "metrics:events"
_BUCKET_TTL_SECONDS = 2 * 60 * 60
_DELAY_SAMPLES_PER_BUCKET = 5000


def _bucket(ts: float) -> int:
    return int(ts // 60)


def record_upload_batch(
    redis: Redis,
    *,
    accepted: int,
    duplicate: int,
    rejected: int,
    delays_ms: list[float] | None = None,
    now: float | None = None,
) -> None:
    """一次上传请求处理完之后记一笔。

    `delays_ms` 是这一批里被新接收（`accepted`）的事件的上传延迟（服务端接收时间
    减设备时间，毫秒），可能是负数（设备时间比服务端快）；重复、拒收的事件不产生
    新的延迟样本。
    """
    bucket = _bucket(now if now is not None else time.time())
    counts_key = f"{_PREFIX}:{bucket}:counts"
    delay_key = f"{_PREFIX}:{bucket}:delay_ms"
    try:
        pipe = redis.pipeline()
        pipe.hincrby(counts_key, "accepted", accepted)
        pipe.hincrby(counts_key, "duplicate", duplicate)
        pipe.hincrby(counts_key, "rejected", rejected)
        pipe.expire(counts_key, _BUCKET_TTL_SECONDS)
        if delays_ms:
            pipe.rpush(delay_key, *(round(d, 1) for d in delays_ms))
            pipe.ltrim(delay_key, -_DELAY_SAMPLES_PER_BUCKET, -1)
            pipe.expire(delay_key, _BUCKET_TTL_SECONDS)
        pipe.execute()
    except Exception:
        logger.warning("failed to record events metrics", exc_info=True)


@dataclass(frozen=True)
class WindowStats:
    accepted: int
    duplicate: int
    rejected: int
    avg_delay_ms: float

    @property
    def total(self) -> int:
        return self.accepted + self.duplicate + self.rejected

    @property
    def duplicate_rate(self) -> float:
        return self.duplicate / self.total if self.total else 0.0

    @property
    def reject_rate(self) -> float:
        return self.rejected / self.total if self.total else 0.0


def window(redis: Redis, minutes: int, now: float | None = None) -> WindowStats:
    end = _bucket(now if now is not None else time.time())
    accepted = duplicate = rejected = 0
    delays: list[float] = []
    for bucket in range(end - minutes + 1, end + 1):
        counts = cast(dict[bytes, bytes], redis.hgetall(f"{_PREFIX}:{bucket}:counts"))
        accepted += int(counts.get(b"accepted", 0))
        duplicate += int(counts.get(b"duplicate", 0))
        rejected += int(counts.get(b"rejected", 0))
        samples = cast(list[bytes], redis.lrange(f"{_PREFIX}:{bucket}:delay_ms", 0, -1))
        delays.extend(float(v) for v in samples)
    avg_delay = sum(delays) / len(delays) if delays else 0.0
    return WindowStats(
        accepted=accepted, duplicate=duplicate, rejected=rejected, avg_delay_ms=avg_delay
    )
