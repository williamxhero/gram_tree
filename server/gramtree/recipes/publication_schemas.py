"""Publication state, actionable eligibility and durable notification contracts."""

from typing import Literal

from pydantic import BaseModel, ConfigDict, Field

from gramtree.core.ids import IdV4

PublicationState = Literal["draft", "published", "pending_verification"]


class PublicationCondition(BaseModel):
    code: str
    label: str
    action: str
    remaining_count: int | None = None


class PublicationPanel(BaseModel):
    state: Literal["draft", "published", "pending_verification", "withdrawn"]
    ever_public: bool
    automatically_publishes: bool = True
    missing: list[PublicationCondition] = Field(default_factory=list)
    baseline_version_id: IdV4 | None = None
    cumulative_conclusion: str | None = None
    rules_version: str | None = None
    high_risk: bool = False
    review_level: Literal["standard", "high"] = "standard"


class PublicationNotificationOut(BaseModel):
    id: IdV4
    recipe_id: IdV4
    version_id: IdV4
    version_number: int
    title: str
    message: str


class PublicationNotifications(BaseModel):
    items: list[PublicationNotificationOut] = Field(default_factory=list)
    next_cursor: str | None = None
    license_notice: str | None = None


class PublicationNotificationAck(BaseModel):
    model_config = ConfigDict(extra="forbid")

    notification_ids: list[IdV4] = Field(default_factory=list, max_length=100)
    license_seen: bool = False
