"""列表接口统一用游标分页。

游标是不透明字符串，客户端原样带回。签名和有效期在 SPEC-011.2 加。
"""

import base64
import json
import uuid
from datetime import datetime
from typing import Annotated, Generic, TypeVar

from fastapi import Query
from pydantic import BaseModel

from gramtree.core.errors import ApiError

DEFAULT_PAGE_SIZE = 20

T = TypeVar("T")


class Page(BaseModel, Generic[T]):
    items: list[T]
    next_cursor: str | None = None


class PageParams(BaseModel):
    cursor: str | None
    limit: int


def page_params(
    cursor: Annotated[str | None, Query(description="上一页返回的 next_cursor")] = None,
    limit: Annotated[int, Query(ge=1, description="每页条数，上限见配置项 api.page_size_max")] = (
        DEFAULT_PAGE_SIZE
    ),
) -> PageParams:
    return PageParams(cursor=cursor, limit=limit)


def encode_cursor(created_at: datetime, id_: uuid.UUID) -> str:
    raw = json.dumps([created_at.isoformat(), str(id_)]).encode()
    return base64.urlsafe_b64encode(raw).decode().rstrip("=")


def decode_cursor(cursor: str) -> tuple[datetime, uuid.UUID]:
    try:
        padded = cursor + "=" * (-len(cursor) % 4)
        created_at, id_ = json.loads(base64.urlsafe_b64decode(padded))
        return datetime.fromisoformat(created_at), uuid.UUID(id_)
    except (ValueError, TypeError) as exc:
        raise ApiError(422, "invalid_cursor", "请求参数有误", "cursor 无法解析") from exc


def encode_parts(parts: list[int | str]) -> str:
    """把一组标量编成不透明游标。

    按创建时间倒序的列表用 `encode_cursor`（它带上完整的时间戳）；排序键不是时间的列表
    （例如按出现次数排的统计、排名后切页的搜索结果）用这一对：把排序键的最后一个值放进
    `parts`，下一页从它之后接着取。客户端只负责原样带回，内容的形状属于服务端私有约定。
    """
    raw = json.dumps(parts, separators=(",", ":")).encode()
    return base64.urlsafe_b64encode(raw).decode().rstrip("=")


def decode_parts(cursor: str) -> list[object]:
    try:
        padded = cursor + "=" * (-len(cursor) % 4)
        parts = json.loads(base64.b64decode(padded, altchars=b"-_", validate=True))
    except (ValueError, TypeError) as exc:
        raise ApiError(422, "invalid_cursor", "请求参数有误", "cursor 无法解析") from exc
    if not isinstance(parts, list) or not parts or any(type(p) not in (int, str) for p in parts):
        raise ApiError(422, "invalid_cursor", "请求参数有误", "cursor 无法解析")
    return parts


def check_limit(limit: int, maximum: int) -> None:
    if limit > maximum:
        raise ApiError(422, "invalid_request", "请求参数有误", f"limit 不能超过 {maximum}")
