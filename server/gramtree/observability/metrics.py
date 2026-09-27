"""接口耗时和错误率：按分钟分桶存在 Redis 里，多个 API 进程共享。

Redis 不可用时只丢指标，不影响接口本身。
"""

import logging
import time
from dataclasses import dataclass
from typing import cast

from redis import Redis

logger = logging.getLogger("gramtree.metrics")

_PREFIX = "metrics:api"
_BUCKET_TTL_SECONDS = 2 * 60 * 60
_LATENCY_SAMPLES_PER_BUCKET = 5000


def _bucket(ts: float) -> int:
    return int(ts // 60)


def record(redis: Redis, status_code: int, duration_ms: float, now: float | None = None) -> None:
    bucket = _bucket(now if now is not None else time.time())
    counts_key = f"{_PREFIX}:{bucket}:counts"
    latency_key = f"{_PREFIX}:{bucket}:latency"
    try:
        pipe = redis.pipeline()
        pipe.hincrby(counts_key, "total", 1)
        if status_code >= 500:
            pipe.hincrby(counts_key, "errors", 1)
        pipe.lpush(latency_key, round(duration_ms, 1))
        pipe.ltrim(latency_key, 0, _LATENCY_SAMPLES_PER_BUCKET - 1)
        pipe.expire(counts_key, _BUCKET_TTL_SECONDS)
        pipe.expire(latency_key, _BUCKET_TTL_SECONDS)
        pipe.execute()
    except Exception:
        logger.warning("failed to record api metrics", exc_info=True)


@dataclass(frozen=True)
class WindowStats:
    total: int
    errors: int
    p95_ms: float

    @property
    def error_rate(self) -> float:
        return self.errors / self.total if self.total else 0.0


def window(redis: Redis, minutes: int, now: float | None = None) -> WindowStats:
    end = _bucket(now if now is not None else time.time())
    total = errors = 0
    latencies: list[float] = []
    for bucket in range(end - minutes + 1, end + 1):
        counts = cast(dict[bytes, bytes], redis.hgetall(f"{_PREFIX}:{bucket}:counts"))
        total += int(counts.get(b"total", 0))
        errors += int(counts.get(b"errors", 0))
        samples = cast(list[bytes], redis.lrange(f"{_PREFIX}:{bucket}:latency", 0, -1))
        latencies.extend(float(v) for v in samples)
    p95 = 0.0
    if latencies:
        latencies.sort()
        p95 = latencies[min(len(latencies) - 1, int(len(latencies) * 0.95))]
    return WindowStats(total=total, errors=errors, p95_ms=p95)
