"""列表接口统一用游标分页。

游标是不透明字符串，客户端原样带回。签名和有效期在 SPEC-011.2 加。
"""

import base64
import hmac
import json
import uuid
from datetime import UTC, datetime, timedelta
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


def _cursor_error(code: str = "invalid_cursor") -> ApiError:
    return ApiError(422, code, "请刷新列表")


def _b64_json(value: object) -> str:
    raw = json.dumps(value, ensure_ascii=False, separators=(",", ":"), sort_keys=True).encode()
    return base64.urlsafe_b64encode(raw).decode().rstrip("=")


def _decode_b64_json(value: str) -> object:
    padded = value + "=" * (-len(value) % 4)
    return json.loads(base64.urlsafe_b64decode(padded))


def encode_cursor(created_at: datetime, id_: uuid.UUID) -> str:
    """Legacy unsigned cursor retained for non-user-facing examples and migrations."""
    return _b64_json([created_at.isoformat(), str(id_)])


def decode_cursor(cursor: str) -> tuple[datetime, uuid.UUID]:
    try:
        decoded = _decode_b64_json(cursor)
        if not isinstance(decoded, list) or len(decoded) != 2:
            raise ValueError
        created_at, id_ = decoded
        if not isinstance(created_at, str) or not isinstance(id_, str):
            raise ValueError
        return datetime.fromisoformat(created_at), uuid.UUID(id_)
    except (ValueError, TypeError, json.JSONDecodeError) as exc:
        raise ApiError(422, "invalid_cursor", "请求参数有误", "cursor 无法解析") from exc


def encode_signed_cursor(
    created_at: datetime,
    id_: uuid.UUID,
    *,
    secret: str,
    subject: str,
    query: str,
    page: int = 1,
    ttl_seconds: int = 600,
    now: datetime | None = None,
) -> str:
    """Create an opaque, user/query-bound cursor with an expiration and page bound."""
    issued_at = now or datetime.now(UTC)
    if issued_at.tzinfo is None:
        issued_at = issued_at.replace(tzinfo=UTC)
    payload: dict[str, object] = {
        "a": created_at.isoformat(),
        "e": int((issued_at + timedelta(seconds=max(1, ttl_seconds))).timestamp()),
        "i": str(id_),
        "p": page,
        "q": hmac.new(secret.encode(), query.encode(), "sha256").hexdigest(),
        "s": hmac.new(secret.encode(), subject.encode(), "sha256").hexdigest(),
        "t": int(issued_at.timestamp()),
        "v": 1,
    }
    unsigned = _b64_json(payload)
    signature = hmac.new(secret.encode(), unsigned.encode(), "sha256").hexdigest()
    return _b64_json({"d": unsigned, "m": signature})


def decode_signed_cursor(
    cursor: str,
    *,
    secret: str,
    subject: str,
    query: str,
    max_pages: int,
    now: datetime | None = None,
) -> tuple[datetime, uuid.UUID, int]:
    """Verify a cursor without revealing whether parsing, binding, or expiry failed."""
    try:
        envelope = _decode_b64_json(cursor)
        if not isinstance(envelope, dict) or set(envelope) != {"d", "m"}:
            raise ValueError
        unsigned = envelope["d"]
        supplied_mac = envelope["m"]
        if not isinstance(unsigned, str) or not isinstance(supplied_mac, str):
            raise ValueError
        expected_mac = hmac.new(secret.encode(), unsigned.encode(), "sha256").hexdigest()
        if not hmac.compare_digest(supplied_mac, expected_mac):
            raise ValueError
        payload = _decode_b64_json(unsigned)
        if not isinstance(payload, dict) or set(payload) != {
            "a",
            "e",
            "i",
            "p",
            "q",
            "s",
            "t",
            "v",
        }:
            raise ValueError
        expected_query = hmac.new(secret.encode(), query.encode(), "sha256").hexdigest()
        expected_subject = hmac.new(secret.encode(), subject.encode(), "sha256").hexdigest()
        if payload["q"] != expected_query or payload["s"] != expected_subject or payload["v"] != 1:
            raise ValueError
        page = payload["p"]
        if not isinstance(page, int) or isinstance(page, bool) or page < 1:
            raise ValueError
        if page > max(1, max_pages):
            raise ApiError(422, "pagination_limit_reached", "请换搜索条件")
        current = now or datetime.now(UTC)
        if current.tzinfo is None:
            current = current.replace(tzinfo=UTC)
        if not isinstance(payload["e"], int) or payload["e"] < int(current.timestamp()):
            raise ValueError
        return datetime.fromisoformat(str(payload["a"])), uuid.UUID(str(payload["i"])), page
    except ApiError:
        raise
    except (ValueError, TypeError, KeyError, json.JSONDecodeError, UnicodeDecodeError) as exc:
        raise _cursor_error() from exc


def next_signed_cursor(
    created_at: datetime,
    id_: uuid.UUID,
    *,
    secret: str,
    subject: str,
    query: str,
    current_page: int,
    max_pages: int,
    ttl_seconds: int,
    now: datetime | None = None,
) -> str | None:
    next_page = current_page + 1
    if next_page > max_pages:
        return None
    return encode_signed_cursor(
        created_at,
        id_,
        secret=secret,
        subject=subject,
        query=query,
        page=next_page,
        ttl_seconds=ttl_seconds,
        now=now,
    )


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
