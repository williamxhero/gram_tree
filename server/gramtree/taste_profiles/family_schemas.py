from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, model_validator

from gramtree.core.ids import IdV4
from gramtree.taste_profiles.allergy_router import AllergyIngredientOut
from gramtree.taste_profiles.schemas import FiniteNumber, FlavorKey

AgeBand = Literal["under_1", "1_to_3", "3_to_6", "6_to_12", "12_to_18", "adult", "elder"]
AGE_BANDS: tuple[AgeBand, ...] = (
    "under_1",
    "1_to_3",
    "3_to_6",
    "6_to_12",
    "12_to_18",
    "adult",
    "elder",
)


class FamilyAvoidance(BaseModel):
    model_config = ConfigDict(extra="forbid")
    ingredient_id: IdV4 | None = None
    category: str | None = Field(default=None, min_length=1, max_length=20)

    @model_validator(mode="after")
    def one_target(self) -> "FamilyAvoidance":
        if (self.ingredient_id is None) == (self.category is None):
            raise ValueError("请选择一个标准食材或食材分类")
        return self


class FamilyAvoidanceOut(FamilyAvoidance):
    name: str


class FamilyAllergiesWrite(BaseModel):
    model_config = ConfigDict(extra="forbid")
    categories: list[str] = Field(default_factory=list, max_length=8)
    ingredient_ids: list[IdV4] = Field(default_factory=list, max_length=100)


class FamilyAllergiesOut(BaseModel):
    categories: list[str]
    ingredients: list[AllergyIngredientOut]


class FamilyMemberWrite(BaseModel):
    model_config = ConfigDict(extra="forbid")
    consent_id: IdV4
    authorization_version: int = Field(ge=0)
    nickname: str = Field(min_length=1, max_length=40)
    age_band: AgeBand
    flavors: dict[FlavorKey, FiniteNumber] = Field(default_factory=dict, max_length=7)
    avoidances: list[FamilyAvoidance] = Field(default_factory=list, max_length=100)
    allergies: FamilyAllergiesWrite = Field(default_factory=FamilyAllergiesWrite)

    @model_validator(mode="after")
    def meaningful_nickname(self) -> "FamilyMemberWrite":
        self.nickname = self.nickname.strip()
        if not self.nickname:
            raise ValueError("请填写称呼")
        return self


class FamilyMemberOut(BaseModel):
    id: IdV4
    nickname: str
    age_band: AgeBand
    flavors: dict[FlavorKey, float]
    avoidances: list[FamilyAvoidanceOut]
    allergies: FamilyAllergiesOut
    source: Literal["manual"]


class FamilyMembersOut(BaseModel):
    consent_id: IdV4 | None
    consent_version: str
    authorization_version: int
    profile_version: int
    available_age_bands: list[AgeBand]
    available_allergen_categories: list[str]
    items: list[FamilyMemberOut]
    next_cursor: str | None = None
