"""The client supplies edits, never ancestry or publication evidence."""

from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, model_validator

from gramtree.core.ids import IdV4
from gramtree.recipes.full_comparison import RecipeFullComparison
from gramtree.recipes.schemas import RecipeDetail, RecipeSnapshot


class ImprovementDraftInput(BaseModel):
    model_config = ConfigDict(extra="forbid")
    source_version_id: IdV4


class ImprovementDraftOut(BaseModel):
    id: IdV4
    source_recipe_id: IdV4
    source_version_id: IdV4
    snapshot: RecipeSnapshot
    dish_name: str
    ai_assisted: bool


class ImprovementPreviewInput(BaseModel):
    model_config = ConfigDict(extra="forbid")
    source_version_id: IdV4
    snapshot: RecipeSnapshot | None = None
    modification_request_id: IdV4 | None = None
    modification_revision: int | None = Field(default=None, ge=0)
    from_cooking_record_id: IdV4 | None = None
    change_note: str = Field(default="", max_length=2000)
    explanation_fingerprint: str | None = Field(default=None, pattern=r"^[0-9a-f]{64}$")

    @model_validator(mode="after")
    def one_edit(self):
        if self.modification_request_id is not None:
            if self.snapshot is not None or self.from_cooking_record_id is not None:
                raise ValueError("一句话修改不能同时提交配方或做菜记录")
            if self.modification_revision is None:
                raise ValueError("需要修改预览的选择版本")
        return self


class ImprovementSaveInput(ImprovementPreviewInput):
    request_id: IdV4
    microadjust_choice: Literal["branch", "taste"] | None = None
    expected_profile_version: int | None = Field(default=None, ge=1)


class ImprovementTasteProposal(BaseModel):
    convertible: bool
    reason: str | None = None
    profile_version: int | None = None
    coefficients: dict[str, float] = Field(default_factory=dict)


class ImprovementPreviewOut(BaseModel):
    snapshot: RecipeSnapshot
    comparison: RecipeFullComparison
    microadjust_prompt: str | None = None
    taste_proposal: ImprovementTasteProposal


class RecordVersionSaveInput(BaseModel):
    model_config = ConfigDict(extra="forbid")
    request_id: IdV4
    change_note: str = Field(default="临场调整", max_length=2000)


class ImprovementSaveOut(BaseModel):
    outcome: Literal["branch", "taste"]
    recipe: RecipeDetail | None = None
    profile_version: int | None = None
