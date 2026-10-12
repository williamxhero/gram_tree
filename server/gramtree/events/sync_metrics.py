"""Registered-write monitoring in the existing Redis minute-bucket pipeline.

Attempts count every returned delivery result (including replay/deferred).
Outcomes count only the first durable terminal receipt transition, supplied by
sync_router after commit; replay must NEVER call record_outcome. Redis failure
may lose a metric, never a business write. No IDs, payloads or private labels are
stored, and no Redis ID dedup set grows with the number of business records.
"""

import logging
import time
from typing import cast

from redis import Redis

logger = logging.getLogger("gramtree.events.sync_metrics")
_PREFIX = "metrics:sync"
_TTL_SECONDS = 2 * 60 * 60
_TYPES = {"experience.event", "recipe_version.save", "personal_measure.change"}
_STATUSES = {"confirmed", "already_processed", "deferred", "conflict", "failed"}
_PERMISSION = {
    "owner_mismatch",
    "forbidden",
    "dependency_unavailable",
    "write_id_unavailable",
    "reference_forbidden",
    "recipe_not_writable",
    "prohibited_health_claim",
}
_VALIDATION = {
    "invalid_content",
    "invalid_recipe",
    "unknown_write_type",
    "unknown_event_type",
    "write_id_reused",
    "duplicate_dependency",
    "dependency_cycle",
    "unsupported_type_version",
    "server_fact_only",
    "reference_dependency_required",
    "reference_dependency_type",
    "reference_dependency_mismatch",
    "baseline_dependency_required",
    "baseline_dependency_type",
    "candidate_version_id_reused",
    "dependency_resource_mismatch",
    "resource_already_exists",
    "measure_name_taken",
}
_DEPENDENCY = {
    "dependency_failed",
    "dependency_not_arrived",
    "dependency_not_confirmed",
    "dependency_conflict",
    "reference_not_arrived",
}


def _labels(write_type: str, status: str, reason_code: str | None) -> tuple[str, str, str]:
    reason = "none"
    if reason_code is not None:
        if reason_code in _PERMISSION:
            reason = "permission"
        elif reason_code in _VALIDATION:
            reason = "validation"
        elif reason_code in _DEPENDENCY:
            reason = "dependency"
        elif reason_code == "conflict_choice_required":
            reason = "conflict"
        else:
            reason = "other"
    return (
        write_type if write_type in _TYPES else "other",
        status if status in _STATUSES else "other",
        reason,
    )


def _record(
    redis: Redis,
    kind: str,
    *,
    write_type: str,
    status: str,
    reason_code: str | None,
    now: float | None,
) -> None:
    labels = _labels(write_type, status, reason_code)
    bucket = int((now if now is not None else time.time()) // 60)
    key = f"{_PREFIX}:{bucket}:{kind}"
    try:
        pipe = redis.pipeline()
        pipe.hincrby(key, "|".join(labels), 1)
        pipe.expire(key, _TTL_SECONDS)
        pipe.execute()
    except Exception:
        # Never include connection strings or raw exception/payload text.
        logger.warning("failed to record sync metrics")
    logger.info(
        "sync write delivery",
        extra={
            "sync_metric_kind": kind,
            "sync_write_type": labels[0],
            "sync_status": labels[1],
            "sync_reason": labels[2],
        },
    )


def record_attempt(
    redis: Redis,
    *,
    write_type: str,
    status: str,
    reason_code: str | None = None,
    now: float | None = None,
) -> None:
    _record(
        redis, "attempts", write_type=write_type, status=status, reason_code=reason_code, now=now
    )


def record_outcome(
    redis: Redis,
    *,
    write_type: str,
    status: str,
    reason_code: str | None = None,
    now: float | None = None,
) -> None:
    if status not in {"confirmed", "conflict", "failed"}:
        return
    _record(
        redis, "outcomes", write_type=write_type, status=status, reason_code=reason_code, now=now
    )


def window(redis: Redis, minutes: int, now: float | None = None) -> dict[str, object]:
    end = int((now if now is not None else time.time()) // 60)
    groups: dict[str, list[dict[str, object]]] = {}
    for kind in ("attempts", "outcomes"):
        totals: dict[str, int] = {}
        for bucket in range(end - minutes + 1, end + 1):
            counts = cast(dict[bytes, bytes], redis.hgetall(f"{_PREFIX}:{bucket}:{kind}"))
            for field, count in counts.items():
                label = field.decode()
                totals[label] = totals.get(label, 0) + int(count)
        rows = []
        for label, count in sorted(totals.items()):
            write_type, status, reason = label.split("|")
            rows.append(
                {"write_type": write_type, "status": status, "reason": reason, "count": count}
            )
        groups[kind] = rows
    outcomes = groups["outcomes"]
    return {
        **groups,
        "attempt_count": sum(cast(int, row["count"]) for row in groups["attempts"]),
        "outcome_count": sum(cast(int, row["count"]) for row in outcomes),
        "failed_count": sum(
            cast(int, row["count"]) for row in outcomes if row["status"] == "failed"
        ),
        "conflict_count": sum(
            cast(int, row["count"]) for row in outcomes if row["status"] == "conflict"
        ),
    }
