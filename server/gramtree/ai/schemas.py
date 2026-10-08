from typing import Literal

from pydantic import BaseModel, ConfigDict, Field

from gramtree.core.ids import IdV4
from gramtree.recipes.schemas import RecipeCreate, RecipeSafetyResult


class AIStatus(BaseModel):
    remaining: int
    available: bool
    reason: str | None = None


class OneLineInput(BaseModel):
    text: str = Field(min_length=1, max_length=1000, pattern=r"\S")


class RecipeIntent(BaseModel):
    model_config = ConfigDict(extra="forbid")

    dish_name: str = Field(min_length=1, max_length=200)
    servings: int | None = Field(default=None, ge=1, le=1000)
    taste: list[str] = Field(default_factory=list, max_length=20)
    restrictions: list[str] = Field(default_factory=list, max_length=20)
    cookware: list[str] = Field(default_factory=list, max_length=20)


class Question(BaseModel):
    key: Literal["servings", "cookware"]
    text: str
    default: str


class SimilarRecipe(BaseModel):
    recipe_id: IdV4
    version_id: IdV4
    dish_name: str
    servings: int
    ai_assisted: bool
    basis: str


class RetrievalResult(BaseModel):
    request_id: IdV4
    text: str
    intent: RecipeIntent
    recipes: list[SimilarRecipe]
    questions: list[Question]
    status: AIStatus
    local_fallback: bool = False


class GenerateInput(BaseModel):
    model_config = ConfigDict(extra="forbid")
    servings: int | None = Field(default=None, ge=1, le=1000)
    cookware: str | None = Field(default=None, max_length=200)


class GeneratedDraft(BaseModel):
    model_config = ConfigDict(extra="forbid")
    recipe: RecipeCreate
    rationale: str = Field(min_length=1, max_length=4000)
    cuisine: str = Field(min_length=1, max_length=100)


class GenerationResult(BaseModel):
    request_id: IdV4
    status: AIStatus
    draft: GeneratedDraft | None = None
    safety: RecipeSafetyResult | None = None
    numeric_warnings: list[str] = Field(default_factory=list)
    ingredient_confirmations: list[str] = Field(default_factory=list)
    error: str | None = None


class ExistingChoice(BaseModel):
    recipe_id: IdV4


class RecipeQuestion(BaseModel):
    model_config = ConfigDict(extra="forbid")
    question: str = Field(min_length=1, max_length=1000, pattern=r"\S")


class ModelAnswer(BaseModel):
    """Model text is untrusted; provenance and safety are server decisions."""

    model_config = ConfigDict(extra="forbid")
    state: Literal["answered", "uncertain", "cannot_answer"]
    kitchen_scope: bool
    confidence: float = Field(ge=0, le=1, allow_inf_nan=False)
    conclusion: str = Field(min_length=1, max_length=2000)
    explanation: str = Field(min_length=1, max_length=4000)
    details: str = Field(default="", max_length=4000)


class RecipeAnswer(BaseModel):
    recipe_id: IdV4
    version_id: IdV4
    question: str
    state: Literal["answered", "uncertain", "cannot_answer", "unavailable"]
    capability: Literal["explain"] = "explain"
    status: AIStatus
    source: Literal["ai_estimated"] = "ai_estimated"
    basis: Literal["general_experience"] = "general_experience"
    basis_text: str = "这是一般经验，还没有足够记录验证"
    conclusion: str
    explanation: str = ""
    details: str = ""
    safety: RecipeSafetyResult
    numeric_warnings: list[str] = Field(default_factory=list)
    error: str | None = None
