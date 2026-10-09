"""One server-only model boundary, with fail-closed accounting and file replay.

Replay keys exclude user/trace IDs but include the exact semantic request and prompt
version. Recording is explicit and must use synthetic data, never production inputs.
"""

import hashlib
import json
import logging
import math
import time
import uuid
from collections.abc import Callable
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import httpx
from pydantic import BaseModel, Field
from sqlalchemy import func, select, text
from sqlalchemy.orm import Session

from gramtree.ai.models import AICall, GenerationLog
from gramtree.core.time import utcnow
from gramtree.observability import alerts
from gramtree.runtime_config import service as config
from gramtree.settings import Settings

PROMPT_VERSION = "one-line-v1"
PROMPTS = Path(__file__).with_name("prompts")
logger = logging.getLogger("gramtree.ai")


class ModelRoute(BaseModel):
    provider: str = Field(min_length=1, max_length=200)
    base_url: str = ""
    model: str = Field(min_length=1, max_length=200)
    input_price: float = Field(default=0, ge=0, allow_inf_nan=False)
    output_price: float = Field(default=0, ge=0, allow_inf_nan=False)

    @property
    def embedding_space(self) -> str:
        return hashlib.sha256(
            json.dumps([self.provider, self.base_url, self.model]).encode()
        ).hexdigest()


class Policy(BaseModel):
    timeout: float = Field(default=30, gt=0, le=120)
    retries: int = Field(default=0, ge=0, le=2)
    daily_limit: int = Field(default=50, ge=0, le=10000)
    users: dict[str, int] = Field(default_factory=dict)


@dataclass
class Unavailable(Exception):
    reason: str


def route(session: Session, capability: str) -> tuple[ModelRoute, Policy]:
    try:
        tier = config.get(session, "ai.routes")[capability]
        model = ModelRoute.model_validate(config.get(session, "ai.models")[tier])
        policy = Policy.model_validate(config.get(session, "ai.policies")[capability])
        return model, policy
    except (ValueError, KeyError, TypeError) as exc:
        raise Unavailable("configuration") from exc


def quota_capabilities(capability: str) -> tuple[str, ...]:
    return (
        ("modify", "modify_intent") if capability in ("modify", "modify_intent") else (capability,)
    )


def remaining(session: Session, user_id: uuid.UUID, capability: str) -> int:
    _, policy = route(session, "modify" if capability == "modify_intent" else capability)
    now = utcnow()
    midnight = now.replace(hour=0, minute=0, second=0, microsecond=0)
    used = (
        session.scalar(
            select(func.count(func.distinct(AICall.request_id))).where(
                AICall.user_id == user_id,
                AICall.capability.in_(quota_capabilities(capability)),
                AICall.created_at >= midnight,
            )
        )
        or 0
    )
    return max(0, policy.users.get(str(user_id), policy.daily_limit) - used)


def monthly_spend(session: Session) -> float:
    month = utcnow().replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    return float(
        session.scalar(
            select(func.coalesce(func.sum(AICall.cost + AICall.reserved_cost), 0)).where(
                AICall.created_at >= month
            )
        )
        or 0
    )


def availability(
    session: Session, settings: Settings, user_id: uuid.UUID, capability: str = "generate"
) -> dict[str, Any]:
    try:
        count = remaining(session, user_id, capability)
        reason = None
        if count == 0 and capability != "comparison":
            reason = "daily_quota"
        elif monthly_spend(session) + float(config.get(session, "ai.call_reservation")) > float(
            config.get(session, "ai.monthly_budget")
        ):
            reason = "monthly_budget"
        elif settings.ai_mode == "disabled":
            reason = "model_unavailable"
        else:
            model, _ = route(session, capability)
            if settings.ai_mode in ("live", "record") and (
                not settings.ai_api_key or not model.base_url
            ):
                reason = "model_unavailable"
        return {"remaining": count, "available": reason is None, "reason": reason}
    except Unavailable as exc:
        return {"remaining": 0, "available": False, "reason": exc.reason}


def _audit_payload(capability: str, payload: dict[str, Any]) -> dict[str, Any]:
    """Keep operational logs useful without copying user/model content."""
    raw = json.dumps(payload, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
    return {
        "capability": capability,
        "prompt_version": PROMPT_VERSION,
        "payload_sha256": hashlib.sha256(raw.encode()).hexdigest(),
        "keys": sorted(payload),
    }


def _audit_output(value: Any) -> dict[str, Any]:
    raw = value if isinstance(value, str) else json.dumps(value, ensure_ascii=False, sort_keys=True)
    return {
        "sha256": hashlib.sha256(raw.encode()).hexdigest(),
        "type": type(value).__name__,
        "length": len(raw),
    }


def replay_key(capability: str, payload: dict[str, Any]) -> str:
    raw = json.dumps(
        {"capability": capability, "prompt_version": PROMPT_VERSION, "input": payload},
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    )
    return hashlib.sha256(raw.encode()).hexdigest()


def _invoke(
    settings: Settings, model: ModelRoute, policy: Policy, capability: str, payload: dict[str, Any]
) -> dict[str, Any]:
    path = Path(settings.ai_replay_dir) / f"{replay_key(capability, payload)}.json"
    if settings.ai_mode == "replay":
        data = json.loads(path.read_text(encoding="utf-8"))
        if data.get("error"):
            raise Unavailable("model_unavailable")
        return data
    if settings.ai_mode == "disabled" or not model.base_url or not settings.ai_api_key:
        raise Unavailable("model_unavailable")
    headers = {"Authorization": f"Bearer {settings.ai_api_key}"}
    if capability == "embedding":
        endpoint = "embeddings"
        body = {"model": model.model, "input": payload["text"]}
    else:
        endpoint = "chat/completions"
        prompt = (PROMPTS / f"{capability}-{PROMPT_VERSION}.txt").read_text(encoding="utf-8")
        if capability in ("generate", "explain", "batch_advice"):
            from gramtree.ai.schemas import BatchAdvice, GeneratedDraft, ModelAnswer

            schema = {
                "generate": GeneratedDraft,
                "explain": ModelAnswer,
                "batch_advice": BatchAdvice,
            }[capability]
            prompt += "\nJSON schema: " + json.dumps(schema.model_json_schema(), ensure_ascii=False)
        if capability == "comparison":
            from gramtree.recipes.comparison_assistance import ComparisonModelOutput

            prompt += "\nJSON schema: " + json.dumps(
                ComparisonModelOutput.model_json_schema(), ensure_ascii=False
            )
        if capability in ("modify", "modify_intent"):
            from gramtree.ai.modification_schemas import ModificationIntent, ModificationOutput

            schema = ModificationOutput if capability == "modify" else ModificationIntent
            prompt += "\nJSON schema: " + json.dumps(schema.model_json_schema(), ensure_ascii=False)
        if capability == "quantify":
            from gramtree.recipes.quantification_schemas import QuantificationOutput

            prompt += "\nJSON schema: " + json.dumps(
                QuantificationOutput.model_json_schema(), ensure_ascii=False
            )
        body = {
            "model": model.model,
            "temperature": 0,
            "max_tokens": 4096,
            "response_format": {"type": "json_object"},
            "messages": [
                {"role": "system", "content": prompt},
                {"role": "user", "content": json.dumps(payload, ensure_ascii=False)},
            ],
        }
    response = httpx.post(
        f"{model.base_url.rstrip('/')}/{endpoint}",
        json=body,
        headers=headers,
        timeout=policy.timeout,
    )
    response.raise_for_status()
    raw = response.json()
    output = (
        raw["data"][0]["embedding"]
        if capability == "embedding"
        else raw["choices"][0]["message"]["content"]
    )
    data = {"output": output, "usage": raw.get("usage", {})}
    if settings.ai_mode == "record":
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
    return data


def call(
    session: Session,
    settings: Settings,
    user_id: uuid.UUID,
    capability: str,
    payload: dict[str, Any],
    operation_id: uuid.UUID,
    *,
    content_id: uuid.UUID | None = None,
    validate_output: Callable[[Any], Any] | None = None,
) -> Any:
    model, policy = route(session, capability)
    # Disabled/unconfigured providers never made a billable attempt. In particular,
    # background embedding retries must not exhaust quota or budget while disabled.
    if settings.ai_mode == "disabled" or (
        settings.ai_mode in ("live", "record") and (not model.base_url or not settings.ai_api_key)
    ):
        raise Unavailable("model_unavailable")
    result: Any = None
    for attempt in range(policy.retries + 1):
        # Short transaction reserves budget before I/O; simultaneous callers cannot
        # spend the same remaining budget. Failed/unknown usage keeps its reservation.
        session.execute(text("SELECT pg_advisory_xact_lock(330031)"))
        already_counted = session.scalar(
            select(AICall.id)
            .where(
                AICall.user_id == user_id,
                AICall.capability.in_(quota_capabilities(capability)),
                AICall.request_id == operation_id,
            )
            .limit(1)
        )
        # Shared comparison overlays are not user generation/modification operations.
        # They still use this same reservation, retry and actual-attempt ledger.
        if (
            capability != "comparison"
            and not already_counted
            and remaining(session, user_id, capability) == 0
        ):
            session.rollback()
            raise Unavailable("daily_quota")
        estimated_input = len(json.dumps(payload, ensure_ascii=False).encode()) + 16000
        reserve = max(
            float(config.get(session, "ai.call_reservation")),
            (estimated_input * model.input_price + 4096 * model.output_price) / 1_000_000,
        )
        budget = float(config.get(session, "ai.monthly_budget"))
        spend = monthly_spend(session)
        if spend + reserve > budget:
            session.rollback()
            raise Unavailable("monthly_budget")
        if (
            budget
            and spend
            < budget * float(config.get(session, "ai.budget_alert_ratio"))
            <= spend + reserve
        ):
            alerts.notify(session, "味谱 AI 月预算告警", "AI 调用预留成本已达到月预算告警阈值")
        row = AICall(
            user_id=user_id,
            request_id=operation_id,
            capability=capability,
            model=model.model,
            provider=model.provider,
            prompt_version=PROMPT_VERSION,
            content_id=content_id,
            reserved_cost=reserve,
        )
        session.add(row)
        session.flush()
        # Durable audit stores only a digest and field names. Full payload/response
        # remains transient in process memory for validation and replay matching.
        log = GenerationLog(call_id=row.id, input=_audit_payload(capability, payload))
        session.add(log)
        session.commit()
        start = time.monotonic()
        failure: Unavailable | None = None
        try:
            data = _invoke(settings, model, policy, capability, payload)
            usage = data.get("usage", {})
            row.input_tokens = max(0, int(usage.get("prompt_tokens", usage.get("total_tokens", 0))))
            row.output_tokens = max(0, int(usage.get("completion_tokens", 0)))
            row.cost = (
                row.input_tokens * model.input_price + row.output_tokens * model.output_price
            ) / 1_000_000
            if "prompt_tokens" in usage or "total_tokens" in usage:
                row.reserved_cost = 0
            result = data["output"]
            # Batch advice is untrusted until its schema/step references are checked.
            # Preserve raw output as text: JSONB rejects NaN in structured replay
            # objects before the caller can reject it and request one repair.
            log.output = _audit_output(result)
            # Semantic rejection is a failed actual attempt, not a free success.
            # Usage/cost already recorded above still belongs to that attempt.
            if validate_output is not None:
                result = validate_output(result)
            row.status = "succeeded"
        except (
            Unavailable,
            httpx.HTTPError,
            OSError,
            ValueError,
            KeyError,
            TypeError,
            AttributeError,
            IndexError,
        ) as exc:
            failure = exc if isinstance(exc, Unavailable) else Unavailable("model_unavailable")
            row.status = "failed"
            row.error_code = failure.reason
        row.duration_ms = int((time.monotonic() - start) * 1000)
        session.commit()
        logger.info(
            "ai call completed",
            extra={
                "capability": capability,
                "model": model.model,
                "status": row.status,
                "call_id": str(row.id),
                "cost": row.cost,
            },
        )
        if failure is None:
            return result
        if attempt == policy.retries:
            raise failure
    raise Unavailable("model_unavailable")


def embedding(value: Any) -> list[float]:
    if not isinstance(value, list) or not value or len(value) > 4096:
        raise Unavailable("invalid_embedding")
    values = [float(v) for v in value]
    if not all(math.isfinite(v) for v in values) or not any(values):
        raise Unavailable("invalid_embedding")
    return values
