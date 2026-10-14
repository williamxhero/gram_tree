from __future__ import annotations

import hashlib
import hmac
import ipaddress
import json
import logging
import re
import time
import uuid
from collections.abc import Iterator
from contextlib import contextmanager
from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import Any, Literal, cast

from redis import Redis
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from gramtree.accounts.models import User
from gramtree.core.errors import ApiError
from gramtree.core.time import utcnow
from gramtree.risk.captcha import CaptchaAdapter, CaptchaChallenge, CaptchaPresentation
from gramtree.risk.models import RiskAction, RiskEvent
from gramtree.risk.rules import OBSERVE, RECOVER
from gramtree.runtime_config import service as config
from gramtree.settings import Settings

logger = logging.getLogger("gramtree.risk")
RiskLevel = Literal["captcha", "throttle", "temporary_block", "permanent_block"]
_SUBJECTS = ("account", "device", "ip")
_DETAIL_RE = re.compile(r"^/v1/(?:recipes|ingredients)/([^/]+)(?:/|$)")
_BYPASS_PREFIXES = ("/v1/health", "/v1/dev", "/v1/client-config")


def is_recovery_route(path: str, method: str) -> bool:
    if method.upper() == "POST" and path == "/v1/risk/captcha":
        return True
    prefix = "/v1/risk/captcha/"
    return (
        method.upper() == "GET"
        and path.startswith(prefix)
        and bool(path[len(prefix) :])
        and "/" not in path[len(prefix) :]
    )


class RiskActionError(ApiError):
    def __init__(
        self, level: RiskLevel, *, retry_after: int | None = None, challenge: str | None = None
    ):
        errors = {
            "captcha": (403, "risk_captcha_required", "请完成安全验证后继续"),
            "throttle": (429, "risk_slowed", "请求频率需要降低，请稍后再试"),
            "temporary_block": (403, "risk_temporarily_blocked", "当前访问暂时受限，请稍后再试"),
            "permanent_block": (403, "risk_permanently_blocked", "当前访问已被限制，请联系支持"),
        }
        status, code, message = errors[level]
        super().__init__(status, code, message, None)
        self.retry_after = retry_after
        self.headers = {"X-Risk-Level": level}
        if retry_after is not None:
            self.headers["Retry-After"] = str(retry_after)
        if challenge:
            self.headers["X-Risk-Challenge"] = challenge


@dataclass(frozen=True)
class RiskDecision:
    level: RiskLevel | None
    retry_after: int | None = None
    challenge_id: str | None = None

    @property
    def blocked(self) -> bool:
        return self.level is not None


@dataclass(frozen=True)
class Subject:
    kind: str
    value: str


def enabled(session: Session) -> bool:
    return bool(config.get(session, "risk.enabled"))


def _int(session: Session, key: str) -> int:
    return max(1, int(config.get(session, key)))


def _hash(settings: Settings, value: str) -> str:
    return hmac.new(settings.auth_secret.encode(), value.encode(), hashlib.sha256).hexdigest()


def _subject(kind: str, value: str, settings: Settings) -> Subject:
    return Subject(kind, _hash(settings, value))


def request_subnet(ip: str | None) -> str | None:
    if not ip:
        return None
    try:
        address = ipaddress.ip_address(ip)
    except ValueError:
        return None
    prefix = 24 if address.version == 4 else 64
    return f"{ipaddress.ip_network(f'{ip}/{prefix}', strict=False).network_address}/{prefix}"


def _level(value: str) -> RiskLevel | None:
    if value in {"captcha", "throttle", "temporary_block", "permanent_block"}:
        return cast(RiskLevel, value)
    return None


def _config(session: Session) -> dict[str, int]:
    keys = (
        "short_window_seconds",
        "short_request_limit",
        "detail_interval_seconds",
        "detail_interval_tolerance_ms",
        "detail_repeat_limit",
        "sequential_limit",
        "uniform_daily_limit",
        "uniform_days",
        "uniform_bucket_seconds",
        "uniform_tolerance_percent",
        "multi_account_limit",
        "subnet_new_account_limit",
        "captcha_points",
        "throttle_points",
        "temporary_block_points",
        "permanent_block_points",
        "throttle_seconds",
        "throttle_window_seconds",
        "throttle_request_limit",
        "temporary_block_seconds",
        "captcha_seconds",
        "security_failure_limit",
        "score_ttl_seconds",
        "retention_seconds",
    )
    values = {key: _int(session, f"risk.{key}") for key in keys}
    values["uniform_tolerance_percent"] = max(
        0, int(config.get(session, "risk.uniform_tolerance_percent"))
    )
    values["detail_interval_tolerance_ms"] = max(
        0, int(config.get(session, "risk.detail_interval_tolerance_ms"))
    )
    return values


def _subject_key(subject: Subject) -> str:
    return f"risk:{subject.kind}:{subject.value}"


@contextmanager
def _audit_session(session: Session, subjects: list[Subject]) -> Iterator[Session]:
    # Hold locks through the durable commit: Redis publication must not overtake
    # action insertion or a companion-subject lift. Never commit the caller's
    # account/recipe transaction as a side effect of a risk observation.
    with Session(session.get_bind(), expire_on_commit=False) as audit:
        for name in sorted({_subject_key(subject) for subject in subjects}):
            lock_id = int.from_bytes(hashlib.sha256(name.encode()).digest()[:8], signed=True)
            audit.execute(select(func.pg_advisory_xact_lock(lock_id)))
        yield audit
        audit.commit()


def _record(
    session: Session,
    subject: Subject,
    rule: str,
    evidence: dict[str, object],
    points: int,
    now: datetime,
) -> None:
    session.add(
        RiskEvent(
            subject_type=subject.kind,
            subject_key_hash=subject.value,
            rule=rule,
            evidence=evidence,
            points=points,
            created_at=now,
        )
    )


def _challenge(
    redis: Redis,
    session: Session,
    subject: Subject,
    action_id: str,
    now: datetime,
    adapter: CaptchaAdapter,
) -> str:
    key = f"risk:captcha:{subject.kind}:{subject.value}"
    existing = cast(Any, redis.hgetall(key))
    stored_id = existing.get(b"challenge_id") or existing.get("challenge_id")
    stored_action = existing.get(b"action_id") or existing.get("action_id")
    expires_at = existing.get(b"expires_at") or existing.get("expires_at") or 0
    if (
        stored_id
        and float(expires_at) > now.timestamp()
        and (stored_action.decode() if isinstance(stored_action, bytes) else stored_action)
        == action_id
    ):
        return stored_id.decode() if isinstance(stored_id, bytes) else str(stored_id)
    redis.delete(key)
    issued = adapter.issue(subject.value, now)
    binding = hashlib.sha256(f"{subject.kind}:{subject.value}".encode()).hexdigest()
    redis.hset(
        key,
        mapping={
            "challenge_id": issued.challenge_id,
            "prompt": issued.prompt,
            "binding": binding,
            "base": _subject_key(subject),
            "action_id": action_id,
            "expires_at": int(
                (now + timedelta(seconds=_int(session, "risk.captcha_seconds"))).timestamp()
            ),
        },
    )
    redis.expire(key, _int(session, "risk.captcha_seconds"))
    return issued.challenge_id


def _run(
    redis: Redis,
    session: Session,
    settings: Settings,
    subject: Subject,
    *,
    mode: str,
    input_data: dict[str, object],
    now: datetime,
    captcha: CaptchaAdapter,
    release_caller_session: bool = False,
) -> RiskDecision | None:
    cfg = _config(session)
    if release_caller_session:
        # The caller has performed only read checks. Release its connection before
        # opening the independent durable audit session, or a request burst can
        # have every pool slot wait for a second one.
        session.commit()
    with _audit_session(session, [subject]) as audit:
        return _run_locked(
            redis,
            audit,
            subject,
            cfg=cfg,
            mode=mode,
            input_data=input_data,
            now=now,
            captcha=captcha,
        )


def _run_locked(
    redis: Redis,
    session: Session,
    subject: Subject,
    *,
    cfg: dict[str, int],
    mode: str,
    input_data: dict[str, object],
    now: datetime,
    captcha: CaptchaAdapter,
) -> RiskDecision | None:
    action_id = str(uuid.uuid4())
    input_data["action_id"] = action_id
    input_data["can_ban"] = subject.kind in {"account", "device"}
    member = f"{now.timestamp():.6f}:{time.monotonic_ns()}"
    input_data.setdefault("member", member)
    base = _subject_key(subject)
    raw = cast(
        Any,
        redis.eval(
            OBSERVE, 1, base, str(now.timestamp()), mode, json.dumps(cfg), json.dumps(input_data)
        ),
    )
    result = json.loads(raw.decode() if isinstance(raw, bytes) else raw)
    if result.get("grace"):
        return RiskDecision(None)
    old_id = result.get("previous_action")
    if old_id:
        old = session.get(RiskAction, uuid.UUID(old_id))
        if old is not None and old.lifted_at is None:
            old.lifted_at = now
            old.lift_reason = "expired" if old.ends_at and old.ends_at <= now else "superseded"
    rule = str(result.get("rule") or "")
    points = int(result.get("points") or 0)
    level = _level(str(result.get("level") or ""))
    if rule:
        evidence = result.get("evidence") or {}
        _record(session, subject, rule, evidence, points, now)
    if level and result.get("action_id") == action_id:
        end_ts = int(now.timestamp() + int(result.get("retry") or 0))
        ends_at = (
            datetime.fromtimestamp(end_ts, tz=now.tzinfo) if end_ts > int(now.timestamp()) else None
        )
        action = RiskAction(
            id=uuid.UUID(action_id),
            subject_type=subject.kind,
            subject_key_hash=subject.value,
            rule=rule,
            evidence=result.get("evidence") or {},
            level=level,
            started_at=now,
            ends_at=ends_at,
        )
        session.add(action)
        session.flush()
        challenge_id = (
            _challenge(redis, session, subject, str(action.id), now, captcha)
            if level == "captcha"
            else None
        )
        logger.warning(
            "risk action",
            extra={
                "subject_type": subject.kind,
                "rule": rule,
                "level": level,
                "action_id": action_id,
            },
        )
        return RiskDecision(level, int(result.get("retry") or 0) or None, challenge_id)
    if level == "captcha":
        challenge_id = _challenge(
            redis, session, subject, str(result.get("action_id")), now, captcha
        )
        return RiskDecision(level, challenge_id=challenge_id)
    if level in {"throttle", "temporary_block"}:
        return RiskDecision(level, int(result.get("retry") or 1))
    if level == "permanent_block":
        return RiskDecision(level)
    return None


def observe_request(
    redis: Redis,
    session: Session,
    settings: Settings,
    *,
    ip: str | None,
    device_id: str | None,
    path: str,
    now: datetime | None = None,
    captcha: CaptchaAdapter,
) -> RiskDecision | None:
    if not enabled(session) or path.startswith(_BYPASS_PREFIXES):
        return None
    current = now or utcnow()
    if device_id and is_permanently_banned(session, settings, device_id=device_id, now=current):
        return RiskDecision("permanent_block")
    detail = _DETAIL_RE.match(path)
    for kind, value in (("device", device_id), ("ip", ip)):
        if value:
            decision = _run(
                redis,
                session,
                settings,
                _subject(kind, value, settings),
                mode="request",
                input_data={"detail": detail.group(1) if detail else ""},
                now=current,
                captcha=captcha,
                release_caller_session=True,
            )
            if decision:
                return decision
    subnet = request_subnet(ip)
    if subnet:
        return _run(
            redis,
            session,
            settings,
            _subject("ip", f"subnet:{subnet}", settings),
            mode="check",
            input_data={},
            now=current,
            captcha=captcha,
            release_caller_session=True,
        )
    return None


def observe_account(
    redis: Redis,
    session: Session,
    settings: Settings,
    *,
    user_id: str,
    device_id: str | None,
    ip: str | None,
    path: str,
    now: datetime,
    captcha: CaptchaAdapter,
) -> RiskDecision | None:
    if not enabled(session) or path.startswith(_BYPASS_PREFIXES):
        return None
    account = _subject("account", user_id, settings)
    detail = _DETAIL_RE.match(path)
    decision = _run(
        redis,
        session,
        settings,
        account,
        mode="request",
        input_data={"detail": detail.group(1) if detail else ""},
        now=now,
        captcha=captcha,
        release_caller_session=True,
    )
    if decision:
        return decision
    if device_id:
        device = _subject("device", device_id, settings)
        decision = _run(
            redis,
            session,
            settings,
            device,
            mode="login",
            input_data={"account": account.value, "new_account": False},
            now=now,
            captcha=captcha,
            release_caller_session=True,
        )
        if decision:
            return decision
    return None


def observe_login(
    redis: Redis,
    session: Session,
    settings: Settings,
    *,
    user: User,
    device_id: str | None,
    ip: str | None,
    is_new_account: bool,
    now: datetime,
    captcha: CaptchaAdapter,
) -> RiskDecision | None:
    if not enabled(session):
        return None
    if device_id:
        device = _subject("device", device_id, settings)
        decision = _run(
            redis,
            session,
            settings,
            device,
            mode="login",
            input_data={
                "account": _subject("account", str(user.id), settings).value,
                "new_account": False,
            },
            now=now,
            captcha=captcha,
        )
        if decision:
            return decision
    subnet = request_subnet(ip)
    if subnet and is_new_account:
        subject = _subject("ip", f"subnet:{subnet}", settings)
        decision = _run(
            redis,
            session,
            settings,
            subject,
            mode="login",
            input_data={
                "account": _subject("account", str(user.id), settings).value,
                "new_account": True,
            },
            now=now,
            captcha=captcha,
        )
        if decision:
            return decision
    return None


def record_security_failure(
    redis: Redis,
    session: Session,
    settings: Settings,
    *,
    subject_type: Literal["account", "device", "ip"],
    subject_value: str,
    rule: Literal["signature_failure", "nonce_replay", "rate_limit_violation"],
    now: datetime,
    captcha: CaptchaAdapter,
) -> RiskDecision | None:
    if not enabled(session):
        return None
    subject = _subject(subject_type, subject_value[:256], settings)
    return _run(
        redis,
        session,
        settings,
        subject,
        mode="security",
        input_data={"rule": rule},
        now=now,
        captcha=captcha,
        release_caller_session=True,
    )


def _find_challenge(
    redis: Redis,
    settings: Settings,
    challenge_id: str,
    choices: list[tuple[str, str]],
    now: datetime,
) -> tuple[Subject, str] | None:
    for kind, value in choices:
        if kind not in _SUBJECTS or not value:
            continue
        subject = _subject(kind, value[:256], settings)
        key = f"risk:captcha:{subject.kind}:{subject.value}"
        raw = cast(Any, redis.hgetall(key))
        stored = {
            k.decode() if isinstance(k, bytes) else str(k): v.decode()
            if isinstance(v, bytes)
            else str(v)
            for k, v in raw.items()
        }
        if stored.get("challenge_id") != challenge_id:
            continue
        binding = hashlib.sha256(f"{subject.kind}:{subject.value}".encode()).hexdigest()
        active_id = cast(Any, redis.hget(f"{_subject_key(subject)}:state", "action_id"))
        active_id = active_id.decode() if isinstance(active_id, bytes) else active_id
        if (
            hmac.compare_digest(stored.get("binding", ""), binding)
            and float(stored.get("expires_at", "0")) > now.timestamp()
            and stored.get("action_id") == active_id
        ):
            return subject, key
    return None


def get_captcha_challenge(
    redis: Redis,
    session: Session,
    settings: Settings,
    adapter: CaptchaAdapter,
    *,
    challenge_id: str,
    candidates: list[tuple[str, str]],
    now: datetime,
) -> CaptchaPresentation | None:
    subjects = [
        _subject(kind, value[:256], settings)
        for kind, value in candidates
        if kind in _SUBJECTS and value
    ]
    with _audit_session(session, subjects):
        if _find_challenge(redis, settings, challenge_id, candidates, now) is None:
            return None
        return adapter.presentation(CaptchaChallenge(challenge_id, "请完成安全验证"), now)


def verify_captcha(
    redis: Redis,
    session: Session,
    settings: Settings,
    adapter: CaptchaAdapter,
    *,
    challenge_id: str,
    response: str,
    now: datetime,
    subject_type: str | None = None,
    subject_value: str | None = None,
    candidates: list[tuple[str, str]] | None = None,
) -> bool:
    choices = candidates or (
        [(subject_type, subject_value)] if subject_type and subject_value else []
    )
    subjects = [
        _subject(kind, value[:256], settings)
        for kind, value in choices
        if kind in _SUBJECTS and value
    ]
    with _audit_session(session, subjects) as audit:
        return _verify_captcha_locked(
            redis,
            audit,
            settings,
            adapter,
            challenge_id=challenge_id,
            response=response,
            now=now,
            candidates=choices,
        )


def _verify_captcha_locked(
    redis: Redis,
    session: Session,
    settings: Settings,
    adapter: CaptchaAdapter,
    *,
    challenge_id: str,
    response: str,
    now: datetime,
    subject_type: str | None = None,
    subject_value: str | None = None,
    candidates: list[tuple[str, str]] | None = None,
) -> bool:
    choices = candidates or (
        [(subject_type, subject_value)] if subject_type and subject_value else []
    )
    found = _find_challenge(redis, settings, challenge_id, choices, now)
    if found is None:
        return False
    subject, key = found
    binding = hashlib.sha256(f"{subject.kind}:{subject.value}".encode()).hexdigest()
    if not adapter.verify(CaptchaChallenge(challenge_id, "请完成安全验证"), response, now):
        return False
    state_keys = list(
        dict.fromkeys(
            [
                f"{_subject_key(_subject(kind, value[:256], settings))}:state"
                for kind, value in choices
                if kind in _SUBJECTS and value
            ]
            + [f"{_subject_key(subject)}:state"]
        )
    )
    keys = [key, *state_keys]
    action_id = cast(
        Any,
        redis.eval(
            RECOVER,
            len(keys),
            *keys,
            binding,
            str(now.timestamp()),
            str(_int(session, "risk.retention_seconds")),
        ),
    )
    if not action_id:
        return False
    lifted_ids = json.loads(action_id.decode() if isinstance(action_id, bytes) else action_id)
    for lifted in lifted_ids:
        action = session.get(RiskAction, uuid.UUID(lifted["id"]))
        if action is not None and action.lifted_at is None:
            action.lifted_at = now
            action.lift_reason = lifted["reason"]
    return True


def is_permanently_banned(
    session: Session,
    settings: Settings,
    *,
    user_id: str | None = None,
    device_id: str | None = None,
    now: datetime | None = None,
) -> bool:
    current = now or utcnow()
    subjects = []
    if user_id:
        subjects.append(_subject("account", user_id, settings))
    if device_id:
        subjects.append(_subject("device", device_id, settings))
    if not subjects:
        return False
    clauses = [
        (RiskAction.subject_type == item.kind) & (RiskAction.subject_key_hash == item.value)
        for item in subjects
    ]
    action = session.scalars(
        select(RiskAction)
        .where(
            RiskAction.level == "permanent_block",
            RiskAction.lifted_at.is_(None),
            RiskAction.ends_at.is_(None),
            clauses[0] if len(clauses) == 1 else clauses[0] | clauses[1],
        )
        .limit(1)
    ).first()
    return action is not None and action.started_at <= current


def lift_permanent_ban(
    redis: Redis, session: Session, *, action_id: str, now: datetime, reason: str
) -> bool:
    action = session.get(RiskAction, uuid.UUID(action_id))
    if action is None:
        return False
    subject = Subject(action.subject_type, action.subject_key_hash)
    with _audit_session(session, [subject]) as audit:
        return _lift_permanent_ban_locked(redis, audit, action_id=action_id, now=now, reason=reason)


def _lift_permanent_ban_locked(
    redis: Redis, session: Session, *, action_id: str, now: datetime, reason: str
) -> bool:
    action = session.get(RiskAction, uuid.UUID(action_id))
    if action is None or action.level != "permanent_block" or action.lifted_at is not None:
        return False
    base = f"risk:{action.subject_type}:{action.subject_key_hash}"
    redis.delete(
        *(
            f"{base}:{suffix}"
            for suffix in (
                "state",
                "requests",
                "details",
                "uniform",
                "accounts",
                "new-accounts",
                "security",
                "throttle",
            )
        )
    )
    action.lifted_at = now
    action.lift_reason = f"manual:{reason[:24]}"
    return True
