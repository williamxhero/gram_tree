"""账号数据表。

用户和登录身份分开存：一个用户可以绑定多种登录方式（邮箱、Apple，以后手机号、微信），
换登录方式不用迁移用户数据。
"""

import enum
import uuid
from datetime import datetime

from sqlalchemy import Enum, ForeignKey, Index, Integer, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from gramtree.core.ids import new_id
from gramtree.core.time import utcnow
from gramtree.db import Base


def _enum(cls: type[enum.Enum], name: str) -> Enum:
    # 数据库里存枚举的值（小写字符串），不存名字
    return Enum(
        cls,
        name=name,
        native_enum=False,
        length=32,
        values_callable=lambda e: [m.value for m in e],
    )


class UserStatus(enum.StrEnum):
    active = "active"
    deleting = "deleting"
    deleted = "deleted"


class RealNameStatus(enum.StrEnum):
    """发布内容实名（SPEC-011）。字段从第一天预留，阶段一一直是 none。"""

    none = "none"
    pending = "pending"
    verified = "verified"


class IdentityKind(enum.StrEnum):
    email = "email"
    apple = "apple"
    phone = "phone"
    wechat = "wechat"


class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=new_id)
    nickname: Mapped[str] = mapped_column(String(64))
    timezone: Mapped[str] = mapped_column(String(64), default="Asia/Shanghai")
    status: Mapped[UserStatus] = mapped_column(
        _enum(UserStatus, "user_status"), default=UserStatus.active
    )
    # 预留：手机号（国内上线前的手机号登录）和实名状态
    phone: Mapped[str | None] = mapped_column(String(32), default=None)
    real_name_status: Mapped[RealNameStatus] = mapped_column(
        _enum(RealNameStatus, "real_name_status"), default=RealNameStatus.none
    )
    created_at: Mapped[datetime] = mapped_column(default=utcnow)
    deletion_requested_at: Mapped[datetime | None] = mapped_column(default=None)
    deletion_due_at: Mapped[datetime | None] = mapped_column(default=None)
    deleted_at: Mapped[datetime | None] = mapped_column(default=None)


class Identity(Base):
    """一种登录方式。同一个身份（类型 + 标识）只能属于一个用户。"""

    __tablename__ = "identities"
    __table_args__ = (UniqueConstraint("kind", "subject", name="uq_identities_kind_subject"),)

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=new_id)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    kind: Mapped[IdentityKind] = mapped_column(_enum(IdentityKind, "identity_kind"))
    # 邮箱：规范化后的地址；Apple：Apple 给的用户标识（sub）
    subject: Mapped[str] = mapped_column(String(320))
    # 展示用的邮箱（Apple 可能是隐藏邮箱的中转地址）
    email: Mapped[str | None] = mapped_column(String(320), default=None)
    # Apple 的刷新令牌，注销账号时用来撤销授权
    apple_refresh_token: Mapped[str | None] = mapped_column(Text, default=None)
    created_at: Mapped[datetime] = mapped_column(default=utcnow)


class EmailCode(Base):
    """发出的邮箱验证码。只存哈希；同一邮箱同一用途只有最新一条有效。"""

    __tablename__ = "email_codes"
    __table_args__ = (Index("ix_email_codes_email_purpose", "email", "purpose", "created_at"),)

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=new_id)
    email: Mapped[str] = mapped_column(String(320))
    purpose: Mapped[str] = mapped_column(String(16))
    code_hash: Mapped[str] = mapped_column(String(128))
    attempts: Mapped[int] = mapped_column(Integer, default=0)
    created_at: Mapped[datetime] = mapped_column(default=utcnow)
    expires_at: Mapped[datetime]
    consumed_at: Mapped[datetime | None] = mapped_column(default=None)


class DeviceSession(Base):
    """一台设备上的一次登录，对应一串刷新令牌。退出登录只吊销当前这一串。"""

    __tablename__ = "device_sessions"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=new_id)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    device_id: Mapped[str | None] = mapped_column(String(64), default=None)
    created_at: Mapped[datetime] = mapped_column(default=utcnow)
    # 最近一次重新验证身份的时间（敏感操作要求在时间窗内）
    reauthenticated_at: Mapped[datetime | None] = mapped_column(default=None)
    revoked_at: Mapped[datetime | None] = mapped_column(default=None)
    revoked_reason: Mapped[str | None] = mapped_column(String(32), default=None)


class RefreshToken(Base):
    """刷新令牌只存哈希。每次续期把旧的标记为已用并换发新的；已用的再出现就是被盗用。"""

    __tablename__ = "refresh_tokens"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=new_id)
    session_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("device_sessions.id"), index=True)
    token_hash: Mapped[str] = mapped_column(String(128), unique=True)
    created_at: Mapped[datetime] = mapped_column(default=utcnow)
    expires_at: Mapped[datetime]
    used_at: Mapped[datetime | None] = mapped_column(default=None)


class Consent(Base):
    """同意记录：按类型和版本保存每一次同意或撤回。"""

    __tablename__ = "consents"

    # 客户端生成的 UUID，重复上传按它去重
    id: Mapped[uuid.UUID] = mapped_column(primary_key=True)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    kind: Mapped[str] = mapped_column(String(32))
    version: Mapped[str] = mapped_column(String(32))
    action: Mapped[str] = mapped_column(String(16))
    occurred_at: Mapped[datetime]
    device_id: Mapped[str | None] = mapped_column(String(64), default=None)
    received_at: Mapped[datetime] = mapped_column(default=utcnow)
