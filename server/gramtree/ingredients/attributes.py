"""食材的详细属性（SPEC-002.1 #97）：数据文件格式、导入校验和接口输出共用这一套模型。

数据文件里每条食材可以带一个 `attributes` 对象，里面每个属性都是可选的；写了的属性一律是
`{"value": …, "source": "…", "status": "ai_draft" | "verified"}`：
- `source` 是这项数据的来源（例如 “USDA FoodData Central 171287”、“AI 起草、待核对”），
  有值就必须写来源；
- `status` 是校对状态，`ai_draft` 表示 AI 起草、还没人核对，`verified` 表示人工校对过。
接口输出时每个属性再带 `estimate`：没经人工校对的一律是估算。

登记值（缩放方式、超市分区、存放方式、计数单位、过敏原分类）在本文件维护，数据文件只能用
这里登记过的值。
"""

import enum
from typing import Self

from pydantic import BaseModel, ConfigDict, Field, computed_field, field_validator, model_validator

SCALING_METHODS = ("线性", "固定", "阶梯")
BASE_UNITS = ("克", "毫升")
COUNT_UNITS = ("个", "只", "颗", "粒", "瓣", "头", "根", "条", "片", "块", "张", "棵", "朵", "枚")
MARKET_ZONES = ("蔬果", "肉禽", "水产", "冷藏", "冷冻", "粮油调味", "干货", "烘焙")
STORAGE_METHODS = ("常温", "冷藏", "冷冻")
# GB 7718 列出的 8 类致敏物质，外加可扩展的芝麻
ALLERGENS = (
    "含麸质的谷物",
    "甲壳纲类动物",
    "鱼类",
    "蛋类",
    "花生",
    "大豆",
    "乳及乳制品",
    "坚果及其果仁",
    "芝麻",
)


def _check_registered(value: str, allowed: tuple[str, ...], what: str) -> str:
    if value not in allowed:
        raise ValueError(f"{what}“{value}”没有登记，只能用：{'、'.join(allowed)}")
    return value


def _check_unique(values: list[str], what: str) -> None:
    seen: set[str] = set()
    for v in values:
        if v in seen:
            raise ValueError(f"{what}“{v}”重复")
        seen.add(v)


class AttributeStatus(enum.StrEnum):
    """字段的校对状态。"""

    ai_draft = "ai_draft"
    verified = "verified"


class _Sourced(BaseModel):
    """每个属性字段都带来源和校对状态。"""

    model_config = ConfigDict(extra="forbid")

    source: str = Field(min_length=1, max_length=200, description="这项数据的来源")
    status: AttributeStatus = Field(description="ai_draft：AI 起草；verified：人工校对过")

    @computed_field(description="没经人工校对的字段按估算处理")
    @property
    def estimate(self) -> bool:
        return self.status != AttributeStatus.verified


class FlavorProfile(BaseModel):
    """味型贡献：单位用量下的相对强度，0～3，没写的项是 0。"""

    model_config = ConfigDict(extra="forbid")

    salty: int = Field(0, ge=0, le=3, strict=True, description="咸")
    sweet: int = Field(0, ge=0, le=3, strict=True, description="甜")
    sour: int = Field(0, ge=0, le=3, strict=True, description="酸")
    spicy: int = Field(0, ge=0, le=3, strict=True, description="辣")
    umami: int = Field(0, ge=0, le=3, strict=True, description="鲜")
    numbing: int = Field(0, ge=0, le=3, strict=True, description="麻")
    oily: int = Field(0, ge=0, le=3, strict=True, description="油")


class FlavorAttribute(_Sourced):
    value: FlavorProfile


class BoolAttribute(_Sourced):
    value: bool = Field(strict=True)


class TextAttribute(_Sourced):
    """取值为登记值之一的属性（缩放方式、基础单位、超市分区）。"""

    value: str


class DensityAttribute(_Sourced):
    value: float = Field(gt=0, strict=True, description="克/毫升")


class CountUnit(BaseModel):
    model_config = ConfigDict(extra="forbid")

    unit: str = Field(description="计数单位，例如 个、瓣、根、片")
    grams: float = Field(gt=0, strict=True, description="一个这样的单位大约多少克")

    @field_validator("unit")
    @classmethod
    def _unit(cls, v: str) -> str:
        return _check_registered(v, COUNT_UNITS, "计数单位")


class CountUnitsAttribute(_Sourced):
    value: list[CountUnit] = Field(min_length=1)

    @field_validator("value")
    @classmethod
    def _unique(cls, v: list[CountUnit]) -> list[CountUnit]:
        _check_unique([u.unit for u in v], "计数单位")
        return v


class AllergensAttribute(_Sourced):
    """所属过敏原分类；空列表表示不含已登记的过敏原。"""

    value: list[str]

    @field_validator("value")
    @classmethod
    def _registered(cls, v: list[str]) -> list[str]:
        for a in v:
            _check_registered(a, ALLERGENS, "过敏原分类")
        _check_unique(v, "过敏原分类")
        return v


class Nutrition(BaseModel):
    """每 100 克的营养，缺失的项留空。"""

    model_config = ConfigDict(extra="forbid")

    energy_kcal: float | None = Field(None, ge=0, strict=True, description="能量（千卡）")
    protein_g: float | None = Field(None, ge=0, strict=True, description="蛋白质（克）")
    fat_g: float | None = Field(None, ge=0, strict=True, description="脂肪（克）")
    carbohydrate_g: float | None = Field(None, ge=0, strict=True, description="碳水化合物（克）")
    sodium_mg: float | None = Field(None, ge=0, strict=True, description="钠（毫克）")

    @model_validator(mode="after")
    def _not_empty(self) -> Self:
        if all(v is None for v in self.model_dump().values()):
            raise ValueError("营养至少要有一项，全都没有就不要写这个属性")
        return self


class NutritionAttribute(_Sourced):
    value: Nutrition


class PurchaseUnit(BaseModel):
    model_config = ConfigDict(extra="forbid")

    name: str = Field(min_length=1, max_length=20, description="购买单位，例如 盒、把、瓶")
    grams: float = Field(gt=0, strict=True, description="一个购买单位大约多少克")


class PurchaseUnitsAttribute(_Sourced):
    value: list[PurchaseUnit] = Field(min_length=1)

    @field_validator("value")
    @classmethod
    def _unique(cls, v: list[PurchaseUnit]) -> list[PurchaseUnit]:
        _check_unique([u.name for u in v], "购买单位")
        return v


class StorageAdvice(BaseModel):
    model_config = ConfigDict(extra="forbid")

    method: str = Field(description="常温、冷藏或冷冻")
    days: int = Field(gt=0, strict=True, description="建议存放天数")

    @field_validator("method")
    @classmethod
    def _method(cls, v: str) -> str:
        return _check_registered(v, STORAGE_METHODS, "存放方式")


class StorageAttribute(_Sourced):
    value: list[StorageAdvice] = Field(min_length=1)

    @field_validator("value")
    @classmethod
    def _unique(cls, v: list[StorageAdvice]) -> list[StorageAdvice]:
        _check_unique([s.method for s in v], "存放方式")
        return v


class IngredientAttributes(BaseModel):
    """一种食材的全部详细属性，每项都可选；没有数据的项为 null。"""

    model_config = ConfigDict(extra="forbid")

    flavor: FlavorAttribute | None = Field(None, description="味型贡献")
    functional: BoolAttribute | None = Field(None, description="是否常作功能性用料")
    scaling: TextAttribute | None = Field(None, description="默认缩放方式：线性、固定、阶梯")
    base_unit: TextAttribute | None = Field(None, description="基础单位：克或毫升")
    density: DensityAttribute | None = Field(None, description="密度（克/毫升），液体和粉粒类")
    count_units: CountUnitsAttribute | None = Field(None, description="常见计数单位和单个重量")
    allergens: AllergensAttribute | None = Field(None, description="过敏原分类，可多类")
    nutrition: NutritionAttribute | None = Field(None, description="每 100 克营养")
    purchase_units: PurchaseUnitsAttribute | None = Field(None, description="购买单位和大约重量")
    market_zone: TextAttribute | None = Field(None, description="超市分区")
    storage: StorageAttribute | None = Field(None, description="建议存放方式和天数")
    pantry_staple: BoolAttribute | None = Field(None, description="是否常备调料")

    @field_validator("scaling")
    @classmethod
    def _scaling(cls, v: TextAttribute | None) -> TextAttribute | None:
        if v is not None:
            _check_registered(v.value, SCALING_METHODS, "缩放方式")
        return v

    @field_validator("base_unit")
    @classmethod
    def _base_unit(cls, v: TextAttribute | None) -> TextAttribute | None:
        if v is not None:
            _check_registered(v.value, BASE_UNITS, "基础单位")
        return v

    @field_validator("market_zone")
    @classmethod
    def _market_zone(cls, v: TextAttribute | None) -> TextAttribute | None:
        if v is not None:
            _check_registered(v.value, MARKET_ZONES, "超市分区")
        return v

    def stored_fields(self) -> dict[str, tuple[object, str, str]]:
        """写了的属性：字段名 → (值, 来源, 校对状态)，值是可直接存进 JSONB 的形式。"""
        out: dict[str, tuple[object, str, str]] = {}
        for name in type(self).model_fields:
            attr: _Sourced | None = getattr(self, name)
            if attr is not None:
                dumped = attr.model_dump(mode="json", exclude={"estimate"})
                out[name] = (dumped["value"], attr.source, attr.status.value)
        return out

    @classmethod
    def from_stored(cls, rows: dict[str, tuple[object, str, str]]) -> "IngredientAttributes":
        return cls.model_validate(
            {name: {"value": v, "source": s, "status": st} for name, (v, s, st) in rows.items()}
        )

    @classmethod
    def from_stored_empty(cls) -> "IngredientAttributes":
        """一条属性都没有的食材。"""
        return cls.from_stored({})
