"""需要登录的接口统一用 CurrentAuth 取当前用户，未登录时返回统一的 401 错误。"""

from dataclasses import dataclass
from typing import Annotated, Literal

from fastapi import Depends, Header, Request
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from gramtree.accounts import service
from gramtree.accounts.apple import AppleClient
from gramtree.accounts.errors import Unauthorized
from gramtree.accounts.mailer import MailSender
from gramtree.accounts.models import DeviceSession, User
from gramtree.accounts.signing import SignatureError
from gramtree.accounts.signing import verify as verify_request_signature
from gramtree.core.clock import ClockDep
from gramtree.deps import RedisDep, SessionDep, SettingsDep
from gramtree.risk import service as risk_service
from gramtree.runtime_config import service as config

DEVICE_ID_HEADER = "X-Device-ID"

_bearer = HTTPBearer(auto_error=False, description="登录后拿到的访问令牌")


@dataclass(frozen=True)
class AuthContext:
    user: User
    device_session: DeviceSession


async def get_identity_auth(
    request: Request,
    session: SessionDep,
    redis: RedisDep,
    settings: SettingsDep,
    clock: ClockDep,
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(_bearer)],
    signature: Annotated[
        str | None, Header(alias="X-Request-Signature", description="HMAC-SHA256 请求签名")
    ] = None,
    timestamp: Annotated[
        str | None, Header(alias="X-Request-Timestamp", description="Unix 秒时间戳")
    ] = None,
    nonce: Annotated[
        str | None, Header(alias="X-Request-Nonce", description="每次请求唯一的随机数")
    ] = None,
    device_id: Annotated[
        str | None, Header(alias="X-Device-ID", description="登录时的设备安装 ID")
    ] = None,
) -> AuthContext:
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise Unauthorized("missing bearer token")
    user, ds = service.authenticate(
        session, settings, credentials.credentials, clock(), enforce_risk_ban=False
    )
    request.scope["gramtree.account_id"] = str(user.id)
    request.scope["gramtree.device_id"] = ds.device_id
    # Read the body through Starlette's cache so downstream Pydantic parsing sees
    # the same bytes that were authenticated here.
    body = await request.body()
    headers = {key.lower(): value for key, value in request.headers.items()}
    try:
        verify_request_signature(
            redis,
            ds,
            settings.auth_secret,
            headers=headers,
            method=request.method,
            path=request.url.path,
            query=request.scope.get("query_string", b"").decode("latin-1"),
            body=body,
            now=clock(),
            tolerance_seconds=max(
                1, int(config.get(session, "auth.signing_clock_tolerance_seconds"))
            ),
            nonce_ttl_seconds=max(1, int(config.get(session, "auth.signing_nonce_ttl_seconds"))),
        )
    except SignatureError as exc:
        rule = "nonce_replay" if exc.code == "nonce_replayed" else "signature_failure"
        subjects: tuple[tuple[Literal["account", "device", "ip"], str | None], ...] = (
            ("account", str(user.id)),
            ("device", ds.device_id),
            ("ip", request.client.host if request.client else None),
        )
        for kind, value in subjects:
            if value:
                risk_service.record_security_failure(
                    redis,
                    session,
                    settings,
                    subject_type=kind,
                    subject_value=value,
                    rule=rule,
                    now=clock(),
                    captcha=request.app.state.captcha,
                )
        raise
    return AuthContext(user, ds)


IdentityAuth = Annotated[AuthContext, Depends(get_identity_auth)]


async def get_auth(
    request: Request,
    session: SessionDep,
    redis: RedisDep,
    settings: SettingsDep,
    clock: ClockDep,
    auth: IdentityAuth,
) -> AuthContext:
    if risk_service.is_permanently_banned(
        session,
        settings,
        user_id=str(auth.user.id),
        device_id=auth.device_session.device_id,
        now=clock(),
    ):
        raise Unauthorized("account unavailable")
    decision = risk_service.observe_account(
        redis,
        session,
        settings,
        user_id=str(auth.user.id),
        device_id=auth.device_session.device_id,
        ip=request.client.host if request.client else None,
        path=request.url.path,
        now=clock(),
        captcha=request.app.state.captcha,
    )
    if decision is not None and decision.level is not None:
        raise risk_service.RiskActionError(
            decision.level, retry_after=decision.retry_after, challenge=decision.challenge_id
        )
    return auth


CurrentAuth = Annotated[AuthContext, Depends(get_auth)]


async def get_optional_auth(
    request: Request,
    session: SessionDep,
    redis: RedisDep,
    settings: SettingsDep,
    clock: ClockDep,
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(_bearer)],
) -> AuthContext | None:
    """带了令牌就校验，没带返回 None（给登录前后都能调用的接口用）。"""
    if credentials is None:
        if request.headers.get("authorization"):
            raise Unauthorized("invalid authorization header")
        return None
    identity = await get_identity_auth(request, session, redis, settings, clock, credentials)
    return await get_auth(request, session, redis, settings, clock, identity)


OptionalAuth = Annotated[AuthContext | None, Depends(get_optional_auth)]


async def get_optional_identity_auth(
    request: Request,
    session: SessionDep,
    redis: RedisDep,
    settings: SettingsDep,
    clock: ClockDep,
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(_bearer)],
) -> AuthContext | None:
    if credentials is None:
        if request.headers.get("authorization"):
            raise Unauthorized("invalid authorization header")
        return None
    return await get_identity_auth(request, session, redis, settings, clock, credentials)


OptionalIdentityAuth = Annotated[AuthContext | None, Depends(get_optional_identity_auth)]


def get_mailer(request: Request) -> MailSender:
    return request.app.state.mailer


def get_apple(request: Request) -> AppleClient:
    return request.app.state.apple


def get_device_id(request: Request) -> str | None:
    """App 安装时生成的设备 ID，放在请求头里；用来按设备限流和区分登录设备。"""
    value = request.headers.get(DEVICE_ID_HEADER)
    return value[:64] if value else None


def get_client_ip(request: Request) -> str | None:
    return request.client.host if request.client else None


MailerDep = Annotated[MailSender, Depends(get_mailer)]
AppleDep = Annotated[AppleClient, Depends(get_apple)]
DeviceIdDep = Annotated[str | None, Depends(get_device_id)]
ClientIpDep = Annotated[str | None, Depends(get_client_ip)]
