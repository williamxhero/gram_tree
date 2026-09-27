from typing import Any, Literal

from fastapi import APIRouter, status
from pydantic import BaseModel, Field

from gramtree.accounts import service
from gramtree.accounts.deps import (
    AppleDep,
    ClientIpDep,
    CurrentAuth,
    DeviceIdDep,
    MailerDep,
    OptionalAuth,
)
from gramtree.accounts.errors import NotYourIdentity, Unauthorized
from gramtree.accounts.models import Identity, IdentityKind, User
from gramtree.core.clock import ClockDep
from gramtree.core.errors import ERROR_RESPONSES, ErrorResponse
from gramtree.core.ids import IdV4
from gramtree.core.time import Timestamp
from gramtree.deps import RedisDep, SessionDep, SettingsDep

router = APIRouter(tags=["auth"])
me_router = APIRouter(tags=["account"])


def _errors(*codes: int) -> dict[int | str, dict[str, Any]]:
    out: dict[int | str, dict[str, Any]] = dict(ERROR_RESPONSES)
    for code in codes:
        out[code] = {"model": ErrorResponse}
    return out


# —— 模型 ——


class UserOut(BaseModel):
    id: str
    nickname: str
    timezone: str
    status: Literal["active", "deleting", "deleted"]
    phone: str | None = Field(description="预留：手机号登录（SPEC-011）")
    real_name_status: Literal["none", "pending", "verified"] = Field(
        description="预留：发布内容实名状态（SPEC-011）"
    )
    created_at: Timestamp

    @classmethod
    def of(cls, user: User) -> "UserOut":
        return cls(
            id=str(user.id),
            nickname=user.nickname,
            timezone=user.timezone,
            status=user.status.value,
            phone=user.phone,
            real_name_status=user.real_name_status.value,
            created_at=user.created_at,
        )


class TokenPair(BaseModel):
    access_token: str
    access_expires_in: int = Field(description="访问令牌多少秒后过期")
    refresh_token: str = Field(description="续期用；每次续期都会换发新的，旧的立即作废")
    user: UserOut

    @classmethod
    def of(cls, issued: service.IssuedTokens) -> "TokenPair":
        return cls(
            access_token=issued.access_token,
            access_expires_in=issued.access_expires_in,
            refresh_token=issued.refresh_token,
            user=UserOut.of(issued.user),
        )


class EmailCodeRequest(BaseModel):
    email: str
    purpose: Literal["login", "bind", "reauth"] = "login"


class EmailCodeSent(BaseModel):
    resend_after_seconds: int
    expires_in_seconds: int


class EmailLoginRequest(BaseModel):
    email: str
    code: str = Field(min_length=6, max_length=6)


class AppleLoginRequest(BaseModel):
    identity_token: str
    authorization_code: str | None = None
    given_name: str | None = Field(default=None, description="首次授权时 Apple 给的名字")
    family_name: str | None = None


class RefreshRequest(BaseModel):
    refresh_token: str


class EmailReauthRequest(BaseModel):
    email: str
    code: str = Field(min_length=6, max_length=6)


class AppleReauthRequest(BaseModel):
    identity_token: str


class ProfileUpdate(BaseModel):
    nickname: str | None = None
    timezone: str | None = Field(default=None, description="IANA 时区名，如 Asia/Shanghai")


class IdentityOut(BaseModel):
    kind: Literal["email", "apple", "phone", "wechat"]
    email: str | None
    created_at: Timestamp

    @classmethod
    def of(cls, identity: Identity) -> "IdentityOut":
        return cls(kind=identity.kind.value, email=identity.email, created_at=identity.created_at)


class BindEmailRequest(BaseModel):
    email: str
    code: str = Field(min_length=6, max_length=6)


class BindAppleRequest(BaseModel):
    identity_token: str
    authorization_code: str | None = None


ConsentKind = Literal["terms", "privacy", "sensitive_personal_info", "product_analytics"]


class ConsentRecord(BaseModel):
    id: IdV4 = Field(description="客户端生成的 UUID v4，重复上传按它去重")
    kind: ConsentKind
    version: str = Field(min_length=1, max_length=32)
    action: Literal["agree", "withdraw"]
    occurred_at: Timestamp
    device_id: str | None = Field(default=None, max_length=64)


class ConsentUpload(BaseModel):
    records: list[ConsentRecord] = Field(max_length=100)


class DeletionOut(BaseModel):
    status: Literal["active", "deleting", "deleted"]
    deletion_due_at: Timestamp | None


# —— 登录 ——


@router.post(
    "/auth/email/code",
    response_model=EmailCodeSent,
    responses=_errors(401, 403, 409, 429),
    summary="发送邮箱验证码",
    description="purpose=login 不需要登录；bind（绑定新邮箱）和 reauth（重新验证身份）需要登录。",
)
def send_email_code(
    body: EmailCodeRequest,
    session: SessionDep,
    redis: RedisDep,
    settings: SettingsDep,
    mailer: MailerDep,
    clock: ClockDep,
    device_id: DeviceIdDep,
    ip: ClientIpDep,
    auth: OptionalAuth,
) -> EmailCodeSent:
    email = service.normalize_email(body.email)
    if body.purpose != "login":
        if auth is None:
            raise Unauthorized("login required for this purpose")
        if body.purpose == "reauth" and not service.user_owns_email(session, auth.user, email):
            raise NotYourIdentity()
        if body.purpose == "bind":
            service.ensure_identity_free(session, IdentityKind.email, email, auth.user)
    sent = service.send_email_code(
        session,
        redis,
        mailer,
        settings,
        email=email,
        purpose=body.purpose,
        device_id=device_id,
        ip=ip,
        now=clock(),
    )
    return EmailCodeSent(
        resend_after_seconds=sent.resend_after_seconds, expires_in_seconds=sent.expires_in_seconds
    )


@router.post(
    "/auth/email/login",
    response_model=TokenPair,
    responses=_errors(400, 403),
    summary="用邮箱验证码登录（首次登录自动创建账号）",
)
def email_login(
    body: EmailLoginRequest,
    session: SessionDep,
    settings: SettingsDep,
    clock: ClockDep,
    device_id: DeviceIdDep,
) -> TokenPair:
    issued = service.login_with_email(
        session,
        settings,
        email=service.normalize_email(body.email),
        code=body.code,
        device_id=device_id,
        now=clock(),
    )
    return TokenPair.of(issued)


@router.post(
    "/auth/apple/login",
    response_model=TokenPair,
    responses=_errors(401, 403, 503),
    summary="通过 Apple 登录（首次登录自动创建账号）",
)
def apple_login(
    body: AppleLoginRequest,
    session: SessionDep,
    settings: SettingsDep,
    apple: AppleDep,
    clock: ClockDep,
    device_id: DeviceIdDep,
) -> TokenPair:
    issued = service.login_with_apple(
        session,
        settings,
        apple,
        identity_token=body.identity_token,
        authorization_code=body.authorization_code,
        given_name=body.given_name,
        family_name=body.family_name,
        device_id=device_id,
        now=clock(),
    )
    return TokenPair.of(issued)


@router.post(
    "/auth/refresh",
    response_model=TokenPair,
    responses=_errors(401),
    summary="用刷新令牌续期",
    description="每次续期都换发新的刷新令牌。旧的刷新令牌再被使用时，这台设备的登录全部失效。",
)
def refresh_tokens(
    body: RefreshRequest, session: SessionDep, settings: SettingsDep, clock: ClockDep
) -> TokenPair:
    return TokenPair.of(service.refresh(session, settings, body.refresh_token, clock()))


@router.post(
    "/auth/logout",
    status_code=status.HTTP_204_NO_CONTENT,
    responses=_errors(401),
    summary="退出当前设备的登录",
)
def logout(auth: CurrentAuth, session: SessionDep, clock: ClockDep) -> None:
    service.logout(session, auth.device_session, clock())


@router.post(
    "/auth/reauth/email",
    status_code=status.HTTP_204_NO_CONTENT,
    responses=_errors(400, 401, 403),
    summary="用邮箱验证码重新验证身份（注销账号等敏感操作前）",
)
def reauth_email(
    body: EmailReauthRequest,
    auth: CurrentAuth,
    session: SessionDep,
    settings: SettingsDep,
    clock: ClockDep,
) -> None:
    service.reauth_with_email(
        session,
        settings,
        auth.user,
        auth.device_session,
        email=service.normalize_email(body.email),
        code=body.code,
        now=clock(),
    )


@router.post(
    "/auth/reauth/apple",
    status_code=status.HTTP_204_NO_CONTENT,
    responses=_errors(401, 403, 503),
    summary="通过 Apple 重新验证身份",
)
def reauth_apple(
    body: AppleReauthRequest,
    auth: CurrentAuth,
    session: SessionDep,
    apple: AppleDep,
    clock: ClockDep,
) -> None:
    service.reauth_with_apple(
        session,
        apple,
        auth.user,
        auth.device_session,
        identity_token=body.identity_token,
        now=clock(),
    )


# —— 我的账号 ——


@me_router.get("/me", response_model=UserOut, responses=_errors(401), summary="当前账号")
def get_me(auth: CurrentAuth) -> UserOut:
    return UserOut.of(auth.user)


@me_router.patch("/me", response_model=UserOut, responses=_errors(401), summary="修改昵称或时区")
def update_me(body: ProfileUpdate, auth: CurrentAuth, session: SessionDep) -> UserOut:
    user = service.update_profile(
        session, auth.user, nickname=body.nickname, timezone=body.timezone
    )
    return UserOut.of(user)


@me_router.get(
    "/me/identities",
    response_model=list[IdentityOut],
    responses=_errors(401),
    summary="已绑定的登录方式",
)
def list_identities(auth: CurrentAuth, session: SessionDep) -> list[IdentityOut]:
    return [IdentityOut.of(i) for i in service.identities(session, auth.user)]


@me_router.post(
    "/me/identities/email",
    response_model=list[IdentityOut],
    responses=_errors(400, 401, 409),
    summary="绑定邮箱",
)
def bind_email(
    body: BindEmailRequest,
    auth: CurrentAuth,
    session: SessionDep,
    settings: SettingsDep,
    clock: ClockDep,
) -> list[IdentityOut]:
    service.bind_email(
        session,
        settings,
        auth.user,
        email=service.normalize_email(body.email),
        code=body.code,
        now=clock(),
    )
    return [IdentityOut.of(i) for i in service.identities(session, auth.user)]


@me_router.post(
    "/me/identities/apple",
    response_model=list[IdentityOut],
    responses=_errors(401, 409, 503),
    summary="绑定 Apple",
)
def bind_apple(
    body: BindAppleRequest,
    auth: CurrentAuth,
    session: SessionDep,
    apple: AppleDep,
    clock: ClockDep,
) -> list[IdentityOut]:
    service.bind_apple(
        session,
        apple,
        auth.user,
        identity_token=body.identity_token,
        authorization_code=body.authorization_code,
        now=clock(),
    )
    return [IdentityOut.of(i) for i in service.identities(session, auth.user)]


@me_router.get(
    "/me/consents",
    response_model=list[ConsentRecord],
    responses=_errors(401),
    summary="我的同意记录",
)
def list_consents(auth: CurrentAuth, session: SessionDep) -> list[ConsentRecord]:
    return [
        ConsentRecord(
            id=c.id,
            kind=c.kind,  # type: ignore[arg-type]
            version=c.version,
            action=c.action,  # type: ignore[arg-type]
            occurred_at=c.occurred_at,
            device_id=c.device_id,
        )
        for c in service.consents(session, auth.user)
    ]


@me_router.post(
    "/me/consents",
    status_code=status.HTTP_204_NO_CONTENT,
    responses=_errors(401),
    summary="上传同意或撤回记录（登录前存在本机的，登录后补传）",
)
def upload_consents(
    body: ConsentUpload, auth: CurrentAuth, session: SessionDep, clock: ClockDep
) -> None:
    service.record_consents(
        session,
        auth.user,
        [
            service.ConsentInput(
                id=r.id,
                kind=r.kind,
                version=r.version,
                action=r.action,
                occurred_at=r.occurred_at,
                device_id=r.device_id,
            )
            for r in body.records
        ],
        clock(),
    )


@me_router.post(
    "/me/deletion",
    response_model=DeletionOut,
    status_code=status.HTTP_202_ACCEPTED,
    responses=_errors(401, 403),
    summary="注销账号",
    description=(
        "要求最近几分钟内重新验证过身份。成功后所有设备立即退出，账号变为注销中，"
        "个人数据在期限内由后台删除。"
    ),
)
def request_deletion(
    auth: CurrentAuth, session: SessionDep, apple: AppleDep, clock: ClockDep
) -> DeletionOut:
    user = service.request_deletion(session, apple, auth.user, auth.device_session, clock())
    return DeletionOut(status=user.status.value, deletion_due_at=user.deletion_due_at)
