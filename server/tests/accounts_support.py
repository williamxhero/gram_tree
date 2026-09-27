"""账号测试用的工具：可拨动的时钟、从假邮件里取验证码、用测试密钥签发的 Apple 身份令牌。"""

import time
import uuid
from collections.abc import Iterator
from dataclasses import dataclass, field
from datetime import UTC, datetime, timedelta
from typing import Any

import jwt
import pytest
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import ec, rsa
from fastapi.testclient import TestClient
from jwt.algorithms import RSAAlgorithm

from gramtree.accounts.mailer import MemoryMailSender
from gramtree.main import create_app
from tests.conftest import make_settings

APPLE_CLIENT_ID = "app.gramtree.test"
APPLE_ISSUER = "https://appleid.apple.com"

_apple_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
_other_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
_client_secret_key = ec.generate_private_key(ec.SECP256R1())
CLIENT_SECRET_PEM = _client_secret_key.private_bytes(
    serialization.Encoding.PEM,
    serialization.PrivateFormat.PKCS8,
    serialization.NoEncryption(),
).decode()


@dataclass
class FakeAppleTransport:
    """假的 Apple 接口：提供测试公钥，记录换码和撤销调用。"""

    exchanged: list[str] = field(default_factory=list)
    revoked: list[str] = field(default_factory=list)

    def get_keys(self) -> dict[str, Any]:
        jwk = RSAAlgorithm.to_jwk(_apple_key.public_key(), as_dict=True)
        jwk.update({"kid": "test-kid", "alg": "RS256", "use": "sig"})
        return {"keys": [jwk]}

    def exchange_code(self, client_id: str, client_secret: str, code: str) -> dict[str, Any]:
        # 确认 client_secret 是用配置的密钥签的
        jwt.decode(
            client_secret,
            _client_secret_key.public_key(),
            algorithms=["ES256"],
            audience=APPLE_ISSUER,
        )
        self.exchanged.append(code)
        return {"refresh_token": f"apple-refresh-{code}"}

    def revoke(self, client_id: str, client_secret: str, refresh_token: str) -> None:
        self.revoked.append(refresh_token)


def apple_token(
    sub: str,
    *,
    email: str | None = None,
    private_email: bool = False,
    aud: str = APPLE_CLIENT_ID,
    exp_in: int = 600,
    signed_by_apple: bool = True,
    now: float | None = None,
) -> str:
    issued = int(now if now is not None else time.time())
    claims: dict[str, Any] = {
        "iss": APPLE_ISSUER,
        "aud": aud,
        "sub": sub,
        "iat": issued,
        "exp": issued + exp_in,
    }
    if email:
        claims["email"] = email
        claims["is_private_email"] = "true" if private_email else "false"
    key = _apple_key if signed_by_apple else _other_key
    return jwt.encode(claims, key, algorithm="RS256", headers={"kid": "test-kid"})


class Clock:
    def __init__(self) -> None:
        self.now = datetime.now(UTC)

    def __call__(self) -> datetime:
        return self.now

    def advance(self, **kwargs: float) -> None:
        self.now += timedelta(**kwargs)


@dataclass
class Api:
    client: TestClient
    clock: Clock
    apple: FakeAppleTransport

    @property
    def mailer(self) -> MemoryMailSender:
        return self.client.app.state.mailer  # type: ignore[attr-defined]

    def latest_code(self, email: str) -> str:
        resp = self.client.get("/v1/dev/latest-email-code", params={"email": email})
        assert resp.status_code == 200, resp.text
        return resp.json()["code"]

    def send_code(self, email: str, purpose: str = "login", **kw: Any) -> Any:
        return self.client.post(
            "/v1/auth/email/code", json={"email": email, "purpose": purpose}, **kw
        )

    def login(self, email: str, device: str | None = None) -> dict[str, Any]:
        headers = {"X-Device-ID": device} if device else {}
        resp = self.send_code(email, headers=headers)
        assert resp.status_code == 200, resp.text
        resp = self.client.post(
            "/v1/auth/email/login",
            json={"email": email, "code": self.latest_code(email)},
            headers=headers,
        )
        assert resp.status_code == 200, resp.text
        # 同一邮箱下一次发码不受重发间隔影响
        self.clock.advance(seconds=61)
        return resp.json()

    def apple_login(self, sub: str, **kw: Any) -> Any:
        body = {"identity_token": apple_token(sub, now=self.clock.now.timestamp(), **kw)}
        return self.client.post("/v1/auth/apple/login", json=body)


def bearer(tokens: dict[str, Any]) -> dict[str, str]:
    return {"Authorization": f"Bearer {tokens['access_token']}"}


def new_uuid() -> str:
    return str(uuid.uuid4())


@pytest.fixture
def api(database_url: str) -> Iterator[Api]:
    settings = make_settings(
        apple_client_id=APPLE_CLIENT_ID,
        apple_team_id="TEAMID",
        apple_key_id="KEYID",
        apple_private_key=CLIENT_SECRET_PEM,
    )
    app = create_app(settings)
    clock = Clock()
    fake = FakeAppleTransport()
    app.state.clock = clock
    app.state.apple.transport = fake
    with TestClient(app, raise_server_exceptions=False) as c:
        yield Api(c, clock, fake)
