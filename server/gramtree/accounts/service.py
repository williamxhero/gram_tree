"""账号、登录和注销的业务逻辑。接口层（router）只做参数和响应的转换。"""

import hashlib
import hmac
import logging
import re
import secrets
import uuid
from dataclasses import dataclass
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

import jwt
from redis import Redis
from sqlalchemy import delete, select, update
from sqlalchemy.orm import Session

from gramtree.accounts.apple import AppleClient, AppleIdentity
from gramtree.accounts.errors import (
    AccountUnavailable,
    CodeAttemptsExceeded,
    CodeExpired,
    CodeInvalid,
    DailyLimitReached,
    IdentityTaken,
    InvalidEmail,
    InvalidNickname,
    InvalidTimezone,
    NotYourIdentity,
    ReauthRequired,
    RefreshInvalid,
    ResendTooSoon,
    TokenExpired,
    Unauthorized,
)
from gramtree.accounts.mailer import Mail, MailSender
from gramtree.accounts.models import (
    Consent,
    DeviceSession,
    EmailCode,
    Identity,
    IdentityKind,
    RefreshToken,
    User,
    UserStatus,
)
from gramtree.events.models import Event
from gramtree.recipes.measure_models import PersonalMeasure
from gramtree.runtime_config import service as config
from gramtree.settings import Settings
from gramtree.taste_profiles.models import TasteProfile

logger = logging.getLogger("gramtree.accounts")

_EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")
PURPOSES = ("login", "bind", "reauth")


# —— 小工具 ——


def normalize_email(raw: str) -> str:
    email = raw.strip().lower()
    if len(email) > 320 or not _EMAIL_RE.match(email):
        raise InvalidEmail()
    return email


def _hash(value: str, secret: str) -> str:
    return hmac.new(secret.encode(), value.encode(), hashlib.sha256).hexdigest()


def default_nickname() -> str:
    return f"味友{secrets.randbelow(10000):04d}"


def add_business_days(start: datetime, days: int) -> datetime:
    """往后数 days 个工作日（跳过周六周日；法定节假日不在这里处理）。"""
    current = start
    remaining = days
    while remaining > 0:
        current += timedelta(days=1)
        if current.weekday() < 5:
            remaining -= 1
    return current


# —— 验证码 ——


@dataclass(frozen=True)
class CodeSent:
    resend_after_seconds: int
    expires_in_seconds: int


def _rate_limit(
    redis: Redis,
    session: Session,
    email: str,
    purpose: str,
    device_id: str | None,
    ip: str | None,
    now: datetime,
) -> None:
    resend = int(config.get(session, "auth.email_code_resend_seconds"))
    daily = int(config.get(session, "auth.email_code_daily_limit"))
    # 用业务时钟记上次发送时间（不用 Redis 的过期倒计时），测试可以拨时钟
    resend_key = f"auth:last_sent:{purpose}:{email}"
    last = redis.get(resend_key)
    if last is not None:
        wait = int(float(last) + resend - now.timestamp() + 0.999)  # type: ignore[arg-type]
        if wait > 0:
            raise ResendTooSoon(wait)
    day = now.strftime("%Y%m%d")
    keys = [f"auth:daily:email:{email}:{day}"]
    if device_id:
        keys.append(f"auth:daily:device:{device_id}:{day}")
    if ip:
        keys.append(f"auth:daily:ip:{ip}:{day}")
    for key in keys:
        count = redis.get(key)
        if count is not None and int(count) >= daily:  # type: ignore[arg-type]
            raise DailyLimitReached()
    pipe = redis.pipeline()
    for key in keys:
        pipe.incr(key)
        pipe.expire(key, 2 * 24 * 3600)
    pipe.set(resend_key, str(now.timestamp()), ex=max(resend, 1))
    pipe.execute()


def send_email_code(
    session: Session,
    redis: Redis,
    mailer: MailSender,
    settings: Settings,
    *,
    email: str,
    purpose: str,
    device_id: str | None,
    ip: str | None,
    now: datetime,
) -> CodeSent:
    _rate_limit(redis, session, email, purpose, device_id, ip, now)
    ttl_minutes = int(config.get(session, "auth.email_code_ttl_minutes"))
    code = f"{secrets.randbelow(1_000_000):06d}"
    session.add(
        EmailCode(
            email=email,
            purpose=purpose,
            code_hash=_hash(f"{email}:{purpose}:{code}", settings.auth_secret),
            created_at=now,
            expires_at=now + timedelta(minutes=ttl_minutes),
        )
    )
    session.commit()
    mailer.send(
        Mail(
            to=email,
            subject=f"味谱验证码：{code}",
            body=(
                f"你的味谱验证码是 {code}，{ttl_minutes} 分钟内有效。\n"
                "如果不是你本人操作，请忽略这封邮件。"
            ),
        )
    )
    return CodeSent(
        resend_after_seconds=int(config.get(session, "auth.email_code_resend_seconds")),
        expires_in_seconds=ttl_minutes * 60,
    )


def verify_email_code(
    session: Session, settings: Settings, *, email: str, purpose: str, code: str, now: datetime
) -> None:
    """校验并消耗验证码。只认同一邮箱同一用途的最新一条。"""
    row = session.scalars(
        select(EmailCode)
        .where(EmailCode.email == email, EmailCode.purpose == purpose)
        .order_by(EmailCode.created_at.desc())
        .limit(1)
        .with_for_update()
    ).first()
    if row is None or row.consumed_at is not None:
        raise CodeInvalid(None)
    if row.expires_at <= now:
        raise CodeExpired()
    max_attempts = int(config.get(session, "auth.email_code_max_attempts"))
    if row.attempts >= max_attempts:
        raise CodeAttemptsExceeded()
    expected = _hash(f"{email}:{purpose}:{code.strip()}", settings.auth_secret)
    if not hmac.compare_digest(expected, row.code_hash):
        row.attempts += 1
        session.commit()
        left = max_attempts - row.attempts
        if left <= 0:
            raise CodeAttemptsExceeded()
        raise CodeInvalid(left)
    row.consumed_at = now
    session.flush()


# —— 令牌 ——


@dataclass(frozen=True)
class IssuedTokens:
    access_token: str
    access_expires_in: int
    refresh_token: str
    user: User


def _issue(
    session: Session, settings: Settings, user: User, device_session: DeviceSession, now: datetime
) -> IssuedTokens:
    access_minutes = int(config.get(session, "auth.access_token_minutes"))
    refresh_days = int(config.get(session, "auth.refresh_token_days"))
    access = jwt.encode(
        {
            "sub": str(user.id),
            "sid": str(device_session.id),
            "iat": int(now.timestamp()),
            "exp": int((now + timedelta(minutes=access_minutes)).timestamp()),
            "typ": "access",
        },
        settings.auth_secret,
        algorithm="HS256",
    )
    refresh = secrets.token_urlsafe(32)
    session.add(
        RefreshToken(
            session_id=device_session.id,
            token_hash=_hash(refresh, settings.auth_secret),
            created_at=now,
            expires_at=now + timedelta(days=refresh_days),
        )
    )
    session.commit()
    return IssuedTokens(access, access_minutes * 60, refresh, user)


def _start_session(
    session: Session, settings: Settings, user: User, device_id: str | None, now: datetime
) -> IssuedTokens:
    if user.status != UserStatus.active:
        raise AccountUnavailable()
    ds = DeviceSession(user_id=user.id, device_id=device_id, created_at=now)
    session.add(ds)
    session.flush()
    return _issue(session, settings, user, ds, now)


def authenticate(
    session: Session, settings: Settings, token: str, now: datetime
) -> tuple[User, DeviceSession]:
    try:
        claims = jwt.decode(
            token,
            settings.auth_secret,
            algorithms=["HS256"],
            options={"require": ["exp", "sub", "sid"], "verify_exp": False, "verify_iat": False},
        )
    except jwt.PyJWTError as exc:
        raise Unauthorized(type(exc).__name__) from exc
    if claims.get("typ") != "access":
        raise Unauthorized("wrong token type")
    if int(claims["exp"]) <= int(now.timestamp()):
        raise TokenExpired()
    try:
        sid = uuid.UUID(str(claims["sid"]))
        uid = uuid.UUID(str(claims["sub"]))
    except ValueError as exc:
        raise Unauthorized("bad claims") from exc
    ds = session.get(DeviceSession, sid)
    user = session.get(User, uid)
    if ds is None or user is None or ds.user_id != user.id:
        raise Unauthorized("unknown session")
    if ds.revoked_at is not None:
        raise Unauthorized("session revoked")
    if user.status != UserStatus.active:
        raise Unauthorized("account unavailable")
    return user, ds


def refresh(session: Session, settings: Settings, token: str, now: datetime) -> IssuedTokens:
    row = session.scalars(
        select(RefreshToken)
        .where(RefreshToken.token_hash == _hash(token, settings.auth_secret))
        .with_for_update()
    ).first()
    if row is None:
        raise RefreshInvalid()
    ds = session.get(DeviceSession, row.session_id)
    if ds is None or ds.revoked_at is not None:
        raise RefreshInvalid()
    if row.used_at is not None:
        # 已经换过的刷新令牌又出现了：可能被盗，吊销这台设备的整串令牌
        ds.revoked_at = now
        ds.revoked_reason = "refresh_reused"
        session.commit()
        logger.warning("refresh token reused; session revoked", extra={"session_id": str(ds.id)})
        raise RefreshInvalid()
    if row.expires_at <= now:
        raise RefreshInvalid()
    user = session.get(User, ds.user_id)
    if user is None or user.status != UserStatus.active:
        raise RefreshInvalid()
    row.used_at = now
    return _issue(session, settings, user, ds, now)


def logout(session: Session, ds: DeviceSession, now: datetime) -> None:
    ds.revoked_at = now
    ds.revoked_reason = "logout"
    session.commit()


# —— 登录 ——


def _user_for_identity(session: Session, kind: IdentityKind, subject: str) -> User | None:
    identity = session.scalars(
        select(Identity).where(Identity.kind == kind, Identity.subject == subject)
    ).first()
    return None if identity is None else session.get(User, identity.user_id)


def login_with_email(
    session: Session,
    settings: Settings,
    *,
    email: str,
    code: str,
    device_id: str | None,
    now: datetime,
) -> IssuedTokens:
    verify_email_code(session, settings, email=email, purpose="login", code=code, now=now)
    user = _user_for_identity(session, IdentityKind.email, email)
    if user is None:
        # 首次登录即创建账号
        user = User(nickname=default_nickname(), created_at=now)
        session.add(user)
        session.flush()
        session.add(
            Identity(
                user_id=user.id, kind=IdentityKind.email, subject=email, email=email, created_at=now
            )
        )
        session.flush()
    return _start_session(session, settings, user, device_id, now)


def _apple_nickname(given: str | None, family: str | None) -> str | None:
    parts = [p.strip() for p in (family, given) if p and p.strip()]
    if not parts:
        return None
    # 中文名习惯姓在前、不加空格；拉丁字母名按名在前、空格分隔
    if all(re.fullmatch(r"[㐀-鿿]+", p) for p in parts):
        return "".join(parts)
    return " ".join(reversed(parts))


def login_with_apple(
    session: Session,
    settings: Settings,
    apple: AppleClient,
    *,
    identity_token: str,
    authorization_code: str | None,
    given_name: str | None,
    family_name: str | None,
    device_id: str | None,
    now: datetime,
) -> IssuedTokens:
    info = apple.verify_identity_token(identity_token, now.timestamp())
    user = _user_for_identity(session, IdentityKind.apple, info.subject)
    if user is None:
        max_len = int(config.get(session, "account.nickname_max_length"))
        name = _apple_nickname(given_name, family_name)
        user = User(
            nickname=(name[:max_len] if name else default_nickname()),
            created_at=now,
        )
        session.add(user)
        session.flush()
        _add_apple_identity(session, apple, user, info, authorization_code, now)
    elif authorization_code:
        _refresh_apple_grant(session, apple, info.subject, authorization_code)
    return _start_session(session, settings, user, device_id, now)


def _add_apple_identity(
    session: Session,
    apple: AppleClient,
    user: User,
    info: AppleIdentity,
    authorization_code: str | None,
    now: datetime,
) -> Identity:
    identity = Identity(
        user_id=user.id,
        kind=IdentityKind.apple,
        subject=info.subject,
        email=info.email,
        apple_refresh_token=apple.exchange_code(authorization_code) if authorization_code else None,
        created_at=now,
    )
    session.add(identity)
    session.flush()
    return identity


def _refresh_apple_grant(session: Session, apple: AppleClient, subject: str, code: str) -> None:
    token = apple.exchange_code(code)
    if token:
        session.execute(
            update(Identity)
            .where(Identity.kind == IdentityKind.apple, Identity.subject == subject)
            .values(apple_refresh_token=token)
        )


# —— 绑定登录方式 ——


def ensure_identity_free(session: Session, kind: IdentityKind, subject: str, user: User) -> None:
    owner = _user_for_identity(session, kind, subject)
    if owner is not None and owner.id != user.id:
        raise IdentityTaken()


def bind_email(
    session: Session, settings: Settings, user: User, *, email: str, code: str, now: datetime
) -> None:
    ensure_identity_free(session, IdentityKind.email, email, user)
    verify_email_code(session, settings, email=email, purpose="bind", code=code, now=now)
    if _user_for_identity(session, IdentityKind.email, email) is None:
        session.add(
            Identity(
                user_id=user.id, kind=IdentityKind.email, subject=email, email=email, created_at=now
            )
        )
    session.commit()


def bind_apple(
    session: Session,
    apple: AppleClient,
    user: User,
    *,
    identity_token: str,
    authorization_code: str | None,
    now: datetime,
) -> None:
    info = apple.verify_identity_token(identity_token, now.timestamp())
    ensure_identity_free(session, IdentityKind.apple, info.subject, user)
    if _user_for_identity(session, IdentityKind.apple, info.subject) is None:
        _add_apple_identity(session, apple, user, info, authorization_code, now)
    elif authorization_code:
        _refresh_apple_grant(session, apple, info.subject, authorization_code)
    session.commit()


def identities(session: Session, user: User) -> list[Identity]:
    return list(
        session.scalars(
            select(Identity).where(Identity.user_id == user.id).order_by(Identity.created_at)
        )
    )


# —— 重新验证身份 ——


def user_owns_email(session: Session, user: User, email: str) -> bool:
    owner = _user_for_identity(session, IdentityKind.email, email)
    return owner is not None and owner.id == user.id


def reauth_with_email(
    session: Session,
    settings: Settings,
    user: User,
    ds: DeviceSession,
    *,
    email: str,
    code: str,
    now: datetime,
) -> None:
    if not user_owns_email(session, user, email):
        raise NotYourIdentity()
    verify_email_code(session, settings, email=email, purpose="reauth", code=code, now=now)
    ds.reauthenticated_at = now
    session.commit()


def reauth_with_apple(
    session: Session,
    apple: AppleClient,
    user: User,
    ds: DeviceSession,
    *,
    identity_token: str,
    now: datetime,
) -> None:
    info = apple.verify_identity_token(identity_token, now.timestamp())
    owner = _user_for_identity(session, IdentityKind.apple, info.subject)
    if owner is None or owner.id != user.id:
        raise NotYourIdentity()
    ds.reauthenticated_at = now
    session.commit()


def require_recent_reauth(session: Session, ds: DeviceSession, now: datetime) -> None:
    window = int(config.get(session, "auth.reauth_window_minutes"))
    if ds.reauthenticated_at is None or ds.reauthenticated_at < now - timedelta(minutes=window):
        raise ReauthRequired()


# —— 资料 ——


def update_profile(
    session: Session, user: User, *, nickname: str | None, timezone: str | None
) -> User:
    if nickname is not None:
        name = nickname.strip()
        max_len = int(config.get(session, "account.nickname_max_length"))
        if not name:
            raise InvalidNickname("昵称不能为空")
        if len(name) > max_len:
            raise InvalidNickname(f"昵称最多 {max_len} 个字")
        user.nickname = name
    if timezone is not None:
        try:
            ZoneInfo(timezone)
        except (ZoneInfoNotFoundError, ValueError) as exc:
            raise InvalidTimezone() from exc
        user.timezone = timezone
    session.commit()
    return user


# —— 同意记录 ——


@dataclass(frozen=True)
class ConsentInput:
    id: uuid.UUID
    kind: str
    version: str
    action: str
    occurred_at: datetime
    device_id: str | None


def record_consents(
    session: Session, user: User, records: list[ConsentInput], now: datetime
) -> None:
    from gramtree.taste_profiles import allergies
    from gramtree.taste_profiles import service as taste_service

    profile = taste_service.locked_profile(session, user.id, taste_service.scale_for(session))
    for r in records:
        existing = session.get(Consent, r.id)
        if existing is not None:
            continue  # 同一条重复上传，按 ID 去重
        session.add(
            Consent(
                id=r.id,
                user_id=user.id,
                kind=r.kind,
                version=r.version,
                action=r.action,
                occurred_at=r.occurred_at,
                device_id=r.device_id,
                received_at=now,
            )
        )
    session.flush()
    allergies.refresh_authorization(session, profile, now)
    session.commit()


def consents(session: Session, user: User) -> list[Consent]:
    return list(
        session.scalars(
            select(Consent)
            .where(Consent.user_id == user.id)
            .order_by(Consent.occurred_at, Consent.received_at)
        )
    )


# —— 注销 ——


def request_deletion(
    session: Session, apple: AppleClient, user: User, ds: DeviceSession, now: datetime
) -> User:
    require_recent_reauth(session, ds, now)
    days = int(config.get(session, "account.deletion_business_days"))
    user.status = UserStatus.deleting
    user.deletion_requested_at = now
    user.deletion_due_at = add_business_days(now, days)
    # 所有设备立即退出
    session.execute(
        update(DeviceSession)
        .where(DeviceSession.user_id == user.id, DeviceSession.revoked_at.is_(None))
        .values(revoked_at=now, revoked_reason="account_deleted")
    )
    # App Store 要求：用 Apple 登录的账号注销时撤销授权
    for identity in identities(session, user):
        token = identity.apple_refresh_token
        if identity.kind == IdentityKind.apple and token and apple.revoke(token):
            identity.apple_refresh_token = None
    session.commit()
    return user


def purge_due_accounts(session: Session, apple: AppleClient, now: datetime) -> int:
    """删除到期的注销中账号的个人数据。账号行保留为“已注销”，ID 不复用。"""
    due = list(
        session.scalars(
            select(User).where(User.status == UserStatus.deleting, User.deletion_due_at <= now)
        )
    )
    for user in due:
        ids = identities(session, user)
        for identity in ids:
            # 注销时撤销失败的，这里再试一次
            if identity.apple_refresh_token:
                apple.revoke(identity.apple_refresh_token)
        emails = [i.subject for i in ids if i.kind == IdentityKind.email]
        if emails:
            session.execute(delete(EmailCode).where(EmailCode.email.in_(emails)))
        session.execute(delete(Identity).where(Identity.user_id == user.id))
        session.execute(delete(Consent).where(Consent.user_id == user.id))
        session.execute(delete(PersonalMeasure).where(PersonalMeasure.owner_id == user.id))
        session.execute(
            delete(Event).where(
                Event.user_id == user.id, Event.correlation.has_key("taste_profile_change_id")
            )
        )
        session.execute(delete(TasteProfile).where(TasteProfile.owner_id == user.id))
        session_ids = select(DeviceSession.id).where(DeviceSession.user_id == user.id)
        session.execute(delete(RefreshToken).where(RefreshToken.session_id.in_(session_ids)))
        session.execute(delete(DeviceSession).where(DeviceSession.user_id == user.id))
        user.nickname = "已注销用户"
        user.phone = None
        user.status = UserStatus.deleted
        user.deleted_at = now
    session.commit()
    if due:
        logger.info("purged deleted accounts", extra={"count": len(due)})
    return len(due)
