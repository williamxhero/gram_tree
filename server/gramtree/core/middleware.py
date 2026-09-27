import logging
import time

from starlette.types import ASGIApp, Message, Receive, Scope, Send

from gramtree.core.errors import error_response
from gramtree.core.request_context import REQUEST_ID_HEADER, accept_or_new, set_request_id
from gramtree.observability import metrics

logger = logging.getLogger("gramtree.access")


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
        headers = {k.decode().lower(): v.decode() for k, v in scope.get("headers", [])}
        request_id = accept_or_new(headers.get(REQUEST_ID_HEADER.lower()))
        set_request_id(request_id)
        started = time.perf_counter()
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
            logger.exception("unhandled error", exc_info=exc)
            if not response_started:
                response = error_response(
                    500, "internal_error", "服务暂时出了问题，请稍后再试", type(exc).__name__
                )
                await response(scope, receive, send_wrapper)
        finally:
            duration_ms = (time.perf_counter() - started) * 1000
            route = scope.get("route")
            logger.info(
                "request",
                extra={
                    "request_id": request_id,
                    "method": scope.get("method"),
                    "path": scope.get("path"),
                    "route": getattr(route, "path", None),
                    "status": status_code,
                    "duration_ms": round(duration_ms, 1),
                },
            )
            app_state = scope.get("app")
            redis = getattr(getattr(app_state, "state", None), "redis", None)
            if redis is not None:
                metrics.record(redis, status_code, duration_ms)
            set_request_id(None)
