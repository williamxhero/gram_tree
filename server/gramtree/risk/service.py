from __future__ import annotations

import hashlib
import hmac
import ipaddress
import logging
import re
import time
from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import Literal, cast

from redis import Redis
from sqlalchemy.orm import Session

from gramtree.accounts.models import User
from gramtree.core.errors import ApiError
from gramtree.core.time import utcnow
from gramtree.risk.captcha import CaptchaAdapter, CaptchaChallenge
from gramtree.risk.models import RiskAction, RiskEvent
from gramtree.runtime_config import service as config
from gramtree.settings import Settings

logger = logging.getLogger("gramtree.risk")

RiskLevel = Literal["captcha", "throttle", "temporary_block", "permanent_block"]
_SUBJECTS = ("account", "device", "ip")
_DETAIL_RE = re.compile(r"^/v1/(?:recipes|ingredients)/([^/]+)(?:/|$)")
_BYPASS_PREFIXES = ("/v1/health", "/v1/dev", "/v1/client-config", "/v1/risk/captcha")


class RiskActionError(ApiError):
    def __init__(
        self, level: RiskLevel, *, retry_after: int | None = None, challenge: str | None = None
    ):
        if level == "captcha":
            status, code, message = 403, "risk_captcha_required", "请完成安全验证后继续"
        elif level == "throttle":
            status, code, message = 429, "risk_slowed", "请求频率需要降低，请稍后再试"
        elif level == "temporary_block":
            status, code, message = 403, "risk_temporarily_blocked", "当前访问暂时受限，请稍后再试"
        else:
            status, code, message = 403, "risk_permanently_blocked", "当前访问已被限制，请联系支持"
        super().__init__(status, code, message, None)
        if retry_after is not None:
            self.retry_after = retry_after
        self.headers = {"X-Risk-Level": level}
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


def _now_ts(now: datetime) -> float:
    return now.timestamp()


def _category(path: str) -> str:
    if "/search" in path or "/list" in path:
        return "search_list"
    if "/ai/" in path:
        return "ai"
    if path.startswith("/v1/auth/"):
        return "auth"
    if path.startswith("/v1/me"):
        return "account"
    return "other"


def _is_detail(path: str) -> bool:
    return _DETAIL_RE.match(path) is not None and "/search" not in path


def _subnet(ip: str | None) -> str | None:
    if not ip:
        return None
    try:
        address = ipaddress.ip_address(ip)
    except ValueError:
        return None
    network = (
        ipaddress.ip_network(f"{ip}/24", strict=False)
        if address.version == 4
        else ipaddress.ip_network(f"{ip}/64", strict=False)
    )
    return str(network.network_address) + ("/24" if address.version == 4 else "/64")


def _active_action(
    redis: Redis, subject: Subject, now: datetime
) -> tuple[RiskLevel, int | None] | None:
    raw = redis.hget(f"risk:enforcement:{subject.kind}:{subject.value}", "level")
    if raw is None:
        return None
    level = raw.decode() if isinstance(raw, bytes) else str(raw)
    if level == "captcha":
        return "captcha", None
    # Redis command annotations also cover async clients; this service uses sync Redis.
    ends = cast(
        bytes | str | None,
        redis.hget(f"risk:enforcement:{subject.kind}:{subject.value}", "ends_at"),
    )
    if ends is not None:
        end = int(ends)
        if end <= int(_now_ts(now)):
            redis.delete(f"risk:enforcement:{subject.kind}:{subject.value}")
            return None
        return level, end - int(_now_ts(now))  # type: ignore[return-value]
    return level, None  # type: ignore[return-value]


def _level_for(score: int, previous: str | None, session: Session) -> RiskLevel | None:
    thresholds = (
        ("permanent_block", _int(session, "risk.permanent_block_points")),
        ("temporary_block", _int(session, "risk.temporary_block_points")),
        ("throttle", _int(session, "risk.throttle_points")),
        ("captcha", _int(session, "risk.captcha_points")),
    )
    current: RiskLevel | None = None
    for level, threshold in thresholds:
        if score >= threshold:
            current = level  # type: ignore[assignment]
            break
    order: tuple[RiskLevel, ...] = ("captcha", "throttle", "temporary_block", "permanent_block")
    if previous in order:
        index = order.index(previous) + 1
        if current is None or order.index(current) < index:
            current = order[min(index, len(order) - 1)]
    return current


def _active_level(redis: Redis, subject: Subject) -> str | None:
    raw = redis.hget(f"risk:state:{subject.kind}:{subject.value}", "level")
    return raw.decode() if isinstance(raw, bytes) else (str(raw) if raw is not None else None)


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


def _activate(
    redis: Redis,
    session: Session,
    subject: Subject,
    level: RiskLevel,
    rule: str,
    evidence: dict[str, object],
    now: datetime,
    captcha: CaptchaAdapter,
) -> str | None:
    key = f"risk:enforcement:{subject.kind}:{subject.value}"
    existing = _active_action(redis, subject, now)
    if existing is not None and existing[0] == level:
        challenge = cast(
            bytes | str | None,
            redis.hget(f"risk:captcha:{subject.kind}:{subject.value}", "challenge_id"),
        )
        return challenge.decode() if isinstance(challenge, bytes) else challenge
    ends_at: datetime | None = None
    if level == "throttle":
        ends_at = now + timedelta(seconds=_int(session, "risk.throttle_seconds"))
    elif level == "temporary_block":
        ends_at = now + timedelta(seconds=_int(session, "risk.temporary_block_seconds"))
    action = RiskAction(
        subject_type=subject.kind,
        subject_key_hash=subject.value,
        rule=rule,
        evidence=evidence,
        level=level,
        started_at=now,
        ends_at=ends_at,
    )
    session.add(action)
    session.flush()
    mapping: dict[str, str | int] = {"level": level, "action_id": str(action.id)}
    if ends_at:
        mapping["ends_at"] = int(ends_at.timestamp())
    redis.hset(key, mapping=mapping)
    redis.expire(key, _int(session, "risk.retention_seconds"))
    if level == "captcha":
        issued = captcha.issue(subject.value, now)
        redis.hset(
            f"risk:captcha:{subject.kind}:{subject.value}",
            mapping={"challenge_id": issued.challenge_id, "prompt": issued.prompt},
        )
        redis.expire(
            f"risk:captcha:{subject.kind}:{subject.value}", _int(session, "risk.captcha_seconds")
        )
        return issued.challenge_id
    return None


def _apply_signal(
    redis: Redis,
    session: Session,
    settings: Settings,
    subject: Subject,
    rule: str,
    evidence: dict[str, object],
    points: int,
    now: datetime,
    captcha: CaptchaAdapter,
) -> RiskDecision | None:
    score_key = f"risk:score:{subject.kind}:{subject.value}"
    score = cast(int, redis.incrby(score_key, points))
    redis.expire(score_key, _int(session, "risk.score_ttl_seconds"))
    previous = _active_level(redis, subject)
    _record(session, subject, rule, evidence, points, now)
    level = _level_for(score, previous, session)
    if level is None:
        session.commit()
        return None
    redis.hset(f"risk:state:{subject.kind}:{subject.value}", "level", level)
    redis.expire(
        f"risk:state:{subject.kind}:{subject.value}", _int(session, "risk.retention_seconds")
    )
    challenge = _activate(redis, session, subject, level, rule, evidence, now, captcha)
    session.commit()
    retry = None
    if level == "throttle":
        retry = _int(session, "risk.throttle_seconds")
    elif level == "temporary_block":
        retry = _int(session, "risk.temporary_block_seconds")
    return RiskDecision(level, retry, challenge)


def _window_count(redis: Redis, key: str, now: datetime, seconds: int) -> int:
    timestamp = _now_ts(now)
    redis.zremrangebyscore(key, 0, timestamp - seconds)
    redis.zadd(key, {f"{timestamp}:{time.monotonic_ns()}": timestamp})
    redis.expire(key, seconds * 2)
    return cast(int, redis.zcard(key))


def _observe_one(
    redis: Redis,
    session: Session,
    settings: Settings,
    subject: Subject,
    path: str,
    now: datetime,
    captcha: CaptchaAdapter,
) -> RiskDecision | None:
    active = _active_action(redis, subject, now)
    if active is not None:
        level, retry = active
        challenge = cast(
            bytes | str | None,
            redis.hget(f"risk:captcha:{subject.kind}:{subject.value}", "challenge_id"),
        )
        return RiskDecision(
            level, retry, challenge.decode() if isinstance(challenge, bytes) else challenge
        )
    window = _int(session, "risk.short_window_seconds")
    count = _window_count(redis, f"risk:requests:{subject.kind}:{subject.value}", now, window)
    if count >= _int(session, "risk.short_request_limit"):
        return _apply_signal(
            redis,
            session,
            settings,
            subject,
            "short_burst",
            {"count": count, "window_seconds": window, "category": _category(path)},
            10,
            now,
            captcha,
        )
    uniform_key = f"risk:uniform:{subject.kind}:{subject.value}"
    timestamp = _now_ts(now)
    redis.zremrangebyscore(uniform_key, 0, timestamp - 86400)
    redis.zadd(uniform_key, {f"{timestamp}:{time.monotonic_ns()}": timestamp})
    redis.expire(uniform_key, 2 * 86400)
    uniform_count = cast(int, redis.zcard(uniform_key))
    if uniform_count >= _int(session, "risk.uniform_daily_limit"):
        first = cast(list[tuple[bytes, float]], redis.zrange(uniform_key, 0, 0, withscores=True))
        last = cast(list[tuple[bytes, float]], redis.zrange(uniform_key, -1, -1, withscores=True))
        span_hours = ((float(last[0][1]) - float(first[0][1])) / 3600) if first and last else 0
        if span_hours >= _int(session, "risk.uniform_min_span_hours"):
            return _apply_signal(
                redis,
                session,
                settings,
                subject,
                "uniform_daily_access",
                {"count": uniform_count, "span_hours": round(span_hours, 2)},
                15,
                now,
                captcha,
            )
    if _is_detail(path):
        detail_key = f"risk:detail:{subject.kind}:{subject.value}"
        previous = cast(bytes | None, redis.get(detail_key))
        previous_at = float(previous) if previous is not None else None
        redis.set(detail_key, str(_now_ts(now)), ex=window)
        if previous_at is not None and _now_ts(now) - previous_at <= int(
            config.get(session, "risk.detail_interval_seconds")
        ):
            rapid_key = f"risk:rapid:{subject.kind}:{subject.value}"
            rapid = cast(int, redis.incr(rapid_key))
            redis.expire(rapid_key, window)
            if rapid >= _int(session, "risk.detail_repeat_limit"):
                return _apply_signal(
                    redis,
                    session,
                    settings,
                    subject,
                    "rapid_detail",
                    {
                        "repeat_count": rapid,
                        "interval_seconds": int(
                            config.get(session, "risk.detail_interval_seconds")
                        ),
                    },
                    10,
                    now,
                    captcha,
                )
    identifier = _DETAIL_RE.match(path)
    if identifier:
        sequence_key = f"risk:sequence:{subject.kind}:{subject.value}"
        previous_id = cast(bytes | None, redis.get(sequence_key))
        current_id = identifier.group(1)
        if previous_id is not None and previous_id.decode() != current_id:
            redis.set(sequence_key, current_id, ex=window)
            sequential = cast(int, redis.incr(f"{sequence_key}:count"))
            redis.expire(f"{sequence_key}:count", window)
            if sequential >= _int(session, "risk.sequential_limit"):
                return _apply_signal(
                    redis,
                    session,
                    settings,
                    subject,
                    "sequential_detail",
                    {"distinct_count": sequential, "category": _category(path)},
                    15,
                    now,
                    captcha,
                )
        else:
            redis.set(sequence_key, current_id, ex=window)
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
    subjects = []
    if ip:
        subjects.append(_subject("ip", ip, settings))
    if device_id:
        subjects.append(_subject("device", device_id, settings))
    for subject in subjects:
        decision = _observe_one(redis, session, settings, subject, path, current, captcha)
        if decision is not None and decision.blocked:
            return decision
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
    if not enabled(session):
        return None
    account = _subject("account", user_id, settings)
    decision = _observe_one(redis, session, settings, account, path, now, captcha)
    if decision:
        return decision
    if device_id:
        device = _subject("device", device_id, settings)
        members_key = f"risk:device-accounts:{device.value}"
        redis.sadd(members_key, account.value)
        redis.expire(members_key, _int(session, "risk.score_ttl_seconds"))
        count = cast(int, redis.scard(members_key))
        if count >= _int(session, "risk.multi_account_limit"):
            return _apply_signal(
                redis,
                session,
                settings,
                device,
                "multi_account_device",
                {"account_count": count},
                20,
                now,
                captcha,
            )
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
    decision = observe_account(
        redis,
        session,
        settings,
        user_id=str(user.id),
        device_id=device_id,
        ip=ip,
        path="/v1/auth/login",
        now=now,
        captcha=captcha,
    )
    if decision:
        return decision
    subnet = _subnet(ip)
    if subnet and is_new_account:
        subject = _subject("ip", f"subnet:{subnet}", settings)
        key = f"risk:new-accounts:{subject.value}"
        count = cast(int, redis.incr(key))
        redis.expire(key, _int(session, "risk.short_window_seconds"))
        if count >= _int(session, "risk.subnet_new_account_limit"):
            return _apply_signal(
                redis,
                session,
                settings,
                subject,
                "subnet_new_accounts",
                {
                    "account_count": count,
                    "window_seconds": _int(session, "risk.short_window_seconds"),
                },
                20,
                now,
                captcha,
            )
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
    """Record a non-secret signal from signing/rate-limit boundaries.

    Callers pass only the stable subject and rule name; credentials, nonce values and
    request bodies never become evidence or log fields.
    """
    subject = _subject(subject_type, subject_value[:256], settings)
    return _apply_signal(
        redis,
        session,
        settings,
        subject,
        rule,
        {"signal": rule},
        10 if rule == "signature_failure" else 15,
        now,
        captcha,
    )


def verify_captcha(
    redis: Redis,
    session: Session,
    settings: Settings,
    adapter: CaptchaAdapter,
    *,
    challenge_id: str,
    response: str,
    now: datetime,
) -> bool:
    found: tuple[str, str, str] | None = None
    for kind in _SUBJECTS:
        pattern = f"risk:captcha:{kind}:*"
        for key in redis.scan_iter(match=pattern):
            stored = redis.hget(key, "challenge_id")
            if (
                stored is not None
                and (stored.decode() if isinstance(stored, bytes) else str(stored)) == challenge_id
            ):
                suffix = key.decode() if isinstance(key, bytes) else key
                found = (
                    kind,
                    suffix.rsplit(":", 1)[-1],
                    key.decode() if isinstance(key, bytes) else key,
                )
                break
        if found:
            break
    if found is None:
        return False
    kind, subject_hash, captcha_key = found
    challenge = CaptchaChallenge(challenge_id, "请完成安全验证")
    if not adapter.verify(challenge, response, now):
        return False
    action_key = f"risk:enforcement:{kind}:{subject_hash}"
    action_id = redis.hget(action_key, "action_id")
    if action_id:
        action = session.get(
            RiskAction, action_id.decode() if isinstance(action_id, bytes) else str(action_id)
        )
        if action and action.lifted_at is None:
            action.lifted_at = now
            action.lift_reason = "captcha"
    redis.delete(action_key, captcha_key)
    redis.set(f"risk:score:{kind}:{subject_hash}", 0, ex=_int(session, "risk.score_ttl_seconds"))
    session.commit()
    return True
