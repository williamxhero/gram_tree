from typing import Annotated, Any

from fastapi import APIRouter, Depends
from pydantic import BaseModel, ConfigDict, Field
from sqlalchemy import select

from gramtree.accounts.deps import CurrentAuth
from gramtree.core.errors import ERROR_RESPONSES, ErrorResponse, NotFound
from gramtree.core.ids import IdV4
from gramtree.core.pagination import Page, PageParams, check_limit, decode_cursor, encode_cursor, page_params
from gramtree.deps import SessionDep, SettingsDep
from gramtree.ingredients.attributes import GB_ALLERGENS
from gramtree.runtime_config import service as config
from gramtree.taste_profiles import allergies, service
from gramtree.taste_profiles.models import TasteProfile, TasteProfileChange
from gramtree.taste_profiles.schemas import TasteProfileChangeOut

router = APIRouter(prefix="/me/taste-profile/allergies", tags=["allergies"])
_ERRORS: dict[int | str, dict[str, Any]] = {**ERROR_RESPONSES, **{n: {"model": ErrorResponse} for n in (401, 403, 404, 409, 503)}}
PageDep = Annotated[PageParams, Depends(page_params)]


class AllergyIngredientOut(BaseModel):
    ingredient_id: IdV4
    name: str


class AllergiesOut(BaseModel):
    consent_id: IdV4 | None
    consent_version: str
    authorization_version: int
    profile_version: int
    available_categories: list[str]
    categories: list[str]
    ingredients: list[AllergyIngredientOut]


class AllergiesWrite(BaseModel):
    model_config = ConfigDict(extra="forbid")
    consent_id: IdV4
    authorization_version: int = Field(ge=0)
    categories: list[str] = Field(max_length=8)
    ingredient_ids: list[IdV4] = Field(max_length=100)


def _out(session: SessionDep, profile: TasteProfile, settings: SettingsDep) -> AllergiesOut:
    value = allergies.read_sensitive(session, profile, settings) if profile.sensitive_consent_id else allergies.EMPTY
    return AllergiesOut(
        consent_id=profile.sensitive_consent_id, consent_version=allergies.CONSENT_VERSION,
        authorization_version=profile.sensitive_authorization_version,
        profile_version=profile.version, available_categories=list(GB_ALLERGENS), **value,
    )


@router.get("", response_model=AllergiesOut, responses=_ERRORS)
def get_allergies(auth: CurrentAuth, session: SessionDep, settings: SettingsDep) -> AllergiesOut:
    profile = service.locked_profile(session, auth.user.id, service.scale_for(session))
    result = _out(session, profile, settings)
    session.commit()
    return result


@router.put("", response_model=AllergiesOut, responses=_ERRORS)
def set_allergies(body: AllergiesWrite, auth: CurrentAuth, session: SessionDep, settings: SettingsDep) -> AllergiesOut:
    profile = service.locked_profile(session, auth.user.id, service.scale_for(session))
    allergies.mutate_sensitive(session, profile, settings, **body.model_dump())
    result = _out(session, profile, settings)
    session.commit()
    return result


def _change_out(row: TasteProfileChange, settings: SettingsDep) -> TasteProfileChangeOut:
    result = TasteProfileChangeOut.model_validate(row)
    return result.model_copy(update=allergies.change_values(settings, row.owner_id, row))


@router.get("/changes", response_model=Page[TasteProfileChangeOut], responses=_ERRORS)
def list_allergy_changes(auth: CurrentAuth, session: SessionDep, settings: SettingsDep, page: PageDep) -> Page[TasteProfileChangeOut]:
    profile = service.locked_profile(session, auth.user.id, service.scale_for(session))
    allergies.require_grant(profile)
    check_limit(page.limit, config.get(session, "api.page_size_max"))
    query = select(TasteProfileChange).where(TasteProfileChange.owner_id == auth.user.id, TasteProfileChange.field == "allergies")
    if page.cursor:
        timestamp, row_id = decode_cursor(page.cursor)
        query = query.where((TasteProfileChange.created_at < timestamp) | ((TasteProfileChange.created_at == timestamp) & (TasteProfileChange.id < row_id)))
    rows = list(session.scalars(query.order_by(TasteProfileChange.created_at.desc(), TasteProfileChange.id.desc()).limit(page.limit + 1)))
    more = len(rows) > page.limit
    rows = rows[:page.limit]
    result = Page[TasteProfileChangeOut](items=[_change_out(row, settings) for row in rows], next_cursor=encode_cursor(rows[-1].created_at, rows[-1].id) if more else None)
    session.commit()
    return result


@router.get("/changes/{change_id}", response_model=TasteProfileChangeOut, responses=_ERRORS)
def get_allergy_change(change_id: IdV4, auth: CurrentAuth, session: SessionDep, settings: SettingsDep) -> TasteProfileChangeOut:
    profile = service.locked_profile(session, auth.user.id, service.scale_for(session))
    allergies.require_grant(profile)
    row = session.scalar(select(TasteProfileChange).where(TasteProfileChange.id == change_id, TasteProfileChange.owner_id == auth.user.id, TasteProfileChange.field == "allergies"))
    if row is None:
        raise NotFound()
    result = _change_out(row, settings)
    session.commit()
    return result
