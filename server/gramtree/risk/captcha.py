from __future__ import annotations

import secrets
from dataclasses import dataclass
from datetime import datetime
from typing import Protocol


@dataclass(frozen=True)
class CaptchaChallenge:
    challenge_id: str
    prompt: str


class CaptchaAdapter(Protocol):
    """Replaceable boundary for a hosted CAPTCHA provider."""

    def issue(self, subject: str, now: datetime) -> CaptchaChallenge: ...

    def verify(self, challenge: CaptchaChallenge, response: str, now: datetime) -> bool: ...


class RejectingCaptchaAdapter:
    """Production-safe default until a provider is explicitly installed."""

    def issue(self, subject: str, now: datetime) -> CaptchaChallenge:
        return CaptchaChallenge(secrets.token_urlsafe(24), "请完成安全验证")

    def verify(self, challenge: CaptchaChallenge, response: str, now: datetime) -> bool:
        return False


class MemoryCaptchaAdapter:
    """Deterministic adapter for HTTP tests and local development."""

    def __init__(self, answer: str = "ok") -> None:
        self.answer = answer

    def issue(self, subject: str, now: datetime) -> CaptchaChallenge:
        return CaptchaChallenge(secrets.token_urlsafe(24), "请完成安全验证")

    def verify(self, challenge: CaptchaChallenge, response: str, now: datetime) -> bool:
        return secrets.compare_digest(response, self.answer)
