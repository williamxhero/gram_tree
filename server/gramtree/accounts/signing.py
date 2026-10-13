"""Replay-safe request signing for authenticated device sessions."""

from __future__ import annotations

import hashlib
import hmac
from dataclasses import dataclass
from datetime import UTC, datetime
from urllib.parse import quote

from redis import Redis

from gramtree.accounts.models import DeviceSession
from gramtree.core.errors import ApiError

SIGNATURE_HEADER = "X-Request-Signature"
TIMESTAMP_HEADER = "X-Request-Timestamp"
NONCE_HEADER = "X-Request-Nonce"
DEVICE_HEADER = "x-device-id"


@dataclass(frozen=True)
class SignatureInput:
    timestamp: int
    nonce: str
    signature: str


def body_digest(body: bytes) -> str:
    return hashlib.sha256(body).hexdigest()


def canonical_message(
    method: str,
    path: str,
    query: str,
    timestamp: int,
    nonce: str,
    body_hash: str,
) -> bytes:
    # The raw query string is intentional: reordering or re-encoding parameters
    # must invalidate a captured signature.
    fields = (method.upper(), path, query, str(timestamp), nonce, body_hash)
    return "\n".join(quote(field, safe="/-_.~=&%") for field in fields).encode()


def sign(
    key: str,
    method: str,
    path: str,
    query: str,
    timestamp: int,
    nonce: str,
    body: bytes = b"",
) -> str:
    return hmac.new(
        key.encode(),
        canonical_message(method, path, query, timestamp, nonce, body_digest(body)),
        hashlib.sha256,
    ).hexdigest()


def credential_hash(key: str, auth_secret: str) -> str:
    """Return the device credential persisted by the server.

    The value returned in a login response is this derived credential rather
    than the random seed. This derived value is itself a signing secret: HMAC
    verification needs the same credential as the client. Never log or expose it
    outside the login/refresh response.
    """
    return hmac.new(auth_secret.encode(), key.encode(), hashlib.sha256).hexdigest()


def _read_input(headers: dict[str, str]) -> SignatureInput:
    raw_timestamp = headers.get(TIMESTAMP_HEADER.lower())
    nonce = headers.get(NONCE_HEADER.lower())
    signature = headers.get(SIGNATURE_HEADER.lower())
    if not raw_timestamp or not nonce or not signature:
        raise SignatureError("signature_required")
    try:
        timestamp = int(raw_timestamp)
    except ValueError as exc:
        raise SignatureError("signature_invalid") from exc
    if (
        len(nonce) > 128
        or not nonce.isprintable()
        or any(character not in "0123456789abcdef" for character in signature)
        or len(signature) != hashlib.sha256().digest_size * 2
    ):
        raise SignatureError("signature_invalid")
    return SignatureInput(timestamp=timestamp, nonce=nonce, signature=signature)


class SignatureError(ApiError):
    def __init__(self, code: str, *, server_time: datetime | None = None):
        messages = {
            "signature_required": "请求签名无效",
            "signature_invalid": "请求签名无效",
            "signature_expired": "请求签名已过期",
            "signature_clock_skew": "设备时间不准确，请校正后重试",
            "nonce_replayed": "请求签名无效",
            "device_mismatch": "请求签名无效",
        }
        super().__init__(401, code, messages.get(code, messages["signature_invalid"]), None)
        self.server_time = server_time


def verify(
    redis: Redis,
    device_session: DeviceSession,
    auth_secret: str,
    *,
    headers: dict[str, str],
    method: str,
    path: str,
    query: str,
    body: bytes,
    now: datetime,
    tolerance_seconds: int,
    nonce_ttl_seconds: int,
) -> None:
    """Validate the MAC and atomically reserve a nonce for one device session."""
    current = now.astimezone(UTC)
    supplied = _read_input(headers)
    difference = abs(int(current.timestamp()) - supplied.timestamp)
    if difference > tolerance_seconds:
        raise SignatureError("signature_clock_skew", server_time=current)
    if (
        device_session.device_id is not None
        and headers.get(DEVICE_HEADER) != device_session.device_id
    ):
        raise SignatureError("device_mismatch")

    candidates = [device_session.signing_secret_hash]
    if (
        device_session.previous_signing_secret_hash
        and device_session.previous_signing_secret_expires_at
        and device_session.previous_signing_secret_expires_at > current
    ):
        candidates.append(device_session.previous_signing_secret_hash)
    message = canonical_message(
        method, path, query, supplied.timestamp, supplied.nonce, body_digest(body)
    )
    valid = any(
        stored_hash is not None
        and hmac.compare_digest(
            hmac.new(stored_hash.encode(), message, hashlib.sha256).hexdigest(), supplied.signature
        )
        for stored_hash in candidates
    )
    if not valid:
        raise SignatureError("signature_invalid")

    nonce_key = (
        "signing:nonce:"
        + str(device_session.id)
        + ":"
        + hashlib.sha256(supplied.nonce.encode()).hexdigest()
    )
    try:
        # Retain even future-dated nonces until the entire acceptance window ends.
        # A shorter configured TTL must never make the captured request replayable.
        ttl = max(
            1,
            nonce_ttl_seconds,
            supplied.timestamp + tolerance_seconds - int(current.timestamp()) + 1,
        )
        reserved = redis.set(nonce_key, "1", nx=True, ex=ttl)
    except Exception:
        # A replay-safe boundary must not silently become a bearer-token
        # boundary when Redis is unavailable.
        raise SignatureError("signature_invalid") from None
    if not reserved:
        raise SignatureError("nonce_replayed")
