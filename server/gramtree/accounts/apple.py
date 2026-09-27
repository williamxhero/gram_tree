"""通过 Apple 登录：校验身份令牌、用授权码换刷新令牌、注销时撤销授权。

和 Apple 的网络交互都在 AppleTransport 里，测试换成假的；令牌校验逻辑用真的。
"""

import logging
import time
from dataclasses import dataclass
from typing import Any, Protocol

import httpx
import jwt

from gramtree.core.errors import ApiError
from gramtree.settings import Settings

logger = logging.getLogger("gramtree.accounts.apple")

APPLE_ISSUER = "https://appleid.apple.com"


class AppleTransport(Protocol):
    def get_keys(self) -> dict[str, Any]:
        """Apple 的公钥（JWKS）。"""
        ...

    def exchange_code(self, client_id: str, client_secret: str, code: str) -> dict[str, Any]: ...

    def revoke(self, client_id: str, client_secret: str, refresh_token: str) -> None: ...


class HttpAppleTransport:
    def __init__(self) -> None:
        self._keys: dict[str, Any] | None = None
        self._keys_at = 0.0

    def get_keys(self) -> dict[str, Any]:
        # 公钥很少变，缓存一小时
        if self._keys is not None and time.monotonic() - self._keys_at < 3600:
            return self._keys
        resp = httpx.get(f"{APPLE_ISSUER}/auth/keys", timeout=10)
        resp.raise_for_status()
        keys: dict[str, Any] = resp.json()
        self._keys, self._keys_at = keys, time.monotonic()
        return keys

    def exchange_code(self, client_id: str, client_secret: str, code: str) -> dict[str, Any]:
        resp = httpx.post(
            f"{APPLE_ISSUER}/auth/token",
            data={
                "client_id": client_id,
                "client_secret": client_secret,
                "code": code,
                "grant_type": "authorization_code",
            },
            timeout=10,
        )
        resp.raise_for_status()
        return resp.json()

    def revoke(self, client_id: str, client_secret: str, refresh_token: str) -> None:
        resp = httpx.post(
            f"{APPLE_ISSUER}/auth/revoke",
            data={
                "client_id": client_id,
                "client_secret": client_secret,
                "token": refresh_token,
                "token_type_hint": "refresh_token",
            },
            timeout=10,
        )
        resp.raise_for_status()


class InvalidAppleToken(ApiError):
    def __init__(self, detail: str):
        super().__init__(401, "apple_token_invalid", "Apple 登录没有成功，请重试", detail)


class AppleNotConfigured(ApiError):
    def __init__(self) -> None:
        super().__init__(503, "apple_unavailable", "暂时不能通过 Apple 登录，请用邮箱登录")


@dataclass(frozen=True)
class AppleIdentity:
    subject: str
    email: str | None
    is_private_email: bool


class AppleClient:
    def __init__(self, settings: Settings, transport: AppleTransport):
        self.settings = settings
        self.transport = transport

    def _require_configured(self) -> None:
        if not self.settings.apple_client_id:
            raise AppleNotConfigured()

    def verify_identity_token(self, token: str, now: float) -> AppleIdentity:
        """校验签名、签发方、受众和有效期。"""
        self._require_configured()
        try:
            header = jwt.get_unverified_header(token)
            keys = self.transport.get_keys().get("keys", [])
            jwk = next((k for k in keys if k.get("kid") == header.get("kid")), None)
            if jwk is None:
                raise InvalidAppleToken("unknown key id")
            key = jwt.PyJWK(jwk).key
            claims = jwt.decode(
                token,
                key=key,  # type: ignore[arg-type]
                algorithms=["RS256"],
                audience=self.settings.apple_client_id,
                issuer=APPLE_ISSUER,
                options={
                    "require": ["exp", "iat", "sub", "aud", "iss"],
                    "verify_exp": False,
                    "verify_iat": False,
                },
            )
        except jwt.PyJWTError as exc:
            raise InvalidAppleToken(type(exc).__name__) from exc
        # 过期时间按服务端时钟判断（测试里时钟可以拨）
        if float(claims["exp"]) <= now:
            raise InvalidAppleToken("expired")
        private = claims.get("is_private_email")
        return AppleIdentity(
            subject=str(claims["sub"]),
            email=claims.get("email"),
            is_private_email=private in (True, "true"),
        )

    def _client_secret(self) -> str | None:
        s = self.settings
        if not (s.apple_team_id and s.apple_key_id and s.apple_private_key):
            return None
        now = int(time.time())
        return jwt.encode(
            {
                "iss": s.apple_team_id,
                "iat": now,
                "exp": now + 300,
                "aud": APPLE_ISSUER,
                "sub": s.apple_client_id,
            },
            s.apple_private_key,
            algorithm="ES256",
            headers={"kid": s.apple_key_id},
        )

    def exchange_code(self, code: str) -> str | None:
        """用授权码换 Apple 的刷新令牌（注销时撤销授权要用）。换不到不影响登录。"""
        secret = self._client_secret()
        if secret is None:
            logger.warning("apple key not configured; skip code exchange")
            return None
        try:
            data = self.transport.exchange_code(self.settings.apple_client_id, secret, code)
        except Exception:
            logger.exception("apple code exchange failed")
            return None
        token = data.get("refresh_token")
        return str(token) if token else None

    def revoke(self, refresh_token: str) -> bool:
        secret = self._client_secret()
        if secret is None:
            logger.warning("apple key not configured; skip revoke")
            return False
        try:
            self.transport.revoke(self.settings.apple_client_id, secret, refresh_token)
        except Exception:
            logger.exception("apple revoke failed")
            return False
        return True
