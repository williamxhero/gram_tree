from fastapi import APIRouter

from gramtree.accounts.deps import CurrentAuth
from gramtree.core.errors import ERROR_RESPONSES, ErrorResponse
from gramtree.deps import SessionDep
from gramtree.taste_profiles import constraint_service, service
from gramtree.taste_profiles.constraint_schemas import CookingConstraints, CookingConstraintsOut

router = APIRouter(prefix="/me/taste-profile/cooking-constraints", tags=["taste-profile"])
_ERRORS = {**ERROR_RESPONSES, 401: {"model": ErrorResponse}, 503: {"model": ErrorResponse}}


@router.get("", response_model=CookingConstraintsOut, responses=_ERRORS)
def get_cooking_constraints(auth: CurrentAuth, session: SessionDep) -> CookingConstraintsOut:
    profile = service.locked_profile(session, auth.user.id, service.scale_for(session))
    result = constraint_service.constraints_out(session, profile)
    session.commit()
    return result


@router.put("", response_model=CookingConstraintsOut, responses=_ERRORS)
def replace_cooking_constraints(
    body: CookingConstraints, auth: CurrentAuth, session: SessionDep
) -> CookingConstraintsOut:
    """Replace cooking settings; an empty object clears them.

    Omitted fields use empty defaults.
    """
    profile = service.locked_profile(session, auth.user.id, service.scale_for(session))
    constraint_service.replace_constraints(session, profile, body)
    result = constraint_service.constraints_out(session, profile)
    session.commit()
    return result
