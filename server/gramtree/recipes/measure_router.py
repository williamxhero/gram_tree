"""Current-account measuring tools (SPEC-002.3 #117)."""

from typing import Literal

from fastapi import APIRouter, status
from pydantic import BaseModel, ConfigDict, Field, field_validator
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError

from gramtree.accounts.deps import CurrentAuth
from gramtree.core.errors import ERROR_RESPONSES, ApiError, ErrorResponse, NotFound
from gramtree.core.ids import IdV4
from gramtree.core.time import Timestamp, utcnow
from gramtree.deps import SessionDep
from gramtree.recipes.measure_models import PersonalMeasure

router = APIRouter(prefix="/me/measures", tags=["personal-measures"])
_ERRORS = {
    **ERROR_RESPONSES,
    401: {"model": ErrorResponse},
    404: {"model": ErrorResponse},
    409: {"model": ErrorResponse},
}
MeasureKind = Literal["spoon", "bowl", "cup"]


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


def _owned(session: SessionDep, auth: CurrentAuth, measure_id: IdV4) -> PersonalMeasure:
    row = session.scalar(
        select(PersonalMeasure).where(
            PersonalMeasure.id == measure_id, PersonalMeasure.owner_id == auth.user.id
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


@router.get("", response_model=list[PersonalMeasureOut], responses=_ERRORS)
def list_personal_measures(auth: CurrentAuth, session: SessionDep) -> list[PersonalMeasureOut]:
    rows = session.scalars(
        select(PersonalMeasure)
        .where(PersonalMeasure.owner_id == auth.user.id)
        .order_by(PersonalMeasure.created_at, PersonalMeasure.id)
    )
    return [PersonalMeasureOut.model_validate(row) for row in rows]


@router.post("", response_model=PersonalMeasureOut, status_code=201, responses=_ERRORS)
def create_personal_measure(
    body: PersonalMeasureInput, auth: CurrentAuth, session: SessionDep
) -> PersonalMeasureOut:
    row = PersonalMeasure(owner_id=auth.user.id, **body.model_dump())
    session.add(row)
    _commit(session)
    return PersonalMeasureOut.model_validate(row)


@router.get("/{measure_id}", response_model=PersonalMeasureOut, responses=_ERRORS)
def get_personal_measure(
    measure_id: IdV4, auth: CurrentAuth, session: SessionDep
) -> PersonalMeasureOut:
    return PersonalMeasureOut.model_validate(_owned(session, auth, measure_id))


@router.patch("/{measure_id}", response_model=PersonalMeasureOut, responses=_ERRORS)
def update_personal_measure(
    measure_id: IdV4, body: PersonalMeasureUpdate, auth: CurrentAuth, session: SessionDep
) -> PersonalMeasureOut:
    row = _owned(session, auth, measure_id)
    for key, value in body.model_dump(exclude_unset=True).items():
        if value is None:
            raise ApiError(422, "invalid_request", "量具字段不能为 null")
        setattr(row, key, value)
    row.updated_at = utcnow()
    _commit(session)
    return PersonalMeasureOut.model_validate(row)


@router.delete("/{measure_id}", status_code=status.HTTP_204_NO_CONTENT, responses=_ERRORS)
def delete_personal_measure(measure_id: IdV4, auth: CurrentAuth, session: SessionDep) -> None:
    row = _owned(session, auth, measure_id)
    session.delete(row)
    session.commit()
