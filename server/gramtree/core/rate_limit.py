"""Redis-backed multi-dimensional request quotas."""

from __future__ import annotations

import hashlib
import hmac
import uuid
from contextlib import suppress
from datetime import UTC, datetime
from typing import Any, Literal, cast

import jwt
from redis import Redis
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from gramtree.core.errors import ApiError
from gramtree.runtime_config import service as config
from gramtree.runtime_config.registry import BY_KEY
from gramtree.settings import Settings

RateCategory = Literal["search_list", "detail", "write", "ai", "auth", "captcha", "export"]

# INCR + EXPIRE must be one Redis operation so concurrent requests cannot leave
# an unbounded counter or observe a half-updated set of dimensions.
_INCREMENT = """
local exceeded = 0
local retry = 0
local distinct = ARGV[3 * #KEYS + 1]
for i, key in ipairs(KEYS) do
  local count
  if ARGV[2 * #KEYS + i] == 'distinct' then
    redis.call('SADD', key, distinct)
    count = redis.call('SCARD', key)
  else
    count = redis.call('INCR', key)
  end
  if redis.call('TTL', key) < 0 then redis.call('EXPIRE', key, ARGV[i]) end
  local limit = tonumber(ARGV[i + #KEYS])
  if count > limit then
    exceeded = 1
    local ttl = redis.call('TTL', key)
    if ttl > retry then retry = ttl end
  end
end
return {exceeded, retry}
"""


class RateLimitError(ApiError):
    retry_after: int

    def __init__(self, retry_after: int):
        ApiError.__init__(self, 429, "rate_limited", "操作太频繁，请稍后再试", None)
        self.retry_after = max(1, retry_after)
        self.headers = {"Retry-After": str(self.retry_after)}


def category(path: str, method: str) -> RateCategory | None:
    if path in {"/v1/health", "/v1/client-config"} or path.startswith("/v1/dev/"):
        return None
    # Recovery must survive exhausted ordinary/login quotas, but it still has
    # its own finite multi-dimensional budget. Match only the two recovery routes.
    captcha_root = "/v1/risk/captcha"
    if method.upper() == "POST" and path == captcha_root:
        return "captcha"
    if method.upper() == "GET" and path.startswith(captcha_root + "/"):
        challenge_id = path[len(captcha_root) + 1 :]
        if challenge_id and "/" not in challenge_id:
            return "captcha"
    if path.startswith("/v1/auth/"):
        return "auth"
    if path.startswith("/v1/export"):
        return "export"
    if "/ai/" in path:
        return "ai"
    if path.endswith("/search") or (method.upper() == "GET" and path.endswith("/changes")):
        return "search_list"
    if method.upper() == "GET" and (
        path in {"/v1/recipes", "/v1/ingredients", "/v1/records"}
        or path.endswith("/versions")
        or path.endswith("/candidates")
        or path.endswith("/comparison-candidates")
        or path.endswith("/changes/pending")
        or path.endswith("/unrecorded")
        or path.endswith("/family-members")
        or path in {"/v1/me/measures", "/v1/examples/samples"}
        or path.endswith("/history")
    ):
        return "search_list"
    if method.upper() == "GET":
        return "detail"
    return "write"


def _safe_limit(session: Session, key: str, fallback: int) -> int:
    item = BY_KEY.get(key)
    default = item.default if item is not None and type(item.default) is int else fallback
    try:
        value = config.get(session, key)
        if type(value) is not int:
            return default
        if item is not None:
            config.validate(item, value)
    except SQLAlchemyError as exc:
        # Config storage is part of the quota boundary: an outage must fail closed,
        # just like an unavailable Redis counter, rather than escape as a 500.
        raise RateLimitError(60) from exc
    except (KeyError, TypeError, ValueError, OverflowError):
        return default
    return value if value > 0 else default


def _subject_from_token(token: str | None, settings: Settings) -> str | None:
    if not token:
        return None
    try:
        claims = jwt.decode(
            token,
            settings.auth_secret,
            algorithms=["HS256"],
            options={"verify_exp": False, "verify_iat": False},
        )
        subject = claims.get("sub")
        return str(subject) if subject else None
    except jwt.PyJWTError:
        return None


def _key(settings: Settings, kind: str, value: str) -> str:
    digest = hmac.new(settings.auth_secret.encode(), value.encode(), hashlib.sha256).hexdigest()
    return f"rate:{kind}:{digest}"


def enforce(
    redis: Redis,
    session: Session,
    settings: Settings,
    *,
    path: str,
    method: str,
    token: str | None,
    device_id: str | None,
    ip: str | None,
    now: datetime | None = None,
) -> None:
    """Count all known dimensions and reject if any fixed window is exhausted."""
    kind = category(path, method)
    if kind is None:
        return
    current = int((now or datetime.now(UTC)).timestamp())
    account = _subject_from_token(token, settings)
    dimensions = [("account", account), ("device", device_id), ("ip", ip)]
    dimensions = [(name, value) for name, value in dimensions if value]
    if not dimensions:
        # An unauthenticated request is still protected by its IP when available.
        return
    keys: list[str] = []
    expirations: list[str] = []
    limits: list[str] = []
    modes: list[str] = []
    recipe_id = ""
    path_parts = path.strip("/").split("/")
    if kind == "detail" and len(path_parts) >= 3 and path_parts[:2] == ["v1", "recipes"]:
        with suppress(ValueError):
            recipe_id = str(uuid.UUID(path_parts[2]))
    for name, value in dimensions:
        for window, seconds, fallback in (
            ("minute", 60, 120),
            ("day", 86400, 5000),
        ):
            # UTC bucket identity and Redis expiration share the business clock.
            # Counts cannot leak into the next minute/day even if cleanup lags.
            bucket = current // seconds
            key = _key(settings, f"{kind}:{window}:{name}:{bucket}", str(value))
            keys.append(key)
            expirations.append(str(seconds - current % seconds))
            limits.append(str(_safe_limit(session, f"rate.{kind}.{name}_per_{window}", fallback)))
            modes.append("count")
        if recipe_id:
            keys.append(
                _key(settings, f"detail:distinct:day:{name}:{current // 86400}", str(value))
            )
            expirations.append(str(86400 - current % 86400))
            limits.append(
                str(_safe_limit(session, f"rate.detail.{name}_distinct_recipes_per_day", 1000))
            )
            modes.append("distinct")
    try:
        result = cast(
            Any, redis.eval(_INCREMENT, len(keys), *keys, *expirations, *limits, *modes, recipe_id)
        )
        if not isinstance(result, (list, tuple)) or len(result) != 2:
            raise ValueError("invalid quota result")
    except Exception as exc:
        # Fail closed: a quota outage must not silently expose a bulk endpoint.
        raise RateLimitError(60) from exc
    if isinstance(result, (list, tuple)) and int(result[0]):
        raise RateLimitError(int(result[1]) if int(result[1]) > 0 else 60)
