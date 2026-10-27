"""记录 API schemas: only explicit caller data is stored."""

from typing import Any, Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator

from gramtree.core.ids import IdV4
from gramtree.core.time import Timestamp

Meal = Literal["breakfast", "lunch", "dinner", "snack"]
RecordSource = Literal[
    "cooking_session", "recommendation", "calendar", "external_cooking", "dining"
]
Verification = Literal["cooking_mode", "unverified"]


class CookingCompletion(BaseModel):
    model_config = ConfigDict(extra="forbid")

    session_id: IdV4
    execution_token: str = Field(min_length=64, max_length=64, pattern=r"^[0-9a-f]{64}$")
    status: Literal["completed"]
    started_at: Timestamp
    finished_at: Timestamp
    reached_steps: list[str] = Field(max_length=200)
    completed_steps: list[str] = Field(max_length=200)
    skipped_steps: list[str] = Field(default_factory=list, max_length=200)


class CookingRecordCreate(BaseModel):
    client_id: IdV4
    recipe_id: IdV4 | None = None
    recipe_version_id: IdV4 | None = None
    dish_name: str | None = Field(default=None, min_length=1, max_length=200)
    source: RecordSource = "cooking_session"
    meal: Meal | None = None
    occurred_at: Timestamp | None = None
    snapshot: dict[str, Any] | None = None
    adjustments: list[dict[str, Any]] = Field(default_factory=list)
    source_context: dict[str, Any] = Field(default_factory=dict)
    co_diner_ids: list[IdV4] = Field(default_factory=list, max_length=50)
    verification: Verification = "unverified"
    # Record photos are explicit private evidence from this cooking record. They
    # are never inferred from the recipe snapshot, which may contain public media.
    photos: list[str] = Field(default_factory=list, max_length=3)
    completion: CookingCompletion | None = None

    @field_validator("photos")
    @classmethod
    def validate_photos(cls, value: list[str]) -> list[str]:
        for photo in value:
            if len(photo) > 180_000 or not photo.startswith("data:image/jpeg;base64,"):
                raise ValueError("记录照片必须是受限的 JPEG data URI")
        return value


class CookingRecordOut(BaseModel):
    id: IdV4
    client_id: IdV4
    recipe_id: IdV4 | None
    recipe_version_id: IdV4 | None
    dish_name: str | None
    source: RecordSource
    verification: Verification
    counts_as_cooked: bool
    meal: Meal | None
    occurred_at: Timestamp
    snapshot: dict[str, Any] | None
    adjustments: list[dict[str, Any]]
    source_context: dict[str, Any]
    taste_summary: dict[str, Any]
    co_diner_ids: list[IdV4]
    photos: list[str]
    created_at: Timestamp


class CookingRecordRevisionCreate(BaseModel):
    revision_id: IdV4
    field: Literal["rating", "feedback", "tags", "adjustments"]
    value: dict[str, Any]
    note: str = ""


class CookingRecordRevisionOut(BaseModel):
    revision_id: IdV4
    revision: int
    field: str
    value: dict[str, Any]
    note: str
    created_at: Timestamp


class CookingRecordHistoryOut(BaseModel):
    items: list[CookingRecordRevisionOut]


class CookingRecordListOut(BaseModel):
    items: list[CookingRecordOut]
    next_cursor: str | None = None
