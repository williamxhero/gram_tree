from fastapi import APIRouter

from gramtree.accounts.deps import CurrentAuth
from gramtree.ai import answers, gateway, modifications, service
from gramtree.ai.modification_schemas import (
    ModificationConfirmInput,
    ModificationDecisionsInput,
    ModificationInput,
    ModificationPreview,
)
from gramtree.ai.schemas import (
    AIStatus,
    ExistingChoice,
    GenerateInput,
    GenerationResult,
    OneLineInput,
    RecipeAnswer,
    RecipeQuestion,
    RetrievalResult,
)
from gramtree.core.errors import ERROR_RESPONSES
from gramtree.core.ids import IdV4
from gramtree.deps import RedisDep, SessionDep, SettingsDep
from gramtree.recipes.schemas import RecipeCreate, RecipeDetail

router = APIRouter(prefix="/ai/recipes", tags=["recipe-ai"], responses=ERROR_RESPONSES)


@router.get(
    "/modifications/status", response_model=AIStatus, operation_id="recipe_modification_status"
)
def modification_status(auth: CurrentAuth, session: SessionDep, settings: SettingsDep) -> AIStatus:
    return AIStatus.model_validate(gateway.availability(session, settings, auth.user.id, "modify"))


@router.post(
    "/modifications", response_model=ModificationPreview, operation_id="propose_recipe_modification"
)
def propose_modification(
    body: ModificationInput,
    auth: CurrentAuth,
    session: SessionDep,
    redis: RedisDep,
    settings: SettingsDep,
) -> ModificationPreview:
    return modifications.propose(session, redis, settings, auth.user, body)


@router.get(
    "/modifications/{modification_id}",
    response_model=ModificationPreview,
    operation_id="get_recipe_modification",
)
def get_modification(
    modification_id: IdV4, auth: CurrentAuth, session: SessionDep, settings: SettingsDep
) -> ModificationPreview:
    return modifications.get(session, settings, auth.user, modification_id)


@router.post(
    "/modifications/{modification_id}/decisions",
    response_model=ModificationPreview,
    operation_id="decide_recipe_modification",
)
def decide_modification(
    modification_id: IdV4,
    body: ModificationDecisionsInput,
    auth: CurrentAuth,
    session: SessionDep,
    redis: RedisDep,
    settings: SettingsDep,
) -> ModificationPreview:
    return modifications.decide(session, redis, settings, auth.user, modification_id, body)


@router.post(
    "/modifications/{modification_id}/confirm",
    response_model=RecipeDetail,
    status_code=201,
    operation_id="confirm_recipe_modification",
)
def confirm_modification(
    modification_id: IdV4,
    body: ModificationConfirmInput,
    auth: CurrentAuth,
    session: SessionDep,
    redis: RedisDep,
    settings: SettingsDep,
) -> RecipeDetail:
    return modifications.confirm(session, redis, settings, auth.user, modification_id, body)


@router.get("/status", response_model=AIStatus)
def recipe_ai_status(auth: CurrentAuth, session: SessionDep, settings: SettingsDep) -> AIStatus:
    return AIStatus.model_validate(gateway.availability(session, settings, auth.user.id))


@router.post("/requests", response_model=RetrievalResult)
def find_recipe_for_request(
    body: OneLineInput,
    auth: CurrentAuth,
    session: SessionDep,
    redis: RedisDep,
    settings: SettingsDep,
) -> RetrievalResult:
    return service.begin(session, redis, settings, auth.user, body.text.strip())


@router.post("/requests/{request_id}/existing", response_model=RecipeDetail)
def choose_existing_recipe(
    request_id: IdV4,
    body: ExistingChoice,
    auth: CurrentAuth,
    session: SessionDep,
    redis: RedisDep,
    settings: SettingsDep,
) -> RecipeDetail:
    return service.choose_existing(session, redis, settings, auth.user, request_id, body.recipe_id)


@router.post("/requests/{request_id}/generate", response_model=GenerationResult)
def generate_recipe_draft(
    request_id: IdV4,
    body: GenerateInput,
    auth: CurrentAuth,
    session: SessionDep,
    redis: RedisDep,
    settings: SettingsDep,
) -> GenerationResult:
    return service.generate(session, redis, settings, auth.user, request_id, body)


@router.post("/requests/{request_id}/save", response_model=RecipeDetail, status_code=201)
def save_generated_recipe(
    request_id: IdV4,
    body: RecipeCreate,
    auth: CurrentAuth,
    session: SessionDep,
    redis: RedisDep,
    settings: SettingsDep,
) -> RecipeDetail:
    return service.save(session, redis, settings, auth.user, request_id, body)


@router.post("/{recipe_id}/versions/{version_id}/answer", response_model=RecipeAnswer)
def answer_recipe_question(
    recipe_id: IdV4,
    version_id: IdV4,
    body: RecipeQuestion,
    auth: CurrentAuth,
    session: SessionDep,
    settings: SettingsDep,
) -> RecipeAnswer:
    return answers.answer(
        session, settings, auth.user, recipe_id, version_id, body.question.strip()
    )
