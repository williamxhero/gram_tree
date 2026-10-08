"""Owned, finite text-edit proposals; snapshots are results, never client patches."""

from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, JsonValue, model_validator

from gramtree.ai.schemas import AIStatus
from gramtree.core.ids import IdV4
from gramtree.recipes.schemas import RecipeReproducibilityResult, RecipeSafetyResult, RecipeSnapshot


class ModificationInput(BaseModel):
    model_config = ConfigDict(extra="forbid")
    text: str = Field(min_length=1, max_length=1000, pattern=r"\S")
    request_id: IdV4 | None = None
    retry_failed: bool = False
    recipe_id: IdV4 | None = None
    base_version_id: IdV4 | None = None
    generation_request_id: IdV4 | None = None

    @model_validator(mode="after")
    def one_target(self):
        if self.generation_request_id is not None:
            if self.recipe_id is not None or self.base_version_id is not None:
                raise ValueError("只能选择一个修改入口")
        elif self.recipe_id is None or self.base_version_id is None:
            raise ValueError("需要本人菜谱和基准版本，或本人生成请求")
        return self


class ModificationIntent(BaseModel):
    model_config = ConfigDict(extra="forbid")
    category: Literal[
        "taste", "cookware", "substitution", "time_difficulty", "method", "text", "unknown"
    ]
    parameters: dict[str, str | float | bool | None] = Field(default_factory=dict)
    confidence: float = Field(ge=0, le=1, allow_inf_nan=False)


class ModificationOperation(BaseModel):
    model_config = ConfigDict(extra="forbid", strict=True)
    operation_id: str = Field(min_length=1, max_length=100, pattern=r"\S")
    # These names are the existing SPEC-002.2 vocabulary, not a generic patch.
    type: Literal[
        "change_step_field",
        "change_step_duration",
        "change_step_heat",
        "change_preparation",
        "change_display_name",
        "change_recipe_info",
    ]
    id: str | None = Field(default=None, max_length=100)
    field: str = Field(min_length=1, max_length=100)
    before: JsonValue
    after: JsonValue
    scope: list[str] = Field(min_length=1, max_length=20)
    intent: str = Field(min_length=1, max_length=1000, pattern=r"\S")
    reason: str = Field(min_length=1, max_length=2000, pattern=r"\S")
    risk: str = Field(min_length=1, max_length=2000, pattern=r"\S")
    confidence: float = Field(ge=0, le=1, allow_inf_nan=False)
    depends_on: list[str] = Field(default_factory=list, max_length=100)


class ModificationOutput(BaseModel):
    model_config = ConfigDict(extra="forbid")
    operations: list[ModificationOperation] = Field(max_length=100)
    explanation: str | None = Field(default=None, min_length=1, max_length=2000, pattern=r"\S")

    @model_validator(mode="after")
    def explained_noop(self):
        if not self.operations and self.explanation is None:
            raise ValueError("无法修改时需要明确说明原因")
        return self


class ModificationDecision(BaseModel):
    model_config = ConfigDict(extra="forbid")
    operation_id: str = Field(min_length=1, max_length=100)
    decision: Literal["accept", "reject", "modify"]
    after: JsonValue = None

    @model_validator(mode="after")
    def only_modified_value(self):
        if self.decision != "modify" and "after" in self.model_fields_set:
            raise ValueError("仅修改时可以提供后值")
        if self.decision == "modify" and "after" not in self.model_fields_set:
            raise ValueError("修改需要明确的后值")
        return self


class ModificationDecisionOut(BaseModel):
    operation_id: str
    decision: Literal["pending", "accept", "reject", "modify"]
    after: JsonValue = None
    blocked_by: list[str] = Field(default_factory=list)


class ModificationDecisionsInput(BaseModel):
    model_config = ConfigDict(extra="forbid")
    decisions: list[ModificationDecision] = Field(default_factory=list, max_length=100)


class ModificationConfirmInput(BaseModel):
    model_config = ConfigDict(extra="forbid")
    revision: int = Field(ge=0)
    change_note: str = Field(default="", max_length=2000)
    tags: list[str] | None = Field(default=None, max_length=50)
    explanation_fingerprint: str | None = Field(
        default=None, min_length=64, max_length=64, pattern=r"^[0-9a-f]{64}$"
    )


class ModificationPreview(BaseModel):
    id: IdV4
    revision: int
    recipe_id: IdV4 | None = None
    base_version_id: IdV4 | None = None
    generation_request_id: IdV4 | None = None
    intent: ModificationIntent | None = None
    operations: list[ModificationOperation] = Field(default_factory=list)
    decisions: list[ModificationDecisionOut] = Field(default_factory=list)
    snapshot: RecipeSnapshot
    safety: RecipeSafetyResult
    reproducibility: RecipeReproducibilityResult
    status: AIStatus
    warnings: list[str] = Field(default_factory=list)
    error: str | None = None
