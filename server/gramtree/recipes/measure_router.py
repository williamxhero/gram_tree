"""Current-account measuring tools (SPEC-002.3 #117)."""

import uuid
from typing import Annotated, Any, Literal

from fastapi import APIRouter, Depends, Request, Response, status
from pydantic import BaseModel, ConfigDict, Field, field_validator
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError

from gramtree.accounts.deps import CurrentAuth
from gramtree.core.errors import ERROR_RESPONSES, ApiError, ErrorResponse, NotFound
from gramtree.core.ids import IdV4
from gramtree.core.pagination import (
    Page,
    PageParams,
    check_limit,
    decode_cursor,
    encode_cursor,
    page_params,
)
from gramtree.core.time import Timestamp, utcnow
from gramtree.deps import SessionDep
from gramtree.recipes.measure_display import display_amount, quantity_text
from gramtree.recipes.measure_models import PersonalMeasure
from gramtree.runtime_config import service as config
from gramtree.ui_protocol.protocol import SourceBasis, SourcedValue

router = APIRouter(prefix="/me/measures", tags=["personal-measures"])
_ERRORS = {
    **ERROR_RESPONSES,
    401: {"model": ErrorResponse},
    404: {"model": ErrorResponse},
    409: {"model": ErrorResponse},
}
MeasureKind = Literal["spoon", "bowl", "cup"]
DisplayMode = Literal["base", "standard", "home"]
PageDep = Annotated[PageParams, Depends(page_params)]


class PersonalMeasureInput(BaseModel):
    model_config = ConfigDict(extra="forbid")

    name: str = Field(min_length=1, max_length=64)
    kind: MeasureKind
    capacity_ml: float = Field(gt=0, le=10000, allow_inf_nan=False)

    @field_validator("name")
    @classmethod
    def clean_name(cls, value: str) -> str:
        value = value.strip()
        if not value:
            raise ValueError("量具名称不能为空")
        return value


class PersonalMeasureUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    name: str | None = Field(default=None, min_length=1, max_length=64)
    kind: MeasureKind | None = None
    capacity_ml: float | None = Field(default=None, gt=0, le=10000, allow_inf_nan=False)

    @field_validator("name")
    @classmethod
    def clean_name(cls, value: str | None) -> str | None:
        if value is None:
            return value
        value = value.strip()
        if not value:
            raise ValueError("量具名称不能为空")
        return value


class PersonalMeasureOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: IdV4
    name: str
    kind: MeasureKind
    capacity_ml: float
    created_at: Timestamp
    updated_at: Timestamp


class MeasureDisplayRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    base_quantity: float = Field(ge=0, allow_inf_nan=False)
    base_unit: Literal["g", "ml"]
    density: float | None = Field(default=None, gt=0, allow_inf_nan=False)
    mode: DisplayMode
    measure_id: IdV4 | None = None


class MeasureDisplayOut(BaseModel):
    text: str
    display_quantity: float
    display_unit: str
    grams: float | None = None
    rule: Literal["base", "standard_measure", "personal_measure", "no_density"]
    source: SourcedValue


def _owned(session: SessionDep, auth: CurrentAuth, measure_id: IdV4) -> PersonalMeasure:
    row = session.scalar(
        select(PersonalMeasure).where(
            PersonalMeasure.id == measure_id,
            PersonalMeasure.owner_id == auth.user.id,
            PersonalMeasure.deleted_at.is_(None),
        )
    )
    if row is None:
        raise NotFound()
    return row


def _commit(session: SessionDep) -> None:
    try:
        session.commit()
    except IntegrityError as exc:
        session.rollback()
        raise ApiError(409, "measure_name_taken", "这个量具名称已登记，请换一个名称") from exc


def _display_source(body: MeasureDisplayRequest, result: dict[str, object]) -> SourcedValue:
    original_unit = "克" if body.base_unit == "g" else "毫升"
    original_value = f"{quantity_text(body.base_quantity)} {original_unit}"
    changed = result["rule"] not in {"base", "no_density"}
    if result["rule"] == "no_density":
        basis_text = f"缺少密度数据，保留原始{original_unit}用量。"
        reason_code = "no_density"
    elif changed:
        display_name = "自家量具" if body.mode == "home" else "常用量具"
        basis_text = f"按{display_name}显示，仅改变显示方式，不修改原始用量。"
        reason_code = "measure_display"
    else:
        basis_text = "作者提供的基础用量。"
        reason_code = "author_filled"
    return SourcedValue(
        source_type="scenario_adjusted" if changed else "author_filled",
        value=str(result["text"]),
        original_value=original_value if changed else None,
        basis=SourceBasis(reason_code=reason_code, text=basis_text),
    )


@router.post("/display", response_model=MeasureDisplayOut, responses=_ERRORS)
def display_personal_measure(
    body: MeasureDisplayRequest, auth: CurrentAuth, session: SessionDep
) -> MeasureDisplayOut:
    personal_measure: PersonalMeasure | None = None
    if body.measure_id is not None:
        personal_measure = _owned(session, auth, body.measure_id)
    if body.mode == "home" and personal_measure is None:
        raise ApiError(422, "invalid_request", "请求参数有误", "自家量具模式需要 measure_id")
    result = display_amount(
        base_quantity=body.base_quantity,
        base_unit=body.base_unit,
        density=body.density,
        mode=body.mode,
        measure=(
            {
                "name": personal_measure.name,
                "kind": personal_measure.kind,
                "capacity_ml": personal_measure.capacity_ml,
            }
            if personal_measure is not None
            else None
        ),
    )
    return MeasureDisplayOut.model_validate({**result, "source": _display_source(body, result)})


@router.get("", response_model=Page[PersonalMeasureOut], responses=_ERRORS)
def list_personal_measures(
    auth: CurrentAuth, session: SessionDep, page: PageDep, request: Request, response: Response
) -> Page[PersonalMeasureOut]:
    from gramtree.events.field_adjudication import FieldHistory
    from gramtree.recipes.measure_sync import RESOURCE_TYPE, lock_owner

    raw = request.headers.get("X-Measure-Known-Writes", "")
    parts = raw.split(",") if raw else []
    try:
        if len(parts) > 100 or len(raw) > 3699:
            raise ValueError("too many writes")
        known = {uuid.UUID(part) for part in parts}
        if any(value.version != 4 for value in known) or any(
            str(uuid.UUID(part)) != part.lower() for part in parts
        ):
            raise ValueError("expected canonical UUID v4")
    except ValueError as exc:
        raise ApiError(422, "invalid_request", "量具写入标识有误") from exc
    # READ COMMITTED alone cannot make the row query and observed-history query
    # coherent. Mutations hold this same owner lock until their transaction ends.
    lock_owner(session, auth.user.id)
    observed = (
        set(
            session.scalars(
                select(FieldHistory.write_id).where(
                    FieldHistory.owner_id == auth.user.id,
                    FieldHistory.resource_type == RESOURCE_TYPE,
                    FieldHistory.write_id.in_(known),
                )
            )
        )
        if known
        else set()
    )
    response.headers["X-Measure-Observed-Writes"] = ",".join(sorted(map(str, observed)))
    # Every accepted edit retains history, even losses/unchanged values. Its
    # monotone count detects mutations between separate pages/ID chunks, so a
    # client can reject a mixed collection snapshot without trusting timestamps.
    response.headers["X-Measure-Snapshot-Version"] = str(
        session.scalar(
            select(func.count())
            .select_from(FieldHistory)
            .where(
                FieldHistory.owner_id == auth.user.id,
                FieldHistory.resource_type == RESOURCE_TYPE,
            )
        )
    )
    check_limit(page.limit, config.get(session, "api.page_size_max"))
    query = select(PersonalMeasure).where(
        PersonalMeasure.owner_id == auth.user.id, PersonalMeasure.deleted_at.is_(None)
    )
    if page.cursor:
        timestamp, row_id = decode_cursor(page.cursor)
        query = query.where(
            (PersonalMeasure.created_at > timestamp)
            | ((PersonalMeasure.created_at == timestamp) & (PersonalMeasure.id > row_id))
        )
    rows = list(
        session.scalars(
            query.order_by(PersonalMeasure.created_at, PersonalMeasure.id).limit(page.limit + 1)
        )
    )
    has_more = len(rows) > page.limit
    rows = rows[: page.limit]
    return Page[PersonalMeasureOut](
        items=[PersonalMeasureOut.model_validate(row) for row in rows],
        next_cursor=encode_cursor(rows[-1].created_at, rows[-1].id) if has_more else None,
    )


@router.post("", response_model=PersonalMeasureOut, status_code=201, responses=_ERRORS)
def create_personal_measure(
    body: PersonalMeasureInput, auth: CurrentAuth, session: SessionDep
) -> PersonalMeasureOut:
    measure_id = uuid.uuid4()
    _online_change(session, auth, measure_id, "create", body.model_dump())
    return PersonalMeasureOut.model_validate(_owned(session, auth, measure_id))


@router.get("/{measure_id}", response_model=PersonalMeasureOut, responses=_ERRORS)
def get_personal_measure(
    measure_id: IdV4, auth: CurrentAuth, session: SessionDep
) -> PersonalMeasureOut:
    return PersonalMeasureOut.model_validate(_owned(session, auth, measure_id))


@router.patch("/{measure_id}", response_model=PersonalMeasureOut, responses=_ERRORS)
def update_personal_measure(
    measure_id: IdV4, body: PersonalMeasureUpdate, auth: CurrentAuth, session: SessionDep
) -> PersonalMeasureOut:
    _owned(session, auth, measure_id)
    values = body.model_dump(exclude_unset=True)
    if any(value is None for value in values.values()):
        raise ApiError(422, "invalid_request", "量具字段不能为 null")
    if values:
        _online_change(session, auth, measure_id, "update", values)
    return PersonalMeasureOut.model_validate(_owned(session, auth, measure_id))


@router.delete("/{measure_id}", status_code=status.HTTP_204_NO_CONTENT, responses=_ERRORS)
def delete_personal_measure(measure_id: IdV4, auth: CurrentAuth, session: SessionDep) -> None:
    _owned(session, auth, measure_id)
    _online_change(session, auth, measure_id, "delete", {"deleted": True})


def _online_change(
    session: SessionDep, auth: CurrentAuth, measure_id: IdV4, action: str, values: dict[str, Any]
) -> None:
    from gramtree.events.sync_contract import WriteEnvelope, WriteFailure
    from gramtree.recipes.measure_sync import apply, validate

    now = utcnow()
    payload = {
        "resource_id": str(measure_id),
        "action": action,
        "fields": {key: {"value": value, "device_time": now} for key, value in values.items()},
    }
    write = WriteEnvelope(
        format_version=1,
        write_type="personal_measure.change",
        write_id=uuid.uuid4(),
        owner_id=auth.user.id,
        device_time=now,
        payload=payload,
    )
    try:
        apply(session, auth.user.id, write, validate(payload), now)
        _commit(session)
    except WriteFailure as exc:
        session.rollback()
        raise ApiError(409, exc.code, "这个量具名称已登记，请换一个名称") from exc


class MeasureHistoryOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: IdV4
    write_id: IdV4
    field: str
    device_time: Timestamp
    old_value: Any
    new_value: Any
    outcome: Literal["won", "lost", "unchanged", "tombstoned"]


@router.get("/{measure_id}/history", response_model=Page[MeasureHistoryOut], responses=_ERRORS)
def personal_measure_history(
    measure_id: IdV4, auth: CurrentAuth, session: SessionDep, page: PageDep
) -> Page[MeasureHistoryOut]:
    from gramtree.events.field_adjudication import FieldHistory

    # Retained deleted identities still have owner-readable history.
    row = session.get(PersonalMeasure, measure_id)
    if row is None or row.owner_id != auth.user.id:
        raise NotFound()
    check_limit(page.limit, config.get(session, "api.page_size_max"))
    query = select(FieldHistory).where(
        FieldHistory.owner_id == auth.user.id,
        FieldHistory.resource_type == "personal_measure",
        FieldHistory.resource_id == measure_id,
    )
    if page.cursor:
        timestamp, row_id = decode_cursor(page.cursor)
        query = query.where(
            (FieldHistory.device_time > timestamp)
            | ((FieldHistory.device_time == timestamp) & (FieldHistory.id > row_id))
        )
    rows = list(
        session.scalars(
            query.order_by(FieldHistory.device_time, FieldHistory.id).limit(page.limit + 1)
        )
    )
    has_more = len(rows) > page.limit
    rows = rows[: page.limit]
    return Page[MeasureHistoryOut](
        items=[MeasureHistoryOut.model_validate(row) for row in rows],
        next_cursor=encode_cursor(rows[-1].device_time, rows[-1].id) if has_more else None,
    )
