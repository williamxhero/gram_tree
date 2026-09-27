"""时间约定：接口里一律带时区（ISO 8601），服务端按 UTC 存储。"""

from datetime import UTC, datetime
from typing import Annotated

from pydantic import AfterValidator, AwareDatetime, PlainSerializer


def utcnow() -> datetime:
    return datetime.now(UTC)


def _to_utc(value: datetime) -> datetime:
    return value.astimezone(UTC)


# 请求里不带时区的时间会被拒绝；响应统一输出成 UTC 的 ISO 8601
Timestamp = Annotated[
    AwareDatetime,
    AfterValidator(_to_utc),
    PlainSerializer(lambda v: v.astimezone(UTC).isoformat(), return_type=str),
]
