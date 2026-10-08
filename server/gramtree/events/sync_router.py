"""Registered durable writes on the existing experience-event pipeline."""

import hashlib
import json
import uuid
from typing import Literal, cast

from fastapi import APIRouter, Request
from pydantic import BaseModel, Field, ValidationError
from sqlalchemy import select, text

from gramtree.accounts.deps import CurrentAuth
from gramtree.core.errors import ERROR_RESPONSES, ApiError
from gramtree.core.time import utcnow
from gramtree.deps import SessionDep
from gramtree.events.sync_contract import (
    WriteConflict,
    WriteDeferred,
    WriteEnvelope,
    WriteFailure,
    WriteResourceResult,
    WriteResult,
)
from gramtree.events.sync_models import WriteFactOutbox, WriteReceipt
from gramtree.events.sync_registry import REGISTERED_WRITES
from gramtree.runtime_config import service as config_service

router = APIRouter(prefix="/sync", tags=["sync"])


class WriteBatch(BaseModel):
    writes: list[WriteEnvelope] = Field(min_length=1)


class WriteBatchResponse(BaseModel):
    results: list[WriteResult]


def _fingerprint(write: WriteEnvelope) -> str:
    raw = json.dumps(write.model_dump(mode="json"), ensure_ascii=False, sort_keys=True)
    return hashlib.sha256(raw.encode()).hexdigest()


def _result(receipt: WriteReceipt, *, replay: bool = False) -> WriteResult:
    return WriteResult(
        write_id=receipt.write_id,
        status=cast(
            Literal["confirmed", "already_processed", "deferred", "conflict", "failed"],
            "already_processed" if replay and receipt.status == "confirmed" else receipt.status,
        ),
        reason_code=receipt.reason_code,
        result=WriteResourceResult.model_validate(receipt.result)
        if receipt.status == "confirmed"
        else None,
        conflict=receipt.result if receipt.status == "conflict" else None,
    )


def _process(session: SessionDep, owner: uuid.UUID, write: WriteEnvelope) -> WriteResult:
    # No identity-controlled receipt lookup, business lookup or content disclosure
    # happens before this check. Another account gets no result or existence hint.
    if write.owner_id != owner:
        return WriteResult(write_id=write.write_id, status="failed", reason_code="owner_mismatch")
    spec = REGISTERED_WRITES.get(write.write_type)
    if spec is None:
        return WriteResult(
            write_id=write.write_id, status="failed", reason_code="unknown_write_type"
        )
    try:
        parsed = spec.validate(write.payload)
        spec.authorize(session, owner, parsed)
    except (WriteFailure, ValidationError) as error:
        code = error.code if isinstance(error, WriteFailure) else "invalid_content"
        return WriteResult(write_id=write.write_id, status="failed", reason_code=code)

    # The transaction lock covers first receipt creation too (SELECT FOR UPDATE
    # cannot lock a row that doesn't exist). A collision only serializes unrelated
    # writes; it does not conflate IDs. Handlers must not acquire dependency locks.
    lock = int.from_bytes(hashlib.sha256(write.write_id.bytes).digest()[:8], "big", signed=True)
    session.execute(text("SELECT pg_advisory_xact_lock(:key)"), {"key": lock})
    receipt = session.get(WriteReceipt, write.write_id)
    fingerprint = _fingerprint(write)
    if receipt is not None:
        if receipt.owner_id != owner:
            session.rollback()
            return WriteResult(
                write_id=write.write_id, status="failed", reason_code="write_id_unavailable"
            )
        if receipt.fingerprint != fingerprint:
            session.rollback()
            return WriteResult(
                write_id=write.write_id, status="failed", reason_code="write_id_reused"
            )
        if receipt.status != "deferred":
            result = _result(receipt, replay=True)
            session.rollback()
            return result
    else:
        receipt = WriteReceipt(
            write_id=write.write_id,
            owner_id=owner,
            write_type=write.write_type,
            fingerprint=fingerprint,
            dependencies=[str(d) for d in write.dependencies],
            status="deferred",
            reason_code=None,
            result=None,
            received_at=utcnow(),
        )
        session.add(receipt)
        session.flush()
    try:
        dependencies = _dependencies(session, owner, write)
        resolved = spec.resolve_references(session, owner, parsed, dependencies)
        # A savepoint rolls back partial handler changes on business conflict or
        # failure, without losing the immutable receipt/reason saved below.
        with session.begin_nested():
            application = spec.apply(session, owner, write, resolved, utcnow())
            receipt.status = "confirmed"
            receipt.reason_code = None
            receipt.result = application.result.model_dump(mode="json")
            session.add(
                WriteFactOutbox(
                    write_id=write.write_id,
                    owner_id=owner,
                    facts=application.facts,
                    created_at=utcnow(),
                )
            )
    except WriteDeferred as error:
        receipt.status, receipt.reason_code = "deferred", error.code
    except WriteFailure as error:
        receipt.status, receipt.reason_code = "failed", error.code
    except WriteConflict as error:
        receipt.status, receipt.reason_code, receipt.result = (
            "conflict",
            "conflict_choice_required",
            error.copies,
        )
    # This is the only commit point. Any infrastructure failure rolls back the
    # business write, receipt AND outbox; response loss can safely replay all three.
    session.commit()
    return _result(receipt)


def _dependencies(
    session: SessionDep,
    owner: uuid.UUID,
    write: WriteEnvelope,
) -> dict[uuid.UUID, WriteResourceResult]:
    if len(set(write.dependencies)) != len(write.dependencies):
        raise WriteFailure("duplicate_dependency")
    # Include all this owner's deferred edges; never inspect another owner's
    # graph. An unknown ID is deferred, not interpreted as a business resource ID.
    graph = {
        row.write_id: [uuid.UUID(d) for d in row.dependencies]
        for row in session.scalars(select(WriteReceipt).where(WriteReceipt.owner_id == owner))
    }
    graph[write.write_id] = write.dependencies
    visiting: set[uuid.UUID] = set()
    visited: set[uuid.UUID] = set()

    def visit(node: uuid.UUID) -> None:
        if node in visiting:
            raise WriteFailure("dependency_cycle")
        if node in visited:
            return
        visiting.add(node)
        for child in graph.get(node, []):
            visit(child)
        visiting.remove(node)
        visited.add(node)

    visit(write.write_id)
    results = {}
    for dependency in write.dependencies:
        row = session.get(WriteReceipt, dependency)
        if row is None:
            raise WriteDeferred("dependency_not_arrived")
        if row.owner_id != owner:
            raise WriteFailure("dependency_unavailable")
        if row.status == "failed":
            raise WriteFailure("dependency_failed")
        if row.status == "conflict":
            raise WriteDeferred("dependency_conflict")
        if row.status != "confirmed":
            raise WriteDeferred("dependency_not_confirmed")
        results[dependency] = WriteResourceResult.model_validate(row.result)
    return results


@router.post(
    "/writes",
    response_model=WriteBatchResponse,
    responses=ERROR_RESPONSES,
    summary="按账号上传登记式离线写入；原子幂等处理，未知依赖暂缓",
)
def upload_writes(
    request: Request,
    body: WriteBatch,
    auth: CurrentAuth,
    session: SessionDep,
) -> WriteBatchResponse:
    limit = config_service.get(session, "events.upload_max_items")
    if len(body.writes) > limit:
        raise ApiError(422, "too_many_events", "写入条数超过上限")
    max_bytes = config_service.get(session, "events.upload_max_bytes")
    if int(request.headers.get("content-length", "0")) > max_bytes:
        raise ApiError(422, "payload_too_large", "写入请求超过上限")
    results = []
    for write in body.writes:
        results.append(_process(session, auth.user.id, write))
    return WriteBatchResponse(results=results)
