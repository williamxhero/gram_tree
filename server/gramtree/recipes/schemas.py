"""菜谱 HTTP 请求与响应模型。

快照是版本的公开边界：所有可编辑字段在这里定义，服务层只负责校验、补充基础量和
派生信息，不把 ORM 对象暴露给客户端。
"""

from typing import Any, Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator

from gramtree.core.ids import IdV4
from gramtree.core.time import Timestamp
from gramtree.ui_protocol.protocol import SourcedValue

SourceType = Literal["author_filled", "ai_estimated", "verified"]
MoldShape = Literal["round", "square", "rectangular", "custom"]
MoldUnit = Literal["cm", "in", "inch"]


class ValueSource(BaseModel):
    model_config = ConfigDict(extra="forbid")

    source: SourceType
    original: str | None = None
    confidence: float | None = Field(default=None, ge=0, le=1)
    basis: str | None = None

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

    ingredient_id: IdV4 | None = None
    display_name: str = Field(min_length=1, max_length=200)
    ratio: float = Field(default=1, gt=0, le=100)
    note: str | None = None


class RecipeIngredient(BaseModel):
    model_config = ConfigDict(extra="forbid")

    id: str = Field(min_length=1, max_length=100, description="菜谱内食材 ID")
    ingredient_id: IdV4 | None = Field(default=None, description="标准食材 UUID；为空表示未收录")
    display_name: str = Field(min_length=1, max_length=200)
    quantity: float = Field(ge=0, le=10_000_000)
    unit: str = Field(min_length=1, max_length=20)
    # 服务端保存的统一基础量；作者只需填写 quantity/unit。
    base_quantity: float | None = Field(default=None, description="换算后的基础数量")
    base_unit: Literal["g", "ml", "count"] | None = Field(
        default=None, description="换算后的基础单位"
    )
    preparation: str | None = Field(default=None, description="处理方式")
    group: str | None = Field(default=None, description="食材分组")
    optional: bool = False
    replacement: RecipeReplacement | str | None = None
    functional: bool = False
    # 不填（或 null）表示作者没有设置：保存时用标准食材库的默认值，未收录的食材按比例。
    # 保存下来的版本快照里总是具体的缩放方式。
    scaling_mode: Literal["proportional", "unchanged", "round"] | None = Field(
        default=None, description="缩放方式；不填时用标准食材库的默认值，未收录的食材按比例"
    )
    quantity_source: ValueSource | None = None
    preparation_source: ValueSource | None = None

    @field_validator("display_name", "unit")
    @classmethod
    def non_blank_text(cls, value: str) -> str:
        value = value.strip()
        if not value:
            raise ValueError("文字不能为空")
        return value


class RecipeStep(BaseModel):
    model_config = ConfigDict(extra="forbid")

    id: str = Field(min_length=1, max_length=100, description="步骤 ID")
    action: str | None = None
    instruction: str = Field(min_length=1, max_length=2000)
    ingredient_ids: list[str] = Field(default_factory=list, max_length=100)
    duration_seconds: int = Field(default=0, ge=0, le=86400)
    unattended: bool = False
    heat: str | None = None
    temperature_celsius: float | None = Field(default=None, ge=-50, le=1000)
    cookware: str | None = None
    doneness: str | None = None
    depends_on: list[str] = Field(default_factory=list, max_length=100)
    notes: str | None = None
    why: str | None = None
    instruction_source: ValueSource | None = None
    doneness_source: ValueSource | None = None
    duration_source: ValueSource | None = None
    heat_source: ValueSource | None = None
    temperature_source: ValueSource | None = None

    @field_validator("temperature_celsius")
    @classmethod
    def reasonable_temperature(cls, value: float | None) -> float | None:
        if value is not None and not -50 <= value <= 1000:
            raise ValueError("温度超出合理范围")
        return value


class NutritionEstimate(BaseModel):
    energy_kcal: float | None = None
    protein_g: float | None = None
    fat_g: float | None = None
    carbohydrate_g: float | None = None
    sodium_mg: float | None = None

    estimated: bool = True
    incomplete: bool = False


class RecipeDerived(BaseModel):
    total_time_seconds: int
    active_time_seconds: int
    cookware: list[str] = Field(default_factory=list)
    allergens: list[str] = Field(default_factory=list)
    allergens_incomplete: bool = False
    nutrition_per_serving: NutritionEstimate | None = None


class RecipeSafetyFinding(BaseModel):
    rule_id: str
    severity: Literal["info", "warning", "high_risk"]
    message: str
    basis: str
    step_ids: list[str] = Field(default_factory=list)
    ingredient_ids: list[str] = Field(default_factory=list)
    threshold_celsius: float | None = None
    rest_minutes: int | None = None


class RecipeReplacementAllergens(BaseModel):
    ingredient_id: str = Field(description="替代品所属的菜谱内食材 ID")
    display_name: str
    allergens: list[str] = Field(default_factory=list)
    incomplete: bool = False


class RecipeSafetyResult(BaseModel):
    rules_version: str
    checked_at: Timestamp
    stale: bool = Field(default=False, description="当前检查早于已部署规则，正在等待后台复检")
    findings: list[RecipeSafetyFinding] = Field(default_factory=list)
    high_risk: bool = False
    allergens: list[str] = Field(default_factory=list)
    allergens_incomplete: bool = False
    replacement_allergens: list[RecipeReplacementAllergens] = Field(default_factory=list)
    prohibited_claims: list[str] = Field(default_factory=list)
    can_save: bool = True
    claim_basis: str | None = None


class MoldSpec(BaseModel):
    """A recipe base or target mold, stored as part of the immutable snapshot."""

    model_config = ConfigDict(extra="forbid")

    shape: MoldShape
    unit: MoldUnit | None = Field(default=None, validate_default=True)
    diameter: float | None = Field(default=None, gt=0, le=1000, allow_inf_nan=False)
    side: float | None = Field(default=None, gt=0, le=1000, allow_inf_nan=False)
    width: float | None = Field(default=None, gt=0, le=1000, allow_inf_nan=False)
    length: float | None = Field(default=None, gt=0, le=1000, allow_inf_nan=False)

    @field_validator("unit", mode="before")
    @classmethod
    def default_unit(cls, value: str | None) -> str:
        return value or "cm"

    @model_validator(mode="after")
    def validate_dimensions(self) -> "MoldSpec":
        if self.shape != "round" and self.unit != "cm":
            raise ValueError("方模、长方模及自定义尺寸请使用厘米")
        if self.shape == "round":
            if self.diameter is None:
                raise ValueError("圆模需要提供正的直径")
            return self
        if self.shape == "square":
            if self.side is not None and self.width is not None and self.side != self.width:
                raise ValueError("方模的 side 与 width 必须一致")
            effective_side = self.side if self.side is not None else self.width
            if effective_side is None:
                raise ValueError("方模需要提供正的边长")
            if self.length is not None and self.length != effective_side:
                raise ValueError("方模的边长必须相等")
            return self
        if self.width is None or self.length is None:
            raise ValueError("长方模或自定义模具需要提供正的宽和长")
        return self


class MoldConversionIngredient(BaseModel):
    """One ingredient as displayed after a bottom-area mold conversion."""

    id: str
    display_name: str
    original_quantity: float
    display_quantity: float
    unit: str
    rule: Literal["mold_ratio", "unchanged", "round"]
    source: SourcedValue
    deviation_ratio: float | None = None
    deviation_warning: bool = False


class MoldConversionStep(BaseModel):
    """Stable baking values plus the deterministic time/doneness advisory."""

    id: str
    instruction: str
    duration_seconds: int
    temperature_celsius: float | None = None
    heat: str | None = None
    time_advisory: str | None = None
    doneness_warning: bool = False
    doneness_warning_text: str | None = None


class MoldConversionWarning(BaseModel):
    code: Literal["round_deviation", "doneness_check"]
    ingredient_id: str | None = None
    message: str


class MoldConversion(BaseModel):
    """Deterministic mold conversion contract shared with the App."""

    original_mold: MoldSpec
    target_mold: MoldSpec
    area_ratio: float
    ingredients: list[MoldConversionIngredient]
    steps: list[MoldConversionStep]
    warnings: list[MoldConversionWarning]


class RecipeMoldConversionOut(BaseModel):
    recipe_id: IdV4
    version_id: IdV4
    conversion: MoldConversion


class RecipeSnapshot(BaseModel):
    model_config = ConfigDict(extra="forbid")

    format_version: Literal[1] = Field(default=1, description="快照格式版本")
    servings: int = Field(ge=1, le=1000)
    base_mold: MoldSpec | None = Field(default=None, description="烘焙菜谱的基准模具")
    total_time_seconds: int = Field(default=0, ge=0, le=604800)
    active_time_seconds: int = Field(default=0, ge=0, le=604800)
    difficulty: str | None = None
    dish_type: str | None = None
    description: str | None = Field(default=None, max_length=4000)
    tags: list[str] = Field(default_factory=list, max_length=50)
    cuisine: str | None = Field(default=None, max_length=100)
    design_rationale: str | None = Field(default=None, max_length=4000)
    text_source: ValueSource | None = None
    servings_source: ValueSource | None = None
    ingredients: list[RecipeIngredient] = Field(default_factory=list, max_length=500)
    steps: list[RecipeStep] = Field(default_factory=list, max_length=200)


class RecipeSnapshotInput(BaseModel):
    """Input-only trust boundary; backend and response snapshots may be verified."""

    snapshot: RecipeSnapshot

    @field_validator("snapshot")
    @classmethod
    def refuse_client_verified(cls, value: RecipeSnapshot) -> RecipeSnapshot:
        def visit(node: Any) -> None:
            if isinstance(node, ValueSource) and node.source == "verified":
                raise ValueError("已验证只能由后台根据做菜数据设置")
            if isinstance(node, BaseModel):
                for name in type(node).model_fields:
                    visit(getattr(node, name))
            elif isinstance(node, list):
                for item in node:
                    visit(item)

        visit(value)
        return value


class ReproducibilityPosition(BaseModel):
    collection: Literal["ingredients", "steps", "snapshot"]
    item_id: str | None = None
    field: str
    start: int | None = None
    end: int | None = None


class ReproducibilityProblem(BaseModel):
    id: str
    type: Literal["ambiguous", "missing"]
    status: Literal["unresolved", "ignored", "resolved"]
    message: str
    original: str | None = None
    position: ReproducibilityPosition


class RecipeReproducibilityResult(BaseModel):
    rules_version: str
    state: Literal["incomplete", "reproducible"]
    remaining_count: int
    required_field_count: int
    concrete_field_count: int
    field_completeness: float = Field(ge=0, le=1)
    problems: list[ReproducibilityProblem] = Field(default_factory=list)


class RecipeReproducibilityCheckRequest(RecipeSnapshotInput):
    model_config = ConfigDict(extra="forbid")
    snapshot: RecipeSnapshot


class RecipeReproducibilityCheckOut(BaseModel):
    result: RecipeReproducibilityResult


class RecipeCreate(RecipeSnapshotInput):
    """创建菜谱并保存第 1 版。"""

    dish_name: str | None = None
    dish_aliases: list[str] = Field(default_factory=list, max_length=20)
    dish: DishInput | None = None
    snapshot: RecipeSnapshot
    change_note: str = Field(default="", max_length=2000)
    ai_assisted: bool = False
    image_ids: list[IdV4] = Field(default_factory=list, max_length=10)

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


class RecipeVersionCreate(RecipeSnapshotInput):
    snapshot: RecipeSnapshot
    change_note: str = Field(default="", max_length=2000)
    ai_assisted: bool = False
    base_version_id: IdV4 | None = None
    image_ids: list[IdV4] = Field(default_factory=list, max_length=10)


class RecipeSafetyCheckRequest(RecipeSnapshotInput):
    model_config = ConfigDict(extra="forbid")

    dish_name: str = Field(default="", max_length=200)
    dish_aliases: list[str] = Field(default_factory=list, max_length=20)
    description: str | None = Field(default=None, max_length=4000)
    change_note: str = Field(default="", max_length=2000)
    snapshot: RecipeSnapshot


class RecipeSafetyCheckOut(BaseModel):
    result: RecipeSafetyResult


class RecipeSafetyRecheckOut(BaseModel):
    rules_version: str
    checked: int
    failed: int = 0


class RecipeMoldConversionRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    target_mold: MoldSpec


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
    width: int | None = None
    height: int | None = None
    url: str
    expires_in_seconds: int


class RecipeImageStagedOut(BaseModel):
    """Image uploaded before a recipe version is created."""

    id: IdV4
    content_type: str
    byte_size: int
    width: int | None = None
    height: int | None = None
    url: str
    expires_in_seconds: int


class RecipeVersionOut(BaseModel):
    id: IdV4
    version_number: int
    previous_version_id: IdV4 | None = None
    snapshot: RecipeSnapshot
    derived: RecipeDerived
    safety: RecipeSafetyResult | None = None
    safety_at_save: RecipeSafetyResult | None = None
    reproducibility: RecipeReproducibilityResult | None = None
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
    source_version_id: IdV4 | None = None
    root_recipe_id: IdV4 | None = None
    created_at: Timestamp
    updated_at: Timestamp
    version: RecipeVersionOut


class RecipeVersionSummary(BaseModel):
    id: IdV4
    version_number: int
    previous_version_id: IdV4 | None = None
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
    difficulty: str | None = None
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
    filename: str | None = None


class ServingConversionIngredient(BaseModel):
    """One immutable recipe ingredient as displayed at the requested servings."""

    id: str
    display_name: str
    original_quantity: float
    display_quantity: float
    unit: str
    rule: Literal["proportional", "unchanged", "round"]
    source: SourcedValue
    deviation_ratio: float | None = None
    deviation_warning: bool = False


class ServingConversionStep(BaseModel):
    """Step values that remain unchanged, plus a deterministic batch warning."""

    id: str
    instruction: str
    duration_seconds: int
    temperature_celsius: float | None = None
    heat: str | None = None
    batch_warning: bool = False
    batch_warning_text: str | None = None


class ServingConversionWarning(BaseModel):
    code: Literal["round_deviation"]
    ingredient_id: str | None = None
    message: str


class ServingConversion(BaseModel):
    """Deterministic serving conversion contract shared with the App."""

    original_servings: int
    target_servings: int
    min_servings: int
    max_servings: int
    ingredients: list[ServingConversionIngredient]
    steps: list[ServingConversionStep]
    warnings: list[ServingConversionWarning]
    total_time_seconds: int
    active_time_seconds: int


class RecipeServingConversionOut(BaseModel):
    recipe_id: IdV4
    version_id: IdV4
    conversion: ServingConversion


class RecipeDisplayedIngredient(BaseModel):
    """One immutable recipe amount in the requested display mode."""

    id: str
    display_name: str
    original_quantity: float
    original_unit: str
    converted_quantity: float | None = None
    converted_unit: str | None = None
    conversion_rule: Literal["base", "proportional", "unchanged", "round", "mold_ratio"] = "base"
    text: str
    display_quantity: float
    display_unit: str
    grams: float | None = None
    rule: Literal["base", "standard_measure", "personal_measure", "no_density"]
    source: SourcedValue


class RecipeIngredientDisplay(BaseModel):
    """Read-only display conversion for one owned recipe version."""

    recipe_id: IdV4
    version_id: IdV4
    mode: Literal["base", "standard", "home"]
    measure_id: IdV4 | None = None
    ingredients: list[RecipeDisplayedIngredient]


class RecipeIngredientDisplayOut(BaseModel):
    display: RecipeIngredientDisplay
