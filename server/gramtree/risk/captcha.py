from __future__ import annotations

import base64
import hashlib
import hmac
import io
import secrets
from dataclasses import dataclass
from datetime import datetime
from typing import Any, Protocol, cast

from PIL import Image, ImageDraw, ImageFont
from redis import Redis


@dataclass(frozen=True)
class CaptchaChallenge:
    challenge_id: str
    prompt: str


@dataclass(frozen=True)
class CaptchaPresentation:
    prompt: str
    image_data_uri: str


class CaptchaAdapter(Protocol):
    """Replaceable boundary for a hosted CAPTCHA provider."""

    def issue(self, subject: str, now: datetime) -> CaptchaChallenge: ...

    def verify(self, challenge: CaptchaChallenge, response: str, now: datetime) -> bool: ...

    def presentation(
        self, challenge: CaptchaChallenge, now: datetime
    ) -> CaptchaPresentation | None: ...


_PROMPT = "请输入图片中的字符（不区分大小写）"


def _image(answer: str) -> str:
    image = Image.new("RGB", (240, 88), "#f7f4ee")
    draw = ImageDraw.Draw(image)
    font = ImageFont.load_default(size=34)
    for index, character in enumerate(answer):
        draw.text(
            (14 + index * 35, 18 + secrets.randbelow(14)), character, font=font, fill="#1b1813"
        )
    for _ in range(8):
        draw.line(
            [
                (secrets.randbelow(240), secrets.randbelow(88)),
                (secrets.randbelow(240), secrets.randbelow(88)),
            ],
            fill="#8b887e",
            width=1,
        )
    output = io.BytesIO()
    image.save(output, format="PNG")
    return "data:image/png;base64," + base64.b64encode(output.getvalue()).decode("ascii")


class ImageCaptchaAdapter:
    """Usable built-in provider: only a keyed verifier and PNG survive issuance.

    Redis garbage-collects the presentation. Risk recovery owns subject binding,
    business-clock expiry and single-use consumption of the active challenge.
    """

    def __init__(self, redis: Redis, secret: str, ttl_seconds: int = 86400) -> None:
        self.redis = redis
        self.secret = secret.encode()
        self.ttl_seconds = ttl_seconds

    def _verifier(self, challenge_id: str, subject: str, answer: str) -> str:
        return hmac.new(
            self.secret,
            f"{challenge_id}:{subject}:{answer.strip().upper()}".encode(),
            hashlib.sha256,
        ).hexdigest()

    def issue(self, subject: str, now: datetime) -> CaptchaChallenge:
        challenge_id = secrets.token_urlsafe(24)
        answer = "".join(secrets.choice("ABCDEFGHJKLMNPQRSTUVWXYZ23456789") for _ in range(6))
        key = f"risk:captcha-image:{challenge_id}"
        with self.redis.pipeline() as pipe:
            pipe.hset(
                key,
                mapping={
                    "subject": subject,
                    "verifier": self._verifier(challenge_id, subject, answer),
                    "image": _image(answer),
                    "expires_at": str(now.timestamp() + self.ttl_seconds),
                },
            )
            pipe.expire(key, self.ttl_seconds)
            pipe.execute()
        return CaptchaChallenge(challenge_id, _PROMPT)

    def _stored(self, challenge: CaptchaChallenge, now: datetime) -> dict[str, str]:
        raw = cast(Any, self.redis.hgetall(f"risk:captcha-image:{challenge.challenge_id}"))
        values = {
            k.decode() if isinstance(k, bytes) else str(k): v.decode()
            if isinstance(v, bytes)
            else str(v)
            for k, v in raw.items()
        }
        if float(values.get("expires_at", "0")) <= now.timestamp():
            return {}
        return values

    def verify(self, challenge: CaptchaChallenge, response: str, now: datetime) -> bool:
        values = self._stored(challenge, now)
        return bool(values) and hmac.compare_digest(
            values.get("verifier", ""),
            self._verifier(challenge.challenge_id, values.get("subject", ""), response),
        )

    def presentation(
        self, challenge: CaptchaChallenge, now: datetime
    ) -> CaptchaPresentation | None:
        values = self._stored(challenge, now)
        return CaptchaPresentation(_PROMPT, values["image"]) if values else None


class RejectingCaptchaAdapter:
    """Explicit opt-out provider; the application's default is ImageCaptchaAdapter."""

    def issue(self, subject: str, now: datetime) -> CaptchaChallenge:
        return CaptchaChallenge(secrets.token_urlsafe(24), "请完成安全验证")

    def verify(self, challenge: CaptchaChallenge, response: str, now: datetime) -> bool:
        return False

    def presentation(
        self, challenge: CaptchaChallenge, now: datetime
    ) -> CaptchaPresentation | None:
        return None


class MemoryCaptchaAdapter:
    """Deterministic adapter for HTTP tests and local development."""

    def __init__(self, answer: str = "ok") -> None:
        self.answer = answer

    def issue(self, subject: str, now: datetime) -> CaptchaChallenge:
        return CaptchaChallenge(secrets.token_urlsafe(24), "请完成安全验证")

    def verify(self, challenge: CaptchaChallenge, response: str, now: datetime) -> bool:
        return secrets.compare_digest(response, self.answer)

    def presentation(
        self, challenge: CaptchaChallenge, now: datetime
    ) -> CaptchaPresentation | None:
        return CaptchaPresentation("请完成安全验证", _image(self.answer))
