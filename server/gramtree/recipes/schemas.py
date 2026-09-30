"""菜谱 HTTP 请求与响应模型。

快照是版本的公开边界：所有可编辑字段在这里定义，服务层只负责校验、补充基础量和
派生信息，不把 ORM 对象暴露给客户端。
"""

import uuid
from typing import Any, Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator

from gramtree.core.ids import IdV4
from gramtree.core.time import Timestamp

SourceType = Literal["author_filled", "ai_estimated", "verified"]


class ValueSource(BaseModel):
    model_config = ConfigDict(extra="forbid")

    source: SourceType
    original: str | None = Field(..., json_schema_extra={"title": None})
    confidence: float | None = Field(..., json_schema_extra={"title": None})
    basis: str | None = Field(..., json_schema_extra={"title": None})

    @model_validator(mode="before")
    @classmethod
    def fill_nullable(cls, value: object) -> object:
        if isinstance(value, dict):
            return {
                "source": "author_filled",
                "original": None,
                "confidence": None,
                "basis": None,
                **value,
            }
        return value

    @field_validator("confidence")
    @classmethod
    def valid_confidence(cls, value: float | None) -> float | None:
        if value is not None and not 0 <= value <= 1:
            raise ValueError("把握程度必须在 0 到 1 之间")
        return value


class DishInput(BaseModel):
    name: str = Field(min_length=1, max_length=200)
    aliases: list[str] = Field(default_factory=list, max_length=20)

    @field_validator("name")
    @classmethod
    def non_blank_name(cls, value: str) -> str:
        value = value.strip()
        if not value:
            raise ValueError("菜名不能为空")
        return value

    @field_validator("aliases")
    @classmethod
    def clean_aliases(cls, values: list[str]) -> list[str]:
        result: list[str] = []
        for value in values:
            value = value.strip()
            if value and value not in result:
                result.append(value)
        return result


class RecipeReplacement(BaseModel):
    model_config = ConfigDict(extra="forbid")

    ingredient_id: uuid.UUID | None = Field(..., json_schema_extra={"title": None})
    display_name: str = Field(min_length=1, max_length=200)
    ratio: float = Field(default=1, gt=0, le=100)
    note: str | None = Field(..., json_schema_extra={"title": None})

    @model_validator(mode="before")
    @classmethod
    def fill_nullable(cls, value: object) -> object:
        if isinstance(value, dict):
            filled = {"ingredient_id": None, "note": None, **value}
            if filled["ingredient_id"] == "":
                filled["ingredient_id"] = None
            return filled
        return value

    @field_validator("ingredient_id")
    @classmethod
    def v4_ingredient_id(cls, value: uuid.UUID | None) -> uuid.UUID | None:
        if value is not None and value.version != 4:
            raise ValueError("ID 必须是 UUID v4")
        return value


class RecipeIngredient(BaseModel):
    model_config = ConfigDict(extra="forbid")

    id: str = Field(min_length=1, max_length=100, description="菜谱内食材 ID")
    ingredient_id: uuid.UUID | None = Field(
        ..., description="标准食材 UUID；为空表示未收录", json_schema_extra={"title": None}
    )
    display_name: str = Field(min_length=1, max_length=200)
    quantity: float = Field(ge=0, le=10_000_000)
    unit: str = Field(min_length=1, max_length=20)
    # 服务端保存的统一基础量；作者只需填写 quantity/unit。
    base_quantity: float | None = Field(
        ..., description="换算后的基础数量", json_schema_extra={"title": None}
    )
    base_unit: Literal["g", "ml", "count"] | None = Field(
        ..., description="换算后的基础单位", json_schema_extra={"title": None}
    )
    preparation: str | None = Field(..., description="处理方式", json_schema_extra={"title": None})
    group: str | None = Field(..., description="食材分组", json_schema_extra={"title": None})
    optional: bool = False
    replacement: RecipeReplacement | str | None = Field(
        default=None, json_schema_extra={"title": None}
    )
    functional: bool = False
    scaling_mode: Literal["proportional", "unchanged", "round"]
    quantity_source: ValueSource | None = None

    @model_validator(mode="before")
    @classmethod
    def fill_nullable(cls, value: object) -> object:
        if isinstance(value, dict):
            filled = {
                "ingredient_id": None,
                "base_quantity": None,
                "base_unit": None,
                "preparation": None,
                "group": None,
                "scaling_mode": "proportional",
                **value,
            }
            if filled["ingredient_id"] == "":
                filled["ingredient_id"] = None
            return filled
        return value

    @field_validator("display_name", "unit")
    @classmethod
    def non_blank_text(cls, value: str) -> str:
        value = value.strip()
        if not value:
            raise ValueError("文字不能为空")
        return value

    @field_validator("ingredient_id")
    @classmethod
    def v4_ingredient_id(cls, value: uuid.UUID | None) -> uuid.UUID | None:
        if value is not None and value.version != 4:
            raise ValueError("ID 必须是 UUID v4")
        return value


class RecipeStep(BaseModel):
    model_config = ConfigDict(extra="forbid")

    id: str = Field(min_length=1, max_length=100, description="步骤 ID")
    action: str | None = Field(..., json_schema_extra={"title": None})
    instruction: str = Field(min_length=1, max_length=2000)
    ingredient_ids: list[str] = Field(default_factory=list, max_length=100)
    duration_seconds: int = Field(default=0, ge=0, le=86400)
    unattended: bool = False
    heat: str | None = Field(..., json_schema_extra={"title": None})
    temperature_celsius: float | None = Field(..., json_schema_extra={"title": None})
    cookware: str | None = Field(..., json_schema_extra={"title": None})
    doneness: str | None = Field(..., json_schema_extra={"title": None})
    depends_on: list[str] = Field(default_factory=list, max_length=100)
    notes: str | None = Field(..., json_schema_extra={"title": None})
    why: str | None = Field(..., json_schema_extra={"title": None})
    duration_source: ValueSource | None = None
    heat_source: ValueSource | None = None
    temperature_source: ValueSource | None = None

    @model_validator(mode="before")
    @classmethod
    def fill_nullable(cls, value: object) -> object:
        if isinstance(value, dict):
            return {
                "action": None,
                "heat": None,
                "temperature_celsius": None,
                "cookware": None,
                "doneness": None,
                "notes": None,
                "why": None,
                **value,
            }
        return value

    @field_validator("temperature_celsius")
    @classmethod
    def reasonable_temperature(cls, value: float | None) -> float | None:
        if value is not None and not -50 <= value <= 1000:
            raise ValueError("温度超出合理范围")
        return value


class NutritionEstimate(BaseModel):
    energy_kcal: float | None = Field(..., json_schema_extra={"title": None})
    protein_g: float | None = Field(..., json_schema_extra={"title": None})
    fat_g: float | None = Field(..., json_schema_extra={"title": None})
    carbohydrate_g: float | None = Field(..., json_schema_extra={"title": None})
    sodium_mg: float | None = Field(..., json_schema_extra={"title": None})

    @model_validator(mode="before")
    @classmethod
    def fill_nullable(cls, value: object) -> object:
        if isinstance(value, dict):
            return {
                "energy_kcal": None,
                "protein_g": None,
                "fat_g": None,
                "carbohydrate_g": None,
                "sodium_mg": None,
                **value,
            }
        return value

    estimated: bool = True
    incomplete: bool = False


class RecipeDerived(BaseModel):
    total_time_seconds: int
    active_time_seconds: int
    cookware: list[str] = Field(default_factory=list)
    allergens: list[str] = Field(default_factory=list)
    allergens_incomplete: bool = False
    nutrition_per_serving: NutritionEstimate | None = Field(
        default=None, json_schema_extra={"title": None}
    )


class RecipeSnapshot(BaseModel):
    model_config = ConfigDict(extra="forbid")

    @model_validator(mode="before")
    @classmethod
    def fill_nullable(cls, value: object) -> object:
        if isinstance(value, dict):
            return {
                "difficulty": None,
                "dish_type": None,
                "format_version": 1,
                **value,
            }
        return value

    format_version: Literal[1] = Field(..., description="快照格式版本")
    servings: int = Field(ge=1, le=1000)
    total_time_seconds: int = Field(default=0, ge=0, le=604800)
    active_time_seconds: int = Field(default=0, ge=0, le=604800)
    difficulty: str | None = Field(..., json_schema_extra={"title": None})
    dish_type: str | None = Field(..., json_schema_extra={"title": None})
    tags: list[str] = Field(default_factory=list, max_length=50)
    ingredients: list[RecipeIngredient] = Field(default_factory=list, max_length=500)
    steps: list[RecipeStep] = Field(default_factory=list, max_length=200)


class RecipeCreate(BaseModel):
    """创建菜谱并保存第 1 版。"""

    dish_name: str | None = Field(..., json_schema_extra={"title": None})
    dish_aliases: list[str] = Field(default_factory=list, max_length=20)
    dish: DishInput | None = Field(..., json_schema_extra={"title": None})
    snapshot: RecipeSnapshot
    change_note: str = Field(default="", max_length=2000)
    ai_assisted: bool = False

    @model_validator(mode="before")
    @classmethod
    def fill_nullable(cls, value: object) -> object:
        if isinstance(value, dict):
            return {"dish_name": None, "dish": None, **value}
        return value

    @field_validator("dish_name")
    @classmethod
    def clean_dish_name(cls, value: str | None) -> str | None:
        if value is None:
            return value
        value = value.strip()
        if not value or len(value) > 200:
            raise ValueError("菜名不能为空且不超过 200 个字")
        return value

    @field_validator("dish_aliases")
    @classmethod
    def clean_dish_aliases(cls, values: list[str]) -> list[str]:
        return list(dict.fromkeys(v.strip() for v in values if v.strip()))

    def dish_input(self) -> DishInput:
        if self.dish is not None:
            if self.dish_name is not None and self.dish_name != self.dish.name:
                raise ValueError("dish_name 与 dish.name 不一致")
            aliases = list(dict.fromkeys([*self.dish.aliases, *self.dish_aliases]))
            return DishInput(name=self.dish.name, aliases=aliases)
        if self.dish_name is None:
            raise ValueError("需要提供 dish_name 或 dish")
        return DishInput(name=self.dish_name, aliases=self.dish_aliases)


class RecipeVersionCreate(BaseModel):
    snapshot: RecipeSnapshot
    change_note: str = Field(default="", max_length=2000)
    ai_assisted: bool = False
    base_version_id: IdV4 | None = Field(default=None, json_schema_extra={"title": None})


class RecipeAuthor(BaseModel):
    id: IdV4
    nickname: str


class DishOut(BaseModel):
    id: IdV4
    name: str
    aliases: list[str]


class RecipeImageOut(BaseModel):
    id: IdV4
    version_id: IdV4
    content_type: str
    byte_size: int
    width: int | None = Field(default=None, json_schema_extra={"title": None})
    height: int | None = Field(default=None, json_schema_extra={"title": None})
    url: str
    expires_in_seconds: int


class RecipeVersionOut(BaseModel):
    id: IdV4
    version_number: int
    previous_version_id: IdV4 | None = Field(default=None, json_schema_extra={"title": None})
    snapshot: RecipeSnapshot
    derived: RecipeDerived
    edit_operations: list[dict[str, Any]]
    change_note: str
    ai_assisted: bool
    created_at: Timestamp
    images: list[RecipeImageOut] = Field(default_factory=list)


class RecipeDetail(BaseModel):
    id: IdV4
    dish: DishOut
    author: RecipeAuthor
    visibility: Literal["private"]
    source_version_id: IdV4 | None = Field(default=None, json_schema_extra={"title": None})
    root_recipe_id: IdV4 | None = Field(default=None, json_schema_extra={"title": None})
    created_at: Timestamp
    updated_at: Timestamp
    version: RecipeVersionOut


class RecipeVersionSummary(BaseModel):
    id: IdV4
    version_number: int
    previous_version_id: IdV4 | None = Field(default=None, json_schema_extra={"title": None})
    change_note: str
    ai_assisted: bool
    created_at: Timestamp


class RecipeVersionHistory(BaseModel):
    items: list[RecipeVersionSummary]
    next_cursor: str | None = None


class RecipeListItem(BaseModel):
    id: IdV4
    dish: DishOut
    visibility: Literal["private"]
    version_number: int
    servings: int
    difficulty: str | None = Field(default=None, json_schema_extra={"title": None})
    total_time_seconds: int
    active_time_seconds: int
    updated_at: Timestamp


class RecipeList(BaseModel):
    items: list[RecipeListItem]
    next_cursor: str | None = None


class RecipeImageUpload(BaseModel):
    """JSON 上传替身，供网页端和无法使用 multipart 的客户端使用。"""

    content_base64: str = Field(min_length=1, max_length=20_000_000)
    content_type: str = Field(pattern=r"^image/(jpeg|png|webp)$")
    filename: str | None = Field(default=None, json_schema_extra={"title": None})
