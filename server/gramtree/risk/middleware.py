from __future__ import annotations

import logging
from datetime import UTC, datetime

from redis import Redis
from sqlalchemy.orm import sessionmaker
from starlette.concurrency import run_in_threadpool
from starlette.types import ASGIApp, Receive, Scope, Send

from gramtree.core.errors import error_response
from gramtree.risk import service
from gramtree.risk.captcha import CaptchaAdapter
from gramtree.settings import Settings

logger = logging.getLogger("gramtree.risk")


class RiskMiddleware:
    """Apply IP/device rules before routing, without reading request bodies or secrets."""

    def __init__(
        self,
        app: ASGIApp,
        *,
        session_factory: sessionmaker,
        redis: Redis,
        settings: Settings,
        captcha: CaptchaAdapter,
    ):
        self.app = app
        self.session_factory = session_factory
        self.redis = redis
        self.settings = settings
        self.captcha = captcha

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return
        headers = {
            k.decode("latin-1").lower(): v.decode("latin-1") for k, v in scope.get("headers", [])
        }
        device_id = headers.get("x-device-id")
        client = scope.get("client")
        ip = client[0] if client else None
        path = scope.get("path", "")
        try:
            with self.session_factory() as session:
                decision = await run_in_threadpool(
                    service.observe_request,
                    self.redis,
                    session,
                    self.settings,
                    ip=ip,
                    device_id=device_id[:64] if device_id else None,
                    path=path,
                    now=datetime.now(UTC),
                    captcha=self.captcha,
                )
            if decision is not None and decision.level is not None:
                error = service.RiskActionError(
                    decision.level,
                    retry_after=decision.retry_after,
                    challenge=decision.challenge_id,
                )
                headers_out = dict(error.headers)
                if decision.retry_after is not None:
                    headers_out["Retry-After"] = str(decision.retry_after)
                response = error_response(
                    error.status, error.code, error.message, None, headers=headers_out
                )
                await response(scope, receive, send)
                return
        except Exception:
            # Protection is fail-open when Redis/PostgreSQL is unavailable; the ordinary
            # rate limiter and authentication boundary still remain active.
            logger.warning("risk evaluation unavailable", exc_info=True)
        await self.app(scope, receive, send)
