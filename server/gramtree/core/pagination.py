"""列表接口统一用游标分页。

游标是不透明字符串，客户端原样带回。分页依赖统一绑定请求主体、查询、有效期和页数。
"""

import base64
import hashlib
import hmac
import json
import uuid
from collections.abc import AsyncIterator
from contextvars import ContextVar
from dataclasses import dataclass
from datetime import datetime
from typing import Annotated, Generic, TypeVar

import jwt
from fastapi import Query, Request, Response
from pydantic import BaseModel

from gramtree.core.clock import ClockDep
from gramtree.core.errors import ApiError
from gramtree.deps import SessionDep, SettingsDep
from gramtree.runtime_config import service as config

DEFAULT_PAGE_SIZE = 20

T = TypeVar("T")


class Page(BaseModel, Generic[T]):
    items: list[T]
    next_cursor: str | None = None


class PageParams(BaseModel):
    cursor: str | None
    limit: int


@dataclass
class CursorContext:
    secret: str
    subject: str
    query: str
    now: datetime
    ttl: int
    max_pages: int
    response: Response
    page: int = 1
    issued: int = 0
    expires: int = 0
    cursor: str | None = None
    position: str | None = None


_cursor_context: ContextVar[CursorContext | None] = ContextVar("cursor_context", default=None)


async def page_params(
    request: Request,
    response: Response,
    session: SessionDep,
    settings: SettingsDep,
    clock: ClockDep,
    cursor: Annotated[str | None, Query(description="上一页返回的 next_cursor")] = None,
    limit: Annotated[int, Query(ge=1, description="每页条数，上限见配置项 api.page_size_max")] = (
        DEFAULT_PAGE_SIZE
    ),
) -> AsyncIterator[PageParams]:
    now = clock()
    subject = "public:" + json.dumps(
        [request.client.host if request.client else None, request.headers.get("x-device-id")]
    )
    authorization = request.headers.get("authorization", "")
    if authorization.lower().startswith("bearer "):
        try:
            claims = jwt.decode(
                authorization[7:],
                settings.auth_secret,
                algorithms=["HS256"],
                options={"verify_exp": False, "verify_iat": False},
            )
            if claims.get("typ") == "access" and claims.get("sub"):
                subject = "account:" + str(claims["sub"])
        except jwt.PyJWTError:
            pass  # Protected routes still perform full session/signature authentication.
    # Bind all filters (including duplicate parameters), effective limit, route and
    # POST search body. Cursor itself is the sole excluded request parameter.
    filters = sorted(
        (key, value) for key, value in request.query_params.multi_items() if key != "cursor"
    )
    filters = [(key, value) for key, value in filters if key != "limit"] + [("limit", str(limit))]
    query = json.dumps(
        [
            request.method,
            request.url.path,
            filters,
            hashlib.sha256(await request.body()).hexdigest(),
        ],
        separators=(",", ":"),
    )
    context = CursorContext(
        settings.auth_secret,
        subject,
        query,
        now,
        int(config.get(session, "api.cursor_ttl_seconds")),
        int(config.get(session, "api.cursor_max_pages")),
        response,
        issued=int(now.timestamp()),
    )
    context.expires = context.issued + context.ttl
    if cursor is not None:
        _read_bound_cursor(cursor, context)
    token = _cursor_context.set(context)
    try:
        yield PageParams(cursor=cursor, limit=limit)
    finally:
        _cursor_context.reset(token)


def _cursor_error(code: str = "invalid_cursor") -> ApiError:
    return ApiError(422, code, "请刷新列表")


def _b64_json(value: object) -> str:
    raw = json.dumps(value, ensure_ascii=False, separators=(",", ":"), sort_keys=True).encode()
    return base64.urlsafe_b64encode(raw).decode().rstrip("=")


def _decode_b64_json(value: str) -> object:
    padded = value + "=" * (-len(value) % 4)
    return json.loads(base64.urlsafe_b64decode(padded))


def _read_bound_cursor(cursor: str, context: CursorContext) -> None:
    try:
        envelope = _decode_b64_json(cursor)
        if not isinstance(envelope, dict) or set(envelope) != {"d", "m"}:
            raise ValueError
        unsigned, mac = envelope["d"], envelope["m"]
        if not isinstance(unsigned, str) or not isinstance(mac, str):
            raise ValueError
        expected = hmac.new(context.secret.encode(), unsigned.encode(), "sha256").hexdigest()
        if not hmac.compare_digest(expected, mac):
            raise ValueError
        payload = _decode_b64_json(unsigned)
        if not isinstance(payload, dict) or set(payload) != {"v", "o", "s", "q", "t", "e", "p"}:
            raise ValueError
        for field in ("t", "e", "p"):
            if type(payload[field]) is not int:
                raise ValueError
        if payload["v"] != 2 or not isinstance(payload["o"], str):
            raise ValueError
        if payload["s"] != _binding(context, context.subject) or payload["q"] != _binding(
            context, context.query
        ):
            raise ValueError
        current = int(context.now.timestamp())
        if (
            payload["t"] > current
            or payload["e"] <= current
            or payload["t"] + context.ttl <= current
            or payload["p"] < 2
        ):
            raise ValueError
        if payload["p"] > max(1, context.max_pages):
            raise ApiError(422, "pagination_limit_reached", "请换搜索条件")
        context.cursor, context.position = cursor, payload["o"]
        context.page, context.issued = payload["p"], payload["t"]
        context.expires = min(payload["e"], context.issued + context.ttl)
    except ApiError:
        raise
    except (ValueError, TypeError, KeyError, UnicodeDecodeError) as exc:
        raise _cursor_error() from exc


def _binding(context: CursorContext, value: str) -> str:
    return hmac.new(context.secret.encode(), value.encode(), "sha256").hexdigest()


def _wrap_position(position: str) -> str | None:
    context = _cursor_context.get()
    if context is None:
        return position
    if context.page >= context.max_pages:
        context.response.headers["X-Pagination-Limit-Reached"] = "true"
        return None
    unsigned = _b64_json(
        {
            "v": 2,
            "o": position,
            "s": _binding(context, context.subject),
            "q": _binding(context, context.query),
            "t": context.issued,
            "e": context.expires,
            "p": context.page + 1,
        }
    )
    return _b64_json({"d": unsigned, "m": _binding(context, unsigned)})


def _unwrap_position(cursor: str) -> str:
    context = _cursor_context.get()
    if context is None:
        return cursor
    if cursor != context.cursor or context.position is None:
        raise _cursor_error()
    return context.position


def encode_cursor(created_at: datetime, id_: uuid.UUID) -> str | None:
    return _wrap_position(_b64_json([created_at.isoformat(), str(id_)]))


def decode_cursor(cursor: str) -> tuple[datetime, uuid.UUID]:
    try:
        decoded = _decode_b64_json(_unwrap_position(cursor))
        if not isinstance(decoded, list) or len(decoded) != 2:
            raise ValueError
        created_at, id_ = decoded
        if not isinstance(created_at, str) or not isinstance(id_, str):
            raise ValueError
        return datetime.fromisoformat(created_at), uuid.UUID(id_)
    except (ValueError, TypeError, json.JSONDecodeError) as exc:
        raise ApiError(422, "invalid_cursor", "请求参数有误", "cursor 无法解析") from exc


def encode_parts(parts: list[int | str]) -> str | None:
    """把一组标量编成不透明游标。

    按创建时间倒序的列表用 `encode_cursor`（它带上完整的时间戳）；排序键不是时间的列表
    （例如按出现次数排的统计、排名后切页的搜索结果）用这一对：把排序键的最后一个值放进
    `parts`，下一页从它之后接着取。客户端只负责原样带回，内容的形状属于服务端私有约定。
    """
    raw = json.dumps(parts, separators=(",", ":")).encode()
    return _wrap_position(base64.urlsafe_b64encode(raw).decode().rstrip("="))


def decode_parts(cursor: str) -> list[object]:
    try:
        cursor = _unwrap_position(cursor)
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
