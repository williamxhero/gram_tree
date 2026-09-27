"""需要登录的接口统一用 CurrentAuth 取当前用户，未登录时返回统一的 401 错误。"""

from dataclasses import dataclass
from typing import Annotated

from fastapi import Depends, Request
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from gramtree.accounts import service
from gramtree.accounts.apple import AppleClient
from gramtree.accounts.errors import Unauthorized
from gramtree.accounts.mailer import MailSender
from gramtree.accounts.models import DeviceSession, User
from gramtree.core.clock import ClockDep
from gramtree.deps import SessionDep, SettingsDep

DEVICE_ID_HEADER = "X-Device-ID"

_bearer = HTTPBearer(auto_error=False, description="登录后拿到的访问令牌")


@dataclass(frozen=True)
class AuthContext:
    user: User
    device_session: DeviceSession


def get_auth(
    session: SessionDep,
    settings: SettingsDep,
    clock: ClockDep,
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(_bearer)],
) -> AuthContext:
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise Unauthorized("missing bearer token")
    user, ds = service.authenticate(session, settings, credentials.credentials, clock())
    return AuthContext(user, ds)


CurrentAuth = Annotated[AuthContext, Depends(get_auth)]


def get_optional_auth(
    session: SessionDep,
    settings: SettingsDep,
    clock: ClockDep,
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(_bearer)],
) -> AuthContext | None:
    """带了令牌就校验，没带返回 None（给登录前后都能调用的接口用）。"""
    if credentials is None:
        return None
    return get_auth(session, settings, clock, credentials)


OptionalAuth = Annotated[AuthContext | None, Depends(get_optional_auth)]


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
