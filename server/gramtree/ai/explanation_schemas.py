"""Optional change descriptions; the server derives the facts, never the client."""

from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator

from gramtree.ai.schemas import AIStatus
from gramtree.core.ids import IdV4
from gramtree.recipes.schemas import RecipeSnapshot, RecipeSnapshotInput


class ChangeExplanationInput(BaseModel):
    model_config = ConfigDict(extra="forbid")

    modification_id: IdV4 | None = None
    revision: int | None = Field(default=None, ge=0)
    recipe_id: IdV4 | None = None
    base_version_id: IdV4 | None = None
    generation_request_id: IdV4 | None = None
    snapshot: RecipeSnapshot | None = None

    @field_validator("snapshot")
    @classmethod
    def refuse_client_verified(cls, value: RecipeSnapshot | None) -> RecipeSnapshot | None:
        return RecipeSnapshotInput(snapshot=value).snapshot if value is not None else None

    @model_validator(mode="after")
    def one_target(self):
        if self.modification_id is not None:
            if self.revision is None or any(
                v is not None
                for v in (
                    self.recipe_id,
                    self.base_version_id,
                    self.generation_request_id,
                    self.snapshot,
                )
            ):
                raise ValueError("确认操作说明只需要修改请求和当前选择版本")
        elif self.generation_request_id is not None:
            if self.snapshot is None or any(
                v is not None for v in (self.recipe_id, self.base_version_id, self.revision)
            ):
                raise ValueError("生成结果的手动修改需要生成请求和新快照")
        elif (
            self.recipe_id is None
            or self.base_version_id is None
            or self.snapshot is None
            or self.revision is not None
        ):
            raise ValueError("手动修改需要本人菜谱、基准版本和新快照")
        return self


class ChangeExplanationOutput(BaseModel):
    model_config = ConfigDict(extra="forbid", strict=True)

    change_note: str = Field(min_length=1, max_length=2000, pattern=r"\S")
    tags: list[str] = Field(default_factory=list, max_length=50)

    @field_validator("tags")
    @classmethod
    def valid_tags(cls, values: list[str]) -> list[str]:
        if any(not value.strip() or len(value) > 100 for value in values):
            raise ValueError("标签不能为空且不超过 100 个字")
        return list(dict.fromkeys(value.strip() for value in values))


class ChangeExplanationResult(BaseModel):
    status: AIStatus
    change_note: str | None = None
    tags: list[str] = Field(default_factory=list)
    source: Literal["ai_estimated"] | None = None
    changes_fingerprint: str
    error: str | None = None
