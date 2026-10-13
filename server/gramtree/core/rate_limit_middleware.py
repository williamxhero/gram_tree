from __future__ import annotations

from redis import Redis
from sqlalchemy.orm import sessionmaker
from starlette.concurrency import run_in_threadpool
from starlette.types import ASGIApp, Receive, Scope, Send

from gramtree.core.errors import error_response
from gramtree.core.rate_limit import RateLimitError, enforce
from gramtree.settings import Settings


class RateLimitMiddleware:
    """Apply category quotas before a route does expensive work."""

    def __init__(
        self,
        app: ASGIApp,
        *,
        session_factory: sessionmaker,
        redis: Redis,
        settings: Settings,
    ) -> None:
        self.app = app
        self.session_factory = session_factory
        self.redis = redis
        self.settings = settings

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return
        headers = {
            key.decode("latin-1").lower(): value.decode("latin-1")
            for key, value in scope.get("headers", [])
        }
        authorization = headers.get("authorization", "")
        token = authorization[7:] if authorization.lower().startswith("bearer ") else None
        client = scope.get("client")
        ip = client[0] if client else None
        try:
            with self.session_factory() as session:
                await run_in_threadpool(
                    enforce,
                    self.redis,
                    session,
                    self.settings,
                    path=scope.get("path", ""),
                    method=scope.get("method", "GET"),
                    token=token,
                    device_id=headers.get("x-device-id"),
                    ip=ip,
                )
        except RateLimitError as exc:
            response = error_response(
                exc.status,
                exc.code,
                exc.message,
                None,
                headers=exc.headers,
            )
            await response(scope, receive, send)
            return
        await self.app(scope, receive, send)
