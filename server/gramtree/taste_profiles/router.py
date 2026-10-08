from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy import select

from gramtree.accounts.deps import CurrentAuth
from gramtree.core.errors import ERROR_RESPONSES, ErrorResponse, NotFound
from gramtree.core.ids import IdV4
from gramtree.core.pagination import (
    Page,
    PageParams,
    check_limit,
    decode_cursor,
    encode_cursor,
    page_params,
)
from gramtree.deps import SessionDep
from gramtree.runtime_config import service as config
from gramtree.taste_profiles import service
from gramtree.taste_profiles.models import TasteProfileChange
from gramtree.taste_profiles.schemas import (
    FLAVOR_KEYS,
    TasteProfileChangeOut,
    TasteProfileOut,
    TasteProfilePatch,
)

router = APIRouter(prefix="/me/taste-profile", tags=["taste-profile"])
_ERRORS = {
    **ERROR_RESPONSES,
    401: {"model": ErrorResponse},
    404: {"model": ErrorResponse},
    503: {"model": ErrorResponse},
}
PageDep = Annotated[PageParams, Depends(page_params)]


@router.get("", response_model=TasteProfileOut, responses=_ERRORS)
def get_taste_profile(auth: CurrentAuth, session: SessionDep) -> TasteProfileOut:
    scale = service.scale_for(session)
    profile = service.locked_profile(session, auth.user.id, scale)
    result = service.profile_out(profile, scale)
    session.commit()
    return result


@router.patch("", response_model=TasteProfileOut, responses=_ERRORS)
def update_taste_profile(
    body: TasteProfilePatch, auth: CurrentAuth, session: SessionDep
) -> TasteProfileOut:
    scale = service.scale_for(session)
    profile = service.locked_profile(session, auth.user.id, scale)
    service.mutate_profile(
        session,
        profile,
        body.flavors or {},
        scale,
        ingredient_preferences=body.ingredient_preferences,
    )
    result = service.profile_out(profile, scale)
    session.commit()
    return result


@router.post("/reset", response_model=TasteProfileOut, responses=_ERRORS)
def reset_taste_profile(auth: CurrentAuth, session: SessionDep) -> TasteProfileOut:
    scale = service.scale_for(session)
    profile = service.locked_profile(session, auth.user.id, scale)
    service.mutate_profile(
        session, profile, {key: scale.default for key in FLAVOR_KEYS}, scale, reset=True
    )
    result = service.profile_out(profile, scale)
    session.commit()
    return result


@router.get("/changes", response_model=Page[TasteProfileChangeOut], responses=_ERRORS)
def list_taste_profile_changes(
    auth: CurrentAuth, session: SessionDep, page: PageDep
) -> Page[TasteProfileChangeOut]:
    check_limit(page.limit, config.get(session, "api.page_size_max"))
    query = select(TasteProfileChange).where(
        TasteProfileChange.owner_id == auth.user.id, TasteProfileChange.field != "allergies"
    )
    if page.cursor:
        timestamp, row_id = decode_cursor(page.cursor)
        query = query.where(
            (TasteProfileChange.created_at < timestamp)
            | ((TasteProfileChange.created_at == timestamp) & (TasteProfileChange.id < row_id))
        )
    rows = list(
        session.scalars(
            query.order_by(
                TasteProfileChange.created_at.desc(), TasteProfileChange.id.desc()
            ).limit(page.limit + 1)
        )
    )
    more = len(rows) > page.limit
    rows = rows[: page.limit]
    return Page[TasteProfileChangeOut](
        items=[TasteProfileChangeOut.model_validate(row) for row in rows],
        next_cursor=encode_cursor(rows[-1].created_at, rows[-1].id) if more else None,
    )


@router.get("/changes/{change_id}", response_model=TasteProfileChangeOut, responses=_ERRORS)
def get_taste_profile_change(
    change_id: IdV4, auth: CurrentAuth, session: SessionDep
) -> TasteProfileChangeOut:
    row = session.scalar(
        select(TasteProfileChange).where(
            TasteProfileChange.id == change_id,
            TasteProfileChange.owner_id == auth.user.id,
            TasteProfileChange.field != "allergies",
        )
    )
    if row is None:
        raise NotFound()
    return TasteProfileChangeOut.model_validate(row)
