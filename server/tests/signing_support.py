"""Sign real HTTP requests for existing behavior tests, without bypassing verification.

Use X-Test-Unsigned: true for missing-signature tests. Explicit signing headers are
never repaired, so tampering and replay tests continue to exercise the boundary.
"""

import hashlib
import hmac
import uuid
from datetime import UTC, datetime
from typing import Any
from urllib.parse import quote

import httpx
import jwt
import pytest
from fastapi.testclient import TestClient


def signed_headers(
    tokens: dict[str, Any],
    method: str,
    url: str,
    *,
    body: bytes = b"",
    timestamp: int | None = None,
    nonce: str | None = None,
    device: str | None = None,
    key: str | None = None,
) -> dict[str, str]:
    target = httpx.URL(url)
    stamp = timestamp if timestamp is not None else int(datetime.now(UTC).timestamp())
    random = nonce or uuid.uuid4().hex
    fields = (
        method.upper(),
        target.path,
        target.query.decode("ascii"),
        str(stamp),
        random,
        hashlib.sha256(body).hexdigest(),
    )
    message = "\n".join(quote(value, safe="/-_.~=&") for value in fields).encode()
    signature = hmac.new(
        (key or tokens["request_signing_key"]).encode(), message, hashlib.sha256
    ).hexdigest()
    headers = {
        "Authorization": f"Bearer {tokens['access_token']}",
        "X-Request-Timestamp": str(stamp),
        "X-Request-Nonce": random,
        "X-Request-Signature": signature,
    }
    if device is not None:
        headers["X-Device-ID"] = device
    return headers


@pytest.fixture(autouse=True)
def _sign_behavior_http(monkeypatch: pytest.MonkeyPatch) -> None:
    # Capture credentials only from the same public login/refresh contract used
    # by the App. Shared across clients within a test for cross-client journeys.
    credentials: dict[str, tuple[str, str | None]] = {}
    refresh_devices: dict[str, str | None] = {}
    original = TestClient.send

    def send(
        client: TestClient, request: httpx.Request, *args: Any, **kwargs: Any
    ) -> httpx.Response:
        raw = request.headers.pop("X-Test-Unsigned", None)
        authorization = request.headers.get("authorization", "")
        token = authorization[7:] if authorization.lower().startswith("bearer ") else None
        supplied = any(
            name in request.headers
            for name in ("X-Request-Timestamp", "X-Request-Nonce", "X-Request-Signature")
        )
        if token and token in credentials and not supplied and not raw:
            key, device = credentials[token]
            now = getattr(client.app.state, "clock", lambda: datetime.now(UTC))()  # type: ignore[attr-defined]
            headers = signed_headers(
                {"access_token": token, "request_signing_key": key},
                request.method,
                str(request.url),
                body=request.read(),
                timestamp=int(now.timestamp()),
                device=device,
            )
            for name, value in headers.items():
                if name.lower() == "x-device-id" and name in request.headers:
                    continue
                request.headers[name] = value
        response = original(client, request, *args, **kwargs)
        if response.status_code == 200 and request.url.path in {
            "/v1/auth/email/login",
            "/v1/auth/apple/login",
            "/v1/auth/refresh",
        }:
            payload = response.json()
            if "request_signing_key" in payload:
                device = request.headers.get("X-Device-ID")
                if request.url.path == "/v1/auth/refresh":
                    import json

                    device = refresh_devices.get(
                        json.loads(request.read())["refresh_token"], device
                    )
                access = payload["access_token"]
                sid = jwt.decode(access, options={"verify_signature": False}).get("sid")
                for known in list(credentials):
                    if jwt.decode(known, options={"verify_signature": False}).get("sid") == sid:
                        credentials[known] = (payload["request_signing_key"], device)
                credentials[access] = (payload["request_signing_key"], device)
                refresh_devices[payload["refresh_token"]] = device
        return response

    monkeypatch.setattr(TestClient, "send", send)
