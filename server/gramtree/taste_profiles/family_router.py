from fastapi import APIRouter
from sqlalchemy import select

from gramtree.accounts.deps import CurrentAuth
from gramtree.core.ids import IdV4
from gramtree.core.pagination import Page, check_limit, decode_cursor, encode_cursor
from gramtree.deps import SessionDep, SettingsDep
from gramtree.ingredients.attributes import GB_ALLERGENS
from gramtree.runtime_config import service as config
from gramtree.taste_profiles import allergies, family, service
from gramtree.taste_profiles.allergy_router import _ERRORS, PageDep, _change_out
from gramtree.taste_profiles.family_schemas import (
    AGE_BANDS,
    FamilyMemberOut,
    FamilyMembersOut,
    FamilyMemberWrite,
)
from gramtree.taste_profiles.models import FamilyMember, TasteProfileChange
from gramtree.taste_profiles.schemas import TasteProfileChangeOut

router = APIRouter(prefix="/me/taste-profile/family-members", tags=["family-members"])


@router.get("", response_model=FamilyMembersOut, responses=_ERRORS)
def list_family_members(
    auth: CurrentAuth, session: SessionDep, settings: SettingsDep, page: PageDep
) -> FamilyMembersOut:
    profile = service.locked_profile(session, auth.user.id, service.scale_for(session))
    check_limit(page.limit, config.get(session, "api.page_size_max"))
    query = select(FamilyMember).where(FamilyMember.owner_id == auth.user.id)
    if page.cursor:
        timestamp, row_id = decode_cursor(page.cursor)
        query = query.where(
            (FamilyMember.created_at < timestamp)
            | ((FamilyMember.created_at == timestamp) & (FamilyMember.id < row_id))
        )
    rows = (
        list(
            session.scalars(
                query.order_by(FamilyMember.created_at.desc(), FamilyMember.id.desc()).limit(
                    page.limit + 1
                )
            )
        )
        if profile.sensitive_consent_id
        else []
    )
    more = len(rows) > page.limit
    rows = rows[: page.limit]
    result = FamilyMembersOut(
        consent_id=profile.sensitive_consent_id,
        consent_version=allergies.CONSENT_VERSION,
        authorization_version=profile.sensitive_authorization_version,
        profile_version=profile.version,
        available_age_bands=list(AGE_BANDS),
        available_allergen_categories=list(GB_ALLERGENS),
        members=[family.member_out(profile, row, settings) for row in rows],
        next_cursor=encode_cursor(rows[-1].created_at, rows[-1].id) if more else None,
    )
    session.commit()
    return result


@router.post("", response_model=FamilyMemberOut, status_code=201, responses=_ERRORS)
def create_family_member(
    body: FamilyMemberWrite, auth: CurrentAuth, session: SessionDep, settings: SettingsDep
) -> FamilyMemberOut:
    scale = service.scale_for(session)
    profile = service.locked_profile(session, auth.user.id, scale)
    row = family.write_member(session, profile, settings, scale, body)
    result = family.member_out(profile, row, settings)
    session.commit()
    return result


@router.get("/changes", response_model=Page[TasteProfileChangeOut], responses=_ERRORS)
def list_family_member_changes(
    auth: CurrentAuth, session: SessionDep, settings: SettingsDep, page: PageDep
) -> Page[TasteProfileChangeOut]:
    profile = service.locked_profile(session, auth.user.id, service.scale_for(session))
    allergies.require_grant(profile)
    check_limit(page.limit, config.get(session, "api.page_size_max"))
    query = select(TasteProfileChange).where(
        TasteProfileChange.owner_id == auth.user.id,
        TasteProfileChange.field.startswith(family.FAMILY_FIELD),
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
    result = Page[TasteProfileChangeOut](
        items=[_change_out(row, settings) for row in rows],
        next_cursor=encode_cursor(rows[-1].created_at, rows[-1].id) if more else None,
    )
    session.commit()
    return result


@router.get("/{member_id}", response_model=FamilyMemberOut, responses=_ERRORS)
def get_family_member(
    member_id: IdV4, auth: CurrentAuth, session: SessionDep, settings: SettingsDep
) -> FamilyMemberOut:
    profile = service.locked_profile(session, auth.user.id, service.scale_for(session))
    row = family.owned_member(session, auth.user.id, member_id)
    result = family.member_out(profile, row, settings)
    session.commit()
    return result


@router.put("/{member_id}", response_model=FamilyMemberOut, responses=_ERRORS)
def update_family_member(
    member_id: IdV4,
    body: FamilyMemberWrite,
    auth: CurrentAuth,
    session: SessionDep,
    settings: SettingsDep,
) -> FamilyMemberOut:
    scale = service.scale_for(session)
    profile = service.locked_profile(session, auth.user.id, scale)
    row = family.owned_member(session, auth.user.id, member_id)
    row = family.write_member(session, profile, settings, scale, body, row)
    result = family.member_out(profile, row, settings)
    session.commit()
    return result
