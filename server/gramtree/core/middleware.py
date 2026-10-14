import logging
import time
import uuid
from contextlib import suppress
from datetime import UTC, datetime

import jwt
from starlette.concurrency import run_in_threadpool
from starlette.routing import Match
from starlette.types import ASGIApp, Message, Receive, Scope, Send

from gramtree.core.access_log import record as record_access_log
from gramtree.core.errors import error_response, private_profile_boundary
from gramtree.core.request_context import REQUEST_ID_HEADER, accept_or_new, set_request_id
from gramtree.observability import metrics

logger = logging.getLogger("gramtree.access")
_CONTENT_PARAMS = {"recipe_id", "version_id", "record_id", "measure_id", "image_id"}


def _route_path(scope: Scope) -> str:
    route = scope.get("route")
    fastapi_scope = scope.get("fastapi")
    effective = (
        fastapi_scope.get("effective_route_context") if isinstance(fastapi_scope, dict) else None
    )
    template = getattr(effective, "path", None) or getattr(route, "path", None)
    if not isinstance(template, str):
        # Pre-routing risk/rate rejections still identify the finite route template,
        # never an arbitrary user-controlled path or query string.
        for candidate in getattr(scope.get("app"), "routes", []):
            match, child = candidate.matches(scope)
            if match in {Match.FULL, Match.PARTIAL} and isinstance(
                getattr(candidate, "path", None), str
            ):
                template = candidate.path
                scope["path_params"] = child.get("path_params", {})
                break
        if not isinstance(template, str):
            return "/__unmatched__"
    root_path = scope.get("root_path", "")
    if root_path and not template.startswith(root_path):
        template = f"{root_path.rstrip('/')}/{template.lstrip('/')}"
    return template if len(template) <= 255 else "/__unmatched__"


def _account_id(headers: dict[str, str], settings: object) -> uuid.UUID | None:
    authorization = headers.get("authorization", "")
    secret = getattr(settings, "auth_secret", None)
    if not authorization.lower().startswith("bearer ") or not isinstance(secret, str):
        return None
    try:
        claims = jwt.decode(authorization[7:], secret, algorithms=["HS256"])
        return uuid.UUID(str(claims["sub"]))
    except (jwt.PyJWTError, KeyError, ValueError, TypeError):
        return None


class RequestContextMiddleware:
    """给每个请求分配请求编号，写访问日志，记录耗时和状态码。

    用纯 ASGI 中间件而不是 BaseHTTPMiddleware，保证异常处理器里也能拿到请求编号。
    """

    def __init__(self, app: ASGIApp):
        self.app = app

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return
        headers = {
            k.decode("latin-1").lower(): v.decode("latin-1") for k, v in scope.get("headers", [])
        }
        request_id = accept_or_new(headers.get(REQUEST_ID_HEADER.lower()))
        set_request_id(request_id)
        started = time.perf_counter()
        created_at = datetime.now(UTC)
        status_code = 500
        response_started = False

        async def send_wrapper(message: Message) -> None:
            nonlocal status_code
            nonlocal response_started
            if message["type"] == "http.response.start":
                response_started = True
                status_code = message["status"]
                raw = [
                    (k, v) for k, v in message.get("headers", []) if k.lower() != b"x-request-id"
                ]
                raw.append((REQUEST_ID_HEADER.encode(), request_id.encode()))
                message["headers"] = raw
            await send(message)

        try:
            await self.app(scope, receive, send_wrapper)
        except Exception as exc:
            # 未处理的异常在这里转成统一错误格式，保证带上请求编号
            private = private_profile_boundary(scope.get("path", ""))
            # Traceback/exception repr can contain secrets or SQL parameters.
            logger.error("unhandled error", extra={"error_type": type(exc).__name__})
            if not response_started:
                response = error_response(
                    500,
                    "internal_error",
                    "服务暂时出了问题，请稍后再试",
                    None if private else type(exc).__name__,
                )
                await response(scope, receive, send_wrapper)
        finally:
            duration_ms = (time.perf_counter() - started) * 1000
            endpoint = _route_path(scope)
            logger.info(
                "request",
                extra={
                    "request_id": request_id,
                    "method": scope.get("method"),
                    "path": endpoint,
                    "route": endpoint if endpoint != "/__unmatched__" else None,
                    "status": status_code,
                    "duration_ms": round(duration_ms, 1),
                },
            )
            app_state = scope.get("app")
            state = getattr(app_state, "state", None)
            session_factory = getattr(state, "session_factory", None)
            settings = getattr(state, "settings", None)
            if session_factory is not None:
                client = scope.get("client")
                params = scope.get("path_params", {})
                content_ids = []
                with suppress(ValueError, TypeError, AttributeError):
                    content_ids.append(str(uuid.UUID(str(scope.get("gramtree.content_id")))))
                returned = scope.get("gramtree.content_ids", [])
                if isinstance(returned, list):
                    for value in returned[:1000]:
                        with suppress(ValueError, TypeError, AttributeError):
                            content_ids.append(str(uuid.UUID(str(value))))
                for key in _CONTENT_PARAMS:
                    value = params.get(key) if isinstance(params, dict) else None
                    try:
                        content_ids.append(str(uuid.UUID(str(value))))
                    except (ValueError, TypeError, AttributeError):
                        continue
                account_id = _account_id(headers, settings)
                with suppress(ValueError, TypeError, AttributeError):
                    account_id = uuid.UUID(str(scope.get("gramtree.account_id")))
                device_id = scope.get("gramtree.device_id") or headers.get("x-device-id", "")
                try:
                    with session_factory() as session:
                        await run_in_threadpool(
                            record_access_log,
                            session,
                            created_at=created_at,
                            request_id=request_id,
                            account_id=account_id,
                            device_id=str(device_id)[:64] or None,
                            ip_address=client[0] if client else None,
                            method=str(scope.get("method", "GET"))[:10],
                            endpoint=endpoint,
                            content_ids=list(dict.fromkeys(content_ids)),
                            status_code=status_code,
                        )
                except Exception:
                    logger.error("access log write failed", extra={"request_id": request_id})
            redis = getattr(state, "redis", None)
            if redis is not None:
                # Redis 调用会阻塞，放到线程池里，不卡住事件循环
                await run_in_threadpool(metrics.record, redis, status_code, duration_ms)
            set_request_id(None)
