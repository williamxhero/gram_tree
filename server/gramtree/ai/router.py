from fastapi import APIRouter

from gramtree.accounts.deps import CurrentAuth
from gramtree.ai import gateway
from gramtree.ai.schemas import AIStatus
from gramtree.core.errors import ERROR_RESPONSES
from gramtree.deps import SessionDep, SettingsDep

router = APIRouter(prefix="/ai/recipes", tags=["recipe-ai"], responses=ERROR_RESPONSES)


@router.get("/status", response_model=AIStatus)
def recipe_ai_status(auth: CurrentAuth, session: SessionDep, settings: SettingsDep) -> AIStatus:
    return AIStatus.model_validate(gateway.availability(session, settings, auth.user.id))
