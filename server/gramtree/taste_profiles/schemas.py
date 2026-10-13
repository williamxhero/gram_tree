from itertools import pairwise
from typing import Annotated, Any, Literal

from pydantic import BaseModel, ConfigDict, Field, model_validator

from gramtree.core.ids import IdV4
from gramtree.core.time import Timestamp

FlavorKey = Literal["salty", "sweet", "sour", "spicy", "numbing", "umami", "oily"]
FLAVOR_KEYS: tuple[FlavorKey, ...] = ("salty", "sweet", "sour", "spicy", "numbing", "umami", "oily")
FiniteNumber = Annotated[float, Field(allow_inf_nan=False, strict=True)]


class TasteLevel(BaseModel):
    model_config = ConfigDict(extra="forbid")
    coefficient: FiniteNumber
    label: str = Field(min_length=1, max_length=32)


class TasteScale(BaseModel):
    model_config = ConfigDict(extra="forbid")
    minimum: FiniteNumber
    maximum: FiniteNumber
    default: FiniteNumber
    levels: list[TasteLevel] = Field(min_length=5, max_length=5)

    @model_validator(mode="after")
    def coherent(self) -> "TasteScale":
        values = [level.coefficient for level in self.levels]
        if not (
            0 < self.minimum < self.maximum
            and self.minimum <= values[0]
            and values[-1] <= self.maximum
        ):
            raise ValueError("口味档位范围配置不合法")
        if any(a >= b for a, b in pairwise(values)) or self.default != values[2]:
            raise ValueError("口味档位必须递增，默认值须对应标准档")
        return self


class IngredientPreference(BaseModel):
    model_config = ConfigDict(extra="forbid")
    ingredient_id: IdV4 | None = None
    category: str | None = Field(default=None, min_length=1, max_length=20)
    preference: Literal["liked", "disliked", "avoided"]

    @model_validator(mode="after")
    def one_target(self) -> "IngredientPreference":
        if (self.ingredient_id is None) == (self.category is None):
            raise ValueError("请选择一个标准食材或食材分类")
        return self


class IngredientPreferenceOut(IngredientPreference):
    name: str


class TasteProfilePatch(BaseModel):
    model_config = ConfigDict(extra="forbid")
    flavors: dict[FlavorKey, FiniteNumber] | None = Field(None, min_length=1, max_length=7)
    ingredient_preferences: list[IngredientPreference] | None = Field(None, max_length=100)

    @model_validator(mode="after")
    def explicit_changes(self) -> "TasteProfilePatch":
        if not self.model_fields_set or any(
            getattr(self, key) is None for key in self.model_fields_set
        ):
            raise ValueError("请提交要修改的字段；清除食材偏好请提交空列表")
        return self


class TasteFlavorOut(BaseModel):
    coefficient: float
    confidence: Literal["low", "high"]
    confidence_text: str
    level: int
    label: str


class LocalCuisineOut(BaseModel):
    cuisine: str
    adjustments: dict[FlavorKey, FiniteNumber]


class TasteProfileOut(BaseModel):
    id: IdV4
    version: int
    flavors: dict[str, TasteFlavorOut]
    scale: TasteScale
    local_cuisines: list[LocalCuisineOut]
    ingredient_preferences: list[IngredientPreferenceOut]
    ingredient_categories: list[str]


class TasteProfileChangeOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: IdV4
    version: int
    field: str
    old_value: dict[str, Any]
    new_value: dict[str, Any]
    reason: str
    source: Literal["manual", "learning"]
    origin: Literal["manual", "auto", "explicit_save"] = "manual"
    status: Literal["active", "reverted", "pending", "confirmed"]
    source_record_ids: list[str] = Field(default_factory=list)
    created_at: Timestamp
    reverted_at: Timestamp | None = None


LearningSignalKind = Literal[
    "manual_adjustment",
    "feedback_tag",
    "feedback_unanswered",
    "rating",
    "repeat_cook",
    "explicit_save",
    "skipped_recommendation",
    "favorite",
]


class TasteChangeStatusOut(BaseModel):
    """Revert-rate facts for SPEC-012 (auto changes only)."""

    auto_changes: int
    auto_reverted: int


class AttributionAnswer(BaseModel):
    model_config = ConfigDict(extra="forbid")
    answer: Literal["personal", "recipe", "unanswered"]


class AutomationOut(BaseModel):
    """Capability switch consumed by the app and by sibling tickets."""

    automatic_learning: bool
    save_to_taste: bool


class LearningRunOut(BaseModel):
    applied_changes: list[TasteProfileChangeOut]
    pending_suggestions: list[TasteProfileChangeOut]
    signals_considered: int


class FieldLockWrite(BaseModel):
    model_config = ConfigDict(extra="forbid")
    field: str = Field(min_length=1, max_length=100)
    locked: bool


class AttributionOut(BaseModel):
    record_id: str
    recipe_version_id: str | None = None
    verdict: Literal["personal", "recipe", "pending"]
    decision_source: Literal["rule", "user", "unanswered"]
    reason_code: str
    rules_version: str
    sample_size: int
    flavors: dict[str, int]
    learning_eligibility: Literal["strong", "reduced", "excluded"]
    asked: bool
    answered: bool
    updated_at: Timestamp


class AttributionStateOut(BaseModel):
    attribution: AttributionOut | None
    reason_text: str
