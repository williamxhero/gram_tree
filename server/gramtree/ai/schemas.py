from typing import Literal

from pydantic import BaseModel, ConfigDict, Field

from gramtree.core.ids import IdV4
from gramtree.recipes.schemas import RecipeCreate, RecipeSafetyResult


class AIStatus(BaseModel):
    remaining: int
    available: bool
    reason: str | None = None


class BatchAdviceInput(BaseModel):
    model_config = ConfigDict(extra="forbid", strict=True)

    target_servings: int = Field(ge=1, le=1000)


class BatchStepAdvice(BaseModel):
    model_config = ConfigDict(extra="forbid", strict=True)

    step_id: str = Field(min_length=1, max_length=100, pattern=r"\S")
    suggested_duration_seconds: int = Field(ge=1, le=86400)
    batch_count: int = Field(ge=1, le=100)
    batch_guidance: str = Field(min_length=1, max_length=1000, pattern=r"\S")
    doneness: str = Field(min_length=1, max_length=1000, pattern=r"\S")
    basis: str = Field(min_length=1, max_length=1000, pattern=r"\S")
    risk: str = Field(min_length=1, max_length=1000, pattern=r"\S")
    confidence: float = Field(ge=0, le=1, allow_inf_nan=False)
    source: Literal["ai_estimated"]


class BatchAdvice(BaseModel):
    model_config = ConfigDict(extra="forbid", strict=True)

    steps: list[BatchStepAdvice] = Field(min_length=1, max_length=200)
    basis: str = Field(min_length=1, max_length=2000, pattern=r"\S")
    risk: str = Field(min_length=1, max_length=2000, pattern=r"\S")


class RecipeBatchAdviceOut(BaseModel):
    recipe_id: IdV4
    version_id: IdV4
    original_servings: int
    target_servings: int
    eligible: bool
    status: AIStatus
    advice: BatchAdvice | None = None
    error: str | None = None


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
